package main

import (
	"flag"
	"fmt"
	"os"
	"sort"
	"strconv"
	"sync"
	"time"

	"golang.org/x/exp/rand"

	"github.com/cheggaaa/pb"
	"github.com/reallyasi9/b1g-bbtournament-sim/internal/b1gbb"
)

var bias float64
var seed uint64
var nsims int

const nworkers = 32

func init() {
	flag.Float64Var(&bias, "bias", 0, "Bias of model in favor of top team (default: 0)")
	flag.Uint64Var(&seed, "seed", 0, "RNG seed for simulations (default: use system clock)")
	flag.IntVar(&nsims, "sims", 0, "Number of tournament simulations to run (default: 1,000,000)")
	// flag.IntVar(&nworkers, "workers", 32, "Number of accumulator worker goroutines (default: 32)")
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

	tournament, err := b1gbb.NewTournament(tournamentStructure)
	if err != nil {
		panic(err)
	}
	if seed == 0 {
		seed = uint64(time.Now().UnixNano())
	}
	src := rand.NewSource(seed)

	if nsims <= 0 {
		nsims = 1000000
	}

	prog1 := pb.StartNew(nsims)
	prog1.Prefix("Simulating")

	tchan := make(chan b1gbb.Tournament, 100)
	go func() {
		defer close(tchan)
		var wg sync.WaitGroup
		for i := 0; i < nsims; i++ {
			wg.Add(1)
			src2 := rand.NewSource(src.Uint64())
			model := b1gbb.NewGameSimulator(src2, bias, sigma, ratings)
			go func() {
				defer wg.Done()
				t := tournament.Clone()
				itr := t.ReadyGameIterator()
				for itr.Next() {
					game := itr.Game()
					rankings, _ := model.Simulate(game)
					t.Propagate(game.Id(), 0, rankings[0])
				}
				tchan <- t
			}()
		}
		wg.Wait()
	}()

	workers := make([]*b1gbb.PickerAccumulator, nworkers)
	for i := 0; i < nworkers; i++ {
		// listen for tournaments
		workers[i] = b1gbb.NewPickerAccumulator(picks)
	}
	var wg sync.WaitGroup
	for i := 0; i < nworkers; i++ {
		wg.Add(1)
		go func(j int) {
			defer wg.Done()
			for t := range tchan {
				workers[j].Accumulate(t)
				prog1.Increment()
			}
		}(i)
	}
	wg.Wait()
	prog1.Finish()
	for len(workers) > 1 {
		n := len(workers)
		for i := 0; i < n/2; i++ {
			// only works for len(workers) a power of 2
			workers[i].Add(workers[i+n/2])
		}
		workers = workers[:n/2]
	}
	pa := workers[0]

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
	// nready := len(tournament.FirstGames(nil)) * 2
	for _, e := range excitement {
		bestT, bestF := e.MostExciting(-1)
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
