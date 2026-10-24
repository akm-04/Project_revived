package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

// BookCatalogTx reads only the caller-pinned immutable revision. Registration
// and controlled deployment/backfill must complete before activation.
func (s Store) BookCatalogTx(ctx context.Context, q tx.Queryer, revision string) (book.Catalog, error) {
	var out book.Catalog
	if q == nil || len(revision) != 64 {
		return out, book.ErrUnqualified
	}
	var manifest, raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return out, e
	}
	good, e := manifestHasCapability([]byte(manifest), revision, "BOOK_INPUTS_I7C2D")
	if e != nil {
		return out, e
	}
	if !good {
		return out, book.ErrUnqualified
	}
	if e = q.QueryRow(ctx, `SELECT payload::text FROM content_book_input_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
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
	hash := sha256.Sum256(append(canonical, 10))
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["book_input_catalog.json"] {
		return out, book.ErrUnqualified
	}
	var dto builtin.BookInputCatalog
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&dto); e != nil {
		return out, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, book.ErrUnqualified
	}
	return bookCatalogDomain(dto)
}
func bookCatalogDomain(d builtin.BookInputCatalog) (book.Catalog, error) {
	out := book.Catalog{Buildings: map[[2]int64]book.BookBuildingRule{}, Books: map[int64]book.BookRule{}, Skills: map[int64]book.BookSkillRule{}, Costs: map[[2]int64]book.BookCostRule{}}
	if e := d.Validate(); e != nil {
		return out, e
	}
	// DTO and domain types are independent; normalized source fields are copied explicitly.
	for _, r := range d.Buildings {
		key := [2]int64{r.Type, r.Level}
		if _, ok := out.Buildings[key]; ok {
			return out, book.ErrUnqualified
		}
		out.Buildings[key] = book.BookBuildingRule{Type: r.Type, Level: r.Level, Duration: r.Duration, RequiresType: r.RequiresType, RequiresLevel: r.RequiresLevel, CutTime: r.CutTime, UpperLimit: r.UpperLimit, Resources: r.Resources, Attributes: r.Attributes}
	}
	for _, r := range d.Books {
		if _, ok := out.Books[r.ID]; ok {
			return out, book.ErrUnqualified
		}
		out.Books[r.ID] = book.BookRule{ID: r.ID, Star: r.Star, Type: r.Type, Piece: r.Piece, PieceCount: r.PieceCount, SkillPage: r.SkillPage, Skills: r.Skills}
	}
	for _, r := range d.Skills {
		if _, ok := out.Skills[r.ID]; ok {
			return out, book.ErrUnqualified
		}
		out.Skills[r.ID] = book.BookSkillRule{ID: r.ID, Book: r.Book, Partner: r.Partner, CostClass: r.CostClass, AttrID: r.AttrID, ActionType: r.ActionType, Value: r.Value, Times: r.Times, Prerequisites: r.Prerequisites}
	}
	for _, r := range d.Costs {
		key := [2]int64{r.Class, r.Level}
		if _, ok := out.Costs[key]; ok {
			return out, book.ErrUnqualified
		}
		out.Costs[key] = book.BookCostRule{Level: r.Level, Class: r.Class, Resources: r.Resources, Pages: r.Pages}
	}
	return out, out.Validate()
}
func (Store) InsertBookInputs(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_book_input_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.BookInputsJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyBookInputsSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_book_input_catalogs WHERE revision_id=$1`

func (s Store) BookInputsActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, book.ErrUnqualified
	}
	a, ok, e := s.ReadActiveSummary(ctx, s.Queryer)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "BOOK_INPUTS_I7C2D")
	return a.Activation.RevisionID, good, e
}

func (Store) BookInputsRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	var raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(raw), revision, "BOOK_INPUTS_I7C2D")
}

func (s Store) BookInputsActiveTx(ctx context.Context, q tx.Queryer) (string, bool, error) {
	a, ok, e := s.ReadActiveSummary(ctx, q)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "BOOK_INPUTS_I7C2D")
	return a.Activation.RevisionID, good, e
}
