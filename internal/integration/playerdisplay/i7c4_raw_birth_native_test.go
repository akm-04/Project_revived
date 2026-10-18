//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"reflect"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
)

func rawBirthReader() hero.RawAwakeningObservationReader {
	return hero.RawAwakeningObservationReader{Heroes: characterstore.Store{}, Births: characterstore.RawAwakeningStore{}}
}

// The historical stat helper contains conditional command-only eligibility
// profiles. Replace those with actual production profiles for this read proof.
func rawBirthStats(p *pg.Pool) publicstats.Service {
	s := statService(p)
	s.Awakening = rawBirthReader()
	inscriptions := inscriptionService(p, p)
	inscriptions.Eligibility = characterstore.InscriptionHeroPort{Store: characterstore.Store{Queryer: p}}
	s.Inscription = inscriptions
	elements := elementService(p, p)
	elements.MaxHeroColor = i5.PreservationMaxHeroColorProvider{}
	s.Element = elements
	courses := courseService(p, p)
	courses.Privileges = commerceprivilege.Provider{Store: commerceprivilegestore.Store{}, Content: contentstore.Store{Queryer: p}}
	s.Courses = courses
	return s
}
func rawBirthService(p *pg.Pool) hero.Service {
	s := collectionService(p)
	s.FreshFacets = characterstore.RawAwakeningStore{}
	return s
}
func rawCount(t *testing.T, p *pg.Pool, ref character.HeroRef) int64 {
	t.Helper()
	var n int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM player_hero_raw_awakening WHERE player_id=$1 AND partner_id=$2`, int64(ref.PlayerID), ref.PartnerID).Scan(&n); e != nil {
		t.Fatal(e)
	}
	return n
}
func TestI7C4RawBirthActualCreationAndStrictLegacyRead(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := rankingActor(t, p, rankingServer(t, p), true)
	def := collectionResources(t, p, a, rev, 10001001)
	s := rawBirthService(p)
	o := op()
	h, e := s.SummonNormal(ctx, a, def.Template.TableID, def.Template.FragmentItemID, def.FragmentCount, o)
	if e != nil {
		t.Fatal(e)
	}
	assertRead := func(wantVersion int64) {
		t.Helper()
		if e := statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
			got, e := rawBirthReader().RawAwakeningTx(ctx, sc, h.Ref())
			if e == nil && (!got.Known || got.RawStage != 0 || got.StateVersion != wantVersion || got.ProducerReference == "" || got.ContentRevision != rev || !got.ObservedAt.Equal(sc.ObservedAt)) {
				t.Fatal(got)
			}
			return e
		}); e != nil {
			t.Fatal(e)
		}
	}
	assertRead(1)
	if e = statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
		sc.ContentRevision = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
		_, e := rawBirthReader().RawAwakeningTx(ctx, sc, h.Ref())
		if e == nil {
			t.Fatal("scope content differs from original operation pin")
		}
		return nil
	}); e != nil {
		t.Fatal(e)
	}
	replay, e := s.SummonNormal(ctx, a, def.Template.TableID, def.Template.FragmentItemID, def.FragmentCount, o)
	if e != nil || !reflect.DeepEqual(h, replay) || rawCount(t, p, h.Ref()) != 1 {
		t.Fatal("birth duplicated on original proof", e)
	}
	// Ordinary real star evolution changes the Hero base version, not blood stage
	// or the independent intrinsic birth-fact version.
	exec(t, p, `UPDATE player_item_stacks SET quantity=100000 WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), def.Template.FragmentItemID)
	if e = s.Evolve(ctx, a, h.PartnerID, op()); e != nil {
		t.Fatal(e)
	}
	assertRead(2)
	f, e := (characterstore.RawAwakeningStore{}).ReadRawAwakeningBirthTx(ctx, p, h.Ref())
	if e != nil || f.Version != 1 || f.RawStage != 0 {
		t.Fatal(f, e)
	}
	if _, e = rawBirthReader().RawAwakeningTx(ctx, ca.CoherentReadScope{}, h.Ref()); e == nil {
		t.Fatal("unwitnessed scope accepted")
	}
	// Existing receipt/Hero created without the new initializer stays unknown.
	b := rankingActor(t, p, rankingServer(t, p), true)
	legacyDef := collectionResources(t, p, b, rev, 10001001)
	oldOp := op()
	old, e := collectionService(p).SummonNormal(ctx, b, legacyDef.Template.TableID, legacyDef.Template.FragmentItemID, legacyDef.FragmentCount, oldOp)
	if e != nil {
		t.Fatal(e)
	}
	if e = statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
		_, e := rawBirthReader().RawAwakeningTx(ctx, sc, old.Ref())
		return e
	}); e == nil {
		t.Fatal("legacy missing birth became zero")
	}
	if _, e = rawBirthService(p).SummonNormal(ctx, b, legacyDef.Template.TableID, legacyDef.Template.FragmentItemID, legacyDef.FragmentCount, oldOp); e != nil || rawCount(t, p, old.Ref()) != 0 {
		t.Fatal("historic proof backfilled/rejected", e)
	}
	// Explicit corruption fixtures prove refusal, not positive-stage production.
	for _, q := range []string{"UPDATE player_hero_raw_awakening SET birth_policy='unqualified' WHERE player_id=$1", "UPDATE player_hero_raw_awakening SET birth_policy='C4C_PRIVATE_CHARACTER_RAW_AWAKENING_BIRTH_V1',raw_stage=3 WHERE player_id=$1"} {
		exec(t, p, q, int64(a.PlayerID))
		if e = statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
			_, e := rawBirthReader().RawAwakeningTx(ctx, sc, h.Ref())
			return e
		}); e == nil {
			t.Fatal("unknown policy/stage accepted")
		}
	}
	exec(t, p, `UPDATE player_hero_raw_awakening SET raw_stage=0 WHERE player_id=$1`, int64(a.PlayerID))
	assertRead(2)
	// Simulated retired/missing canonical actor must not be authorized by orphan
	// provenance. No real retirement producer is claimed by this fixture.
	exec(t, p, `DELETE FROM player_heroes WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), h.PartnerID)
	if e = statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
		_, e := rawBirthReader().RawAwakeningTx(ctx, sc, h.Ref())
		return e
	}); e == nil || rawCount(t, p, h.Ref()) != 1 {
		t.Fatal("inactive actor read or provenance lost", e)
	}
}
func TestI7C4RawBirthAtomicRollbackAndPositiveUnknownCommit(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	for _, mode := range []string{"facet-failure", "commit-positive", "commit-absent"} {
		t.Run(mode, func(t *testing.T) {
			a := rankingActor(t, p, rankingServer(t, p), true)
			def := collectionResources(t, p, a, rev, 10001001)
			s := rawBirthService(p)
			o := op()
			if mode == "facet-failure" {
				s.FreshFacets = hero.FreshFacetChain{characterstore.RawAwakeningStore{}, failCollectionFacet{}}
			} else {
				s.Runner.DB = metricCommitDB{p, mode == "commit-positive"}
			}
			got, e := s.SummonNormal(context.Background(), a, def.Template.TableID, def.Template.FragmentItemID, def.FragmentCount, o)
			ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}
			if mode == "commit-positive" {
				if e != nil || rawCount(t, p, ref) != 1 {
					t.Fatal("positive unknownCOMMIT proof", e)
				}
				again, e := rawBirthService(p).SummonNormal(ctx, a, def.Template.TableID, def.Template.FragmentItemID, def.FragmentCount, o)
				if e != nil || !reflect.DeepEqual(got, again) {
					t.Fatal(e)
				}
			} else {
				if e == nil || rawCount(t, p, ref) != 0 {
					t.Fatal("partial birth leaked", e)
				}
				if mode == "facet-failure" && !errors.Is(e, errCollectionFacet) {
					t.Fatal(e)
				}
				var stones int64
				if e = p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), def.Template.FragmentItemID).Scan(&stones); e != nil || stones != def.FragmentCount+9 {
					t.Fatal("cost escaped rollback", stones, e)
				}
			}
		})
	}
}
