package characterstore

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterqueries"
	"gxb.local/backend/v2/internal/application/charactersavedpreset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type presetRowFunc func(...any) error

func (f presetRowFunc) Scan(dest ...any) error { return f(dest...) }

type presetTag int64

func (t presetTag) RowsAffected() int64 { return int64(t) }

type presetFakeTx struct {
	queryRows map[string]presetRowFunc
	execs     []struct {
		q    string
		args []any
	}
	casRows int64
}

func (f *presetFakeTx) QueryRow(_ context.Context, q string, _ ...any) tx.Row {
	if row, ok := f.queryRows[q]; ok {
		return row
	}
	return presetRowFunc(func(...any) error { return errors.New("unexpected query") })
}
func (f *presetFakeTx) Exec(_ context.Context, q string, args ...any) (tx.CommandTag, error) {
	f.execs = append(f.execs, struct {
		q    string
		args []any
	}{q: q, args: append([]any(nil), args...)})
	if q == characterqueries.SaveSavedPresetRootVersion {
		return presetTag(f.casRows), nil
	}
	return presetTag(1), nil
}
func (*presetFakeTx) Commit(context.Context) error   { return nil }
func (*presetFakeTx) Rollback(context.Context) error { return nil }

func aggregateReadRow() presetRowFunc {
	now := time.Unix(100, 0).UTC()
	raw := `[{"lane_ordinal":1,"name":"A","pet_id":4,"heroes":[{"hero_ordinal":1,"partner_id":2},{"hero_ordinal":2,"partner_id":9}]},{"lane_ordinal":2,"name":"","pet_id":null,"heroes":[{"hero_ordinal":1,"partner_id":3}]}]`
	return func(dest ...any) error {
		*(dest[0].(*int64)) = 7
		*(dest[1].(*int64)) = 2
		*(dest[2].(*time.Time)) = now
		*(dest[3].(*time.Time)) = now
		*(dest[4].(*string)) = raw
		return nil
	}
}

func rootLockRow() presetRowFunc {
	now := time.Unix(100, 0).UTC()
	return func(dest ...any) error {
		*(dest[0].(*int64)) = 7
		*(dest[1].(*int64)) = 2
		*(dest[2].(*time.Time)) = now
		*(dest[3].(*time.Time)) = now
		return nil
	}
}

func TestReadSavedPresetAggregatePreservesOrderAndTypedRefs(t *testing.T) {
	f := &presetFakeTx{queryRows: map[string]presetRowFunc{characterqueries.ReadSavedPresetAggregate: aggregateReadRow()}}
	agg, err := (Store{}).ReadSavedPresetAggregateTx(context.Background(), f, 7)
	if err != nil {
		t.Fatal(err)
	}
	if agg.Root.StateVersion != 2 || len(agg.Lanes) != 2 || agg.Lanes[0].Heroes[1].PartnerID != 9 || agg.Lanes[1].Pet != nil {
		t.Fatalf("aggregate=%+v", agg)
	}
	if agg.Lanes[0].Pet == nil || agg.Lanes[0].Pet.PlayerID != 7 || agg.Lanes[0].Pet.PetID != 4 {
		t.Fatalf("pet ref=%+v", agg.Lanes[0].Pet)
	}
}

func TestReplaceSavedPresetAggregateIsWholeOwnerCAS(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	pet := character.PetRef{PlayerID: 7, PetID: 4}
	agg := character.SavedPresetAggregate{Root: character.SavedPresetRoot{PlayerID: 7, StateVersion: 3, CreatedAt: now, UpdatedAt: now.Add(time.Second)}, Lanes: []character.SavedPresetLane{{Name: "A", Heroes: []character.HeroRef{{PlayerID: 7, PartnerID: 2}, {PlayerID: 7, PartnerID: 9}}, Pet: &pet}}}
	f := &presetFakeTx{casRows: 1}
	if err := (Store{}).ReplaceSavedPresetAggregateTx(context.Background(), f, agg, 2); err != nil {
		t.Fatal(err)
	}
	got := []string{}
	for _, x := range f.execs {
		got = append(got, x.q)
	}
	want := []string{characterqueries.DeleteSavedPresetLanes, characterqueries.InsertSavedPresetLane, characterqueries.InsertSavedPresetHero, characterqueries.InsertSavedPresetHero, characterqueries.SaveSavedPresetRootVersion}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("exec order=%v", got)
	}
	f = &presetFakeTx{casRows: 0}
	if err := (Store{}).ReplaceSavedPresetAggregateTx(context.Background(), f, agg, 2); !errors.Is(err, charactersavedpreset.ErrStaleVersion) {
		t.Fatalf("CAS err=%v", err)
	}
}

func TestLockSavedPresetRootReadsStableRoot(t *testing.T) {
	f := &presetFakeTx{queryRows: map[string]presetRowFunc{characterqueries.LockSavedPresetRoot: rootLockRow()}}
	r, err := (Store{}).LockSavedPresetRootTx(context.Background(), f, identity.PlayerID(7))
	if err != nil || r.PlayerID != 7 || r.StateVersion != 2 {
		t.Fatalf("root=%+v err=%v", r, err)
	}
}

type presetBootstrapTx struct{ rows int64 }

func (f presetBootstrapTx) QueryRow(context.Context, string, ...any) tx.Row {
	return presetRowFunc(func(...any) error { return errors.New("unexpected query") })
}
func (f presetBootstrapTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return presetTag(f.rows), nil
}
func (presetBootstrapTx) Commit(context.Context) error   { return nil }
func (presetBootstrapTx) Rollback(context.Context) error { return nil }

func TestSavedPresetBootstrapContributorRequiresFreshRootInsert(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	b := logicalserver.BootstrapContext{PlayerID: 7, Operation: operation.Context{StartedAt: now}}
	c := SavedPresetBootstrapContributor{}
	if !c.Required() || c.Name() != "ca5.saved-presets" {
		t.Fatalf("contributor identity required=%v name=%q", c.Required(), c.Name())
	}
	if err := c.PersistCharacterBootstrap(context.Background(), presetBootstrapTx{rows: 1}, b); err != nil {
		t.Fatal(err)
	}
	if err := c.PersistCharacterBootstrap(context.Background(), presetBootstrapTx{rows: 0}, b); err == nil {
		t.Fatal("duplicate/missing bootstrap root insert accepted")
	}
}

func boolPresetRow(v bool) presetRowFunc {
	return func(dest ...any) error {
		*(dest[0].(*bool)) = v
		return nil
	}
}

func TestSavedPresetReferenceExistenceQueries(t *testing.T) {
	f := &presetFakeTx{queryRows: map[string]presetRowFunc{
		characterqueries.SavedPresetReferencesHero: boolPresetRow(true),
		characterqueries.SavedPresetReferencesPet:  boolPresetRow(false),
	}}
	hero, err := (Store{}).SavedPresetReferencesHeroTx(context.Background(), f, identity.PlayerID(7), 2)
	if err != nil || !hero {
		t.Fatalf("hero=%v err=%v", hero, err)
	}
	pet, err := (Store{}).SavedPresetReferencesPetTx(context.Background(), f, identity.PlayerID(7), 4)
	if err != nil || pet {
		t.Fatalf("pet=%v err=%v", pet, err)
	}
}
