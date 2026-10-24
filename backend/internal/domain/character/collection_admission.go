package character

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// This is an explicit current-client preservation policy. It is not the
// unrecovered legacy purchased-slot algorithm and does not price an expansion.
const CollectionAdmissionPolicy = "C4C_PRIVATE_CURRENT_CLIENT_COLLECTION_ADMISSION_V1"
const CollectionAdmissionPolicyRef = "hero-collection-admission"

var ErrCollectionAdmission = errors.New("character hero: unqualified collection admission")

type CollectionAdmissionProof struct {
	PolicyID, Revision, CatalogDigest, PopulationDigest string
	Player                                              identity.PlayerID
	OriginTableID, RootVersion                          int64
	CatalogCount, OwnedCount, RetainedLegacyCount       int64
	UnionLimit, ResultCount                             int64
	DecisionAt                                          time.Time
}

func collectionRevision(s string) bool {
	b, e := hex.DecodeString(s)
	return e == nil && len(b) == 32 && hex.EncodeToString(b) == s
}
func collectionDigest(ids []int64) string {
	b, _ := json.Marshal(ids)
	h := sha256.Sum256(b)
	return hex.EncodeToString(h[:])
}
func (p CollectionAdmissionProof) Validate() error {
	if p.PolicyID != CollectionAdmissionPolicy || !p.Player.Valid() || !collectionRevision(p.Revision) || !collectionRevision(p.CatalogDigest) || !collectionRevision(p.PopulationDigest) || p.OriginTableID <= 0 || p.OriginTableID > 9007199254740991 || p.RootVersion < 1 || p.DecisionAt.Unix() <= 0 || p.CatalogCount < 1 || p.OwnedCount < 0 || p.RetainedLegacyCount < 0 || p.RetainedLegacyCount > p.OwnedCount || p.CatalogCount > 9007199254740991-p.RetainedLegacyCount || p.UnionLimit != p.CatalogCount+p.RetainedLegacyCount || p.OwnedCount >= 9007199254740991 || p.ResultCount != p.OwnedCount+1 || p.ResultCount > p.UnionLimit {
		return ErrCollectionAdmission
	}
	return nil
}

// AdmitCollectionOrigin uses finite pinned catalog membership and canonical
// unique origins. Retained historic owned origins do not consume a fabricated
// purchased-slot budget. The caller supplies owned state under HeroRoot400.
func AdmitCollectionOrigin(player identity.PlayerID, rootVersion int64, revision string, at time.Time, catalog, owned []int64, candidate int64) (CollectionAdmissionProof, error) {
	out := CollectionAdmissionProof{PolicyID: CollectionAdmissionPolicy, Player: player, RootVersion: rootVersion, Revision: revision, DecisionAt: at.UTC(), OriginTableID: candidate}
	if !player.Valid() || rootVersion < 1 || !collectionRevision(revision) || at.Unix() <= 0 || len(catalog) == 0 {
		return out, ErrCollectionAdmission
	}
	known, existing := map[int64]bool{}, map[int64]bool{}
	for _, id := range catalog {
		if id <= 0 || id > 9007199254740991 || known[id] {
			return out, ErrCollectionAdmission
		}
		known[id] = true
	}
	for _, id := range owned {
		if id <= 0 || id > 9007199254740991 || existing[id] {
			return out, ErrCollectionAdmission
		}
		existing[id] = true
		if !known[id] {
			out.RetainedLegacyCount++
		}
	}
	if !known[candidate] || existing[candidate] {
		return out, ErrCollectionAdmission
	}
	catalog = append([]int64{}, catalog...)
	owned = append([]int64{}, owned...)
	sort.Slice(catalog, func(i, j int) bool { return catalog[i] < catalog[j] })
	sort.Slice(owned, func(i, j int) bool { return owned[i] < owned[j] })
	out.CatalogDigest, out.PopulationDigest = collectionDigest(catalog), collectionDigest(owned)
	out.CatalogCount, out.OwnedCount = int64(len(catalog)), int64(len(owned))
	out.UnionLimit, out.ResultCount = out.CatalogCount+out.RetainedLegacyCount, out.OwnedCount+1
	return out, out.Validate()
}
