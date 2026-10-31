package worldboss

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	d "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	resultKind   = "WORLD_BOSS_RESULT"
	attemptLimit = time.Hour
	rankLimit    = 1000
	boardLimit   = 100
	mailRanks    = 100000
)

func profile() tx.Profile {
	return tx.Profile{Name: "world-boss", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

// retry is the shared-row abort budget of I9-WORLD-BOSS (8 attempts, 20-80 ms).
func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}
}

type timedReceipt struct{ receipt.Resolver }

func (r timedReceipt) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}

func (s Mode) pin(c context.Context, op operation.Context) (operation.Context, error) {
	if !s.ready() {
		return op, d.ErrUnavailable
	}
	if _, bound := op.Policies.Get("content"); bound {
		return op, nil
	}
	revision, err := s.Content.ActiveRevision(c, s.Fresh)
	if err != nil {
		return op, err
	}
	op.Policies, err = policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})...)
	return op, err
}

// run executes one receipted owner change; an ambiguous COMMIT replays the
// stored body instead of charging or settling twice.
func (s Mode) run(c context.Context, a identity.ActorContext, name string, request any, op operation.Context, apply func(context.Context, gen.TimedScope, d.Catalog) (Response, error)) (Response, error) {
	var out Response
	op, err := s.pin(c, op)
	if err != nil {
		return out, err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "worldboss", Operation: name, SemanticKey: op.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(request)
	if err != nil {
		return out, err
	}
	_, res, err := s.Timed.Run(c, op, profile(), tx.Options{Isolation: tx.Serializable}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fingerprint}}, func(c context.Context, sc gen.TimedScope) error {
		revision, _ := sc.Operation.Operation().Policies.Get("content")
		catalog, err := s.Content.WorldBossCatalogTx(c, sc.Tx, revision)
		if err != nil {
			return err
		}
		out, err = apply(c, sc, catalog)
		if err != nil {
			return err
		}
		if out.Body == nil {
			out.Body = map[string]any{}
		}
		if balance, functions := changes.Recorded(c); len(balance) > 0 || len(functions) > 0 {
			if len(balance) > 0 {
				out.Body["economy_"] = balance
			}
			if len(functions) > 0 {
				out.Body["new_funcs_"] = functions
			}
		}
		for key, value := range changes.RecordedMissions(c) {
			out.Body[key] = value
		}
		raw, err := json.Marshal(out.Body)
		if err != nil {
			return err
		}
		record, err := receipt.New(sc.Operation.Operation(), id, "I9_WORLD_BOSS_V1", "gxb.worldboss."+name+".v1", raw, fingerprint)
		if err != nil {
			return err
		}
		record.PolicyVersion, record.ActorAccountUID, record.ContextID = d.PolicyID, string(a.AccountUID), a.ContextID.UUID()
		_, err = s.Receipts.PutTx(c, sc.Tx, record)
		return err
	})
	if err != nil {
		return out, err
	}
	if res.Reconciled {
		stored, ok := res.Evidence.(receipt.Receipt)
		if !ok {
			return Response{}, d.ErrUnavailable
		}
		if err = json.Unmarshal(stored.ResultPayload, &out.Body); err != nil {
			return Response{}, err
		}
		out.Duplicate = false
	}
	return out, nil
}

// open applies F6 actor, level, root, player and occurrence admission in the
// declared lock order.
func (s Mode) open(c context.Context, sc gen.TimedScope, a identity.ActorContext, catalog d.Catalog) (session, error) {
	at := sc.Operation.DecisionAt()
	if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
		return session{}, err
	}
	profile, found, err := s.Directory.ProfileTx(c, sc.Tx, a.PlayerID)
	if err != nil {
		return session{}, err
	}
	if !found || profile.Level < catalog.OpenLevel {
		return session{}, fmt.Errorf("%w: world boss opens at level %d", d.ErrRefused, catalog.OpenLevel)
	}
	if _, err = s.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID}); err != nil {
		return session{}, err
	}
	player, err := s.Store.LockPlayerTx(c, sc.Tx, int64(a.LogicalServerID), a.PlayerID, at)
	if err != nil {
		return session{}, err
	}
	day := modes.Day(at)
	player.Reset(day)
	occurrence, err := s.Store.LockOccurrenceTx(c, sc.Tx, int64(a.LogicalServerID), at)
	if err != nil {
		return session{}, err
	}
	return session{occurrence: occurrence, player: player, day: day}, nil
}

// Info answers 624 from canonical state; the lazy counter reset is projected
// without a write.
func (s Mode) Info(c context.Context, a identity.ActorContext, _ operation.Context) (map[string]any, error) {
	if !s.ready() {
		return nil, d.ErrUnavailable
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	occurrence, found, err := s.Store.ReadOccurrenceTx(c, s.Fresh, int64(a.LogicalServerID))
	if err != nil {
		return nil, err
	}
	if !found {
		occurrence = d.Occurrence{LogicalServerID: int64(a.LogicalServerID), Generation: 1, CurrentBoss: d.FirstBossID}
	}
	player, found, err := s.Store.ReadPlayerTx(c, s.Fresh, a.PlayerID)
	if err != nil {
		return nil, err
	}
	if !found {
		player = d.Player{PlayerID: int64(a.PlayerID)}
	}
	player.Reset(modes.Day(at))
	rank, hurt, err := s.rankAndHurt(c, s.Fresh, occurrence.Board(), a.PlayerID)
	if err != nil {
		return nil, err
	}
	return infoBody(occurrence, player, rank, hurt), nil
}

func infoBody(occurrence d.Occurrence, player d.Player, rank, hurt int64) map[string]any {
	return map[string]any{
		"total_hurt":      hurt,
		"total_rank":      rank,
		"challenge_times": player.Attempts,
		"boss_info": map[string]any{
			"boss_brave":   occurrence.Courage,
			"current_boss": occurrence.CurrentBoss,
			"boss_id":      occurrence.CurrentBoss,
		},
		"can_sweep": flag(player.CanSweep()),
		"buy_times": player.Bought,
	}
}

// personalHurt reads the total straight from its row, so a player outside the
// rank limit still sees their history.
func (s Mode) personalHurt(c context.Context, q tx.Queryer, board d.Board, playerID identity.PlayerID) (int64, error) {
	total, found, err := s.Store.ReadTotalTx(c, q, board, playerID)
	if err != nil || !found {
		return 0, err
	}
	return total.Hurt, nil
}

func (s Mode) rankAndHurt(c context.Context, q tx.Queryer, board d.Board, playerID identity.PlayerID) (int64, int64, error) {
	ranks, err := s.Store.ReadRankTx(c, q, board, rankLimit)
	if err != nil {
		return 0, 0, err
	}
	rank, _ := d.RankOf(ranks, int64(playerID))
	hurt, err := s.personalHurt(c, q, board, playerID)
	return rank, hurt, err
}

func flag(value bool) int64 {
	if value {
		return 1
	}
	return 0
}

func (s Mode) preInfo(c context.Context, q tx.Queryer, ranks []d.RankEntry, playerID identity.PlayerID) (map[string]any, error) {
	ordered := d.OrderRank(ranks)
	position := -1
	for index, entry := range ordered {
		if entry.PlayerID == int64(playerID) {
			position = index
			break
		}
	}
	if position <= 0 {
		return nil, nil
	}
	ahead := ordered[position-1]
	profile, found, err := s.Directory.ProfileTx(c, q, identity.PlayerID(ahead.PlayerID))
	if err != nil {
		return nil, err
	}
	if !found {
		return nil, nil
	}
	return map[string]any{"player_name": profile.Name, "avatar_id": profile.AvatarID, "avatar_frame_id": profile.AvatarFrameID, "lev": profile.Level, "hurt": ahead.TotalHurt, "pre_rank": int64(position)}, nil
}

func validateFormation(formation []int64) error {
	if len(formation) < 1 || len(formation) > 5 {
		return d.ErrInvalid
	}
	seen := map[int64]struct{}{}
	for _, id := range formation {
		if id <= 0 {
			return d.ErrInvalid
		}
		if _, repeated := seen[id]; repeated {
			return d.ErrInvalid
		}
		seen[id] = struct{}{}
	}
	return nil
}

// purpleHeroes reads the stock roster and requires every selected hero to be
// owned at purple (color >= 7).
func (s Mode) purpleHeroes(c context.Context, q tx.Queryer, a identity.ActorContext, at time.Time, formation []int64) error {
	detail := map[string]any{}
	if err := s.Heroes.OverlayMID1(c, q, identity.ActorContext{PlayerID: a.PlayerID}, false, at, detail); err != nil {
		return err
	}
	body, _ := detail["49"].(map[string]any)
	rows, _ := body["heros"].(map[string]any)
	for _, id := range formation {
		row, owned := rows[strconv.FormatInt(id, 10)].(map[string]any)
		if !owned {
			return fmt.Errorf("%w: hero %d not owned", d.ErrRefused, id)
		}
		color, ok := numeric(row["color"])
		if !ok || color < 7 {
			return fmt.Errorf("%w: hero %d below purple", d.ErrRefused, id)
		}
	}
	return nil
}

func numeric(raw any) (int64, bool) {
	switch value := raw.(type) {
	case int:
		return int64(value), true
	case int32:
		return int64(value), true
	case int64:
		return value, true
	case float64:
		return int64(value), true
	case json.Number:
		n, err := value.Int64()
		return n, err == nil
	default:
		return 0, false
	}
}
