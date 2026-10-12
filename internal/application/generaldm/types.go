package generaldm

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/domain/player"
	"strings"
	"time"
	"unicode/utf8"
)

const (
	LockRank        uint16 = 381
	PolicyID               = "GENERAL_DM_DEADLINE_V1"
	WakeupRoute            = "personal.dm.v1"
	IntentLifetime         = 8 * time.Second
	ClaimLease             = 2 * time.Second
	MaxMessageRunes        = 140
	MaxBindings            = 64
)

var (
	ErrInvalid            = errors.New("general dm invalid request or state")
	ErrUnavailable        = errors.New("general dm unavailable")
	ErrPrivacySuppressed  = errors.New("general dm privacy suppressed")
	ErrAdmissionRetired   = errors.New("general dm admission retired")
	ErrTimeInvalid        = errors.New("general dm completion time invalid")
	ErrAttemptAlreadyMade = errors.New("general dm attempt already made")
	ErrChanged            = errors.New("general dm state changed")
)

type Status string

const (
	Pending               Status = "PENDING"
	Claimed               Status = "CLAIMED"
	Attempting            Status = "ATTEMPTING"
	WrittenBeforeDeadline Status = "WRITTEN_BEFORE_DEADLINE"
	Undelivered           Status = "UNDELIVERED"
	Expired               Status = "EXPIRED"
	PrivacySuppressed     Status = "PRIVACY_SUPPRESSED"
	AdmissionRetired      Status = "ADMISSION_RETIRED"
	TimeInvalid           Status = "TIME_INVALID"
	Unknown               Status = "UNKNOWN"
)

func (s Status) Terminal() bool {
	switch s {
	case WrittenBeforeDeadline, Undelivered, Expired, PrivacySuppressed, AdmissionRetired, TimeInvalid, Unknown:
		return true
	}
	return false
}

type Binding struct {
	ContextID            string `json:"context_id"`
	ContextGeneration    int64  `json:"context_generation"`
	SessionID            string `json:"session_id"`
	SessionLiveness      int64  `json:"session_liveness"`
	ContextLiveness      int64  `json:"context_liveness"`
	RealtimeInstanceID   string `json:"realtime_instance_id"`
	ConnectionGeneration int64  `json:"connection_generation"`
	OwnerFence           int64  `json:"owner_fence"`
	LogicalServerID      int64  `json:"logical_server_id"`
}

func (b Binding) Valid() bool {
	return b.ContextID != "" && b.SessionID != "" && b.RealtimeInstanceID != "" && b.ContextGeneration > 0 && b.SessionLiveness > 0 && b.ContextLiveness > 0 && b.ConnectionGeneration > 0 && b.OwnerFence > 0 && b.LogicalServerID > 0
}

type Intent struct {
	ID                  string
	Digest              string
	Sender              int64
	Recipient           int64
	Message             string
	SenderName          string
	SenderType          int64
	SenderAvatarID      int64
	SenderAvatarFrameID int64
	SenderLevel         int64
	SenderConquerLevel  int64
	SenderConquerLoopID int64
	AcceptedAt          time.Time
	ExpiresAt           time.Time
	BlockVersion        int64
	Bindings            []Binding
	Status              Status
	StateVersion        int64
	ClaimGeneration     int64
	OwnerFence          int64
	LeaseExpiresAt      *time.Time
	LastObservedAt      time.Time
	AttemptCommittedAt  *time.Time
	CompletionUpper     *time.Time
	// Empty fields are omitted to preserve the exact legacy payload digest. Never backfill.
	SenderTitleInfo  string `json:",omitempty"`
	SenderBubbleInfo string `json:",omitempty"`
}

func ValidateMessage(s string) error {
	if !utf8.ValidString(s) || strings.TrimSpace(s) == "" || utf8.RuneCountInString(s) > MaxMessageRunes || len(s) > 2048 {
		return ErrInvalid
	}
	return nil
}
func (i Intent) Validate() error {
	if i.SenderTitleInfo != "" && !player.ValidateChatCosmeticString(i.SenderTitleInfo, true) || i.SenderBubbleInfo != "" && !player.ValidateChatCosmeticString(i.SenderBubbleInfo, false) {
		return ErrInvalid
	}
	if i.ID == "" || len(i.Digest) != 64 || i.Sender < 1 || i.Recipient < 1 || i.Sender == i.Recipient || i.AcceptedAt.IsZero() || i.ExpiresAt.Sub(i.AcceptedAt) != IntentLifetime || i.BlockVersion < 0 || i.StateVersion < 1 || i.ClaimGeneration < 0 || !i.StatusValid() {
		return ErrInvalid
	}
	if _, e := hex.DecodeString(i.Digest); e != nil {
		return ErrInvalid
	}
	if !i.Status.Terminal() {
		if ValidateMessage(i.Message) != nil || len(i.Bindings) == 0 || len(i.Bindings) > MaxBindings {
			return ErrInvalid
		}
		for _, b := range i.Bindings {
			if !b.Valid() {
				return ErrInvalid
			}
		}
	}
	if i.Status == Claimed && (i.LeaseExpiresAt == nil || i.OwnerFence < 1 || i.ClaimGeneration < 1) {
		return ErrInvalid
	}
	if i.Status == Attempting && i.AttemptCommittedAt == nil {
		return ErrInvalid
	}
	if i.LastObservedAt.IsZero() || i.LastObservedAt.Before(i.AcceptedAt) {
		return ErrInvalid
	}
	if i.Status == WrittenBeforeDeadline && (i.CompletionUpper == nil || i.CompletionUpper.IsZero() || i.AttemptCommittedAt == nil || i.AttemptCommittedAt.Before(i.AcceptedAt) || i.CompletionUpper.Before(*i.AttemptCommittedAt) || !i.CompletionUpper.Before(i.ExpiresAt) || !i.LastObservedAt.Before(i.ExpiresAt) || i.OwnerFence < 1 || i.ClaimGeneration < 1) {
		return ErrInvalid
	}
	return nil
}
func (i Intent) StatusValid() bool {
	return i.Status == Pending || i.Status == Claimed || i.Status == Attempting || i.Status.Terminal()
}
func Digest(a, b int64, msg string) string {
	v, _ := json.Marshal(struct {
		Sender, Recipient int64
		Message           string
	}{a, b, msg})
	h := sha256.Sum256(v)
	return hex.EncodeToString(h[:])
}
func (i Intent) Claim(now time.Time, fence int64) (Intent, error) {
	if i.Validate() != nil || i.Status != Pending || now.Before(i.AcceptedAt) || !now.Before(i.ExpiresAt) || fence < 1 {
		return Intent{}, ErrInvalid
	}
	lease := now.Add(ClaimLease)
	if lease.After(i.ExpiresAt) {
		lease = i.ExpiresAt
	}
	i.Status = Claimed
	i.StateVersion++
	i.ClaimGeneration++
	i.OwnerFence = fence
	i.LeaseExpiresAt = &lease
	i.LastObservedAt = now
	return i, nil
}
func (i Intent) BeginAttempt(now time.Time) (Intent, error) {
	if i.Status != Claimed || i.LeaseExpiresAt == nil || !now.Before(*i.LeaseExpiresAt) || !now.Before(i.ExpiresAt) || now.Before(i.LastObservedAt) {
		return Intent{}, ErrAttemptAlreadyMade
	}
	i.Status = Attempting
	i.StateVersion++
	i.AttemptCommittedAt = &now
	i.LastObservedAt = now
	return i, nil
}
func (i Intent) Terminal(status Status, at time.Time) Intent {
	if i.Status.Terminal() {
		return i
	}
	i.Status = status
	i.StateVersion++
	i.LastObservedAt = at
	i.LeaseExpiresAt = nil
	return i
}
func (i Intent) Finish(now, upper time.Time, wrote bool) (Intent, error) {
	if i.Status != Attempting {
		return Intent{}, ErrAttemptAlreadyMade
	}
	if !wrote {
		return i.Terminal(Unknown, now), nil
	}
	if upper.IsZero() || !upper.Before(i.ExpiresAt) || upper.Before(*i.AttemptCommittedAt) || now.Before(i.LastObservedAt) {
		return i.Terminal(TimeInvalid, now), ErrTimeInvalid
	}
	i = i.Terminal(WrittenBeforeDeadline, now)
	i.CompletionUpper = &upper
	return i, nil
}
