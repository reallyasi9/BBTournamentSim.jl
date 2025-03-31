#!/opt/homebrew/bin/fish

set OUTDIR ~/Documents/b1g-bbtournament-sim
set CURRENT_YEAR (date +%Y)
set LEAGUES "ncaaw" "ncaam"
set COMPETITIONS "cid" "mpr"
# by competition, cid first
set PIDS "L:1:P3UlkdfrP7pM+Zwq85DZNA==:1" "L:1:hqGSrEVSEEfGfMDR/1dM8g==:1"
# by pool, cid ncaaw first, then mpr ncaaw, then cid ncaam, then mpr ncaam
set POOL_IDS "kbxw63b2geztimbxguztq===" "kbxw63b2geztmmzqgyytg===" "kbxw63b2geztcnzwgq4ti===" "kbxw63b2geztmmzsgaztc==="

set ipool 1
for ileague in (seq 2)
    set league $LEAGUES[$ileague]
    for icomp in (seq 2)
        set comp $COMPETITIONS[$icomp]
        set pool $POOL_IDS[$ipool]
        set ipool (math $ipool + 1)

        mkdir -p $OUTDIR/$comp/$league/picks

        julia --project=. download-cbs-picks.jl "$PIDS[$icomp]" "$pool" $league $OUTDIR/$comp/$league/teams/map-$CURRENT_YEAR.json $OUTDIR/$comp/$league/teams/seeds-$CURRENT_YEAR.json -o $OUTDIR/$comp/$league/picks/picks-$CURRENT_YEAR.json

        echo "Picks downloaded: update $OUTDIR/$comp/$league/tournaments/tournament-shell-$CURRENT_YEAR.json with winners, then proceed with scoring picks, simulating remaining games, and scoring simulations"
    end
end