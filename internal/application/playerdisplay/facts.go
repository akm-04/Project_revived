package playerdisplay

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

const EligibilityPolicy = "I7C4A_SOURCE_ELIGIBILITY_V1"
const Eligible = "ELIGIBLE"
const Ineligible = "INELIGIBLE"
const Unavailable = "UNAVAILABLE"

// NotLive is a forward-bound row (C4F_FULL_FAMILY_V1): resolved, never earnable
// and never counted.
const NotLive = "NOT_LIVE"

type CosmeticPrivilegeReader interface {
	ReadCosmeticPrivilegeTx(context.Context, tx.Queryer, identity.PlayerID, string, time.Time) (privilege.Snapshot, error)
}
type CharacterPopulation struct {
	PlayerID      identity.PlayerID
	Revision      string
	ObservedAt    time.Time
	RootVersion   int64
	RootUpdatedAt time.Time
	Heroes        []HeroFacet
	Digest        string
}
type CharacterPopulationReader interface {
	ReadDisplayPopulationTx(context.Context, ca.CoherentReadScope, identity.PlayerID) (CharacterPopulation, error)
}
type InventoryPopulation struct {
	PlayerID    identity.PlayerID
	RootVersion int64
	CreatedAt   time.Time
	Stacks      []economy.StackState
}
type InventoryReader interface {
	ReadDisplayInventoryTx(context.Context, tx.Queryer, identity.PlayerID) (InventoryPopulation, error)
}
type EligibilityRequest struct {
	PlayerID       identity.PlayerID
	Family         string
	CompleteFamily bool
}
type EligibilityFact struct {
	Family                        string
	CatalogID, Category, UniqueID int64
	Status, Basis                 string
	EndTime                       int64
	Heroes                        []HeroFacet
	Origins                       []Origin
	// Eligible is not a durable owned entitlement. A selected row is separate.
}
type EligibilityObservation struct {
	Policy, ContentRevision            string
	PlayerID                           identity.PlayerID
	OperationID                        string
	ObservedAt                         time.Time
	ProfileVersion, ProgressionVersion int64
	Selection                          player.DisplaySelection
	Character                          CharacterPopulation
	Inventory                          InventoryPopulation
	Privilege                          *privilege.Snapshot
	Facts                              []EligibilityFact
	RecipientOrigins                   []Origin
	PopulationDigest                   string
	CompleteFamily                     bool
	MissingProviders                   []string
}

func PopulationDigest(v any) string {
	b, _ := json.Marshal(v)
	h := sha256.Sum256(b)
	return hex.EncodeToString(h[:])
}
func scopeValid(sc ca.CoherentReadScope) bool {
	p, ok := sc.Operation.Policies.Get("content")
	return sc.Validate() == nil && ok && p == sc.ContentRevision
}

// ReadEligibilityTx has no clock, revision discovery, nested transaction, lock or
// write. It returns exact per-row core facts. A family is complete only when no
// row is UNAVAILABLE; a CompleteFamily request fails otherwise, never reading zero.
func (s Service) ReadEligibilityTx(c context.Context, sc ca.CoherentReadScope, q EligibilityRequest) (EligibilityObservation, error) {
	var out EligibilityObservation
	if !scopeValid(sc) || !q.PlayerID.Valid() || s.Content == nil || s.Store == nil || s.Population == nil || s.Inventory == nil {
		return out, ErrUnavailable
	}
	if q.Family != "avatar" && q.Family != "frame" && q.Family != "title" && q.Family != "bubble" {
		return out, ErrRequest
	}
	p, e := s.Content.ReadPlayerDisplayCatalogTx(c, sc.Queryer(), sc.ContentRevision)
	if e != nil {
		return out, e
	}
	if p.Validate() != nil {
		return out, ErrConflict
	}
	state, e := s.Store.ReadDisplayStateTx(c, sc.Queryer(), q.PlayerID, false)
	if e != nil {
		return out, e
	}
	if state.Validate() != nil || state.Basis.Profile.PlayerID != q.PlayerID || state.Basis.Progression.PlayerID != q.PlayerID || state.Basis.Profile.UpdatedAt.After(sc.ObservedAt) || state.Basis.Progression.UpdatedAt.After(sc.ObservedAt) {
		return out, ErrConflict
	}
	pop, e := s.Population.ReadDisplayPopulationTx(c, sc, q.PlayerID)
	if e != nil {
		return out, e
	}
	if pop.PlayerID != q.PlayerID || pop.Revision != sc.ContentRevision || !pop.ObservedAt.Equal(sc.ObservedAt) || pop.RootVersion < 1 || pop.RootUpdatedAt.After(sc.ObservedAt) || pop.Digest != PopulationDigest(pop.Heroes) {
		return out, ErrConflict
	}
	for _, h := range pop.Heroes {
		if h.PlayerID != q.PlayerID || h.PartnerID <= 0 || h.Version < 1 {
			return out, ErrConflict
		}
	}
	inv, e := s.Inventory.ReadDisplayInventoryTx(c, sc.Queryer(), q.PlayerID)
	if e != nil {
		return out, e
	}
	if inv.PlayerID != q.PlayerID || inv.RootVersion < 1 || inv.CreatedAt.IsZero() || inv.CreatedAt.After(sc.ObservedAt) {
		return out, ErrConflict
	}
	stacks := map[int64]economy.StackState{}
	for _, v := range inv.Stacks {
		if v.Validate() != nil || v.PlayerID != q.PlayerID || v.UpdatedAt.After(sc.ObservedAt) {
			return out, ErrConflict
		}
		if _, ok := stacks[v.ItemID]; ok {
			return out, ErrConflict
		}
		stacks[v.ItemID] = v
	}
	out = EligibilityObservation{Policy: EligibilityPolicy, ContentRevision: sc.ContentRevision, PlayerID: q.PlayerID, OperationID: sc.Operation.ID.String(), ObservedAt: sc.ObservedAt, ProfileVersion: state.Basis.Profile.StateVersion, ProgressionVersion: state.Basis.Progression.StateVersion, Selection: state.Selection, Character: pop, Inventory: inv, Facts: []EligibilityFact{}, MissingProviders: []string{"ACTUAL_MODE_OCCURRENCE_RANKING_TITLE_ORIGIN_COVERAGE"}}
	if s.CosmeticPrivileges != nil {
		v, e := s.CosmeticPrivileges.ReadCosmeticPrivilegeTx(c, sc.Queryer(), q.PlayerID, sc.ContentRevision, sc.ObservedAt)
		if e != nil && !errors.Is(e, privilege.ErrUnavailable) {
			return out, e
		}
		if e == nil {
			if v.Validate(q.PlayerID, sc.ContentRevision, sc.ObservedAt) != nil {
				return out, ErrConflict
			}
			out.Privilege = &v
		}
	}
	// Recipient rows are retained evidence only. Their presence is not proof of
	// a mode producer, a complete origin population, or current eligibility.
	out.RecipientOrigins, e = s.Store.ReadDisplayEntitlementsTx(c, sc.Queryer(), q.PlayerID, q.Family)
	if e != nil {
		return out, e
	}
	for _, v := range out.RecipientOrigins {
		if v.Validate() != nil || v.PlayerID != q.PlayerID || v.Family != q.Family {
			return out, ErrConflict
		}
	}
	for _, v := range p.Cosmetics {
		if v.Family != q.Family {
			continue
		}
		categories := []int64{0}
		if v.Family == "avatar" {
			switch v.Type {
			case 1:
				categories = []int64{1}
			case 2:
				categories = []int64{2, 3}
			case 3:
				categories = []int64{4}
			default:
				categories = []int64{5}
			}
		}
		for _, category := range categories {
			f := EligibilityFact{Family: v.Family, CatalogID: v.ID, Category: category, Status: Unavailable, Basis: "ACTUAL_ORIGIN_NOT_QUALIFIED"}
			switch {
			case v.Family == "avatar" && v.Type == 1 || v.Family == "frame" && v.Type == 1 || v.Family == "bubble" && v.ID == p.DefaultBubble:
				f.Status = Eligible
				f.Basis = "SOURCE_BASE"
			case v.Family == "avatar" && (v.Type == 2 || v.Type == 3 || v.Type == 7 || v.Type == 11):
				f.Status = Ineligible
				f.Basis = "CHARACTER_CANONICAL_POPULATION"
				f.Heroes = HeroEligibility(v, category, pop.Heroes, p)
				if len(f.Heroes) > 0 {
					f.Status = Eligible
				}
			case v.Family == "frame" && v.Type == 6:
				f.Basis = "COMMERCE_CANONICAL_PRIVILEGE"
				if out.Privilege != nil {
					f.Status = Ineligible
					if out.Privilege.State.VIPLevel >= v.VIP {
						f.Status = Eligible
					}
				}
			case (v.Family == "avatar" || v.Family == "frame") && v.Days == -1:
				f.Status = Ineligible
				f.Basis = "I5_PERMANENT_STACK"
				if x, ok := stacks[v.ID]; ok && x.Quantity > 0 {
					f.Status = Eligible
					f.Origins = []Origin{{PlayerID: q.PlayerID, Key: "ordinary-stack", Owner: "i5", Family: v.Family, CatalogID: v.ID, Revision: sc.ContentRevision, StateVersion: x.StateVersion}}
				}
			}
			// Source special inventory is an OR branch, also for skin,
			// collection and VIP rows. A permanent stack does not require the
			// independent Hero or privilege predicate to succeed.
			if f.Status != Eligible && (v.Family == "frame" || v.Family == "avatar" && v.Type > 3) && v.Days == -1 {
				if x, ok := stacks[v.ID]; ok && x.Quantity > 0 {
					f.Status = Eligible
					f.Basis = "I5_PERMANENT_STACK"
					f.Origins = []Origin{{PlayerID: q.PlayerID, Key: "ordinary-stack", Owner: "i5", Family: v.Family, CatalogID: v.ID, Revision: sc.ContentRevision, StateVersion: x.StateVersion}}
				}
			}
			// A bounded title, bubble or timed avatar/frame owner can provide exact
			// positive or complete negative facts for one catalog row without
			// claiming the family.
			timed := (q.Family == "avatar" || q.Family == "frame") && v.Days > 0
			if (q.Family == "title" || q.Family == "bubble" || timed) && f.Status == Unavailable && s.CatalogExternal != nil {
				os, complete, err := s.catalogOrigins(c, sc.Queryer(), q.PlayerID, q.Family, v.ID, sc.ContentRevision, sc.ObservedAt)
				if err != nil && !errors.Is(err, ErrUnavailable) {
					return out, err
				}
				if err == nil {
					f.Basis = "CANONICAL_CATALOG_SCOPED_ORIGIN"
					if complete {
						f.Status = Ineligible
					}
					for _, o := range os {
						original, err := s.Content.ReadPlayerDisplayCatalogTx(c, sc.Queryer(), o.Revision)
						if err != nil {
							return out, err
						}
						if original.Validate() != nil {
							return out, ErrConflict
						}
						row, found := original.Find(o.Family, o.CatalogID)
						if !found {
							return out, ErrConflict
						}
						end, err := row.EndTime(o.StartsAt, o.EndTime)
						if err != nil {
							return out, err
						}
						if player.EligibleAt(end, sc.ObservedAt) {
							o.EndTime = end
							f.Status = Eligible
							f.Origins = append(f.Origins, o)
						}
					}
				}
			}
			if f.Status == Unavailable && player.ForwardBound(f.Family, f.CatalogID) {
				f.Status = NotLive
				f.Basis = player.ForwardBindingsPolicy
			}
			out.Facts = append(out.Facts, f)
		}
	}
	out.CompleteFamily = completeFamily(out.Facts)
	if out.CompleteFamily {
		out.MissingProviders = []string{}
	}
	if q.CompleteFamily && !out.CompleteFamily {
		return out, ErrUnavailable
	}
	out.PopulationDigest = PopulationDigest(struct {
		Character CharacterPopulation
		Inventory InventoryPopulation
		Privilege *privilege.Snapshot
		Origins   []Origin
	}{pop, inv, out.Privilege, out.RecipientOrigins})
	return out, nil
}
func completeFamily(facts []EligibilityFact) bool {
	for _, f := range facts {
		if f.Status == Unavailable {
			return false
		}
	}
	return true
}
