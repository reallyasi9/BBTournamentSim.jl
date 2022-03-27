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
	Winners map[int]int
	Points  map[int]int
}

func ReadPicks(r io.Reader) (map[string]Picks, error) {
	d := yaml.NewDecoder(r)
	var out map[string]Picks
	err := d.Decode(&out)
	return out, err
}

type PointsRule struct {
	Games   []int
	Minimum int
}

type Points struct {
	Values []int
	Rules  []PointsRule
}

func (p Points) ValidPoints(perm []int) bool {
	for _, rule := range p.Rules {
		sum := 0
		for _, game := range rule.Games {
			sum += p.Values[perm[game-1]]
		}
		if sum < rule.Minimum {
			return false
		}
	}
	return true
}

type TournamentStructure struct {
	NTeams      int `yaml:"nTeams"`
	Matchups    [][2]int
	Progression [][2]int
	Winners     map[int]int
	Points      Points
}

func ReadTournamentStructure(r io.Reader) (TournamentStructure, error) {
	d := yaml.NewDecoder(r)
	var out TournamentStructure
	err := d.Decode(&out)
	return out, err
}
