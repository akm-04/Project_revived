package mail

import (
	"errors"
	"time"
)

const (
	DefaultOverflowAfterLoginSeconds int64 = 3600
	DefaultOrdinarySeconds           int64 = 604800
)

// Tuning is the operator overlay (mail_tuning, written by the I11 operator
// tool). Zero fields keep the built-in durations; negative fields are invalid.
type Tuning struct {
	Version                   int64 `json:"version"`
	OverflowAfterLoginSeconds int64 `json:"overflow_after_login_seconds"`
	OrdinarySeconds           int64 `json:"ordinary_seconds"`
}

var ErrTuning = errors.New("mail: operator tuning")

func (t Tuning) Validate() error {
	if t.Version < 0 || t.OverflowAfterLoginSeconds < 0 || t.OrdinarySeconds < 0 {
		return ErrTuning
	}
	return nil
}

// OverflowAfterLogin is the lifetime an unclaimed overflow mail gets at login.
func (t Tuning) OverflowAfterLogin() time.Duration {
	if t.OverflowAfterLoginSeconds <= 0 {
		return time.Duration(DefaultOverflowAfterLoginSeconds) * time.Second
	}
	return time.Duration(t.OverflowAfterLoginSeconds) * time.Second
}

// Ordinary is the lifetime of an ordinary reward mail.
func (t Tuning) Ordinary() time.Duration {
	if t.OrdinarySeconds <= 0 {
		return time.Duration(DefaultOrdinarySeconds) * time.Second
	}
	return time.Duration(t.OrdinarySeconds) * time.Second
}
