package frienddm

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/friendmessage"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"time"
)

const LockRank uint16 = 380
const PendingPolicy = "FRIEND_DM_PENDING_V1"
const ClaimPolicy = "FRIEND_DM_CLAIM_V1"
const PendingLimit = 50
const LeaseDuration = 30 * time.Second

var ErrInvalid = errors.New("friend dm invalid input or state")
var ErrUnavailable = errors.New("friend dm unavailable")
var ErrManifestChanged = errors.New("friend dm manifest changed")
var ErrStale = errors.New("friend dm stale claim or decision")

type Status string

const (
	Pending                Status = "PENDING"
	TransportWriteRecorded Status = "TRANSPORT_WRITE_RECORDED"
	OfflineProjected       Status = "OFFLINE_PROJECTED"
	RetentionSuppressed    Status = "RETENTION_SUPPRESSED"
	PrivacySuppressed      Status = "PRIVACY_SUPPRESSED"
)

func (s Status) Valid() bool {
	return s == Pending || s == TransportWriteRecorded || s == OfflineProjected || s == RetentionSuppressed || s == PrivacySuppressed
}

type Occurrence struct {
	ID                    string            `json:"id"`
	Digest                string            `json:"digest"`
	Sender                identity.PlayerID `json:"sender"`
	Recipient             identity.PlayerID `json:"recipient"`
	Sequence              int64             `json:"sequence"`
	AcceptedAt            time.Time         `json:"accepted_at"`
	Message               string            `json:"message"`
	FriendshipGeneration  int64             `json:"friendship_generation"`
	RecipientBlockVersion int64             `json:"recipient_block_version"`
	ContentRevision       string            `json:"content_revision"`
	EmoticonID            int64             `json:"emoticon_id"`
	EntitlementVersion    int64             `json:"entitlement_version"`
}
type Delivery struct {
	Occurrence      Occurrence `json:"occurrence"`
	Status          Status     `json:"status"`
	Version         int64      `json:"version"`
	ClaimGeneration int64      `json:"claim_generation"`
	OwnerFence      int64      `json:"owner_fence"`
	ExpiresAt       *time.Time `json:"expires_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

func (o Occurrence) Validate() error {
	u, e := ids.ParseUUID(o.ID)
	if e != nil || u.IsZero() || !o.Sender.Valid() || !o.Recipient.Valid() || o.Sender == o.Recipient || o.Sequence < 1 || o.AcceptedAt.IsZero() || o.AcceptedAt.Unix() < 0 || o.AcceptedAt.Unix() > 9007199254740991 || o.FriendshipGeneration < 1 || o.RecipientBlockVersion < 0 || o.EntitlementVersion < 0 || o.EmoticonID < 0 || len(o.Digest) != 64 {
		return ErrInvalid
	}
	if _, e := hex.DecodeString(o.Digest); e != nil {
		return ErrInvalid
	}
	decoded, e := friendmessage.Decode(o.Message)
	if e != nil {
		return ErrInvalid
	}
	canonical, e := decoded.Canonical()
	if e != nil || canonical != o.Message || decoded.EmoticonID != o.EmoticonID {
		return ErrInvalid
	}
	if o.EmoticonID == 0 {
		if o.ContentRevision != "" || o.EntitlementVersion != 0 {
			return ErrInvalid
		}
	} else {
		if len(o.ContentRevision) != 64 {
			return ErrInvalid
		}
		if _, e := hex.DecodeString(o.ContentRevision); e != nil {
			return ErrInvalid
		}
	}
	return nil
}
func (d Delivery) Validate() error {
	if d.Occurrence.Validate() != nil || !d.Status.Valid() || d.Version < 1 || d.ClaimGeneration < 0 || d.UpdatedAt.Before(d.Occurrence.AcceptedAt) {
		return ErrInvalid
	}
	if d.ExpiresAt == nil {
		if d.OwnerFence != 0 {
			return ErrInvalid
		}
	} else if d.Status != Pending || d.OwnerFence < 1 || d.ClaimGeneration < 1 || !d.ExpiresAt.After(d.UpdatedAt) {
		return ErrInvalid
	}
	return nil
}
func (d Delivery) ActiveLease(at time.Time) bool {
	return d.Status == Pending && d.ExpiresAt != nil && at.Before(*d.ExpiresAt)
}
func (d Delivery) Eligible(p socialrelation.FriendDMPrivacy) bool {
	return p.Eligible && p.FriendshipGeneration == d.Occurrence.FriendshipGeneration && p.RecipientBlockVersion == d.Occurrence.RecipientBlockVersion
}

type Manifest struct {
	Recipient      identity.PlayerID `json:"recipient"`
	Version        int64             `json:"version"`
	NextSequence   int64             `json:"next_sequence"`
	LastDecisionAt time.Time         `json:"last_decision_at"`
	Rows           []Delivery        `json:"rows"`
}

func (m Manifest) Digest() string {
	b, _ := json.Marshal(m)
	h := sha256.Sum256(b)
	return hex.EncodeToString(h[:])
}
func (m Manifest) Validate() error {
	if !m.Recipient.Valid() || m.Version < 0 || len(m.Rows) > PendingLimit {
		return ErrInvalid
	}
	if m.Version == 0 {
		if m.NextSequence != 0 || len(m.Rows) != 0 || !m.LastDecisionAt.IsZero() {
			return ErrInvalid
		}
	} else if m.NextSequence < 1 || m.LastDecisionAt.IsZero() {
		return ErrInvalid
	}
	var seq int64
	for _, d := range m.Rows {
		if d.Validate() != nil || d.Status != Pending || d.Occurrence.Recipient != m.Recipient || d.Occurrence.Sequence <= seq || d.Occurrence.Sequence >= m.NextSequence {
			return ErrInvalid
		}
		seq = d.Occurrence.Sequence
	}
	return nil
}

type Projection struct {
	PlayerID identity.PlayerID `json:"player_id"`
	Message  string            `json:"message"`
	Time     int64             `json:"time"`
}

func Project(o Occurrence) Projection {
	return Projection{PlayerID: o.Sender, Message: o.Message, Time: o.AcceptedAt.UTC().Unix()}
}

type ProjectionReceipt struct {
	OperationID    string
	Recipient      identity.PlayerID
	ManifestDigest string
	ObservedAt     time.Time
	Messages       []Projection
}
type Change struct {
	Before          Delivery
	Status          Status
	ClaimGeneration int64
	OwnerFence      int64
	ExpiresAt       *time.Time
	At              time.Time
}

func LockKey(id identity.PlayerID) (lockkey.Key, error) {
	if !id.Valid() {
		return lockkey.Key{}, ErrInvalid
	}
	return lockkey.New(LockRank, "friend-dm.recipient", lockkey.Int64(int64(id)))
}

func (p Projection) Validate() error {
	if _, e := socialrelation.CanonicalServer(p.PlayerID); e != nil || p.Time < 0 || p.Time > 9007199254740991 {
		return ErrInvalid
	}
	m, e := friendmessage.Decode(p.Message)
	if e != nil {
		return ErrInvalid
	}
	raw, e := m.Canonical()
	if e != nil || raw != p.Message {
		return ErrInvalid
	}
	return nil
}
