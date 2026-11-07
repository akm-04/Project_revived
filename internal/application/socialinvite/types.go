// Package socialinvite owns the durable friend-invitation surface: one
// immutable inviter per invitee and once-only invitation mission claims. Codes,
// accounts, levels and mission configuration are supplied by their owners.
package socialinvite

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const PolicyVersion = "I9_10E_SOCIAL_INVITE_V1"

const (
	bindOperationClass  = "I9_10E_SOCIAL_INVITE_BIND"
	bindResultSchema    = "gxb.social.invite.bind.v1"
	claimOperationClass = "I9_10E_SOCIAL_INVITE_CLAIM"
	claimResultSchema   = "gxb.social.invite.claim.v1"

	maxInviteeRows = 512
	maxMissionRows = 512

	// InviteeLimit and ClaimLimit bound the MID 384 projections.
	InviteeLimit = 512
	ClaimLimit   = 512
)

var (
	ErrUnavailable  = errors.New("social invite: unavailable")
	ErrProof        = errors.New("social invite: invalid receipt proof")
	ErrFacts        = errors.New("social invite: unqualified facts")
	ErrBindRefused  = errors.New("social invite: binding refused")
	ErrClaimRefused = errors.New("social invite: claim not eligible or already claimed")
	ErrBindConflict = errors.New("social invite: binding lost race")
)

type ActorFence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Profile struct {
	PlayerID   identity.PlayerID
	Name       string
	AvatarID   int64
	RegionName string
}

func (p Profile) Validate(player identity.PlayerID) error {
	if p.PlayerID != player || p.Name == "" || p.AvatarID < 0 {
		return ErrFacts
	}
	return nil
}

// InviteeFacts carries the canonical observations a mission metric may read.
// HighestOwnedHeroLevel is a PRIVATE_POLICY type-3 projection (D493 item 5).
type InviteeFacts struct {
	Player                identity.PlayerID
	Name                  string
	AvatarID              int64
	RegionName            string
	AcademyLevel          int64
	OwnedHeroCount        int64
	HighestOwnedHeroLevel int64
	ChargeTotal           int64
}

func (f InviteeFacts) Validate() error {
	if !f.Player.Valid() || f.Name == "" || f.AvatarID < 0 || f.RegionName == "" || f.AcademyLevel < 0 || f.OwnedHeroCount < 0 || f.HighestOwnedHeroLevel < 0 || f.ChargeTotal < 0 {
		return ErrFacts
	}
	return nil
}

func (f InviteeFacts) domainFacts() domain.InviteeFacts {
	return domain.InviteeFacts{Player: f.Player, AcademyLevel: f.AcademyLevel, OwnedHeroCount: f.OwnedHeroCount, HighestOwnedHeroLevel: f.HighestOwnedHeroLevel, ChargeTotal: f.ChargeTotal}
}

type Snapshot struct {
	InviteCode  string
	InvitorID   identity.PlayerID
	InvitorName string
	Invitees    []InviteeFacts
	Claimed     []int64
}

func (s Snapshot) Validate(server identity.LogicalServerID) error {
	if s.InviteCode == "" {
		return ErrFacts
	}
	previous := identity.PlayerID(0)
	for _, invitee := range s.Invitees {
		if invitee.Validate() != nil || invitee.Player <= previous || identity.LogicalServerID(invitee.Player/100000) != server {
			return ErrFacts
		}
		previous = invitee.Player
	}
	previousAward := int64(0)
	for _, mission := range s.Claimed {
		if mission <= previousAward {
			return ErrFacts
		}
		previousAward = mission
	}
	return nil
}

type InviteReader interface {
	ReadInviteTx(context.Context, tx.Scope, identity.ActorContext, string, time.Time) (Snapshot, error)
}

type BindingRecord struct {
	Invitee, Inviter identity.PlayerID
	LogicalServerID  identity.LogicalServerID
	OperationID      ids.UUID
	PolicyVersion    string
	BoundAt          time.Time
}

func (r BindingRecord) Validate() error {
	if !r.Invitee.Valid() || !r.Inviter.Valid() || r.Invitee == r.Inviter || !r.LogicalServerID.Valid() || r.OperationID.IsZero() || r.PolicyVersion != PolicyVersion || r.BoundAt.IsZero() || r.BoundAt.Location() != time.UTC {
		return ErrFacts
	}
	if identity.LogicalServerID(r.Invitee/100000) != r.LogicalServerID || identity.LogicalServerID(r.Inviter/100000) != r.LogicalServerID {
		return ErrFacts
	}
	return nil
}

type ClaimRecord struct {
	Player, Mission int64
	LogicalServerID identity.LogicalServerID
	OperationID     ids.UUID
	ContentRevision string
	PolicyVersion   string
	GrantKey        string
	ClaimedAt       time.Time
}

func (r ClaimRecord) Validate() error {
	if r.Player <= 0 || r.Mission <= 0 || !r.LogicalServerID.Valid() || r.OperationID.IsZero() || r.PolicyVersion != PolicyVersion || r.GrantKey == "" || r.ClaimedAt.IsZero() || r.ClaimedAt.Location() != time.UTC || len(r.ContentRevision) != 64 {
		return ErrFacts
	}
	if identity.LogicalServerID(r.Player/100000) != r.LogicalServerID {
		return ErrFacts
	}
	return nil
}

// Owner is the socialinvite adapter boundary; it owns only its two tables.
type Owner interface {
	ReadBindingTx(context.Context, tx.Queryer, identity.PlayerID) (BindingRecord, bool, error)
	InsertBindingTx(context.Context, tx.Tx, BindingRecord) error
	InviteesForInviterTx(context.Context, tx.Queryer, identity.PlayerID, identity.LogicalServerID, int) ([]identity.PlayerID, error)
	ClaimsTx(context.Context, tx.Queryer, identity.PlayerID, identity.LogicalServerID) ([]int64, error)
	InsertClaimTx(context.Context, tx.Tx, ClaimRecord) error
}

type FactsReader interface {
	ReadPlayerProfileTx(context.Context, tx.Tx, identity.PlayerID) (Profile, error)
	ReadAccountTx(context.Context, tx.Queryer, identity.PlayerID) (identity.AccountID, error)
	ReadAcademyLevelTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error)
	ReadInviteeFactsTx(context.Context, tx.Scope, identity.PlayerID, string, time.Time) (InviteeFacts, error)
}

// Mission is one source invitation_mission row. PRIVATE_POLICY (D493 item 5):
// type 3 compares the invited player's highest currently owned battle girl
// level; the other types use their existing canonical metric owners.
type Mission struct {
	ID            int64
	Type          domain.MissionType
	RequiredCount int64
	Threshold     int64
	Diamond       int64
}

func (m Mission) Validate() error {
	if m.ID <= 0 || m.RequiredCount < 1 || m.RequiredCount > 10 || m.Diamond <= 0 {
		return ErrFacts
	}
	return domain.Mission{ID: m.ID, Type: m.Type, Threshold: m.Threshold}.Validate()
}

type MissionCatalog []Mission

func (c MissionCatalog) Validate() error {
	if len(c) == 0 || len(c) > maxMissionRows {
		return ErrFacts
	}
	previous := int64(0)
	for _, mission := range c {
		if mission.Validate() != nil || mission.ID <= previous {
			return ErrFacts
		}
		previous = mission.ID
	}
	return nil
}

func (c MissionCatalog) Find(id int64) (Mission, bool) {
	for _, mission := range c {
		if mission.ID == id {
			return mission, true
		}
	}
	return Mission{}, false
}

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	SocialInvitationMissionsTx(context.Context, tx.Queryer, string) (MissionCatalog, error)
}

// BindInvitePolicies adds the exact content/roster/invite pins used by this
// family. A conflicting existing pin is never replaced.
func BindInvitePolicies(current operation.Context, revision string) (operation.Context, error) {
	references := current.Policies.Refs()
	for _, wanted := range []policy.Ref{{Name: "content", Version: revision}, {Name: "roster-metrics", Version: characterasset.RosterMetricPolicy}, {Name: "socialinvite", Version: PolicyVersion}} {
		if existing, found := current.Policies.Get(wanted.Name); found {
			if existing != wanted.Version {
				return current, ErrProof
			}
			continue
		}
		references = append(references, wanted)
	}
	var err error
	current.Policies, err = policy.NewSet(references...)
	return current, err
}
