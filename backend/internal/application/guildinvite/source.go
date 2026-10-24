package guildinvite

import (
	"context"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"time"
)

type SourceService struct {
	Reads    tx.Runner
	Store    Store
	Bindings GuildBindings
	History  HistoricalGenerationReader
	Reader   SourceReader
	Content  ContentReader
	Queryer  tx.Queryer
	Enqueue  obligation.Queue
}

func (s SourceService) Admit(c context.Context, op operation.Context, core string) (operation.Context, bool, error) {
	if s.Store == nil || s.Bindings == nil || s.History == nil || s.Content == nil || s.Queryer == nil || s.Enqueue == nil {
		return op, false, gi.ErrEvidence
	}
	rev, e := s.Content.ActiveRevision(c, s.Queryer)
	if e != nil {
		return op, false, e
	}
	p, ok, e := s.Content.ReadInvitePolicy(c, s.Queryer, rev)
	if e != nil {
		return op, false, e
	}
	if !ok {
		return op, false, nil
	}
	if p.Validate() != nil || p.Revision != rev || p.GuildCoreRevision != core {
		return op, false, gi.ErrEvidence
	}
	refs := op.Policies.Refs()
	for _, add := range []policy.Ref{{Name: "content", Version: rev}, {Name: "guild-invite", Version: gi.PolicyID}} {
		if v, exists := op.Policies.Get(add.Name); exists {
			if v != add.Version {
				return op, false, gi.ErrEvidence
			}
		} else {
			refs = append(refs, add)
		}
	}
	op.Policies, e = policy.NewSet(refs...)
	return op, e == nil, e
}

type IssuePlan struct {
	caller        tx.Tx
	source        gi.Issue
	cursorVersion int64
	prepared      bool
}

func (p IssuePlan) Generation() int64 { return p.source.Tuple.Generation }

type MarkerPlan struct {
	caller   tx.Tx
	marker   gi.Marker
	prepared bool
}

func sameCaller(a, b tx.Tx) bool {
	x, y := reflect.ValueOf(a), reflect.ValueOf(b)
	return x.IsValid() && y.IsValid() && x.Type() == y.Type() && x.Comparable() && x.Equal(y)
}

// PrepareIssueTx enters cursor340 then source350 under the caller's closed
// Guild310/sorted315/membership320/Invite340 plan, before any business effect.
func (s SourceService) PrepareIssueTx(c context.Context, t tx.Tx, g guild.Guild, a identity.ActorContext, target identity.PlayerID, current int64, op operation.Context, at, expires time.Time) (IssuePlan, error) {
	if t == nil || g.Validate() != nil || g.RetiredAt != nil || a.LogicalServerID != g.LogicalServerID || a.PlayerID == target || at.Before(op.StartedAt) || !expires.After(at) {
		return IssuePlan{}, gi.ErrEvidence
	}
	cursor, ver, e := s.Store.LockCursorTx(c, t, g.ID, target)
	if e != nil {
		return IssuePlan{}, e
	}
	high, e := s.History.GuildInviteGenerationHighWaterTx(c, t, g.ID, target)
	if e != nil {
		return IssuePlan{}, e
	}
	gen, e := gi.NextGeneration(cursor, current, high)
	if e != nil {
		return IssuePlan{}, e
	}
	join, has, e := s.Bindings.LatestJoinTx(c, t, target)
	if e != nil {
		return IssuePlan{}, e
	}
	if e = s.Store.PrepareScopeTx(c, t, g.ID); e != nil {
		return IssuePlan{}, e
	}
	serial, e := s.Store.NextIssueSerialTx(c, t)
	if e != nil {
		return IssuePlan{}, e
	}
	rev, ok := op.Policies.Get("content")
	if !ok {
		return IssuePlan{}, gi.ErrEvidence
	}
	v := gi.Issue{Operation: op, Tuple: gi.Tuple{GuildID: g.ID, Recipient: target, Generation: gen}, Serial: serial, Server: g.LogicalServerID, Inviter: a.PlayerID, ActorAccountUID: string(a.AccountUID), DecisionAt: at.UTC(), ExpiresAt: expires.UTC(), GuildName: g.Name, ContentRevision: rev, GuildCoreRevision: g.PolicyRevision, PolicyID: gi.PolicyID}
	if has {
		v.LastJoinEventID = join.EventID
		v.LastJoinedAt = join.OccurredAt.UTC()
	}
	return IssuePlan{caller: t, source: v, cursorVersion: ver, prepared: true}, nil
}

func (s SourceService) ApplyIssueTx(c context.Context, t tx.Tx, p IssuePlan, sendID int64, rr receipt.Receipt) error {
	if !p.prepared || !sameCaller(p.caller, t) {
		return gi.ErrEvidence
	}
	v := p.source
	v.SendEventID = sendID
	v.Core = coreWitness(rr)
	if v.Validate() != nil || validateCore(rr, v.Core, v.Tuple.GuildID) != nil {
		return gi.ErrEvidence
	}
	if e := s.Store.AdvanceCursorTx(c, t, v.Tuple, p.cursorVersion, v.DecisionAt); e != nil {
		return e
	}
	d := gi.Delivery{SourceID: v.Operation.ID, Recipient: v.Tuple.Recipient, State: gi.Pending, LastEnqueueAt: v.DecisionAt, NextWakeupAt: v.DecisionAt.Add(time.Minute)}
	if e := s.Store.InsertIssueTx(c, t, v, d); e != nil {
		return e
	}
	if e := s.Bindings.BindInviteIssueTx(c, t, v); e != nil {
		return e
	}
	job, e := IssueObligation(v.Operation.ID, v.DecisionAt)
	if e != nil {
		return e
	}
	return s.Enqueue.InsertTx(c, t, job)
}

func (s SourceService) PrepareMarkerTx(c context.Context, t tx.Tx, g guild.Guild, a identity.ActorContext, subject identity.PlayerID, kind gi.MarkerKind, op operation.Context, at time.Time) (MarkerPlan, error) {
	if t == nil || g.Validate() != nil || kind != gi.Join && kind != gi.Retire || at.Before(op.StartedAt) {
		return MarkerPlan{}, gi.ErrEvidence
	}
	if kind == gi.Retire {
		if e := s.Bindings.PrepareRetirementChildrenTx(c, t, g.ID); e != nil {
			return MarkerPlan{}, e
		}
	}
	if e := s.Store.PrepareScopeTx(c, t, g.ID); e != nil {
		return MarkerPlan{}, e
	}
	high, e := s.Store.IssueHighWaterTx(c, t)
	if e != nil {
		return MarkerPlan{}, e
	}
	latest, present, e := s.Store.LatestMarkerSourceDecisionTx(c, t, kind, g.ID, subject, high)
	if e != nil {
		return MarkerPlan{}, e
	}
	if present && at.Before(latest) {
		return MarkerPlan{}, gi.ErrEvidence
	}
	rev, ok := op.Policies.Get("content")
	if !ok {
		return MarkerPlan{}, gi.ErrEvidence
	}
	m := gi.Marker{Operation: op, Kind: kind, GuildID: g.ID, Server: g.LogicalServerID, Actor: a.PlayerID, Subject: subject, ActorAccountUID: string(a.AccountUID), DecisionAt: at.UTC(), MaxIssueSerial: high, ContentRevision: rev, GuildCoreRevision: g.PolicyRevision, PolicyID: gi.PolicyID}
	return MarkerPlan{caller: t, marker: m, prepared: true}, nil
}

func (s SourceService) ApplyMarkerTx(c context.Context, t tx.Tx, p MarkerPlan, event guild.MembershipEvent, rr receipt.Receipt) error {
	if !p.prepared || !sameCaller(p.caller, t) {
		return gi.ErrEvidence
	}
	m := p.marker
	m.EventID = event.EventID
	m.Core = coreWitness(rr)
	kind := guild.EventJoin
	if m.Kind == gi.Retire {
		kind = guild.EventDissolve
	}
	if m.Validate() != nil || validateCore(rr, m.Core, m.GuildID) != nil || event.Kind != kind || event.GuildID != m.GuildID || event.PlayerID != m.Subject || event.ActorPlayerID != m.Actor || !event.OccurredAt.Equal(m.DecisionAt) || event.PolicyRevision != m.GuildCoreRevision {
		return gi.ErrEvidence
	}
	progress := gi.MarkerProgress{MarkerID: m.Operation.ID, MaxIssueSerial: m.MaxIssueSerial, LastEnqueueAt: m.DecisionAt, NextWakeupAt: m.DecisionAt.Add(time.Minute)}
	if e := s.Store.InsertMarkerTx(c, t, m, progress); e != nil {
		return e
	}
	if e := s.Bindings.BindMembershipMarkerTx(c, t, m); e != nil {
		return e
	}
	job, e := MarkerObligation(m.Operation.ID, m.DecisionAt)
	if e != nil {
		return e
	}
	return s.Enqueue.InsertTx(c, t, job)
}

func (s SourceService) ValidateCurrentInviteTx(c context.Context, q tx.Queryer, inv guild.Invite) error {
	id, e := s.Bindings.ReadInviteIssueIDTx(c, q, inv.GuildID, inv.InvitedPlayerID)
	if e != nil {
		return e
	}
	if id.IsZero() {
		_, exists, e := s.Store.ReadIssueTupleTx(c, q, gi.Tuple{GuildID: inv.GuildID, Recipient: inv.InvitedPlayerID, Generation: inv.Generation})
		if e != nil {
			return e
		}
		if exists {
			return gi.ErrEvidence
		}
		return nil
	}
	v, e := s.Reader.ReadIssueEvidenceTx(c, q, id)
	if e != nil {
		return e
	}
	if v.Tuple.GuildID != inv.GuildID || v.Tuple.Recipient != inv.InvitedPlayerID || v.Tuple.Generation != inv.Generation || v.Inviter != inv.InviterPlayerID || v.DecisionAt.UnixMicro() != inv.CreatedAt.UnixMicro() || v.ExpiresAt.UnixMicro() != inv.ExpiresAt.UnixMicro() {
		return gi.ErrEvidence
	}
	return nil
}

func (s SourceService) ValidateMembershipTx(c context.Context, q tx.Queryer, event guild.MembershipEvent) error {
	id, e := s.Bindings.ReadMembershipMarkerIDTx(c, q, event.EventID)
	if e != nil {
		return e
	}
	if id.IsZero() {
		retained, e := s.Store.FindMarkerForEventTx(c, q, event.EventID)
		if e != nil {
			return e
		}
		if !retained.IsZero() {
			return gi.ErrEvidence
		}
		return nil
	}
	m, e := s.Reader.ReadMarkerEvidenceTx(c, q, id)
	if e != nil {
		return e
	}
	if m.EventID != event.EventID || m.GuildID != event.GuildID || m.Subject != event.PlayerID {
		return gi.ErrEvidence
	}
	return nil
}

func (s SourceService) ValidateRetirementTx(c context.Context, q tx.Queryer, gid guild.ID) error {
	event, ok, e := s.Bindings.ReadRetirementEventTx(c, q, gid)
	if e != nil {
		return e
	}
	if !ok {
		return gi.ErrEvidence
	}
	return s.ValidateMembershipTx(c, q, event)
}

// ValidateCommitted is for known and UNKNOWN-positive command reconciliation.
// Absence remains an error/unknown, never permission to replay an ambiguous op.
func (s SourceService) ValidateCommitted(c context.Context, id ids.UUID, issue bool) error {
	if s.Reads.DB == nil || id.IsZero() {
		return gi.ErrEvidence
	}
	_, e := s.Reads.Run(c, operation.Context{}, ProgressProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, scope tx.Scope) error {
		if issue {
			_, e := s.Reader.ReadIssueEvidenceTx(c, scope.Tx, id)
			return e
		}
		_, e := s.Reader.ReadMarkerEvidenceTx(c, scope.Tx, id)
		return e
	})
	return e
}
