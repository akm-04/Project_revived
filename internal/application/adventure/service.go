package adventure

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/adventure"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	// NoticeRoute wakes the realtime projection that pushes notices 33 and 34.
	NoticeRoute = "adventure.notice.v1"

	attemptLimit = 5 * time.Minute

	listLimit           = 64
	noticeLimit         = 64
	occurrenceRetention = 7 * 24 * time.Hour
)

var singleSummaryPolicy = cd.SummaryPolicy{ID: "I9_ADVENTURE_SINGLE_SUMMARY_V1", Version: 1, MaxStar: d.MaxSoloStar, MaxDamage: illusion.DefaultPoolHP}

func profile() tx.Profile {
	return tx.Profile{Name: "adventure", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

// retry is the shared-row abort budget (8 attempts, 20-80 ms).
func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}
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

func (s Mode) readCatalogs(c context.Context, q tx.Queryer, op operation.Context) (d.Catalog, illusion.Catalog, error) {
	revision, _ := op.Policies.Get("content")
	catalog, err := s.Content.AdventureCatalogTx(c, q, revision)
	if err != nil {
		return d.Catalog{}, illusion.Catalog{}, err
	}
	fantasy, err := s.Content.IllusionCatalogTx(c, q, revision)
	return catalog, fantasy, err
}

// admit enforces function 68 at academy level 11 on every MID.
func (s Mode) admit(c context.Context, q tx.Queryer, a identity.ActorContext, catalog d.Catalog, at time.Time) error {
	gate, open, err := s.Functions.ReadFunctionEligibilityTx(c, q, a.PlayerID, d.FunctionID)
	if err != nil {
		return err
	}
	if !open || at.Before(gate.EligibleAt) {
		return fmt.Errorf("%w: function %d is not open", d.ErrRefused, d.FunctionID)
	}
	record, found, err := s.Directory.ProfileTx(c, q, a.PlayerID)
	if err != nil {
		return err
	}
	if !found || record.Level < catalog.OpenAcademyLevel {
		return fmt.Errorf("%w: adventure opens at level %d", d.ErrRefused, catalog.OpenAcademyLevel)
	}
	return nil
}

func (s Mode) run(c context.Context, a identity.ActorContext, op operation.Context, apply func(context.Context, gen.TimedScope, d.Catalog, illusion.Catalog) (map[string]any, error)) (map[string]any, error) {
	var out map[string]any
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	_, _, err = s.Timed.Run(c, op, profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		catalog, fantasy, err := s.readCatalogs(c, sc.Tx, sc.Operation.Operation())
		if err != nil {
			return err
		}
		if err = s.admit(c, sc.Tx, a, catalog, at); err != nil {
			return err
		}
		out, err = apply(c, sc, catalog, fantasy)
		if err != nil {
			return err
		}
		piggyback(c, out)
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

func piggyback(c context.Context, body map[string]any) {
	if body == nil {
		return
	}
	balance, functions := changes.Recorded(c)
	if len(balance) > 0 {
		body["economy_"] = balance
	}
	if len(functions) > 0 {
		body["new_funcs_"] = functions
	}
	for key, value := range changes.RecordedMissions(c) {
		body[key] = value
	}
}

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

func validateFormation(formation []int64) error {
	if len(formation) == 0 || len(formation) > d.DefenseRoomCapacity {
		return d.ErrInvalid
	}
	seen := make(map[int64]struct{}, len(formation))
	for _, id := range formation {
		if id <= 0 {
			return d.ErrInvalid
		}
		if _, duplicate := seen[id]; duplicate {
			return d.ErrInvalid
		}
		seen[id] = struct{}{}
	}
	return nil
}

// activeOccurrence refuses a missing, finished or expired occurrence (35029).
func (s Mode) activeOccurrence(c context.Context, q tx.Queryer, player identity.PlayerID, eventType int64, at time.Time) (d.Occurrence, error) {
	occurrence, found, err := s.Store.ReadOccurrenceTx(c, q, player, eventType)
	if err != nil {
		return d.Occurrence{}, err
	}
	if !found || !occurrence.Active(at) {
		return d.Occurrence{}, d.ErrExpired
	}
	return occurrence, nil
}

func (s Mode) finish(c context.Context, transaction tx.Tx, a identity.ActorContext, occurrence d.Occurrence, at time.Time) (bool, error) {
	finished, err := s.Store.FinishOccurrenceTx(c, transaction, a.PlayerID, occurrence.EventType, occurrence.OccurredAt, at)
	if err != nil || !finished {
		return false, err
	}
	return true, s.Wake.WakeAdventureNotice(c, transaction, a.PlayerID)
}

func giftAwards(catalog d.Catalog, giftID int64) ([]any, []grant.Line) {
	gift, ok := catalog.Gift(giftID)
	if !ok {
		return nil, nil
	}
	awards := make([]any, 0, len(gift.Items))
	lines := make([]grant.Line, 0, len(gift.Items))
	for index, itemID := range gift.Items {
		amount := gift.ItemNums[index]
		awards = append(awards, map[string]any{"table_id": itemID, "item_num": amount})
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: itemID, Amount: amount})
	}
	return awards, lines
}

func (s Mode) settleGrant(c context.Context, sc gen.TimedScope, a identity.ActorContext, name string, occurrence d.Occurrence, lines []grant.Line) error {
	if len(lines) == 0 {
		return nil
	}
	current := sc.Operation.Operation()
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "adventure", Operation: name, BusinessKey: occurrence.SourceKey, Occurrence: occurrence.SourceKey, PolicyVersion: d.PolicyID}, Lines: lines}
	_, err := s.Grants.SettleGrantTx(c, sc.Tx, a, plan, current, i5.GrantTxOptions{})
	return err
}

func (s Mode) debitCrystal(c context.Context, sc gen.TimedScope, a identity.ActorContext, amount int64) error {
	if amount <= 0 {
		return d.ErrInvalid
	}
	_, err := s.Costs.DebitMaterialCostTx(c, sc.Tx, a.PlayerID, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: amount}}}, sc.Operation.Operation())
	return err
}

func eventOrdinal(op operation.Context, label, key string) uint64 {
	digest := op.Derive(label+"/"+key, 0)
	return binary.BigEndian.Uint64(digest[:8])
}

func locator(a identity.ActorContext, occurrence d.Occurrence, kind string) cd.Locator {
	return cd.Locator{DomainKind: kind, AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID),
		DomainLocator: fmt.Sprintf("player:%d/%d/%d", a.PlayerID, occurrence.EventType, occurrence.OccurredAt.Unix())}
}

func startFingerprint(a identity.ActorContext, operationID string, formation []int64) string {
	raw, _ := json.Marshal(struct {
		Player    int64
		Operation string
		Formation []int64
	}{int64(a.PlayerID), operationID, formation})
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

func (s Mode) coherentScope(sc gen.TimedScope, at time.Time) (ca.CoherentReadScope, error) {
	op := sc.Operation.Operation()
	revision, _ := op.Policies.Get("content")
	return ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: op, Attempt: sc.Attempt, Options: sc.Options}, revision, at)
}

var errNoOpponent = errors.New("adventure: no pvp opponent")
