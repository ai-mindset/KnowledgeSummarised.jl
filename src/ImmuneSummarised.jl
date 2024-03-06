module ImmuneSummarised
include("Preprocess.jl")

file = "./Immune 77： Squeezing the most killing out of neutrophils.txt"
Preprocess.clean_text(file)

text::Vector{String} = open(file) |> readlines
num_of_words::Int64 = Preprocess.token_count(text)
d::Dict{Int64, String} = Preprocess.segment_input(text)

summaries = Preprocess.summarise_text("llama2", d)

end # module ImmuneSummarised
