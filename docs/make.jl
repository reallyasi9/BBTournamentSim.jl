using BBTournamentSim
using Documenter

DocMeta.setdocmeta!(BBTournamentSim, :DocTestSetup, :(using BBTournamentSim); recursive=true)

makedocs(;
    modules=[BBTournamentSim],
    authors="Phil Killewald <reallyasi9@users.noreply.github.com> and contributors",
    sitename="BBTournamentSim.jl",
    format=Documenter.HTML(;
        canonical="https://reallyasi9.github.io/BBTournamentSim.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/reallyasi9/BBTournamentSim.jl",
    devbranch="main",
)
