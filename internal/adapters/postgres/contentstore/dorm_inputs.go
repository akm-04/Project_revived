package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

// DormCatalogTx reads only the caller-pinned immutable revision. Registration
// and controlled deployment/backfill must complete before activation.
func (s Store) DormCatalogTx(ctx context.Context, q tx.Queryer, revision string) (dorm.Catalog, error) {
	var out dorm.Catalog
	if q == nil || len(revision) != 64 {
		return out, dorm.ErrUnqualified
	}
	var manifest, raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return out, e
	}
	good, e := manifestHasCapability([]byte(manifest), revision, "DORM_INPUTS_I7C2C")
	if e != nil {
		return out, e
	}
	if !good {
		return out, dorm.ErrUnqualified
	}
	if e = q.QueryRow(ctx, `SELECT payload::text FROM content_dorm_input_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
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
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["dorm_input_catalog.json"] {
		return out, dorm.ErrUnqualified
	}
	var dto builtin.DormInputCatalog
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&dto); e != nil {
		return out, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, dorm.ErrUnqualified
	}
	return dormCatalogDomain(dto)
}
func dormCatalogDomain(d builtin.DormInputCatalog) (dorm.Catalog, error) {
	var out dorm.Catalog
	if e := d.Validate(); e != nil {
		return out, e
	}
	out = dorm.Catalog{ExchangeRates: map[int64]int64{}, Rooms: map[int64]dorm.RoomRule{}, Types: map[int64]dorm.TypeRule{}, Keys: map[int64]dorm.KeyRule{}, Expansions: map[int64]dorm.ExpansionRule{}, Equipment: map[int64]dorm.EquipmentRule{}, Furniture: map[int64]dorm.FurnitureRule{}, EquipmentLevel: map[int64]int64{}}
	for _, r := range d.ExchangeKeys {
		if r.ItemID <= 0 || r.CementPerKey <= 0 || out.ExchangeRates[r.ItemID] != 0 {
			return out, dorm.ErrUnqualified
		}
		out.ExchangeRates[r.ItemID] = r.CementPerKey
	}
	for _, r := range d.Rooms {
		x := dorm.RoomRule{TableID: r.TableID, MainType: r.MainType, AttributeType: r.AttributeType, Length: r.Length, Width: r.Width, Height: r.Height, Dresser: r.Dresser}
		for _, t := range r.Growth {
			x.Growth = append(x.Growth, dorm.GrowthTier{Comfort: t.Comfort, Attributes: dorm.AttributesBP(t.AttributesBP)})
		}
		out.Rooms[r.TableID] = x
	}
	for _, r := range d.Types {
		out.Types[r.MainType] = dorm.TypeRule{MainType: r.MainType, Residents: r.Residents, MaxExpansion: r.MaxExpansion}
	}
	for _, r := range d.Keys {
		out.Keys[r.ItemID] = dorm.KeyRule{ItemID: r.ItemID, MainType: r.MainType, Templates: append([]int64(nil), r.Templates...)}
	}
	for _, r := range d.Expansions {
		x := dorm.ExpansionRule{Level: r.Level, Area: r.Area, Comfort: r.Comfort, DurationSeconds: r.DurationSeconds, CostItems: append([]int64(nil), r.CostItems...), CostCounts: append([]int64(nil), r.CostCounts...)}
		for i, a := range r.AttributesBP {
			x.Attributes[i] = dorm.AttributesBP(a)
		}
		out.Expansions[r.Level] = x
	}
	for _, r := range d.HeroEquipment {
		out.Equipment[r.TemplateID] = dorm.EquipmentRule{TemplateID: r.TemplateID, Items: r.Items}
	}
	for _, r := range d.EquipmentItems {
		out.EquipmentLevel[r.ItemID] = r.RequiredLevel
	}
	for _, r := range d.Furniture {
		out.Furniture[r.ItemID] = dorm.FurnitureRule{ItemID: r.ItemID, Comfort: r.Comfort, Floor: r.Floor, PaperItem: r.PaperItem, SpecialType: r.SpecialType, Length: r.Length, Width: r.Width, Height: r.Height, CanRotate: r.CanRotate, CanPile: r.CanPile, CanBePile: r.CanBePile, PileLimit: r.PileLimit, Panels: append([]int64(nil), r.Panels...), PileStart: append([]int64(nil), r.PileStart...), PileEnd: append([]int64(nil), r.PileEnd...)}
	}
	return out, nil
}

func (Store) InsertDormInputs(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_dorm_input_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.DormInputsJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyDormInputsSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_dorm_input_catalogs WHERE revision_id=$1`

func (s Store) DormInputsActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, dorm.ErrUnqualified
	}
	a, ok, e := s.ReadActiveSummary(ctx, s.Queryer)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "DORM_INPUTS_I7C2C")
	return a.Activation.RevisionID, good, e
}

func (Store) DormInputsRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	var raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(raw), revision, "DORM_INPUTS_I7C2C")
}
