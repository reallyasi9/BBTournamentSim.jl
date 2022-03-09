package main

import (
	"fmt"
	"io"
	"os"
	"strconv"
	"time"

	"github.com/cheggaaa/pb"
	"github.com/reallyasi9/b1g-bbtournament-sim/b1gbb"
	"golang.org/x/exp/rand"
	"gonum.org/v1/gonum/stat/combin"
	"gopkg.in/yaml.v3"
)

func init() {

}

func main() {
	if len(os.Args) != 5 {
		fmt.Printf("Usage: %s <ratings.yaml> <seeds.yaml> <mu> <sigma>\n", os.Args[0])
		os.Exit(2)
	}

	ratingsFile, err := os.Open(os.Args[1])
	if err != nil {
		panic(err)
	}
	defer ratingsFile.Close()

	ratings, err := readRatings(ratingsFile)
	if err != nil {
		panic(err)
	}

	seedsFile, err := os.Open(os.Args[2])
	if err != nil {
		panic(err)
	}
	defer seedsFile.Close()

	seeds, err := readSeeds(seedsFile)
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

	fmt.Println(ratings)
	fmt.Println(seeds)
	fmt.Println(mu)
	fmt.Println(sigma)

	tournament := b1gbb.CreateTournament()
	src := rand.NewSource(uint64(time.Now().UnixNano()))
	model := b1gbb.NewSagarinSimulator(src, mu, sigma, ratings)

	nsims := 1000000
	var h histogram
	for i := 0; i < nsims; i++ {
		simulate(&tournament, model)
		h.accumulate(&tournament)
	}

	d := h.density(nsims)
	best := d.getBest()

	pg := combin.NewPermutationGenerator(13, 13)
	permutations := make(chan []int, 100)
	progbar := pb.StartNew(combin.NumPermutations(13, 13))
	go func(pg *combin.PermutationGenerator) {
		defer close(permutations)
		defer progbar.Finish()
		for pg.Next() {
			permutations <- pg.Permutation(nil)
			progbar.Increment()
		}
	}(pg)

	expectedPoints := make(chan solution, 100)
	go func(perms chan []int) {
		defer close(expectedPoints)
		for perm := range perms {
			if !goodPoints(perm) {
				continue
			}
			var soln solution
			for i, val := range perm {
				soln.points[i] = val + 1
				soln.expectedValue += best[i].prob * float64(soln.points[i])
			}
			expectedPoints <- soln
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
	for game := 0; game < 13; game++ {
		fmt.Printf("Game %d: (%d) %s [%d] -- %f\n", game+1, best[game].winner+1, seeds[best[game].winner], topSoln.points[game], float64(topSoln.points[game])*best[game].prob)
	}
}

func readRatings(r io.Reader) ([]float64, error) {
	d := yaml.NewDecoder(r)
	var out []float64
	err := d.Decode(&out)
	return out, err
}

func readSeeds(r io.Reader) ([]string, error) {
	d := yaml.NewDecoder(r)
	var out []string
	err := d.Decode(&out)
	return out, err
}

func simulate(t *b1gbb.Tournament, m *b1gbb.SagarinSimulator) {
	for game := 0; game < 13; game++ {
		t1, t2 := t.Teams(game)
		w, _ := m.Simulate(t1, t2)
		slot := b1gbb.WinnerTo(game)
		t.SetTeam(slot, w)
	}
}

type histogram [13][14]int64

func (h *histogram) accumulate(t *b1gbb.Tournament) {
	for game := 0; game < 13; game++ {
		winner := t.GetWinner(game)
		h[game][winner]++
	}
}

type winsDensity [13][14]float64

func (h *histogram) density(nsims int) winsDensity {
	var d winsDensity
	for game := 0; game < 13; game++ {
		for winner := 0; winner < 14; winner++ {
			d[game][winner] = float64(h[game][winner]) / float64(nsims)
		}
	}
	return d
}

type winnerProb struct {
	winner int
	prob   float64
}

func (d *winsDensity) getBest() [13]winnerProb {
	var wp [13]winnerProb
	for game := 0; game < 13; game++ {
		for winner := 0; winner < 14; winner++ {
			p := d[game][winner]
			if p > wp[game].prob {
				wp[game].winner = winner
				wp[game].prob = p
			}
		}
	}
	return wp
}

type solution struct {
	points        [13]int
	expectedValue float64
}

func goodPoints(perm []int) bool {
	// each generation must have at least 5 points assigned
	var gentotal int
	for i := 0; i < 2; i++ {
		gentotal += perm[i] + 1
	}
	if gentotal < 5 {
		return false
	}
	gentotal = 0
	for i := 2; i < 6; i++ {
		gentotal += perm[i] + 1
	}
	if gentotal < 5 {
		return false
	}
	for i := 6; i < 10; i++ {
		gentotal += perm[i] + 1
	}
	if gentotal < 5 {
		return false
	}
	for i := 10; i < 12; i++ {
		gentotal += perm[i] + 1
	}
	if gentotal < 5 {
		return false
	}
	if perm[12]+1 < 5 {
		return false
	}
	return true
}
