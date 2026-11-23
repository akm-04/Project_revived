package otastore

import (
	"context"
	"errors"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/foundation/tx"
)

type scriptedQueryer struct {
	answers []string
	queries []string
	index   int
}

func (queryer *scriptedQueryer) QueryRow(_ context.Context, sql string, _ ...any) tx.Row {
	queryer.queries = append(queryer.queries, sql)
	answer := ""
	if queryer.index < len(queryer.answers) {
		answer = queryer.answers[queryer.index]
	}
	queryer.index++
	return scriptedRow{value: answer}
}

type scriptedRow struct {
	value string
}

func (row scriptedRow) Scan(dest ...any) error {
	if len(dest) != 1 {
		return errors.New("unexpected scan shape")
	}
	target, ok := dest[0].(*string)
	if !ok {
		return errors.New("unexpected scan target")
	}
	*target = row.value
	return nil
}

func TestExportStateReadsEveryLifecycleColumn(t *testing.T) {
	releases := `[{"id":2,"version":"1.631.2","lane":"code","state":"REPLACED",
		"package_files":[],"total_size":1,"md5":"22222222222222222222222222222222",
		"sha256":"1111111111111111111111111111111111111111111111111111111111111111","manifest":{},
		"built_at":"2026-01-01T00:00:00Z","published_at":"2026-01-02T00:00:00Z",
		"superseded_at":"2026-01-03T00:00:00Z","withdrawn_at":"2026-01-04T00:00:00Z",
		"replaced_at":"2026-01-05T00:00:00Z","replaced_by":5}]`
	activations := `[{"id":7,"release_id":2,"version":"1.631.2","action":"PUBLISH","command_key":"key","at":"2026-01-06T00:00:00Z"}]`
	queryer := &scriptedQueryer{answers: []string{releases, activations}}
	document, err := (Store{}).ExportStateTx(context.Background(), queryer)
	if err != nil {
		t.Fatal(err)
	}
	if len(document.Releases) != 1 || len(document.Activations) != 1 {
		t.Fatalf("document = %+v", document)
	}
	release := document.Releases[0]
	if release.ReplacedAt == nil || release.ReplacedBy == nil || *release.ReplacedBy != 5 {
		t.Fatalf("replaced trail = %+v", release)
	}
	if release.SupersededAt == nil || release.WithdrawnAt == nil || release.PublishedAt == nil {
		t.Fatalf("lifecycle timestamps = %+v", release)
	}
	if document.Activations[0].ReleaseID != 2 || document.Activations[0].CommandKey != "key" {
		t.Fatalf("activation = %+v", document.Activations[0])
	}
	for _, column := range []string{"superseded_at", "withdrawn_at", "replaced_at", "replaced_by"} {
		if !strings.Contains(queryer.queries[0], column) {
			t.Fatalf("export query omits %s: %s", column, queryer.queries[0])
		}
	}
}

func TestReadLedgerDecodesTheCounters(t *testing.T) {
	served := `[{"path":"src_64/a.lua","hits":4}]`
	misses := `[{"path":"src_64/b.lua","md5":"","first_seen":"2026-01-01T00:00:00Z","last_seen":"2026-01-02T00:00:00Z","hits":2,"first_uid":null}]`
	queryer := &scriptedQueryer{answers: []string{served, misses}}
	status, err := (Store{}).ReadLedgerTx(context.Background(), queryer, 51, 51)
	if err != nil {
		t.Fatal(err)
	}
	if len(status.Served) != 1 || status.Served[0].Path != "src_64/a.lua" || status.Served[0].Hits != 4 {
		t.Fatalf("served = %+v", status.Served)
	}
	if len(status.Misses) != 1 || status.Misses[0].Path != "src_64/b.lua" || status.Misses[0].Hits != 2 {
		t.Fatalf("misses = %+v", status.Misses)
	}
	if !strings.Contains(queryer.queries[0], "ota_asset_served_daily") || !strings.Contains(queryer.queries[1], "ota_asset_misses") {
		t.Fatalf("ledger queries = %v", queryer.queries)
	}
	if _, err := (Store{}).ReadLedgerTx(context.Background(), nil, 51, 51); !errors.Is(err, errInvalid) {
		t.Fatalf("nil query err = %v", err)
	}
}
