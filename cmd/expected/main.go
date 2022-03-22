package main

import (
	"flag"
	"fmt"
	"os"
	"sort"
	"strconv"
	"time"

	"golang.org/x/exp/rand"

	"github.com/cheggaaa/pb"
	"github.com/reallyasi9/b1g-bbtournament-sim/internal/b1gbb"
)

var bias float64
var seed uint64
var nsims int

func init() {
	flag.Float64Var(&bias, "bias", 0, "Bias of model in favor of top team (default: 0)")
	flag.Uint64Var(&seed, "seed", 0, "RNG seed for simulations (default: use system clock)")
	flag.IntVar(&nsims, "sims", 0, "Number of tournament simulations to run (default: 100,000 per remaining game)")
}

func main() {
	flag.Parse()

	if flag.NArg() != 4 {
		fmt.Printf("Usage: %s <tournament.yaml> <teams.yaml> <picks.yaml> <sigma>\n", os.Args[0])
		os.Exit(2)
	}

	tournamentFile, err := os.Open(flag.Arg(0))
	if err != nil {
		panic(err)
	}
	defer tournamentFile.Close()
	tournamentStructure, err := b1gbb.ReadTournamentStructure(tournamentFile)
	if err != nil {
		panic(err)
	}

	ratingsFile, err := os.Open(flag.Arg(1))
	if err != nil {
		panic(err)
	}
	defer ratingsFile.Close()

	teams, err := b1gbb.ReadTeams(ratingsFile)
	if err != nil {
		panic(err)
	}

	picksFile, err := os.Open(flag.Arg(2))
	if err != nil {
		panic(err)
	}
	defer picksFile.Close()
	picks, err := b1gbb.ReadPicks(picksFile)
	if err != nil {
		panic(err)
	}

	sigma, err := strconv.ParseFloat(flag.Arg(3), 64)
	if err != nil {
		panic(err)
	}

	names := make([]string, len(teams))
	ratings := make([]float64, len(teams))
	seeds := make([]int, len(teams))
	for i, t := range teams {
		names[i] = t.Name
		ratings[i] = t.Rating
		seeds[i] = t.Seed
	}

	tournament, err := b1gbb.NewTournament(tournamentStructure, names)
	if err != nil {
		panic(err)
	}
	if seed == 0 {
		seed = uint64(time.Now().UnixNano())
	}
	src := rand.NewSource(seed)
	model := b1gbb.NewSagarinSimulator(src, bias, sigma, ratings)

	if nsims <= 0 {
		nsims = tournament.RemainingMatchups() * 100000
	}
	pa := b1gbb.NewPickerAccumulator(picks)
	prog1 := pb.StartNew(nsims)
	prog1.Prefix("Simulating")
	for i := 0; i < nsims; i++ {
		b1gbb.SimulatePartial(tournament, model)
		pa.Accumulate(tournament)
		prog1.Increment()
	}
	prog1.Finish()

	outcomes := pa.ExpectedValues()
	sort.Sort(sort.Reverse(ByWins(outcomes)))
	fmt.Println("\nPickers with a chance to win:")
	for i, o := range outcomes {
		if o.Wins == 0 {
			continue
		}
		fmt.Printf("%d. %s (%0.1f%%)\n", i+1, o.Picker, o.Wins*100)
	}
	sort.Sort(sort.Reverse(ByPoints(outcomes)))
	fmt.Println("\nLikely points:")
	for i, o := range outcomes {
		fmt.Printf("%d. %s (%0.1f)\n", i+1, o.Picker, o.Points)
	}
	sort.Sort(sort.Reverse(ByCorrect(outcomes)))
	fmt.Println("\nLikely number of correct picks:")
	for i, o := range outcomes {
		fmt.Printf("%d. %s (%0.2f)\n", i+1, o.Picker, o.Correct)
	}

	excitement := pa.ExcitementValues()
	sort.Sort(ByPicker(excitement))
	fmt.Println("\nMost exciting games per picker:")
	nready := len(tournament.FirstGames(nil)) * 2
	for _, e := range excitement {
		bestT, bestF := e.MostExciting(nready)
		fmt.Printf("%s:\n", e.Picker)
		for i := 0; i < len(bestT); i++ {
			// if bestF[i] < 1 {
			// 	continue
			// }
			fmt.Printf("\t%s (%0.2f)\n", teams[bestT[i]].Name, bestF[i])
		}
	}
}

type ByPoints []b1gbb.ExpectedValues

func (b ByPoints) Len() int {
	return len(b)
}
func (b ByPoints) Less(i, j int) bool {
	return b[i].Points < b[j].Points
}
func (b ByPoints) Swap(i, j int) {
	b[i], b[j] = b[j], b[i]
}

type ByWins []b1gbb.ExpectedValues

func (b ByWins) Len() int {
	return len(b)
}
func (b ByWins) Less(i, j int) bool {
	return b[i].Wins < b[j].Wins
}
func (b ByWins) Swap(i, j int) {
	b[i], b[j] = b[j], b[i]
}

type ByCorrect []b1gbb.ExpectedValues

func (b ByCorrect) Len() int {
	return len(b)
}
func (b ByCorrect) Less(i, j int) bool {
	return b[i].Correct < b[j].Correct
}
func (b ByCorrect) Swap(i, j int) {
	b[i], b[j] = b[j], b[i]
}

type ByPicker []b1gbb.ExcitementValues

func (b ByPicker) Len() int {
	return len(b)
}
func (b ByPicker) Less(i, j int) bool {
	return b[i].Picker < b[j].Picker
}
func (b ByPicker) Swap(i, j int) {
	b[i], b[j] = b[j], b[i]
}
