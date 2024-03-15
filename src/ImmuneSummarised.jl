module ImmuneSummarised
include("Preprocess.jl")

##
"""
    julia_main()

Main function. It triggers the transciption and summarisation process.
WARNING: Slow process on computers without a modern GPU

# Arguments
nothing

# Returns
- `summaries::Vector{String}`: Individual summaries of a larger document that may not fit in a smaller LLM's context Windows
- `master_summary::Vector{String}`: A summary of all `summaries`
"""
function julia_main(
        playlist_url::String, playlist_file::String)::Tuple{Vector{String}, Vector{String}}
    # Extract the audio and download as .mp3 the video or entire playlist that `playlist_url` points to
    episodes = Preprocess.download_episodes(playlist_url; playlist_file)

    for episode in episodes
        summaries::Vector{String} = master_summary::Vector{String} = transcripts::Vector{String} = []

        # FIXME
        transcripts::Vector{String} = Preprocess.transcribe(episode)
        for file in transcripts
            Preprocess.clean_text(file)

            text::Vector{String} = open(file) |> readlines
            _, text_words::Int64 = Preprocess.word_and_token_count(text)
            println("Original transcript contains $text_words words")
            d::Dict{Int64, String} = Preprocess.segment_input(text)

            append!(summaries, Preprocess.summarise_text("mistral", d))
            if length(summaries) > 1
                d_final::Dict{Int64, String} = Preprocess.segment_input(summaries)
                append!(master_summary, Preprocess.summarise_text("mistral", d_final))
                _, summary_words::Int64 = Preprocess.word_and_token_count(master_summary)
                println("The summary contains $summary_words words. That is $(round(Int64, (text_words / summary_words)))x compression ratio")
            end
        end
    end

    return summaries, master_summary
end

master_summary, summary_of_summaries = julia_main()

end # module ImmuneSummarised
