#!/opt/homebrew/bin/fish

set OUTDIR ~/Documents/b1g-bbtournament-sim
set CURRENT_DATE (date +%Y-%m-%d)
set LEAGUES "ncaaw" "ncaam"
set COMPETITIONS "cid" "mpr"

set fish_trace 1

for league in $LEAGUES
    for comp in $COMPETITIONS
        mkdir -p $OUTDIR/$comp/$league/plots

        julia --project=. plot-excite-o-matic.jl $OUTDIR/$comp/$league/tournaments/tournament-$CURRENT_DATE.json $OUTDIR/$comp/$league/output/posteriors-$CURRENT_DATE.parquet $OUTDIR/$comp/$league/output/exciteo-$CURRENT_DATE.parquet -o $OUTDIR/$comp/$league/plots/exciteo-$CURRENT_DATE.svg

        julia --project=. plot-ranks.jl $OUTDIR/$comp/$league/output/posteriors-$CURRENT_DATE.parquet -o $OUTDIR/$comp/$league/plots/ranks-$CURRENT_DATE.svg
    end
end