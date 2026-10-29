package arena

import (
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"time"
)

const FriendFightContractIdentifier = "I9_FRIEND_FIGHT_V1"
const FriendFightPolicyIdentifier = "I9_FRIEND_FIGHT_POLICY_V1"
const FriendFightInvitationLifetime = time.Minute

const (
	FriendInvitationPending  = "PENDING"
	FriendInvitationAccepted = "ACCEPTED"
	FriendInvitationRejected = "REJECTED"
	FriendInvitationExpired  = "EXPIRED"
)

type FriendInvitation struct {
	Identifier   ids.UUID          `json:"identifier"`
	Inviter      AdmissionContext  `json:"inviter"`
	Recipient    identity.PlayerID `json:"recipient"`
	Mode         int               `json:"mode"`
	GameType     int               `json:"game_type"`
	Status       string            `json:"status"`
	Room         ids.UUID          `json:"room"`
	CreatedAt    time.Time         `json:"created_at"`
	ExpiresAt    time.Time         `json:"expires_at"`
	Sequence     int64             `json:"sequence"`
	StateVersion int64             `json:"state_version"`
}

func (invitation FriendInvitation) Validate() error {
	if invitation.Identifier.IsZero() || !invitation.Recipient.Valid() || invitation.Recipient == invitation.Inviter.PlayerID || invitation.Mode < 1 || invitation.Mode > 2 || invitation.GameType < 1 || invitation.GameType > 2 || invitation.Sequence < 1 || invitation.StateVersion < 1 || invitation.CreatedAt.IsZero() || !invitation.ExpiresAt.Equal(invitation.CreatedAt.Add(FriendFightInvitationLifetime)) {
		return ErrInvalid
	}
	if _, err := invitation.Inviter.Actor(); err != nil {
		return err
	}
	switch invitation.Status {
	case FriendInvitationAccepted:
		if invitation.Room.IsZero() {
			return ErrInvalid
		}
	case FriendInvitationPending, FriendInvitationRejected, FriendInvitationExpired:
		if !invitation.Room.IsZero() {
			return ErrInvalid
		}
	default:
		return ErrInvalid
	}
	return nil
}
