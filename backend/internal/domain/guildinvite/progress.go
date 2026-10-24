package guildinvite

import (
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"time"
)

type DeliveryState string

const (
	Pending       DeliveryState = "PENDING"
	Materialized  DeliveryState = "MATERIALIZED"
	Suppressed    DeliveryState = "SUPPRESSED"
	RecipientGone DeliveryState = "RECIPIENT_GONE"
)

// TargetProof describes a committed SocialInbox result. Source owners may ACK
// only a result reread through the typed target owner; scheduling is not proof.
type TargetProof struct {
	SourceID              ids.UUID
	Recipient             identity.PlayerID
	SourceFingerprint     [32]byte
	ReceiptID             ids.UUID
	State                 DeliveryState
	NoticeID, RootVersion int64
	DecisionAt            time.Time
}

func (p TargetProof) Validate() error {
	if p.SourceID.IsZero() || !p.Recipient.Valid() || p.SourceFingerprint == ([32]byte{}) || p.ReceiptID.IsZero() || p.RootVersion < 0 || p.DecisionAt.IsZero() || p.DecisionAt.Location() != time.UTC {
		return ErrEvidence
	}
	switch p.State {
	case Materialized:
		if p.NoticeID < 1 || p.NoticeID > MaxNoticeID || p.RootVersion < 1 {
			return ErrEvidence
		}
	case Suppressed, RecipientGone:
		if p.NoticeID != 0 {
			return ErrEvidence
		}
	default:
		return ErrEvidence
	}
	return nil
}

func (p TargetProof) Matches(s Issue) error {
	fp, e := s.Fingerprint()
	if e != nil || p.Validate() != nil || p.SourceID != s.Operation.ID || p.Recipient != s.Tuple.Recipient || p.SourceFingerprint != fp || p.DecisionAt.Before(s.DecisionAt) {
		return ErrEvidence
	}
	return nil
}

type Delivery struct {
	SourceID                    ids.UUID
	Recipient                   identity.PlayerID
	State                       DeliveryState
	ReceiptID                   ids.UUID
	NoticeID                    int64
	AcknowledgedAt              *time.Time
	LastEnqueueAt, NextWakeupAt time.Time
}

func (d Delivery) Validate() error {
	if d.SourceID.IsZero() || !d.Recipient.Valid() || d.LastEnqueueAt.IsZero() || d.NextWakeupAt.Before(d.LastEnqueueAt) {
		return ErrEvidence
	}
	switch d.State {
	case Pending:
		if !d.ReceiptID.IsZero() || d.NoticeID != 0 || d.AcknowledgedAt != nil {
			return ErrEvidence
		}
	case Materialized, Suppressed, RecipientGone:
		if d.ReceiptID.IsZero() || d.AcknowledgedAt == nil || d.AcknowledgedAt.Before(d.LastEnqueueAt) {
			return ErrEvidence
		}
		if d.State == Materialized {
			if d.NoticeID < 1 || d.NoticeID > MaxNoticeID {
				return ErrEvidence
			}
		} else if d.NoticeID != 0 {
			return ErrEvidence
		}
	default:
		return ErrEvidence
	}
	return nil
}

func (d Delivery) Matches(p TargetProof) error {
	if d.Validate() != nil || p.Validate() != nil || d.SourceID != p.SourceID || d.Recipient != p.Recipient {
		return ErrEvidence
	}
	if d.State != Pending && (d.State != p.State || d.ReceiptID != p.ReceiptID || d.NoticeID != p.NoticeID) {
		return ErrEvidence
	}
	return nil
}

type InvalidationProof struct {
	MarkerID, SourceID                   ids.UUID
	Recipient                            identity.PlayerID
	MarkerFingerprint, SourceFingerprint [32]byte
	ReceiptID                            ids.UUID
	NoticeID, RootVersion                int64
	NoticeStateVersion                   int64
	SourceSerial                         int64
	SourceKey                            string
	Consumed                             bool
	DecisionAt                           time.Time
}

func (p InvalidationProof) Validate() error {
	if p.SourceSerial < 1 || p.SourceKey == "" {
		return ErrEvidence
	}
	if p.MarkerID.IsZero() || p.SourceID.IsZero() || !p.Recipient.Valid() || p.MarkerFingerprint == ([32]byte{}) || p.SourceFingerprint == ([32]byte{}) || p.ReceiptID.IsZero() || p.NoticeID < 0 || p.NoticeID > MaxNoticeID || p.RootVersion < 0 || p.DecisionAt.IsZero() || p.DecisionAt.Location() != time.UTC || p.NoticeStateVersion < 0 || (p.NoticeID == 0) != (p.NoticeStateVersion == 0) || p.Consumed && (p.NoticeID == 0 || p.RootVersion == 0 || p.NoticeStateVersion < 2) {
		return ErrEvidence
	}
	return nil
}

// AppliesTo is evaluated only on immutable source facts within the marker's
// finite high water. A later issue which already includes this JOIN stays live.
func (m Marker) AppliesTo(s Issue) (bool, error) {
	if m.Validate() != nil || s.Validate() != nil {
		return false, ErrEvidence
	}
	if s.Serial > m.MaxIssueSerial {
		return false, nil
	}
	if m.Kind == Retire {
		return s.Tuple.GuildID == m.GuildID, nil
	}
	return s.Tuple.Recipient == m.Subject && s.LastJoinEventID < m.EventID, nil
}

func (p InvalidationProof) Matches(m Marker, s Issue) error {
	key, keyErr := s.Tuple.SourceKey()
	if keyErr != nil || p.SourceSerial != s.Serial || p.SourceKey != key {
		return ErrEvidence
	}
	mfp, e := m.Fingerprint()
	sfp, e2 := s.Fingerprint()
	applies, e3 := m.AppliesTo(s)
	if e != nil || e2 != nil || e3 != nil || !applies || p.Validate() != nil || p.MarkerID != m.Operation.ID || p.SourceID != s.Operation.ID || p.Recipient != s.Tuple.Recipient || p.MarkerFingerprint != mfp || p.SourceFingerprint != sfp || p.DecisionAt.Before(m.DecisionAt) || p.DecisionAt.Before(s.DecisionAt) {
		return ErrEvidence
	}
	return nil
}

type MarkerProgress struct {
	MarkerID                     ids.UUID
	CursorSerial, MaxIssueSerial int64
	Complete                     bool
	CompletedAt                  *time.Time
	LastEnqueueAt, NextWakeupAt  time.Time
	CursorProof                  *CursorProof
}

func (p MarkerProgress) Validate() error {
	if p.CursorSerial == 0 && !p.Complete {
		if p.CursorProof != nil {
			return ErrEvidence
		}
	} else if p.CursorProof == nil || p.CursorProof.Request.MarkerID != p.MarkerID || p.CursorProof.Request.To != p.CursorSerial || p.CursorProof.Request.Complete != p.Complete || p.CursorProof.ReceiptID.IsZero() {
		return ErrEvidence
	}
	if p.MarkerID.IsZero() || p.CursorSerial < 0 || p.MaxIssueSerial < p.CursorSerial || p.LastEnqueueAt.IsZero() || p.NextWakeupAt.Before(p.LastEnqueueAt) || p.Complete != (p.CompletedAt != nil) {
		return ErrEvidence
	}
	if p.Complete && (p.CursorSerial != p.MaxIssueSerial || p.CompletedAt.Before(p.LastEnqueueAt)) {
		return ErrEvidence
	}
	return nil
}
