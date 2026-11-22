package postgres

import (
	"context"
	"errors"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/foundation/tx"
)

type settingsRow struct{ values []int }

func (r settingsRow) Scan(dest ...any) error {
	if len(dest) != len(r.values) {
		return errors.New("bad scan destination")
	}
	for i, value := range r.values {
		*dest[i].(*int) = value
	}
	return nil
}

type settingsQueryer struct{ row settingsRow }

func (q settingsQueryer) QueryRow(context.Context, string, ...any) tx.Row { return q.row }

func TestSerializableLockShortfall(t *testing.T) {
	cases := []struct {
		name     string
		settings []int
		want     []string
	}{
		{"defaults", []int{64, -2, 2}, []string{
			"max_pred_locks_per_transaction=64 (want >= 1024)",
			"max_pred_locks_per_relation=32 (want >= 512)",
			"max_pred_locks_per_page=2 (want >= 8)"}},
		{"budget", []int{1024, 512, 8}, nil},
		{"negative relation resolves through the transaction value", []int{2048, -2, 8}, nil},
	}
	for _, c := range cases {
		got, err := SerializableLockShortfall(context.Background(), settingsQueryer{settingsRow{c.settings}})
		if err != nil || !reflect.DeepEqual(got, c.want) {
			t.Fatalf("%s: got %q, %v", c.name, got, err)
		}
	}
}
