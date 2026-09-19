package lockkey

import (
	"bytes"
	"encoding/binary"
	"errors"
	"sort"

	"gxb.local/backend/v2/internal/foundation/ids"
)

type IdentityKind uint8

const (
	IdentityInt64 IdentityKind = iota + 1
	IdentityUint64
	IdentityString
	IdentityUUID
	IdentityBytes
)

type Identity struct {
	Kind IdentityKind
	raw  []byte
}

func Int64(v int64) Identity {
	var b [8]byte
	binary.BigEndian.PutUint64(b[:], uint64(v)^(1<<63))
	return Identity{Kind: IdentityInt64, raw: b[:]}
}
func Uint64(v uint64) Identity {
	var b [8]byte
	binary.BigEndian.PutUint64(b[:], v)
	return Identity{Kind: IdentityUint64, raw: b[:]}
}
func String(v string) Identity { return Identity{Kind: IdentityString, raw: []byte(v)} }
func UUID(v ids.UUID) Identity {
	b := v.Bytes()
	return Identity{Kind: IdentityUUID, raw: append([]byte(nil), b[:]...)}
}
func Bytes(v []byte) Identity            { return Identity{Kind: IdentityBytes, raw: append([]byte(nil), v...)} }
func (i Identity) Equal(j Identity) bool { return i.Kind == j.Kind && bytes.Equal(i.raw, j.raw) }
func (i Identity) Raw() []byte           { return append([]byte(nil), i.raw...) }

type Key struct {
	DomainRank uint16
	OwnerKind  string
	Identity   Identity
}

var ErrInvalidKey = errors.New("invalid lock key")

func New(rank uint16, owner string, id Identity) (Key, error) {
	if rank == 0 || owner == "" || id.Kind == 0 {
		return Key{}, ErrInvalidKey
	}
	return Key{rank, owner, id}, nil
}
func Compare(a, b Key) int {
	if a.DomainRank < b.DomainRank {
		return -1
	}
	if a.DomainRank > b.DomainRank {
		return 1
	}
	if a.OwnerKind < b.OwnerKind {
		return -1
	}
	if a.OwnerKind > b.OwnerKind {
		return 1
	}
	if a.Identity.Kind < b.Identity.Kind {
		return -1
	}
	if a.Identity.Kind > b.Identity.Kind {
		return 1
	}
	return bytes.Compare(a.Identity.raw, b.Identity.raw)
}
func Sort(keys []Key) []Key {
	out := append([]Key(nil), keys...)
	sort.Slice(out, func(i, j int) bool { return Compare(out[i], out[j]) < 0 })
	return out
}
func Canonical(keys []Key) ([]Key, error) {
	out := Sort(keys)
	for i, k := range out {
		if k.DomainRank == 0 || k.OwnerKind == "" || k.Identity.Kind == 0 {
			return nil, ErrInvalidKey
		}
		if i > 0 && Compare(out[i-1], k) == 0 {
			return nil, errors.New("duplicate lock key")
		}
	}
	return out, nil
}

// CanonicalDedup validates, sorts and deduplicates a lock set. A business
// planner may discover the same canonical owner through multiple plan lines;
// those duplicate requirements collapse to one lock acquisition. Canonical
// intentionally retains its stricter duplicate-rejection contract for callers
// that use duplicates as a planning bug signal.
func CanonicalDedup(keys []Key) ([]Key, error) {
	out := Sort(keys)
	uniq := make([]Key, 0, len(out))
	for _, k := range out {
		if k.DomainRank == 0 || k.OwnerKind == "" || k.Identity.Kind == 0 {
			return nil, ErrInvalidKey
		}
		if len(uniq) > 0 && Compare(uniq[len(uniq)-1], k) == 0 {
			continue
		}
		uniq = append(uniq, k)
	}
	return uniq, nil
}
