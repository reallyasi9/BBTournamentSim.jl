package b1gbb

import (
	"io"

	"gopkg.in/yaml.v3"
)

func ReadRatings(r io.Reader) ([]float64, error) {
	d := yaml.NewDecoder(r)
	var out []float64
	err := d.Decode(&out)
	return out, err
}

func ReadSeeds(r io.Reader) ([]string, error) {
	d := yaml.NewDecoder(r)
	var out []string
	err := d.Decode(&out)
	return out, err
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
