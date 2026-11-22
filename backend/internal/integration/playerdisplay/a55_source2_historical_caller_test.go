//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"encoding/json"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	bookapp "gxb.local/backend/v2/internal/application/bookskill"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Requires the legacy schema1 revision installed by the first phase, then the
// exact-source generated schema2 bundle installed as a second immutable
// revision. The caller stays pinned to the legacy revision.
func TestA55ReadMaterializesExtensionPin(t *testing.T) {
	p := pool(t)
	activateHistoricalBookInputs(t, p)
	a := actor(t, p)
	s := bookService(p, p)
	var legacy, source2 string
	if e := p.Raw().QueryRow(ctx, `SELECT revision_id FROM content_book_input_catalogs WHERE (payload->>'schema_version')::int=1 ORDER BY revision_id LIMIT 1`).Scan(&legacy); e != nil {
		t.Fatalf("legacy revision missing; run phase 1 first: %v", e)
	}
	if e := p.Raw().QueryRow(ctx, `SELECT revision_id FROM content_book_input_catalogs WHERE (payload->>'schema_version')::int=2 ORDER BY revision_id LIMIT 1`).Scan(&source2); e != nil {
		bundle, loadErr := registry.LoadBuiltinBundle()
		if loadErr != nil {
			t.Fatalf("source2 revision missing and bundle unreadable: %v %v", e, loadErr)
		}
		installer := registry.Service{Runner: tx.Runner{DB: p}, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}
		if _, installErr := installer.EnsureBuiltinInstalled(ctx, op(), bundle); installErr != nil {
			t.Fatalf("source2 revision missing and install failed: %v %v", e, installErr)
		}
		if e = p.Raw().QueryRow(ctx, `SELECT revision_id FROM content_book_input_catalogs WHERE (payload->>'schema_version')::int=2 ORDER BY revision_id LIMIT 1`).Scan(&source2); e != nil {
			t.Fatalf("source2 revision still missing after generation install: %v", e)
		}
	}
	content := contentstore.Store{Queryer: p}
	active, on, e := content.BookInputsActive(ctx)
	if e != nil || !on || active != legacy {
		t.Fatalf("active revision %q on=%t err=%v", active, on, e)
	}
	owner := bookstore.Store{}
	at := time.Now().UTC()
	transaction, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	if e = owner.EnsureRootTx(ctx, transaction, a.PlayerID, legacy, at.Add(-time.Hour)); e != nil {
		t.Fatal(e)
	}
	if e = transaction.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	transaction, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	root, e := owner.LockRootTx(ctx, transaction, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	root.Facts.Buildings[2] = book.Building{Level: 1, CatalogRevision: source2, Job: &book.Job{Occurrence: "a55-read", Revision: source2, StartedAt: at.Add(-time.Minute), Duration: 1, Target: 2, Subject: 2, Cost: book.EmptyCost()}}
	old := root.Version
	root.Version++
	root.UpdatedAt = at.Add(-time.Second)
	if e = owner.SaveRootTx(ctx, transaction, root, old); e != nil {
		t.Fatal(e)
	}
	if e = transaction.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	before, e := owner.ReadRootTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	body, e := s.Read(ctx, a, 1056, op())
	if e != nil {
		t.Fatalf("materializing read: %v", e)
	}
	buildings, ok := body["building_list"].(map[string]any)
	if !ok {
		t.Fatal("1056 body missing building_list")
	}
	row, ok := buildings["2"].(map[string]any)
	if !ok {
		t.Fatal("1056 body missing building 2")
	}
	if level, ok := row["lev"].(int64); !ok || level != 2 {
		t.Fatalf("materialized workbench wire = %+v", row)
	}
	after, e := owner.ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || after.Version != before.Version+1 || after.Revision != legacy || after.Facts.Buildings[2].Level != 2 || after.Facts.Buildings[2].CatalogRevision != source2 || after.Facts.Buildings[2].Job != nil {
		t.Fatalf("materialization did not retain provenance: version %d creation %q building %+v err %v", after.Version, after.Revision, after.Facts.Buildings[2], e)
	}
	inputs, e := s.BookInputsTx(ctx, p, bookapp.InputScope{Player: a.PlayerID, ContentRevision: legacy, ObservedAt: time.Now().UTC()})
	if e != nil || inputs.ContentRevision != legacy || inputs.Applied.Buildings[2].Level != 2 {
		t.Fatalf("pure read after materialization: %v %+v", e, inputs.Applied.Buildings[2])
	}
	again, e := owner.ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || again.Version != after.Version {
		t.Fatalf("pure read wrote version %d -> %d err %v", after.Version, again.Version, e)
	}
}

func TestA55Source2HistoricalCallerPins(t *testing.T) {
	p := pool(t)
	activateHistoricalBookInputs(t, p)
	var legacy string
	if e := p.Raw().QueryRow(ctx, `SELECT revision_id FROM content_book_input_catalogs WHERE (payload->>'schema_version')::int=1 ORDER BY revision_id LIMIT 1`).Scan(&legacy); e != nil {
		t.Fatalf("legacy schema1 revision missing; run phase 1 first: %v", e)
	}
	bundle, e := registry.LoadBuiltinBundle()
	if e != nil {
		t.Fatal(e)
	}
	decoder := json.NewDecoder(bytes.NewReader(bundle.BookInputsJSON()))
	decoder.DisallowUnknownFields()
	var dto builtin.BookInputCatalog
	if e = decoder.Decode(&dto); e != nil {
		t.Fatal(e)
	}
	if dto.SchemaVersion != 2 || len(dto.Buildings) != 135 {
		t.Fatalf("build did not carry the exact source2 bundle: schema %d buildings %d", dto.SchemaVersion, len(dto.Buildings))
	}
	source2 := bundle.RevisionID()
	if source2 == legacy || len(source2) != 64 {
		t.Fatalf("source2 revision %q conflicts with legacy %q", source2, legacy)
	}
	service := registry.Service{Runner: tx.Runner{DB: p}, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}
	if _, e = service.EnsureBuiltinInstalled(ctx, op(), bundle); e != nil {
		t.Fatalf("source2 install: %v", e)
	}
	content := contentstore.Store{Queryer: p}
	active, on, e := content.BookInputsActive(ctx)
	if e != nil || !on || active != legacy {
		t.Fatalf("active revision changed: %q on=%t err=%v", active, on, e)
	}
	callerCatalog, e := content.BookCatalogTx(ctx, p, legacy)
	if e != nil || len(callerCatalog.Buildings) != 112 {
		t.Fatalf("legacy catalog: %d %v", len(callerCatalog.Buildings), e)
	}
	pinnedCatalog, e := content.BookCatalogTx(ctx, p, source2)
	if e != nil || len(pinnedCatalog.Buildings) != 135 {
		t.Fatalf("source2 catalog: %d %v", len(pinnedCatalog.Buildings), e)
	}
	for _, level := range []int64{1, 2} {
		if _, ok := pinnedCatalog.Buildings[[2]int64{2, level}]; !ok {
			t.Fatalf("source2 catalog lacks workbench level %d", level)
		}
	}

	player := actor(t, p)
	owner := bookstore.Store{}
	at := time.Now().UTC().Add(-time.Hour)
	transaction, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	if e = owner.EnsureRootTx(ctx, transaction, player.PlayerID, legacy, at); e != nil {
		t.Fatal(e)
	}
	if e = transaction.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	transaction, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	root, e := owner.LockRootTx(ctx, transaction, player.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	root.Facts.Buildings[2] = book.Building{Level: 1, CatalogRevision: source2, Job: &book.Job{Occurrence: "a55", Revision: legacy, StartedAt: at, Duration: 1, Target: 2, Subject: 2, Cost: book.EmptyCost()}}
	root.Version++
	root.UpdatedAt = at.Add(time.Second)
	if e = owner.SaveRootTx(ctx, transaction, root, 1); e != nil {
		t.Fatal(e)
	}
	if e = transaction.Commit(ctx); e != nil {
		t.Fatal(e)
	}

	application := bookapp.Service{Owner: owner, Content: content}
	scope := bookapp.InputScope{Player: player.PlayerID, ContentRevision: legacy, ObservedAt: at.Add(2 * time.Second)}
	if _, e = application.BookInputsTx(ctx, p, scope); e == nil {
		t.Fatal("pending job qualified from a legacy pin that lacks its target rule")
	}

	transaction, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	root, e = owner.LockRootTx(ctx, transaction, player.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	root.Facts.Buildings[2].Job.Revision = source2
	root.Version++
	root.UpdatedAt = at.Add(time.Second)
	if e = owner.SaveRootTx(ctx, transaction, root, 2); e != nil {
		t.Fatal(e)
	}
	if e = transaction.Commit(ctx); e != nil {
		t.Fatal(e)
	}

	inputs, e := application.BookInputsTx(ctx, p, scope)
	if e != nil {
		t.Fatalf("historical caller read: %v", e)
	}
	if inputs.ContentRevision != legacy || !reflect.DeepEqual(inputs.Catalog.Buildings, callerCatalog.Buildings) || len(inputs.Catalog.Buildings) != 112 {
		t.Fatal("caller catalog or revision changed")
	}
	if inputs.Applied.Buildings[2].Level != 2 || inputs.Applied.Buildings[2].CatalogRevision != source2 || inputs.Applied.Buildings[2].Job != nil {
		t.Fatalf("settled provenance: %+v", inputs.Applied.Buildings[2])
	}
	stored, e := owner.ReadRootTx(ctx, p, player.PlayerID)
	if e != nil || stored.Version != 3 || stored.Revision != legacy || stored.Facts.Buildings[2].Level != 1 {
		t.Fatalf("pure port wrote: version %d creation %q level %d err %v", stored.Version, stored.Revision, stored.Facts.Buildings[2].Level, e)
	}
}
