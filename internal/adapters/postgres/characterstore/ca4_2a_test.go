package characterstore

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterqueries"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ca42Tag int64

func (t ca42Tag) RowsAffected() int64 { return int64(t) }

type ca42Tx struct {
	sql  string
	args []any
	n    int64
}

func (q *ca42Tx) QueryRow(context.Context, string, ...any) tx.Row { return ca42Row{} }
func (q *ca42Tx) Exec(_ context.Context, sql string, args ...any) (tx.CommandTag, error) {
	q.sql = sql
	q.args = args
	return ca42Tag(q.n), nil
}
func (q *ca42Tx) Commit(context.Context) error   { return errors.New("unexpected commit") }
func (q *ca42Tx) Rollback(context.Context) error { return errors.New("unexpected rollback") }

type ca42Row struct{}

func (ca42Row) Scan(...any) error { return errors.New("unexpected row") }

func ca42Hero() character.Hero {
	now := time.Unix(100, 0).UTC()
	return character.Hero{RawSkills: character.NewHeroRawSkillSeed(), PlayerID: identity.PlayerID(1), PartnerID: 7, TableID: 11001, OriginTableID: 11001, Star: 3, Level: 20, Exp: 500, Color: 5,
		Equipment: character.HeroEquipmentSlots{1, 0, 1, 0, 1, 0}, CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 4, CreatedAt: now, UpdatedAt: now}
}

func TestSaveHeroStateTxCohesiveCAS(t *testing.T) {
	h := ca42Hero()
	old := h.StateVersion
	h.StateVersion++
	h.Level = 21
	h.Exp = 525
	h.Color = 6
	h.Equipment[1] = 1
	h.Fumo = character.HeroFumoSlots{10, 20, 30, 40, 50, 60}
	h.UpdatedAt = h.UpdatedAt.Add(time.Second)
	q := &ca42Tx{n: 1}
	if err := (Store{}).SaveHeroStateTx(context.Background(), q, h, old); err != nil {
		t.Fatal(err)
	}
	want := []any{int64(h.PlayerID), h.PartnerID, h.Star, h.Level, h.Exp, h.Color, h.Equipment[0], h.Equipment[1], h.Equipment[2], h.Equipment[3], h.Equipment[4], h.Equipment[5], h.Fumo[0], h.Fumo[1], h.Fumo[2], h.Fumo[3], h.Fumo[4], h.Fumo[5], h.UpdatedAt.UTC(), old}
	if q.sql != characterqueries.SaveHeroState || !reflect.DeepEqual(q.args, want) {
		t.Fatalf("sql/args mismatch sql=%q args=%#v", q.sql, q.args)
	}
}

func TestSaveHeroStateTxRejectsLostCAS(t *testing.T) {
	h := ca42Hero()
	old := h.StateVersion
	h.StateVersion++
	q := &ca42Tx{n: 0}
	if err := (Store{}).SaveHeroStateTx(context.Background(), q, h, old); err == nil {
		t.Fatal("lost CAS accepted")
	}
}
