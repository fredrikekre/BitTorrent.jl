using Documenter, BitTorrent

if haskey(ENV, "GITHUB_ACTIONS")
    ENV["JULIA_DEBUG"] = "Documenter"
end

makedocs(
    format = Documenter.HTML(
        prettyurls = haskey(ENV, "GITHUB_ACTIONS"),
        canonical = "https://fredrikekre.github.io/BitTorrent.jl/v1",
    ),
    modules = [BitTorrent],
    sitename = "BitTorrent.jl",
    pages = Any[
        "index.md",
    ]
)

deploydocs(
    repo = "github.com/fredrikekre/BitTorrent.jl.git",
    push_preview=true,
)
