package combat

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"math"

	"gxb.local/backend/v2/internal/foundation/ids"
)

// MaxExactInteger is the largest integer a Lua number represents exactly.
const MaxExactInteger = 1<<53 - 1

var ErrRandomRange = errors.New("combat: Lua random argument outside the exact integer range or empty interval")

func mac(key []byte, message ...[]byte) [32]byte {
	h := hmac.New(sha256.New, key)
	for _, m := range message {
		h.Write(m)
	}
	var out [32]byte
	copy(out[:], h.Sum(nil))
	return out
}

// EntropyRoot = HMAC-SHA256(key, "gxb-combat/v1" 0 attempt 0 snapshot 0 policy).
func EntropyRoot(key []byte, attempt ids.UUID, snapshotHash string) ([32]byte, error) {
	if len(key) < 32 || attempt.IsZero() || len(snapshotHash) != 64 {
		return [32]byte{}, ErrKeyUnavailable
	}
	zero := []byte{0}
	return mac(key, []byte("gxb-combat/v1"), zero, []byte(attempt.String()), zero, []byte(snapshotHash), zero, []byte(EntropyPolicyVersion)), nil
}

// Stream is the attempt-local HMAC counter generator behind math.random.
// math.randomseed rekeys it from the root, so reseeding is attempt-scoped.
type Stream struct {
	root, key [32]byte
	counter   uint64
	Draws     uint64
	Reseeds   uint64
}

func NewStream(root [32]byte) *Stream { return &Stream{root: root, key: root} }

func (s *Stream) block() uint64 {
	var c [8]byte
	binary.BigEndian.PutUint64(c[:], s.counter)
	v := mac(s.key[:], []byte("lua.random.block/v1\x00"), c[:])
	s.counter++
	s.Draws++
	return binary.BigEndian.Uint64(v[:8])
}

// Float maps math.random() to [0,1) with 53 bits.
func (s *Stream) Float() float64 { return float64(s.block()>>11) / (1 << 53) }

// Uniform returns an unbiased value in [0,n) by rejection.
func (s *Stream) Uniform(n uint64) uint64 {
	threshold := -n % n
	for {
		if v := s.block(); v >= threshold {
			return v % n
		}
	}
}

// Between maps math.random(low, high) to an unbiased integer in [low, high].
func (s *Stream) Between(low, high float64) (int64, error) {
	a, okA := exactInteger(low)
	b, okB := exactInteger(high)
	if !okA || !okB || b < a || float64(b)-float64(a)+1 > MaxExactInteger {
		return 0, ErrRandomRange
	}
	return a + int64(s.Uniform(uint64(b-a+1))), nil
}

func (s *Stream) Reseed(seed float64) error {
	value, ok := exactInteger(seed)
	if !ok {
		return ErrRandomRange
	}
	s.Reseeds++
	var b [16]byte
	binary.BigEndian.PutUint64(b[:8], uint64(value))
	binary.BigEndian.PutUint64(b[8:], s.Reseeds)
	s.key = mac(s.root[:], []byte("lua.randomseed/v1\x00"), b[:])
	s.counter = 0
	return nil
}

func exactInteger(v float64) (int64, bool) {
	if math.IsNaN(v) || math.IsInf(v, 0) || math.Trunc(v) != v || math.Abs(v) > MaxExactInteger {
		return 0, false
	}
	return int64(v), true
}
