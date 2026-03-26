# BBTournamentSim

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://reallyasi9.github.io/BBTournamentSim.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://reallyasi9.github.io/BBTournamentSim.jl/dev/)
[![Build Status](https://github.com/reallyasi9/BBTournamentSim.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/reallyasi9/BBTournamentSim.jl/actions/workflows/CI.yml?query=branch%3Amain)

Simulate yer NCAA basketball tournament bracket pools!

## Instructions

### 1. Instantiate project(s)

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()

Pkg.activate("./scripts")
Pkg.develop(path="../")
Pkg.instantiate()
```

### 2. Generate bracket shell

```shell
julia --project=scripts scripts/generate-bracket-shell.jl <ncaaw|ncaam> [--values gm1_val gm2_val ...] [-o outpath/bracket-shell.json]
```

### 3. Download team data (CBS version)
```shell
julia --project=scripts scripts/download-cbs-teams.jl <ncaaw|ncaam> [-o outpath/team-map.json]
```

### 4. (**MANUAL**) Update power ratings shell with proper seed and quadrant values

Open `outpath/moore-shell.json` and assign the appropriate "seed" and "quadrant" values for all the teams in the tournament. The "seed" values should run from 1 to 16, and the "quadrant" values are selected from the set "NW", "NE", "SW", and "SE" for the north-west (upper-left), north-east (upper-right), south-west (lower-left), and south-east (lower-right) starting 16 teams, respectively.

### 5. (**MANUAL**) Create a power ratings simulation configuration

Based on information recorded at [ThePredictionTracker](http://thepredictiontracker.com), create a file `outpath/moore-config.json` with a structure similar to the following:

```json
{
    "type": "gaussian",
    "mean": 0.0,
    "std": 10.00
}
```

### 6. (**MANUAL**) Create team name-to-seed mapping (CBS version)

Create a file `outdir/seeds.json` that consists of a single JSON object with keys equal to the team names (the values of the JSON object created in step 3) and values equal to quadrant-string values (the concatenated "quadrant" values and "seed" values entered in step 5). For example, if the team named "Gonzaga" is the 3rd seed in the north-east quadrant, one of the entries in the `outdir/seeds.json` file will be `{... "Gonzaga": "NE3", ...}`.

### 7. Download picks (CBS version)

Navigate a web browser to the CBS bracket pool website containing the entries that you want to download. Make note of:

1. The pool ID, which should be a string of random characters in the path of the URL of the bracket pool standings page. For example, is the URL of the standings page is `https://picks.cbssports.com/college-basketball/ncaa-tournament/bracket/pools/kbxw67du454d5k76fdi===/standings`, then the pool ID is `kbxw67du454d5k76fdi===`.

2. The PID cookie value, which you will have to extract from the HTTP request information through your browser's developer tools.

With these in hand:

```shell
julia --project=scripts scripts/download-cbs-picks.jl <PID> <POOL_ID> <ncaaw|ncaam> <outpath/team-map.json> <outpath/seeds.json> [-o outpath/picks.json]
```

### 7. Download picks (B1G Pick'Em version)

Download the picks Google Sheet as an Excel document, then:

```shell
julia --project=scripts scripts/read-b1g-spreadsheet.jl <downloads/picks-sheet.xlsx> <col1 col2 ...> [-s Picks] [-o outpath/picks.json]
```

The `col1 col2...` arguments are the column letters (in Excel notation) corresponding to the pickers who are active in the tournament. Check the spreadsheet to see which columns in the `Picks` sheet are unhidden.

### 8. Download power ratings

```shell
julia --project=scripts scripts/download-moore.jl <ncaaw|ncaam> [-o outpath/moore-shell.json]
```

### 9. (**MANUAL**) Update winners

Update the bracket tournament shell, created in step 2, with the winners of each game. The winner of each game is specified by the quadrant-seed combination. For example, if the `"teams"` field of the first game object in the tournament shell is defined as `["NW1", "NW16"]`, and the first seed won the game, then create a new field in the game object called `"winner"` with the value `"NW1"`. The complete game JSON object would be:

```json
{
    "game": 1,
    "teams": [
        "NW1",
        "NW16"
    ],
    "quadrant": "NW",
    "league": "ncaaw",
    "value": 1,
    "winner": "NW1"
}
```

Optionally, propagate the winners to the `"teams"` fields of the next games they play in. The simulation code should handle this automatically, but manually specifying the teams in each game rather than just the winners of the feeder games speeds up the simulation process.

### 10. Update power ratings

```shell
julia --project=scripts scripts/update-moore.jl <outpath/moore-shell.json> <ncaaw|ncaam> [-o outpath/moore-updated.json]
```

### 11. Combine all shells into a complete tournament status file

```shell
julia --project=scripts scripts/make-tournament.jl <outpath/bracket-shell-updated.json> <outpath/moore-updated.json> [-o outpath/tournament.json]

julia --project=scripts scripts/convert-picks.jl <outpath/picks.json> <outpath/moore-updated.json> [-o outpath/picks-updated.json]
```

### 12. Simulate remaining games

```shell
julia --project=scripts scripts/simulate-remaining.jl [-n NUM_SIMS] <outpath/tournament.json> <outpath/moore-config.json> [-o outpath/simulations.parquet]
```

### 13. Score picks based on simulations

```shell
julia --project=scripts scripts/score-picks.jl <outpath/tournament.json> <outpath/picks-updated.json> <outpath/simulations.parquet> [-r outpath/rankfile.csv] [-p outpath/posteriors.parquet]
```

### 14. Compute Expect-o-Matic and Excite-o-Matic

```shell
julia --project=scripts scripts/score-simulations.jl <outpath/tournament.json> <outpath/posteriors.parquet> <outpath/simulations.parquet> [-e outpath/expecto.csv] [-x outpath/exciteo.parquet]
```

### 15. Plot Expect-o-Matic and Excite-o-Matic

```shell
julia --project=scripts scripts/plot-ranks.jl <outpath/posteriors.parquet> [-o outpath/ranks.svg]

julia --project=scripts scripts/plot-excite-o-matic.jl <outpath/tournament> <outpath/posteriors.parquet> <outpath/exciteo.parquet> [-o outpath/exciteo.svg]
```

### GOTO 7