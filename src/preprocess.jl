##
# Imports



##
"""
    download_episodes(playlist_url::String, playlist_file::String)

Download new episodes from a YouTube playlist of interest.  Episodes will be saved in
```julia
$(splitpath(Base.active_project())[end-1])/playlist
\```
Supported OSs: Linux, macOS, Windows.
Make sure you've downloaded the latest [`yt-dlp`](https://github.com/yt-dlp/yt-dlp/releases)
and placed it in your \$PATH
"""
function download_episodes(playlist_url::String, playlist_file::String)
    mkdir("playlist")
    cd("playlist")
    if Sys.islinux()
        run(`yt-dlp_linux -x --audio-format mp3 $(playlist_url) --download-archive $(playlist_file)`)
    elseif Sys.isapple()
        run(`yt-dlp_macos -x --audio-format mp3 $(playlist_url) --download-archive $(playlist_file)`)
    elseif Sys.iswindows()
        run(`yt-dlp_x86.exe -x --audio-format mp3 $(playlist_url) --download-archive $(playlist_file)`)
    else
        error("Unknown OS")
    end

end


##
"""
    transcribe(episode::String)

Transcribe downloaded episode. Warning: slow process
Make sure you've downloaded the latest [whisper-standalone-win](https://github.com/Purfview/whisper-standalone-win/releases)
and placed it in your \$PATH
"""
function transcribe(episode::String)
    progress_bar::String = "--print_progress=True" # Prints progress bar instead of transcript
    timestamps::String = "--without_timestamps=True" # Prints timestamps
    command::Cmd = `whisper-faster $episode --language=English --model=medium --output_dir=. $progress_bar $timestamps`    
    println("Transcribing $(episode)...")
    run(command)
end
    

##
"""
    clean_text(filename::String)

"""
function clean_text(filename::String)
    # Define the regex pattern to match timestamps
    pattern = r"^\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}$"
    # Define regex pattern to remove number over timestamp & empty lines
    expanded_pattern = r"(^\d+$)|(^\s*$)|($pattern)"

    # Read the file and store non-matching lines in a list
    lines_to_keep = filter(line -> !occursin(expanded_pattern, line), readlines(filename))

    # Write the filtered lines back to the file
    open(filename, "w") do file
        foreach(line -> println(file, line), lines_to_keep)
    end
end


##
"""
    count_words()
Simplistic proxy for counting tokens.
It most likely underestimates the number of tokens in a file.
1 token = 0.75 words per [OpenAI API documentation](https://platform.openai.com/docs/introduction)

Input:
- `vector::Vector{String}` - Text of interest

Returns:
- total_words::Int64 - The number of words included in the string vector
"""
function count_words(vector::Vector{String})
    token_estimate = 0
    for text in vector
        words = split(text)
        token_estimate += length(words) / 0.75
    end
    return token_estimate
end


##
"""
Segment text into 3000 word chunks.
3000 is derived by the smallest model context (4192 tokens) / 1.33,
used as a rule of thumb by OpenAI to convert words into tokens
(1 token = 0.75 words, 1 word ≈ 1.33 tokens)
"""
function segment_input(vector::Vector{String})

end




##
# Call the function with the filename containing the timestamps
file = "./../../Downloads/Whisper-Faster/Immune 77： Squeezing the most killing out of neutrophils.txt"
clean_text(file)

text::Vector{String} = open(file) |> readlines
num_of_words::Int64 = count_words(text)
