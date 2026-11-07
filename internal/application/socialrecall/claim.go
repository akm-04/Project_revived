package socialrecall

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const recallAwardOperationClass = "I9_10E_SOCIAL_RECALL_AWARD"
const recallAwardResultSchema = "gxb.social.recall.award.v1"

var (
	ErrAwardUnavailable = errors.New("social recall: award unavailable")
	ErrAwardProof       = errors.New("social recall: invalid award receipt proof")
)

// AwardScalarReader reads one owner scalar inside the caller transaction. It
// freezes the stock economy_ value with the same transaction that paid it.
type AwardScalarReader interface {
	ReadScalarTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.ScalarBalance, bool, error)
}

type ContentRevisionReader interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
}

// ClaimService is the public MID194 boundary. It composes AwardTx with the
// actor fence, the caller I4 root, one timed serializable transaction and the
// permanent success-only business receipt.
type ClaimService struct {
	Timed         generation.TimedRunner
	Fence         ActorFence
	Players       playerroot.TxLocker
	Content       ContentRevisionReader
	Awarder       Awarder
	Values        AwardScalarReader
	Receipts      receipt.Store
	ReceiptReader receipt.Reader
}

type awardTerminal struct {
	OperationID     string            `json:"operation_id"`
	StartedAt       time.Time         `json:"started_at"`
	EntropySeed     [32]byte          `json:"entropy_seed"`
	ContextID       ids.UUID          `json:"context_id"`
	ActorAccountUID string            `json:"actor_account_uid"`
	Player          int64             `json:"player_id"`
	Server          int64             `json:"server_id"`
	AwardID         int64             `json:"award_id"`
	GiftID          int64             `json:"gift_id"`
	Revision        string            `json:"content_revision"`
	GrantKey        string            `json:"grant_key"`
	GrantReceiptID  string            `json:"grant_receipt_id"`
	Policies        operationPolicies `json:"policies"`
	Awarded         []int64           `json:"awarded"`
	Body            json.RawMessage   `json:"body"`
}

// operationPolicies is the durable canonical policy set embedded in the frozen
// producer proof. It rejects unknown members and non-canonical ordering.
type policyReference struct {
	Name    string `json:"name"`
	Version string `json:"version"`
}

type operationPolicies struct {
	Refs []policyReference `json:"refs"`
}

func (service ClaimService) Claim(ctx context.Context, actor identity.ActorContext, awardID int64, current operation.Context) (map[string]any, error) {
	if service.Timed.Runner.DB == nil || service.Timed.Binder.Time == nil || service.Fence == nil || service.Players == nil || service.Content == nil || service.Awarder.Players == nil || service.Awarder.Owner == nil || service.Awarder.Content == nil || service.Awarder.Current == nil || service.Awarder.Grants == nil || service.Values == nil || service.Receipts == nil || service.ReceiptReader == nil {
		return nil, ErrAwardUnavailable
	}
	if !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || logicalserver.PlayerRegion(actor.PlayerID) != actor.LogicalServerID || actor.AccountUID == "" || actor.ContextID.UUID().IsZero() || current.ID.IsZero() || current.StartedAt.IsZero() || awardID <= 0 {
		return nil, ErrAwardFacts
	}
	identityValue := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "socialrecall", Operation: "award", SemanticKey: strconv.FormatInt(awardID, 10)}
	fingerprint, err := receipt.FingerprintRequest(struct {
		Player int64
		Server int64
		Award  int64
		Policy string
	}{int64(actor.PlayerID), int64(actor.LogicalServerID), awardID, RecallPolicyVersion})
	if err != nil {
		return nil, err
	}
	recovery := awardRecovery{reader: service.ReceiptReader, identity: identityValue, fingerprint: fingerprint, actor: actor, awardID: awardID}
	profile := tx.Profile{Name: "social-recall-award", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 45 * time.Second}
	var output map[string]any
	_, result, err := service.Timed.Run(ctx, current, profile, tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}, recovery, func(ctx context.Context, scope generation.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := service.Fence.FenceActorTx(ctx, scope.Tx, actor, at); err != nil {
			return err
		}
		roots, err := service.Players.LockPlayerRootsTx(ctx, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID})
		if err != nil {
			return err
		}
		if len(roots) != 1 || roots[0].Validate() != nil || roots[0].PlayerID != actor.PlayerID || roots[0].LogicalServerID != actor.LogicalServerID {
			return ErrAwardFacts
		}
		stored, found, err := service.Receipts.FindTx(ctx, scope.Tx, identityValue)
		if err != nil {
			return err
		}
		if found {
			output, err = recovery.decode(stored)
			return err
		}
		claimed, err := service.Awarder.Owner.AwardedIDsTx(ctx, scope.Tx, actor.PlayerID, actor.LogicalServerID)
		if err != nil {
			return err
		}
		for _, identifier := range claimed {
			if identifier == awardID {
				return ErrAwardProof
			}
		}
		revision, pinned := current.Policies.Get("content")
		if !pinned {
			revision, err = service.Content.ActiveRevision(ctx, scope.Tx)
			if err != nil {
				return err
			}
		}
		if characterasset.ValidateExactRevisionID(revision) != nil {
			return ErrAwardProof
		}
		bound, err := BindRecallPolicies(current, revision)
		if err != nil {
			return err
		}
		awarded, err := service.Awarder.AwardTx(ctx, tx.Scope{Tx: scope.Tx, Operation: bound, Attempt: scope.Attempt, Options: scope.Options}, actor, awardID, revision, at)
		if err != nil {
			return err
		}
		body, err := service.stockBody(ctx, scope.Tx, actor, awarded)
		if err != nil {
			return err
		}
		terminal := awardTerminal{OperationID: current.ID.String(), StartedAt: current.StartedAt.UTC(), EntropySeed: current.EntropySeed, ContextID: actor.ContextID.UUID(), ActorAccountUID: string(actor.AccountUID), Player: int64(actor.PlayerID), Server: int64(actor.LogicalServerID), AwardID: awarded.AwardID, GiftID: awarded.GiftID, Revision: awarded.Revision, GrantKey: awardSource(actor.PlayerID, awarded.AwardID).SemanticKey(), GrantReceiptID: awarded.Grant.ReceiptID, Policies: encodePolicies(bound.Policies), Awarded: awarded.Awarded, Body: body}
		encoded, err := json.Marshal(terminal)
		if err != nil {
			return err
		}
		value, err := receipt.New(bound, identityValue, recallAwardOperationClass, recallAwardResultSchema, encoded, fingerprint)
		if err != nil {
			return err
		}
		value.PolicyVersion = RecallPolicyVersion
		value.ActorAccountUID = string(actor.AccountUID)
		value.ContextID = actor.ContextID.UUID()
		output, err = recovery.decode(value)
		if err != nil {
			return err
		}
		inserted, err := service.Receipts.PutTx(ctx, scope.Tx, value)
		if err != nil {
			return err
		}
		if !inserted.Inserted {
			return &receipt.ConflictError{Identity: identityValue}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	if result.Reconciled {
		stored, valid := result.Evidence.(receipt.Receipt)
		if !valid {
			return nil, ErrAwardProof
		}
		return recovery.decode(stored)
	}
	return output, nil
}

func (service ClaimService) stockBody(ctx context.Context, queryer tx.Queryer, actor identity.ActorContext, awarded AwardResult) (json.RawMessage, error) {
	awards := awarded.Grant.Awards
	rows := make([]any, 0, len(awards))
	scalars := map[string]bool{}
	for _, award := range awards {
		if award.ItemNum <= 0 {
			return nil, ErrAwardProof
		}
		if award.ResourceKey != "" {
			row := map[string]any{"table_id": int64(-1), "item_num": award.ItemNum, award.ResourceKey: award.ItemNum}
			rows = append(rows, row)
			scalars[award.ResourceKey] = true
			continue
		}
		if award.TableID <= 0 {
			return nil, ErrAwardProof
		}
		rows = append(rows, map[string]any{"table_id": award.TableID, "item_num": award.ItemNum})
	}
	body := map[string]any{"recall_awarded": awarded.Awarded, "awards": rows}
	if len(scalars) > 0 {
		values := map[string]any{}
		for key := range scalars {
			balance, found, err := service.Values.ReadScalarTx(ctx, queryer, actor.PlayerID, key)
			if err != nil {
				return nil, err
			}
			if !found || balance.Validate() != nil || balance.PlayerID != actor.PlayerID || balance.ResourceKey != key || balance.Amount > 9007199254740991 {
				return nil, ErrAwardProof
			}
			values[key] = balance.Amount
		}
		body["economy_"] = values
	}
	return json.Marshal(body)
}

func encodePolicies(set policy.Set) operationPolicies {
	refs := set.Refs()
	out := operationPolicies{Refs: make([]policyReference, len(refs))}
	for index, ref := range refs {
		out.Refs[index] = policyReference{Name: ref.Name, Version: ref.Version}
	}
	return out
}

type awardRecovery struct {
	reader      receipt.Reader
	identity    receipt.Identity
	fingerprint [32]byte
	actor       identity.ActorContext
	awardID     int64
}

func (recovery awardRecovery) decode(stored receipt.Receipt) (map[string]any, error) {
	if stored.RequestFingerprint != recovery.fingerprint {
		return nil, &receipt.ConflictError{Identity: recovery.identity}
	}
	if stored.Validate() != nil || stored.Identity != recovery.identity || stored.OperationClass != recallAwardOperationClass || stored.ResultSchema != recallAwardResultSchema || stored.PolicyVersion != RecallPolicyVersion || stored.ActorAccountUID != string(recovery.actor.AccountUID) || stored.RetainUntil != nil {
		return nil, ErrAwardProof
	}
	content, found := stored.OperationPolicyRefs.Get("content")
	if !found || characterasset.ValidateExactRevisionID(content) != nil {
		return nil, ErrAwardProof
	}
	if version, found := stored.OperationPolicyRefs.Get("socialrecall"); !found || version != RecallPolicyVersion {
		return nil, ErrAwardProof
	}
	if version, found := stored.OperationPolicyRefs.Get("roster-metrics"); !found || version != characterasset.RosterMetricPolicy {
		return nil, ErrAwardProof
	}
	var terminal awardTerminal
	decoder := json.NewDecoder(bytes.NewReader(stored.ResultPayload))
	decoder.DisallowUnknownFields()
	if decoder.Decode(&terminal) != nil {
		return nil, ErrAwardProof
	}
	var extra any
	if decoder.Decode(&extra) != io.EOF {
		return nil, ErrAwardProof
	}
	operationID, err := ids.ParseUUID(terminal.OperationID)
	if err != nil || operationID.IsZero() || terminal.StartedAt.IsZero() || terminal.StartedAt.Location() != time.UTC || terminal.StartedAt.UnixMicro() != stored.OperationStartedAt.UnixMicro() {
		return nil, ErrAwardProof
	}
	if terminal.ContextID != stored.ContextID || terminal.ActorAccountUID != stored.ActorAccountUID || terminal.Player != int64(recovery.actor.PlayerID) || terminal.Server != int64(recovery.actor.LogicalServerID) {
		return nil, ErrAwardProof
	}
	if terminal.AwardID != recovery.awardID || terminal.GiftID <= 0 || terminal.Revision != content || characterasset.ValidateExactRevisionID(terminal.Revision) != nil || terminal.GrantKey != awardSource(recovery.actor.PlayerID, terminal.AwardID).SemanticKey() || terminal.GrantReceiptID == "" || terminal.EntropySeed == ([32]byte{}) {
		return nil, ErrAwardProof
	}
	if len(terminal.Awarded) == 0 || len(terminal.Awarded) > 25 {
		return nil, ErrAwardProof
	}
	foundAward := false
	previous := int64(0)
	for _, identifier := range terminal.Awarded {
		if identifier <= previous || identifier <= 0 {
			return nil, ErrAwardProof
		}
		previous = identifier
		if identifier == terminal.AwardID {
			foundAward = true
		}
	}
	if !foundAward {
		return nil, ErrAwardProof
	}
	if !policiesEqual(terminal.Policies, stored.OperationPolicyRefs) {
		return nil, ErrAwardProof
	}
	return decodeAwardBody(terminal.Body, terminal.Awarded)
}

func policiesEqual(encoded operationPolicies, expected policy.Set) bool {
	refs := expected.Refs()
	if len(encoded.Refs) != len(refs) {
		return false
	}
	for index, ref := range refs {
		if encoded.Refs[index].Name != ref.Name || encoded.Refs[index].Version != ref.Version {
			return false
		}
	}
	return true
}

func decodeAwardBody(raw json.RawMessage, awarded []int64) (map[string]any, error) {
	if len(raw) == 0 {
		return nil, ErrAwardProof
	}
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.UseNumber()
	var body map[string]any
	if decoder.Decode(&body) != nil {
		return nil, ErrAwardProof
	}
	var extra any
	if decoder.Decode(&extra) != io.EOF || body == nil {
		return nil, ErrAwardProof
	}
	if len(body) != 2 && len(body) != 3 {
		return nil, ErrAwardProof
	}
	for key := range body {
		if key != "recall_awarded" && key != "awards" && key != "economy_" {
			return nil, ErrAwardProof
		}
	}
	listed, ok := body["recall_awarded"].([]any)
	if !ok || len(listed) != len(awarded) {
		return nil, ErrAwardProof
	}
	for index, value := range listed {
		number, ok := value.(json.Number)
		if !ok {
			return nil, ErrAwardProof
		}
		identifier, err := number.Int64()
		if err != nil || identifier != awarded[index] {
			return nil, ErrAwardProof
		}
	}
	rows, ok := body["awards"].([]any)
	if !ok {
		return nil, ErrAwardProof
	}
	for _, value := range rows {
		row, ok := value.(map[string]any)
		if !ok {
			return nil, ErrAwardProof
		}
		table, ok := row["table_id"].(json.Number)
		if !ok {
			return nil, ErrAwardProof
		}
		tableID, err := table.Int64()
		if err != nil || tableID < -1 || tableID == 0 {
			return nil, ErrAwardProof
		}
		quantity, ok := row["item_num"].(json.Number)
		if !ok {
			return nil, ErrAwardProof
		}
		amount, err := quantity.Int64()
		if err != nil || amount <= 0 || amount > 9007199254740991 {
			return nil, ErrAwardProof
		}
		if tableID == -1 {
			if len(row) != 3 {
				return nil, ErrAwardProof
			}
			scalar := ""
			for key, value := range row {
				if key == "table_id" || key == "item_num" {
					continue
				}
				scalar = key
				number, ok := value.(json.Number)
				if !ok {
					return nil, ErrAwardProof
				}
				frozen, err := number.Int64()
				if err != nil || frozen != amount {
					return nil, ErrAwardProof
				}
			}
			if scalar != "crystal" {
				return nil, ErrAwardProof
			}
			continue
		}
		if len(row) != 2 {
			return nil, ErrAwardProof
		}
	}
	if economy, present := body["economy_"]; present {
		values, ok := economy.(map[string]any)
		if !ok || len(values) == 0 {
			return nil, ErrAwardProof
		}
		for key, value := range values {
			number, ok := value.(json.Number)
			if !ok || key == "" {
				return nil, ErrAwardProof
			}
			amount, err := number.Int64()
			if err != nil || amount < 0 || amount > 9007199254740991 {
				return nil, ErrAwardProof
			}
		}
	}
	return body, nil
}

func (recovery awardRecovery) ResolveTimed(ctx context.Context, _ generation.TimedResolutionRequest) (tx.Resolution, error) {
	stored, found, err := recovery.reader.Find(ctx, recovery.identity)
	if err != nil {
		return tx.Resolution{}, err
	}
	if !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	if _, err := recovery.decode(stored); err != nil {
		return tx.Resolution{}, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: stored}, nil
}
