//go:build postgres

package playerdisplay_test

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// New owner foundation only: does not qualify commands, API, economic effects or process recovery.
func TestI7C2DBookCoreSourceRoundtripRollbackPreserve(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	legacyRevision := seedHistoricalBookInputs(t, p)
	a := actor(t, p)
	content := contentstore.Store{Queryer: p}
	active, on, e := content.BookInputsActive(ctx)
	if e != nil || !on || active != legacyRevision {
		t.Fatalf("fresh database must start from seeded legacy R1: active %q legacy %q new %q err %v", active, legacyRevision, rev, e)
	}
	if active == rev {
		t.Fatalf("legacy and new revisions must differ: %q", active)
	}
	legacy, e := content.BookCatalogTx(ctx, p, active)
	if e != nil || len(legacy.Buildings) != 112 || len(legacy.Skills) != 399 {
		t.Fatal("legacy source binder", e)
	}
	c, e := content.BookCatalogTx(ctx, p, rev)
	if e != nil || len(c.Buildings) != 135 || len(c.Skills) != 399 {
		t.Fatal("new source binder", e)
	}
	if c.Books[130001020].PieceCount != 40 || c.Books[130001021].PieceCount != 45 {
		t.Fatal("qualified anomaly policy")
	}
	store := bookstore.Store{}
	at := time.Now().UTC().Add(-time.Hour)
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	if e = store.EnsureRootTx(ctx, tr, a.PlayerID, rev, at); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	root, e := store.ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.Facts.Validate(c) != nil || root.Facts.Validate(legacy) != nil || root.Version != 1 || root.Facts.Buildings[4].Level != 1 || len(root.Facts.Skills) != 0 {
		t.Fatal(root, e)
	}
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	locked, e := store.LockRootTx(ctx, tr, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	b := locked.Facts.Buildings[4]
	b.Level = 50
	locked.Facts.Buildings[4] = b
	locked.Version++
	locked.UpdatedAt = at.Add(time.Second)
	if e = store.SaveRootTx(ctx, tr, locked, 1); e != nil {
		t.Fatal(e)
	}
	if e = tr.Rollback(ctx); e != nil {
		t.Fatal(e)
	}
	root, e = store.ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.Facts.Buildings[4].Level != 1 {
		t.Fatal("rollback", root, e)
	}
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	locked, e = store.LockRootTx(ctx, tr, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	b = locked.Facts.Buildings[4]
	b.Level = 50
	locked.Facts.Buildings[4] = b
	locked.Version++
	locked.UpdatedAt = at.Add(time.Second)
	if e = store.SaveRootTx(ctx, tr, locked, 1); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	if e = store.EnsureRootTx(ctx, tr, a.PlayerID, rev, time.Now().UTC()); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	root, e = store.ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.Facts.Buildings[4].Level != 50 || root.Version != 2 || root.Facts.Validate(c) != nil || root.Facts.Validate(legacy) != nil {
		t.Fatal("preserve explicit", root, e)
	}
}

func TestI7C2DBookCostScalarProfileRequired(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	store := contentstore.Store{}
	for _, key := range []string{"magic_dust", "magic_liquid", "magic_energy", "magic_exp"} {
		_, e := store.ResolveResourceTx(ctx, p, rev, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: key, Amount: 1})
		if e != nil {
			t.Fatalf("required Book cost %s unresolved: %v", key, e)
		}
	}
}

// seedHistoricalBookInputs adds the retained schema-1 revision a fresh gate database does not contain.
func seedHistoricalBookInputs(t *testing.T, p *pg.Pool) string {
	t.Helper()
	manifestRaw, err := os.ReadFile("../../content/builtin/testdata/manifest_i9_9c_404.json")
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := registry.DecodeManifestStrict(manifestRaw)
	if err != nil {
		t.Fatal(err)
	}
	payload, err := os.ReadFile("../../content/builtin/testdata/book_input_catalog_i9_9c.json")
	if err != nil {
		t.Fatal(err)
	}
	var decodedPayload any
	if err = json.Unmarshal(payload, &decodedPayload); err != nil {
		t.Fatal(err)
	}
	canonicalPayload, err := json.Marshal(decodedPayload)
	if err != nil {
		t.Fatal(err)
	}
	artifactDigest := sha256.Sum256(append(canonicalPayload, '\n'))
	if hex.EncodeToString(artifactDigest[:]) != manifest.ArtifactSHA256s["book_input_catalog.json"] {
		t.Fatal("retained historical book catalog does not match its manifest")
	}

	databaseTransaction, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer databaseTransaction.Rollback(ctx)
	if _, err = databaseTransaction.Exec(ctx, `
		INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest)
		VALUES($1,decode($1,'hex'),$2,$3,$4,$5::jsonb)
		ON CONFLICT(revision_id) DO NOTHING`, manifest.RevisionID, manifest.SchemaVersion, manifest.CompilerVersion, manifest.ParserVersion, string(manifestRaw)); err != nil {
		t.Fatal(err)
	}
	if _, err = databaseTransaction.Exec(ctx, `
		INSERT INTO content_book_input_catalogs(revision_id,payload)VALUES($1,$2::jsonb)
		ON CONFLICT(revision_id) DO NOTHING`, manifest.RevisionID, string(payload)); err != nil {
		t.Fatal(err)
	}
	var manifestMatches, payloadMatches bool
	if err = databaseTransaction.QueryRow(ctx, `SELECT manifest=$2::jsonb FROM gxb_content_revisions WHERE revision_id=$1`, manifest.RevisionID, string(manifestRaw)).Scan(&manifestMatches); err != nil {
		t.Fatal(err)
	}
	if err = databaseTransaction.QueryRow(ctx, `SELECT payload=$2::jsonb FROM content_book_input_catalogs WHERE revision_id=$1`, manifest.RevisionID, string(payload)).Scan(&payloadMatches); err != nil {
		t.Fatal(err)
	}
	if !manifestMatches || !payloadMatches {
		t.Fatal("historical Book fixture conflicts with stored content")
	}
	store := contentstore.Store{}
	activation, found, err := store.ReadActivation(ctx, databaseTransaction)
	if err != nil || !found {
		t.Fatalf("current activation unavailable: found %v err %v", found, err)
	}
	originalRevision := activation.RevisionID
	t.Cleanup(func() {
		restoreTransaction, restoreError := p.Begin(ctx, tx.Options{})
		if restoreError != nil {
			t.Fatal(restoreError)
		}
		defer restoreTransaction.Rollback(ctx)
		restoreActivation, active, restoreError := store.ReadActivation(ctx, restoreTransaction)
		if restoreError != nil || !active {
			t.Fatalf("activation unavailable during fixture cleanup: active %v err %v", active, restoreError)
		}
		restored, restoreError := store.ActivateCAS(ctx, restoreTransaction, originalRevision, time.Now().UTC(), "i7c2d-native-test-cleanup", restoreActivation)
		if restoreError != nil || !restored {
			t.Fatalf("restore original content activation: restored %v err %v", restored, restoreError)
		}
		if restoreError = restoreTransaction.Commit(ctx); restoreError != nil {
			t.Fatal(restoreError)
		}
	})
	activated, err := store.ActivateCAS(ctx, databaseTransaction, manifest.RevisionID, time.Now().UTC(), "i7c2d-native-test", activation)
	if err != nil || !activated {
		t.Fatalf("activate historical Book fixture: activated %v err %v", activated, err)
	}
	if err = databaseTransaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return manifest.RevisionID
}
