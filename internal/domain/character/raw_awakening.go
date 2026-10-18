package character

import (
	"encoding/hex"
	"errors"
	"time"
)

const RawAwakeningBirthPolicy = "C4C_PRIVATE_CHARACTER_RAW_AWAKENING_BIRTH_V1"

var ErrRawAwakeningUnavailable = errors.New("character hero: raw awakening unavailable")

// RawAwakeningBirth is an explicit intrinsic owner fact, never an inference
// from a missing row or client default. Positive mission transitions are not
// implemented by this initial-state policy.
type RawAwakeningBirth struct {
	Ref                           HeroRef
	Version                       int64
	RawStage                      int64
	BirthPolicy                   string
	CreationContentRevision       string
	BirthAt, CreatedAt, UpdatedAt time.Time
}

func (f RawAwakeningBirth) Validate() error {
	revision, e := hex.DecodeString(f.CreationContentRevision)
	if f.Ref.Validate() != nil || f.Version != 1 || f.RawStage != 0 || f.BirthPolicy != RawAwakeningBirthPolicy || e != nil || len(revision) != 32 || hex.EncodeToString(revision) != f.CreationContentRevision || f.BirthAt.IsZero() || !f.CreatedAt.Equal(f.BirthAt) || !f.UpdatedAt.Equal(f.BirthAt) {
		return ErrRawAwakeningUnavailable
	}
	return nil
}
func NewRawAwakeningBirth(h Hero) (RawAwakeningBirth, error) {
	f := RawAwakeningBirth{Ref: h.Ref(), Version: 1, RawStage: 0, BirthPolicy: RawAwakeningBirthPolicy, CreationContentRevision: h.CreationContentRevision, BirthAt: h.CreatedAt.UTC(), CreatedAt: h.CreatedAt.UTC(), UpdatedAt: h.CreatedAt.UTC()}
	if h.ValidatePersistent() != nil || h.StateVersion != 1 || !h.UpdatedAt.Equal(h.CreatedAt) {
		return f, ErrRawAwakeningUnavailable
	}
	return f, f.Validate()
}
