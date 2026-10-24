package characterhero

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type HeroOriginCatalogReader interface {
	HeroOriginCatalogTx(context.Context, tx.Queryer, string) ([]int64, error)
}
type CollectionAdmissionAuthorizer interface {
	AuthorizeCollectionOriginTx(context.Context, tx.Tx, character.HeroRoot, []character.Hero, int64, string, operation.Context) (character.CollectionAdmissionProof, error)
}

// CatalogCollectionAdmission is the production current-client policy. Its
// source catalog and canonical caller-locked roster are never client counts.
type CatalogCollectionAdmission struct{ Content HeroOriginCatalogReader }

func (a CatalogCollectionAdmission) AuthorizeCollectionOriginTx(c context.Context, t tx.Tx, root character.HeroRoot, heroes []character.Hero, candidate int64, revision string, op operation.Context) (character.CollectionAdmissionProof, error) {
	var out character.CollectionAdmissionProof
	content, cp := op.Policies.Get("content")
	pin, pp := op.Policies.Get(character.CollectionAdmissionPolicyRef)
	if t == nil || a.Content == nil || root.Validate() != nil || root.UpdatedAt.Before(root.CreatedAt) || root.UpdatedAt.After(op.StartedAt) || !cp || content != revision || !pp || pin != character.CollectionAdmissionPolicy {
		return out, ErrHeroCapacityUnavailable
	}
	origins, instances := []int64{}, map[int64]bool{}
	for _, h := range heroes {
		if h.ValidatePersistent() != nil || h.PlayerID != root.PlayerID || h.CreatedAt.After(h.UpdatedAt) || h.UpdatedAt.After(op.StartedAt) || instances[h.PartnerID] {
			return out, ErrHeroCapacityUnavailable
		}
		instances[h.PartnerID] = true
		origins = append(origins, h.OriginTableID)
	}
	catalog, e := a.Content.HeroOriginCatalogTx(c, t, revision)
	if e != nil {
		return out, e
	}
	out, e = character.AdmitCollectionOrigin(root.PlayerID, root.StateVersion, revision, op.StartedAt, catalog, origins, candidate)
	if e != nil {
		return out, fmt.Errorf("%w: %v", ErrHeroCapacityUnavailable, e)
	}
	return out, nil
}

func (s Service) bindNormalAcquisition(c context.Context, actor identity.ActorContext, op operation.Context, fp [32]byte) (operation.Context, string, error) {
	if op.ID.IsZero() || op.StartedAt.IsZero() {
		return op, "", ErrHeroAcquisitionInvalid
	}
	if s.CollectionAdmission == nil {
		return s.bindProgressionContent(c, op)
	}
	if s.ReceiptRead == nil {
		return op, "", ErrHeroCapacityUnavailable
	}
	prior, found, e := s.ReceiptRead.Find(c, heroReceiptID(actor, "stone-summon", op))
	if e != nil {
		return op, "", e
	}
	if found {
		if _, e = decodeNormalAcquisition(prior, actor, op, fp); e != nil {
			return op, "", e
		}
		op.Policies = prior.OperationPolicyRefs
		revision, _ := op.Policies.Get("content")
		return op, revision, nil
	}
	bound, revision, e := s.bindProgressionContent(c, op)
	if e != nil {
		return op, "", e
	}
	if v, ok := bound.Policies.Get(character.CollectionAdmissionPolicyRef); ok {
		if v != character.CollectionAdmissionPolicy {
			return op, "", ErrHeroCapacityUnavailable
		}
		return bound, revision, nil
	}
	refs := append(bound.Policies.Refs(), policy.Ref{Name: character.CollectionAdmissionPolicyRef, Version: character.CollectionAdmissionPolicy})
	bound.Policies, e = policy.NewSet(refs...)
	return bound, revision, e
}

func decodeNormalAcquisition(prior receipt.Receipt, actor identity.ActorContext, original operation.Context, fp [32]byte) (character.Hero, error) {
	if prior.Validate() != nil || prior.Identity != heroReceiptID(actor, "stone-summon", original) || !bytes.Equal(prior.RequestFingerprint[:], fp[:]) || prior.OperationClass != "CA2_HERO_ACQUISITION" || prior.ResultSchema != "gxb.ca2.hero-acquisition.v1" || prior.OperationStartedAt.UnixMicro() != original.StartedAt.UnixMicro() {
		return character.Hero{}, ErrHeroAcquisitionInvalid
	}
	for _, supplied := range original.Policies.Refs() {
		got, ok := prior.OperationPolicyRefs.Get(supplied.Name)
		if !ok || got != supplied.Version {
			return character.Hero{}, ErrHeroAcquisitionInvalid
		}
	}
	revision, pinned := prior.OperationPolicyRefs.Get("content")
	if !pinned {
		return character.Hero{}, ErrHeroAcquisitionInvalid
	}
	var ar acquisitionReceipt
	if e := json.Unmarshal(prior.ResultPayload, &ar); e != nil {
		return character.Hero{}, e
	}
	if ar.CreationContentRevision != revision {
		return character.Hero{}, ErrHeroAcquisitionInvalid
	}
	bound := original
	bound.Policies = prior.OperationPolicyRefs
	if ar.CollectionAdmission == nil {
		if prior.PolicyVersion == character.CollectionAdmissionPolicy {
			return character.Hero{}, ErrHeroAcquisitionInvalid
		}
		if _, has := bound.Policies.Get(character.CollectionAdmissionPolicyRef); has {
			return character.Hero{}, ErrHeroAcquisitionInvalid
		}
	} else {
		pin, has := bound.Policies.Get(character.CollectionAdmissionPolicyRef)
		if !has || pin != character.CollectionAdmissionPolicy || prior.PolicyVersion != character.CollectionAdmissionPolicy || prior.ActorAccountUID != string(actor.AccountUID) || prior.ContextID != actor.ContextID.UUID() {
			return character.Hero{}, ErrHeroAcquisitionInvalid
		}
	}
	return heroFromReceipt(ar, actor.PlayerID, bound)
}
