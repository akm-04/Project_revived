package frienddm

import (
	"fmt"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"strconv"
	"strings"
)

const WakeupRoute = "friend.dm.v1"

type Reference struct {
	Recipient    identity.PlayerID
	OccurrenceID string
	Version      int64
}

func (r Reference) Encode() (string, error) {
	u, e := ids.ParseUUID(r.OccurrenceID)
	if e != nil || u.IsZero() || !r.Recipient.Valid() || r.Version < 1 {
		return "", ErrInvalid
	}
	return fmt.Sprintf("%d:%s:%d", r.Recipient, r.OccurrenceID, r.Version), nil
}
func DecodeReference(raw string) (Reference, error) {
	parts := strings.Split(raw, ":")
	if len(parts) != 3 {
		return Reference{}, ErrInvalid
	}
	pid, e := strconv.ParseInt(parts[0], 10, 64)
	if e != nil {
		return Reference{}, ErrInvalid
	}
	v, e := strconv.ParseInt(parts[2], 10, 64)
	if e != nil {
		return Reference{}, ErrInvalid
	}
	r := Reference{Recipient: identity.PlayerID(pid), OccurrenceID: parts[1], Version: v}
	canonical, e := r.Encode()
	if e != nil || raw != canonical {
		return Reference{}, ErrInvalid
	}
	return r, nil
}
