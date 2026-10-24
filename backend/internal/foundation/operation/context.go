package operation

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"io"
	"time"

	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/policy"
)

// Context is created once per semantic operation and reused byte-for-byte across
// internal transaction retries. It is not a client idempotency token.
type Context struct {
	ID          ids.UUID
	StartedAt   time.Time
	EntropySeed [32]byte
	Policies    policy.Set
}

type Factory struct {
	Clock  clock.Clock
	Random io.Reader
}

func (f Factory) New(policies policy.Set) (Context, error) {
	if f.Clock == nil {
		return Context{}, errors.New("nil authoritative clock")
	}
	r := f.Random
	if r == nil {
		r = rand.Reader
	}
	id, err := ids.NewUUIDFrom(r)
	if err != nil {
		return Context{}, err
	}
	var seed [32]byte
	if _, err = io.ReadFull(r, seed[:]); err != nil {
		return Context{}, err
	}
	return Context{ID: id, StartedAt: f.Clock.Now().UTC(), EntropySeed: seed, Policies: policies}, nil
}

// Derive returns deterministic retry-stable entropy. A domain must use a stable
// label and ordinal; transaction retry count must never enter this function.
func (c Context) Derive(label string, ordinal uint64) [32]byte {
	h := hmac.New(sha256.New, c.EntropySeed[:])
	h.Write([]byte("gxb-v2/entropy/v1\x00"))
	h.Write([]byte(label))
	h.Write([]byte{0})
	var b [8]byte
	binary.BigEndian.PutUint64(b[:], ordinal)
	h.Write(b[:])
	var out [32]byte
	copy(out[:], h.Sum(nil))
	return out
}

type Attempt struct {
	Operation Context
	Number    int
}
