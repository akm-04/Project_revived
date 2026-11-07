package socialexchange

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"math"
	"strconv"
	"time"

	generation "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialexchange"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const PolicyVersion = "I9_10E_FRIENDSHIP_EXCHANGE_V1"
const operationClass = "I9_10E_SOCIAL_EXCHANGE"
const resultSchema = "gxb.social.exchange.v1"

var ErrProof = errors.New("social exchange: invalid receipt proof")
var ErrUnavailable = errors.New("social exchange: unavailable")
var ErrProductOff = errors.New("social exchange: product disabled")

type Request struct{ ProductID, Count int64 }
type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	SocialExchangeCatalogTx(context.Context, tx.Queryer, string) (domain.Catalog, error)
}
type Settings interface {
	TuningTx(context.Context, tx.Queryer) (json.RawMessage, error)
}
type Service struct {
	Timed         generation.TimedRunner
	Fence         Fence
	Players       playerroot.TxLocker
	Content       Content
	Settings      Settings
	Materials     i5.TxMaterialExchange
	Receipts      receipt.Store
	ReceiptReader receipt.Reader
}
type terminalResult struct {
	OperationID      string         `json:"operation_id"`
	StartedAt        time.Time      `json:"started_at"`
	EntropySeed      [32]byte       `json:"entropy_seed"`
	ContentRevision  string         `json:"content_revision"`
	SettingsRevision string         `json:"settings_revision"`
	SettingsDigest   string         `json:"settings_digest"`
	Plan             domain.Plan    `json:"plan"`
	Body             map[string]any `json:"body"`
}

func profile() tx.Profile {
	return tx.Profile{Name: "social-exchange", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 45 * time.Second}
}
func (service Service) Exchange(ctx context.Context, actor identity.ActorContext, request Request, current operation.Context) (map[string]any, error) {
	if service.Timed.Runner.DB == nil || service.Timed.Binder.Time == nil || service.Fence == nil || service.Players == nil || service.Content == nil || service.Settings == nil || service.Materials == nil || service.Receipts == nil || service.ReceiptReader == nil {
		return nil, ErrUnavailable
	}
	if !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || actor.AccountUID == "" || actor.ContextID.UUID().IsZero() || current.ID.IsZero() || current.StartedAt.IsZero() || request.ProductID <= 0 || request.Count <= 0 {
		return nil, domain.ErrUnqualified
	}
	if selected, found := current.Policies.Get("socialexchange"); found && selected != PolicyVersion {
		return nil, ErrProof
	}
	receiptIdentity := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "socialexchange", Operation: "exchange", SemanticKey: current.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(struct {
		Player  int64
		Server  int64
		Product int64
		Count   int64
		Policy  string
	}{int64(actor.PlayerID), int64(actor.LogicalServerID), request.ProductID, request.Count, PolicyVersion})
	if err != nil {
		return nil, err
	}
	recovery := resolver{reader: service.ReceiptReader, identity: receiptIdentity, fingerprint: fingerprint, actor: actor, request: request, operation: current}
	var output map[string]any
	_, result, err := service.Timed.Run(ctx, current, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}, recovery, func(ctx context.Context, scope generation.TimedScope) error {
		if err := service.Fence.FenceActorTx(ctx, scope.Tx, actor, scope.Operation.DecisionAt()); err != nil {
			return err
		}
		roots, err := service.Players.LockPlayerRootsTx(ctx, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID})
		if err != nil {
			return err
		}
		if len(roots) != 1 || roots[0].PlayerID != actor.PlayerID || roots[0].LogicalServerID != actor.LogicalServerID || roots[0].Validate() != nil {
			return playerroot.ErrPlayerServerMismatch
		}
		stored, found, err := service.Receipts.FindTx(ctx, scope.Tx, receiptIdentity)
		if err != nil {
			return err
		}
		if found {
			output, err = recovery.decode(stored)
			return err
		}
		revision, pinned := current.Policies.Get("content")
		if !pinned {
			revision, err = service.Content.ActiveRevision(ctx, scope.Tx)
			if err != nil {
				return err
			}
		}
		if !validRevision(revision) {
			return ErrProof
		}
		catalog, err := service.Content.SocialExchangeCatalogTx(ctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		if err = catalog.Validate(); err != nil {
			return err
		}
		raw, err := service.Settings.TuningTx(ctx, scope.Tx)
		if err != nil {
			return err
		}
		catalog, disabled, settingsRevision := effectiveCatalog(catalog, request.ProductID, raw)
		if disabled {
			return ErrProductOff
		}
		bound, err := bindPolicy(current, revision)
		if err != nil {
			return err
		}
		plan, err := domain.BuildPlan(catalog, request.ProductID, request.Count, bound)
		if err != nil {
			return err
		}
		lines := make([]grant.Line, 0, len(plan.Items))
		for _, item := range plan.Items {
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: item.ItemID, Amount: item.ItemNum})
		}
		requestValue := i5.MaterialExchangeRequest{Cost: i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: domain.PriceCurrency, Amount: plan.TotalCost}}}, Restoration: grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "socialexchange", Operation: "exchange", BusinessKey: strconv.FormatInt(int64(actor.PlayerID), 10), Occurrence: current.ID.String(), PolicyVersion: PolicyVersion}, Lines: lines}, AllowOverflowMail: true}
		valueOperation := bound
		valueOperation.StartedAt = scope.Operation.DecisionAt()
		prepared, err := service.Materials.PrepareMaterialExchangeTx(ctx, scope.Tx, actor, requestValue, valueOperation)
		if err != nil {
			return err
		}
		applied, err := service.Materials.ApplyMaterialExchangeTx(ctx, scope.Tx, prepared)
		if err != nil {
			return err
		}
		balances := map[string]int64{}
		for _, balance := range applied.Debit.Scalars {
			if balance.PlayerID != actor.PlayerID || balance.ResourceKey != domain.PriceCurrency || balance.Amount < 0 {
				return ErrProof
			}
			balances[balance.ResourceKey] = balance.Amount
		}
		if len(balances) != 1 {
			return ErrProof
		}
		awards := applied.Restoration.Awards
		if awards == nil {
			awards = []i5.Award{}
		}
		body := map[string]any{"awards": awards, "economy_": balances}
		settingsBytes, err := json.Marshal(catalog)
		if err != nil {
			return err
		}
		digest := sha256.Sum256(settingsBytes)
		terminal := terminalResult{OperationID: current.ID.String(), StartedAt: current.StartedAt, EntropySeed: current.EntropySeed, ContentRevision: revision, SettingsRevision: settingsRevision, SettingsDigest: hex.EncodeToString(digest[:]), Plan: plan, Body: body}
		encoded, err := json.Marshal(terminal)
		if err != nil {
			return err
		}
		terminalReceipt, err := receipt.New(bound, receiptIdentity, operationClass, resultSchema, encoded, fingerprint)
		if err != nil {
			return err
		}
		terminalReceipt.PolicyVersion = PolicyVersion
		terminalReceipt.ActorAccountUID = string(actor.AccountUID)
		terminalReceipt.ContextID = actor.ContextID.UUID()
		inserted, err := service.Receipts.PutTx(ctx, scope.Tx, terminalReceipt)
		if err != nil {
			return err
		}
		// A collision after applying value must abort, even if its payload matches.
		if !inserted.Inserted {
			return &receipt.ConflictError{Identity: receiptIdentity}
		}
		output, err = recovery.decode(terminalReceipt)
		return err
	})
	if err != nil {
		return nil, err
	}
	if result.Reconciled {
		stored, ok := result.Evidence.(receipt.Receipt)
		if !ok {
			return nil, ErrProof
		}
		return recovery.decode(stored)
	}
	return output, nil
}

func validRevision(value string) bool {
	decoded, err := hex.DecodeString(value)
	return err == nil && len(decoded) == 32
}
func bindPolicy(current operation.Context, revision string) (operation.Context, error) {
	references := current.Policies.Refs()
	if _, found := current.Policies.Get("content"); !found {
		references = append(references, policy.Ref{Name: "content", Version: revision})
	}
	if _, found := current.Policies.Get("socialexchange"); !found {
		references = append(references, policy.Ref{Name: "socialexchange", Version: PolicyVersion})
	}
	var err error
	current.Policies, err = policy.NewSet(references...)
	return current, err
}

type resolver struct {
	reader      receipt.Reader
	identity    receipt.Identity
	fingerprint [32]byte
	actor       identity.ActorContext
	request     Request
	operation   operation.Context
}

func (recovery resolver) decode(stored receipt.Receipt) (map[string]any, error) {
	if stored.RequestFingerprint != recovery.fingerprint {
		return nil, &receipt.ConflictError{Identity: recovery.identity}
	}
	if stored.Validate() != nil || stored.Identity != recovery.identity || stored.OperationClass != operationClass || stored.ResultSchema != resultSchema || stored.PolicyVersion != PolicyVersion || stored.ActorAccountUID != string(recovery.actor.AccountUID) || stored.ContextID != recovery.actor.ContextID.UUID() || stored.OperationStartedAt.UnixMicro() != recovery.operation.StartedAt.UnixMicro() {
		return nil, ErrProof
	}
	for _, reference := range recovery.operation.Policies.Refs() {
		actual, found := stored.OperationPolicyRefs.Get(reference.Name)
		if !found || actual != reference.Version {
			return nil, ErrProof
		}
	}
	var terminal terminalResult
	if decodeStrict(stored.ResultPayload, &terminal) != nil || !validRevision(terminal.ContentRevision) || !validRevision(terminal.SettingsDigest) || terminal.SettingsRevision == "" || terminal.Plan.ProductID != recovery.request.ProductID || terminal.Plan.Count != recovery.request.Count || terminal.Plan.PriceCurrency != domain.PriceCurrency || terminal.Plan.UnitPrice <= 0 || terminal.Plan.TotalCost <= 0 || terminal.Body == nil {
		return nil, ErrProof
	}
	if terminal.OperationID != recovery.operation.ID.String() || !terminal.StartedAt.Equal(recovery.operation.StartedAt) || terminal.EntropySeed != recovery.operation.EntropySeed || stored.RetainUntil != nil || terminal.Plan.Count > math.MaxInt64/terminal.Plan.UnitPrice || terminal.Plan.TotalCost != terminal.Plan.Count*terminal.Plan.UnitPrice || len(terminal.Plan.Items) == 0 {
		return nil, ErrProof
	}
	seenItems := map[int64]bool{}
	for _, item := range terminal.Plan.Items {
		if item.ItemID <= 0 || item.ItemNum <= 0 || seenItems[item.ItemID] {
			return nil, ErrProof
		}
		seenItems[item.ItemID] = true
	}
	awards, awardsValid := terminal.Body["awards"].([]any)
	balances, balancesValid := terminal.Body["economy_"].(map[string]any)
	balance, balanceValid := balances[domain.PriceCurrency].(json.Number)
	if !awardsValid || !balancesValid || !balanceValid || len(balances) != 1 || len(terminal.Body) != 2 {
		return nil, ErrProof
	}
	remaining, err := balance.Int64()
	if err != nil || remaining < 0 {
		return nil, ErrProof
	}
	for _, award := range awards {
		fields, valid := award.(map[string]any)
		if !valid {
			return nil, ErrProof
		}
		identifier, valid := fields["table_id"].(json.Number)
		if !valid {
			return nil, ErrProof
		}
		itemID, err := identifier.Int64()
		if err != nil || !seenItems[itemID] {
			return nil, ErrProof
		}
		amount, valid := fields["item_num"].(json.Number)
		if !valid {
			return nil, ErrProof
		}
		quantity, err := amount.Int64()
		if err != nil || quantity < 0 {
			return nil, ErrProof
		}
	}
	content, found := stored.OperationPolicyRefs.Get("content")
	if !found || content != terminal.ContentRevision {
		return nil, ErrProof
	}
	version, found := stored.OperationPolicyRefs.Get("socialexchange")
	if !found || version != PolicyVersion {
		return nil, ErrProof
	}
	return terminal.Body, nil
}
func (recovery resolver) ResolveTimed(ctx context.Context, _ generation.TimedResolutionRequest) (tx.Resolution, error) {
	stored, found, err := recovery.reader.Find(ctx, recovery.identity)
	if err != nil {
		return tx.Resolution{}, err
	}
	if !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	if _, err = recovery.decode(stored); err != nil {
		return tx.Resolution{}, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: stored}, nil
}
