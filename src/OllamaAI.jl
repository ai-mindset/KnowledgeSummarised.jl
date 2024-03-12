module OllamaAI

using HTTP
using JSON
import DataFrames: DataFrame

"""
    send_request(prompt::String, model::String)

Send request to Ollama LLM

# Arguments
- `prompt::String`: Prompt incl. context to be sent to Ollama LLM
- `model::String`: Model name

# Credit
@rcherukuri12 for the [solution](https://discourse.julialang.org/t/using-julia-to-connect-to-local-llms/106137)
"""
function send_request(prompt::String, model::String)
    println("Sending request to LLM...")
    data = Dict() # declare empty to support Any type.
    data["model"] = model
    data["prompt"] = prompt
    data["stream"] = false  # turning off streaming response.
    data["temperature"] = 0.0
    return JSON.json(data)
end

end
