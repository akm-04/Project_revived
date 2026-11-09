package publicstats

import (
	"context"
	"fmt"

	book "gxb.local/backend/v2/internal/application/bookskill"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	course "gxb.local/backend/v2/internal/application/course"
	dorm "gxb.local/backend/v2/internal/application/dormhouse"
	elem "gxb.local/backend/v2/internal/application/elementequipment"
	evo "gxb.local/backend/v2/internal/application/heroevolution"
	ins "gxb.local/backend/v2/internal/application/inscription"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	spirit "gxb.local/backend/v2/internal/application/spirit"
	"gxb.local/backend/v2/internal/domain/character"
	cq "gxb.local/backend/v2/internal/domain/conquerschool"
	d "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	n "gxb.local/backend/v2/internal/domain/statinputs"
	rules "gxb.local/backend/v2/internal/domain/statrules"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// FrozenHero is one qualified owned Hero whose owner facts were read once.
// Overridden level, star and colour evaluate against the same snapshot, so a
// scaled projection costs one owner read instead of one per candidate value.
type FrozenHero struct {
	input frozenHeroInput
}

type frozenHeroInput struct {
	materializer *n.Materializer
	model        string
	base         ca.HeroBaseObservation
	skills       ca.HeroRawSkillObservation
	awakening    ca.HeroRawAwakeningObservation
	owned        ca.OwnedHeroComposite
	library      lib.HeroInputs
	dorm         dorm.HeroInputs
	book         book.HeroInputs
	courses      course.HeroInputs
	inscription  ins.HeroInputs
	element      elem.HeroInputs
	spirit       spirit.HeroInputs
	evolution    evo.HeroInputs
	conquer      cq.HeroInputs
	album        n.Vector
	view         View
	actor        string
	revision     string
	observedAt   time.Time
	operationID  string
	dormEquip    d.EquipmentRule
	hasDormEquip bool
}

// Base returns the owned Hero's own level, star and colour.
func (h *FrozenHero) Base() (int64, int64, int64) {
	return h.input.base.Level, h.input.base.Star, h.input.base.Color
}

// FreezeHeroTx reads every canonical input that does not depend on the
// level/star/colour override.
func (s Service) FreezeHeroTx(ctx context.Context, sc ca.CoherentReadScope, ref character.HeroRef, view View) (*FrozenHero, error) {
	if !scopeValid(sc) || ref.Validate() != nil || view.validate(ref.PlayerID) != nil || s.Skills == nil || s.Awakening == nil || s.Library == nil || s.Dorm == nil || s.Book == nil || s.Courses == nil || s.Inscription == nil || s.Element == nil || s.Spirit == nil || s.Evolution == nil || s.Conquer == nil {
		return nil, ErrUnqualified
	}
	m, err := s.materializer(ctx, sc)
	if err != nil {
		return nil, err
	}
	o, err := s.Owned.OwnedHeroTx(ctx, sc, ref)
	if err != nil {
		return nil, err
	}
	if o.Validate() != nil || o.Base.Ref != ref || o.Equipment.Disposition != ca.ProviderQualifiedActive || o.Practice.Disposition != ca.ProviderQualifiedActive || o.Appearance.Disposition != ca.ProviderQualifiedActive || o.Practice.Value.ContentRevision != sc.ContentRevision || o.Appearance.Value.ContentRevision != sc.ContentRevision || !o.Appearance.Value.Appearance.ObservedAt.Equal(sc.ObservedAt) {
		return nil, ErrUnqualified
	}
	base := o.Base
	model := "NormalHero"
	if base.Kind == character.SuperHero {
		model = "SuperHero"
	}
	raw, err := s.Skills.HeroRawSkillsTx(ctx, sc, ref)
	if err != nil {
		return nil, err
	}
	if raw.Ref != ref || raw.StateVersion != base.StateVersion || !pinned(raw.ContentRevision, raw.ObservedAt, sc) || raw.Facts.Validate() != nil {
		return nil, ErrUnqualified
	}
	aw, err := s.Awakening.RawAwakeningTx(ctx, sc, ref)
	if err != nil {
		return nil, err
	}
	if !aw.Known || aw.ProducerReference == "" || aw.Ref != ref || aw.StateVersion != base.StateVersion || !pinned(aw.ContentRevision, aw.ObservedAt, sc) || aw.RawStage < 0 || aw.RawStage > 3 {
		return nil, ErrUnqualified
	}
	q := sc.Queryer()
	rev := sc.ContentRevision
	at := sc.ObservedAt
	pid := ref.PlayerID
	l, err := s.Library.HeroLibraryInputsTx(ctx, q, lib.InputScope{Player: pid, ContentRevision: rev, ObservedAt: at}, ref.PartnerID)
	if err != nil {
		return nil, err
	}
	if !sameHero(l.Hero, base, sc) || !pinned(l.ContentRevision, l.ObservedAt, sc) || l.PopulationVersion < 1 || l.LibraryRootVersion < 1 || l.Facts.Ref != ref || l.Facts.Validate() != nil {
		return nil, ErrUnqualified
	}
	pop := l.PopulationVersion
	dh, err := s.Dorm.DormHouseInputsTx(ctx, q, dorm.InputScope{Player: pid, ContentRevision: rev, ObservedAt: at}, ref)
	if err != nil {
		return nil, err
	}
	if !sameHero(dh.Hero, base, sc) || !pinned(dh.ContentRevision, dh.ObservedAt, sc) || dh.PopulationVersion != pop || dh.DormRootVersion < 1 || dh.Facts.Player != pid || dh.Facts.PartnerID != ref.PartnerID || dh.Facts.StateVersion < 1 {
		return nil, ErrUnqualified
	}
	bk, err := s.Book.HeroBookInputsTx(ctx, q, book.InputScope{Player: pid, ContentRevision: rev, ObservedAt: at}, ref)
	if err != nil {
		return nil, err
	}
	if !sameHero(bk.Hero, base, sc) || !pinned(bk.Inputs.ContentRevision, bk.Inputs.ObservedAt, sc) || bk.PopulationVersion != pop || bk.Inputs.Root.Player != pid || bk.Inputs.OwnerVersion < 1 {
		return nil, ErrUnqualified
	}
	co, err := s.Courses.HeroCourseInputsTx(ctx, q, course.InputScope{Player: pid, ContentRevision: rev, ObservedAt: at}, ref.PartnerID)
	if err != nil {
		return nil, err
	}
	if !sameHero(co.Hero, base, sc) || !pinned(co.Inputs.ContentRevision, co.Inputs.ObservedAt, sc) || co.Inputs.PopulationVersion != pop || co.Inputs.Root.Player != pid || co.FacetVersion < 1 {
		return nil, ErrUnqualified
	}
	ii, err := s.Inscription.CoherentHeroInputsTx(ctx, sc, ref)
	if err != nil {
		return nil, err
	}
	if !sameHero(ii.Hero, base, sc) || !pinned(ii.Inputs.ContentRevision, ii.Inputs.ObservedAt, sc) || ii.Inputs.PopulationVersion != pop || ii.Inputs.Root.Player != pid || ii.FacetVersion < 1 {
		return nil, ErrUnqualified
	}
	el, err := s.Element.CoherentHeroInputsTx(ctx, sc, ref)
	if err != nil {
		return nil, err
	}
	if !sameHero(el.Hero, base, sc) || !pinned(el.ContentRevision, el.ObservedAt, sc) || el.PopulationVersion != pop || el.Root.Player != pid {
		return nil, ErrUnqualified
	}
	sp, err := s.Spirit.CoherentHeroInputsTx(ctx, sc, ref)
	if err != nil {
		return nil, err
	}
	if !sameHero(sp.Hero, base, sc) || !pinned(sp.ContentRevision, sp.ObservedAt, sc) || sp.PopulationVersion != pop || sp.Root.Player != pid {
		return nil, ErrUnqualified
	}
	ev, err := s.Evolution.CoherentHeroInputsTx(ctx, sc, ref)
	if err != nil {
		return nil, err
	}
	if !sameHero(ev.Hero, base, sc) || !pinned(ev.ContentRevision, ev.ObservedAt, sc) || ev.PopulationVersion != pop {
		return nil, ErrUnqualified
	}
	conquer, err := s.Conquer.HeroInputsTx(ctx, sc, ref)
	if err != nil {
		return nil, err
	}
	if !sameHero(conquer.Hero, base, sc) || !pinned(conquer.Observation.ContentRevision, conquer.Observation.ObservedAt, sc) || conquer.PopulationVersion != pop || conquer.Observation.Facts.Player != pid || !conquer.Observation.Facts.Known() {
		return nil, ErrUnqualified
	}
	album := n.Vector{}
	if view.Kind == Self {
		a, err := s.Library.PlayerCollectionInputsTx(ctx, q, lib.InputScope{Player: pid, ContentRevision: rev, ObservedAt: at})
		if err != nil {
			return nil, err
		}
		if a.Player != pid || a.PopulationVersion != pop || a.LibraryRootVersion != l.LibraryRootVersion || !pinned(a.ContentRevision, a.ObservedAt, sc) {
			return nil, ErrUnqualified
		}
		for k, v := range a.Contributions {
			if k < 1 || k > 49 {
				return nil, ErrUnqualified
			}
			album[k-1] = float64(v) / 100
		}
	}
	dormEquip, hasDormEquip, err := s.freezeDormEquipment(ctx, q, rev, pid, base.TableID, dh)
	if err != nil {
		return nil, err
	}
	return &FrozenHero{input: frozenHeroInput{
		materializer: m, model: model, base: base, skills: raw, awakening: aw, owned: o,
		library: l, dorm: dh, book: bk, courses: co, inscription: ii, element: el,
		spirit: sp, evolution: ev, conquer: conquer, album: album, view: view,
		actor:    fmt.Sprintf("OWNED/HERO/%d/%d/v%d", pid, ref.PartnerID, base.StateVersion),
		revision: rev, observedAt: at, operationID: fmt.Sprint(sc.Operation.ID),
		dormEquip: dormEquip, hasDormEquip: hasDormEquip,
	}}, nil
}

func (s Service) freezeDormEquipment(ctx context.Context, q tx.Queryer, rev string, pid identity.PlayerID, tableID int64, dh dorm.HeroInputs) (d.EquipmentRule, bool, error) {
	if dh.Room == nil || dh.Room.MainType == d.LoungeType {
		if dh.Room == nil && dh.Facts.HouseID != 0 {
			return d.EquipmentRule{}, false, ErrUnqualified
		}
		return d.EquipmentRule{}, false, nil
	}
	if dh.Room.Player != pid || dh.Room.ID != dh.Facts.HouseID {
		return d.EquipmentRule{}, false, ErrUnqualified
	}
	dc, err := s.Content.DormCatalogTx(ctx, q, rev)
	if err != nil {
		return d.EquipmentRule{}, false, err
	}
	rule, ok := dc.Equipment[tableID]
	if !ok {
		return d.EquipmentRule{}, false, ErrUnqualified
	}
	return rule, true, nil
}

// Evaluate computes the canonical result at the requested level, star and
// colour from the frozen inputs.
func (h *FrozenHero) Evaluate(level, star, color int64) (Result, error) {
	if level < 1 || level > character.MaxHeroLevel || star < 1 || star > character.MaxHeroStar || color < 1 || color > 16 {
		return Result{}, ErrUnqualified
	}
	in := h.input
	m, model, b := in.materializer, in.model, in.base
	raw, aw, o := in.skills, in.awakening, in.owned
	l, dh, bk, co, ii, el, sp, ev, cq := in.library, in.dorm, in.book, in.courses, in.inscription, in.element, in.spirit, in.evolution, in.conquer
	album, view, actor := in.album, in.view, in.actor
	eq, prom, fumo, err := m.Inputs.Equipment(model, b.TableID, int(color), slots(o.Equipment.Value))
	if err != nil {
		return Result{}, err
	}
	pr, award, err := practice(o.Practice.Value)
	if err != nil {
		return Result{}, err
	}
	input := inputs(eq, prom, fumo, pr, actor)
	vectors := map[string]n.Vector{}
	scalars := map[string]float64{}
	var dhEquip n.Vector
	if in.hasDormEquip {
		for i, v := range dh.Facts.Equipment {
			if v > 0 && int64(i) < star {
				a, e := m.Inputs.Item(in.dormEquip.Items[i])
				if e != nil {
					return Result{}, e
				}
				if e = dhEquip.Add(a); e != nil {
					return Result{}, e
				}
			}
		}
	}
	if err = eq.Add(dhEquip); err != nil {
		return Result{}, err
	}
	input["getEquipAttr"] = rules.Observation{Reference: actor, Values: eq.Map()}
	var bookAttrs, shelf, growth, feed n.Vector
	for id, count := range bk.Skills {
		r, ok := bk.SkillRules[id]
		if !ok || r.AttrID < 1 || r.AttrID > 49 || count < 0 {
			return Result{}, ErrUnqualified
		}
		v, e := n.Number(r.Value)
		if e != nil {
			return Result{}, e
		}
		bookAttrs[r.AttrID-1] += v * float64(count)
	}
	growthBase, err := m.BaseGrowth(b.TableID, int(star), int(level))
	if err != nil {
		return Result{}, err
	}
	for i, v := range bk.Bookshelf.Attributes {
		a, e := n.Number(v)
		if e != nil {
			return Result{}, e
		}
		shelf[i] = a / 100 * growthBase[i]
	}
	for i, v := range dh.GrowthBP {
		growth[i] = float64(v) / 10000
	}
	for i, v := range l.Facts.Applied {
		feed[i+3] = float64(v)
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
			return Result{}, ErrUnqualified
		}
		p, e := n.Number(md["power"])
		step, e2 := n.Number(md["step_power"])
		if e != nil || e2 != nil {
			return Result{}, ErrUnqualified
		}
		scalars["getCoursesForce"] += p + float64(r.Quality)*step
		if md["book_type"] == "0" {
			a, e := n.Attrs(md["attr"], md["number"])
			b, e2 := n.Attrs(md["attr"], md["step_up"])
			if e != nil || e2 != nil {
				return Result{}, ErrUnqualified
			}
			for i := range a {
				a[i] += float64(r.Quality) * b[i]
			}
			if e = courseAttrs.Add(a); e != nil {
				return Result{}, e
			}
		}
	}
	vectors["getCoursesAttr"] = courseAttrs
	display, battle, insForce, err := inscriptionNumbers(ii)
	if err != nil {
		return Result{}, err
	}
	vectors["getInscriptionAttr"] = display
	vectors["getBattleInscriptionAttr"] = battle
	scalars["getInscriptionForce"] = insForce
	var element, showElement, spirits, evolution, conquer n.Vector
	for k, v := range el.Contributions {
		if err = setRational(&element, k, v.Value); err != nil {
			return Result{}, err
		}
	}
	if model == "NormalHero" {
		es, e := el.Catalog.Evaluate(el.Facet.Facts, false, b.TableID, 0)
		if e != nil {
			return Result{}, e
		}
		for k, v := range es {
			if err = setRational(&showElement, k, v.Value); err != nil {
				return Result{}, err
			}
		}
		vectors["getElementAttrJustForShow"] = showElement
	}
	for k, v := range sp.Contributions.Values {
		if err = setRational(&spirits, k, v); err != nil {
			return Result{}, err
		}
	}
	for k, v := range ev.Contributions {
		if k < 1 || k > 49 {
			return Result{}, ErrUnqualified
		}
		evolution[k-1] = float64(v)
	}
	for k, v := range cq.Observation.Contributions {
		if k < 1 || k > 49 {
			return Result{}, ErrUnqualified
		}
		conquer[k-1] = float64(v)
	}
	vectors["getElementAttr"] = element
	vectors["getSpiritEquipsAttr"] = spirits
	vectors["getStoneEvolutionAttr"] = evolution
	vectors["getConquerSchoolAttr"] = conquer
	extra := eq[19] + prom[19] + bookAttrs[19] + award[19] + display[19] + conquer[19] + courseAttrs[19] + album[19]
	skillAttrs, skillForce, err := m.SkillNumbers(n.SkillState{Model: model, TemplateID: b.TableID, Level: int(level), Star: int(star), Color: int(color), Raw: raw.Facts.Levels, IDs: raw.ResolvedIDs, Twice: aw.RawStage == 3, BookshelfCap: float64(bk.Bookshelf.UpperLimit), Extra: extra})
	if err != nil {
		return Result{}, err
	}
	vectors["getSkillAttr"] = skillAttrs
	scalars["getSkillForce"] = skillForce
	if scalars["getFeedForce"], err = m.Weighted(feed); err != nil {
		return Result{}, err
	}
	if scalars["getWhiteAlbumForce"], err = m.Weighted(album); err != nil {
		return Result{}, err
	}
	if _, ok := scalars["getCoursesForce"]; !ok {
		scalars["getCoursesForce"] = 0
	}
	for k, v := range vectors {
		input[k] = rules.Observation{Reference: actor, Values: v.Map()}
	}
	for k, v := range scalars {
		input[k] = rules.Observation{Reference: actor, Values: map[int]float64{0: v}}
	}
	if model == "SuperHero" {
		delete(input, "getEquipFumoAttr")
	}
	result, err := m.Engine.Evaluate(rules.Snapshot{Model: model, TemplateID: b.TableID, Level: int(level), Star: int(star), Color: int(color), ActorReference: actor, ObservationID: in.operationID, ContentRevision: in.revision, PolicyID: rules.PolicyID, ObservedAt: in.observedAt, Inputs: input})
	if err != nil {
		return Result{}, err
	}
	return Result{Stats: result, View: view, OwnerStateVersion: b.StateVersion, Profile: "C3B_HERO_CANONICAL_CONDITIONAL_V1"}, nil
}
