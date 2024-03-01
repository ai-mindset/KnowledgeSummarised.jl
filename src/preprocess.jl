##`
# Imports


##
function clean_text(filename::AbstractString)
    # Define the regex pattern to match timestamps
    pattern = r"^\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}$"
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
It is expected to underestimate the number of tokens in a file.

Input:
- vector::Vector{String} - Text of interest

Returns: 
- total_words::Int64 - The number of words included in the string vector
"""
function count_words(vector::Vector{String})
    total_words = 0
    for text in vector
        words = split(text)
        total_words += length(words)
    end
    return total_words
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
