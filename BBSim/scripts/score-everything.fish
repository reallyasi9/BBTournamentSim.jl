#!/opt/homebrew/bin/fish

set OUTDIR ~/Documents/b1g-bbtournament-sim
set CURRENT_YEAR (date +%Y)
set CURRENT_DATE (date +%Y-%m-%d)
set LEAGUES "ncaaw" "ncaam"
set COMPETITIONS "cid" "mpr"

set fish_trace 1

for league in $LEAGUES
    for comp in $COMPETITIONS
        julia --project=. update-rpi.jl $OUTDIR/$comp/$league/rpi/rpi-shell.json $league -o $OUTDIR/$comp/$league/rpi/rpi-$CURRENT_DATE.json

        mkdir -p $OUTDIR/$comp/$league/tournaments
        julia --project=. make-tournament.jl $OUTDIR/$comp/$league/brackets/shell-$CURRENT_YEAR.json $OUTDIR/$comp/$league/rpi/rpi-$CURRENT_DATE.json -o $OUTDIR/$comp/$league/tournaments/tournament-$CURRENT_DATE.json
        
        julia --project=. convert-picks.jl $OUTDIR/$comp/$league/picks/picks-$CURRENT_YEAR.json $OUTDIR/$comp/$league/rpi/rpi-$CURRENT_DATE.json -o $OUTDIR/$comp/$league/picks/picks-merged-$CURRENT_DATE.json

        mkdir -p $OUTDIR/$comp/$league/output
        julia --project=. simulate-remaining.jl $OUTDIR/$comp/$league/tournaments/tournament-$CURRENT_DATE.json $OUTDIR/models/rpi-gaussian.json -o $OUTDIR/$comp/$league/output/simulations-$CURRENT_DATE.parquet
        julia --project=. score-picks.jl $OUTDIR/$comp/$league/tournaments/tournament-$CURRENT_DATE.json $OUTDIR/$comp/$league/picks/picks-merged-$CURRENT_DATE.json $OUTDIR/$comp/$league/output/simulations-$CURRENT_DATE.parquet -r $OUTDIR/$comp/$league/output/rankfile-$CURRENT_DATE.csv -p $OUTDIR/$comp/$league/output/posteriors-$CURRENT_DATE.parquet
        julia --project=. score-simulations.jl $OUTDIR/$comp/$league/tournaments/tournament-$CURRENT_DATE.json $OUTDIR/$comp/$league/output/posteriors-$CURRENT_DATE.parquet $OUTDIR/$comp/$league/output/simulations-$CURRENT_DATE.parquet -e $OUTDIR/$comp/$league/output/expecto-$CURRENT_DATE.csv -x $OUTDIR/$comp/$league/output/exciteo-$CURRENT_DATE.parquet
        
    end
end