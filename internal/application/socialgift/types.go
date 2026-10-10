// Package socialgift owns canonical daily gift entitlements. Public stock
// activation is intentionally a successor concern; the inbox never owns value.
package socialgift

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/application/socialinbox"
	dg "gxb.local/backend/v2/internal/domain/generation"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	dgift "gxb.local/backend/v2/internal/domain/socialgift"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"strconv"
	"time"
)

const DayPolicy = "SOCIAL_GIFT_DAY_V1"
const ClaimPolicy = "SOCIAL_GIFT_CLAIM_BATCH_V1"
const LockRankEpoch uint16 = 371
const LockRankTransfer uint16 = 372

var (
	ErrInvalid     = errors.New("invalid SocialGift request")
	ErrConflict    = errors.New("SocialGift source/evidence conflict")
	ErrQuota       = errors.New("SocialGift daily quota exceeded")
	ErrDuplicate   = errors.New("SocialGift already sent today")
	ErrNotEligible = errors.New("SocialGift relation is not eligible")
	ErrClock       = errors.New("SocialGift time/version regression")
	ErrContent     = errors.New("SocialGift content unavailable")
)

type Epoch struct {
	Player               identity.PlayerID
	Day                  string
	Generation           dg.GenerationID
	Version              int64
	CreatedAt, UpdatedAt time.Time
}

func Day(at time.Time) (string, error) {
	if at.IsZero() {
		return "", ErrInvalid
	}
	day := at.UTC().Add(8 * time.Hour).Format("2006-01-02")
	if len(day) != 10 {
		return "", ErrInvalid
	}
	return day, nil
}
func (e Epoch) Ref() (dg.GenerationRef, error) {
	s, err := dg.NewAuthorityScope("player", strconv.FormatInt(int64(e.Player), 10))
	if err != nil {
		return dg.GenerationRef{}, err
	}
	return dg.NewGenerationRef("social-gift", s, e.Generation)
}
func (e Epoch) Validate() error {
	d, err := time.Parse("2006-01-02", e.Day)
	if err != nil || d.Format("2006-01-02") != e.Day || !e.Player.Valid() || !e.Generation.Valid() || e.Version < 1 || e.CreatedAt.IsZero() || e.UpdatedAt.Before(e.CreatedAt) {
		return ErrConflict
	}
	r, err := e.Ref()
	if err != nil || !r.Valid() {
		return ErrConflict
	}
	return nil
}
func NewEpoch(pid identity.PlayerID, day string, op operation.Context, at time.Time) (Epoch, error) {
	h := op.Derive(fmt.Sprintf("social-gift.epoch:%d:%s", pid, day), 0)
	u, err := ids.NewUUIDFrom(bytes.NewReader(h[:]))
	if err != nil {
		return Epoch{}, err
	}
	g, err := dg.GenerationIDFrom(u)
	if err != nil {
		return Epoch{}, err
	}
	e := Epoch{pid, day, g, 1, at, at}
	return e, e.Validate()
}
func EpochKey(pid identity.PlayerID) (lockkey.Key, error) {
	return lockkey.New(LockRankEpoch, "social-gift.epoch", lockkey.String(fmt.Sprintf("%d:%s", pid, DayPolicy)))
}
func TransferKey(sender, recipient identity.PlayerID, day string) (lockkey.Key, error) {
	return lockkey.New(LockRankTransfer, "social-gift.transfer", lockkey.String(fmt.Sprintf("%d:%d:%s:%s", sender, recipient, DayPolicy, day)))
}

type Transfer struct {
	ID                                          ids.UUID
	Sender, Recipient                           identity.PlayerID
	SenderDay                                   string
	SenderGeneration                            dg.GenerationID
	SendOperation                               ids.UUID
	RequestFingerprint                          string
	StartedAt, IssuedAt                         time.Time
	FriendshipGeneration, RecipientBlockVersion int64
	RewardRevision, VectorFingerprint           string
	Amount                                      int64
	NoticeID                                    socialinbox.NoticeID
	Version                                     int64
	ClaimOperation                              ids.UUID
	ClaimDay                                    string
	ClaimGeneration                             dg.GenerationID
	ClaimedAt                                   *time.Time
	GrantReceiptID, ClaimContentRevision        string
}

func (t Transfer) Validate() error {
	if t.ID.IsZero() || !t.Sender.Valid() || !t.Recipient.Valid() || t.Sender == t.Recipient || !t.SenderGeneration.Valid() || t.SendOperation.IsZero() || len(t.RequestFingerprint) != 64 || t.StartedAt.IsZero() || t.IssuedAt.IsZero() || t.FriendshipGeneration < 1 || t.RecipientBlockVersion < 0 || len(t.RewardRevision) != 64 || len(t.VectorFingerprint) != 64 || t.Amount != 5 || !t.NoticeID.WireSafe() || t.Version < 1 {
		return ErrConflict
	}
	day, err := Day(t.IssuedAt)
	if err != nil || day != t.SenderDay {
		return ErrConflict
	}
	if t.ClaimOperation.IsZero() {
		if t.ClaimDay != "" || t.ClaimGeneration.Valid() || t.ClaimedAt != nil || t.GrantReceiptID != "" || t.ClaimContentRevision != "" {
			return ErrConflict
		}
	} else {
		if t.ClaimedAt == nil || t.ClaimedAt.Before(t.IssuedAt) || !t.ClaimGeneration.Valid() || t.GrantReceiptID == "" || len(t.ClaimContentRevision) != 64 {
			return ErrConflict
		}
		d, e := Day(*t.ClaimedAt)
		if e != nil || d != t.ClaimDay {
			return ErrConflict
		}
	}
	return nil
}
func (t Transfer) Descriptor() socialinbox.GiftDescriptor {
	return socialinbox.GiftDescriptor{TransferID: t.ID, Sender: t.Sender, Recipient: t.Recipient, IssuedAt: t.IssuedAt}
}

type Content struct {
	Revision string
	Catalog  dgift.SocialGiftCatalog
}

func (c Content) Validate() error {
	if len(c.Revision) != 64 {
		return ErrContent
	}
	return c.Catalog.Validate()
}
func (c Content) Compatible(t Transfer) bool {
	return t.Amount == c.Catalog.Amount && t.VectorFingerprint == c.Catalog.VectorFingerprint && t.Validate() == nil
}

type Result struct {
	OperationStartedAtExact string                 `json:"operation_started_at_exact,omitempty"`
	NoticeIDs               []socialinbox.NoticeID `json:"notice_ids"`
	TransferIDs             []string               `json:"transfer_ids"`
	GrantReceiptID          string                 `json:"grant_receipt_id,omitempty"`
	Amount                  int64                  `json:"amount"`
	Revision                string                 `json:"revision"`
}
type ClaimOperation struct {
	ID                    ids.UUID
	Recipient             identity.PlayerID
	Fingerprint           string
	StartedAt, DecisionAt time.Time
	Day                   string
	Generation            dg.GenerationID
	Revision              string
	Result                Result
}

func fingerprint(kind string, actor identity.ActorContext, param any, op operation.Context) (string, error) {
	if op.ID.IsZero() || op.StartedAt.IsZero() {
		return "", ErrInvalid
	}
	scope := struct {
		AccountID, AccountUID, SessionID, ContextID         string
		PlayerID                                            identity.PlayerID
		LogicalServer                                       identity.LogicalServerID
		ContextGeneration, ContextLiveness, SessionLiveness int64
	}{actor.AccountID.UUID().String(), string(actor.AccountUID), actor.SessionID.UUID().String(), actor.ContextID.UUID().String(), actor.PlayerID, actor.LogicalServerID, actor.ContextGeneration, actor.ContextLivenessVersion, actor.SessionLivenessVersion}
	raw, e := json.Marshal(struct {
		Kind      string
		Actor     any
		Param     any
		Operation operation.Context
	}{kind, scope, param, op})
	if e != nil {
		return "", e
	}
	h := sha256.Sum256(raw)
	return hex.EncodeToString(h[:]), nil
}
func GrantPlan(pid identity.PlayerID, op ids.UUID, amount int64) grant.Plan {
	return grant.Plan{PlayerID: pid, Source: grant.SourceIdentity{Domain: "social-gift", Operation: "claim-batch", BusinessKey: strconv.FormatInt(int64(pid), 10), Occurrence: op.String(), PolicyVersion: ClaimPolicy}, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "friendship_coin", Amount: amount}}}
}
func CanonicalIDs(in []socialinbox.NoticeID) ([]socialinbox.NoticeID, error) {
	out := []socialinbox.NoticeID{}
	seen := map[socialinbox.NoticeID]bool{}
	for _, id := range in {
		if !id.WireSafe() {
			return nil, ErrInvalid
		}
		if !seen[id] {
			seen[id] = true
			out = append(out, id)
		}
	}
	return out, nil
}

func TransferID(op operation.Context) (ids.UUID, error) {
	h := op.Derive("social-gift.transfer:"+op.ID.String(), 0)
	return ids.NewUUIDFrom(bytes.NewReader(h[:]))
}
