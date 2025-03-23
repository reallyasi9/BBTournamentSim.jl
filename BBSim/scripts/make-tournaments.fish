#!/opt/homebrew/bin/fish

set OUTDIR ~/Documents/b1g-bbtournament-sim
set CURRENT_YEAR (date +%Y)
set LEAGUES "ncaaw" "ncaam"
set COMPETITIONS "cid" "mpr"

for league in $LEAGUES
    for comp in $COMPETITIONS

        echo "Tournament shell created: update $OUTDIR/$comp/$league/tournaments/tournament-shell-$CURRENT_YEAR.json with winners, then proceed with scoring picks, simulating remaining games, and scoring simulations"
    end
end