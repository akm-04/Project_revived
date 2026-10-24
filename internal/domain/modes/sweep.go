package modes

import "errors"

var ErrSweepRefused = errors.New("sweep refused")

const fullStars = 3

// AdmitSweep is the shared sweep law: only a three-star stage sweeps, between 1 and limit times in one request.
func AdmitSweep(star, count, limit int64) error {
	if star != fullStars || count < 1 || count > limit {
		return ErrSweepRefused
	}
	return nil
}
