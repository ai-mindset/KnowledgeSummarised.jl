# Knowledge, summarised

[![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle)

This project started as an efficient way to summarise some of the excellent [MicrobeTV](https://www.microbe.tv) podcast episodes, for my personal education. I chose [Immune](https://www.microbe.tv/immune/) as a starting point. It runs on a monthly cadence, each episode spans approx. 1 hour, where a panel of immunology experts discuss new publications. At the time of writing, the [Immune playlist](https://www.youtube.com/watch?v=jnvBvbTcwIQ&list=PLGhmZX2NKiNkNlShZ2YuHH1GkwdsnH4pr&pp=iAQB) contains approximately 66 hours of high-quality scientific content over 49 episodes (some older episodes seem to be missing from the YouTube playlist).

This initial aim acted as motivation for me to write a tool in Julia, which will help me learn what I'm interested in, at a faster pace. The final goal is to utilise open-source technology able to run locally on an affordable personal computer, to learn about immunology in a time efficient way, affordably.  
Should this experiment yields satisfactory results, the same principle could be applied to different playlists depending on interest. Hence broadening the scope by naming this tool `KnowledgeSummarised.jl` i.e. knowledge, summarised, using Julia.

Technology stack:
[Julia](https://julialang.org/) for development
[yt-dlp](https://github.com/yt-dlp/yt-dlp) to download podcast audio from its YouTube playlist  
[Whisper-Faster](https://github.com/Purfview/whisper-standalone-win/releases/tag/faster-whisper) for audio transcription  
[Ollama](https://ollama.ai/) with Llama2, for summarisation and information retrieval  

