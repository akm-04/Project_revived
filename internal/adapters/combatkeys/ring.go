// Package combatkeys is the configured Combat entropy key ring. Retired versions
// stay listed so historical attempts remain reconstructible.
package combatkeys

import (
	"encoding/hex"
	"errors"
	"strings"
)

// minimumKeyBytes is the HMAC-SHA256 key strength the ring accepts.
const minimumKeyBytes = 32

type Ring struct {
	current string
	keys    map[string][]byte
}

// Parse reads "version=hex,version=hex" and the current version name.
func Parse(spec, current string) (Ring, error) {
	ring := Ring{current: current, keys: map[string][]byte{}}
	for _, entry := range strings.Split(spec, ",") {
		version, raw, ok := strings.Cut(strings.TrimSpace(entry), "=")
		key, err := hex.DecodeString(raw)
		if !ok || version == "" || len(version) > 64 || err != nil || len(key) < minimumKeyBytes {
			return Ring{}, errors.New("combat key ring: invalid entry")
		}
		if _, dup := ring.keys[version]; dup {
			return Ring{}, errors.New("combat key ring: duplicate version")
		}
		ring.keys[version] = key
	}
	if _, ok := ring.keys[current]; !ok {
		return Ring{}, errors.New("combat key ring: current version not listed")
	}
	return ring, nil
}

func (r Ring) Current() (string, []byte, error) {
	key, err := r.Key(r.current)
	return r.current, key, err
}

func (r Ring) Key(version string) ([]byte, error) {
	key, ok := r.keys[version]
	if !ok {
		return nil, errors.New("combat key ring: version unavailable")
	}
	return append([]byte(nil), key...), nil
}
