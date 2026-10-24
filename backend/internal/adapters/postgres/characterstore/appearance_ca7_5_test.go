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

type ca75StoreTx struct {
	execs   []ca73Exec
	casRows int64
}

func (*ca75StoreTx) QueryRow(context.Context, string, ...any) tx.Row { return ca42Row{} }
func (q *ca75StoreTx) Exec(_ context.Context, sql string, args ...any) (tx.CommandTag, error) {
	q.execs = append(q.execs, ca73Exec{sql: sql, args: append([]any(nil), args...)})
	if sql == characterqueries.SavePetActiveStyle {
		return ca42Tag(q.casRows), nil
	}
	return ca42Tag(1), nil
}
func (*ca75StoreTx) Commit(context.Context) error   { return errors.New("unexpected commit") }
func (*ca75StoreTx) Rollback(context.Context) error { return errors.New("unexpected rollback") }

func ca75StorePet() character.Pet {
	now := time.Unix(100, 0).UTC()
	return character.Pet{
		PlayerID: identity.PlayerID(1), PetID: 7, TableID: 10030001, OriginTableID: 10030001,
		Star: 1, Level: 1, Color: 1, Skills: character.DefaultPetSkillLevels(), IsShow: true,
		CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		StateVersion:            5, CreatedAt: now, UpdatedAt: now,
	}
}

func TestCA75SavePetAppearanceMutationTxEntitlementAndSelectorShareOneOwnerCAS(t *testing.T) {
	p := ca75StorePet()
	old := p.StateVersion
	p.StateVersion++
	p.ActiveStyle = 0
	p.UpdatedAt = p.UpdatedAt.Add(time.Second)
	ent := character.PetStyleEntitlement{PlayerID: p.PlayerID, PetID: p.PetID, StyleItemID: 50001376}
	q := &ca75StoreTx{casRows: 1}
	if err := (Store{}).SavePetAppearanceMutationTx(context.Background(), q, p, &ent, old); err != nil {
		t.Fatal(err)
	}
	if len(q.execs) != 2 {
		t.Fatalf("execs=%#v", q.execs)
	}
	if q.execs[0].sql != characterqueries.InsertPetStyleEntitlement || !reflect.DeepEqual(q.execs[0].args, []any{int64(p.PlayerID), p.PetID, ent.StyleItemID}) {
		t.Fatalf("entitlement=%#v", q.execs[0])
	}
	wantCAS := []any{int64(p.PlayerID), p.PetID, p.ActiveStyle, p.UpdatedAt.UTC(), old}
	if q.execs[1].sql != characterqueries.SavePetActiveStyle || !reflect.DeepEqual(q.execs[1].args, wantCAS) {
		t.Fatalf("owner CAS=%#v", q.execs[1])
	}
}

func TestCA75SavePetAppearanceMutationTxNormalizationOnlyUsesExactlyOneCAS(t *testing.T) {
	p := ca75StorePet()
	old := p.StateVersion
	p.StateVersion++
	p.UpdatedAt = p.UpdatedAt.Add(time.Second)
	q := &ca75StoreTx{casRows: 1}
	if err := (Store{}).SavePetAppearanceMutationTx(context.Background(), q, p, nil, old); err != nil {
		t.Fatal(err)
	}
	if len(q.execs) != 1 || q.execs[0].sql != characterqueries.SavePetActiveStyle {
		t.Fatalf("execs=%#v", q.execs)
	}
}

func TestCA75SavePetAppearanceMutationTxLostCASFailsAfterChildWrite(t *testing.T) {
	p := ca75StorePet()
	old := p.StateVersion
	p.StateVersion++
	p.UpdatedAt = p.UpdatedAt.Add(time.Second)
	ent := character.PetStyleEntitlement{PlayerID: p.PlayerID, PetID: p.PetID, StyleItemID: 50001376}
	q := &ca75StoreTx{casRows: 0}
	if err := (Store{}).SavePetAppearanceMutationTx(context.Background(), q, p, &ent, old); err == nil {
		t.Fatal("lost Pet CAS accepted")
	}
	if len(q.execs) != 2 || q.execs[0].sql != characterqueries.InsertPetStyleEntitlement || q.execs[1].sql != characterqueries.SavePetActiveStyle {
		t.Fatalf("execs=%#v", q.execs)
	}
}

func TestCA75SavePetActiveStyleTxUsesOwnerCASOnly(t *testing.T) {
	p := ca75StorePet()
	old := p.StateVersion
	p.StateVersion++
	p.ActiveStyle = 50001376
	p.UpdatedAt = p.UpdatedAt.Add(time.Second)
	q := &ca75StoreTx{casRows: 1}
	if err := (Store{}).SavePetActiveStyleTx(context.Background(), q, p, old); err != nil {
		t.Fatal(err)
	}
	if len(q.execs) != 1 || q.execs[0].sql != characterqueries.SavePetActiveStyle {
		t.Fatalf("execs=%#v", q.execs)
	}
}
