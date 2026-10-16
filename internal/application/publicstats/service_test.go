package publicstats

import (
	"context"
	"encoding/json"
	"errors"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/character"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	n "gxb.local/backend/v2/internal/domain/statinputs"
	rules "gxb.local/backend/v2/internal/domain/statrules"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"testing"
	"time"
)

type noWrite struct{}

func (noWrite) QueryRow(context.Context, string, ...any) tx.Row             { panic("unexpected database access") }
func (noWrite) Exec(context.Context, string, ...any) (tx.CommandTag, error) { panic("read wrote") }
func (noWrite) Commit(context.Context) error                                { return nil }
func (noWrite) Rollback(context.Context) error                              { return nil }

type contentFixture struct{ c *builtin.Catalog }

func (f contentFixture) StatCatalogTx(_ context.Context, _ tx.Queryer, r string) (rules.Catalog, error) {
	if r != f.c.RevisionID() {
		return rules.Catalog{}, ErrUnqualified
	}
	raw, _ := json.Marshal(f.c.StatRules)
	var v rules.Catalog
	json.Unmarshal(raw, &v)
	return v, nil
}
func (f contentFixture) StatInputCatalogTx(_ context.Context, _ tx.Queryer, r string) (n.Catalog, error) {
	if r != f.c.RevisionID() {
		return n.Catalog{}, ErrUnqualified
	}
	return n.NewCatalog(f.c.StatInputs.SchemaVersion, f.c.StatInputs.PolicyID, f.c.StatInputs.Tables)
}
func (contentFixture) DormCatalogTx(context.Context, tx.Queryer, string) (dorm.Catalog, error) {
	panic("Pet must not query Dorm")
}

type ownedFixture struct{ o ca.OwnedPetComposite }

func (f ownedFixture) OwnedPetTx(context.Context, ca.CoherentReadScope, character.PetRef) (ca.OwnedPetComposite, error) {
	return f.o, nil
}
func (ownedFixture) OwnedHeroTx(context.Context, ca.CoherentReadScope, character.HeroRef) (ca.OwnedHeroComposite, error) {
	panic("unexpected Hero dependency")
}

type petFixture struct{ p character.Pet }

func (f petFixture) ReadPetByIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, error) {
	return f.p, nil
}
func fixture(t *testing.T) (Service, ca.CoherentReadScope, character.PetRef) {
	t.Helper()
	c, e := builtin.Load()
	if e != nil {
		t.Fatal(e)
	}
	at := time.Unix(100, 0).UTC()
	ref := character.PetRef{PlayerID: 1, PetID: 1}
	p := character.Pet{PlayerID: 1, PetID: 1, TableID: 10010001, OriginTableID: 10010001, Star: 1, Level: 1, Color: 1, Skills: character.DefaultPetSkillLevels(), CreationContentRevision: c.RevisionID(), StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	base := ca.PetBaseObservation{Ref: ref, TableID: p.TableID, OriginTableID: p.OriginTableID, Star: 1, Level: 1, Color: 1, Skills: p.Skills, CreationContentRevision: c.RevisionID(), StateVersion: 1}
	o := ca.OwnedPetComposite{Origin: ca.ActorOriginOwned, Base: base, Equipment: ca.ProviderObservation[ca.RawEquipmentState]{Disposition: ca.ProviderQualifiedActive, Value: ca.RawEquipmentState{Family: "PET", OwnerID: 1, StateVersion: 1, Slots: []ca.RawEquipmentSlot{}}}, Practice: ca.ProviderObservation[ca.PracticeContribution]{Disposition: ca.ProviderQualifiedActive, Value: ca.PracticeContribution{Family: ca.PracticeFamilyPet, OwnerID: 1, TableID: p.TableID, StateVersion: 1, ContentRevision: c.RevisionID(), Reducer: ca.PracticeReducerPetSourceOverwrite, Applied: character.PracticeAttrs{2, 3, 4}, Contributions: []ca.PracticeContributionEntry{{AttrType: 1, Value: 2}, {AttrType: 2, Value: 3}, {AttrType: 3, Value: 4}, {AttrType: 5, Value: 7}}}}, Appearance: ca.ProviderObservation[ca.PetAppearanceContribution]{Disposition: ca.ProviderQualifiedActive, Value: ca.PetAppearanceContribution{OwnerID: 1, TableID: p.TableID, OriginTableID: p.OriginTableID, ContentRevision: c.RevisionID(), Appearance: ca.EffectivePetAppearance{OwnerStateVersion: 1, ObservedAt: at}}}}
	ps, _ := policy.NewSet(policy.Ref{Name: "content", Version: c.RevisionID()})
	op := operation.Context{ID: ids.UUID{1}, StartedAt: at, Policies: ps}
	scope, e := ca.NewCoherentReadScope(tx.Scope{Tx: noWrite{}, Operation: op, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}}, c.RevisionID(), at)
	if e != nil {
		t.Fatal(e)
	}
	return Service{Owned: ownedFixture{o: o}, Pets: petFixture{p: p}, Content: contentFixture{c: c}}, scope, ref
}
func TestPetIndependentCanonicalFacetsAndDetachedResult(t *testing.T) {
	s, sc, ref := fixture(t)
	v, e := s.PetTx(context.Background(), sc, ref, View{Kind: Self, Viewer: 1})
	if e != nil {
		t.Fatal(e)
	}
	v.Stats.Total[0] = -1
	again, e := s.PetTx(context.Background(), sc, ref, View{Kind: Self, Viewer: 1})
	if e != nil || again.Stats.Total[0] < 0 {
		t.Fatal("mutable result", e)
	}
	foreign, e := s.PetTx(context.Background(), sc, ref, View{Kind: Foreign, Viewer: 2})
	if e != nil || !reflect.DeepEqual(again.Stats, foreign.Stats) {
		t.Fatal("Pet depended on Hero/viewer", e)
	}
}
func TestUnavailableStaleForeignAndReplayFailClosed(t *testing.T) {
	s, sc, ref := fixture(t)
	for _, change := range []func(*Service, *ca.CoherentReadScope, *View){
		func(s *Service, sc *ca.CoherentReadScope, v *View) { s.Content = nil },
		func(s *Service, sc *ca.CoherentReadScope, v *View) { s.Pets = nil },
		func(s *Service, sc *ca.CoherentReadScope, v *View) { sc.ContentRevision = "bad" },
		func(s *Service, sc *ca.CoherentReadScope, v *View) { v.Kind = "REPLAY" },
		func(s *Service, sc *ca.CoherentReadScope, v *View) { v.Viewer = 2 },
		func(s *Service, sc *ca.CoherentReadScope, v *View) {
			f := s.Owned.(ownedFixture)
			f.o.Practice.Disposition = ca.ProviderUnavailableUnqualified
			s.Owned = f
		},
		func(s *Service, sc *ca.CoherentReadScope, v *View) {
			f := s.Owned.(ownedFixture)
			f.o.Appearance.Value.ContentRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
			s.Owned = f
		},
		func(s *Service, sc *ca.CoherentReadScope, v *View) {
			f := s.Pets.(petFixture)
			f.p.StateVersion++
			s.Pets = f
		},
		func(s *Service, sc *ca.CoherentReadScope, v *View) {
			f := s.Pets.(petFixture)
			f.p.UpdatedAt = sc.ObservedAt.Add(time.Second)
			s.Pets = f
		},
	} {
		ss, scope, view := s, sc, View{Kind: Self, Viewer: 1}
		change(&ss, &scope, &view)
		if _, e := ss.PetTx(context.Background(), scope, ref, view); e == nil {
			t.Fatal("unqualified accepted")
		}
	}
	if _, e := s.HeroTx(context.Background(), sc, character.HeroRef{PlayerID: 1, PartnerID: 1}, View{Kind: Self, Viewer: 1}); !errors.Is(e, ErrUnqualified) {
		t.Fatal("missing raw awakening was defaulted", e)
	}
}
func TestPracticeAppliedAndAwardAreBothPresent(t *testing.T) {
	a, w, e := practice(ca.PracticeContribution{Applied: character.PracticeAttrs{2, 3, 4}, Contributions: []ca.PracticeContributionEntry{{AttrType: 1, Value: 7}, {AttrType: 2, Value: 3}, {AttrType: 3, Value: 4}, {AttrType: 20, Value: 7}}})
	if e != nil || a[0] != 7 || a[1] != 3 || a[19] != 7 || w[0] != 5 || w[19] != 7 {
		t.Fatal(a, w, e)
	}
}
