#!/opt/homebrew/bin/fish

set OUTDIR ~/Documents/b1g-bbtournament-sim
set CURRENT_YEAR (date +%Y)
set LEAGUES "ncaaw" "ncaam"
set COMPETITIONS "cid" "mpr"
set COMP_VALUES "" ""

for i in (seq 1 32)
    set COMP_VALUES[1] (string join " " $COMP_VALUES[1] "1")
    set COMP_VALUES[2] (string join " " $COMP_VALUES[2] "3")
end
for i in (seq 1 16)
    set COMP_VALUES[1] (string join " " $COMP_VALUES[1] "2")
    set COMP_VALUES[2] (string join " " $COMP_VALUES[2] "4")
end
for i in (seq 1 8)
    set COMP_VALUES[1] (string join " " $COMP_VALUES[1] "4")
    set COMP_VALUES[2] (string join " " $COMP_VALUES[2] "6")
end
set COMP_VALUES[1] (string join " " $COMP_VALUES[1] "8 8 8 8 16 16 32")
set COMP_VALUES[2] (string join " " $COMP_VALUES[2] "8 8 8 8 12 12 20")

for league in $LEAGUES
    for i in (seq 2)
        set comp $COMPETITIONS[$i]

        mkdir -p $OUTDIR/$comp/$league/teams
        mkdir -p $OUTDIR/$comp/$league/brackets
        mkdir -p $OUTDIR/$comp/$league/rpi

        eval "julia --project=. generate-bracket-shell.jl $league --values" (string join ' ' {$COMP_VALUES[$i]}) "-o $OUTDIR/$comp/$league/brackets/shell-$CURRENT_YEAR.json"
        julia --project=. download-cbs-teams.jl $league -o $OUTDIR/$comp/$league/teams/map-$CURRENT_YEAR.json
        if test -e $OUTDIR/$comp/$league/rpi/rpi-shell.json
            echo "RPI file already exists, refusing to overwrite"
        else
            julia --project=. download-rpi.jl $league -o $OUTDIR/$comp/$league/rpi/rpi-shell.json
        end
        echo "Update $OUTDIR/$comp/$league/rpi/rpi-shell.json with proper seed quadrant values, then proceed with running julia --project=. make-tournament.jl"
    end
end