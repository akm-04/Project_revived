package i4store

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/foundation/tx"
)

type discoveryTestRow struct{ scan func(...any) error }

func (r discoveryTestRow) Scan(dest ...any) error { return r.scan(dest...) }

type discoveryTestQueryer struct {
	query string
	args  []any
	rows  any
	min   int64
	max   int64
}

func (q *discoveryTestQueryer) QueryRow(_ context.Context, query string, args ...any) tx.Row {
	q.query, q.args = query, args
	return discoveryTestRow{scan: func(dest ...any) error {
		if query == playerIDBoundsSQL {
			*(dest[0].(*int64)), *(dest[1].(*int64)) = q.min, q.max
			return nil
		}
		b, err := json.Marshal(q.rows)
		if err != nil {
			return err
		}
		*(dest[0].(*string)) = string(b)
		return nil
	}}
}

type discoveryFixture struct {
	PlayerID      int64  `json:"player_id"`
	Name          string `json:"name"`
	Level         int64  `json:"lev"`
	AvatarID      int64  `json:"avatar_id"`
	AvatarFrameID int64  `json:"avatar_frame_id"`
	ConquerLevel  int64  `json:"conquer_lev"`
	ConquerLoopID int64  `json:"conquer_loop_id"`
}

func TestDiscoveryExactNameIsOwnerLocalExactAndOrdered(t *testing.T) {
	q := &discoveryTestQueryer{rows: []discoveryFixture{
		{100001, "123456", 1, 110001001, 0, 0, 1}, {200001, "123456", 2, 110001001, 0, 0, 1},
	}}
	r := PlayerDirectoryReader{Queryer: q}
	got, err := r.ProfilesByExactName(context.Background(), "123456", 101)
	if err != nil || len(got) != 2 || got[0].PlayerID != 100001 || got[1].PlayerID != 200001 {
		t.Fatalf("got=%+v err=%v", got, err)
	}
	if !strings.Contains(q.query, `name COLLATE "C" = $1 COLLATE "C"`) || len(q.args) != 2 || q.args[0] != "123456" || q.args[1] != 101 {
		t.Fatalf("query=%q args=%v", q.query, q.args)
	}
}

func TestDiscoveryBoundsAndPaging(t *testing.T) {
	q := &discoveryTestQueryer{min: 100001, max: 300009, rows: []discoveryFixture{{200001, "B", 1, 110001001, 0, 0, 1}}}
	r := PlayerDirectoryReader{Queryer: q}
	min, max, ok, err := r.PlayerIDBounds(context.Background())
	if err != nil || !ok || min != 100001 || max != 300009 {
		t.Fatalf("bounds %d %d %v %v", min, max, ok, err)
	}
	got, err := r.ProfilesAfter(context.Background(), 100001, 64)
	if err != nil || len(got) != 1 || got[0].PlayerID != 200001 {
		t.Fatalf("got=%+v err=%v", got, err)
	}
	if len(q.args) != 2 || q.args[0] != int64(100001) || q.args[1] != 64 {
		t.Fatalf("args=%v", q.args)
	}
}

func TestDiscoveryRejectsUnsafeBoundsAndMalformedRows(t *testing.T) {
	r := PlayerDirectoryReader{Queryer: &discoveryTestQueryer{rows: []discoveryFixture{}}}
	if _, err := r.ProfilesAfter(context.Background(), -1, 1); err == nil {
		t.Fatal("negative cursor accepted")
	}
	if _, err := r.ProfilesByExactName(context.Background(), "x", MaxDirectoryDiscoveryRead+1); err == nil {
		t.Fatal("oversized read accepted")
	}
	q := &discoveryTestQueryer{rows: []discoveryFixture{{200001, "B", 1, 110001001, 0, 0, 1}, {100001, "A", 1, 110001001, 0, 0, 1}}}
	_, err := (PlayerDirectoryReader{Queryer: q}).ProfilesByExactName(context.Background(), "x", 2)
	if err == nil {
		t.Fatal("unordered result accepted")
	}
	if !errors.Is(err, err) { /* keep compiler honest without binding error text */
	}
}
