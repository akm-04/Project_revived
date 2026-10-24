package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) InsertLibraryInputs(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_library_input_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.LibraryInputsJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyLibraryInputsSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_library_input_catalogs WHERE revision_id=$1`

func (s Store) LibraryInputsActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, library.ErrUnqualified
	}
	a, ok, e := s.ReadActiveSummary(ctx, s.Queryer)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "LIBRARY_INPUTS_I7C2B")
	return a.Activation.RevisionID, good, e
}

// LibraryCatalogTx resolves exact captured content through the caller's queryer.
// It neither discovers current time/activation nor opens another transaction.
func (s Store) LibraryCatalogTx(ctx context.Context, q tx.Queryer, revision string) (library.Catalog, error) {
	var out library.Catalog
	if q == nil || !library.ValidRevision(revision) {
		return out, library.ErrUnqualified
	}
	var manifest, raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return out, e
	}
	good, e := manifestHasCapability([]byte(manifest), revision, "LIBRARY_INPUTS_I7C2B")
	if e != nil {
		return out, e
	}
	if !good {
		return out, library.ErrUnqualified
	}
	if e = q.QueryRow(ctx, `SELECT payload::text FROM content_library_input_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return out, e
	}
	var generic any
	if e = json.Unmarshal([]byte(raw), &generic); e != nil {
		return out, e
	}
	canonical, e := json.Marshal(generic)
	if e != nil {
		return out, e
	}
	sum := sha256.Sum256(append(canonical, 10))
	if hex.EncodeToString(sum[:]) != m.ArtifactSHA256s["library_input_catalog.json"] {
		return out, library.ErrUnqualified
	}
	var payload builtin.LibraryInputCatalog
	d := json.NewDecoder(bytes.NewBufferString(raw))
	d.DisallowUnknownFields()
	if e = d.Decode(&payload); e != nil {
		return out, e
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return out, library.ErrUnqualified
	}
	return libraryCatalogDomain(payload, revision)
}

func (s Store) LibraryInputsRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	var manifest string
	if q == nil || !library.ValidRevision(revision) {
		return false, library.ErrUnqualified
	}
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(manifest), revision, "LIBRARY_INPUTS_I7C2B")
}

type libraryDomainPayload struct {
	Templates          []library.TemplateRule          `json:"templates"`
	Gifts              []library.GiftRule              `json:"gifts"`
	Feeding            library.FeedRules               `json:"feeding"`
	NormalCollections  []library.NormalCollectionRule  `json:"normal_collections"`
	SpecialCollections []library.SpecialCollectionRule `json:"special_collections"`
}

func libraryCatalogDomain(payload builtin.LibraryInputCatalog, revision string) (library.Catalog, error) {
	var out library.Catalog
	if !library.ValidRevision(revision) || payload.Validate() != nil {
		return out, library.ErrUnqualified
	}
	raw, e := json.Marshal(payload)
	if e != nil {
		return out, e
	}
	var c libraryDomainPayload
	if e = json.Unmarshal(raw, &c); e != nil {
		return out, e
	}
	if c.Feeding.Validate() != nil {
		return out, library.ErrUnqualified
	}
	out = library.Catalog{ContentRevision: revision, Templates: map[int64]library.TemplateRule{}, Gifts: map[int64]library.GiftRule{}, Feeding: c.Feeding, NormalCollections: map[int64]library.NormalCollectionRule{}}
	for _, r := range c.Templates {
		out.Templates[r.TableID] = r
	}
	for _, r := range c.Gifts {
		out.Gifts[r.ItemID] = r
	}
	for _, r := range c.NormalCollections {
		r.QualityThresholds = append([]int64(nil), r.QualityThresholds...)
		r.QualityHundredths = append([]int64(nil), r.QualityHundredths...)
		r.StarThresholds = append([]int64(nil), r.StarThresholds...)
		r.StarHundredths = append([]int64(nil), r.StarHundredths...)
		out.NormalCollections[r.SourceID] = r
	}
	for i, r := range c.SpecialCollections {
		r.RequiredSourceIDs = append([]int64(nil), r.RequiredSourceIDs...)
		out.SpecialCollections[i] = r
	}
	return out, nil
}
