package socialinbox

import (
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

type NoticeID int64

func (id NoticeID) Valid() bool { return id > 0 }

// Durable int64 identity is retained; the stock Lua/JSON wire has a safe-integer boundary.
const MaxWireNoticeID NoticeID = 1<<53 - 1

func (id NoticeID) WireSafe() bool { return id.Valid() && id <= MaxWireNoticeID }

var ErrInvalidNotice = errors.New("invalid social inbox notice")

type SourceKey struct {
	Kind string
	Key  string
}

func (s SourceKey) Validate() error {
	if s.Kind == "" || s.Key == "" {
		return ErrInvalidNotice
	}
	return nil
}

type Notice struct {
	RecipientPlayerID    identity.PlayerID
	NoticeID             NoticeID
	NoticeType           int16
	Source               SourceKey
	RelatedPlayerID      identity.PlayerID
	RelatedPlayerDeleted bool // true only when the owner read observed SQL NULL
	Active               bool
	NoticeTime           time.Time
	DismissedAt          *time.Time
	StateVersion         int64
	CreatedAt            time.Time
	UpdatedAt            time.Time
}

func (n Notice) Validate() error {
	if !n.RecipientPlayerID.Valid() || !n.NoticeID.Valid() || n.NoticeType < 1 || n.Source.Validate() != nil || n.StateVersion < 1 || n.NoticeTime.IsZero() || n.CreatedAt.IsZero() || n.UpdatedAt.Before(n.CreatedAt) {
		return ErrInvalidNotice
	}
	if n.Active != (n.DismissedAt == nil) {
		return ErrInvalidNotice
	}
	if n.DismissedAt != nil && n.DismissedAt.Before(n.NoticeTime) {
		return ErrInvalidNotice
	}
	if n.RelatedPlayerID < 0 || (n.RelatedPlayerDeleted && n.RelatedPlayerID != 0) {
		return ErrInvalidNotice
	}
	return nil
}
