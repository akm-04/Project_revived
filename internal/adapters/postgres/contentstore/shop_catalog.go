package contentstore

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strconv"
	"sync"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	d "gxb.local/backend/v2/internal/domain/shop"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var shopCatalogs sync.Map

const verifyShopSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_shop_catalogs WHERE revision_id=$1`

// ShopCatalogTx loads the exact-revision shop catalog, verifying the manifest
// capability and the artifact hash before decoding.
func (s Store) ShopCatalogTx(ctx context.Context, q tx.Queryer, revision string) (d.Catalog, error) {
	return memoCatalog(&shopCatalogs, revision, func() (d.Catalog, error) {
		return s.shopCatalogTx(ctx, q, revision)
	})
}

func (s Store) shopCatalogTx(ctx context.Context, q tx.Queryer, revision string) (d.Catalog, error) {
	var out d.Catalog
	if q == nil || len(revision) != 64 {
		return out, d.ErrUnavailable
	}
	var manifest, raw string
	var version int16
	if err := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); err != nil {
		return out, err
	}
	m, err := registry.DecodeManifestStrict([]byte(manifest))
	if err != nil {
		return out, err
	}
	good, err := manifestHasCapability([]byte(manifest), revision, "CORE_SHOPS_I9_11C")
	if err != nil {
		return out, err
	}
	if !good {
		return out, fmt.Errorf("%w: content capability is not active", d.ErrUnavailable)
	}
	if err = q.QueryRow(ctx, `SELECT payload::text, payload_version FROM content_shop_catalogs WHERE revision_id=$1`, revision).Scan(&raw, &version); err != nil {
		return out, err
	}
	var generic any
	if err = json.Unmarshal([]byte(raw), &generic); err != nil {
		return out, err
	}
	canonical, err := json.Marshal(generic)
	if err != nil {
		return out, err
	}
	hash := sha256.Sum256(append(canonical, 10))
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["shop_catalog.json"] {
		return out, fmt.Errorf("%w: shop artifact hash drift", d.ErrUnavailable)
	}
	var dto builtin.ShopCatalog
	if err = payload.Decode("content_shop_catalogs", version, []byte(raw), &dto); err != nil {
		return out, err
	}
	return shopCatalogDomain(dto, revision)
}

func shopCatalogDomain(dto builtin.ShopCatalog, revision string) (d.Catalog, error) {
	out := d.Catalog{
		Revision:    revision,
		Shops:       make(map[int64]d.Shop, len(dto.Shops)),
		StockTables: make(map[string][]d.SourceRow, len(dto.StockTables)),
		Groups:      make(map[int64][]d.Roll, len(dto.Groups)),
		RefreshCost: make(map[string][]int64, len(dto.RefreshCost)),
		Tunables: d.Tunables{
			StoneSubstituteItem: dto.Tunables.StoneSubstituteItem,
			CubeCurrencyItem:    dto.Tunables.CubeCurrencyItem,
			DiscountMillionths:  dto.Tunables.DiscountMillionths,
			MonthCardMillionths: dto.Tunables.MonthCardMillionths,
			LevelPoolRows:       dto.Tunables.LevelPoolRows,
		},
	}
	if err := builtin.QualifyShopCatalog(dto); err != nil {
		return out, fmt.Errorf("%w: %v", d.ErrUnavailable, err)
	}
	for _, shop := range dto.Shops {
		out.Shops[shop.Type] = d.Shop{
			Type: shop.Type, FunctionID: shop.FunctionID, Team: shop.IsTeamShop == 1,
			SlotNum: shop.SlotNum, RefreshType: shop.RefreshType, RefreshKey: shop.RefreshKey,
			RefreshTimes: append([]int64(nil), shop.RefreshTimes...), Table: shop.ShopTable,
			Alone: shop.IsAlone == 1, Unlimit: shop.IsUnlimit == 1,
			AutoRefresh: shop.AutoRefresh, HomologousID: shop.TeamDungeonHomologousID,
		}
	}
	for table, stock := range dto.StockTables {
		rows := make([]d.SourceRow, 0, len(stock.Rows))
		for _, row := range stock.Rows {
			source := d.SourceRow{ID: row.ID, Slots: make([]d.SourceSlot, 0, len(row.Slots))}
			for _, slot := range row.Slots {
				groups := make([]d.Group, 0, len(slot.Groups))
				for _, group := range slot.Groups {
					groups = append(groups, d.Group{DropboxID: group.DropboxID, Weight: group.Weight})
				}
				source.Slots = append(source.Slots, d.SourceSlot{Groups: groups})
			}
			rows = append(rows, source)
		}
		out.StockTables[table] = rows
	}
	for key, rolls := range dto.Groups {
		groupID, err := strconv.ParseInt(key, 10, 64)
		if err != nil {
			return out, d.ErrUnavailable
		}
		converted := make([]d.Roll, 0, len(rolls))
		for _, roll := range rolls {
			converted = append(converted, d.Roll{ItemID: roll.ItemID, ItemNum: roll.ItemNum, SellType: roll.SellType, SellPrice: roll.SellPrice, Discount: roll.Discount, Rate: roll.Rate, StoneID: roll.StoneID})
		}
		out.Groups[groupID] = converted
	}
	for key, ladder := range dto.RefreshCost {
		out.RefreshCost[key] = append([]int64(nil), ladder...)
	}
	return out, nil
}

// InsertShop stores the exact compiled bundle in the migration-00175 table.
func (Store) InsertShop(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, err := t.Exec(ctx, `INSERT INTO content_shop_catalogs(revision_id,payload,payload_version)VALUES($1,$2::jsonb,$3)`, b.RevisionID(), string(b.ShopJSON()), payload.Current)
	if err != nil {
		return 0, err
	}
	return tag.RowsAffected(), nil
}
