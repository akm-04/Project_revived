package achievement

import (
	"context"
	book "gxb.local/backend/v2/internal/application/bookskill"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	conquer "gxb.local/backend/v2/internal/application/conquerschool"
	course "gxb.local/backend/v2/internal/application/course"
	dorm "gxb.local/backend/v2/internal/application/dormhouse"
	ins "gxb.local/backend/v2/internal/application/inscription"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type HeroKinds interface {
	ReadPlayerDisplayCatalogTx(context.Context, tx.Queryer, string) (player.DisplayCatalog, error)
}
type Books interface {
	BookInputsTx(context.Context, tx.Queryer, book.InputScope) (book.Inputs, error)
}
type Conquer interface {
	FactsTx(context.Context, ca.CoherentReadScope, identity.PlayerID) (conquer.Observation, error)
}
type Courses interface {
	HeroCourseInputsTx(context.Context, tx.Queryer, course.InputScope, int64) (course.HeroInputs, error)
}
type Inscriptions interface {
	HeroInscriptionInputsTx(context.Context, tx.Queryer, ins.InputScope, int64) (ins.HeroInputs, error)
}
type Skins interface {
	SkinCollectionTx(context.Context, ca.CoherentReadScope, identity.PlayerID) (display.CosmeticCount, error)
}
type Dorm interface {
	VillaCountTx(context.Context, tx.Queryer, dorm.InputScope) (dorm.VillaInputs, error)
}

// OwnerCounts reads C4F_OWNED_STATE_COUNT_V1 values through each owner's typed
// read port in one coherent scope. An unavailable owner read leaves that
// achievement unobserved (never zero-filled); the next observation catches up.
type OwnerCounts struct {
	Roster       ca.RosterMetricReader
	Kinds        HeroKinds
	Books        Books
	Conquer      Conquer
	Courses      Courses
	Inscriptions Inscriptions
	Dorm         Dorm
	Skins        Skins
}

func (o OwnerCounts) OwnedStateCountsTx(c context.Context, sc ca.CoherentReadScope, p identity.PlayerID, families []int64) map[int64]int64 {
	out := map[int64]int64{}
	wanted := map[int64]bool{}
	for _, id := range families {
		wanted[id] = true
	}
	q := sc.Queryer()
	heroes, heroesErr := o.Roster.ReadRosterMetricsTx(c, sc, p, "Hero")
	catalog, kindsErr := o.Kinds.ReadPlayerDisplayCatalogTx(c, q, sc.ContentRevision)
	heroesKnown := heroesErr == nil && kindsErr == nil
	kinds := map[int64]string{}
	for _, t := range catalog.HeroTemplates {
		kinds[t.TableID] = t.Kind
	}
	if heroesKnown && (wanted[d.NormalHeroesID] || wanted[d.AwakenedHeroesID]) {
		normal := map[int64]bool{}
		for _, h := range heroes.Rows {
			if kinds[h.TableID] == string(character.NormalHero) {
				normal[h.OriginTableID] = true
			}
			if h.BeforeAwaken > 0 {
				out[d.AwakenedHeroesID]++
			}
		}
		out[d.NormalHeroesID] = int64(len(normal))
	}
	if wanted[d.PetsID] {
		if pets, e := o.Roster.ReadRosterMetricsTx(c, sc, p, "Pet"); e == nil {
			out[d.PetsID] = int64(len(pets.Rows))
		}
	}
	if wanted[d.TextbooksID] {
		if v, e := o.Books.BookInputsTx(c, q, book.InputScope{Player: p, ContentRevision: sc.ContentRevision, ObservedAt: sc.ObservedAt}); e == nil {
			total := int64(0)
			for _, level := range v.Applied.Skills {
				total += level
			}
			out[d.TextbooksID] = total
		}
	}
	if wanted[d.RegionsID] {
		if v, e := o.Conquer.FactsTx(c, sc, p); e == nil {
			out[d.RegionsID] = v.Regions
		}
	}
	if wanted[d.SkinsID] && o.Skins != nil {
		if v, e := o.Skins.SkinCollectionTx(c, sc, p); e == nil {
			out[d.SkinsID] = v.Value
		}
	}
	if wanted[d.RoomsID] || wanted[d.ExpandedRoomsID] {
		if v, e := o.Dorm.VillaCountTx(c, q, dorm.InputScope{Player: p, ContentRevision: sc.ContentRevision, ObservedAt: sc.ObservedAt}); e == nil {
			out[d.RoomsID], out[d.ExpandedRoomsID] = v.Rooms, v.Expanded
		}
	}
	if !heroesKnown {
		return out
	}
	if wanted[d.SubjectsID] {
		if n, e := o.completedSubjects(c, q, sc, p, heroes); e == nil {
			out[d.SubjectsID] = n
		}
	}
	if wanted[d.SuitsID] {
		if n, e := o.completeSuits(c, q, sc, p, heroes); e == nil {
			out[d.SuitsID] = n
		}
	}
	return out
}

// shortcut: one owner read per Hero; observe Course/Inscription only after their own commands and on 1302 load.
func (o OwnerCounts) completedSubjects(c context.Context, q tx.Queryer, sc ca.CoherentReadScope, p identity.PlayerID, heroes ca.RosterMetricPopulation) (int64, error) {
	scope := course.InputScope{Player: p, ContentRevision: sc.ContentRevision, ObservedAt: sc.ObservedAt}
	total := int64(0)
	for _, h := range heroes.Rows {
		v, e := o.Courses.HeroCourseInputsTx(c, q, scope, h.InstanceID)
		if e != nil {
			return 0, e
		}
		for _, r := range v.Applied.Courses {
			if r.Progress == 100 {
				total++
			}
		}
	}
	return total, nil
}

func (o OwnerCounts) completeSuits(c context.Context, q tx.Queryer, sc ca.CoherentReadScope, p identity.PlayerID, heroes ca.RosterMetricPopulation) (int64, error) {
	scope := ins.InputScope{Player: p, ContentRevision: sc.ContentRevision, ObservedAt: sc.ObservedAt}
	total := int64(0)
	for _, h := range heroes.Rows {
		v, e := o.Inscriptions.HeroInscriptionInputsTx(c, q, scope, h.InstanceID)
		if e != nil {
			return 0, e
		}
		total += int64(len(v.CompleteSuits))
	}
	return total, nil
}
