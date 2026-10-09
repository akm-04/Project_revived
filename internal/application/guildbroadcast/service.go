package guildbroadcast

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/guild"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
	"time"
)

var (
	ErrContent  = errors.New("Guild broadcast policy unavailable")
	ErrConflict = errors.New("Guild broadcast proof conflict")
	ErrStale    = errors.New("Guild broadcast snapshot newer than bound decision")
	ErrLeader   = errors.New("Guild broadcast requires current leader")
)

const (
	Queue         = "guild.materialization"
	MailKind      = "guild.broadcast.mail.v1"
	ReconcileKind = "guild.broadcast.reconcile.v1"
	WorkerProfile = "guild-broadcast-mail-v1"
)

type sourceGuild interface {
	GuildReader
	ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error)
	AppendAuditTx(context.Context, tx.Tx, guild.ID, string, identity.PlayerID, identity.PlayerID, time.Time, string, ids.UUID, string) error
}
type SourceStore interface {
	Store
	ValidateSchema(context.Context, tx.Queryer) error
	ReadSourceReceiptIDTx(context.Context, tx.Queryer, ids.UUID) (ids.UUID, error)
}
type Service struct {
	Timed    gen.TimedRunner
	Reads    tx.Runner
	Fresh    tx.Queryer
	Store    SourceStore
	Guild    sourceGuild
	Names    playerroot.NameReader
	Players  playerroot.TxLocker
	Fence    guildcore.ActorFencer
	Receipts receipt.Store
	Content  ContentReader
	Enqueue  obligation.Queue
}
type SubmitResult struct {
	SourceID       ids.UUID `json:"source_id"`
	RecipientCount int      `json:"recipient_count"`
}

func sourceReceipt(pid identity.PlayerID, id ids.UUID) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(pid), 10), Domain: "guild-broadcast", Operation: "submit", SemanticKey: id.String()}
}
func bindContent(op operation.Context, p ContentPolicy) (operation.Context, error) {
	refs := op.Policies.Refs()
	for _, r := range []policy.Ref{{Name: "content", Version: p.Revision}, {Name: "guild-core", Version: p.GuildCoreRevision}, {Name: "guild-broadcast", Version: p.PolicyID}} {
		if v, ok := op.Policies.Get(r.Name); ok {
			if v != r.Version {
				return op, ErrConflict
			}
		} else {
			refs = append(refs, r)
		}
	}
	set, e := policy.NewSet(refs...)
	op.Policies = set
	return op, e
}

// positiveProof checks every immutable binding and the complete receipt/source
// pair. Receipt presence alone cannot hide a partial restore.
func (s Service) positiveProof(c context.Context, q tx.Queryer, actor identity.ActorContext, op operation.Context, request gb.Request) (SubmitResult, bool, error) {
	rid := sourceReceipt(actor.PlayerID, op.ID)
	rr, hasR, e := s.Receipts.FindTx(c, q, rid)
	if e != nil {
		return SubmitResult{}, false, e
	}
	source, hasS, e := s.Store.ReadSourceTx(c, q, op.ID)
	if e != nil {
		return SubmitResult{}, false, e
	}
	if !hasR && !hasS {
		return SubmitResult{}, false, nil
	}
	if !hasR || !hasS {
		return SubmitResult{}, false, ErrConflict
	}
	p, e := s.Content.ReadBroadcastPolicy(c, q, source.ContentRevision)
	if e != nil {
		return SubmitResult{}, false, e
	}
	if p.Validate() != nil || p.Revision != source.ContentRevision || p.GuildCoreRevision != source.GuildCoreRevision || p.PolicyID != source.PolicyID {
		return SubmitResult{}, false, ErrContent
	}
	fp, e := receipt.FingerprintRequest(request)
	if e != nil {
		return SubmitResult{}, false, e
	}
	if rr.Validate() != nil || rr.Identity != rid || rr.OperationClass != "I7A8A_GUILD_SOURCE" || rr.ResultSchema != "gxb.guild-broadcast.submit.v1" || rr.PolicyVersion != source.PolicyID || rr.ActorAccountUID != string(actor.AccountUID) || !bytes.Equal(rr.RequestFingerprint[:], fp[:]) || source.Request != request || source.LeaderID != actor.PlayerID || source.Server != actor.LogicalServerID || source.Operation.ID != op.ID || !source.Operation.StartedAt.Equal(op.StartedAt) || source.Operation.EntropySeed != op.EntropySeed || rr.OperationStartedAt.UnixMicro() != source.Operation.StartedAt.UnixMicro() || !rr.OperationPolicyRefs.Equal(source.Operation.Policies) {
		return SubmitResult{}, false, ErrConflict
	}
	for _, ref := range op.Policies.Refs() {
		v, ok := source.Operation.Policies.Get(ref.Name)
		if !ok || v != ref.Version {
			return SubmitResult{}, false, ErrConflict
		}
	}
	receiptID, e := s.Store.ReadSourceReceiptIDTx(c, q, op.ID)
	if e != nil || receiptID != rr.ID {
		return SubmitResult{}, false, ErrConflict
	}
	for _, m := range source.Recipients {
		b, ok, e := s.Store.ReadBindingTx(c, q, op.ID, m.PlayerID)
		if e != nil {
			return SubmitResult{}, false, e
		}
		if !ok || b.Validate() != nil {
			return SubmitResult{}, false, ErrConflict
		}
	}
	want := SubmitResult{SourceID: op.ID, RecipientCount: len(source.Recipients)}
	got, decodeErr := decodeSubmitResult(rr.ResultPayload)
	if decodeErr != nil || got != want {
		return SubmitResult{}, false, ErrConflict
	}
	return want, true, nil
}

type sourceResolver struct {
	s       Service
	actor   identity.ActorContext
	op      operation.Context
	request gb.Request
}

func (r sourceResolver) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	var out SubmitResult
	var found bool
	_, e := r.s.Reads.Run(c, r.op, guildcore.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		out, found, e = r.s.positiveProof(c, sc.Tx, r.actor, r.op, r.request)
		return e
	})
	if e != nil {
		return tx.Resolution{}, e
	}
	if !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: out}, nil
}
func (s Service) Submit(c context.Context, actor identity.ActorContext, request gb.Request, op operation.Context) (SubmitResult, error) {
	if s.Timed.Runner.DB == nil || s.Reads.DB == nil || s.Fresh == nil || s.Store == nil || s.Guild == nil || s.Names == nil || s.Players == nil || s.Fence == nil || s.Receipts == nil || s.Content == nil || s.Enqueue == nil || !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || op.ID.IsZero() || op.StartedAt.IsZero() {
		return SubmitResult{}, gb.ErrSource
	}
	if e := request.Validate(); e != nil {
		return SubmitResult{}, e
	}
	var existing SubmitResult
	var has bool
	var p ContentPolicy
	var gid guild.ID
	_, e := s.Reads.Run(c, op, guildcore.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		if e := s.Fence.FenceActorTx(c, sc.Tx, actor, op.StartedAt); e != nil {
			return e
		}
		var e error
		existing, has, e = s.positiveProof(c, sc.Tx, actor, op, request)
		if e != nil || has {
			return e
		}
		m, ok, e := s.Guild.ReadMembershipTx(c, sc.Tx, actor.PlayerID)
		if e != nil {
			return e
		}
		if !ok {
			return ErrLeader
		}
		gid = m.GuildID
		rev, ok := op.Policies.Get("content")
		if !ok {
			rev, e = s.Content.ActiveRevision(c, sc.Tx)
			if e != nil {
				return e
			}
		}
		p, e = s.Content.ReadBroadcastPolicy(c, sc.Tx, rev)
		return e
	})
	if e != nil {
		return SubmitResult{}, e
	}
	if has {
		return existing, nil
	}
	if e = p.Validate(); e != nil {
		return SubmitResult{}, e
	}
	bound, e := bindContent(op, p)
	if e != nil {
		return SubmitResult{}, e
	}
	var out SubmitResult
	_, _, e = s.Timed.Run(c, bound, guildcore.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, sourceResolver{s, actor, bound, request}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if e := s.Fence.FenceActorTx(c, sc.Tx, actor, at); e != nil {
			return e
		}
		prior, ok, e := s.positiveProof(c, sc.Tx, actor, bound, request)
		if e != nil {
			return e
		}
		if ok {
			out = prior
			return nil
		}
		g, ok, e := s.Guild.LockGuildTx(c, sc.Tx, gid)
		if e != nil {
			return e
		}
		if !ok || g.RetiredAt != nil || g.LogicalServerID != actor.LogicalServerID {
			return ErrLeader
		}
		if g.PolicyRevision != p.GuildCoreRevision {
			return ErrContent
		}
		if g.UpdatedAt.After(at) {
			return ErrStale
		}
		roster, e := s.Guild.ListMembershipsTx(c, sc.Tx, gid)
		if e != nil {
			return e
		}
		if len(roster) < 1 || len(roster) > p.MemberCap {
			return ErrConflict
		}
		pids := make([]identity.PlayerID, len(roster))
		for i, m := range roster {
			pids[i] = m.PlayerID
		}
		closed, e := guildcore.NewLockPlan(actor.LogicalServerID, gid, pids, false, nil, nil)
		if e != nil || len(closed.Keys) == 0 {
			return ErrConflict
		}
		roots, e := s.Players.LockPlayerRootsTx(c, sc.Tx, actor.LogicalServerID, pids)
		if e != nil {
			return e
		}
		if len(roots) != len(pids) {
			return ErrConflict
		}
		recipients := make([]gb.Member, 0, len(roster))
		leader := false
		for _, snapshot := range roster {
			m, ok, e := s.Guild.LockMembershipTx(c, sc.Tx, snapshot.PlayerID)
			if e != nil {
				return e
			}
			if !ok || !sameMembership(m, snapshot) || m.GuildID != gid {
				return ErrStale
			}
			if m.JoinedAt.After(at) || m.UpdatedAt.After(at) {
				return ErrStale
			}
			ev, ok, e := s.Guild.LatestMembershipEventTx(c, sc.Tx, m.PlayerID)
			if e != nil {
				return e
			}
			if !ok || ev.Kind != guild.EventJoin || ev.GuildID != gid || ev.EventID <= 0 || !ev.OccurredAt.Equal(m.JoinedAt) {
				return ErrConflict
			}
			recipients = append(recipients, gb.Member{PlayerID: m.PlayerID, JoinEventID: ev.EventID, JoinedAt: m.JoinedAt.UTC()})
			if m.PlayerID == actor.PlayerID && m.Role == guild.Leader {
				leader = true
			}
		}
		if !leader {
			return ErrLeader
		}
		name, e := s.Names.ReadNameSnapshotTx(c, sc.Tx, actor.PlayerID)
		if e != nil {
			return e
		}
		if name.Validate() != nil || name.PlayerID != actor.PlayerID || name.Server != actor.LogicalServerID {
			return ErrConflict
		}
		if name.ChangedAt.After(at) {
			return ErrStale
		}
		source := gb.Source{Operation: bound, GuildID: gid, Server: actor.LogicalServerID, LeaderID: actor.PlayerID, LeaderName: name.Name, NameSnapshotChangedAt: name.ChangedAt, DecisionAt: at, ContentRevision: p.Revision, GuildCoreRevision: p.GuildCoreRevision, PolicyID: p.PolicyID, Request: request, Recipients: recipients}
		if e = source.Validate(); e != nil {
			return e
		}
		out = SubmitResult{SourceID: op.ID, RecipientCount: len(recipients)}
		raw, _ := json.Marshal(out)
		fp, e := receipt.FingerprintRequest(request)
		if e != nil {
			return e
		}
		rr, e := receipt.New(bound, sourceReceipt(actor.PlayerID, bound.ID), "I7A8A_GUILD_SOURCE", "gxb.guild-broadcast.submit.v1", raw, fp)
		if e != nil {
			return e
		}
		rr.ActorAccountUID = string(actor.AccountUID)
		rr.ContextID = actor.ContextID.UUID()
		rr.PolicyVersion = p.PolicyID
		// Full310/315/320/350 plan is closed; no target Mail/economy locks are added.
		if e = s.Guild.AppendAuditTx(c, sc.Tx, gid, "BROADCAST", actor.PlayerID, actor.PlayerID, at, p.GuildCoreRevision, bound.ID, "{}"); e != nil {
			return e
		}
		if e = s.Store.InsertSourceTx(c, sc.Tx, source, rr.ID); e != nil {
			return e
		}
		for _, m := range recipients {
			binding := gb.Binding{SourceID: op.ID, RecipientID: m.PlayerID, State: gb.Pending, LastEnqueueAt: at, NextWakeupAt: at.Add(time.Minute)}
			if e = s.Store.InsertBindingTx(c, sc.Tx, binding, m); e != nil {
				return e
			}
			job, e := MailObligation(op.ID, m.PlayerID, at)
			if e != nil {
				return e
			}
			if e = s.Enqueue.InsertTx(c, sc.Tx, job); e != nil {
				return e
			}
		}
		put, e := s.Receipts.PutTx(c, sc.Tx, rr)
		if e != nil {
			return e
		}
		if !put.Inserted {
			return ErrConflict
		}
		return nil
	})
	return out, e
}

// References contain no caller-selected title, roster, time or mutable payload.
type MailReference struct {
	SourceID    string `json:"source_id"`
	RecipientID int64  `json:"recipient_id"`
}

func MailObligation(id ids.UUID, pid identity.PlayerID, at time.Time) (obligation.Obligation, error) {
	if id.IsZero() || !pid.Valid() || at.IsZero() {
		return obligation.Obligation{}, gb.ErrSource
	}
	raw, e := json.Marshal(MailReference{SourceID: id.String(), RecipientID: int64(pid)})
	if e != nil {
		return obligation.Obligation{}, e
	}
	return obligation.Obligation{Kind: MailKind, Queue: Queue, Profile: WorkerProfile, SemanticKey: fmt.Sprintf("%s:%d", id.String(), pid), DueAt: at, Args: raw}, nil
}

// Timestamp identity compares instants, not Go location pointers: pgx rows and
// PostgreSQL JSON snapshots can represent the same UTC instant differently.
func sameMembership(a, b guild.Membership) bool {
	return a.PlayerID == b.PlayerID && a.GuildID == b.GuildID && a.Role == b.Role && a.MembershipVersion == b.MembershipVersion && a.StateVersion == b.StateVersion && a.JoinedAt.Equal(b.JoinedAt) && a.UpdatedAt.Equal(b.UpdatedAt)
}
