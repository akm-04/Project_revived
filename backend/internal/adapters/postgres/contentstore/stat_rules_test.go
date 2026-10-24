package contentstore

import (
	"bytes"
	"context"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/statrules"
)

// The integration test cannot observe this check: StatCatalogTx memoizes the
// first successful load of an immutable revision (I7C-5C), so a later in-process
// tamper is never re-read.
func TestStatCatalogRejectsTamperedPayload(t *testing.T) {
	b, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	load := func(payload []byte) error {
		q := &recording{bySQL: map[string][]any{
			`SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`:     {string(b.ManifestJSON())},
			`SELECT payload::text FROM content_stat_rule_catalogs WHERE revision_id=$1`: {string(payload)},
		}}
		_, err := Store{}.statCatalogTx(context.Background(), q, b.RevisionID())
		return err
	}
	if err := load(b.StatRulesJSON()); err != nil {
		t.Fatal("genuine payload", err)
	}
	tampered := bytes.Replace(b.StatRulesJSON(), []byte(`"policy_id":"`), []byte(`"policy_id":"tampered`), 1)
	if bytes.Equal(tampered, b.StatRulesJSON()) {
		t.Fatal("tamper did not apply")
	}
	if err := load(tampered); !errors.Is(err, statrules.ErrUnqualified) {
		t.Fatal("payload hash unchecked", err)
	}
}
