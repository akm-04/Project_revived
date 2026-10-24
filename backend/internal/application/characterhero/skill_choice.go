package characterhero

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const SkillChoicePolicyID = "I7C2A_V1_KONGMING_CHOICE_V1"
const skillChoiceSchema = "gxb.character-hero.skill-choice.v1"

var ErrSkillChoiceRequest = errors.New("character hero: invalid skillChoice request")
var ErrSkillChoiceProof = errors.New("character hero: invalid skillChoice proof")
var ErrSkillChoiceStaleTime = errors.New("character hero: stale skillChoice decision time")

type SkillChoiceStore interface {
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
	ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error)
	SaveHeroSkillChoiceTx(context.Context, tx.Tx, character.Hero, int64) error
}
type SkillChoiceInventory interface {
	LockEconomyOwnerTx(context.Context, tx.Tx, identity.PlayerID) error
	LockStackTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time) (economy.StackState, bool, error)
}
type SkillChoiceContent interface {
	HeroRawSkillsActive(context.Context) (string, bool, error)
	HeroSkillCatalogTx(context.Context, tx.Queryer, string, int64) (character.HeroSkillCatalog, error)
}
type SkillChoiceService struct {
	Inventory SkillChoiceInventory
	Content   SkillChoiceContent
	Timed     gen.TimedRunner
	Reads     tx.Runner
	Store     SkillChoiceStore
	Players   playerroot.TxLocker
	Fence     ActorFencer
	Receipts  receipt.Store
}
type SkillChoiceResult struct {
	Schema          string    `json:"schema"`
	PlayerID        int64     `json:"player_id"`
	PartnerID       int64     `json:"partner_id"`
	SkillIDs        []int64   `json:"skill_ids"`
	BookItemID      int64     `json:"book_item_id"`
	ContentRevision string    `json:"content_revision"`
	StateVersion    int64     `json:"state_version"`
	Changed         bool      `json:"changed"`
	Account         string    `json:"account"`
	Context         string    `json:"context"`
	Server          int32     `json:"server"`
	EntropySeed     [32]byte  `json:"entropy_seed"`
	DecisionAt      time.Time `json:"decision_at"`
}

func skillChoiceReceiptID(a identity.ActorContext, o operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "character-hero", Operation: "skillChoice", SemanticKey: o.ID.String()}
}
func skillChoiceFP(partner, value int64) ([32]byte, error) {
	return receipt.FingerprintRequest(map[string]any{"partner_id": partner, "skill_index": int64(5), "skill_item": value, "policy": SkillChoicePolicyID})
}
func (s SkillChoiceService) proof(c context.Context, q tx.Queryer, a identity.ActorContext, partner, value int64, o operation.Context) (SkillChoiceResult, bool, error) {
	rr, found, e := s.Receipts.FindTx(c, q, skillChoiceReceiptID(a, o))
	if e != nil || !found {
		return SkillChoiceResult{}, found, e
	}
	fp, e := skillChoiceFP(partner, value)
	if e != nil {
		return SkillChoiceResult{}, true, e
	}
	if rr.Validate() != nil || rr.Identity != skillChoiceReceiptID(a, o) || rr.OperationClass != "I7C2A_HERO_SKILL_CHOICE" || rr.ResultSchema != skillChoiceSchema || rr.RequestFingerprint != fp || rr.ActorAccountUID != string(a.AccountUID) || rr.ContextID != a.ContextID.UUID() || rr.OperationStartedAt.UnixMicro() != o.StartedAt.UnixMicro() || rr.PolicyVersion != SkillChoicePolicyID {
		return SkillChoiceResult{}, true, ErrSkillChoiceProof
	}
	if v, ok := rr.OperationPolicyRefs.Get("skillChoice"); !ok || v != SkillChoicePolicyID {
		return SkillChoiceResult{}, true, ErrSkillChoiceProof
	}
	for _, r := range o.Policies.Refs() {
		if v, ok := rr.OperationPolicyRefs.Get(r.Name); !ok || v != r.Version {
			return SkillChoiceResult{}, true, ErrSkillChoiceProof
		}
	}
	var out SkillChoiceResult
	d := json.NewDecoder(bytes.NewReader(rr.ResultPayload))
	d.DisallowUnknownFields()
	if d.Decode(&out) != nil {
		return out, true, ErrSkillChoiceProof
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return out, true, ErrSkillChoiceProof
	}
	if out.Schema != skillChoiceSchema || out.PlayerID != int64(a.PlayerID) || out.PartnerID != partner || out.BookItemID != value || len(out.SkillIDs) != 6 || out.SkillIDs[4] != skillChoiceID(value) || len(out.ContentRevision) != 64 || out.StateVersion < 1 || out.Account != string(a.AccountUID) || out.Context != a.ContextID.UUID().String() || out.Server != int32(a.LogicalServerID) || out.EntropySeed != o.EntropySeed || out.DecisionAt.IsZero() || out.DecisionAt.After(rr.RecordedAt) {
		return out, true, ErrSkillChoiceProof
	}
	if v, ok := rr.OperationPolicyRefs.Get("content"); !ok || v != out.ContentRevision {
		return out, true, ErrSkillChoiceProof
	}
	for _, id := range out.SkillIDs {
		if id < 0 {
			return out, true, ErrSkillChoiceProof
		}
	}
	// Known outcomes are historical. A later owner change need not equal the result.
	return out, true, nil
}

type skillChoiceResolver struct {
	s              SkillChoiceService
	a              identity.ActorContext
	partner, value int64
	o              operation.Context
}

func (r skillChoiceResolver) ResolveTimed(c context.Context, req gen.TimedResolutionRequest) (tx.Resolution, error) {
	var out SkillChoiceResult
	var found bool
	res, e := r.s.Reads.Run(c, r.o, profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		if e := r.s.Fence.FenceActorTx(c, sc.Tx, r.a, req.Operation.DecisionAt()); e != nil {
			return e
		}
		var e error
		out, found, e = r.s.proof(c, sc.Tx, r.a, r.partner, r.value, r.o)
		return e
	})
	if e != nil || res.Outcome != tx.DefiniteCommit {
		return tx.Resolution{}, e
	}
	if !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: out}, nil
}
func (s SkillChoiceService) ChangeSkill(c context.Context, a identity.ActorContext, partner, slot, value int64, o operation.Context) (SkillChoiceResult, error) {
	if partner <= 0 || partner > 9007199254740991 || (slot != 5 || skillChoiceID(value) == 0) || !a.PlayerID.Valid() || !a.LogicalServerID.Valid() || !a.AccountUID.Valid() || a.ContextID.UUID().IsZero() || o.ID.IsZero() || o.StartedAt.IsZero() || s.Timed.Binder.Time == nil || s.Timed.Runner.DB == nil || s.Reads.DB == nil || s.Store == nil || s.Players == nil || s.Fence == nil || s.Receipts == nil || s.Inventory == nil || s.Content == nil {
		return SkillChoiceResult{}, ErrSkillChoiceRequest
	}
	var known SkillChoiceResult
	var found bool
	res, e := s.Reads.Run(c, o, profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		known, found, e = s.proof(c, sc.Tx, a, partner, value, o)
		if e != nil || !found {
			return e
		}
		at, e := s.Timed.Binder.Time.Now(c)
		if e != nil {
			return e
		}
		return s.Fence.FenceActorTx(c, sc.Tx, a, at)
	})
	if e != nil {
		return SkillChoiceResult{}, e
	}
	if found {
		if res.Outcome != tx.DefiniteCommit {
			return SkillChoiceResult{}, ErrSkillChoiceProof
		}
		return known, nil
	}
	revision, active, e := s.Content.HeroRawSkillsActive(c)
	if e != nil {
		return SkillChoiceResult{}, e
	}
	if !active {
		return SkillChoiceResult{}, ErrHeroContentInactive
	}
	if supplied, ok := o.Policies.Get("content"); ok {
		revision = supplied
	}
	refs := o.Policies.Refs()
	if _, ok := o.Policies.Get("content"); !ok {
		refs = append(refs, policy.Ref{Name: "content", Version: revision})
	}
	if v, ok := o.Policies.Get("skillChoice"); ok {
		if v != SkillChoicePolicyID {
			return SkillChoiceResult{}, ErrSkillChoiceProof
		}
	} else {
		refs = append(refs, policy.Ref{Name: "skillChoice", Version: SkillChoicePolicyID})
	}
	ps, e := policy.NewSet(refs...)
	if e != nil {
		return SkillChoiceResult{}, e
	}
	o.Policies = ps
	// Entire owner lock plan is known before mutation: actor root315 then Hero410.
	ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: partner}
	if _, e := characterasset.HeroReferenceLockKey(ref); e != nil {
		return SkillChoiceResult{}, e
	}
	var out SkillChoiceResult
	_, res, e = s.Timed.Run(c, o, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 5 * time.Millisecond, DefiniteAbortBackoffMax: 30 * time.Millisecond}, skillChoiceResolver{s, a, partner, value, o}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if e := s.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		prior, ok, e := s.proof(c, sc.Tx, a, partner, value, o)
		if e != nil {
			return e
		}
		if ok {
			out = prior
			return nil
		}
		roots, e := s.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID})
		if e != nil {
			return e
		}
		if len(roots) != 1 {
			return ErrSkillChoiceRequest
		}
		h, e := s.Store.LockHeroByPartnerIDTx(c, sc.Tx, a.PlayerID, partner)
		if e != nil {
			return e
		}
		if h.ValidatePersistent() != nil || h.Ref() != ref {
			return ErrSkillChoiceRequest
		}
		if at.Before(h.UpdatedAt) {
			return ErrSkillChoiceStaleTime
		}
		if h.TableID != 11001144 {
			return ErrSkillChoiceRequest
		}
		catalog, e := s.Content.HeroSkillCatalogTx(c, sc.Tx, revision, h.TableID)
		if e != nil {
			return e
		}
		desired := skillChoiceID(value)
		qualified := false
		for _, option := range catalog.Choices[4] {
			if option.ID == desired && option.BookItemID == value {
				qualified = true
				break
			}
		}
		if !qualified {
			return ErrSkillChoiceRequest
		}
		// Existing order: player315 -> Hero410 -> economy700 -> stack722.
		if e = s.Inventory.LockEconomyOwnerTx(c, sc.Tx, a.PlayerID); e != nil {
			return e
		}
		book, exists, e := s.Inventory.LockStackTx(c, sc.Tx, a.PlayerID, value, at)
		if e != nil {
			return e
		}
		if !exists || book.Validate() != nil || book.PlayerID != a.PlayerID || book.ItemID != value || book.Quantity <= 0 {
			return ErrSkillChoiceRequest
		}
		if at.Before(book.UpdatedAt) {
			return ErrSkillChoiceStaleTime
		}
		changed := h.RawSkills.ChoiceIDs[4] != desired
		if changed {
			old := h.StateVersion
			h.RawSkills.ChoiceIDs[4] = desired
			h.StateVersion++
			h.UpdatedAt = at
			if e = s.Store.SaveHeroSkillChoiceTx(c, sc.Tx, h, old); e != nil {
				return e
			}
		}
		r := SkillChoiceResult{Schema: skillChoiceSchema, PlayerID: int64(a.PlayerID), PartnerID: partner, SkillIDs: append([]int64(nil), h.RawSkills.ChoiceIDs[:]...), BookItemID: value, ContentRevision: revision, StateVersion: h.StateVersion, Changed: changed, Account: string(a.AccountUID), Context: a.ContextID.UUID().String(), Server: int32(a.LogicalServerID), EntropySeed: o.EntropySeed, DecisionAt: at}
		raw, e := json.Marshal(r)
		if e != nil {
			return e
		}
		fp, e := skillChoiceFP(partner, value)
		if e != nil {
			return e
		}
		rr, e := receipt.New(o, skillChoiceReceiptID(a, o), "I7C2A_HERO_SKILL_CHOICE", skillChoiceSchema, raw, fp)
		if e != nil {
			return e
		}
		rr.ActorAccountUID = string(a.AccountUID)
		rr.ContextID = a.ContextID.UUID()
		rr.PolicyVersion = SkillChoicePolicyID
		rr.RecordedAt = at
		put, e := s.Receipts.PutTx(c, sc.Tx, rr)
		if e != nil {
			return e
		}
		if !put.Inserted {
			return ErrSkillChoiceProof
		}
		out = r
		return nil
	})
	if e != nil {
		return SkillChoiceResult{}, e
	}
	if res.Reconciled && res.Outcome == tx.DefiniteCommit {
		got, ok := res.Evidence.(SkillChoiceResult)
		if !ok {
			return SkillChoiceResult{}, ErrSkillChoiceProof
		}
		return got, nil
	}
	if res.Outcome != tx.DefiniteCommit {
		return SkillChoiceResult{}, ErrSkillChoiceProof
	}
	return out, nil
}

// Exact user-approved frozen V1 preservation mappings; content must corroborate
// them at the bound revision before any new mutation is accepted.
func skillChoiceID(book int64) int64 {
	switch book {
	case 50000005:
		return 60010144
	case 50000010:
		return 60020144
	case 50000015:
		return 60030144
	case 50000020:
		return 60040144
	case 50000025:
		return 60050144
	}
	return 0
}
