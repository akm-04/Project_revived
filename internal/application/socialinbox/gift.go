package socialinbox

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"time"
)

const GiftSourceKind = "social-gift.transfer.v1"

type GiftDescriptor struct {
	TransferID        ids.UUID
	Sender, Recipient identity.PlayerID
	IssuedAt          time.Time
}

func (d GiftDescriptor) Notice() (Notice, error) {
	if d.TransferID.IsZero() || !d.Sender.Valid() || !d.Recipient.Valid() || d.Sender == d.Recipient || d.IssuedAt.IsZero() {
		return Notice{}, ErrInvalidNotice
	}
	return Notice{RecipientPlayerID: d.Recipient, NoticeType: 4, Source: SourceKey{Kind: GiftSourceKind, Key: d.TransferID.String()}, RelatedPlayerID: d.Sender, NoticeTime: d.IssuedAt.UTC()}, nil
}
func ValidateGiftLifecycle(n Notice) error {
	u, e := ids.ParseUUID(n.Source.Key)
	if e != nil || u.IsZero() || n.Source.Kind != GiftSourceKind || n.NoticeType != 4 || n.Validate() != nil || !n.NoticeID.WireSafe() {
		return ErrInvalidNotice
	}
	if !n.RelatedPlayerID.Valid() && !n.RelatedPlayerDeleted {
		return ErrInvalidNotice
	}
	return nil
}
func MatchGift(n Notice, d GiftDescriptor) error {
	w, e := d.Notice()
	if e != nil || ValidateGiftLifecycle(n) != nil || n.RecipientPlayerID != w.RecipientPlayerID || n.Source != w.Source || !n.NoticeTime.Equal(w.NoticeTime) || (!n.RelatedPlayerDeleted && n.RelatedPlayerID != w.RelatedPlayerID) {
		return ErrInvalidNotice
	}
	return nil
}

type GiftNoticeStore interface {
	Store
	SourceReader
	RelationNoticeStore
	DismissStore
	InsertGiftNoticeTx(context.Context, tx.Tx, Notice) (Notice, error)
	ConsumeGiftNoticeTx(context.Context, tx.Tx, Notice, time.Time) error
}
type PreparedGift struct {
	caller     tx.Tx
	descriptor GiftDescriptor
	existing   *Notice
	prepared   bool
}
type GiftService struct{ Store GiftNoticeStore }

func (s GiftService) PrepareTx(c context.Context, t tx.Tx, f RecipientFence, d GiftDescriptor) (PreparedGift, error) {
	w, e := d.Notice()
	if e != nil || t == nil || s.Store == nil || f.PlayerID != d.Recipient || f.StateVersion < 1 {
		return PreparedGift{}, ErrInvalidNotice
	}
	n, ok, e := s.Store.LockNoticeSourceTx(c, t, w.RecipientPlayerID, w.Source)
	if e != nil {
		return PreparedGift{}, e
	}
	p := PreparedGift{caller: t, descriptor: d, prepared: true}
	if ok {
		if MatchGift(n, d) != nil {
			return PreparedGift{}, ErrInvalidNotice
		}
		x := copyNotice(n)
		p.existing = &x
	}
	return p, nil
}
func (p PreparedGift) Existing() (Notice, bool) {
	if p.existing == nil {
		return Notice{}, false
	}
	return copyNotice(*p.existing), true
}
func (s GiftService) ApplyTx(c context.Context, t tx.Tx, p PreparedGift) (Notice, error) {
	if !p.prepared || !sameCaller(t, p.caller) || s.Store == nil {
		return Notice{}, ErrInvalidNotice
	}
	if p.existing != nil {
		return copyNotice(*p.existing), nil
	}
	n, e := p.descriptor.Notice()
	if e != nil {
		return Notice{}, e
	}
	out, e := s.Store.InsertGiftNoticeTx(c, t, n)
	if e != nil {
		return Notice{}, e
	}
	return out, MatchGift(out, p.descriptor)
}
func PreflightConsumption(n Notice, at time.Time) error {
	if !n.Active || n.VersionExhausted() || at.Before(n.UpdatedAt) || at.Before(n.NoticeTime) {
		return ErrInvalidNotice
	}
	return nil
}
func (n Notice) VersionExhausted() bool { return n.StateVersion == math.MaxInt64 }

// PreparedGiftConsumption is presentation-only authority. Canonical Gift value
// and the aggregate Grant remain SocialGift/I5-owned. Fields and caller binding
// are private so a consumer cannot substitute another notice or transaction.
type PreparedGiftConsumption struct {
	caller     tx.Tx
	notice     Notice
	descriptor GiftDescriptor
	at         time.Time
	prepared   bool
}

func (s GiftService) PrepareConsumptionTx(c context.Context, t tx.Tx, f RecipientFence, n Notice, d GiftDescriptor, at time.Time) (PreparedGiftConsumption, error) {
	if t == nil || s.Store == nil || f.PlayerID != n.RecipientPlayerID || f.StateVersion < 1 || MatchGift(n, d) != nil || PreflightConsumption(n, at) != nil {
		return PreparedGiftConsumption{}, ErrInvalidNotice
	}
	return PreparedGiftConsumption{caller: t, notice: copyNotice(n), descriptor: d, at: at.UTC(), prepared: true}, nil
}
func (s GiftService) ApplyConsumptionTx(c context.Context, t tx.Tx, p PreparedGiftConsumption) error {
	if !p.prepared || !sameCaller(t, p.caller) || s.Store == nil || MatchGift(p.notice, p.descriptor) != nil || PreflightConsumption(p.notice, p.at) != nil {
		return ErrInvalidNotice
	}
	return s.Store.ConsumeGiftNoticeTx(c, t, copyNotice(p.notice), p.at)
}
