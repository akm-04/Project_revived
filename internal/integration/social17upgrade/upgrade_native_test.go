//go:build postgres

package social17upgrade_test

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
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/socialexchange"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const acceptedRevision = "414a5de9a6af42b55948fe77e40a25d764c6bb9b3d2cab14d8bb1a5b670d537b"

var ctx = context.Background()

type oldCapture struct {
	Revision              string               `json:"revision"`
	ManifestTextSHA       string               `json:"manifest_text_sha"`
	ManifestSources       int                  `json:"manifest_sources"`
	GooseVersion          int64                `json:"goose_version"`
	ActivationRevision    string               `json:"activation_revision"`
	ActivationVersion     int64                `json:"activation_version"`
	PlayerID              int64                `json:"player_id"`
	PlanSource            grant.SourceIdentity `json:"plan_source"`
	PlanLines             []grant.Line         `json:"plan_lines"`
	OperationID           string               `json:"operation_id"`
	OperationStartedAt    time.Time            `json:"operation_started_at"`
	ReceiptV2SemanticKey  string               `json:"receipt_v2_semantic_key"`
	ReceiptID             string               `json:"receipt_id"`
	ReceiptFingerprint    string               `json:"receipt_fingerprint"`
	ReceiptResultPayload  json.RawMessage      `json:"receipt_result_payload"`
	ReceiptCount          int64                `json:"receipt_count"`
	ManaAfter             int64                `json:"mana_after"`
	StackItemID           int64                `json:"stack_item_id"`
	StackQuantityAfter    int64                `json:"stack_quantity_after"`
	GrantResultContentRev string               `json:"grant_result_content_revision"`
}

type upgradeCapture struct {
	CandidateRevision           string  `json:"candidate_revision"`
	CandidateSources            int     `json:"candidate_sources"`
	OldRevision                 string  `json:"old_revision"`
	OldManifestTextSHA          string  `json:"old_manifest_text_sha"`
	GooseVersion                int64   `json:"goose_version"`
	ActivationBeforeRevision    string  `json:"activation_before_revision"`
	ActivationBeforeVersion     int64   `json:"activation_before_version"`
	ActivationAfterRevision     string  `json:"activation_after_revision"`
	ActivationAfterVersion      int64   `json:"activation_after_version"`
	RevisionRows                int64   `json:"revision_rows"`
	SocialCatalogRows           int64   `json:"social_catalog_rows"`
	OldSocialCatalogRows        int64   `json:"old_social_catalog_rows"`
	NewVerifyExact              bool    `json:"new_verify_exact"`
	NewVerifySocialInputCount   int64   `json:"new_verify_social_input_count"`
	OldSocialUnavailable        bool    `json:"old_social_unavailable"`
	NewSocialProductIDs         []int64 `json:"new_social_product_ids"`
	NewSocialDropboxes          int     `json:"new_social_dropboxes"`
	NewSocialRecallMilestones   int     `json:"new_social_recall_milestones"`
	NewSocialInvitationMissions int     `json:"new_social_invitation_missions"`
	ExchangePlansBuilt          int     `json:"exchange_plans_built"`
	OldCourseReadable           bool    `json:"old_course_readable"`
	OldBookReadable             bool    `json:"old_book_readable"`
	OldGiftReadable             bool    `json:"old_gift_readable"`
	OldManaReadable             bool    `json:"old_mana_readable"`
	NewCourseReadable           bool    `json:"new_course_readable"`
	NewBookReadable             bool    `json:"new_book_readable"`
	NewGiftReadable             bool    `json:"new_gift_readable"`
	NewManaReadable             bool    `json:"new_mana_readable"`
	ReplayReceiptID             string  `json:"replay_receipt_id"`
	ReplayFingerprint           string  `json:"replay_fingerprint"`
	ReplayResultEqual           bool    `json:"replay_result_equal"`
	ReceiptCountBeforeReplay    int64   `json:"receipt_count_before_replay"`
	ReceiptCountAfterReplay     int64   `json:"receipt_count_after_replay"`
	ManaBeforeReplay            int64   `json:"mana_before_replay"`
	ManaAfterReplay             int64   `json:"mana_after_replay"`
	StackBeforeReplay           int64   `json:"stack_before_replay"`
	StackAfterReplay            int64   `json:"stack_after_replay"`
	NewRevisionReplayNoEffect   bool    `json:"new_revision_replay_no_effect"`
}

func open(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_SOCIAL17_DSN")
	if dsn == "" {
		t.Fatal("GXB_SOCIAL17_DSN required")
	}
	p, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "social17-current-upgrade"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	return p
}

func manifestSHA(t *testing.T, p *pg.Pool, revision string) string {
	t.Helper()
	var text string
	if err := p.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&text); err != nil {
		t.Fatal(err)
	}
	sum := sha256.Sum256([]byte(text))
	return hex.EncodeToString(sum[:])
}

func scalar(t *testing.T, p *pg.Pool, player identity.PlayerID, key string) int64 {
	t.Helper()
	balance, exists, err := (i5store.Store{}).ReadScalarTx(ctx, p, player, key)
	if err != nil {
		t.Fatal(err)
	}
	if !exists {
		return 0
	}
	return balance.Amount
}

func stack(t *testing.T, p *pg.Pool, player identity.PlayerID, itemID int64) int64 {
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

func receiptCount(t *testing.T, p *pg.Pool, player identity.PlayerID) int64 {
	t.Helper()
	var count int64
	if err := p.QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_key=$1 AND domain='grant' AND operation='settle'`, fmt.Sprint(player)).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

func grantService(p *pg.Pool) i5.Service {
	values := i5store.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	return i5.Service{
		Runner:      tx.Runner{DB: p},
		Store:       values,
		Content:     content,
		Privileges:  i5.BaselinePrivilegeProvider{},
		Functions:   i5.PetStarterFunctionAnnouncements{},
		Directory:   i4store.DirectoryLevelProjection{},
		Backpack:    values,
		Receipts:    kernelstore.Store{},
		ReceiptRead: kernelstore.Reader{Queryer: p},
	}
}

func requireLegacyReads(t *testing.T, p *pg.Pool, revision string) (course, book, gift, mana bool) {
	t.Helper()
	store := contentstore.Store{Queryer: p}
	c, err := store.CourseCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatalf("course revision %s: %v", revision, err)
	}
	if err = c.Validate(); err != nil {
		t.Fatalf("course validate %s: %v", revision, err)
	}
	b, err := store.BookCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatalf("book revision %s: %v", revision, err)
	}
	if err = b.Validate(); err != nil {
		t.Fatalf("book validate %s: %v", revision, err)
	}
	g, err := store.ReadGiftContent(ctx, p, revision)
	if err != nil {
		t.Fatalf("gift revision %s: %v", revision, err)
	}
	if err = g.Validate(); err != nil {
		t.Fatalf("gift validate %s: %v", revision, err)
	}
	if _, err = store.ResolveResourceTx(ctx, p, revision, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 1}); err != nil {
		t.Fatalf("mana revision %s: %v", revision, err)
	}
	return true, true, true, true
}

func requireNewSocial(t *testing.T, p *pg.Pool, revision string) (builtin.SocialInputCatalog, socialexchange.Catalog) {
	t.Helper()
	store := contentstore.Store{Queryer: p}
	catalog, err := store.SocialInputCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatalf("social source revision %s: %v", revision, err)
	}
	productIDs := make([]int64, 0, len(catalog.ExchangeProducts))
	for _, product := range catalog.ExchangeProducts {
		productIDs = append(productIDs, product.ID)
	}
	if !reflect.DeepEqual(productIDs, []int64{1, 2, 3}) || len(catalog.Dropboxes) != 3 || len(catalog.RecallMilestones) != 25 || len(catalog.InvitationMissions) != 250 {
		t.Fatalf("social source drift revision %s: products=%v dropboxes=%d recall=%d invitations=%d", revision, productIDs, len(catalog.Dropboxes), len(catalog.RecallMilestones), len(catalog.InvitationMissions))
	}
	exchange, err := store.SocialExchangeCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatalf("social exchange revision %s: %v", revision, err)
	}
	o, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	for _, product := range exchange.Products {
		plan, err := socialexchange.BuildPlan(exchange, product.ID, 1, o)
		if err != nil || plan.PriceCurrency != socialexchange.PriceCurrency || plan.UnitPrice != product.SellPrice || len(plan.Items) == 0 {
			t.Fatalf("product %d plan revision %s: %+v %v", product.ID, revision, plan, err)
		}
	}
	return catalog, exchange
}

func TestSocial17HistoricalUpgradeAndReceiptReplay(t *testing.T) {
	evidencePath := os.Getenv("GXB_SOCIAL17_EVIDENCE")
	configured := evidencePath != "" || os.Getenv("GXB_SOCIAL17_DSN") != "" || os.Getenv("GXB_SOCIAL17_UPGRADE_EVIDENCE") != ""
	if !configured {
		t.Skip("dedicated historical-upgrade database and evidence inputs not configured")
	}
	for _, name := range []string{"GXB_SOCIAL17_DSN", "GXB_SOCIAL17_EVIDENCE", "GXB_SOCIAL17_UPGRADE_EVIDENCE"} {
		if os.Getenv(name) == "" {
			t.Fatalf("%s required before running the one-shot historical upgrade", name)
		}
	}
	raw, err := os.ReadFile(evidencePath)
	if err != nil {
		t.Fatal(err)
	}
	var old oldCapture
	if err = json.Unmarshal(raw, &old); err != nil {
		t.Fatal(err)
	}
	p := open(t)
	store := contentstore.Store{Queryer: p}
	bundle, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	if bundle.RevisionID() == acceptedRevision || bundle.RevisionID() != "61acbba9a13d43a85d61079baf1f8f6dfa76df8dbd50f3b93fb581239afc2c9d" {
		t.Fatalf("candidate bundle revision=%s", bundle.RevisionID())
	}
	var gooseVersion int64
	if err = p.QueryRow(ctx, `SELECT max(version_id) FROM goose_db_version`).Scan(&gooseVersion); err != nil {
		t.Fatal(err)
	}
	if gooseVersion != 116 {
		t.Fatalf("migrated goose=%d", gooseVersion)
	}
	activationBefore, ok, err := store.ReadActivation(ctx, p)
	if err != nil || !ok || activationBefore.RevisionID != acceptedRevision || activationBefore.Version != old.ActivationVersion {
		t.Fatalf("activation before install: %+v %v %v", activationBefore, ok, err)
	}
	if got := manifestSHA(t, p, acceptedRevision); got != old.ManifestTextSHA {
		t.Fatalf("old manifest changed before install: %s != %s", got, old.ManifestTextSHA)
	}
	if _, err = store.SocialInputCatalogTx(ctx, p, acceptedRevision); !errors.Is(err, contentstore.ErrSocialContentUnavailable) {
		t.Fatalf("old revision served new Social before install: %v", err)
	}
	oldCourse, oldBook, oldGift, oldMana := requireLegacyReads(t, p, acceptedRevision)
	player := identity.PlayerID(old.PlayerID)
	if scalar(t, p, player, "mana") != old.ManaAfter || stack(t, p, player, old.StackItemID) != old.StackQuantityAfter || receiptCount(t, p, player) != old.ReceiptCount {
		t.Fatal("old value state changed during migration")
	}

	svc := registry.Service{Runner: tx.Runner{DB: p}, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}
	summary, err := registry.Initialize(ctx, svc, operation.Factory{Clock: clock.System{}})
	if err != nil {
		t.Fatal(err)
	}
	if summary.Activation.RevisionID != acceptedRevision || summary.Activation.Version != old.ActivationVersion {
		t.Fatalf("bootstrap changed old activation: %+v", summary.Activation)
	}
	verification, err := store.VerifyRevision(ctx, p, bundle)
	if err != nil || !verification.Matches(bundle) || verification.SocialInputCount != 1 {
		t.Fatalf("candidate exact verification: %+v %v", verification, err)
	}
	var revisionRows, socialRows, oldSocialRows int64
	if err = p.QueryRow(ctx, `SELECT (SELECT count(*) FROM gxb_content_revisions),(SELECT count(*) FROM content_social_input_catalogs),(SELECT count(*) FROM content_social_input_catalogs WHERE revision_id=$1)`, acceptedRevision).Scan(&revisionRows, &socialRows, &oldSocialRows); err != nil {
		t.Fatal(err)
	}
	if revisionRows != 2 || socialRows != 1 || oldSocialRows != 0 {
		t.Fatalf("installed rows revisions=%d social=%d oldSocial=%d", revisionRows, socialRows, oldSocialRows)
	}
	if got := manifestSHA(t, p, acceptedRevision); got != old.ManifestTextSHA {
		t.Fatalf("old manifest changed during install: %s", got)
	}
	activationAfterInstall, _, err := store.ReadActivation(ctx, p)
	if err != nil || activationAfterInstall != activationBefore {
		t.Fatalf("install switched activation: %+v %v", activationAfterInstall, err)
	}
	if _, err = store.SocialInputCatalogTx(ctx, p, acceptedRevision); !errors.Is(err, contentstore.ErrSocialContentUnavailable) {
		t.Fatalf("old revision served new Social after install: %v", err)
	}
	newCatalog, exchange := requireNewSocial(t, p, bundle.RevisionID())
	if scalar(t, p, player, "mana") != old.ManaAfter || stack(t, p, player, old.StackItemID) != old.StackQuantityAfter {
		t.Fatal("install changed old value state")
	}

	result, err := svc.ActivateBuiltin(ctx, opFactory(t), bundle, activationBefore, "i9-10e-social17-qualified-upgrade")
	if err != nil {
		t.Fatal(err)
	}
	_ = result
	activationAfter, ok, err := store.ReadActivation(ctx, p)
	if err != nil || !ok || activationAfter.RevisionID != bundle.RevisionID() || activationAfter.Version != old.ActivationVersion+1 {
		t.Fatalf("activation after: %+v %v %v", activationAfter, ok, err)
	}
	if _, err = svc.ValidateActiveReadiness(ctx); err != nil {
		t.Fatal(err)
	}
	oldCourse2, oldBook2, oldGift2, oldMana2 := requireLegacyReads(t, p, acceptedRevision)
	newCourse, newBook, newGift, newMana := requireLegacyReads(t, p, bundle.RevisionID())
	requireNewSocial(t, p, bundle.RevisionID())
	if _, err = store.SocialInputCatalogTx(ctx, p, acceptedRevision); !errors.Is(err, contentstore.ErrSocialContentUnavailable) {
		t.Fatalf("old revision served new Social after activation: %v", err)
	}
	if got := manifestSHA(t, p, acceptedRevision); got != old.ManifestTextSHA {
		t.Fatalf("old manifest changed after activation: %s", got)
	}

	replayIdentity := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(player), Domain: "grant", Operation: "settle", SemanticKey: old.ReceiptV2SemanticKey}
	prior, found, err := (kernelstore.Store{}).FindTx(ctx, p, replayIdentity)
	if err != nil || !found {
		t.Fatalf("retained receipt before replay: %v %v", found, err)
	}
	if hex.EncodeToString(prior.RequestFingerprint[:]) != old.ReceiptFingerprint || prior.ID.String() != old.ReceiptID {
		t.Fatalf("retained receipt identity drifted: %s %s", prior.ID.String(), hex.EncodeToString(prior.RequestFingerprint[:]))
	}
	receiptsBefore := receiptCount(t, p, player)
	manaBefore := scalar(t, p, player, "mana")
	stackBefore := stack(t, p, player, old.StackItemID)

	originalOp := reconstructOperation(t, old)
	plan := grant.Plan{PlayerID: player, Source: old.PlanSource, Lines: old.PlanLines}
	begin, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	replayed, err := grantService(p).SettleGrantTx(ctx, begin, actorFor(player), plan, originalOp, i5.GrantTxOptions{})
	if err != nil {
		begin.Rollback(ctx)
		t.Fatal(err)
	}
	if err = begin.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var storedPayload, replayPayload any
	if err = json.Unmarshal(prior.ResultPayload, &storedPayload); err != nil {
		t.Fatal(err)
	}
	replayRaw, err := json.Marshal(replayed)
	if err != nil {
		t.Fatal(err)
	}
	if err = json.Unmarshal(replayRaw, &replayPayload); err != nil {
		t.Fatal(err)
	}
	receiptsAfter := receiptCount(t, p, player)
	manaAfter := scalar(t, p, player, "mana")
	stackAfter := stack(t, p, player, old.StackItemID)
	if !reflect.DeepEqual(storedPayload, replayPayload) || receiptsAfter != receiptsBefore || manaAfter != manaBefore || stackAfter != stackBefore {
		t.Fatalf("replay changed state equal=%v receipts=%d/%d mana=%d/%d stack=%d/%d", reflect.DeepEqual(storedPayload, replayPayload), receiptsBefore, receiptsAfter, manaBefore, manaAfter, stackBefore, stackAfter)
	}
	retained, found, err := (kernelstore.Store{}).FindTx(ctx, p, replayIdentity)
	if err != nil || !found || retained.ID != prior.ID || hex.EncodeToString(retained.RequestFingerprint[:]) != old.ReceiptFingerprint {
		t.Fatalf("retained receipt after replay: %v %v", found, err)
	}

	newRevisionOp := reconstructOperation(t, old)
	newRevisionOp.Policies, err = policy.NewSet(policy.Ref{Name: "content", Version: bundle.RevisionID()})
	if err != nil {
		t.Fatal(err)
	}
	begin, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	second, err := grantService(p).SettleGrantTx(ctx, begin, actorFor(player), plan, newRevisionOp, i5.GrantTxOptions{})
	if err != nil {
		begin.Rollback(ctx)
		t.Fatal(err)
	}
	if err = begin.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if receiptCount(t, p, player) != receiptsBefore || scalar(t, p, player, "mana") != manaBefore || stack(t, p, player, old.StackItemID) != stackBefore || second.ReceiptID != old.ReceiptID {
		t.Fatal("new-active-revision replay produced a second value effect")
	}

	evidence := upgradeCapture{
		CandidateRevision:           bundle.RevisionID(),
		CandidateSources:            manifestSourceCount(t, p, bundle.RevisionID()),
		OldRevision:                 acceptedRevision,
		OldManifestTextSHA:          manifestSHA(t, p, acceptedRevision),
		GooseVersion:                gooseVersion,
		ActivationBeforeRevision:    activationBefore.RevisionID,
		ActivationBeforeVersion:     activationBefore.Version,
		ActivationAfterRevision:     activationAfter.RevisionID,
		ActivationAfterVersion:      activationAfter.Version,
		RevisionRows:                revisionRows,
		SocialCatalogRows:           socialRows,
		OldSocialCatalogRows:        oldSocialRows,
		NewVerifyExact:              verification.Matches(bundle),
		NewVerifySocialInputCount:   verification.SocialInputCount,
		OldSocialUnavailable:        true,
		NewSocialProductIDs:         []int64{newCatalog.ExchangeProducts[0].ID, newCatalog.ExchangeProducts[1].ID, newCatalog.ExchangeProducts[2].ID},
		NewSocialDropboxes:          len(newCatalog.Dropboxes),
		NewSocialRecallMilestones:   len(newCatalog.RecallMilestones),
		NewSocialInvitationMissions: len(newCatalog.InvitationMissions),
		ExchangePlansBuilt:          len(exchange.Products),
		OldCourseReadable:           oldCourse && oldCourse2,
		OldBookReadable:             oldBook && oldBook2,
		OldGiftReadable:             oldGift && oldGift2,
		OldManaReadable:             oldMana && oldMana2,
		NewCourseReadable:           newCourse,
		NewBookReadable:             newBook,
		NewGiftReadable:             newGift,
		NewManaReadable:             newMana,
		ReplayReceiptID:             retained.ID.String(),
		ReplayFingerprint:           hex.EncodeToString(retained.RequestFingerprint[:]),
		ReplayResultEqual:           reflect.DeepEqual(storedPayload, replayPayload),
		ReceiptCountBeforeReplay:    receiptsBefore,
		ReceiptCountAfterReplay:     receiptsAfter,
		ManaBeforeReplay:            manaBefore,
		ManaAfterReplay:             manaAfter,
		StackBeforeReplay:           stackBefore,
		StackAfterReplay:            stackAfter,
		NewRevisionReplayNoEffect:   true,
	}
	evidenceRaw, err := json.MarshalIndent(evidence, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err = os.WriteFile(os.Getenv("GXB_SOCIAL17_UPGRADE_EVIDENCE"), evidenceRaw, 0600); err != nil {
		t.Fatal(err)
	}
	t.Logf("REAL_PG historical upgrade: old=%s candidate=%s activation=%s v%d->v%d receipts=%d mana=%d stack=%d replay_equal=%v",
		acceptedRevision, bundle.RevisionID(), activationAfter.RevisionID, activationBefore.Version, activationAfter.Version, receiptsAfter, manaAfter, stackAfter, evidence.ReplayResultEqual)
}

func manifestSourceCount(t *testing.T, p *pg.Pool, revision string) int {
	t.Helper()
	var count int
	if err := p.QueryRow(ctx, `SELECT jsonb_array_length(manifest->'sources') FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

func opFactory(t *testing.T) operation.Context {
	t.Helper()
	o, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	return o
}

func reconstructOperation(t *testing.T, old oldCapture) operation.Context {
	t.Helper()
	id, err := ids.ParseUUID(old.OperationID)
	if err != nil {
		t.Fatal(err)
	}
	o := operation.Context{ID: id, StartedAt: old.OperationStartedAt.UTC()}
	o.Policies, err = policy.NewSet(policy.Ref{Name: "content", Version: old.Revision})
	if err != nil {
		t.Fatal(err)
	}
	return o
}

func actorFor(player identity.PlayerID) identity.ActorContext {
	return identity.ActorContext{PlayerID: player}
}
