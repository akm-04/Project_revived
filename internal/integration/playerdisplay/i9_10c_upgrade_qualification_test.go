//go:build postgres

package playerdisplay_test

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/registry"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	i910cAcceptedRevision  = "414a5de9a6af42b55948fe77e40a25d764c6bb9b3d2cab14d8bb1a5b670d537b"
	i910cCandidateRevision = "034adf4f8737d7737d2b6697af58a2a6ced3ebfd05ce2e558148dd8447d5bee3"
	i910cStackItem         = int64(100001001)
)

type i910cOldCapture struct {
	Revision             string               `json:"revision"`
	ManifestTextSHA      string               `json:"manifest_text_sha"`
	ManifestSources      int                  `json:"manifest_sources"`
	GooseVersion         int64                `json:"goose_version"`
	ActivationRevision   string               `json:"activation_revision"`
	ActivationVersion    int64                `json:"activation_version"`
	DormPayloadSHA       string               `json:"dorm_payload_sha"`
	DormPayloadSchema    int                  `json:"dorm_schema_version"`
	DormGlueKeyPresent   bool                 `json:"dorm_glue_key_present"`
	DormCatalogRows      int64                `json:"dorm_catalog_rows"`
	RoomID               int64                `json:"room_id"`
	RoomTableID          int64                `json:"room_table_id"`
	RoomCreationRevision string               `json:"room_creation_revision"`
	PlayerID             int64                `json:"player_id"`
	PlanSource           grant.SourceIdentity `json:"plan_source"`
	PlanLines            []grant.Line         `json:"plan_lines"`
	OperationID          string               `json:"operation_id"`
	OperationStartedAt   string               `json:"operation_started_at"`
	ReceiptSemanticKey   string               `json:"receipt_v2_semantic_key"`
	ReceiptID            string               `json:"receipt_id"`
	ReceiptFingerprint   string               `json:"receipt_fingerprint"`
	ReceiptResultSchema  string               `json:"receipt_result_schema"`
	ReceiptResultPayload json.RawMessage      `json:"receipt_result_payload"`
	ReceiptCount         int64                `json:"receipt_count"`
	ManaAfter            int64                `json:"mana_after"`
	StackQuantityAfter   int64                `json:"stack_quantity_after"`
}

type i910cUpgradeEvidence struct {
	OldRevision           string `json:"old_revision"`
	NewRevision           string `json:"new_revision"`
	OldManifestSHA        string `json:"old_manifest_sha"`
	OldDormPayloadSHA     string `json:"old_dorm_payload_sha"`
	GooseVersion          int64  `json:"goose_version"`
	ActivationBefore      string `json:"activation_before"`
	ActivationBeforeVer   int64  `json:"activation_before_version"`
	ActivationAfter       string `json:"activation_after"`
	ActivationAfterVer    int64  `json:"activation_after_version"`
	OldDormSchema         int    `json:"old_dorm_schema"`
	OldGlueAbsent         bool   `json:"old_glue_absent"`
	OldRoomID             int64  `json:"old_room_id"`
	OldRoomCreationRev    string `json:"old_room_creation_revision"`
	LegacyProjection      int64  `json:"legacy_projection"`
	LegacyAnchorRows      int64  `json:"legacy_anchor_rows"`
	PreActivationRefusal  string `json:"pre_activation_refusal"`
	NewDormGlueFloor      int64  `json:"new_dorm_glue_floor"`
	NewDormVIPZeroCap     int64  `json:"new_dorm_vip0_cap"`
	NewDormFirstCost      int64  `json:"new_dorm_first_cost"`
	NewGlueScalarNamed    bool   `json:"new_glue_is_named_scalar"`
	NewProjectionReadOnly bool   `json:"new_projection_read_only"`
	NewProjectionAmount   int64  `json:"new_projection_amount"`
	PurchaseCrystalAfter  int64  `json:"purchase_crystal_after"`
	PurchaseGlueAfter     int64  `json:"purchase_glue_after"`
	CounterCount          int64  `json:"counter_count"`
	CounterVersion        int64  `json:"counter_version"`
	CounterDay            int64  `json:"counter_day"`
	OldReceiptID          string `json:"old_receipt_id"`
	OldReceiptFingerprint string `json:"old_receipt_fingerprint"`
	ReplayReceiptID       string `json:"replay_receipt_id"`
	ReplayResultEqual     bool   `json:"replay_result_equal"`
	ReplayReceiptsBefore  int64  `json:"replay_receipts_before"`
	ReplayReceiptsAfter   int64  `json:"replay_receipts_after"`
	ReplayManaBefore      int64  `json:"replay_mana_before"`
	ReplayManaAfter       int64  `json:"replay_mana_after"`
	ReplayStackBefore     int64  `json:"replay_stack_before"`
	ReplayStackAfter      int64  `json:"replay_stack_after"`
}

func i910cReadScalar(t *testing.T, p *pg.Pool, player identity.PlayerID, key string) int64 {
	t.Helper()
	balance, exists, err := (i5store.Store{Queryer: p}).ReadScalarTx(ctx, p, player, key)
	if err != nil {
		t.Fatal(err)
	}
	if !exists {
		return 0
	}
	return balance.Amount
}

func i910cReadStack(t *testing.T, p *pg.Pool, player identity.PlayerID, itemID int64) int64 {
	t.Helper()
	stacks, err := (i5store.Store{Queryer: p}).ListStacks(ctx, player)
	if err != nil {
		t.Fatal(err)
	}
	for _, stack := range stacks {
		if stack.ItemID == itemID {
			return stack.Quantity
		}
	}
	return 0
}

func i910cGrantReceiptCount(t *testing.T, p *pg.Pool, player identity.PlayerID) int64 {
	t.Helper()
	var count int64
	if err := p.QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_key=$1 AND domain='grant' AND operation='settle'`, fmt.Sprint(player)).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

func i910cManifestSHA(t *testing.T, p *pg.Pool, revision string) (string, int) {
	t.Helper()
	var text string
	var sources int
	if err := p.QueryRow(ctx, `SELECT manifest::text, jsonb_array_length(manifest->'sources') FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&text, &sources); err != nil {
		t.Fatal(err)
	}
	sum := sha256.Sum256([]byte(text))
	return hex.EncodeToString(sum[:]), sources
}

func i910cDormPayload(t *testing.T, p *pg.Pool, revision string) (string, int, bool, int64) {
	t.Helper()
	var text string
	var rows int64
	if err := p.QueryRow(ctx, `SELECT payload::text, count(*) OVER () FROM content_dorm_input_catalogs WHERE revision_id=$1`, revision).Scan(&text, &rows); err != nil {
		t.Fatal(err)
	}
	var decoded struct {
		SchemaVersion int             `json:"schema_version"`
		Glue          json.RawMessage `json:"glue"`
	}
	if err := json.Unmarshal([]byte(text), &decoded); err != nil {
		t.Fatal(err)
	}
	sum := sha256.Sum256([]byte(text))
	return hex.EncodeToString(sum[:]), decoded.SchemaVersion, len(decoded.Glue) != 0, rows
}

func i910cReconstructOperation(t *testing.T, old i910cOldCapture) operation.Context {
	t.Helper()
	id, err := ids.ParseUUID(old.OperationID)
	if err != nil {
		t.Fatal(err)
	}
	started, err := time.Parse(time.RFC3339Nano, old.OperationStartedAt)
	if err != nil {
		t.Fatal(err)
	}
	current := operation.Context{ID: id, StartedAt: started.UTC()}
	current.Policies, err = policy.NewSet(policy.Ref{Name: "content", Version: old.Revision})
	if err != nil {
		t.Fatal(err)
	}
	return current
}

func i910cPurchaseRequest(player identity.PlayerID, current operation.Context, cost, amount, startLimit int64) i5.GluePurchaseRequest {
	return i5.GluePurchaseRequest{CrystalCost: cost, GlueAmount: amount, StartLimit: startLimit, Source: grant.SourceIdentity{Domain: "dorm-house", Operation: "buy-glue", BusinessKey: fmt.Sprint(int64(player)), Occurrence: current.ID.String(), PolicyVersion: "i9-10c-qualification"}}
}

// gluePurchaseCounterTransaction composes the accepted lock order root315 ->
// Dorm500 -> I5 union and writes the optional counter in the same transaction.
func gluePurchaseCounterTransaction(service i5.Service, owner dormstore.Store, player identity.ActorContext, rules dorm.GlueRules, current operation.Context) error {
	_, err := service.Runner.Run(ctx, current, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true}, nil, func(ctx context.Context, scope tx.Scope) error {
		if _, err := (i4store.PlayerRootLocker{}).LockPlayerRootsTx(ctx, scope.Tx, player.LogicalServerID, []identity.PlayerID{player.PlayerID}); err != nil {
			return err
		}
		if _, err := owner.LockRootTx(ctx, scope.Tx, player.PlayerID); err != nil {
			return err
		}
		stored, exists, err := owner.ReadGluePurchasesTx(ctx, scope.Tx, player.PlayerID)
		if err != nil {
			return err
		}
		var previous *dorm.GluePurchases
		if exists {
			previous = &stored
		}
		planned, cost, err := rules.PlanPurchase(previous, player.PlayerID, 0, modes.Day(current.StartedAt), current.StartedAt)
		if err != nil {
			return err
		}
		request := i910cPurchaseRequest(player.PlayerID, current, cost, rules.PurchaseAmount, rules.PurchaseStartLimit)
		prepared, err := service.PrepareGluePurchaseTx(ctx, scope.Tx, player, request, current)
		if err != nil {
			return err
		}
		if _, err = service.ApplyGluePurchaseTx(ctx, scope.Tx, prepared); err != nil {
			return err
		}
		return owner.SaveGluePurchasesTx(ctx, scope.Tx, planned, stored.StateVersion)
	})
	return err
}

func TestI910CUpgradeQualification(t *testing.T) {
	evidencePath := os.Getenv("GXB_I910C_OLD_EVIDENCE")
	upgradeDSN := os.Getenv("GXB_I910C_UPGRADE_DSN")
	if evidencePath == "" && upgradeDSN == "" {
		t.Skip("dedicated one-shot schema126 historical upgrade fixture not configured")
	}
	if evidencePath == "" || upgradeDSN == "" {
		t.Fatal("GXB_I910C_OLD_EVIDENCE and GXB_I910C_UPGRADE_DSN must both be configured")
	}
	p, err := pg.Open(ctx, upgradeDSN, pg.PoolSettings{MaxConns: 16, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	raw, err := os.ReadFile(evidencePath)
	if err != nil {
		t.Fatal(err)
	}
	var old i910cOldCapture
	if err := json.Unmarshal(raw, &old); err != nil {
		t.Fatal(err)
	}
	if old.Revision != i910cAcceptedRevision || old.ActivationRevision != i910cAcceptedRevision || old.ActivationVersion != 1 {
		t.Fatalf("unexpected old capture identity: %+v", old)
	}
	player := identity.PlayerID(old.PlayerID)
	store := contentstore.Store{Queryer: p}
	owner := dormstore.Store{Queryer: p}
	bundle, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	if bundle.RevisionID() != i910cCandidateRevision {
		t.Fatalf("candidate bundle=%s", bundle.RevisionID())
	}
	var gooseVersion int64
	if err := p.QueryRow(ctx, `SELECT max(version_id) FROM goose_db_version`).Scan(&gooseVersion); err != nil {
		t.Fatal(err)
	}
	if gooseVersion != 126 {
		t.Fatalf("goose=%d want 126", gooseVersion)
	}

	activationBefore, ok, err := store.ReadActivation(ctx, p)
	if err != nil || !ok || activationBefore.RevisionID != i910cAcceptedRevision || activationBefore.Version != 1 {
		t.Fatalf("activation before: %+v %v %v", activationBefore, ok, err)
	}
	manifestSHA, sources := i910cManifestSHA(t, p, i910cAcceptedRevision)
	payloadSHA, payloadSchema, glueKeyPresent, payloadRows := i910cDormPayload(t, p, i910cAcceptedRevision)
	if manifestSHA != old.ManifestTextSHA || sources != old.ManifestSources || payloadSHA != old.DormPayloadSHA || payloadSchema != 1 || glueKeyPresent || payloadRows != 1 {
		t.Fatalf("old immutable identity drifted manifest=%s/%d payload=%s schema=%d glue=%v rows=%d", manifestSHA, sources, payloadSHA, payloadSchema, glueKeyPresent, payloadRows)
	}
	oldCatalog, err := store.DormCatalogTx(ctx, p, i910cAcceptedRevision)
	if err != nil || oldCatalog.Glue != nil {
		t.Fatalf("old catalog glue=%v err=%v", oldCatalog.Glue, err)
	}
	rooms, err := owner.ListRoomsTx(ctx, p, player)
	if err != nil {
		t.Fatal(err)
	}
	oldRoom, exists := rooms[old.RoomID]
	if !exists || oldRoom.CreationRevision != old.RoomCreationRevision || oldRoom.TableID != old.RoomTableID {
		t.Fatalf("retained room=%+v exists=%v", oldRoom, exists)
	}
	if _, err = store.DormCatalogTx(ctx, p, oldRoom.CreationRevision); err != nil {
		t.Fatalf("retained room creation revision catalog: %v", err)
	}
	if i910cReadScalar(t, p, player, "mana") != old.ManaAfter || i910cReadStack(t, p, player, i910cStackItem) != old.StackQuantityAfter {
		t.Fatal("old value state changed by migration")
	}
	receiptIdentity := receiptIdentityFor(player, old.ReceiptSemanticKey)
	retained, found, err := (kernelstore.Store{}).FindTx(ctx, p, receiptIdentity)
	if err != nil || !found || retained.ID.String() != old.ReceiptID || hex.EncodeToString(retained.RequestFingerprint[:]) != old.ReceiptFingerprint {
		t.Fatalf("retained receipt: %v %v", found, err)
	}
	var originalPayload, retainedPayload any
	if err = json.Unmarshal(old.ReceiptResultPayload, &originalPayload); err != nil {
		t.Fatal(err)
	}
	if err = json.Unmarshal(retained.ResultPayload, &retainedPayload); err != nil {
		t.Fatal(err)
	}
	if retained.ResultSchema != old.ReceiptResultSchema || !reflect.DeepEqual(originalPayload, retainedPayload) || i910cGrantReceiptCount(t, p, player) != old.ReceiptCount {
		t.Fatal("migration changed original receipt schema, payload or count")
	}

	at := i910cReconstructOperation(t, old).StartedAt
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'glue',25,1,$2)`, int64(player), at)
	for _, key := range []string{"glue"} {
		amount, err := i5.EffectiveScalarTx(ctx, p, i5store.Store{Queryer: p}, store, player, key, at)
		if err != nil || amount != 25 {
			t.Fatalf("legacy projection %s=%d %v", key, amount, err)
		}
	}
	var legacyAnchors int64
	if err := p.QueryRow(ctx, `SELECT count(*) FROM player_scalar_daily_floors WHERE player_id=$1`, int64(player)).Scan(&legacyAnchors); err != nil || legacyAnchors != 0 {
		t.Fatalf("legacy projection wrote anchor rows=%d err=%v", legacyAnchors, err)
	}

	oldOperation := i910cReconstructOperation(t, old)
	service := dailyFloorService(p)
	_, refusal := service.Runner.Run(ctx, oldOperation, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		_, err := service.PrepareGluePurchaseTx(ctx, scope.Tx, identity.ActorContext{PlayerID: player}, i910cPurchaseRequest(player, oldOperation, 50, 50, 300), oldOperation)
		return err
	})
	if refusal == nil || !errors.Is(refusal, economy.ErrUnknownResource) {
		t.Fatalf("pre-activation purchase refusal=%v want economy.ErrUnknownResource (old source has no glue scalar)", refusal)
	}

	deployer := registry.Service{Runner: tx.Runner{DB: p}, Repo: store, Fresh: p, Providers: registry.DefaultProviderSet()}
	if _, err = deployer.EnsureBuiltinInstalled(ctx, op(), bundle); err != nil {
		t.Fatal(err)
	}
	verification, err := store.VerifyRevision(ctx, p, bundle)
	if err != nil || !verification.Matches(bundle) || verification.DormInputsCount != 1 {
		t.Fatalf("candidate exact verification: %+v %v", verification, err)
	}
	activationAfterInstall, ok, err := store.ReadActivation(ctx, p)
	if err != nil || !ok || activationAfterInstall != activationBefore {
		t.Fatalf("install switched activation: %+v %v %v", activationAfterInstall, ok, err)
	}
	if manifestSHA2, sources2 := i910cManifestSHA(t, p, i910cAcceptedRevision); manifestSHA2 != manifestSHA || sources2 != sources {
		t.Fatalf("old manifest changed during install: %s/%d", manifestSHA2, sources2)
	}
	if payloadSHA2, _, _, _ := i910cDormPayload(t, p, i910cAcceptedRevision); payloadSHA2 != payloadSHA {
		t.Fatalf("old dorm payload changed during install: %s", payloadSHA2)
	}
	if _, err = store.DormCatalogTx(ctx, p, i910cAcceptedRevision); err != nil {
		t.Fatalf("old catalog after install: %v", err)
	}

	if _, err = deployer.ActivateBuiltin(ctx, op(), bundle, activationBefore, "i9-10c-qualification-upgrade"); err != nil {
		t.Fatal(err)
	}
	activationAfter, ok, err := store.ReadActivation(ctx, p)
	if err != nil || !ok || activationAfter.RevisionID != i910cCandidateRevision || activationAfter.Version != activationBefore.Version+1 {
		t.Fatalf("activation after: %+v %v %v", activationAfter, ok, err)
	}
	if _, err = deployer.ValidateActiveReadiness(ctx); err != nil {
		t.Fatal(err)
	}
	if manifestSHA3, sources3 := i910cManifestSHA(t, p, i910cAcceptedRevision); manifestSHA3 != manifestSHA || sources3 != sources {
		t.Fatalf("old manifest changed after activation: %s/%d", manifestSHA3, sources3)
	}
	if payloadSHA3, _, _, _ := i910cDormPayload(t, p, i910cAcceptedRevision); payloadSHA3 != payloadSHA {
		t.Fatalf("old dorm payload changed after activation: %s", payloadSHA3)
	}
	oldCatalog, err = store.DormCatalogTx(ctx, p, i910cAcceptedRevision)
	if err != nil || oldCatalog.Glue != nil {
		t.Fatalf("old catalog after activation glue=%v err=%v", oldCatalog.Glue, err)
	}
	rooms, err = owner.ListRoomsTx(ctx, p, player)
	if err != nil {
		t.Fatal(err)
	}
	if room, exists := rooms[old.RoomID]; !exists || room.CreationRevision != old.RoomCreationRevision {
		t.Fatalf("old room after activation=%+v exists=%v", room, exists)
	}
	if _, err = store.DormCatalogTx(ctx, p, old.RoomCreationRevision); err != nil {
		t.Fatalf("old room creation revision after activation: %v", err)
	}

	newCatalog, err := store.DormCatalogTx(ctx, p, i910cCandidateRevision)
	if err != nil || newCatalog.Glue == nil {
		t.Fatalf("new catalog glue=%v err=%v", newCatalog.Glue, err)
	}
	glue := newCatalog.Glue
	vipZeroCap, capKnown := glue.VIPDailyCap(0)
	firstCost, costKnown := glue.PurchaseCost(1)
	if !capKnown || vipZeroCap != 1 || !costKnown || firstCost != 50 || glue.DailyFloor != 100 || glue.PurchaseAmount != 50 || glue.PurchaseStartLimit != 300 {
		t.Fatalf("new glue rules=%+v vip0=%d/%v cost1=%d/%v", glue, vipZeroCap, capKnown, firstCost, costKnown)
	}
	glueResource, err := store.ResolveResourceTx(ctx, p, i910cCandidateRevision, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "glue", Amount: 1})
	if err != nil || glueResource.Kind != grant.ScalarCurrency || glueResource.Stack != nil {
		t.Fatalf("new glue resource kind=%v stack=%v err=%v", glueResource.Kind, glueResource.Stack, err)
	}

	buyer := bornActor(t, p)
	expectedGlue, err := i5.EffectiveScalarTx(ctx, p, i5store.Store{Queryer: p}, store, buyer.PlayerID, "glue", at)
	if err != nil || expectedGlue != 100 {
		t.Fatalf("new projection=%d err=%v", expectedGlue, err)
	}
	var newAnchors int64
	if err := p.QueryRow(ctx, `SELECT count(*) FROM player_scalar_daily_floors WHERE player_id=$1`, int64(buyer.PlayerID)).Scan(&newAnchors); err != nil || newAnchors != 0 {
		t.Fatalf("new projection wrote anchor rows=%d err=%v", newAnchors, err)
	}
	current := floorOperation(i910cCandidateRevision, at)
	if err = gluePurchaseCounterTransaction(service, owner, buyer, *glue, current); err != nil {
		t.Fatal(err)
	}
	crystalAfter := i910cReadScalar(t, p, buyer.PlayerID, "crystal")
	glueAfter := i910cReadScalar(t, p, buyer.PlayerID, "glue")
	storedCounter, counterExists, err := owner.ReadGluePurchasesTx(ctx, p, buyer.PlayerID)
	if err != nil || !counterExists || storedCounter.Count != 1 || storedCounter.StateVersion != 1 || storedCounter.GameDay != modes.Day(at) {
		t.Fatalf("counter=%+v exists=%v err=%v", storedCounter, counterExists, err)
	}
	if crystalAfter != 950 || glueAfter != 150 {
		t.Fatalf("purchase values crystal=%d glue=%d", crystalAfter, glueAfter)
	}

	replayIdentity := receiptIdentityFor(player, old.ReceiptSemanticKey)
	prior, found, err := (kernelstore.Store{}).FindTx(ctx, p, replayIdentity)
	if err != nil || !found {
		t.Fatalf("retained receipt before replay: %v %v", found, err)
	}
	receiptsBefore := i910cGrantReceiptCount(t, p, player)
	manaBefore := i910cReadScalar(t, p, player, "mana")
	stackBefore := i910cReadStack(t, p, player, i910cStackItem)
	var storedPayload, replayPayload any
	if err = json.Unmarshal(prior.ResultPayload, &storedPayload); err != nil {
		t.Fatal(err)
	}
	plan := grant.Plan{PlayerID: player, Source: old.PlanSource, Lines: old.PlanLines}
	replayed, err := i910cSettleGrant(t, service, p, identity.ActorContext{PlayerID: player}, plan, oldOperation)
	if err != nil {
		t.Fatal(err)
	}
	replayRaw, err := json.Marshal(replayed)
	if err != nil {
		t.Fatal(err)
	}
	if err = json.Unmarshal(replayRaw, &replayPayload); err != nil {
		t.Fatal(err)
	}
	receiptsAfter := i910cGrantReceiptCount(t, p, player)
	manaAfter := i910cReadScalar(t, p, player, "mana")
	stackAfter := i910cReadStack(t, p, player, i910cStackItem)
	if !reflect.DeepEqual(storedPayload, replayPayload) || receiptsAfter != receiptsBefore || manaAfter != manaBefore || stackAfter != stackBefore {
		t.Fatalf("old replay changed state equal=%v receipts=%d/%d mana=%d/%d stack=%d/%d", reflect.DeepEqual(storedPayload, replayPayload), receiptsBefore, receiptsAfter, manaBefore, manaAfter, stackBefore, stackAfter)
	}
	newOperation := oldOperation
	newOperation.Policies, err = policy.NewSet(policy.Ref{Name: "content", Version: i910cCandidateRevision})
	if err != nil {
		t.Fatal(err)
	}
	second, err := i910cSettleGrant(t, service, p, identity.ActorContext{PlayerID: player}, plan, newOperation)
	if err != nil {
		t.Fatal(err)
	}
	if second.ReceiptID != prior.ID.String() || i910cGrantReceiptCount(t, p, player) != receiptsBefore || i910cReadScalar(t, p, player, "mana") != manaBefore || i910cReadStack(t, p, player, i910cStackItem) != stackBefore {
		t.Fatal("new-active-revision replay produced a second value effect")
	}

	evidence := i910cUpgradeEvidence{
		OldRevision:           i910cAcceptedRevision,
		NewRevision:           i910cCandidateRevision,
		OldManifestSHA:        manifestSHA,
		OldDormPayloadSHA:     payloadSHA,
		GooseVersion:          gooseVersion,
		ActivationBefore:      activationBefore.RevisionID,
		ActivationBeforeVer:   activationBefore.Version,
		ActivationAfter:       activationAfter.RevisionID,
		ActivationAfterVer:    activationAfter.Version,
		OldDormSchema:         payloadSchema,
		OldGlueAbsent:         true,
		OldRoomID:             oldRoom.ID,
		OldRoomCreationRev:    oldRoom.CreationRevision,
		LegacyProjection:      25,
		LegacyAnchorRows:      legacyAnchors,
		PreActivationRefusal:  refusal.Error(),
		NewDormGlueFloor:      glue.DailyFloor,
		NewDormVIPZeroCap:     vipZeroCap,
		NewDormFirstCost:      firstCost,
		NewGlueScalarNamed:    glueResource.Kind == grant.ScalarCurrency && glueResource.Stack == nil,
		NewProjectionReadOnly: newAnchors == 0,
		NewProjectionAmount:   expectedGlue,
		PurchaseCrystalAfter:  crystalAfter,
		PurchaseGlueAfter:     glueAfter,
		CounterCount:          storedCounter.Count,
		CounterVersion:        storedCounter.StateVersion,
		CounterDay:            storedCounter.GameDay,
		OldReceiptID:          old.ReceiptID,
		OldReceiptFingerprint: old.ReceiptFingerprint,
		ReplayReceiptID:       prior.ID.String(),
		ReplayResultEqual:     reflect.DeepEqual(storedPayload, replayPayload),
		ReplayReceiptsBefore:  receiptsBefore,
		ReplayReceiptsAfter:   receiptsAfter,
		ReplayManaBefore:      manaBefore,
		ReplayManaAfter:       manaAfter,
		ReplayStackBefore:     stackBefore,
		ReplayStackAfter:      stackAfter,
	}
	encoded, err := json.MarshalIndent(evidence, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if path := os.Getenv("GXB_I910C_UPGRADE_EVIDENCE"); path != "" {
		if err := os.WriteFile(path, encoded, 0600); err != nil {
			t.Fatal(err)
		}
	}
	t.Logf("REAL_PG upgrade: old=%s new=%s activation=%s v%d->v%d room=%d/%s projection=%d purchase crystal=%d glue=%d counter=%d/%d replay=%s",
		i910cAcceptedRevision, i910cCandidateRevision, activationAfter.RevisionID, activationBefore.Version, activationAfter.Version, oldRoom.ID, oldRoom.CreationRevision, expectedGlue, crystalAfter, glueAfter, storedCounter.Count, storedCounter.StateVersion, prior.ID)
}

func receiptIdentityFor(player identity.PlayerID, semanticKey string) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(int64(player)), Domain: "grant", Operation: "settle", SemanticKey: semanticKey}
}

func i910cSettleGrant(t *testing.T, service i5.Service, p *pg.Pool, actor identity.ActorContext, plan grant.Plan, current operation.Context) (i5.GrantResult, error) {
	t.Helper()
	begin, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	result, err := service.SettleGrantTx(ctx, begin, actor, plan, current, i5.GrantTxOptions{})
	if err != nil {
		begin.Rollback(ctx)
		return result, err
	}
	if err = begin.Commit(ctx); err != nil {
		return result, err
	}
	return result, nil
}
