package b1gbb

import "testing"

func BenchmarkHeapPermutations(b *testing.B) {
	for i := 0; i < b.N; i++ {
		p, _ := HeapPermutations(4)
		for range p {
		}
	}
}
