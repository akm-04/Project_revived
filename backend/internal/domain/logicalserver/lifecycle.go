package logicalserver

import (
	"errors"
	"time"
)

func ApplyLifecycle(s Server, state Lifecycle, now time.Time) (Server, error) {
	if now.IsZero() {
		return s, errors.New("authoritative lifecycle time required")
	}
	if s.RetiredAt != nil {
		if state != Retired {
			return s, ErrServerRetired
		}
		// Retirement is a terminal tombstone. Reapplying the same state is
		// idempotent and preserves the original timestamp/version.
		if err := s.Validate(); err != nil {
			return s, err
		}
		return s, nil
	}
	out := s
	switch state {
	case Provisioned:
		if s.FirstOpenedAt != nil {
			return s, errors.New("opened server cannot return to provisioned")
		}
		out.DirectoryVisible = false
		out.ExistingLoginAllowed = false
		out.NewCharacterAllowed = false
	case Open:
		out.DirectoryVisible = true
		out.ExistingLoginAllowed = true
		out.NewCharacterAllowed = true
		if out.FirstOpenedAt == nil {
			x := now.UTC()
			out.FirstOpenedAt = &x
		}
	case ExistingOnly:
		if out.FirstOpenedAt == nil {
			x := now.UTC()
			out.FirstOpenedAt = &x
		}
		out.DirectoryVisible = true
		out.ExistingLoginAllowed = true
		out.NewCharacterAllowed = false
	case Maintenance:
		out.ExistingLoginAllowed = false
		out.NewCharacterAllowed = false
	case Retired:
		x := now.UTC()
		out.RetiredAt = &x
		out.DirectoryVisible = false
		out.ExistingLoginAllowed = false
		out.NewCharacterAllowed = false
	default:
		return s, errors.New("unknown lifecycle")
	}
	out.StateVersion++
	if err := out.Validate(); err != nil {
		return s, err
	}
	return out, nil
}
