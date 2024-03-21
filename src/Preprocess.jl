module Preprocess
include("OllamaAI.jl")

##
# Imports
using HTTP
using JSON
using Glob: glob

##
# const
const VIDEO_SOURCE_DIR::String = "videos"
const TRANSCRIPTS_DIR::String = "transcripts"
const CONTEXT_TOKENS = 4192
const CONTEXT_WORDS = round(Int64, CONTEXT_TOKENS * 0.75)

##
"""
    download_episodes(playlist_url::String, playlist_file::String)

Download new episodes from a channel or playlist.  Episodes will be saved in
```julia
$(splitpath(Base.active_project())[end-1])/$VIDEO_SOURCE_DIR
\```
See [Supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md) for
more information.
Make sure you've downloaded the latest [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases)
and placed it in your \$PATH

# Arguments
- `playlist_url::String`: A video or playlist URL, youtube.com, youtu.be, yewtu.be, piped.video etc. can be used
- `PROJECT_ROOT::String`: Top-level project path

# Returns
- `episodes::Vector{SubString{String}}`: List of episodes' audio (.mp3) downloaded from `playlist_url`

# Throws
- `ErrorException`: If OS is unknown, throw error. Supported OSs are Linux, macOS, Windows.
"""
function download_episodes(
        playlist_url::String, PROJECT_ROOT::String)::Vector{String}
    # TODO: Check if `yt-dlp` is installed. If not, `mkdir` and `curl` the latest release for the host OS. Set `chmod u+x` and run locally
    current_dir = (@__DIR__)
    if current_dir != PROJECT_ROOT
        cd(PROJECT_ROOT)
    end
    if !isdir(VIDEO_SOURCE_DIR)
        mkdir(VIDEO_SOURCE_DIR)
    end
    cd(VIDEO_SOURCE_DIR)

    local cmd
    if Sys.islinux()
        cmd = ["yt-dlp_linux -x --audio-format mp3 $(playlist_url) ",
            "--download-archive playlist.txt"]
    elseif Sys.isapple()
        cmd = ["yt-dlp_macos -x --audio-format mp3 $(playlist_url) ",
            "--download-archive playlist.txt"]
    elseif Sys.iswindows()
        cmd = ["yt-dlp_x86.exe -x --audio-format mp3 $(playlist_url) ",
            "--download-archive playlist.txt"]
    else
        error("Unknown OS")
    end
    try
        joined_cmd::String = join(cmd)
        c = Cmd(convert(Vector{String}, split(joined_cmd)))
        run(c)
    catch e
        println("download_episodes():$(e)")
    end

    episodes::Vector{String} = glob("*.mp3")
    cd(PROJECT_ROOT) # Return to top-level

    return episodes
end

##
"""
    transcribe(episode::String; progress_bar::Bool = true, timestamps::Bool = false)

Transcribe downloaded episode. Warning: slow process
Make sure you've downloaded the latest [whisper-standalone-win](https://github.com/Purfview/whisper-standalone-win/releases)
and placed it in your PATH

# Arguments
- `episode::String`: Audio of video filename to transcribe

# Returns
- `transcripts::Vector{String}`: Vector of transcript names in "$TRANSCRIPTS_DIR" dir

# Throws
- `ErrorException`: If transcription fails, throw error
othing
"""
function transcribe(episode::String, PROJECT_ROOT::String)::Vector{String}
    # TODO: Check if `whisper-faster` is installed. If not, `mkdir("exe")` or similar
    # and `curl` the latest release for the host OS. Set `chmod u+x` and run locally
    current_dir = (@__DIR__)
    if current_dir != PROJECT_ROOT
        cd(PROJECT_ROOT)
    end
    if !isdir(TRANSCRIPTS_DIR)
        mkdir(TRANSCRIPTS_DIR)
    end
    cd(TRANSCRIPTS_DIR)
    episode = replace(episode, " " => "\\ ")
    episode = replace(episode, "[" => "\\[", "]" => "\\]")

    full_path = " $PROJECT_ROOT/$VIDEO_SOURCE_DIR/$episode"
    cmd = ["whisper-faster", full_path, " --language=English",
        " --model=medium", " --output_dir=.", " -pp", " --output_format=text"]

    println(`$(join(cmd))`)

    try
        run(Cmd(cmd))
    catch e
        println("Preprocess.transcribe():$(e)")
    end
end

##
"""
    token_count(vector::Vector{String})

Approximately count the total number of tokens in a vector of strings.
1 token = 0.75 words per [OpenAI API documentation](https://platform.openai.com/docs/introduction)

# Arguments
- `vector::Vector{String}`: A vector of strings.

# Returns
- `Int64`: The total number of tokens in the vector of strings
- `Int64`: The total number of words in the vector of strings
"""
function word_and_token_count(vector::Vector{String})::Tuple{Int64, Int64}
    token_estimate::Float64 = 0
    total_words::Int64 = 0

    for text in vector
        words = split(text)
        total_words += length(words)
        token_estimate += total_words / 0.75
    end

    return round(Int64, token_estimate), total_words
end

"""
    token_count(text::String)
Approximately count the total number of tokens in a string of text.
1 token = 0.75 words per [OpenAI API documentation](https://platform.openai.com/docs/introduction)

# Arguments
- `text::String`: A string of text

# Returns
- `Int64`: The total number of tokens in the string.
"""

function word_and_token_count(text::String)::Int64
    token_estimate = length(split(text)) / 0.75

    return round(Int64, token_estimate)
end

##
"""
    segment_input(vector::Vector{String})
Segment text into `$(CONTEXT_WORDS)\` word chunks.
Chunk length is calculated using the token = 0.75 word conversion,
according to [OpenAI API documentation](https://platform.openai.com/docs/introduction).

# Arguments
- `vector::Vector{String}`: A vector of strings

# Returns
- `Dict{Int64, String}`: Chunks of text divided into
"""
function segment_input(vector::Vector{String})
    d = Dict{Int64, String}()
    i = 1
    chunk = ""

    for text in vector
        chunk *= text * " "
        if word_and_token_count(chunk) >= (CONTEXT_TOKENS - 10)
            d[i] = chunk
            chunk = ""
            i += 1
        end
    end

    if !isempty(chunk)
        d[i] = chunk
    end

    return d
end

##
"""

"""
function summarise_text(model::String, chunks::Dict{Int64, String})::Vector{String}
    local url = "http://localhost:11434/api/generate"
    local summaries = Vector{String}()

    for (_, v) in chunks
        prompt = "Transcript excerpt: $v"
        prompt *= """\nSummarise the most important knowledge in the transcript above.
            Only return the summary, wrapped in single quotes (' '), and nothing else.
            Be precise."""
        request = OllamaAI.send_request(prompt, model)
        res = HTTP.request("POST", url, [("Content-type", "application/json")], request)
        if res.status == 200
            body = JSON.parse(String(res.body))
            push!(summaries, body["response"])
        else
            error("LLM returned status $(res.status)")
        end
    end

    return summaries
end

end
