package identity

import (
	"errors"
	"time"
)

type Target struct {
	LogicalServerID LogicalServerID
	PlayerID        PlayerID
}
type SelectionKind uint8

const (
	SelectionCoalesced SelectionKind = iota + 1
	SelectionCreated
)

type SelectionPlan struct {
	Kind     SelectionKind
	Previous *GameplayContext
	Selected GameplayContext
}

// PlanSelection is pure: admission/bootstrap must succeed before a target-change
// plan is applied. This preserves the old context on 20018/bootstrap failure.
func PlanSelection(existing *GameplayContext, session Session, target Target, newID ContextID, now time.Time) (SelectionPlan, error) {
	if !target.LogicalServerID.Valid() || !target.PlayerID.Valid() {
		return SelectionPlan{}, errors.New("invalid target")
	}
	if existing != nil && existing.Live() {
		if existing.SessionID != session.ID || existing.AccountID != session.AccountID {
			return SelectionPlan{}, errors.New("existing context parent mismatch")
		}
		if existing.LogicalServerID == target.LogicalServerID && existing.PlayerID == target.PlayerID {
			return SelectionPlan{Kind: SelectionCoalesced, Previous: existing, Selected: *existing}, nil
		}
	}
	if newID.UUID().IsZero() {
		return SelectionPlan{}, errors.New("new context id required")
	}
	generation := int64(1)
	if existing != nil && existing.ContextGeneration >= generation {
		generation = existing.ContextGeneration + 1
	}
	selected := GameplayContext{ID: newID, SessionID: session.ID, AccountID: session.AccountID, LogicalServerID: target.LogicalServerID, PlayerID: target.PlayerID, ContextGeneration: generation, CreatedAt: now.UTC(), LivenessVersion: 1}
	var prev *GameplayContext
	if existing != nil && existing.Live() {
		cp := *existing
		ended := now.UTC()
		cp.EndedAt = &ended
		cp.EndReason = "superseded"
		cp.LivenessVersion++
		prev = &cp
	}
	return SelectionPlan{Kind: SelectionCreated, Previous: prev, Selected: selected}, nil
}

func ActorFrom(account Account, session Session, c GameplayContext, now time.Time) (ActorContext, error) {
	if !account.Live() || !account.UID.Valid() || !session.Live(now) || !c.Live() || session.AccountID != account.ID || c.SessionID != session.ID || c.AccountID != account.ID {
		return ActorContext{}, errors.New("auth liveness failure")
	}
	return ActorContext{AccountID: account.ID, AccountUID: account.UID, SessionID: session.ID, ContextID: c.ID, LogicalServerID: c.LogicalServerID, PlayerID: c.PlayerID, ContextGeneration: c.ContextGeneration, SessionLivenessVersion: session.LivenessVersion, ContextLivenessVersion: c.LivenessVersion}, nil
}
