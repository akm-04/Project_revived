package guildbroadcast

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"time"
	"unicode/utf8"

	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
)

var ErrSource = errors.New("invalid immutable Guild broadcast source")

// Member retains the source-time incarnation (durable JOIN event ID), rather
// than a resettable MembershipVersion. These identities survive player deletion.
type Member struct {
	PlayerID    identity.PlayerID
	JoinEventID int64
	JoinedAt    time.Time
}

// Source contains only immutable facts. Recipient delivery/scheduling state is
// kept in Binding so enqueue attempts cannot change a source fingerprint.
type Source struct {
	Operation             operation.Context
	GuildID               guild.ID
	Server                identity.LogicalServerID
	LeaderID              identity.PlayerID
	LeaderName            string
	NameSnapshotChangedAt time.Time
	DecisionAt            time.Time
	ContentRevision       string
	GuildCoreRevision     string
	PolicyID              string
	Request               Request
	Recipients            []Member
}

func ValidRevision(s string) bool {
	b, e := hex.DecodeString(s)
	if e != nil || len(b) != 32 || len(s) != 64 {
		return false
	}
	return hex.EncodeToString(b) == s
}
func (s Source) Validate() error {
	if s.Operation.ID.IsZero() || s.Operation.StartedAt.IsZero() || s.Operation.StartedAt.Location() != time.UTC || s.DecisionAt.IsZero() || s.DecisionAt.Location() != time.UTC || s.GuildID <= 0 || !s.Server.Valid() || int64(s.GuildID)/1000000 != int64(s.Server) || !s.LeaderID.Valid() || !utf8.ValidString(s.LeaderName) || s.NameSnapshotChangedAt.IsZero() || s.NameSnapshotChangedAt.After(s.DecisionAt) || !ValidRevision(s.ContentRevision) || !ValidRevision(s.GuildCoreRevision) || s.PolicyID != PolicyID || len(s.Recipients) == 0 || len(s.Recipients) > MaxRecipients {
		return ErrSource
	}
	if e := s.Request.Validate(); e != nil {
		return e
	}
	if v, ok := s.Operation.Policies.Get("content"); !ok || v != s.ContentRevision {
		return ErrSource
	}
	if v, ok := s.Operation.Policies.Get("guild-core"); !ok || v != s.GuildCoreRevision {
		return ErrSource
	}
	if v, ok := s.Operation.Policies.Get("guild-broadcast"); !ok || v != PolicyID {
		return ErrSource
	}
	events := map[int64]bool{}
	previous := identity.PlayerID(0)
	leader := false
	for _, m := range s.Recipients {
		if !m.PlayerID.Valid() || int64(m.PlayerID)/100000 != int64(s.Server) || m.PlayerID <= previous || m.JoinEventID <= 0 || events[m.JoinEventID] || m.JoinedAt.IsZero() || m.JoinedAt.After(s.DecisionAt) {
			return ErrSource
		}
		events[m.JoinEventID] = true
		previous = m.PlayerID
		leader = leader || m.PlayerID == s.LeaderID
	}
	if !leader {
		return ErrSource
	}
	return nil
}
func (s Source) Fingerprint() ([32]byte, error) {
	if e := s.Validate(); e != nil {
		return [32]byte{}, e
	}
	// operation.Policies supplies its existing canonical JSON representation.
	canonical := s
	canonical.NameSnapshotChangedAt = s.NameSnapshotChangedAt.UTC()
	canonical.Recipients = append([]Member(nil), s.Recipients...)
	for i := range canonical.Recipients {
		canonical.Recipients[i].JoinedAt = canonical.Recipients[i].JoinedAt.UTC()
	}
	raw, e := json.Marshal(canonical)
	if e != nil {
		return [32]byte{}, e
	}
	return sha256.Sum256(raw), nil
}

type State string

const (
	Pending       State = "PENDING"
	Delivered     State = "DELIVERED"
	RecipientGone State = "RECIPIENT_GONE"
)

type Binding struct {
	SourceID        ids.UUID
	RecipientID     identity.PlayerID
	State           State
	TargetReceiptID ids.UUID
	MailID          ids.UUID
	WireID          int64
	AcknowledgedAt  *time.Time
	LastEnqueueAt   time.Time
	NextWakeupAt    time.Time
}

func (b Binding) Validate() error {
	if b.SourceID.IsZero() || !b.RecipientID.Valid() || b.LastEnqueueAt.IsZero() || b.NextWakeupAt.Before(b.LastEnqueueAt) {
		return ErrSource
	}
	switch b.State {
	case Pending:
		if !b.TargetReceiptID.IsZero() || !b.MailID.IsZero() || b.WireID != 0 || b.AcknowledgedAt != nil {
			return ErrSource
		}
	case Delivered:
		if b.TargetReceiptID.IsZero() || b.MailID.IsZero() || b.WireID <= 0 || b.WireID > 9007199254740991 || b.AcknowledgedAt == nil || b.AcknowledgedAt.IsZero() {
			return ErrSource
		}
	case RecipientGone:
		if b.TargetReceiptID.IsZero() || !b.MailID.IsZero() || b.WireID != 0 || b.AcknowledgedAt == nil || b.AcknowledgedAt.IsZero() {
			return ErrSource
		}
	default:
		return ErrSource
	}
	return nil
}
