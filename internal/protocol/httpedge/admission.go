package httpedge

import "errors"

var ErrSaturated = errors.New("http edge saturated")

type Admission struct{ ch chan struct{} }

func NewAdmission(max int) (*Admission, error) {
	if max <= 0 {
		return nil, errors.New("max in-flight must be positive")
	}
	return &Admission{ch: make(chan struct{}, max)}, nil
}
func (a *Admission) TryAcquire() bool {
	select {
	case a.ch <- struct{}{}:
		return true
	default:
		return false
	}
}
func (a *Admission) Release() { <-a.ch }
