package main

import (
	"fmt"
	"io"
	"os"
	"strconv"
	"time"

	"github.com/reallyasi9/b1g-bbtournament-sim/b1gbb"
	"golang.org/x/exp/rand"
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

	for game := 0; game < 13; game++ {
		t1, t2 := tournament.Teams(game)
		w, p := model.Simulate(t1, t2)
		fmt.Printf("Game %d: %s (%d) vs. %s (%d) -- %s (%d) wins (%f)\n", game, seeds[t1], t1, seeds[t2], t2, seeds[w], w, p)
		slot := b1gbb.WinnerTo(game)
		tournament.SetTeam(slot, w)
	}

	fmt.Println(tournament)
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
