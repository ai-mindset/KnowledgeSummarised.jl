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
$(splitpath(Base.active_project())[end-1])/playlist
\```
Make sure you've downloaded the latest [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases)
and placed it in your \$PATH

# Arguments
- `playlist_url::String`: A YouTube playlist URL, youtube.com, youtu.be, yewtu.be, piped.video etc. can be used
- `playlist_file::String`: Text file keeping a record of the playlist videos that have already been downloaded to directory

# Returns
- `nothing`

# Throws
- `ErrorException`: If OS is unknown, throw error. Supported OSs are Linux, macOS, Windows.
"""
function download_episodes(playlist_url::String, playlist_file::String)::Int64
    # TODO: Check if `yt-dlp` is installed. If not, `mkdir` and `curl` the latest release for the host OS. Set `chmod u+x` and run locally
    dir = "./playlist"
    mkdir(dir)
    cd(dir)
    try
        if Sys.islinux()
            run(`yt-dlp_linux -x --audio-format mp3 $(playlist_url) --download-archive $(playlist_file)`)
        elseif Sys.isapple()
            run(`yt-dlp_macos -x --audio-format mp3 $(playlist_url) --download-archive $(playlist_file)`)
        elseif Sys.iswindows()
            run(`yt-dlp_x86.exe -x --audio-format mp3 $(playlist_url) --download-archive $(playlist_file)`)
        else
            error("Unknown OS")
        end
    catch e
        println("download_episodes():$(e)")
    end
end

##
"""
    transcribe(episode::String)

Transcribe downloaded episode. Warning: slow process
Make sure you've downloaded the latest [whisper-standalone-win](https://github.com/Purfview/whisper-standalone-win/releases)
and placed it in your PATH

# Arguments
- `episode::String`: Filepath that contains an episode transcript. Supported files are .rst, .txt, .md

# Returns
- `nothing`

# Throws
- `ErrorException`: If transcription fails, throw error
othing
"""
function transcribe(episode::String)
    # TODO: Check if `whisper-faster` is installed. If not, `mkdir` and `curl` the latest release for the host OS. Set `chmod u+x` and run locally
    # Print progress bar instead of transcript
    progress_bar::String = "--print_progress=True"
    # Print timestamp
    timestamps::String = "--without_timestamps=True"
    command::Cmd = `whisper-faster $episode --language=English --model=medium --output_dir=. $progress_bar $timestamps`
    println("Transcribing $(episode)...")
    try
        run(command)
    catch e
        println("transcribe():$(e)")
    end
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
    catch e
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
- `Int64`: The total number of tokens in the vector of strings.
"""
function token_count(vector::Vector{String})::Int64
    token_estimate = 0

    for text in vector
        words = split(text)
        token_estimate += length(words) / 0.75
    end

    return round(Int64, token_estimate)
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

function token_count(text::String)::Int64
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
        if token_count(chunk) >= (CONTEXT_TOKENS - 10)
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
function summarise_text(model::String, chunks::Dict{Int64, String})
    prompt = chunks[1] # FIXME: temporary, for testing
    prompt *= "\nSummarise the most important knowledge in the text above,
        in at most three sentences.
        Only return the summary and nothing else.
        Be concise"
    request = OllamaAI.send_request(prompt, model)
    url = "http://localhost:11434/api/generate"
    res = HTTP.request("POST", url, [("Content-type", "application/json")], request)
    if res.status == 200
        body = JSON.parse(String(res.body))
        println(body["response"])
    else
        println("LLM returned status $(res.status)")
    end
end

end
