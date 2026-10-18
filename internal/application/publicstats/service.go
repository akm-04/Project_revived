// Package publicstats composes canonical owned facts in a caller-witnessed CA8
// snapshot. It has no gameplay store, mutation, clock or transaction runner.
package publicstats

import (
	"context"
	"fmt"
	book "gxb.local/backend/v2/internal/application/bookskill"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	conquer "gxb.local/backend/v2/internal/application/conquerschool"
	course "gxb.local/backend/v2/internal/application/course"
	dorm "gxb.local/backend/v2/internal/application/dormhouse"
	elem "gxb.local/backend/v2/internal/application/elementequipment"
	evo "gxb.local/backend/v2/internal/application/heroevolution"
	ins "gxb.local/backend/v2/internal/application/inscription"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	spirit "gxb.local/backend/v2/internal/application/spirit"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	n "gxb.local/backend/v2/internal/domain/statinputs"
	rules "gxb.local/backend/v2/internal/domain/statrules"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math/big"
	"time"
)

var ErrUnqualified = n.ErrUnqualified

const Self = "OWNED_SELF_LIVE"
const Foreign = "OWNED_FOREIGN_LIVE"

type View struct {
	Kind   string
	Viewer identity.PlayerID
}

func (v View) validate(target identity.PlayerID) error {
	if !v.Viewer.Valid() || !target.Valid() || v.Kind != Self && v.Kind != Foreign || v.Kind == Self && v.Viewer != target || v.Kind == Foreign && v.Viewer == target {
		return ErrUnqualified
	}
	return nil
}

type Content interface {
	StatCatalogTx(context.Context, tx.Queryer, string) (rules.Catalog, error)
	StatInputCatalogTx(context.Context, tx.Queryer, string) (n.Catalog, error)
	DormCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}
type PetState interface {
	ReadPetByIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, error)
}
type Owned interface {
	OwnedHeroTx(context.Context, ca.CoherentReadScope, character.HeroRef) (ca.OwnedHeroComposite, error)
	OwnedPetTx(context.Context, ca.CoherentReadScope, character.PetRef) (ca.OwnedPetComposite, error)
}
type Library interface {
	HeroLibraryInputsTx(context.Context, tx.Queryer, lib.InputScope, int64) (lib.HeroInputs, error)
	PlayerCollectionInputsTx(context.Context, tx.Queryer, lib.InputScope) (lib.CollectionInputs, error)
}
type Dorm interface {
	DormHouseInputsTx(context.Context, tx.Queryer, dorm.InputScope, character.HeroRef) (dorm.HeroInputs, error)
}
type Book interface {
	HeroBookInputsTx(context.Context, tx.Queryer, book.InputScope, character.HeroRef) (book.HeroInputs, error)
}
type Courses interface {
	HeroCourseInputsTx(context.Context, tx.Queryer, course.InputScope, int64) (course.HeroInputs, error)
}
type Inscription interface {
	CoherentHeroInputsTx(context.Context, ca.CoherentReadScope, character.HeroRef) (ins.HeroInputs, error)
}
type Element interface {
	CoherentHeroInputsTx(context.Context, ca.CoherentReadScope, character.HeroRef) (elem.HeroInputs, error)
}
type Spirit interface {
	CoherentHeroInputsTx(context.Context, ca.CoherentReadScope, character.HeroRef) (spirit.HeroInputs, error)
}
type Evolution interface {
	CoherentHeroInputsTx(context.Context, ca.CoherentReadScope, character.HeroRef) (evo.HeroInputs, error)
}
type Conquer interface {
	HeroInputsTx(context.Context, ca.CoherentReadScope, character.HeroRef) (conquer.HeroInputs, error)
}

// Awakening is a required Character-owned observation. A caller default
// or a stat fixture is not its implementation; nil leaves Hero reads unavailable.
type AwakeningObservation = ca.HeroRawAwakeningObservation

type Awakening interface {
	RawAwakeningTx(context.Context, ca.CoherentReadScope, character.HeroRef) (AwakeningObservation, error)
}
type Service struct {
	Pets        PetState
	Owned       Owned
	Content     Content
	Skills      ca.HeroRawSkillObservationProvider
	Awakening   Awakening
	Library     Library
	Dorm        Dorm
	Book        Book
	Courses     Courses
	Inscription Inscription
	Element     Element
	Spirit      Spirit
	Evolution   Evolution
	Conquer     Conquer
}
type Result struct {
	Stats             rules.Result
	View              View
	OwnerStateVersion int64
	Profile           string
}

func scopeValid(s ca.CoherentReadScope) bool {
	if s.Validate() != nil {
		return false
	}
	p, ok := s.Operation.Policies.Get("content")
	return ok && p == s.ContentRevision
}
func (s Service) materializer(c context.Context, sc ca.CoherentReadScope) (*n.Materializer, error) {
	if !scopeValid(sc) || s.Content == nil || s.Owned == nil {
		return nil, ErrUnqualified
	}
	r, e := s.Content.StatCatalogTx(c, sc.Queryer(), sc.ContentRevision)
	if e != nil {
		return nil, e
	}
	i, e := s.Content.StatInputCatalogTx(c, sc.Queryer(), sc.ContentRevision)
	if e != nil {
		return nil, e
	}
	return n.New(sc.ContentRevision, i, r)
}
func pinned(rev string, at time.Time, sc ca.CoherentReadScope) bool {
	return rev == sc.ContentRevision && at.Equal(sc.ObservedAt)
}
func sameHero(h character.Hero, b ca.HeroBaseObservation, sc ca.CoherentReadScope) bool {
	return h.ValidatePersistent() == nil && h.Ref() == b.Ref && h.TableID == b.TableID && h.OriginTableID == b.OriginTableID && h.Level == b.Level && h.Color == b.Color && h.Star == b.Star && h.StateVersion == b.StateVersion && h.CreationContentRevision == b.CreationContentRevision && !sc.ObservedAt.Before(h.UpdatedAt) && (h.Kind == "" || h.Kind == b.Kind)
}
func inputs(eq, prom, fumo, practice n.Vector, ref string) map[string]rules.Observation {
	m := map[string]rules.Observation{}
	for k, v := range map[string]n.Vector{"getEquipAttr": eq, "getJinjieEquipAttr": prom, "getEquipFumoAttr": fumo, "getTotalPracticeAttr": practice} {
		m[k] = rules.Observation{Reference: ref, Values: v.Map()}
	}
	return m
}

// The accepted CA6 port already includes applied axes in Contributions.
// Recover award-only values for extra skill levels without adding raw twice.
func practice(p ca.PracticeContribution) (n.Vector, n.Vector, error) {
	var total, award n.Vector
	seen := map[int64]bool{}
	for _, x := range p.Contributions {
		if x.AttrType < 1 || x.AttrType > 49 || seen[x.AttrType] || !n.Finite(float64(x.Value)) || x.Value < 0 {
			return total, award, ErrUnqualified
		}
		seen[x.AttrType] = true
		total[x.AttrType-1] = float64(x.Value)
	}
	award = total
	for i, raw := range p.Applied {
		if raw < 0 || award[i] < float64(raw) {
			return total, award, ErrUnqualified
		}
		award[i] -= float64(raw)
	}
	return total, award, nil
}

func slots(raw ca.RawEquipmentState) []n.Slot {
	out := []n.Slot{}
	for _, v := range raw.Slots {
		out = append(out, n.Slot{ID: int64(v.TemplateID), RawFumo: v.RawFumo, Enhancement: v.Enhancement})
	}
	return out
}
func (scoped Service) PetTx(ctx context.Context, sc ca.CoherentReadScope, ref character.PetRef, view View) (Result, error) {
	var out Result
	if scoped.Pets == nil {
		return out, ErrUnqualified
	}
	if ref.Validate() != nil || view.validate(ref.PlayerID) != nil {
		return out, ErrUnqualified
	}
	m, e := scoped.materializer(ctx, sc)
	if e != nil {
		return out, e
	}
	o, e := scoped.Owned.OwnedPetTx(ctx, sc, ref)
	if e != nil {
		return out, e
	}
	if o.Validate() != nil || o.Base.Ref != ref || o.Equipment.Disposition != ca.ProviderQualifiedActive || o.Practice.Disposition != ca.ProviderQualifiedActive || o.Appearance.Disposition != ca.ProviderQualifiedActive || o.Practice.Value.ContentRevision != sc.ContentRevision || o.Appearance.Value.ContentRevision != sc.ContentRevision || !o.Appearance.Value.Appearance.ObservedAt.Equal(sc.ObservedAt) {
		return out, ErrUnqualified
	}
	b := o.Base
	p, e := scoped.Pets.ReadPetByIDTx(ctx, sc.Queryer(), ref.PlayerID, ref.PetID)
	if e != nil {
		return out, e
	}
	if p.ValidatePersistent() != nil || p.Ref() != ref || p.TableID != b.TableID || p.OriginTableID != b.OriginTableID || p.Level != b.Level || p.Color != b.Color || p.Star != b.Star || p.Skills != b.Skills || p.StateVersion != b.StateVersion || p.CreationContentRevision != b.CreationContentRevision || sc.ObservedAt.Before(p.UpdatedAt) {
		return out, ErrUnqualified
	}
	eq, prom, fumo, e := m.Inputs.Equipment("Pet", b.TableID, int(b.Color), slots(o.Equipment.Value))
	if e != nil {
		return out, e
	}
	pr, _, e := practice(o.Practice.Value)
	if e != nil {
		return out, e
	}
	ss := n.SkillState{Model: "Pet", TemplateID: b.TableID, Level: int(b.Level), Star: int(b.Star), Color: int(b.Color)}
	for i, v := range b.Skills {
		ss.Raw[i] = v
	}
	for _, t := range m.Rules.Templates {
		if t.ID == b.TableID {
			copy(ss.IDs[:], t.SlotSkills)
		}
	}
	attrs, force, e := m.SkillNumbers(ss)
	if e != nil {
		return out, e
	}
	actor := fmt.Sprintf("OWNED/PET/%d/%d/v%d", ref.PlayerID, ref.PetID, b.StateVersion)
	in := inputs(eq, prom, fumo, pr, actor)
	in["getSkillAttr"] = rules.Observation{Reference: actor, Values: attrs.Map()}
	in["getSkillForce"] = rules.Observation{Reference: actor, Values: map[int]float64{0: force}}
	result, e := m.Engine.Evaluate(rules.Snapshot{Model: "Pet", TemplateID: b.TableID, Level: int(b.Level), Star: int(b.Star), Color: int(b.Color), ActorReference: actor, ObservationID: fmt.Sprint(sc.Operation.ID), ContentRevision: sc.ContentRevision, PolicyID: rules.PolicyID, ObservedAt: sc.ObservedAt, Inputs: in})
	if e != nil {
		return out, e
	}
	return Result{Stats: result, View: view, OwnerStateVersion: b.StateVersion, Profile: "C3B_PET_CANONICAL_OWNED_V1"}, nil
}
func (s Service) HeroTx(ctx context.Context, sc ca.CoherentReadScope, ref character.HeroRef, view View) (Result, error) {
	var out Result
	if !scopeValid(sc) || ref.Validate() != nil || view.validate(ref.PlayerID) != nil || s.Skills == nil || s.Awakening == nil || s.Library == nil || s.Dorm == nil || s.Book == nil || s.Courses == nil || s.Inscription == nil || s.Element == nil || s.Spirit == nil || s.Evolution == nil || s.Conquer == nil {
		return out, ErrUnqualified
	}
	m, e := s.materializer(ctx, sc)
	if e != nil {
		return out, e
	}
	o, e := s.Owned.OwnedHeroTx(ctx, sc, ref)
	if e != nil {
		return out, e
	}
	if o.Validate() != nil || o.Base.Ref != ref || o.Equipment.Disposition != ca.ProviderQualifiedActive || o.Practice.Disposition != ca.ProviderQualifiedActive || o.Appearance.Disposition != ca.ProviderQualifiedActive || o.Practice.Value.ContentRevision != sc.ContentRevision || o.Appearance.Value.ContentRevision != sc.ContentRevision || !o.Appearance.Value.Appearance.ObservedAt.Equal(sc.ObservedAt) {
		return out, ErrUnqualified
	}
	b := o.Base
	model := "NormalHero"
	if b.Kind == character.SuperHero {
		model = "SuperHero"
	}
	raw, e := s.Skills.HeroRawSkillsTx(ctx, sc, ref)
	if e != nil {
		return out, e
	}
	if raw.Ref != ref || raw.StateVersion != b.StateVersion || !pinned(raw.ContentRevision, raw.ObservedAt, sc) || raw.Facts.Validate() != nil {
		return out, ErrUnqualified
	}
	aw, e := s.Awakening.RawAwakeningTx(ctx, sc, ref)
	if e != nil {
		return out, e
	}
	if !aw.Known || aw.ProducerReference == "" || aw.Ref != ref || aw.StateVersion != b.StateVersion || !pinned(aw.ContentRevision, aw.ObservedAt, sc) || aw.RawStage < 0 || aw.RawStage > 3 {
		return out, ErrUnqualified
	}
	q := sc.Queryer()
	rev := sc.ContentRevision
	at := sc.ObservedAt
	pid := ref.PlayerID
	l, e := s.Library.HeroLibraryInputsTx(ctx, q, lib.InputScope{Player: pid, ContentRevision: rev, ObservedAt: at}, ref.PartnerID)
	if e != nil {
		return out, e
	}
	if !sameHero(l.Hero, b, sc) || !pinned(l.ContentRevision, l.ObservedAt, sc) || l.PopulationVersion < 1 || l.LibraryRootVersion < 1 || l.Facts.Ref != ref || l.Facts.Validate() != nil {
		return out, ErrUnqualified
	}
	pop := l.PopulationVersion
	dh, e := s.Dorm.DormHouseInputsTx(ctx, q, dorm.InputScope{Player: pid, ContentRevision: rev, ObservedAt: at}, ref)
	if e != nil {
		return out, e
	}
	if !sameHero(dh.Hero, b, sc) || !pinned(dh.ContentRevision, dh.ObservedAt, sc) || dh.PopulationVersion != pop || dh.DormRootVersion < 1 || dh.Facts.Player != pid || dh.Facts.PartnerID != ref.PartnerID || dh.Facts.StateVersion < 1 {
		return out, ErrUnqualified
	}
	bk, e := s.Book.HeroBookInputsTx(ctx, q, book.InputScope{Player: pid, ContentRevision: rev, ObservedAt: at}, ref)
	if e != nil {
		return out, e
	}
	if !sameHero(bk.Hero, b, sc) || !pinned(bk.Inputs.ContentRevision, bk.Inputs.ObservedAt, sc) || bk.PopulationVersion != pop || bk.Inputs.Root.Player != pid || bk.Inputs.OwnerVersion < 1 {
		return out, ErrUnqualified
	}
	co, e := s.Courses.HeroCourseInputsTx(ctx, q, course.InputScope{Player: pid, ContentRevision: rev, ObservedAt: at}, ref.PartnerID)
	if e != nil {
		return out, e
	}
	if !sameHero(co.Hero, b, sc) || !pinned(co.Inputs.ContentRevision, co.Inputs.ObservedAt, sc) || co.Inputs.PopulationVersion != pop || co.Inputs.Root.Player != pid || co.FacetVersion < 1 {
		return out, ErrUnqualified
	}
	ii, e := s.Inscription.CoherentHeroInputsTx(ctx, sc, ref)
	if e != nil {
		return out, e
	}
	if !sameHero(ii.Hero, b, sc) || !pinned(ii.Inputs.ContentRevision, ii.Inputs.ObservedAt, sc) || ii.Inputs.PopulationVersion != pop || ii.Inputs.Root.Player != pid || ii.FacetVersion < 1 {
		return out, ErrUnqualified
	}
	el, e := s.Element.CoherentHeroInputsTx(ctx, sc, ref)
	if e != nil {
		return out, e
	}
	if !sameHero(el.Hero, b, sc) || !pinned(el.ContentRevision, el.ObservedAt, sc) || el.PopulationVersion != pop || el.Root.Player != pid {
		return out, ErrUnqualified
	}
	sp, e := s.Spirit.CoherentHeroInputsTx(ctx, sc, ref)
	if e != nil {
		return out, e
	}
	if !sameHero(sp.Hero, b, sc) || !pinned(sp.ContentRevision, sp.ObservedAt, sc) || sp.PopulationVersion != pop || sp.Root.Player != pid {
		return out, ErrUnqualified
	}
	ev, e := s.Evolution.CoherentHeroInputsTx(ctx, sc, ref)
	if e != nil {
		return out, e
	}
	if !sameHero(ev.Hero, b, sc) || !pinned(ev.ContentRevision, ev.ObservedAt, sc) || ev.PopulationVersion != pop {
		return out, ErrUnqualified
	}
	cq, e := s.Conquer.HeroInputsTx(ctx, sc, ref)
	if e != nil {
		return out, e
	}
	if !sameHero(cq.Hero, b, sc) || !pinned(cq.Observation.ContentRevision, cq.Observation.ObservedAt, sc) || cq.PopulationVersion != pop || cq.Observation.Facts.Player != pid || !cq.Observation.Facts.Known() {
		return out, ErrUnqualified
	}
	eq, prom, fumo, e := m.Inputs.Equipment(model, b.TableID, int(b.Color), slots(o.Equipment.Value))
	if e != nil {
		return out, e
	}
	pr, award, e := practice(o.Practice.Value)
	if e != nil {
		return out, e
	}
	actor := fmt.Sprintf("OWNED/HERO/%d/%d/v%d", pid, ref.PartnerID, b.StateVersion)
	in := inputs(eq, prom, fumo, pr, actor)
	vectors := map[string]n.Vector{}
	scalars := map[string]float64{}
	var dhEquip n.Vector
	if dh.Room != nil && dh.Room.MainType != d.LoungeType {
		if dh.Room.Player != pid || dh.Room.ID != dh.Facts.HouseID {
			return out, ErrUnqualified
		}
		dc, e := s.Content.DormCatalogTx(ctx, q, rev)
		if e != nil {
			return out, e
		}
		r, ok := dc.Equipment[b.TableID]
		if !ok {
			return out, ErrUnqualified
		}
		for i, v := range dh.Facts.Equipment {
			if v > 0 && int64(i) < b.Star {
				a, e := m.Inputs.Item(r.Items[i])
				if e != nil {
					return out, e
				}
				if e = dhEquip.Add(a); e != nil {
					return out, e
				}
			}
		}
	} else if dh.Room == nil && dh.Facts.HouseID != 0 {
		return out, ErrUnqualified
	}
	if e = eq.Add(dhEquip); e != nil {
		return out, e
	}
	in["getEquipAttr"] = rules.Observation{Reference: actor, Values: eq.Map()}
	var bookAttrs, shelf, growth, feed, album n.Vector
	for id, count := range bk.Skills {
		r, ok := bk.SkillRules[id]
		if !ok || r.AttrID < 1 || r.AttrID > 49 || count < 0 {
			return out, ErrUnqualified
		}
		v, e := n.Number(r.Value)
		if e != nil {
			return out, e
		}
		bookAttrs[r.AttrID-1] += v * float64(count)
	}
	base, e := m.BaseGrowth(b.TableID, int(b.Star), int(b.Level))
	if e != nil {
		return out, e
	}
	for i, v := range bk.Bookshelf.Attributes {
		a, e := n.Number(v)
		if e != nil {
			return out, e
		}
		shelf[i] = a / 100 * base[i]
	}
	for i, v := range dh.GrowthBP {
		growth[i] = float64(v) / 10000
	}
	for i, v := range l.Facts.Applied {
		feed[i+3] = float64(v)
	}
	if view.Kind == Self {
		a, e := s.Library.PlayerCollectionInputsTx(ctx, q, lib.InputScope{Player: pid, ContentRevision: rev, ObservedAt: at})
		if e != nil {
			return out, e
		}
		if a.Player != pid || a.PopulationVersion != pop || a.LibraryRootVersion != l.LibraryRootVersion || !pinned(a.ContentRevision, a.ObservedAt, sc) {
			return out, ErrUnqualified
		}
		for k, v := range a.Contributions {
			if k < 1 || k > 49 {
				return out, ErrUnqualified
			}
			album[k-1] = float64(v) / 100
		}
	}
	vectors["getSkillBookAttr"] = bookAttrs
	vectors["getBookShelfAttr"] = shelf
	vectors["getHouseAttrGrowthByType"] = growth
	vectors["getFeedAttr"] = feed
	vectors["getWhiteAlbumAttr"] = album
	scalars["getFavorAttrGrowth"] = float64(l.FavorBonusBP) / 10000
	var courseAttrs n.Vector
	for _, r := range co.AppliedCourses {
		if r.Skill <= 0 {
			continue
		}
		md := co.Inputs.Catalog.Metadata(r.ID)
		if md == nil {
			return out, ErrUnqualified
		}
		p, e := n.Number(md["power"])
		step, e2 := n.Number(md["step_power"])
		if e != nil || e2 != nil {
			return out, ErrUnqualified
		}
		scalars["getCoursesForce"] += p + float64(r.Quality)*step
		if md["book_type"] == "0" {
			a, e := n.Attrs(md["attr"], md["number"])
			b, e2 := n.Attrs(md["attr"], md["step_up"])
			if e != nil || e2 != nil {
				return out, ErrUnqualified
			}
			for i := range a {
				a[i] += float64(r.Quality) * b[i]
			}
			if e = courseAttrs.Add(a); e != nil {
				return out, e
			}
		}
	}
	vectors["getCoursesAttr"] = courseAttrs
	display, battle, insForce, e := inscriptionNumbers(ii)
	if e != nil {
		return out, e
	}
	vectors["getInscriptionAttr"] = display
	vectors["getBattleInscriptionAttr"] = battle
	scalars["getInscriptionForce"] = insForce
	var element, showElement, spirits, evolution, conq n.Vector
	for k, v := range el.Contributions {
		if e = setRational(&element, k, v.Value); e != nil {
			return out, e
		}
	}
	if model == "NormalHero" {
		es, e := el.Catalog.Evaluate(el.Facet.Facts, false, b.TableID, 0)
		if e != nil {
			return out, e
		}
		for k, v := range es {
			if e = setRational(&showElement, k, v.Value); e != nil {
				return out, e
			}
		}
		vectors["getElementAttrJustForShow"] = showElement
	}
	for k, v := range sp.Contributions.Values {
		if e = setRational(&spirits, k, v); e != nil {
			return out, e
		}
	}
	for k, v := range ev.Contributions {
		if k < 1 || k > 49 {
			return out, ErrUnqualified
		}
		evolution[k-1] = float64(v)
	}
	for k, v := range cq.Observation.Contributions {
		if k < 1 || k > 49 {
			return out, ErrUnqualified
		}
		conq[k-1] = float64(v)
	}
	vectors["getElementAttr"] = element
	vectors["getSpiritEquipsAttr"] = spirits
	vectors["getStoneEvolutionAttr"] = evolution
	vectors["getConquerSchoolAttr"] = conq
	extra := eq[19] + prom[19] + bookAttrs[19] + award[19] + display[19] + conq[19] + courseAttrs[19] + album[19]
	skillAttrs, skillForce, e := m.SkillNumbers(n.SkillState{Model: model, TemplateID: b.TableID, Level: int(b.Level), Star: int(b.Star), Color: int(b.Color), Raw: raw.Facts.Levels, IDs: raw.ResolvedIDs, Twice: aw.RawStage == 3, BookshelfCap: float64(bk.Bookshelf.UpperLimit), Extra: extra})
	if e != nil {
		return out, e
	}
	vectors["getSkillAttr"] = skillAttrs
	scalars["getSkillForce"] = skillForce
	scalars["getFeedForce"], e = m.Weighted(feed)
	if e != nil {
		return out, e
	}
	scalars["getWhiteAlbumForce"], e = m.Weighted(album)
	if e != nil {
		return out, e
	}
	if _, ok := scalars["getCoursesForce"]; !ok {
		scalars["getCoursesForce"] = 0
	}
	for k, v := range vectors {
		in[k] = rules.Observation{Reference: actor, Values: v.Map()}
	}
	for k, v := range scalars {
		in[k] = rules.Observation{Reference: actor, Values: map[int]float64{0: v}}
	}
	if model == "SuperHero" {
		delete(in, "getEquipFumoAttr")
	}
	result, e := m.Engine.Evaluate(rules.Snapshot{Model: model, TemplateID: b.TableID, Level: int(b.Level), Star: int(b.Star), Color: int(b.Color), ActorReference: actor, ObservationID: fmt.Sprint(sc.Operation.ID), ContentRevision: rev, PolicyID: rules.PolicyID, ObservedAt: at, Inputs: in})
	if e != nil {
		return out, e
	}
	return Result{Stats: result, View: view, OwnerStateVersion: b.StateVersion, Profile: "C3B_HERO_CANONICAL_CONDITIONAL_V1"}, nil
}
func setRational(v *n.Vector, k int64, s string) error {
	if k < 1 || k > 49 {
		return ErrUnqualified
	}
	r, ok := new(big.Rat).SetString(s)
	if !ok {
		return ErrUnqualified
	}
	f, _ := r.Float64()
	if !n.Finite(f) {
		return ErrUnqualified
	}
	v[k-1] = f
	return nil
}
func inscriptionNumbers(v ins.HeroInputs) (display, battle n.Vector, force float64, err error) {
	for _, it := range v.Items {
		for k, x := range it.Display {
			if k < 1 || k > 49 {
				return display, battle, force, ErrUnqualified
			}
			a, e := n.Number(x)
			if e != nil {
				return display, battle, force, e
			}
			display[k-1] += a
		}
		for k, x := range it.Battle {
			if k < 1 || k > 49 {
				return display, battle, force, ErrUnqualified
			}
			a, e := n.Number(x)
			if e != nil {
				return display, battle, force, e
			}
			battle[k-1] += a
		}
		found := false
		for _, r := range v.Inputs.Catalog.Tables["inscription"] {
			id, _ := n.Int(r["id"])
			if id == it.Family {
				f, e := n.Number(r["fighting_capacity"])
				if e != nil {
					return display, battle, force, e
				}
				force += f
				found = true
				break
			}
		}
		if !found {
			return display, battle, force, ErrUnqualified
		}
	}
	// Three positions allow at most one complete set; source assigns rather than adds suit attrs.
	if len(v.CompleteSuits) > 1 {
		return display, battle, force, ErrUnqualified
	}
	for _, id := range v.CompleteSuits {
		found := false
		for _, r := range v.Inputs.Catalog.Tables["suits"] {
			rid, _ := n.Int(r["id"])
			if rid != id {
				continue
			}
			a, e := n.Attrs(r["attr"], r["attr_num"])
			if e != nil {
				return display, battle, force, e
			}
			if e = display.Add(a); e != nil {
				return display, battle, force, e
			}
			if e = battle.Add(a); e != nil {
				return display, battle, force, e
			}
			f, e := n.Number(r["fighting_capacity"])
			if e != nil {
				return display, battle, force, e
			}
			force += f
			found = true
		}
		if !found {
			return display, battle, force, ErrUnqualified
		}
	}
	return
}
