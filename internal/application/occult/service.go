package occult

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	RoomFamily       = "occult"
	RoomSlot   int64 = 1
	// RoomNoticeRoute wakes the realtime projection for one room.
	RoomNoticeRoute = "occult.room.notice.v1"

	clearedFactKind = "OCCULT_CLEARED"
	logLimit        = 50
	battleLogType   = 1
	eventLogType    = 2
)

func RoomFamilyRef() sr.Family {
	return sr.Family{Name: RoomFamily, Slot: RoomSlot, Route: RoomNoticeRoute}
}

func profile() tx.Profile {
	return tx.Profile{Name: "occult", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

// retry is the shared-row abort budget of I9_8C (8 attempts, 20-80 ms).
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

func (s Mode) readCatalog(c context.Context, q tx.Queryer, op operation.Context) (d.Catalog, error) {
	revision, _ := op.Policies.Get("content")
	return s.Content.OccultCatalogTx(c, q, revision)
}

// run executes one receipted change that needs no room (the sweep); an
// ambiguous COMMIT replays the stored body instead of charging twice.
func (s Mode) run(c context.Context, a identity.ActorContext, name string, request any, op operation.Context, apply func(context.Context, gen.TimedScope, d.Catalog) (map[string]any, error)) (map[string]any, error) {
	var out map[string]any
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "occult", Operation: name, SemanticKey: op.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(request)
	if err != nil {
		return nil, err
	}
	_, res, err := s.Timed.Run(c, op, profile(), tx.Options{Isolation: tx.Serializable}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fingerprint}}, func(c context.Context, sc gen.TimedScope) error {
		catalog, err := s.readCatalog(c, sc.Tx, sc.Operation.Operation())
		if err != nil {
			return err
		}
		out, err = apply(c, sc, catalog)
		if err != nil {
			return err
		}
		piggyback(c, out)
		raw, err := json.Marshal(out)
		if err != nil {
			return err
		}
		record, err := receipt.New(sc.Operation.Operation(), id, d.ContractID, "gxb.occult."+name+".v1", raw, fingerprint)
		if err != nil {
			return err
		}
		record.PolicyVersion, record.ActorAccountUID, record.ContextID = d.PolicyID, string(a.AccountUID), a.ContextID.UUID()
		_, err = s.Receipts.PutTx(c, sc.Tx, record)
		return err
	})
	if err != nil {
		return nil, err
	}
	if !res.Reconciled {
		return out, nil
	}
	stored, ok := res.Evidence.(receipt.Receipt)
	if !ok {
		return nil, d.ErrUnavailable
	}
	return out, json.Unmarshal(stored.ResultPayload, &out)
}

// piggyback adds the stock balance and mission deltas the transaction recorded.
func piggyback(c context.Context, body map[string]any) {
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

// admit is the F6 gate for function 67 at academy level 85, on every MID.
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
		return fmt.Errorf("%w: occult opens at level %d", d.ErrRefused, catalog.OpenAcademyLevel)
	}
	return nil
}

// roomView is a locked room with its decoded run.
type roomView struct {
	room    sharedroom.Room
	state   d.RunState
	catalog d.Catalog
	scores  d.Scores
	at      time.Time
}

// update runs one command against the actor's solo room under the declared
// lock order: fence 315, roots, player row 605, room 607, then Combat and I5
// from inside the command. The run is saved back into the room payload.
func (s Mode) update(c context.Context, a identity.ActorContext, op operation.Context, command func(context.Context, gen.TimedScope, *roomView) (map[string]any, error)) (map[string]any, error) {
	return s.updateRoom(c, a, op, false, command)
}

// updateRoom lets only the exit command touch an expired room, so a player is
// never stuck in a room that ran out before the reconciler closed it.
func (s Mode) updateRoom(c context.Context, a identity.ActorContext, op operation.Context, allowExpired bool, command func(context.Context, gen.TimedScope, *roomView) (map[string]any, error)) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	var scores d.Scores
	var body map[string]any
	_, err = s.Rooms.Update(c, a, sr.UpdateRequest{Family: RoomFamilyRef(),
		Before: func(c context.Context, t tx.Tx, room sharedroom.Room, at time.Time) error {
			catalog, err := s.readCatalog(c, t, op)
			if err != nil {
				return err
			}
			if err = s.admit(c, t, a, catalog, at); err != nil {
				return err
			}
			scores, err = s.Store.LockPlayerTx(c, t, int64(a.LogicalServerID), a.PlayerID, at)
			return err
		},
		Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
			catalog, err := s.readCatalog(c, sc.Tx, sc.Operation.Operation())
			if err != nil {
				return err
			}
			state, err := d.LoadRunState(room.Payload)
			if err != nil {
				return err
			}
			view := &roomView{room: *room, state: state, catalog: catalog, scores: scores, at: sc.Operation.DecisionAt()}
			if !allowExpired && view.state.RoomExpired(view.at.Unix()) {
				return fmt.Errorf("%w: room expired", d.ErrRefused)
			}
			body, err = command(c, sc, view)
			if err != nil {
				return err
			}
			room.Payload, err = view.state.Encode()
			return err
		}}, op)
	return body, err
}

func locator(a identity.ActorContext) cd.Locator {
	return cd.Locator{DomainKind: "OCCULT", AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID), DomainLocator: fmt.Sprintf("player:%d", a.PlayerID)}
}

func generationRef(roomID, campaignID int64, subID int) string {
	return fmt.Sprintf("OCCULT/%d/%d/%d", roomID, campaignID, subID)
}

func startFingerprint(a identity.ActorContext, ref string, op operation.Context) string {
	raw, _ := json.Marshal(struct {
		Player    int64
		Ref       string
		Operation string
	}{int64(a.PlayerID), ref, op.ID.String()})
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

func numberKey(id int64) string { return strconv.FormatInt(id, 10) }
