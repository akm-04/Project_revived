package guildcore

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strconv"
	"time"

	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appinvite "gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrNotGuildMember        = errors.New("actor is not a guild member")
	ErrGuildPermission       = errors.New("guild role does not authorize operation")
	ErrApplicationNotFound   = errors.New("guild application not found")
	ErrInviteNotFound        = errors.New("guild invite not found")
	ErrInviteExpired         = errors.New("guild invite expired")
	ErrInviteLimit           = errors.New("guild rolling invite limit reached")
	ErrTargetAlreadyMember   = errors.New("target already has guild membership")
	ErrTargetNotMember       = errors.New("target is not a member of this guild")
	ErrCannotLeaveLeader     = errors.New("guild leader cannot leave")
	ErrDissolveRequiresSolo  = errors.New("guild dissolution requires solo leader")
	ErrInvalidRoleChange     = errors.New("invalid guild role change")
	ErrInvalidDescription    = errors.New("invalid guild description")
	ErrInvalidSettings       = errors.New("invalid guild settings")
	ErrDeputyLimit           = errors.New("guild deputy limit reached")
	ErrMembershipIncarnation = errors.New("guild membership incarnation invariant violated")
)

type AckResult struct {
	GuildID  int64 `json:"guild_id,omitempty"`
	Replayed bool  `json:"-"`
}

type SettingsRequest struct {
	Name          string
	Icon          int64
	IconFrame     int64
	MinAllowLevel int64
	ApplyType     guild.ApplyType
}

type RoleRequest struct {
	MemberID identity.PlayerID
	Role     guild.Role
}

type TargetRequest struct{ PlayerID identity.PlayerID }

type GuildRequest struct{ GuildID guild.ID }

func (s Service) actorGuildHint(ctx context.Context, actor identity.ActorContext) (guild.ID, error) {
	m, ok, err := s.Store.ReadMembership(ctx, actor.PlayerID)
	if err != nil {
		return 0, err
	}
	if !ok {
		return 0, ErrNotGuildMember
	}
	return m.GuildID, nil
}

func roleCanManage(role guild.Role) bool { return role == guild.Leader || role == guild.Deputy }
func roleCanInvite(role guild.Role) bool { return roleCanManage(role) }

func (s Service) lockGuildActorTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, gid guild.ID) (guild.Guild, guild.Membership, error) {
	g, ok, err := s.Store.LockGuildTx(ctx, t, gid)
	if err != nil {
		return guild.Guild{}, guild.Membership{}, err
	}
	if !ok {
		return guild.Guild{}, guild.Membership{}, ErrGuildNotFound
	}
	if g.RetiredAt != nil {
		return guild.Guild{}, guild.Membership{}, ErrGuildRetired
	}
	if g.LogicalServerID != actor.LogicalServerID {
		return guild.Guild{}, guild.Membership{}, ErrGuildRegionMismatch
	}
	if _, err := s.PlayerRoots.LockPlayerRootsTx(ctx, t, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID}); err != nil {
		return guild.Guild{}, guild.Membership{}, err
	}
	m, ok, err := s.Store.LockMembershipTx(ctx, t, actor.PlayerID)
	if err != nil {
		return guild.Guild{}, guild.Membership{}, err
	}
	if !ok || m.GuildID != gid {
		return guild.Guild{}, guild.Membership{}, ErrNotGuildMember
	}
	return g, m, nil
}

func (s Service) lockGuildActorTargetTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, gid guild.ID, target identity.PlayerID) (guild.Guild, guild.Membership, guild.Membership, bool, error) {
	if !target.Valid() {
		return guild.Guild{}, guild.Membership{}, guild.Membership{}, false, ErrTargetNotMember
	}
	g, ok, err := s.Store.LockGuildTx(ctx, t, gid)
	if err != nil {
		return guild.Guild{}, guild.Membership{}, guild.Membership{}, false, err
	}
	if !ok {
		return guild.Guild{}, guild.Membership{}, guild.Membership{}, false, ErrGuildNotFound
	}
	if g.RetiredAt != nil {
		return guild.Guild{}, guild.Membership{}, guild.Membership{}, false, ErrGuildRetired
	}
	if g.LogicalServerID != actor.LogicalServerID {
		return guild.Guild{}, guild.Membership{}, guild.Membership{}, false, ErrGuildRegionMismatch
	}
	ids := []identity.PlayerID{actor.PlayerID, target}
	if _, err := s.PlayerRoots.LockPlayerRootsTx(ctx, t, actor.LogicalServerID, ids); err != nil {
		return guild.Guild{}, guild.Membership{}, guild.Membership{}, false, err
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	var am, tm guild.Membership
	var aok, tok bool
	var last identity.PlayerID
	for _, pid := range ids {
		if pid == last {
			continue
		}
		last = pid
		m, mok, err := s.Store.LockMembershipTx(ctx, t, pid)
		if err != nil {
			return guild.Guild{}, guild.Membership{}, guild.Membership{}, false, err
		}
		if pid == actor.PlayerID {
			am, aok = m, mok
		}
		if pid == target {
			tm, tok = m, mok
		}
	}
	if !aok || am.GuildID != gid {
		return guild.Guild{}, guild.Membership{}, guild.Membership{}, false, ErrNotGuildMember
	}
	return g, am, tm, tok, nil
}

func semanticReceipt(ownerKey, operationName, semantic string) receipt.Identity {
	return receipt.Identity{OwnerKind: "guild", OwnerKey: ownerKey, Domain: "guild", Operation: operationName, SemanticKey: semantic}
}

// currentMembershipIncarnationTx resolves the non-reused identity of the
// currently locked membership from the append-only JOIN fact that created it.
// membership_version remains mutable current-row state and is deliberately not
// a cross-membership incarnation. Under the PlayerRoot/membership lock plan, a
// current membership whose latest event is not its same-Guild JOIN is corrupt
// and must fail closed rather than fall back to the collision-prone v1 key.
func (s Service) currentMembershipIncarnationTx(ctx context.Context, q tx.Queryer, m guild.Membership) (int64, error) {
	ev, ok, err := s.Store.LatestMembershipEventTx(ctx, q, m.PlayerID)
	if err != nil {
		return 0, err
	}
	if !ok || ev.EventID <= 0 || ev.PlayerID != m.PlayerID || ev.GuildID != m.GuildID || ev.Kind != guild.EventJoin {
		return 0, ErrMembershipIncarnation
	}
	return ev.EventID, nil
}

func (s Service) putAckReceipt(ctx context.Context, t tx.Tx, bound operation.Context, actor identity.ActorContext, rid receipt.Identity, fp [32]byte, profile string, out AckResult) error {
	_, err := s.putAckReceiptReturning(ctx, t, bound, string(actor.AccountUID), actor.ContextID.UUID(), rid, fp, profile, out)
	return err
}

func priorAck(ctx context.Context, rs receipt.Store, q tx.Queryer, rid receipt.Identity, fp [32]byte) (AckResult, bool, error) {
	prior, ok, err := rs.FindTx(ctx, q, rid)
	if err != nil || !ok {
		return AckResult{}, ok, err
	}
	if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
		return AckResult{}, false, &receipt.ConflictError{Identity: rid}
	}
	var out AckResult
	if err := json.Unmarshal(prior.ResultPayload, &out); err != nil {
		return AckResult{}, false, err
	}
	out.Replayed = true
	return out, true, nil
}

func (s Service) CancelApplication(ctx context.Context, actor identity.ActorContext, gid guild.ID, op operation.Context) (AckResult, error) {
	if err := s.validate(); err != nil {
		return AckResult{}, err
	}
	bound, err := bindGuildPolicy(op, s.Policy.Revision)
	if err != nil {
		return AckResult{}, err
	}
	fp, err := receipt.FingerprintRequest(GuildRequest{gid})
	if err != nil {
		return AckResult{}, err
	}
	var out AckResult
	resolver := &dynamicResolver{reader: s.ReceiptRead}
	_, _, err = s.Timed.Run(ctx, bound, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		g, ok, err := s.Store.LockGuildTx(txctx, scope.Tx, gid)
		if err != nil {
			return err
		}
		if !ok {
			return ErrGuildNotFound
		}
		if g.LogicalServerID != actor.LogicalServerID {
			return ErrGuildRegionMismatch
		}
		if _, err := s.PlayerRoots.LockPlayerRootsTx(txctx, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID}); err != nil {
			return err
		}
		a, ok, err := s.Store.LockApplicationTx(txctx, scope.Tx, gid, actor.PlayerID)
		if err != nil {
			return err
		}
		if !ok {
			out = AckResult{GuildID: int64(gid), Replayed: true}
			return nil
		}
		rid := semanticReceipt(strconv.FormatInt(int64(gid), 10), "cancel_application", fmt.Sprintf("player:%d:gen:%d", actor.PlayerID, a.Generation))
		resolver.set(rid, fp)
		if prior, ok, err := priorAck(txctx, s.Receipts, scope.Tx, rid, fp); err != nil {
			return err
		} else if ok {
			out = prior
			return nil
		}
		if err := s.Store.DeleteApplicationTx(txctx, scope.Tx, gid, actor.PlayerID); err != nil {
			return err
		}
		if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "CANCEL_APPLY", actor.PlayerID, actor.PlayerID, at, s.Policy.Revision, bound.ID, "{}"); err != nil {
			return err
		}
		out = AckResult{GuildID: int64(gid)}
		return s.putAckReceipt(txctx, scope.Tx, bound, actor, rid, fp, "gxb.i6c.guild.cancel_application.v1", out)
	})
	return out, err
}

func (s Service) RefuseApplication(ctx context.Context, actor identity.ActorContext, target identity.PlayerID, op operation.Context) (AckResult, error) {
	if err := s.validate(); err != nil {
		return AckResult{}, err
	}
	gid, err := s.actorGuildHint(ctx, actor)
	if err != nil {
		return AckResult{}, err
	}
	bound, err := bindGuildPolicy(op, s.Policy.Revision)
	if err != nil {
		return AckResult{}, err
	}
	fp, err := receipt.FingerprintRequest(TargetRequest{target})
	if err != nil {
		return AckResult{}, err
	}
	var out AckResult
	resolver := &dynamicResolver{reader: s.ReceiptRead}
	_, _, err = s.Timed.Run(ctx, bound, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		_, am, _, _, err := s.lockGuildActorTargetTx(txctx, scope.Tx, actor, gid, target)
		if err != nil {
			return err
		}
		if !roleCanManage(am.Role) {
			return ErrGuildPermission
		}
		a, ok, err := s.Store.LockApplicationTx(txctx, scope.Tx, gid, target)
		if err != nil {
			return err
		}
		if !ok {
			out = AckResult{GuildID: int64(gid), Replayed: true}
			return nil
		}
		rid := semanticReceipt(strconv.FormatInt(int64(gid), 10), "refuse_application", fmt.Sprintf("target:%d:gen:%d", target, a.Generation))
		resolver.set(rid, fp)
		if prior, ok, err := priorAck(txctx, s.Receipts, scope.Tx, rid, fp); err != nil {
			return err
		} else if ok {
			out = prior
			return nil
		}
		if err := s.Store.DeleteApplicationTx(txctx, scope.Tx, gid, target); err != nil {
			return err
		}
		if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "REFUSE_APPLY", actor.PlayerID, target, at, s.Policy.Revision, bound.ID, "{}"); err != nil {
			return err
		}
		out = AckResult{GuildID: int64(gid)}
		return s.putAckReceipt(txctx, scope.Tx, bound, actor, rid, fp, "gxb.i6c.guild.refuse_application.v1", out)
	})
	return out, err
}

func (s Service) AcceptApplication(ctx context.Context, actor identity.ActorContext, target identity.PlayerID, op operation.Context) (AckResult, error) {
	ctx, cancel := context.WithTimeout(ctx, s.profile().OperationTimeout)
	defer cancel()
	if err := s.validate(); err != nil {
		return AckResult{}, err
	}
	gid, err := s.actorGuildHint(ctx, actor)
	if err != nil {
		return AckResult{}, err
	}
	bound, err := bindGuildPolicy(op, s.Policy.Revision)
	if err != nil {
		return AckResult{}, err
	}
	bound, projected, err := s.admitInviteProjection(ctx, bound)
	if err != nil {
		return AckResult{}, err
	}
	fp, err := receipt.FingerprintRequest(TargetRequest{target})
	if err != nil {
		return AckResult{}, err
	}
	var out AckResult
	resolver := &dynamicResolver{reader: s.ReceiptRead}
	_, _, err = s.Timed.Run(ctx, bound, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		g, am, tm, tok, err := s.lockGuildActorTargetTx(txctx, scope.Tx, actor, gid, target)
		if err != nil {
			return err
		}
		if !roleCanManage(am.Role) {
			return ErrGuildPermission
		}
		if tok {
			if tm.GuildID == gid {
				if err := s.validateMembershipProjectionTx(txctx, scope.Tx, tm); err != nil {
					return err
				}
				out = AckResult{GuildID: int64(gid), Replayed: true}
				return nil
			}
			return ErrTargetAlreadyMember
		}
		count, err := s.Store.CountMembersTx(txctx, scope.Tx, gid)
		if err != nil {
			return err
		}
		if count >= s.Policy.Policy.MemberCap {
			return ErrGuildFull
		}
		if projected {
			if err := s.InviteProjection.Bindings.PrepareMembershipCleanupTx(txctx, scope.Tx, target); err != nil {
				return err
			}
		}
		a, ok, err := s.Store.LockApplicationTx(txctx, scope.Tx, gid, target)
		if err != nil {
			return err
		}
		if !ok {
			return ErrApplicationNotFound
		}
		rid := semanticReceipt(strconv.FormatInt(int64(gid), 10), "accept_application", fmt.Sprintf("target:%d:gen:%d", target, a.Generation))
		resolver.set(rid, fp)
		if prior, ok, err := priorAck(txctx, s.Receipts, scope.Tx, rid, fp); err != nil {
			return err
		} else if ok {
			out = prior
			return nil
		}
		if err := s.checkJoinGatesTx(txctx, scope.Tx, target, gid, at); err != nil {
			return err
		}
		// PlayerRoot315 and the prepared membership320 absence fence
		// precede the application330 lock; effects follow all preparation.
		var plan appinvite.MarkerPlan
		if projected {
			plan, err = s.InviteProjection.PrepareMarkerTx(txctx, scope.Tx, g, actor, target, gi.Join, bound, at)
			if err != nil {
				return err
			}
			s.bindProjectionResolver(resolver, bound.ID, false)
		}
		m := guild.Membership{PlayerID: target, GuildID: gid, Role: guild.Member, JoinedAt: at, MembershipVersion: 1, StateVersion: 1, UpdatedAt: at}
		if err := s.Store.InsertMembershipTx(txctx, scope.Tx, m); err != nil {
			return err
		}
		if err := s.Store.DeleteApplicationTx(txctx, scope.Tx, gid, target); err != nil {
			return err
		}
		if err := s.Store.DeleteApplicationsForPlayerTx(txctx, scope.Tx, target); err != nil {
			return err
		}
		ev := guild.MembershipEvent{PlayerID: target, GuildID: gid, Kind: guild.EventJoin, OccurredAt: at, ActorPlayerID: actor.PlayerID, PolicyRevision: s.Policy.Revision}
		ev, err = s.appendProjectionEventTx(txctx, scope.Tx, ev, bound.ID, projected)
		if err != nil {
			return err
		}
		if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "ACCEPT_APPLY", actor.PlayerID, target, at, s.Policy.Revision, bound.ID, "{}"); err != nil {
			return err
		}
		level, err := s.Level.PlayerLevelTx(txctx, scope.Tx, target)
		if err != nil {
			return err
		}
		if level < g.MinAllowLevel {
			return ErrLevelTooLow
		}
		out = AckResult{GuildID: int64(gid)}
		rr, err := s.putAckReceiptReturning(txctx, scope.Tx, bound, string(actor.AccountUID), actor.ContextID.UUID(), rid, fp, "gxb.i6c.guild.accept_application.v1", out)
		if err != nil {
			return err
		}
		if projected {
			return s.InviteProjection.ApplyMarkerTx(txctx, scope.Tx, plan, ev, rr)
		}
		return nil
	})
	return out, err
}

func (s Service) checkJoinGatesTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, gid guild.ID, at time.Time) error {
	p := s.Policy.Policy
	if lastG, _, leftAt, has, err := s.Store.LastDepartureTx(ctx, q, pid); err != nil {
		return err
	} else if has {
		wait := p.JoinOtherAfterLeaveSeconds
		kind := JoinCooldownOtherGuild
		if lastG == gid {
			wait = p.ReapplyPreviousGuildSeconds
			kind = JoinCooldownSameGuild
		}
		until := leftAt.Add(time.Duration(wait) * time.Second)
		if at.Before(until) {
			return &CantJoinError{Kind: kind, RemainingSeconds: int64(until.Sub(at).Seconds() + 0.999999)}
		}
	}
	joins, err := s.Store.CountJoinsSinceTx(ctx, q, pid, at.Add(-7*24*time.Hour))
	if err != nil {
		return err
	}
	if joins >= p.JoinsLimit {
		return ErrJoinLimit
	}
	return nil
}

func (s Service) Leave(ctx context.Context, actor identity.ActorContext, op operation.Context) (AckResult, error) {
	if err := s.validate(); err != nil {
		return AckResult{}, err
	}
	gid, err := s.actorGuildHint(ctx, actor)
	if err != nil {
		return AckResult{}, err
	}
	return s.removeSelf(ctx, actor, gid, guild.EventLeave, "leave", op)
}
func (s Service) removeSelf(ctx context.Context, actor identity.ActorContext, gid guild.ID, kind guild.MembershipEventKind, opName string, op operation.Context) (AckResult, error) {
	bound, err := bindGuildPolicy(op, s.Policy.Revision)
	if err != nil {
		return AckResult{}, err
	}
	fp, err := receipt.FingerprintRequest(struct{ GuildID int64 }{int64(gid)})
	if err != nil {
		return AckResult{}, err
	}
	var out AckResult
	resolver := &dynamicResolver{reader: s.ReceiptRead}
	_, _, err = s.Timed.Run(ctx, bound, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		_, m, err := s.lockGuildActorTx(txctx, scope.Tx, actor, gid)
		if err != nil {
			if errors.Is(err, ErrNotGuildMember) {
				out = AckResult{GuildID: int64(gid), Replayed: true}
				return nil
			}
			return err
		}
		if m.Role == guild.Leader {
			return ErrCannotLeaveLeader
		}
		incarnation, err := s.currentMembershipIncarnationTx(txctx, scope.Tx, m)
		if err != nil {
			return err
		}
		rid := semanticReceipt(strconv.FormatInt(int64(gid), 10), opName, fmt.Sprintf("v2:player:%d:inc:%d:memberver:%d", actor.PlayerID, incarnation, m.MembershipVersion))
		resolver.set(rid, fp)
		if prior, ok, err := priorAck(txctx, s.Receipts, scope.Tx, rid, fp); err != nil {
			return err
		} else if ok {
			out = prior
			return nil
		}
		if err := s.Store.DeleteMembershipTx(txctx, scope.Tx, actor.PlayerID, gid, m.StateVersion); err != nil {
			return err
		}
		ev := guild.MembershipEvent{PlayerID: actor.PlayerID, GuildID: gid, Kind: kind, OccurredAt: at, ActorPlayerID: actor.PlayerID, PolicyRevision: s.Policy.Revision}
		if err := s.Store.AppendMembershipEventTx(txctx, scope.Tx, ev, bound.ID); err != nil {
			return err
		}
		if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "LEAVE", actor.PlayerID, actor.PlayerID, at, s.Policy.Revision, bound.ID, "{}"); err != nil {
			return err
		}
		out = AckResult{GuildID: int64(gid)}
		return s.putAckReceipt(txctx, scope.Tx, bound, actor, rid, fp, "gxb.i6c.guild.leave.v2", out)
	})
	return out, err
}

func (s Service) Dissolve(ctx context.Context, actor identity.ActorContext, op operation.Context) (AckResult, error) {
	ctx, cancel := context.WithTimeout(ctx, s.profile().OperationTimeout)
	defer cancel()
	if err := s.validate(); err != nil {
		return AckResult{}, err
	}
	gid, err := s.actorGuildHint(ctx, actor)
	if err != nil {
		return AckResult{}, err
	}
	bound, err := bindGuildPolicy(op, s.Policy.Revision)
	if err != nil {
		return AckResult{}, err
	}
	bound, projected, err := s.admitInviteProjection(ctx, bound)
	if err != nil {
		return AckResult{}, err
	}
	fp, err := receipt.FingerprintRequest(struct{ GuildID int64 }{int64(gid)})
	if err != nil {
		return AckResult{}, err
	}
	var out AckResult
	resolver := &dynamicResolver{reader: s.ReceiptRead}
	_, _, err = s.Timed.Run(ctx, bound, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		g, ok, err := s.Store.LockGuildTx(txctx, scope.Tx, gid)
		if err != nil {
			return err
		}
		if !ok || g.RetiredAt != nil {
			if s.InviteProjection != nil {
				if err := s.InviteProjection.ValidateRetirementTx(txctx, scope.Tx, gid); err != nil {
					return err
				}
			}
			out = AckResult{GuildID: int64(gid), Replayed: true}
			return nil
		}
		if g.LogicalServerID != actor.LogicalServerID {
			return ErrGuildRegionMismatch
		}
		n, err := s.Store.CountMembersTx(txctx, scope.Tx, gid)
		if err != nil {
			return err
		}
		if n > 1 {
			return ErrDissolveRequiresSolo
		}
		old := g.StateVersion
		if _, err := s.PlayerRoots.LockPlayerRootsTx(txctx, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID}); err != nil {
			return err
		}
		m, mok, err := s.Store.LockMembershipTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		if !mok || m.GuildID != gid || m.Role != guild.Leader {
			return ErrGuildPermission
		}
		rid := semanticReceipt(strconv.FormatInt(int64(gid), 10), "dissolve", fmt.Sprintf("state:%d:memberver:%d", old, m.MembershipVersion))
		resolver.set(rid, fp)
		if prior, ok, err := priorAck(txctx, s.Receipts, scope.Tx, rid, fp); err != nil {
			return err
		} else if ok {
			out = prior
			return nil
		}
		var plan appinvite.MarkerPlan
		if projected {
			plan, err = s.InviteProjection.PrepareMarkerTx(txctx, scope.Tx, g, actor, actor.PlayerID, gi.Retire, bound, at)
			if err != nil {
				return err
			}
			s.bindProjectionResolver(resolver, bound.ID, false)
		}
		g.StateVersion++
		g.UpdatedAt = at
		g.RetiredAt = &at
		if err := s.Store.SaveGuildTx(txctx, scope.Tx, g, old); err != nil {
			return err
		}
		if err := s.Store.DeleteMembershipTx(txctx, scope.Tx, actor.PlayerID, gid, m.StateVersion); err != nil {
			return err
		}
		if err := s.Store.DeleteGuildApplicationsTx(txctx, scope.Tx, gid); err != nil {
			return err
		}
		if err := s.Store.DeleteGuildInvitesTx(txctx, scope.Tx, gid); err != nil {
			return err
		}
		ev := guild.MembershipEvent{PlayerID: actor.PlayerID, GuildID: gid, Kind: guild.EventDissolve, OccurredAt: at, ActorPlayerID: actor.PlayerID, PolicyRevision: s.Policy.Revision}
		ev, err = s.appendProjectionEventTx(txctx, scope.Tx, ev, bound.ID, projected)
		if err != nil {
			return err
		}
		if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "DISSOLVE", actor.PlayerID, actor.PlayerID, at, s.Policy.Revision, bound.ID, "{}"); err != nil {
			return err
		}
		out = AckResult{GuildID: int64(gid)}
		rr, err := s.putAckReceiptReturning(txctx, scope.Tx, bound, string(actor.AccountUID), actor.ContextID.UUID(), rid, fp, "gxb.i6c.guild.dissolve.v1", out)
		if err != nil {
			return err
		}
		if projected {
			return s.InviteProjection.ApplyMarkerTx(txctx, scope.Tx, plan, ev, rr)
		}
		return nil
	})
	return out, err
}

func (s Service) UpdateDescription(ctx context.Context, actor identity.ActorContext, des string, op operation.Context) (AckResult, error) {
	if err := s.validate(); err != nil {
		return AckResult{}, err
	}
	if !s.Policy.Policy.ValidBulletin(des) {
		return AckResult{}, ErrInvalidDescription
	}
	gid, err := s.actorGuildHint(ctx, actor)
	if err != nil {
		return AckResult{}, err
	}
	bound, err := bindGuildPolicy(op, s.Policy.Revision)
	if err != nil {
		return AckResult{}, err
	}
	fp, err := receipt.FingerprintRequest(struct{ Description string }{des})
	if err != nil {
		return AckResult{}, err
	}
	var out AckResult
	resolver := &dynamicResolver{reader: s.ReceiptRead}
	_, _, err = s.Timed.Run(ctx, bound, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		g, m, err := s.lockGuildActorTx(txctx, scope.Tx, actor, gid)
		if err != nil {
			return err
		}
		if !roleCanManage(m.Role) {
			return ErrGuildPermission
		}
		if g.Description == des {
			out = AckResult{GuildID: int64(gid), Replayed: true}
			return nil
		}
		rid := semanticReceipt(strconv.FormatInt(int64(gid), 10), "description", fmt.Sprintf("state:%d:%x", g.StateVersion, fp[:8]))
		resolver.set(rid, fp)
		if prior, ok, err := priorAck(txctx, s.Receipts, scope.Tx, rid, fp); err != nil {
			return err
		} else if ok {
			out = prior
			return nil
		}
		old := g.StateVersion
		g.Description = des
		g.StateVersion++
		g.UpdatedAt = at
		g.PolicyRevision = s.Policy.Revision
		if err := s.Store.SaveGuildTx(txctx, scope.Tx, g, old); err != nil {
			return err
		}
		if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "DESCRIPTION", actor.PlayerID, actor.PlayerID, at, s.Policy.Revision, bound.ID, "{}"); err != nil {
			return err
		}
		out = AckResult{GuildID: int64(gid)}
		return s.putAckReceipt(txctx, scope.Tx, bound, actor, rid, fp, "gxb.i6c.guild.description.v1", out)
	})
	return out, err
}

func (s Service) UpdateSettings(ctx context.Context, actor identity.ActorContext, req SettingsRequest, op operation.Context) (AckResult, error) {
	if err := s.validate(); err != nil {
		return AckResult{}, err
	}
	p := s.Policy.Policy
	if !p.ValidName(req.Name) || !p.AllowsIcon(req.Icon) || req.IconFrame != 0 || req.MinAllowLevel < p.JoinLevelMin || req.MinAllowLevel > p.JoinLevelMax || !req.ApplyType.Valid() {
		return AckResult{}, ErrInvalidSettings
	}
	gid, err := s.actorGuildHint(ctx, actor)
	if err != nil {
		return AckResult{}, err
	}
	bound, err := bindGuildPolicy(op, s.Policy.Revision)
	if err != nil {
		return AckResult{}, err
	}
	fp, err := receipt.FingerprintRequest(req)
	if err != nil {
		return AckResult{}, err
	}
	var out AckResult
	resolver := &dynamicResolver{reader: s.ReceiptRead}
	_, _, err = s.Timed.Run(ctx, bound, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		// Settings can rename a Guild. Acquire the rank-300 namespace lock
		// before the rank-310 Guild root so create/rename name decisions are
		// serialized without lock inversion. The allocator is not advanced.
		if _, _, err := s.Store.LockAllocatorTx(txctx, scope.Tx, actor.LogicalServerID, at); err != nil {
			return err
		}
		g, m, err := s.lockGuildActorTx(txctx, scope.Tx, actor, gid)
		if err != nil {
			return err
		}
		if !roleCanManage(m.Role) {
			return ErrGuildPermission
		}
		if g.Name == req.Name && g.Icon == req.Icon && g.IconFrame == req.IconFrame && g.MinAllowLevel == req.MinAllowLevel && g.ApplyType == req.ApplyType {
			out = AckResult{GuildID: int64(gid), Replayed: true}
			return nil
		}
		rename := g.Name != req.Name
		if rename {
			if taken, err := s.Store.GuildNameInUseTx(txctx, scope.Tx, actor.LogicalServerID, req.Name, gid); err != nil {
				return err
			} else if taken {
				return ErrGuildNameTaken
			}
		}
		rid := semanticReceipt(strconv.FormatInt(int64(gid), 10), "settings", fmt.Sprintf("state:%d:%x", g.StateVersion, fp[:8]))
		resolver.set(rid, fp)
		if prior, ok, err := priorAck(txctx, s.Receipts, scope.Tx, rid, fp); err != nil {
			return err
		} else if ok {
			out = prior
			return nil
		}
		old := g.StateVersion
		g.Name = req.Name
		g.Icon = req.Icon
		g.IconFrame = req.IconFrame
		g.MinAllowLevel = req.MinAllowLevel
		g.ApplyType = req.ApplyType
		g.StateVersion++
		g.UpdatedAt = at
		g.PolicyRevision = s.Policy.Revision
		if err := s.Store.SaveGuildTx(txctx, scope.Tx, g, old); err != nil {
			return err
		}
		if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "SETTINGS", actor.PlayerID, actor.PlayerID, at, s.Policy.Revision, bound.ID, "{}"); err != nil {
			return err
		}
		if rename {
			if _, err := s.Scalar.DebitScalarTx(txctx, scope.Tx, actor.PlayerID, "crystal", p.RenameCrystalCost, at); err != nil {
				return err
			}
		}
		out = AckResult{GuildID: int64(gid)}
		return s.putAckReceipt(txctx, scope.Tx, bound, actor, rid, fp, "gxb.i6c.guild.settings.v1", out)
	})
	return out, err
}

func (s Service) Kick(ctx context.Context, actor identity.ActorContext, target identity.PlayerID, op operation.Context) (AckResult, error) {
	if err := s.validate(); err != nil {
		return AckResult{}, err
	}
	gid, err := s.actorGuildHint(ctx, actor)
	if err != nil {
		return AckResult{}, err
	}
	bound, err := bindGuildPolicy(op, s.Policy.Revision)
	if err != nil {
		return AckResult{}, err
	}
	fp, err := receipt.FingerprintRequest(TargetRequest{target})
	if err != nil {
		return AckResult{}, err
	}
	var out AckResult
	resolver := &dynamicResolver{reader: s.ReceiptRead}
	_, _, err = s.Timed.Run(ctx, bound, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		_, am, tm, tok, err := s.lockGuildActorTargetTx(txctx, scope.Tx, actor, gid, target)
		if err != nil {
			return err
		}
		if !tok || tm.GuildID != gid {
			return ErrTargetNotMember
		}
		allowed := am.Role == guild.Leader && (tm.Role == guild.Member || tm.Role == guild.Deputy) || am.Role == guild.Deputy && tm.Role == guild.Member
		if !allowed {
			return ErrGuildPermission
		}
		actorIncarnation, err := s.currentMembershipIncarnationTx(txctx, scope.Tx, am)
		if err != nil {
			return err
		}
		targetIncarnation, err := s.currentMembershipIncarnationTx(txctx, scope.Tx, tm)
		if err != nil {
			return err
		}
		rid := semanticReceipt(strconv.FormatInt(int64(gid), 10), "kick", fmt.Sprintf("v2:actor:%d:actorinc:%d:target:%d:targetinc:%d:targetver:%d", actor.PlayerID, actorIncarnation, target, targetIncarnation, tm.MembershipVersion))
		resolver.set(rid, fp)
		if prior, ok, err := priorAck(txctx, s.Receipts, scope.Tx, rid, fp); err != nil {
			return err
		} else if ok {
			out = prior
			return nil
		}
		if err := s.Store.DeleteMembershipTx(txctx, scope.Tx, target, gid, tm.StateVersion); err != nil {
			return err
		}
		ev := guild.MembershipEvent{PlayerID: target, GuildID: gid, Kind: guild.EventKick, OccurredAt: at, ActorPlayerID: actor.PlayerID, PolicyRevision: s.Policy.Revision}
		if err := s.Store.AppendMembershipEventTx(txctx, scope.Tx, ev, bound.ID); err != nil {
			return err
		}
		if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "KICK", actor.PlayerID, target, at, s.Policy.Revision, bound.ID, "{}"); err != nil {
			return err
		}
		out = AckResult{GuildID: int64(gid)}
		return s.putAckReceipt(txctx, scope.Tx, bound, actor, rid, fp, "gxb.i6c.guild.kick.v2", out)
	})
	return out, err
}

func (s Service) SetRole(ctx context.Context, actor identity.ActorContext, req RoleRequest, op operation.Context) (AckResult, error) {
	if err := s.validate(); err != nil {
		return AckResult{}, err
	}
	if !req.MemberID.Valid() || !req.Role.Valid() || req.MemberID == actor.PlayerID {
		return AckResult{}, ErrInvalidRoleChange
	}
	gid, err := s.actorGuildHint(ctx, actor)
	if err != nil {
		return AckResult{}, err
	}
	bound, err := bindGuildPolicy(op, s.Policy.Revision)
	if err != nil {
		return AckResult{}, err
	}
	fp, err := receipt.FingerprintRequest(req)
	if err != nil {
		return AckResult{}, err
	}
	var out AckResult
	resolver := &dynamicResolver{reader: s.ReceiptRead}
	_, _, err = s.Timed.Run(ctx, bound, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		_, am, tm, tok, err := s.lockGuildActorTargetTx(txctx, scope.Tx, actor, gid, req.MemberID)
		if err != nil {
			return err
		}
		if !tok || tm.GuildID != gid {
			return ErrTargetNotMember
		}
		if am.Role != guild.Leader {
			return ErrGuildPermission
		}
		if tm.Role == req.Role {
			out = AckResult{GuildID: int64(gid), Replayed: true}
			return nil
		}
		valid := req.Role == guild.Leader && (tm.Role == guild.Member || tm.Role == guild.Deputy) || req.Role == guild.Deputy && tm.Role == guild.Member || req.Role == guild.Member && tm.Role == guild.Deputy
		if !valid {
			return ErrInvalidRoleChange
		}
		if req.Role == guild.Deputy && tm.Role == guild.Member {
			n, err := s.Store.CountRoleTx(txctx, scope.Tx, gid, guild.Deputy)
			if err != nil {
				return err
			}
			if n >= s.Policy.Policy.DeputyLimit {
				return ErrDeputyLimit
			}
		}
		actorIncarnation, err := s.currentMembershipIncarnationTx(txctx, scope.Tx, am)
		if err != nil {
			return err
		}
		targetIncarnation, err := s.currentMembershipIncarnationTx(txctx, scope.Tx, tm)
		if err != nil {
			return err
		}
		rid := semanticReceipt(strconv.FormatInt(int64(gid), 10), "set_role", fmt.Sprintf("v2:actor:%d:actorinc:%d:actorver:%d:target:%d:targetinc:%d:targetver:%d:role:%d", actor.PlayerID, actorIncarnation, am.MembershipVersion, req.MemberID, targetIncarnation, tm.MembershipVersion, req.Role))
		resolver.set(rid, fp)
		if prior, ok, err := priorAck(txctx, s.Receipts, scope.Tx, rid, fp); err != nil {
			return err
		} else if ok {
			out = prior
			return nil
		}
		if req.Role == guild.Leader {
			// The partial unique index permits only one LEADER. Demote the current
			// leader first inside the same transaction, then promote the target.
			// Any subsequent failure rolls both changes back atomically.
			oldA := am.StateVersion
			am.Role = guild.Member
			am.MembershipVersion++
			am.StateVersion++
			am.UpdatedAt = at
			if err := s.Store.SaveMembershipRoleTx(txctx, scope.Tx, am, oldA); err != nil {
				return err
			}
		}
		oldT := tm.StateVersion
		tm.Role = req.Role
		tm.MembershipVersion++
		tm.StateVersion++
		tm.UpdatedAt = at
		if err := s.Store.SaveMembershipRoleTx(txctx, scope.Tx, tm, oldT); err != nil {
			return err
		}
		if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "ROLE", actor.PlayerID, req.MemberID, at, s.Policy.Revision, bound.ID, fmt.Sprintf(`{"role":%d}`, req.Role)); err != nil {
			return err
		}
		out = AckResult{GuildID: int64(gid)}
		return s.putAckReceipt(txctx, scope.Tx, bound, actor, rid, fp, "gxb.i6c.guild.set_role.v2", out)
	})
	return out, err
}

func (s Service) Invite(ctx context.Context, actor identity.ActorContext, target identity.PlayerID, op operation.Context) (AckResult, error) {
	ctx, cancel := context.WithTimeout(ctx, s.profile().OperationTimeout)
	defer cancel()
	if err := s.validate(); err != nil {
		return AckResult{}, err
	}
	if !target.Valid() || target == actor.PlayerID {
		return AckResult{}, ErrInvalidSettings
	}
	gid, err := s.actorGuildHint(ctx, actor)
	if err != nil {
		return AckResult{}, err
	}
	bound, err := bindGuildPolicy(op, s.Policy.Revision)
	if err != nil {
		return AckResult{}, err
	}
	bound, projected, err := s.admitInviteProjection(ctx, bound)
	if err != nil {
		return AckResult{}, err
	}
	fp, err := receipt.FingerprintRequest(TargetRequest{target})
	if err != nil {
		return AckResult{}, err
	}
	var out AckResult
	resolver := &dynamicResolver{reader: s.ReceiptRead}
	_, _, err = s.Timed.Run(ctx, bound, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		g, am, _, tok, err := s.lockGuildActorTargetTx(txctx, scope.Tx, actor, gid, target)
		if err != nil {
			return err
		}
		if !roleCanInvite(am.Role) {
			return ErrGuildPermission
		}
		if tok {
			return ErrTargetAlreadyMember
		}
		ex, exists, err := s.Store.LockInviteTx(txctx, scope.Tx, gid, target)
		if err != nil {
			return err
		}
		if exists && (projected && at.Before(ex.ExpiresAt) || !projected && !at.After(ex.ExpiresAt)) {
			if s.InviteProjection != nil {
				if err := s.InviteProjection.ValidateCurrentInviteTx(txctx, scope.Tx, ex); err != nil {
					return err
				}
			}
			out = AckResult{GuildID: int64(gid), Replayed: true}
			return nil
		}
		count, err := s.Store.CountInvitesSinceTx(txctx, scope.Tx, actor.PlayerID, at.Add(-24*time.Hour))
		if err != nil {
			return err
		}
		if count >= s.Policy.Policy.InviteSendLimit {
			return ErrInviteLimit
		}
		gen := positiveGeneration(bound.Derive("guild.invite-generation", uint64(target)))
		var plan appinvite.IssuePlan
		if projected {
			current := int64(0)
			if exists {
				current = ex.Generation
			}
			plan, err = s.InviteProjection.PrepareIssueTx(txctx, scope.Tx, g, actor, target, current, bound, at, at.Add(time.Duration(s.Policy.Policy.InviteLifetimeSeconds)*time.Second))
			if err != nil {
				return err
			}
			gen = plan.Generation()
			s.bindProjectionResolver(resolver, bound.ID, true)
		}
		inv := guild.Invite{GuildID: gid, InvitedPlayerID: target, Generation: gen, InviterPlayerID: actor.PlayerID, CreatedAt: at, ExpiresAt: at.Add(time.Duration(s.Policy.Policy.InviteLifetimeSeconds) * time.Second), StateVersion: 1}
		rid := semanticReceipt(strconv.FormatInt(int64(gid), 10), "invite", fmt.Sprintf("actorver:%d:target:%d:gen:%d", am.MembershipVersion, target, gen))
		resolver.set(rid, fp)
		if prior, ok, err := priorAck(txctx, s.Receipts, scope.Tx, rid, fp); err != nil {
			return err
		} else if ok {
			out = prior
			return nil
		}
		if s.InviteProjection != nil {
			err = s.InviteProjection.Bindings.UpsertInviteForProjectionTx(txctx, scope.Tx, inv)
		} else {
			err = s.Store.UpsertInviteTx(txctx, scope.Tx, inv)
		}
		if err != nil {
			return err
		}
		var sendID int64
		if projected {
			sendID, err = s.InviteProjection.Bindings.AppendInviteSendReturningTx(txctx, scope.Tx, gid, actor.PlayerID, target, at, s.Policy.Revision, bound.ID)
		} else {
			err = s.Store.AppendInviteSendTx(txctx, scope.Tx, gid, actor.PlayerID, target, at, s.Policy.Revision, bound.ID)
		}
		if err != nil {
			return err
		}
		if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "INVITE", actor.PlayerID, target, at, s.Policy.Revision, bound.ID, "{}"); err != nil {
			return err
		}
		out = AckResult{GuildID: int64(gid)}
		rr, err := s.putAckReceiptReturning(txctx, scope.Tx, bound, string(actor.AccountUID), actor.ContextID.UUID(), rid, fp, "gxb.i6c.guild.invite.v1", out)
		if err != nil {
			return err
		}
		if projected {
			return s.InviteProjection.ApplyIssueTx(txctx, scope.Tx, plan, sendID, rr)
		}
		return nil
	})
	return out, err
}

func (s Service) AcceptInvite(ctx context.Context, actor identity.ActorContext, gid guild.ID, op operation.Context) (AckResult, error) {
	ctx, cancel := context.WithTimeout(ctx, s.profile().OperationTimeout)
	defer cancel()
	if err := s.validate(); err != nil {
		return AckResult{}, err
	}
	if gid <= 0 {
		return AckResult{}, ErrGuildNotFound
	}
	bound, err := bindGuildPolicy(op, s.Policy.Revision)
	if err != nil {
		return AckResult{}, err
	}
	bound, projected, err := s.admitInviteProjection(ctx, bound)
	if err != nil {
		return AckResult{}, err
	}
	fp, err := receipt.FingerprintRequest(GuildRequest{gid})
	if err != nil {
		return AckResult{}, err
	}
	var out AckResult
	resolver := &dynamicResolver{reader: s.ReceiptRead}
	_, _, err = s.Timed.Run(ctx, bound, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		g, ok, err := s.Store.LockGuildTx(txctx, scope.Tx, gid)
		if err != nil {
			return err
		}
		if !ok {
			return ErrGuildNotFound
		}
		if g.RetiredAt != nil {
			return ErrGuildRetired
		}
		if g.LogicalServerID != actor.LogicalServerID {
			return ErrGuildRegionMismatch
		}
		if _, err := s.PlayerRoots.LockPlayerRootsTx(txctx, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID}); err != nil {
			return err
		}
		if m, mok, err := s.Store.LockMembershipTx(txctx, scope.Tx, actor.PlayerID); err != nil {
			return err
		} else if mok {
			if m.GuildID == gid {
				if err := s.validateMembershipProjectionTx(txctx, scope.Tx, m); err != nil {
					return err
				}
				out = AckResult{GuildID: int64(gid), Replayed: true}
				return nil
			}
			return ErrAlreadyInGuild
		}
		n, err := s.Store.CountMembersTx(txctx, scope.Tx, gid)
		if err != nil {
			return err
		}
		if n >= s.Policy.Policy.MemberCap {
			return ErrGuildFull
		}
		if projected {
			if err := s.InviteProjection.Bindings.PrepareMembershipCleanupTx(txctx, scope.Tx, actor.PlayerID); err != nil {
				return err
			}
		}
		inv, ok, err := s.Store.LockInviteTx(txctx, scope.Tx, gid, actor.PlayerID)
		if err != nil {
			return err
		}
		if !ok {
			return ErrInviteNotFound
		}
		if s.InviteProjection != nil {
			if err := s.InviteProjection.ValidateCurrentInviteTx(txctx, scope.Tx, inv); err != nil {
				return err
			}
		}
		if !at.Before(inv.ExpiresAt) {
			return ErrInviteExpired
		}
		rid := semanticReceipt(strconv.FormatInt(int64(gid), 10), "accept_invite", fmt.Sprintf("player:%d:gen:%d", actor.PlayerID, inv.Generation))
		resolver.set(rid, fp)
		if prior, ok, err := priorAck(txctx, s.Receipts, scope.Tx, rid, fp); err != nil {
			return err
		} else if ok {
			out = prior
			return nil
		}
		if err := s.checkJoinGatesTx(txctx, scope.Tx, actor.PlayerID, gid, at); err != nil {
			return err
		}
		var plan appinvite.MarkerPlan
		if projected {
			plan, err = s.InviteProjection.PrepareMarkerTx(txctx, scope.Tx, g, actor, actor.PlayerID, gi.Join, bound, at)
			if err != nil {
				return err
			}
			s.bindProjectionResolver(resolver, bound.ID, false)
		}
		m := guild.Membership{PlayerID: actor.PlayerID, GuildID: gid, Role: guild.Member, JoinedAt: at, MembershipVersion: 1, StateVersion: 1, UpdatedAt: at}
		if err := s.Store.InsertMembershipTx(txctx, scope.Tx, m); err != nil {
			return err
		}
		if err := s.Store.DeleteInviteTx(txctx, scope.Tx, gid, actor.PlayerID); err != nil {
			return err
		}
		if err := s.Store.DeleteApplicationsForPlayerTx(txctx, scope.Tx, actor.PlayerID); err != nil {
			return err
		}
		ev := guild.MembershipEvent{PlayerID: actor.PlayerID, GuildID: gid, Kind: guild.EventJoin, OccurredAt: at, ActorPlayerID: actor.PlayerID, PolicyRevision: s.Policy.Revision}
		ev, err = s.appendProjectionEventTx(txctx, scope.Tx, ev, bound.ID, projected)
		if err != nil {
			return err
		}
		if err := s.Store.AppendAuditTx(txctx, scope.Tx, gid, "ACCEPT_INVITE", actor.PlayerID, actor.PlayerID, at, s.Policy.Revision, bound.ID, "{}"); err != nil {
			return err
		}
		level, err := s.Level.PlayerLevelTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		if level < g.MinAllowLevel {
			return ErrLevelTooLow
		}
		out = AckResult{GuildID: int64(gid)}
		rr, err := s.putAckReceiptReturning(txctx, scope.Tx, bound, string(actor.AccountUID), actor.ContextID.UUID(), rid, fp, "gxb.i6c.guild.accept_invite.v1", out)
		if err != nil {
			return err
		}
		if projected {
			return s.InviteProjection.ApplyMarkerTx(txctx, scope.Tx, plan, ev, rr)
		}
		return nil
	})
	return out, err
}
