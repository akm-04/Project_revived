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

type ca44Tag int64

func (t ca44Tag) RowsAffected() int64 { return int64(t) }

type ca44Tx struct {
	sql  string
	args []any
	n    int64
}

func (q *ca44Tx) QueryRow(context.Context, string, ...any) tx.Row { return ca44Row{} }
func (q *ca44Tx) Exec(_ context.Context, sql string, args ...any) (tx.CommandTag, error) {
	q.sql = sql
	q.args = args
	return ca44Tag(q.n), nil
}
func (*ca44Tx) Commit(context.Context) error   { return errors.New("unexpected commit") }
func (*ca44Tx) Rollback(context.Context) error { return errors.New("unexpected rollback") }

type ca44Row struct{}

func (ca44Row) Scan(...any) error { return errors.New("unexpected row") }

func ca44Pet() character.Pet {
	now := time.Unix(100, 0).UTC()
	return character.Pet{PlayerID: identity.PlayerID(7), PetID: 3, TableID: 10030001, OriginTableID: 10030001, Star: 2, Level: 9, Exp: 123, Color: 5,
		Equipment: character.PetEquipmentSlots{1, 0, 1}, Fumo: character.PetFumoSlots{11, 22, 33}, Skills: character.DefaultPetSkillLevels(), Birthday: 1700000000, IsShow: true,
		CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 4, CreatedAt: now, UpdatedAt: now}
}

func TestSavePetStateTxCohesiveCAS(t *testing.T) {
	p := ca44Pet()
	old := p.StateVersion
	p.StateVersion++
	p.Level = 10
	p.Exp = 150
	p.Color = 6
	p.Equipment[1] = 1
	p.Fumo = character.PetFumoSlots{44, 55, 66}
	p.UpdatedAt = p.UpdatedAt.Add(time.Second)
	q := &ca44Tx{n: 1}
	if err := (Store{}).SavePetStateTx(context.Background(), q, p, old); err != nil {
		t.Fatal(err)
	}
	want := []any{int64(p.PlayerID), p.PetID, p.Star, p.Level, p.Exp, p.Color, p.Skills[0], p.Skills[1], p.Skills[2], p.Skills[3], p.Skills[4], p.Equipment[0], p.Equipment[1], p.Equipment[2], p.Fumo[0], p.Fumo[1], p.Fumo[2], p.UpdatedAt.UTC(), old}
	if q.sql != characterqueries.SavePetState || !reflect.DeepEqual(q.args, want) {
		t.Fatalf("sql/args mismatch sql=%q args=%#v", q.sql, q.args)
	}
}

func TestSavePetStateTxRejectsLostCAS(t *testing.T) {
	p := ca44Pet()
	old := p.StateVersion
	p.StateVersion++
	if err := (Store{}).SavePetStateTx(context.Background(), &ca44Tx{n: 0}, p, old); err == nil {
		t.Fatal("lost CAS accepted")
	}
}

func TestSavePetProgressionCompatibilityWrapperPreservesEquipment(t *testing.T) {
	p := ca44Pet()
	old := p.StateVersion
	p.StateVersion++
	p.Level = 10
	q := &ca44Tx{n: 1}
	if err := (Store{}).SavePetProgressionTx(context.Background(), q, p, old); err != nil {
		t.Fatal(err)
	}
	if q.sql != characterqueries.SavePetState || q.args[5] != p.Color || q.args[11] != int64(1) || q.args[12] != int64(0) || q.args[13] != int64(1) || q.args[14] != int64(11) || q.args[15] != int64(22) || q.args[16] != int64(33) {
		t.Fatalf("progression wrapper did not use cohesive Pet state CAS: %#v", q.args)
	}
}
