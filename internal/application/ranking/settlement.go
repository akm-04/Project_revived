package ranking

import (
	"context"
	"encoding/json"
	"strconv"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const settlementSchema = "gxb.ranking.girls-weekly-settlement.v1"
const settlementClass = "I7C4C_GIRLS_RANKING_WEEKLY_TITLES"

type Settlement struct {
	Server         identity.LogicalServerID
	Policy         string
	Week           time.Time
	Generation     int64
	SnapshotDigest string
	AppliedAt      time.Time
	Awards         []d.GirlsAward
}

func settlementIdentity(server identity.LogicalServerID, week time.Time) receipt.Identity {
	return receipt.Identity{OwnerKind: "logical-server", OwnerKey: strconv.FormatInt(int64(server), 10), Domain: "ranking", Operation: "girls-weekly-titles", SemanticKey: d.GirlsPolicy + ":" + week.UTC().Format("2006-01-02")}
}
func settlementFingerprint(s d.GirlsSnapshot, p d.GirlsPeriod) ([32]byte, error) {
	return receipt.FingerprintRequest(map[string]any{"server": int64(s.Server), "policy": s.Policy, "week": p.Week.UTC().Format(time.RFC3339), "generation": s.Generation, "snapshot_digest": s.Digest})
}
func awardOrigin(s d.GirlsSnapshot, a d.GirlsAward) playerdisplay.Origin {
	at := a.StartsAt.UTC()
	return playerdisplay.Origin{PlayerID: a.Player, Key: a.OriginKey, Owner: "Ranking", Family: "title", CatalogID: a.TitleID, UniqueID: 0, StartsAt: &at, EndTime: a.EndTime, Revision: s.Revision, StateVersion: s.Generation}
}
func (s Service) settlementProof(c context.Context, q tx.Queryer, r receipt.Receipt, snapshot d.GirlsSnapshot, p d.GirlsPeriod, fp [32]byte) (Settlement, error) {
	var out Settlement
	if r.Validate() != nil || r.Identity != settlementIdentity(snapshot.Server, p.Week) || r.RequestFingerprint != fp || r.OperationClass != settlementClass || r.ResultSchema != settlementSchema || r.PolicyVersion != d.GirlsPolicy || strictDecode(r.ResultPayload, &out) != nil {
		return out, ErrConflict
	}
	for k, want := range map[string]string{"content": snapshot.Revision, "ranking": d.GirlsPolicy} {
		got, ok := r.OperationPolicyRefs.Get(k)
		if !ok || got != want {
			return out, ErrConflict
		}
	}
	if out.Server != snapshot.Server || out.Policy != snapshot.Policy || !out.Week.Equal(p.Week) || out.Generation != snapshot.Generation || out.SnapshotDigest != snapshot.Digest || out.AppliedAt.Before(snapshot.ObservedAt) {
		return out, ErrConflict
	}
	expected, e := snapshot.Awards()
	if e != nil {
		return out, e
	}
	raw1, e := json.Marshal(expected)
	if e != nil {
		return out, e
	}
	raw2, e := json.Marshal(out.Awards)
	if e != nil || string(raw1) != string(raw2) {
		return out, ErrConflict
	}
	stored, ok, e := s.Store.ReadGirlsPeriodTx(c, q, snapshot.Server, p.Week)
	if e != nil {
		return out, e
	}
	if !ok || stored.Validate(snapshot) != nil || stored.SettledAt == nil || !stored.SettledAt.Equal(out.AppliedAt) {
		return out, ErrConflict
	}
	return out, nil
}

// SettlePendingGirls processes only periods already bound to genuine immutable
// snapshots. A week with no snapshot has no invented winner or retroactive job.
// This is the private on-demand policy; a future wakeup may call the same owner.
func (s Service) SettlePendingGirls(c context.Context, server identity.LogicalServerID, parent operation.Context) ([]Settlement, error) {
	if s.Store == nil || s.Fresh == nil || s.Players == nil || s.Recipient == nil || s.Receipts == nil || s.ReceiptRead == nil || s.Content == nil || s.Timed.Runner.DB == nil || s.Timed.Binder.Time == nil || !server.Valid() || parent.ID.IsZero() || parent.StartedAt.IsZero() {
		return nil, ErrUnavailable
	}
	pending, e := s.Store.PendingGirlsPeriodsTx(c, s.Fresh, server)
	if e != nil {
		return nil, e
	}
	out := []Settlement{}
	for _, p := range pending {
		v, e := s.settleGirlsPeriod(c, server, p, parent)
		if e != nil {
			return nil, e
		}
		out = append(out, v)
	}
	return out, nil
}
func (s Service) settleGirlsPeriod(c context.Context, server identity.LogicalServerID, p d.GirlsPeriod, parent operation.Context) (Settlement, error) {
	var out Settlement
	snapshot, ok, e := s.Store.ReadGirlsSnapshotTx(c, s.Fresh, server, p.Generation)
	if e != nil {
		return out, e
	}
	if !ok || p.Validate(snapshot) != nil {
		return out, ErrConflict
	}
	fp, e := settlementFingerprint(snapshot, p)
	if e != nil {
		return out, e
	}
	rid := settlementIdentity(server, p.Week)
	prior, has, e := s.Receipts.FindTx(c, s.Fresh, rid)
	if e != nil {
		return out, e
	}
	if has {
		return s.settlementProof(c, s.Fresh, prior, snapshot, p, fp)
	}
	awards, e := snapshot.Awards()
	if e != nil {
		return out, e
	}
	players := []identity.PlayerID{}
	for _, a := range awards {
		players = append(players, a.Player)
	}
	// A separate semantic system operation binds the original snapshot's content.
	// It never mutates the caller's current content policy to reinterpret history.
	id, e := ids.NewUUID()
	if e != nil {
		return out, e
	}
	refs, e := policy.NewSet(policy.Ref{Name: "content", Version: snapshot.Revision}, policy.Ref{Name: "ranking", Version: d.GirlsPolicy})
	if e != nil {
		return out, e
	}
	child := operation.Context{ID: id, StartedAt: parent.StartedAt, EntropySeed: parent.Derive("ranking-girls-settlement:"+rid.OwnerKey+":"+rid.SemanticKey, 0), Policies: refs}
	_, res, e := s.Timed.Run(c, child, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}, timedReceiptResolver{receipt.Resolver{Reader: s.ReceiptRead, Identity: rid, Fingerprint: fp}}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if at.Before(snapshot.ObservedAt) {
			return d.ErrStale
		}
		// Previewed winners come from an immutable generation. Acquire every
		// canonical Player315 in sorted order before the Ranking600 mutex.
		roots := map[identity.PlayerID]playerroot.Root{}
		if len(players) > 0 {
			locked, e := s.Players.LockPlayerRootsTx(c, sc.Tx, server, players)
			if e != nil {
				return e
			}
			if len(locked) != len(players) {
				return ErrConflict
			}
			for _, r := range locked {
				if r.Validate() != nil || r.LogicalServerID != server {
					return ErrConflict
				}
				if _, dup := roots[r.PlayerID]; dup {
					return ErrConflict
				}
				roots[r.PlayerID] = r
			}
		}
		if _, e = s.Store.LockGirlsRootTx(c, sc.Tx, server, at); e != nil {
			return e
		}
		now, ok, e := s.Store.ReadGirlsPeriodTx(c, sc.Tx, server, p.Week)
		if e != nil {
			return e
		}
		if !ok || now.Validate(snapshot) != nil {
			return ErrConflict
		}
		prior, has, e := s.Receipts.FindTx(c, sc.Tx, rid)
		if e != nil {
			return e
		}
		if has {
			out, e = s.settlementProof(c, sc.Tx, prior, snapshot, p, fp)
			return e
		}
		if now.SettledAt != nil {
			return ErrConflict
		}
		retained, ok, e := s.Store.ReadGirlsSnapshotTx(c, sc.Tx, server, p.Generation)
		if e != nil {
			return e
		}
		if !ok || retained.Digest != snapshot.Digest {
			return ErrConflict
		}
		catalog, e := s.Content.ReadPlayerDisplayCatalogTx(c, sc.Tx, snapshot.Revision)
		if e != nil {
			return e
		}
		if catalog.Validate() != nil {
			return ErrConflict
		}
		for _, a := range awards {
			v, ok := catalog.Find("title", a.TitleID)
			if !ok || v.Type != 8 || v.Days != d.GirlsTitleDuration {
				return ErrConflict
			}
			root, ok := roots[a.Player]
			if !ok {
				return ErrConflict
			}
			if e = s.Recipient.ReceiveOriginTx(c, sc.Tx, root, awardOrigin(snapshot, a)); e != nil {
				return e
			}
		}
		if e = s.Store.SettleGirlsPeriodTx(c, sc.Tx, snapshot, now, at); e != nil {
			return e
		}
		out = Settlement{Server: server, Policy: d.GirlsPolicy, Week: p.Week, Generation: p.Generation, SnapshotDigest: snapshot.Digest, AppliedAt: at, Awards: awards}
		raw, e := json.Marshal(out)
		if e != nil {
			return e
		}
		rr, e := receipt.New(child, rid, settlementClass, settlementSchema, raw, fp)
		if e != nil {
			return e
		}
		rr.PolicyVersion = d.GirlsPolicy
		_, e = s.Receipts.PutTx(c, sc.Tx, rr)
		return e
	})
	if e != nil {
		return Settlement{}, e
	}
	if res.Reconciled {
		r, ok := res.Evidence.(receipt.Receipt)
		if !ok {
			return Settlement{}, ErrConflict
		}
		return s.settlementProof(c, s.Fresh, r, snapshot, p, fp)
	}
	if res.Outcome != tx.DefiniteCommit {
		return Settlement{}, ErrUnavailable
	}
	return out, nil
}
