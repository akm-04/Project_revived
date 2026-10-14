package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	course "gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

// CourseCatalogTx reads only the caller-pinned immutable revision. Registration
// and controlled deployment/backfill must complete before activation.
func (s Store) CourseCatalogTx(ctx context.Context, q tx.Queryer, revision string) (course.Catalog, error) {
	var out course.Catalog
	if q == nil || len(revision) != 64 {
		return out, course.ErrUnqualified
	}
	var manifest, raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return out, e
	}
	good, e := manifestHasCapability([]byte(manifest), revision, "COURSE_INPUTS_I7C2E")
	if e != nil {
		return out, e
	}
	if !good {
		return out, course.ErrUnqualified
	}
	if e = q.QueryRow(ctx, `SELECT payload::text FROM content_course_input_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
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
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["course_input_catalog.json"] {
		return out, course.ErrUnqualified
	}
	var dto builtin.CourseInputCatalog
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&dto); e != nil {
		return out, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, course.ErrUnqualified
	}
	return courseCatalogDomain(dto)
}
func courseCatalogDomain(d builtin.CourseInputCatalog) (course.Catalog, error) {
	var out course.Catalog
	if e := d.Validate(); e != nil {
		return out, e
	}
	raw, e := json.Marshal(d)
	if e != nil {
		return out, e
	}
	if e = json.Unmarshal(raw, &out); e != nil {
		return out, e
	}
	return out, out.Validate()
}
func (Store) InsertCourseInputs(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_course_input_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.CourseInputsJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyCourseInputsSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_course_input_catalogs WHERE revision_id=$1`

func (s Store) CourseInputsActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, course.ErrUnqualified
	}
	a, ok, e := s.ReadActiveSummary(ctx, s.Queryer)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "COURSE_INPUTS_I7C2E")
	return a.Activation.RevisionID, good, e
}

func (Store) CourseInputsRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	var raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(raw), revision, "COURSE_INPUTS_I7C2E")
}

func (s Store) CourseInputsActiveTx(ctx context.Context, q tx.Queryer) (string, bool, error) {
	a, ok, e := s.ReadActiveSummary(ctx, q)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "COURSE_INPUTS_I7C2E")
	return a.Activation.RevisionID, good, e
}
