using ImmuneSummarised
using Test

@testset "Example tests" begin
    @testset "Preprocess tests" begin
        include("preprocess_tests.jl")
    end

    @testset "Ollama tests" begin
        include("ollama_tests.jl")
    end

    @testset "Main tests" begin
        include("immunesummarised_tests.jl")
    end
end
