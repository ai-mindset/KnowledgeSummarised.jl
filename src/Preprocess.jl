module Preprocess

##
# Imports
using HTTP
using JSON
include("OllamaAI.jl")

## Globals
const CONTEXT_TOKENS = 4192
const CONTEXT_WORDS = round(Int64, CONTEXT_TOKENS * 0.75)

##
"""
    download_episodes(playlist_url::String, playlist_file::String)

Download new episodes from a YouTube playlist of interest.  Episodes will be saved in
```julia
$(splitpath(Base.active_project())[end-1])/videos
\```
Make sure you've downloaded the latest [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases)
and placed it in your \$PATH

# Arguments
- `playlist_url::String`: A YouTube video or playlist URL, youtube.com, youtu.be, yewtu.be, piped.video etc. can be used

# Keywords
- `playlist_file::String = ""`: Text file keeping a record of the playlist videos that have already been downloaded to directory.
If nothing is passed, it is assumed you're downloading a single episode

# Returns
- `episodes::Vector{SubString{String}}`: List of episodes' audio (.mp3) downloaded from `playlist_url`

# Throws
- `ErrorException`: If OS is unknown, throw error. Supported OSs are Linux, macOS, Windows.
"""
function download_episodes(playlist_url::String;)::Vector{SubString{String}}
    # TODO: Check if `yt-dlp` is installed. If not, `mkdir` and `curl` the latest release for the host OS. Set `chmod u+x` and run locally

    dir::String = "videos"
    if !isdir(dir)
        mkdir(dir)
    end
    cd(dir)

    # If playlist file is empty, we expect a single video URL to be passed in.
    # Otherwise, we expect a playlist which should be recorded in a `playlist_file`
    # for speeding up future playlist updates
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
        if typeof(cmd) == Vector{String}
            joined_cmd::String = join(cmd)
            c = Cmd(convert(Vector{String}, split(joined_cmd)))
            run(c)
        else
            c = Cmd(convert(Vector{String}, split(cmd)))
            run(c)
        end
    catch e
        println("download_episodes():$(e)")
    end

    ep::String = readchomp(`ls`)
    episodes::Vector{SubString{String}} = split(ep, "\n")
    cd("./../") # Return to top-level

    return episodes
end

##
"""
    transcribe(episode::String; progress_bar::Bool = true, timestamps::Bool = false)

Transcribe downloaded episode. Warning: slow process
Make sure you've downloaded the latest [whisper-standalone-win](https://github.com/Purfview/whisper-standalone-win/releases)
and placed it in your PATH

# Arguments
- `episode::String`: Filepath that contains an episode transcript. Supported files are .rst, .txt, .md

# Keywords
- `progress_bar::Bool = true`: Show progress bar instead of actual transcript, during transcription
- `timestamps::Bool = false`: Include timestamp in transcript

# Returns
- `transcripts::Vector{String}`: Vector of names of transcripts in "./transcripts" dir

# Throws
- `ErrorException`: If transcription fails, throw error
othing
"""
function transcribe(
        episode::SubString{String}; progress_bar::Bool = true, timestamps::Bool = false)::Vector{String}
    # TODO: Check if `whisper-faster` is installed. If not, `mkdir("exe")` or similar
    # and `curl` the latest release for the host OS. Set `chmod u+x` and run locally

    source = "videos"
    dir = "transcripts"
    if !isdir(dir)
        mkdir(dir)
    end
    cd(dir)
    out_rel_dir = "./" * dir
    source_rel_dir = "./" * source * "/" * episode

    cmd = ["whisper-faster $source_rel_dir --language=English --model=medium --output_dir=./$out_rel_dir"]
    # Print progress bar instead of transcript?
    prog_bar::String = tstamps::String = ""
    if progress_bar == true
        prog_bar = "--pp=true"
        push!(cmd, prog_bar)
    end
    # Print timestamps?
    if timestamps == false
        tstamps = "--without_timestamps=true"
        push!(cmd, tstamps)
    end

    try
        if typeof(cmd) == Vector{String}
            joined_cmd::String = join(cmd)
            c = Cmd(convert(Vector{String}, split(joined_cmd)))
            run(c)
        else
            c = Cmd(convert(Vector{String}, split(cmd)))
            run(c)
        end
    catch e
        println("transcribe():$(e)")
    end

    t::String = readchomp(`ls`)
    transcripts::Vector{SubString{String}} = split(t, "\n")
    cd("./../") # Return to top-level

    return transcripts
end

##
"""
    clean_text(filename::String)

# Arguments
- `filename::String`: Transcript filename

# Returns
- `Int64`: Status code 0 for success, -1 for error

# Throws
- `ErrorException`: If text cleaning fails, throw errorothing
"""
function clean_text(filename::String)
    # Define the regex pattern to match timestamps
    pattern = r"^\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}$"
    # Define regex pattern to remove number over timestamp & empty lines
    expanded_pattern = r"(^\d+$)|(^\s*$)|($pattern)"

    try
        # Read the file and store non-matching lines in a list
        lines_to_keep = filter(
            line -> !occursin(expanded_pattern, line), readlines(filename))

        # Write the filtered lines back to the file
        open(filename, "w") do file
            foreach(line -> println(file, line), lines_to_keep)
        end
        println("$filename cleaned!")
    catch e
        println("Oh no!")
        println("clean_text():$(e)")
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
    local summaries = Vector{String}()
    local url = "http://localhost:11434/api/generate"
    for (k, v) in chunks
        prompt = "Transcript excerpt: $v"
        prompt *= """\nSummarise the most important knowledge in the transcript above, in three paragraphs at most.
            Only return the summary, wrapped in single quotes (' '), and nothing else.
            Be concise"""
        request = OllamaAI.send_request(prompt, model)
        res = HTTP.request("POST", url, [("Content-type", "application/json")], request)
        if res.status == 200
            body = JSON.parse(String(res.body))
            push!(summaries, body["response"])
        else
            println("LLM returned status $(res.status)")
        end
    end

    return summaries
end

end
