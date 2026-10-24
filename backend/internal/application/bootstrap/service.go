package bootstrap

import (
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type MID1Command struct {
	Account                 identity.Account
	Session                 identity.Session
	Server                  logicalserver.Server
	ExistingPlayer          *logicalserver.PlayerRoot
	Observed                bool
	ExistingContext         *identity.GameplayContext
	NewContextID            identity.ContextID
	Operation               operation.Context
	BootstrapProfileVersion string
	Contributors            []logicalserver.BootstrapContributor
	BearerSecret            []byte
}
type MID1Result struct {
	Token         string                   `json:"token"`
	Region        int32                    `json:"region"`
	UID           identity.AccountUID      `json:"uid"`
	Detail        map[string]any           `json:"detail"`
	IsNew         int64                    `json:"is_new"`
	Player        logicalserver.PlayerRoot `json:"-"`
	Server        logicalserver.Server     `json:"-"`
	ContextPlan   identity.SelectionPlan   `json:"-"`
	PlayerCreated bool                     `json:"-"`
}

// PlanMID1 preserves transaction ordering: character admission/bootstrap is fully
// planned before a target-change context is superseded. A persistence adapter
// applies this plan atomically with the semantic receipt under I1's tx runner.
func PlanMID1(c MID1Command) (MID1Result, error) {
	if !c.Account.Live() || !c.Session.Live(c.Operation.StartedAt) || c.Session.AccountID != c.Account.ID {
		return MID1Result{}, errors.New("account session not live")
	}
	ch, err := logicalserver.PlanCharacter(c.Server, c.Account.ID, c.Session.ID, c.ExistingPlayer, c.Observed, c.Operation, c.BootstrapProfileVersion, c.Contributors)
	if err != nil {
		return MID1Result{}, err
	}
	plan, err := identity.PlanSelection(c.ExistingContext, c.Session, identity.Target{LogicalServerID: c.Server.ID, PlayerID: ch.Player.PlayerID}, c.NewContextID, c.Operation.StartedAt)
	if err != nil {
		return MID1Result{}, err
	}
	token, err := identity.DeriveGameplayBearer(c.BearerSecret, plan.Selected)
	if err != nil {
		return MID1Result{}, err
	}
	return MID1Result{Token: token, Region: int32(c.Server.ID), UID: c.Account.UID, Detail: map[string]any{}, IsNew: logicalserver.MID1IsNew(ch.Player), Player: ch.Player, Server: ch.Server, ContextPlan: plan, PlayerCreated: ch.Created}, nil
}

type MID18Result = logicalserver.MID18View

func ProjectMID18(servers []logicalserver.Server, players []logicalserver.PlayerSummary) MID18Result {
	return logicalserver.ProjectMID18(servers, players)
}
