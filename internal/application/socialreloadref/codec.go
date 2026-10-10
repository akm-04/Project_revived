package socialreloadref

import (
	"fmt"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"strconv"
	"strings"
)

func (r ReloadReference) Encode() (string, error) {
	if e := r.Validate(); e != nil {
		return "", e
	}
	if r.Purpose == ReloadInviteMaterialized || r.Purpose == ReloadInviteInvalidated {
		marker := "-"
		if !r.MarkerID.IsZero() {
			marker = r.MarkerID.String()
		}
		return fmt.Sprintf("u1|%d|%d|%d|%d|%s|%s", r.Recipient, r.Actor, r.RootVersion, r.Purpose, r.SourceID.String(), marker), nil
	}
	if r.Purpose == ReloadGiftRecipientNotice || r.Purpose == ReloadGiftSenderList {
		return fmt.Sprintf("g1|%d|%d|%d|%d|%s", r.Recipient, r.Actor, r.RootVersion, r.Purpose, r.TransferID.String()), nil
	}
	return fmt.Sprintf("r1|%d|%d|%d|%d|%d|%d|%d", r.Recipient, r.Actor, r.RootVersion, r.Purpose, r.First, r.Second, r.Generation), nil
}
func DecodeReloadReference(raw string) (ReloadReference, error) {
	p := strings.Split(raw, "|")
	if len(raw) <= 256 && len(p) == 7 && p[0] == "u1" {
		n := make([]int64, 4)
		for i, v := range p[1:5] {
			x, e := strconv.ParseInt(v, 10, 64)
			if e != nil || x < 1 || strconv.FormatInt(x, 10) != v {
				return ReloadReference{}, ErrInvalidState
			}
			n[i] = x
		}
		id, e := ids.ParseUUID(p[5])
		if e != nil || id.IsZero() || id.String() != p[5] || n[3] < 7 || n[3] > 8 {
			return ReloadReference{}, ErrInvalidState
		}
		var marker ids.UUID
		if p[6] != "-" {
			marker, e = ids.ParseUUID(p[6])
			if e != nil || marker.IsZero() || marker.String() != p[6] {
				return ReloadReference{}, ErrInvalidState
			}
		}
		r := ReloadReference{Recipient: identity.PlayerID(n[0]), Actor: identity.PlayerID(n[1]), RootVersion: n[2], Purpose: ReloadPurpose(n[3]), SourceID: id, MarkerID: marker}
		return r, r.Validate()
	}
	if len(raw) <= 256 && len(p) == 6 && p[0] == "g1" {
		n := make([]int64, 4)
		for i, s := range p[1:5] {
			v, e := strconv.ParseInt(s, 10, 64)
			if e != nil || v < 1 || strconv.FormatInt(v, 10) != s {
				return ReloadReference{}, ErrInvalidState
			}
			n[i] = v
		}
		u, e := ids.ParseUUID(p[5])
		if e != nil || u.IsZero() || u.String() != p[5] || n[3] < 5 || n[3] > 6 {
			return ReloadReference{}, ErrInvalidState
		}
		r := ReloadReference{Recipient: identity.PlayerID(n[0]), Actor: identity.PlayerID(n[1]), RootVersion: n[2], Purpose: ReloadPurpose(n[3]), TransferID: u}
		return r, r.Validate()
	}
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
