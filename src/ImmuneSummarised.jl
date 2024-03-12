module ImmuneSummarised
using ArgParse: ArgParseSettings, parse_args, add_arg_table!
include("Preprocess.jl")

"""
    parse_cli_args()

Parse CLI argument(s). Required arg `file` is the relative path of the transcript file to be summarised.
Defaults to `./transcript.rst` if no file argument is passed

# Arguments
nothing

# Returns
- `args::Dict{String, Any}`: CLI argument(s)
"""
function parse_cli_args()::Dict{String, Any}
    settings = ArgParseSettings()

    add_arg_table!(settings,
        ["--file", "-f"],
        Dict(:help => "transcript file name including relative path.")
    )

    args = parse_args(settings)

    return args
end

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
function julia_main()::Tuple{Vector{String}, Vector{String}}
    args::Dict{String, Any} = parse_cli_args()
    local file
    for (k, v) in args
        if k == "file"
            file = v
        else
            error("Please pass flag '--file' or '-f' with a transcript file name string with its relative path")
        end
    end

    Preprocess.clean_text(file)

    text::Vector{String} = open(file) |> readlines
    _, text_words::Int64 = Preprocess.word_and_token_count(text)
    println("Original transcript contains $text_words words")
    d::Dict{Int64, String} = Preprocess.segment_input(text)

    summaries::Vector{String} = Preprocess.summarise_text("mistral", d)
    d_final::Dict{Int64, String} = Preprocess.segment_input(summaries)
    master_summary::Vector{String} = Preprocess.summarise_text("mistral", d_final)
    _, summary_words::Int64 = Preprocess.word_and_token_count(master_summary)
    println("The summary contains $summary_words words. That is $(round(Int64, (text_words / summary_words)))x compression ratio")

    return summaries, master_summary
end

@time _, summary_of_summaries = julia_main()

end # module ImmuneSummarised
