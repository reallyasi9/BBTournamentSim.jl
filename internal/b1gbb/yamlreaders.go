package b1gbb

import (
	"io"
	"sort"

	"gopkg.in/yaml.v3"
)

type TeamStats struct {
	Name   string
	Seed   int
	Rating float64
}

type teamStatsBySeed []TeamStats

func (a teamStatsBySeed) Len() int {
	return len(a)
}
func (a teamStatsBySeed) Less(i, j int) bool {
	return a[i].Seed < a[j].Seed
}
func (a teamStatsBySeed) Swap(i, j int) {
	a[i], a[j] = a[j], a[i]
}

func ReadTeams(r io.Reader) (teamStatsBySeed, error) {
	d := yaml.NewDecoder(r)
	var out []TeamStats
	err := d.Decode(&out)
	bySeed := teamStatsBySeed(out)
	sort.Sort(bySeed)
	return bySeed, err
}

type Picks struct {
	Winners []int
	Points  []int
}

func ReadPicks(r io.Reader) (map[string]Picks, error) {
	d := yaml.NewDecoder(r)
	var out map[string]Picks
	err := d.Decode(&out)
	return out, err
}

func ReadCompleted(r io.Reader) (map[int]int, error) {
	d := yaml.NewDecoder(r)
	var out map[int]int
	err := d.Decode(&out)
	return out, err
}
