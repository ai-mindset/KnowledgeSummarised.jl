#!/usr/bin/env zsh 

if ! command -v julia &> /dev/null
then
    echo "Installing Juliaup..."
    if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
        curl -fsSL https://install.julialang.org | sh
        if ! command -v ollama &> /dev/null 
            curl -fsSL https://ollama.com/install.sh | sh
        fi
        hash -r
    elif cat /proc/version | grep Microsoft; then
        winget install julia -s msstore
        echo "Please install ollama before continuing https://ollama.com/download/OllamaSetup.exe"
        echo "then run `julia --proj src/ImmuneSummarised.jl` in a terminal"
        exit 1
    fi
fi

# julia --proj src/ImmuneSummarised.jl -f ./Immune\ 77_excerpt.txt
julia --proj src/ImmuneSummarised.jl
