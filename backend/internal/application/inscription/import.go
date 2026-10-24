package inscription

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	ins "gxb.local/backend/v2/internal/domain/inscription"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
	"reflect"
	"sort"
	"time"
)

// Import is a controlled preservation transition; there is no gameplay route.
// The operator supplies an exact source artifact and a typed extraction package.
// Hash verification binds provenance, not recovered original-server semantics.
type ImportPackage struct {
	SchemaVersion                                 int
	Player                                        identity.PlayerID
	ContentRevision, Policy, SourceArtifactSHA256 string
	Facts                                         ins.State
	Heroes                                        []ImportedHero
	Certificates                                  [3]int64
}
type ImportedHero struct {
	PartnerID int64
	Facts     ins.HeroFacts
}
type VerifiedImport struct {
	data   ImportPackage
	digest string
}

func VerifyImport(raw, sourceArtifact []byte) (VerifiedImport, error) {
	var v VerifiedImport
	d := json.NewDecoder(bytes.NewReader(raw))
	d.DisallowUnknownFields()
	if e := d.Decode(&v.data); e != nil {
		return v, e
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return v, ErrProof
	}
	source := sha256.Sum256(sourceArtifact)
	if len(sourceArtifact) == 0 || hex.EncodeToString(source[:]) != v.data.SourceArtifactSHA256 {
		return v, ErrProof
	}
	if v.data.SchemaVersion != 1 || v.data.Policy != ins.Policy || !v.data.Player.Valid() || len(v.data.ContentRevision) != 64 {
		return v, ins.ErrUnqualified
	}
	h := sha256.Sum256(raw)
	v.digest = hex.EncodeToString(h[:])
	return v, nil
}

type ImportOwner interface {
	ReadImportProofTx(context.Context, tx.Queryer, identity.PlayerID) (string, bool, error)
	SaveImportProofTx(context.Context, tx.Tx, identity.PlayerID, string, string, string, time.Time) error
}
type CertificateImporter interface {
	ImportInscriptionCertificatesTx(context.Context, tx.Tx, identity.PlayerID, [3]int64, string, time.Time) error
}

// RunImport only installs into owner-qualified empty seed state. Repeated exact
// input converges by durable proof; conflicting imports never overwrite facts.
func (s Service) RunImport(ctx context.Context, input VerifiedImport, values CertificateImporter, op operation.Context) error {
	if !s.complete() || input.digest == "" || values == nil {
		return ins.ErrUnqualified
	}
	owner, ok := s.Owner.(ImportOwner)
	if !ok {
		return ins.ErrUnqualified
	}
	v := input.data

	_, result, e := s.Timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if _, e := s.Heroes.LockRootTx(ctx, sc.Tx, v.Player); e != nil {
			return e
		}
		heroes := append([]ImportedHero(nil), v.Heroes...)
		sort.Slice(heroes, func(i, j int) bool { return heroes[i].PartnerID < heroes[j].PartnerID })
		for i, h := range heroes {
			if h.PartnerID <= 0 || i > 0 && heroes[i-1].PartnerID == h.PartnerID {
				return ins.ErrUnqualified
			}
			if _, e := s.Heroes.LockHeroByPartnerIDTx(ctx, sc.Tx, v.Player, h.PartnerID); e != nil {
				return e
			}
		}
		r, e := s.Owner.LockRootTx(ctx, sc.Tx, v.Player)
		if e != nil {
			return e
		}
		if at.Before(r.UpdatedAt) {
			return ErrStale
		}
		digest, found, e := owner.ReadImportProofTx(ctx, sc.Tx, v.Player)
		if e != nil {
			return e
		}
		if found {
			if digest == input.digest {
				return nil
			}
			return ErrProof
		}
		c, e := s.Content.InscriptionCatalogTx(ctx, sc.Tx, v.ContentRevision)
		if e != nil {
			return e
		}
		if v.Facts.Pending != nil && (v.Facts.Pending.Revision != v.ContentRevision || v.Facts.Pending.CreatedAt.After(at)) {
			return ins.ErrUnqualified
		}
		if e = v.Facts.Validate(c); e != nil {
			return e
		}
		if r.Version != 1 || !reflect.DeepEqual(r.Facts, ins.Seed()) {
			return ins.ErrInvalid
		}
		facets := []ins.HeroRoot{}
		for _, h := range heroes {
			if e = h.Facts.Validate(c); e != nil {
				return e
			}
			f, e := s.Owner.LockHeroTx(ctx, sc.Tx, v.Player, h.PartnerID)
			if e != nil {
				return e
			}
			if f.Version != 1 || f.Facts != ins.SeedHero() || at.Before(f.UpdatedAt) {
				return ins.ErrInvalid
			}
			f.Facts = h.Facts
			facets = append(facets, f)
		}
		if e = values.ImportInscriptionCertificatesTx(ctx, sc.Tx, v.Player, v.Certificates, v.SourceArtifactSHA256, at); e != nil {
			return e
		}
		old := r.Version
		r.Version++
		r.Facts = v.Facts.Clone()
		r.UpdatedAt = at
		if e = s.Owner.SaveRootTx(ctx, sc.Tx, r, old); e != nil {
			return e
		}
		for _, f := range facets {
			old := f.Version
			f.Version++
			f.UpdatedAt = at
			if e = s.Owner.SaveHeroTx(ctx, sc.Tx, f, old); e != nil {
				return e
			}
		}
		return owner.SaveImportProofTx(ctx, sc.Tx, v.Player, input.digest, v.SourceArtifactSHA256, v.ContentRevision, at)
	})
	if e != nil {
		return e
	}
	if result.Outcome != tx.DefiniteCommit {
		return ErrUnavailable
	}
	return nil
}
