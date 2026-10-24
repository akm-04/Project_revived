package logicalserver

import (
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"time"
)

var ErrObservationRequired = errors.New("new character requires same-session MID18 observation")

type PlayerRoot struct {
	PlayerID                identity.PlayerID
	AccountID               identity.AccountID
	LogicalServerID         identity.LogicalServerID
	CreatedAt               time.Time
	BootstrapProfileVersion string
	FirstEntryPending       bool
	StateVersion            int64
}
type BootstrapContext struct {
	AccountID               identity.AccountID
	SessionID               identity.SessionID
	LogicalServerID         identity.LogicalServerID
	PlayerID                identity.PlayerID
	Operation               operation.Context
	BootstrapProfileVersion string
}
type BootstrapContributor interface {
	Name() string
	Required() bool
	Apply(BootstrapContext) error
}
type BootstrapResult struct {
	Server  Server
	Player  PlayerRoot
	Created bool
}

// PlanCharacter is a pure transaction model. The caller supplies whether the
// UNIQUE(account,server) row exists and whether the same live session observed
// the server via MID18. Failed contributors return no mutated server cursor.
func PlanCharacter(server Server, account identity.AccountID, session identity.SessionID, existing *PlayerRoot, observed bool, op operation.Context, profile string, contributors []BootstrapContributor) (BootstrapResult, error) {
	if existing != nil {
		if existing.AccountID != account || existing.LogicalServerID != server.ID {
			return BootstrapResult{}, errors.New("existing player binding mismatch")
		}
		if err := server.ExistingAdmission(); err != nil {
			return BootstrapResult{}, err
		}
		return BootstrapResult{Server: server, Player: *existing, Created: false}, nil
	}
	if !observed {
		return BootstrapResult{}, ErrObservationRequired
	}
	allocated, pid, err := server.Allocate()
	if err != nil {
		return BootstrapResult{}, err
	}
	if profile == "" {
		return BootstrapResult{}, errors.New("bootstrap profile required")
	}
	player := PlayerRoot{PlayerID: pid, AccountID: account, LogicalServerID: server.ID, CreatedAt: op.StartedAt.UTC(), BootstrapProfileVersion: profile, FirstEntryPending: true, StateVersion: 1}
	ctx := BootstrapContext{AccountID: account, SessionID: session, LogicalServerID: server.ID, PlayerID: pid, Operation: op, BootstrapProfileVersion: profile}
	for _, c := range contributors {
		if c == nil {
			continue
		}
		if err := c.Apply(ctx); err != nil && c.Required() {
			return BootstrapResult{}, err
		}
	}
	return BootstrapResult{Server: allocated, Player: player, Created: true}, nil
}
func MID1IsNew(p PlayerRoot) int64 {
	if p.FirstEntryPending {
		return 1
	}
	return 0
}
