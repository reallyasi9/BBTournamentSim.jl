package b1gbb

// Algorithms are from https://www.princeton.edu/~rblee/ELE572Papers/p137-sedgewick.pdf with modifications for go's syntax and use of channels.

func HeapPermutations(n int) (chan []int, error) {
	// Heap's algorithm, copy to channel output, non recursive
	p := make(chan []int, 100)
	c := make([]int, n)
	a := make([]int, n)
	for i := 0; i < n; i++ {
		c[i] = 0
		a[i] = i
	}
	outputCopy(a, p)

	go func() {
		defer close(p)
		i := 0
		for i < n {
			if c[i] < i {
				if i%2 == 0 {
					a[0], a[i] = a[i], a[0]
				} else {
					a[c[i]], a[i] = a[i], a[c[i]]
				}
				outputCopy(a, p)
				c[i]++
				i = 0
			} else {
				c[i] = 0
				i++
			}
		}
	}()

	return p, nil
}

type HeapPermutor struct {
	n     int
	c     []int
	a     []int
	i     int
	first bool
	done  bool
}

func NewHeapPermutor(n int) *HeapPermutor {
	c := make([]int, n)
	a := make([]int, n)
	itr := HeapPermutor{
		n: n,
		c: c,
		a: a,
	}
	itr.Reset()
	return &itr
}

func (itr *HeapPermutor) Reset() {
	for i := 0; i < itr.n; i++ {
		itr.c[i] = 0
		itr.a[i] = i
	}
	itr.i = 0
	itr.first = true
	itr.done = false
}

func (itr *HeapPermutor) Next() bool {
	if itr.done {
		return false
	}
	if itr.first {
		itr.first = false
		return true
	}
	for itr.i < itr.n {
		if itr.c[itr.i] < itr.i {
			if itr.i%2 == 0 {
				itr.a[0], itr.a[itr.i] = itr.a[itr.i], itr.a[0]
			} else {
				itr.a[itr.c[itr.i]], itr.a[itr.i] = itr.a[itr.i], itr.a[itr.c[itr.i]]
			}
			itr.c[itr.i]++
			itr.i = 0
			return true
		} else {
			itr.c[itr.i] = 0
			itr.i++
		}
	}
	itr.done = true
	return false
}

func (itr *HeapPermutor) Permutation(dst []int) []int {
	if dst == nil {
		dst = make([]int, itr.n)
	}
	copy(dst, itr.a)
	return dst
}

func outputCopy(a []int, out chan []int) {
	x := make([]int, len(a))
	copy(x, a)
	out <- x
}
