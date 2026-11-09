// Package publicstats composes canonical owned facts in a caller-witnessed CA8
// snapshot. It has no gameplay store, mutation, clock or transaction runner.
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
	"math/big"
	"sync"
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
	HeroInputsTx(context.Context, ca.CoherentReadScope, character.HeroRef) (cq.HeroInputs, error)
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

// Installed revisions are immutable and a Materializer is read-only after New,
// so one per revision is shared; building one costs about 60 ms per hero read.
var materializers sync.Map

func (s Service) materializer(c context.Context, sc ca.CoherentReadScope) (*n.Materializer, error) {
	if !scopeValid(sc) || s.Content == nil || s.Owned == nil {
		return nil, ErrUnqualified
	}
	if cached, ok := materializers.Load(sc.ContentRevision); ok {
		return cached.(*n.Materializer), nil
	}
	r, e := s.Content.StatCatalogTx(c, sc.Queryer(), sc.ContentRevision)
	if e != nil {
		return nil, e
	}
	i, e := s.Content.StatInputCatalogTx(c, sc.Queryer(), sc.ContentRevision)
	if e != nil {
		return nil, e
	}
	m, e := n.New(sc.ContentRevision, i, r)
	if e != nil {
		return nil, e
	}
	materializers.Store(sc.ContentRevision, m)
	return m, nil
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
	return s.heroTx(ctx, sc, ref, view, 0, 0, 0)
}

// RobotForceTx evaluates one unowned source hero template with the same stat
// engine owned heroes use. A mode robot has no owner facts, so only the source
// template, its rank-band level/star/colour and its equipped slots contribute.
func (s Service) RobotForceTx(ctx context.Context, sc ca.CoherentReadScope, tableID, level, star, color int64, equipFlags []int64) (Result, error) {
	var out Result
	if !scopeValid(sc) || tableID <= 0 {
		return out, ErrUnqualified
	}
	m, err := s.materializer(ctx, sc)
	if err != nil {
		return out, err
	}
	force, err := m.RobotHeroForce("NormalHero", tableID, int(level), int(star), int(color), equipFlags)
	if err != nil {
		return out, err
	}
	return Result{Stats: rules.Result{Force: force}, Profile: "C3B_HERO_CANONICAL_CONDITIONAL_V1"}, nil
}

// ScaledHeroTx evaluates the same canonical hero at an overridden level, star
// and colour. The observed owned hero still authorizes the read; only the stat
// snapshot changes, so a scaled projection uses the one force formula.
func (s Service) ScaledHeroTx(ctx context.Context, sc ca.CoherentReadScope, ref character.HeroRef, view View, level, star, color int64) (Result, error) {
	if level < 1 || level > character.MaxHeroLevel || star < 1 || star > character.MaxHeroStar || color < 1 || color > 16 {
		return Result{}, ErrUnqualified
	}
	return s.heroTx(ctx, sc, ref, view, level, star, color)
}

func (s Service) heroTx(ctx context.Context, sc ca.CoherentReadScope, ref character.HeroRef, view View, levelOverride, starOverride, colorOverride int64) (Result, error) {
	frozen, err := s.FreezeHeroTx(ctx, sc, ref, view)
	if err != nil {
		return Result{}, err
	}
	level, star, color := frozen.Base()
	if levelOverride > 0 {
		level = levelOverride
	}
	if starOverride > 0 {
		star = starOverride
	}
	if colorOverride > 0 {
		color = colorOverride
	}
	return frozen.Evaluate(level, star, color)
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
