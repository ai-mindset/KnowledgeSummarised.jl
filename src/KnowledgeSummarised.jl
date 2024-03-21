module KnowledgeSummarised
include("Preprocess.jl")

##
# Imports
using Glob: glob

##
# const
# Base.active_project()[end] returns `Project.toml`
# @__DIR__ returns abs project path + /src
const PROJECT_ABS_PATH::Vector{String} = split(Base.active_project(), "/")
const PROJECT_ROOT::String = join(PROJECT_ABS_PATH[1:(end - 1)], "/")

##
"""
    julia_main()

Main function. It triggers the transciption and summarisation process.
WARNING: Slow process on computers without a modern GPU

# Arguments
- `playlist_url::String`: URL of video or playlist, from [supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)

# Returns
- `summaries::Vector{String}`: Individual summaries of a larger document that may not fit in a smaller LLM's context Windows
- `master_summary::Vector{String}`: A summary of all `summaries`
"""
function julia_main(playlist_url::String)::Tuple{Vector{String}, Vector{String}}
    cd(PROJECT_ROOT)

    # Extract the audio and download as .mp3 the video or entire playlist that `playlist_url` points to
    episodes::Vector{String} = Preprocess.download_episodes(playlist_url, PROJECT_ROOT)
    for episode in episodes
        Preprocess.transcribe(episode, PROJECT_ROOT)
    end

    transcripts::Vector{String} = glob("*.text") # We're still in $PROJECT_ROOT/transcrips

    local summaries
    for file in transcripts
        text::Vector{String} = open(file) |> readlines
        _, no_words::Int64 = Preprocess.word_and_token_count(text)
        println("Original transcript contains $no_words words")
        d::Dict{Int64, String} = Preprocess.segment_input(text)

        transcript_summary::Vector{String} = Preprocess.summarise_text("mistral", d)
        append!(summaries, transcript_summary)
    end
    if length(summaries) > 1
        d_final::Dict{Int64, String} = Preprocess.segment_input(summaries)
        append!(master_summary, Preprocess.summarise_text("mistral", d_final))
        _, summary_words::Int64 = Preprocess.word_and_token_count(master_summary)
        println("The summary contains $summary_words words. That is $(round(Int64, (no_words / summary_words)))x compression ratio")
    end

    cd(PROJECT_ROOT) # Return to top-level

    return summaries, master_summary
end

master_summary, summary_of_summaries = julia_main("https://www.youtube.com/shorts/iQEE0LwVp_Q")

end # module KnowledgeSummarised
