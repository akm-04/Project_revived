package ids

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
)

// UUID is a dependency-free RFC 4122 UUID value used for internal server IDs.
// Stock protocol identifiers retain their source-observed types and meanings.
type UUID [16]byte

var ErrInvalidUUID = errors.New("invalid UUID")

func NewUUID() (UUID, error) { return NewUUIDFrom(rand.Reader) }

func NewUUIDFrom(r io.Reader) (UUID, error) {
	var id UUID
	if r == nil {
		return id, errors.New("nil randomness source")
	}
	if _, err := io.ReadFull(r, id[:]); err != nil {
		return UUID{}, err
	}
	id[6] = (id[6] & 0x0f) | 0x40
	id[8] = (id[8] & 0x3f) | 0x80
	return id, nil
}

func ParseUUID(s string) (UUID, error) {
	var id UUID
	if len(s) != 36 || s[8] != '-' || s[13] != '-' || s[18] != '-' || s[23] != '-' {
		return id, ErrInvalidUUID
	}
	compact := s[0:8] + s[9:13] + s[14:18] + s[19:23] + s[24:36]
	b, err := hex.DecodeString(compact)
	if err != nil || len(b) != 16 {
		return UUID{}, ErrInvalidUUID
	}
	copy(id[:], b)
	return id, nil
}

func (id UUID) IsZero() bool    { return id == UUID{} }
func (id UUID) Bytes() [16]byte { return [16]byte(id) }
func (id UUID) String() string {
	b := id[:]
	return fmt.Sprintf("%08x-%04x-%04x-%04x-%012x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:16])
}
func (id UUID) MarshalText() ([]byte, error) { return []byte(id.String()), nil }
func (id *UUID) UnmarshalText(b []byte) error {
	v, err := ParseUUID(string(b))
	if err != nil {
		return err
	}
	*id = v
	return nil
}
