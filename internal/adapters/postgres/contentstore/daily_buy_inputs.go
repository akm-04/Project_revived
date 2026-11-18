package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"sync"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	itemsenergy "gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var dailyBuyCatalogs sync.Map

func (s Store) DailyBuyInputsTx(ctx context.Context, q tx.Queryer, revision string) (itemsenergy.Catalog, error) {
	return memoCatalog(&dailyBuyCatalogs, revision, func() (itemsenergy.Catalog, error) {
		return s.dailyBuyInputsTx(ctx, q, revision)
	})
}

func (s Store) dailyBuyInputsTx(ctx context.Context, q tx.Queryer, revision string) (itemsenergy.Catalog, error) {
	var out itemsenergy.Catalog
	if q == nil || len(revision) != 64 {
		return out, itemsenergy.ErrUnavailable
	}
	var manifest, raw string
	if err := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); err != nil {
		return out, err
	}
	m, err := registry.DecodeManifestStrict([]byte(manifest))
	if err != nil {
		return out, err
	}
	good, err := manifestHasCapability([]byte(manifest), revision, "DAILY_BUY_INPUTS_I9_11B")
	if err != nil {
		return out, err
	}
	if !good {
		return out, itemsenergy.ErrUnavailable
	}
	if err = q.QueryRow(ctx, `SELECT payload::text FROM content_daily_buy_input_catalogs WHERE revision_id=$1`, revision).Scan(&raw); err != nil {
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
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["daily_buy_input_catalog.json"] {
		return out, itemsenergy.ErrUnavailable
	}
	var dto builtin.DailyBuyInputCatalog
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if err = dec.Decode(&dto); err != nil {
		return out, err
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, itemsenergy.ErrUnavailable
	}
	return dailyBuyCatalogDomain(dto, revision)
}

func dailyBuyCatalogDomain(dto builtin.DailyBuyInputCatalog, revision string) (itemsenergy.Catalog, error) {
	out := itemsenergy.Catalog{
		Revision:     revision,
		Items:        make(map[int64]itemsenergy.Item, len(dto.Items)),
		Gifts:        make(map[int64]itemsenergy.Gift, len(dto.Gifts)),
		Dropboxes:    make(map[int64]itemsenergy.Dropbox, len(dto.Dropboxes)),
		VIP:          make(map[int64]itemsenergy.VIPRow, len(dto.VIP)),
		RefreshCost:  make(map[int64]itemsenergy.RefreshCost, len(dto.RefreshCost)),
		DailyConsume: make(map[int64]itemsenergy.DailyConsume, len(dto.DailyConsume)),
	}
	if err := dto.QualifyDailyBuyInputs(); err != nil {
		return out, itemsenergy.ErrUnavailable
	}
	for _, item := range dto.Items {
		out.Items[item.ID] = itemsenergy.Item{
			ID: item.ID, Type: item.Type, SubType: item.SubType, Stack: item.Stack,
			Energy: item.Energy, SkillPoint: item.SkillPoint, Mana: item.Mana, Crystal: item.Crystal,
			MagicEnergy: item.MagicEnergy, MagicDust: item.MagicDust, MagicLiquid: item.MagicLiquid,
			Level: item.Level, Gifts: append([]int64(nil), item.Gifts...), OneInMore: append([]int64(nil), item.OneInMore...),
		}
	}
	for _, gift := range dto.Gifts {
		row := itemsenergy.Gift{
			ID: gift.ID, Items: append([]int64(nil), gift.Items...), ItemNums: append([]int64(nil), gift.ItemNums...),
			Drops: append([]int64(nil), gift.Drops...), Equip: gift.Equip, SummonID: gift.SummonID,
			Crystal: gift.Crystal, Mana: gift.Mana, Energy: gift.Energy, VipExp: gift.VipExp,
			ArenaCoin: gift.ArenaCoin, MarchCoin: gift.MarchCoin, LuckyCoin: gift.LuckyCoin,
			FriendshipCoin: gift.FriendshipCoin, SkinFragment: gift.SkinFragment, Exp: gift.Exp,
			Badge: gift.Badge, Soul: gift.Soul, Vip: gift.Vip, ExBadge: gift.ExBadge,
			TutorCoin: gift.TutorCoin, SkinCoin: gift.SkinCoin, SpiritEnergy: gift.SpiritEnergy,
		}
		out.Gifts[row.ID] = row
	}
	for _, box := range dto.Dropboxes {
		row := itemsenergy.Dropbox{ID: box.ID, Rolls: make([]itemsenergy.DropRoll, 0, len(box.Rolls))}
		for _, roll := range box.Rolls {
			row.Rolls = append(row.Rolls, itemsenergy.DropRoll{ID: roll.ID, ItemID: roll.ItemID, ItemNum: roll.ItemNum, Rate: roll.Rate, RollType: roll.RollType})
		}
		out.Dropboxes[row.ID] = row
	}
	for _, vip := range dto.VIP {
		out.VIP[vip.Level] = itemsenergy.VIPRow{Level: vip.Level, NumEnergy: vip.NumEnergy, NumMidas: vip.NumMidas}
	}
	out.Monthly = itemsenergy.MonthlyPrivilege{NumEnergy: dto.MonthlyPrivilege.NumEnergy, NumMidas: dto.MonthlyPrivilege.NumMidas}
	for _, cost := range dto.RefreshCost {
		out.RefreshCost[cost.ID] = itemsenergy.RefreshCost{ID: cost.ID, BuyEnergyCost: cost.BuyEnergyCost, BuyManaCost: cost.BuyManaCost, BuyManaRatioMillionths: cost.BuyManaRatioMillionths}
	}
	out.Misc = itemsenergy.Misc{
		BuyEnergyNum: dto.Misc.BuyEnergyNum, EnergyMaxLimit: dto.Misc.EnergyMaxLimit,
		MidasBase: dto.Misc.MidasBase, MidasLevelIncrease: dto.Misc.MidasLevelIncrease,
		MidasFloatUpBasisPoints:   dto.Misc.MidasFloatUpBasisPoints,
		MidasFloatDownBasisPoints: dto.Misc.MidasFloatDownBasisPoints,
		MidasCritTypes:            append([]int64(nil), dto.Misc.MidasCritTypes...),
		MidasCritRates:            append([]int64(nil), dto.Misc.MidasCritRates...),
	}
	for _, rule := range dto.DailyConsume {
		out.DailyConsume[rule.ID] = itemsenergy.DailyConsume{ID: rule.ID, Cost: rule.Cost, Num: rule.Num, Value: rule.Value}
	}
	return out, out.Validate()
}

func (Store) InsertDailyBuyInputs(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, err := t.Exec(ctx, `INSERT INTO content_daily_buy_input_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.DailyBuyInputsJSON()))
	if err != nil {
		return 0, err
	}
	return tag.RowsAffected(), nil
}

const verifyDailyBuyInputsSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_daily_buy_input_catalogs WHERE revision_id=$1`

func (s Store) DailyBuyInputsActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, itemsenergy.ErrUnavailable
	}
	return s.dailyBuyInputsActiveTx(ctx, s.Queryer)
}

func (s Store) DailyBuyInputsActiveTx(ctx context.Context, q tx.Queryer) (string, bool, error) {
	return s.dailyBuyInputsActiveTx(ctx, q)
}

func (Store) dailyBuyInputsActiveTx(ctx context.Context, q tx.Queryer) (string, bool, error) {
	summary, ok, err := (Store{}).ReadActiveSummary(ctx, q)
	if err != nil || !ok {
		return "", false, err
	}
	good, err := manifestHasCapability(summary.ManifestJSON, summary.Activation.RevisionID, "DAILY_BUY_INPUTS_I9_11B")
	if err != nil || !good {
		return "", false, err
	}
	if _, err = (Store{}).DailyBuyInputsRevisionTx(ctx, q, summary.Activation.RevisionID); err != nil {
		return "", false, err
	}
	return summary.Activation.RevisionID, true, nil
}

func (Store) DailyBuyInputsRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	var ok bool
	if err := q.QueryRow(ctx, `SELECT count(*)=1 FROM content_daily_buy_input_catalogs WHERE revision_id=$1`, revision).Scan(&ok); err != nil {
		return false, err
	}
	return ok, nil
}
