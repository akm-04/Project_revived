package otastore

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/foundation/tx"
)

type fixedQueryer struct {
	raw   string
	limit any
}

func (query *fixedQueryer) QueryRow(_ context.Context, _ string, args ...any) tx.Row {
	if len(args) > 0 {
		query.limit = args[0]
	}
	return fixedRow{raw: query.raw}
}

type fixedRow struct{ raw string }

func (row fixedRow) Scan(dest ...any) error {
	target, ok := dest[0].(*string)
	if !ok {
		return errors.New("unexpected scan target")
	}
	*target = row.raw
	return nil
}

func activeRowsJSON(count int) string {
	rows := make([]string, count)
	for index := range rows {
		rows[index] = fmt.Sprintf(`{"version":"9.9.%d","lane":"catalog","state":"ACTIVE"}`, index)
	}
	return "[" + strings.Join(rows, ",") + "]"
}

func TestListActiveFailsClosedAboveTheBound(t *testing.T) {
	query := &fixedQueryer{raw: activeRowsJSON(maxActiveReleases + 1)}
	if _, err := (Store{}).ListActiveTx(context.Background(), query); err == nil {
		t.Fatal("17 ACTIVE rows were accepted")
	}
	if query.limit != maxActiveReleases+1 {
		t.Fatalf("limit=%v want %d", query.limit, maxActiveReleases+1)
	}
}

func TestListActiveAcceptsTheBound(t *testing.T) {
	query := &fixedQueryer{raw: activeRowsJSON(maxActiveReleases)}
	rows, err := (Store{}).ListActiveTx(context.Background(), query)
	if err != nil || len(rows) != maxActiveReleases {
		t.Fatalf("rows=%d err=%v", len(rows), err)
	}
}
