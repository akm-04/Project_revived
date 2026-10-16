//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/statrules"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strings"
	"testing"
)

func TestI7C3ANativePinnedCatalogAndPayloadIntegrity(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	s := contentstore.Store{Queryer: p}
	c, err := s.StatCatalogTx(ctx, tr, rev)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = statrules.NewEngine(rev, c); err != nil {
		t.Fatal(err)
	}
	if _, err = s.StatCatalogTx(ctx, tr, strings.Repeat("0", 64)); err == nil {
		t.Fatal("unknownrevision")
	}
	if _, err = tr.Exec(ctx, `UPDATE content_stat_rule_catalogs SET payload=jsonb_set(payload,'{policy_id}','"tampered"') WHERE revision_id=$1`, rev); err != nil {
		t.Fatal(err)
	}
	if _, err = s.StatCatalogTx(ctx, tr, rev); err == nil {
		t.Fatal("payloadhashnotchecked")
	}
	if err = tr.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	if _, err = s.StatCatalogTx(ctx, p, rev); err != nil {
		t.Fatal("rollbackchangedcatalog", err)
	}
}
func TestI7C3ANativeContentMatchesFrozenNumericRules(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	s := contentstore.Store{Queryer: p}
	c, err := s.StatCatalogTx(ctx, p, rev)
	if err != nil {
		t.Fatal(err)
	}
	b, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	native, _ := json.Marshal(c)
	compiled, _ := json.Marshal(b.StatRules)
	if string(native) != string(compiled) {
		t.Fatal("deployment altered numerical payload")
	}
	active, ok, err := s.StatRulesActive(ctx)
	if err != nil || !ok || active != rev {
		t.Fatal("activation capability", active, ok, err)
	}
}
