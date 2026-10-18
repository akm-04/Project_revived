package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	achievement "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

// AchievementCatalogTx reads only the caller-pinned immutable revision. Registration
// and controlled deployment/backfill must complete before activation.
func (s Store) AchievementCatalogTx(ctx context.Context, q tx.Queryer, revision string) (achievement.Catalog, error) {
	var out achievement.Catalog
	if q == nil || len(revision) != 64 {
		return out, achievement.ErrUnavailable
	}
	var manifest, raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return out, e
	}
	good, e := manifestHasCapability([]byte(manifest), revision, "ACHIEVEMENT_TIER_FACTS_I7C4B")
	if e != nil {
		return out, e
	}
	if !good {
		return out, achievement.ErrUnavailable
	}
	if e = q.QueryRow(ctx, `SELECT payload::text FROM content_achievement_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
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
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["achievement_catalog.json"] {
		return out, achievement.ErrUnavailable
	}
	var dto builtin.AchievementCatalog
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&dto); e != nil {
		return out, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, achievement.ErrUnavailable
	}
	return achievementCatalogDomain(dto)
}
func achievementCatalogDomain(d builtin.AchievementCatalog) (achievement.Catalog, error) {
	out := achievement.Catalog{SchemaVersion: d.SchemaVersion, PolicyID: d.PolicyID, SelectedID: d.SelectedID}
	for _, r := range d.Rows {
		out.Rows = append(out.Rows, achievement.Definition{ID: r.ID, Thresholds: r.Thresholds, Points: r.Points, Daily: r.Daily, Hidden: r.Hidden, Stamp: r.Stamp})
	}
	return out, out.Validate()
}
func (Store) InsertAchievement(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_achievement_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.AchievementJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyAchievementSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_achievement_catalogs WHERE revision_id=$1`

func (s Store) AchievementActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, achievement.ErrUnavailable
	}
	a, ok, e := s.ReadActiveSummary(ctx, s.Queryer)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "ACHIEVEMENT_TIER_FACTS_I7C4B")
	return a.Activation.RevisionID, good, e
}

func (Store) AchievementRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	var raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(raw), revision, "ACHIEVEMENT_TIER_FACTS_I7C4B")
}

func (s Store) AchievementActiveTx(ctx context.Context, q tx.Queryer) (string, bool, error) {
	a, ok, e := s.ReadActiveSummary(ctx, q)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "ACHIEVEMENT_TIER_FACTS_I7C4B")
	return a.Activation.RevisionID, good, e
}
