package main

import (
	"fmt"
	"os"
	"sort"
	"strconv"
	"time"

	"golang.org/x/exp/rand"

	"github.com/reallyasi9/b1g-bbtournament-sim/internal/b1gbb"
)

func init() {

}

func main() {
	if len(os.Args) != 7 {
		fmt.Printf("Usage: %s <teams.yaml> <picks.yaml> <completed.yaml> <mu> <sigma>\n", os.Args[0])
		os.Exit(2)
	}

	ratingsFile, err := os.Open(os.Args[1])
	if err != nil {
		panic(err)
	}
	defer ratingsFile.Close()

	teams, err := b1gbb.ReadTeams(ratingsFile)
	if err != nil {
		panic(err)
	}

	picksFile, err := os.Open(os.Args[2])
	if err != nil {
		panic(err)
	}
	defer picksFile.Close()
	picks, err := b1gbb.ReadPicks(picksFile)
	if err != nil {
		panic(err)
	}

	completedFile, err := os.Open(os.Args[3])
	if err != nil {
		panic(err)
	}
	defer completedFile.Close()
	completed, err := b1gbb.ReadCompleted(completedFile)
	if err != nil {
		panic(err)
	}

	mu, err := strconv.ParseFloat(os.Args[4], 64)
	if err != nil {
		panic(err)
	}

	sigma, err := strconv.ParseFloat(os.Args[6], 64)
	if err != nil {
		panic(err)
	}

	ratings := make([]float64, len(teams))
	seeds := make([]int, len(teams))
	for i, t := range teams {
		ratings[i] = t.Rating
		seeds[i] = t.Seed
	}

	tournament := b1gbb.CreateTournament()
	src := rand.NewSource(uint64(time.Now().UnixNano()))
	model := b1gbb.NewSagarinSimulator(src, mu, sigma, ratings)

	nsims := 1000000
	pa := b1gbb.NewPickerAccumulator(picks)
	for i := 0; i < nsims; i++ {
		b1gbb.SimulatePartial(&tournament, model, completed)
		pa.Accumulate(&tournament)
	}

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
