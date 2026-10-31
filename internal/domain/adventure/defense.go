package adventure

// DefenseProgress counts the C5 challenge tries of one player per monster
// position inside one occurrence. The counter resets only with a new occurrence.
type DefenseProgress struct {
	Tries [DefenseMonsterCount]int64 `json:"tries"`
}

func (p DefenseProgress) Validate() error {
	for _, tries := range p.Tries {
		if tries < 0 || tries > DefenseTriesPerPosition {
			return ErrInvalid
		}
	}
	return nil
}

func (p DefenseProgress) index(position int64) (int, bool) {
	if position < 1 || position > DefenseMonsterCount {
		return 0, false
	}
	return int(position - 1), true
}

func (p DefenseProgress) CanChallenge(position int64) bool {
	index, ok := p.index(position)
	return ok && p.Tries[index] < DefenseTriesPerPosition
}

// Admit consumes one try of a monster position. The third try is the last one.
func (p DefenseProgress) Admit(position int64) (DefenseProgress, error) {
	index, ok := p.index(position)
	if !ok {
		return p, ErrInvalid
	}
	if p.Tries[index] >= DefenseTriesPerPosition {
		return p, ErrRefused
	}
	p.Tries[index]++
	return p, nil
}
