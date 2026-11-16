package workplace

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/application/broadcast"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/workplace"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

const closedKind = "WORKPLACE_JOB_CLOSED"

func (s Mode) Claim(c context.Context, a identity.ActorContext, teamID int64, op operation.Context) (map[string]any, error) {
	if teamID < 1 || teamID > 6 {
		return nil, d.ErrInvalid
	}
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	s.Timed.Binder.Time = fixedTime{at}
	var replay map[string]any
	var pending *d.Occurrence
	// Gate and due admission precede any resolver work; the final transaction fences this occurrence again.
	_, _, err = s.Timed.Run(c, op, profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		if err := s.admit(c, sc, a); err != nil {
			return err
		}
		prior, found, e := s.Receipts.FindTx(c, sc.Tx, receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(a.PlayerID), Domain: "workplace", Operation: "claim", SemanticKey: op.ID.String()})
		if e != nil {
			return e
		}
		if found {
			expected, e := receipt.FingerprintRequest(teamID)
			if e != nil {
				return e
			}
			if prior.RequestFingerprint != expected {
				return &receipt.ConflictError{Identity: prior.Identity}
			}
			return json.Unmarshal(prior.ResultPayload, &replay)
		}
		r, _, err := s.Store.ReadTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		pending = r.Slots[teamID]
		if pending != nil && !pending.Ready(sc.Operation.DecisionAt().Unix()) {
			return d.ErrRefused
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	if replay != nil {
		return replay, nil
	}
	resolverFailed := false
	if pending != nil && pending.Attempt != "" {
		id, err := ids.ParseUUID(pending.Attempt)
		if err != nil {
			return nil, d.ErrUnavailable
		}
		if _, err = s.Combat.Resolve(c, op, id); err != nil {
			if !errors.Is(err, cd.ErrResolverPermanent) {
				return nil, err
			}
			resolverFailed = true
		}
	}
	generation := ""
	if pending != nil {
		generation = pending.ID
	}
	return s.run(c, a, "claim", teamID, nil, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		o := r.Slots[teamID]
		if o == nil {
			if last := r.Last[teamID]; last != nil {
				return last, nil
			}
			return nil, d.ErrRefused
		}
		if o.ID != generation || !o.Ready(sc.Operation.DecisionAt().Unix()) {
			return nil, d.ErrRefused
		}
		cat, err := s.Content.WorkplaceCatalogTx(c, sc.Tx, o.Revision)
		if err != nil {
			return nil, err
		}
		if cat.PolicySHA != o.PolicySHA {
			return nil, d.ErrUnavailable
		}
		won := false
		if o.Attempt != "" {
			if resolverFailed {
				// PRIVATE_POLICY WORKPLACE_UNRESOLVED_RIVAL_V1: a permanently
				// unresolvable rival fight is closed without a result; the job
				// still pays its frozen base lines and skips the rival bonus.
				if _, err := s.Combat.CloseTx(c, sc.Tx, cb.TerminalRequest{Locator: locator(a, teamID), GenerationRef: o.ID, TerminalKind: closedKind, SemanticReceiptID: "workplace:" + o.ID, At: sc.Operation.DecisionAt()}); err != nil {
					return nil, err
				}
			} else {
				settled, err := s.Combat.TerminalTx(c, sc.Tx, cb.TerminalRequest{Locator: locator(a, teamID), GenerationRef: o.ID, TerminalKind: "WORKPLACE_JOB", SemanticReceiptID: "workplace:" + o.ID, At: sc.Operation.DecisionAt()})
				if err != nil {
					return nil, err
				}
				won = settled.Resolution.Outcome.Star > 0
				if won {
					reward := o.RivalReward
					o.Award["battle_award"] = map[string]any{"item_id": reward[0], "item_num": reward[1], "award_time": sc.Operation.DecisionAt().Unix()}
					o.Lines = append(o.Lines, grant.Line{Kind: grant.StackItem, ItemID: reward[0], Amount: reward[1]})
				}
			}
		}
		if len(o.Lines) > 0 {
			bound, err := withRevision(ownerOp(sc), o.Revision)
			if err != nil {
				return nil, err
			}
			plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "workplace", Operation: "claim", BusinessKey: "workplace:" + o.ID, Occurrence: o.ID, PolicyVersion: policyID}, Lines: o.Lines}
			if _, err = s.Values.SettleGrantTx(c, sc.Tx, a, plan, bound, i5.GrantTxOptions{AllowOverflowMail: true}); err != nil {
				return nil, err
			}
			if amount := externalCrystalAward(o.Award); amount > 0 {
				message := broadcast.Message{MID: broadcast.SystemMID, MsgType: broadcast.TreasureDiamond, Server: a.LogicalServerID, Player: a.PlayerID, Fields: broadcast.Fields{CrystalAward: amount}}
				if err = s.Broadcast.EmitTx(c, sc.Tx, message); err != nil {
					return nil, err
				}
			}
		}
		entry := map[string]any{"team_id": teamID, "treasure_type": o.Job, "award": o.Award, "partners_info": o.PartnersInfo, "with_battle": int64(0), "is_win": int64(0), "time": sc.Operation.DecisionAt().Unix()}
		if o.Attempt != "" {
			entry["with_battle"] = int64(1)
		}
		if won {
			entry["is_win"] = int64(1)
		}
		r.Diary = append([]map[string]any{entry}, r.Diary...)
		if len(r.Diary) > cat.Policy.DiaryLimit {
			r.Diary = r.Diary[:cat.Policy.DiaryLimit]
		}
		delete(r.Slots, teamID)
		out := map[string]any{"team_info": team(v, r, teamID), "award": o.Award}
		r.Last[teamID] = out
		return out, nil
	})
}

type fixedTime struct{ at time.Time }

func (f fixedTime) Now(context.Context) (time.Time, error) { return f.at, nil }

// externalCrystalAward reads the job's bounty bonus, which the store decodes
// from jsonb as json.Number.
func externalCrystalAward(award map[string]any) int64 {
	switch value := award["externa_crystal_award"].(type) {
	case int64:
		return value
	case int32:
		return int64(value)
	case float64:
		return int64(value)
	case json.Number:
		amount, err := value.Int64()
		if err != nil {
			return 0
		}
		return amount
	default:
		return 0
	}
}
