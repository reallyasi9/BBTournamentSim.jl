package main

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/cheggaaa/pb"
	"github.com/reallyasi9/b1g-bbtournament-sim/internal/b1gbb"
	"golang.org/x/exp/rand"
	"gonum.org/v1/gonum/stat/combin"
)

func init() {
}

func main() {
	if len(os.Args) != 5 {
		fmt.Printf("Usage: %s <tournament.yaml> <ratings.yaml> <mu> <sigma>\n", os.Args[0])
		os.Exit(2)
	}

	tournamentFile, err := os.Open(os.Args[1])
	if err != nil {
		panic(err)
	}
	defer tournamentFile.Close()

	tournamentStructure, err := b1gbb.ReadTournamentStructure(tournamentFile)
	if err != nil {
		panic(err)
	}

	teamsFile, err := os.Open(os.Args[2])
	if err != nil {
		panic(err)
	}
	defer tournamentFile.Close()

	teams, err := b1gbb.ReadTeams(teamsFile)
	if err != nil {
		panic(err)
	}

	mu, err := strconv.ParseFloat(os.Args[3], 64)
	if err != nil {
		panic(err)
	}

	sigma, err := strconv.ParseFloat(os.Args[4], 64)
	if err != nil {
		panic(err)
	}

	tournament, err := b1gbb.NewTournament(tournamentStructure)
	if err != nil {
		panic(err)
	}

	names := make([]string, len(teams))
	ratings := make([]float64, len(teams))
	seeds := make([]int, len(teams))
	for i, team := range teams {
		names[i] = team.Name
		ratings[i] = team.Rating
		seeds[i] = team.Seed
	}
	src := rand.NewSource(uint64(time.Now().UnixNano()))
	model := b1gbb.NewSagarinSimulator(src, mu, sigma, ratings)

	nsims := 10000000
	h := b1gbb.NewHistogram(names)

	prog1 := pb.StartNew(nsims)
	prog1.Prefix("Simulating")
	for i := 0; i < nsims; i++ {
		b1gbb.Simulate(tournament, model)
		h.Accumulate(tournament)
		prog1.Increment()
	}
	prog1.Finish()

	d := h.Density()
	best := d.GetBest()
	fmt.Println(best)

	permutations, _ := b1gbb.HeapPermutations(13)
	prog2 := pb.StartNew(combin.NumPermutations(13, 13))
	prog2.Prefix("Optimizing")

	expectedPoints := make(chan solution, 100)
	go func(perms chan []int) {
		defer close(expectedPoints)
		defer prog2.Finish()
		for perm := range perms {
			prog2.Increment()
			if !goodPoints(perm) {
				continue
			}
			expectedPoints <- makeSolution(perm, best)
		}
	}(permutations)

	// best finder
	var topSoln solution
	for soln := range expectedPoints {
		if soln.expectedValue > topSoln.expectedValue {
			topSoln.points = soln.points
			topSoln.expectedValue = soln.expectedValue
			fmt.Printf("New best solution: %v\n", topSoln)
		}
	}

	fmt.Printf("Best solution: %v\n", topSoln)
	for game := 0; game < len(best); game++ {
		fmt.Printf("Game %d: (%d) %s [%d] @ %f = %f\n", game+1, best[game].Winner+1, names[best[game].Winner], topSoln.points[game], best[game].Prob, float64(topSoln.points[game])*best[game].Prob)
	}
}

type solution struct {
	points        []int
	expectedValue float64
}

func makeSolution(permutation []int, wp []b1gbb.WinnerProb) solution {
	points := make([]int, len(permutation))
	var exp float64
	for i, val := range permutation {
		points[i] = val + 1
		exp += wp[i].Prob * float64(val+1)
	}
	return solution{
		points:        points,
		expectedValue: exp,
	}
}

func goodPoints(perm []int) bool {
	// each generation must have at least 5 points assigned
	return (perm[0]+perm[1]+2 >= 5) && (perm[10]+perm[11]+2 >= 5) && (perm[12]+1 >= 5)
}
