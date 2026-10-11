package publicprofile

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/finitejson"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

const ShowcaseSlots = 6
const ShowcasePolicyID = "I7B_SHOWCASE_SELECTION_V1"

var ErrSelection = errors.New("invalid showcase selection")
var ErrShowcaseUnavailable = errors.New("showcase required provider unavailable")
var ErrShowcasePrivate = errors.New("showcase privacy denied")
var ErrEmptyShowcase = errors.New("empty showcase slot")

// Signed persistent owned-instance references; fixed order and holes are durable.
type Selection [ShowcaseSlots]int64

func (s Selection) Validate() error {
	for _, id := range s {
		if id < -9007199254740991 || id > 9007199254740991 {
			return ErrSelection
		}
	}
	return nil
}

// Decoded edge values must retain exact JSON numbers. Never convert a rounded float.
func ParseSelection(v any) (Selection, error) {
	var out Selection
	a, ok := v.([]any)
	if !ok || len(a) != ShowcaseSlots {
		return out, ErrSelection
	}
	for i, x := range a {
		n, ok := x.(json.Number)
		if !ok {
			return Selection{}, ErrSelection
		}
		id, e := finitejson.ExactInteger(n)
		if e != nil {
			return Selection{}, ErrSelection
		}
		out[i] = id
	}
	return out, nil
}
func ParseShowcaseIndex(v any) (int, error) {
	n, ok := v.(json.Number)
	if !ok {
		return 0, ErrSelection
	}
	i, e := finitejson.ExactInteger(n)
	if e != nil || i < 1 || i > 6 {
		return 0, ErrSelection
	}
	return int(i), nil
}

type ShowcaseStore interface {
	ReadSelectionTx(context.Context, tx.Queryer, identity.PlayerID) (Selection, error)
	ReplaceSelectionTx(context.Context, tx.Tx, identity.PlayerID, Selection) error
	ReferencesHeroTx(context.Context, tx.Queryer, identity.PlayerID, int64) (bool, error)
	ReferencesPetTx(context.Context, tx.Queryer, identity.PlayerID, int64) (bool, error)
}
type ShowcaseContentPolicy struct {
	Revision string
	Policy   builtin.PublicShowcasePolicy
}

func (p ShowcaseContentPolicy) Validate() error {
	if characterasset.ValidateExactRevisionID(p.Revision) != nil || p.Policy.Validate() != nil {
		return ErrContent
	}
	return nil
}

type ShowcaseContentReader interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	ReadPublicShowcasePolicy(context.Context, tx.Queryer, string) (ShowcaseContentPolicy, error)
}
type ShowcaseBases interface {
	characterasset.HeroBaseObservationProvider
	characterasset.PetBaseObservationProvider
}
type ShowcaseReferences interface {
	characterasset.HeroReferenceOwner
	characterasset.PetReferenceOwner
}

// Entire lock plan is built before acquisition. Root315 and391 precede Character keys.
func selectionKeys(pid identity.PlayerID, s Selection, owners ShowcaseReferences) ([]lockkey.Key, error) {
	if !pid.Valid() || s.Validate() != nil || owners == nil {
		return nil, ErrSelection
	}
	keys := []lockkey.Key{}
	for _, id := range s {
		var k lockkey.Key
		var e error
		if id > 0 {
			k, e = owners.HeroReferenceLockKey(character.HeroRef{PlayerID: pid, PartnerID: id})
		} else if id < 0 {
			k, e = owners.PetReferenceLockKey(character.PetRef{PlayerID: pid, PetID: -id})
		} else {
			continue
		}
		if e != nil {
			return nil, e
		}
		var expected lockkey.Key
		if id > 0 {
			expected, e = characterasset.HeroReferenceLockKey(character.HeroRef{PlayerID: pid, PartnerID: id})
		} else {
			expected, e = characterasset.PetReferenceLockKey(character.PetRef{PlayerID: pid, PetID: -id})
		}
		if e != nil || lockkey.Compare(expected, k) != 0 {
			return nil, ErrSelection
		}
		keys = append(keys, k)
	}
	return lockkey.Canonical(keys)
}
func lockSelection(c context.Context, t tx.Tx, pid identity.PlayerID, keys []lockkey.Key, owners ShowcaseReferences) error {
	for _, k := range keys {
		if ref, e := characterasset.HeroReferenceFromLockKey(k); e == nil {
			if ref.PlayerID != pid {
				return ErrSelection
			}
			if e = owners.LockHeroReferenceKeyTx(c, t, k, ref); e != nil {
				return e
			}
		} else if ref, e := characterasset.PetReferenceFromLockKey(k); e == nil {
			if ref.PlayerID != pid {
				return ErrSelection
			}
			if e = owners.LockPetReferenceKeyTx(c, t, k, ref); e != nil {
				return e
			}
		} else {
			return ErrSelection
		}
	}
	return nil
}
func validateSelectionRefs(c context.Context, q tx.Queryer, pid identity.PlayerID, s Selection, b ShowcaseBases) error {
	if b == nil {
		return ErrShowcaseUnavailable
	}
	seen := map[struct {
		family   string
		template int64
	}]bool{}
	for _, id := range s {
		var family string
		var table int64
		if id > 0 {
			ref := character.HeroRef{PlayerID: pid, PartnerID: id}
			o, e := b.HeroBaseObservationTx(c, q, pid, id)
			if e != nil {
				return e
			}
			if o.Validate() != nil || o.Ref != ref {
				return ErrSelection
			}
			family = "hero"
			table = o.TableID
		} else if id < 0 {
			ref := character.PetRef{PlayerID: pid, PetID: -id}
			o, e := b.PetBaseObservationTx(c, q, pid, -id)
			if e != nil {
				return e
			}
			if o.Validate() != nil || o.Ref != ref {
				return ErrSelection
			}
			family = "pet"
			table = o.TableID
		} else {
			continue
		}
		key := struct {
			family   string
			template int64
		}{family, table}
		if seen[key] {
			return ErrSelection
		}
		seen[key] = true
	}
	return nil
}

// Receipt decoding keeps the same exact six-number grammar as the typed edge.
func (s *Selection) UnmarshalJSON(raw []byte) error {
	d := json.NewDecoder(bytes.NewReader(raw))
	d.UseNumber()
	var v any
	if e := d.Decode(&v); e != nil {
		return e
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return ErrSelection
	}
	q, e := ParseSelection(v)
	if e != nil {
		return e
	}
	*s = q
	return nil
}
