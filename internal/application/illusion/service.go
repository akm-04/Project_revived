package illusion

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	rankLimit       = 1000
	boardLimit      = 100
	attemptLimit    = time.Hour
	fantasyFactKind = "FANTASY"
)

func profile() tx.Profile {
	return tx.Profile{Name: "illusion", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

// retry is the shared-row abort budget of I9_8B (8 attempts, 20-80 ms).
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
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "illusion", Operation: name, SemanticKey: op.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(request)
	if err != nil {
		return out, err
	}
	_, res, err := s.Timed.Run(c, op, profile(), tx.Options{Isolation: tx.Serializable}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fingerprint}}, func(c context.Context, sc gen.TimedScope) error {
		revision, _ := sc.Operation.Operation().Policies.Get("content")
		catalog, err := s.Content.IllusionCatalogTx(c, sc.Tx, revision)
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
		record, err := receipt.New(sc.Operation.Operation(), id, d.ContractID, "gxb.illusion."+name+".v1", raw, fingerprint)
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

// open applies F6 actor, function, level, root, player and occurrence admission
// in the declared lock order, then advances a missed cycle.
func (s Mode) open(c context.Context, sc gen.TimedScope, a identity.ActorContext, catalog d.Catalog) (session, error) {
	at := sc.Operation.DecisionAt()
	if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
		return session{}, err
	}
	if err := s.eligible(c, sc.Tx, a, at); err != nil {
		return session{}, err
	}
	record, found, err := s.Directory.ProfileTx(c, sc.Tx, a.PlayerID)
	if err != nil {
		return session{}, err
	}
	if !found || record.Level < catalog.OpenLevel {
		return session{}, fmt.Errorf("%w: illusion opens at level %d", d.ErrRefused, catalog.OpenLevel)
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
	if occurrence.Roll(catalog, at) {
		if err = s.Store.SaveOccurrenceTx(c, sc.Tx, occurrence, at); err != nil {
			return session{}, err
		}
	}
	return session{occurrence: occurrence, player: player, day: day}, nil
}

func (s Mode) eligible(c context.Context, q tx.Queryer, a identity.ActorContext, at time.Time) error {
	gate, open, err := s.Functions.ReadFunctionEligibilityTx(c, q, a.PlayerID, d.FunctionID)
	if err != nil {
		return err
	}
	if !open || at.Before(gate.EligibleAt) {
		return fmt.Errorf("%w: function %d is not open", d.ErrRefused, d.FunctionID)
	}
	return nil
}

func locator(a identity.ActorContext) cd.Locator {
	return cd.Locator{DomainKind: "ILLUSION", AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID), DomainLocator: fmt.Sprintf("player:%d", a.PlayerID)}
}

// generationRef binds the Combat attempt to the occurrence it started against.
func generationRef(occurrence d.Occurrence) string {
	return fmt.Sprintf("ILLUSION/%d/%d/%d", occurrence.LogicalServerID, occurrence.OpenDay, occurrence.CampaignID)
}

func startFingerprint(a identity.ActorContext, request StartRequest, op operation.Context) string {
	raw, _ := json.Marshal(struct {
		Player    int64
		Formation []int64
		Pet       int64
		Operation string
	}{int64(a.PlayerID), request.Formation, request.PetID, op.ID.String()})
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

func validateFormation(formation []int64) error {
	if len(formation) < 1 || len(formation) > int(d.TeamHeroLimit) {
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

// ownedHeroes requires every selected partner id to exist in the stock roster.
func (s Mode) ownedHeroes(c context.Context, q tx.Queryer, a identity.ActorContext, at time.Time, formation []int64) error {
	detail := map[string]any{}
	if err := s.Heroes.OverlayMID1(c, q, identity.ActorContext{PlayerID: a.PlayerID}, false, at, detail); err != nil {
		return err
	}
	body, _ := detail["49"].(map[string]any)
	rows, _ := body["heros"].(map[string]any)
	for _, id := range formation {
		if _, owned := rows[strconv.FormatInt(id, 10)]; !owned {
			return fmt.Errorf("%w: hero %d not owned", d.ErrRefused, id)
		}
	}
	return nil
}

func infoBody(occurrence d.Occurrence, player d.Player, hurt, rank int64, at time.Time) map[string]any {
	count := int64(1)
	if occurrence.CanStart(at) {
		count = 0
	}
	return map[string]any{
		"paradise_info":   map[string]any{"paradise_id": occurrence.CampaignID, "count": count},
		"challenge_times": player.Chances,
		"buy_times":       player.Bought,
		"hurt":            hurt,
		"rank":            rank,
	}
}

func (s Mode) preInfo(c context.Context, q tx.Queryer, ranks []d.Result, playerID identity.PlayerID) (map[string]any, error) {
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
	if err != nil || !found {
		return nil, err
	}
	return map[string]any{"player_name": profile.Name, "avatar_id": profile.AvatarID, "avatar_frame_id": profile.AvatarFrameID,
		"lev": profile.Level, "hurt": ahead.Hurt, "pre_rank": int64(position), "conquer_lev": profile.ConquerLevel,
		"conquer_loop_id": profile.ConquerLoopID}, nil
}

func formationText(formation []int64) string {
	parts := make([]string, 0, len(formation))
	for _, id := range formation {
		parts = append(parts, strconv.FormatInt(id, 10))
	}
	return strings.Join(parts, "|")
}

func parseFormationText(text string) []int64 {
	if text == "" {
		return nil
	}
	out := make([]int64, 0)
	for _, part := range strings.Split(text, "|") {
		id, err := strconv.ParseInt(part, 10, 64)
		if err != nil {
			return nil
		}
		out = append(out, id)
	}
	return out
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
