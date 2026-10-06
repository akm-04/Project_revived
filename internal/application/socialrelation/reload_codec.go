package socialrelation

import (
	"fmt"
	"gxb.local/backend/v2/internal/domain/identity"
	"strconv"
	"strings"
)

func (r ReloadReference) Encode() (string, error) {
	if e := r.Validate(); e != nil {
		return "", e
	}
	return fmt.Sprintf("r1|%d|%d|%d|%d|%d|%d|%d", r.Recipient, r.Actor, r.RootVersion, r.Purpose, r.First, r.Second, r.Generation), nil
}
func DecodeReloadReference(raw string) (ReloadReference, error) {
	p := strings.Split(raw, "|")
	if len(raw) > 256 || len(p) != 8 || p[0] != "r1" {
		return ReloadReference{}, ErrInvalidState
	}
	n := make([]int64, 7)
	for i, s := range p[1:] {
		v, e := strconv.ParseInt(s, 10, 64)
		if e != nil || v < 1 || strconv.FormatInt(v, 10) != s {
			return ReloadReference{}, ErrInvalidState
		}
		n[i] = v
	}
	if n[3] > 4 {
		return ReloadReference{}, ErrInvalidState
	}
	r := ReloadReference{Recipient: identity.PlayerID(n[0]), Actor: identity.PlayerID(n[1]), RootVersion: n[2], Purpose: ReloadPurpose(n[3]), First: identity.PlayerID(n[4]), Second: identity.PlayerID(n[5]), Generation: n[6]}
	return r, r.Validate()
}
