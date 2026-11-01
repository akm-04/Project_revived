package guildstore

import (
	"context"
	"encoding/json"

	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const rentalOfferColumns = `lender_id,kind,unit_id,guild_id,force,rent_award,rent_time`

func scanRentalOffer(row tx.Row) (guild.RentalOffer, error) {
	var offer guild.RentalOffer
	var lender, gid int64
	var kind string
	err := row.Scan(&lender, &kind, &offer.Unit, &gid, &offer.Force, &offer.RentAward, &offer.RentTime)
	offer.Lender, offer.Kind, offer.Guild = identity.PlayerID(lender), guild.RentalKind(kind), guild.ID(gid)
	return offer, err
}

// LockRentalOfferTx takes one offer at rank 609b.
func (Store) LockRentalOfferTx(ctx context.Context, t tx.Tx, lender identity.PlayerID, kind guild.RentalKind, unit int64) (guild.RentalOffer, bool, error) {
	offer, err := scanRentalOffer(t.QueryRow(ctx, `SELECT `+rentalOfferColumns+` FROM guild_rental_offers WHERE lender_id=$1 AND kind=$2 AND unit_id=$3 FOR UPDATE`, int64(lender), string(kind), unit))
	if noRows(err) {
		return guild.RentalOffer{}, false, nil
	}
	return offer, err == nil, err
}

// LockLenderRentalOffersTx takes all of a lender's offers at rank 609b in lock order.
func (Store) LockLenderRentalOffersTx(ctx context.Context, t tx.Tx, lender identity.PlayerID) ([]guild.RentalOffer, error) {
	var raw string
	err := t.QueryRow(ctx, `WITH locked AS (
		SELECT `+rentalOfferColumns+` FROM guild_rental_offers WHERE lender_id=$1 ORDER BY kind,unit_id FOR UPDATE
	) SELECT COALESCE(jsonb_agg(jsonb_build_object('Lender',lender_id,'Kind',kind,'Unit',unit_id,'Guild',guild_id,'Force',force,'RentAward',rent_award,'RentTime',rent_time) ORDER BY kind,unit_id),'[]')::text FROM locked`, int64(lender)).Scan(&raw)
	if err != nil {
		return nil, err
	}
	offers := []guild.RentalOffer{}
	return offers, json.Unmarshal([]byte(raw), &offers)
}

func (Store) InsertRentalOfferTx(ctx context.Context, t tx.Tx, offer guild.RentalOffer) error {
	_, err := t.Exec(ctx, `INSERT INTO guild_rental_offers(`+rentalOfferColumns+`) VALUES($1,$2,$3,$4,$5,$6,$7)`,
		int64(offer.Lender), string(offer.Kind), offer.Unit, int64(offer.Guild), offer.Force, offer.RentAward, offer.RentTime)
	return err
}

func (Store) DeleteRentalOfferTx(ctx context.Context, t tx.Tx, offer guild.RentalOffer) error {
	_, err := t.Exec(ctx, `DELETE FROM guild_rental_offers WHERE lender_id=$1 AND kind=$2 AND unit_id=$3`, int64(offer.Lender), string(offer.Kind), offer.Unit)
	return err
}

func (Store) AddRentalAwardTx(ctx context.Context, t tx.Tx, offer guild.RentalOffer, amount int64) error {
	_, err := t.Exec(ctx, `UPDATE guild_rental_offers SET rent_award=rent_award+$4 WHERE lender_id=$1 AND kind=$2 AND unit_id=$3`, int64(offer.Lender), string(offer.Kind), offer.Unit, amount)
	return err
}

// LockRentalUseTx takes the pair's use row for the day at rank 609b, if it exists.
func (Store) LockRentalUseTx(ctx context.Context, t tx.Tx, borrower, lender identity.PlayerID, day int64) (guild.RentalUse, bool, error) {
	var use guild.RentalUse
	var kind string
	err := t.QueryRow(ctx, `SELECT kind,unit_id FROM guild_rental_uses WHERE borrower_id=$1 AND lender_id=$2 AND game_day=$3 FOR UPDATE`, int64(borrower), int64(lender), day).Scan(&kind, &use.Unit)
	if noRows(err) {
		return guild.RentalUse{}, false, nil
	}
	use.Borrower, use.Lender, use.GameDay, use.Kind = borrower, lender, day, guild.RentalKind(kind)
	return use, err == nil, err
}

// InsertRentalUseTx reports false when a concurrent START took the pair's day first.
func (Store) InsertRentalUseTx(ctx context.Context, t tx.Tx, use guild.RentalUse) (bool, error) {
	tag, err := t.Exec(ctx, `INSERT INTO guild_rental_uses(borrower_id,lender_id,game_day,kind,unit_id,campaign_type,cost_mana,used_at)
		VALUES($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT DO NOTHING`,
		int64(use.Borrower), int64(use.Lender), use.GameDay, string(use.Kind), use.Unit, use.CampaignType, use.CostMana, use.UsedAt)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
}

func (Store) DeleteExpiredRentalUsesTx(ctx context.Context, t tx.Tx, borrower identity.PlayerID, day int64) error {
	_, err := t.Exec(ctx, `DELETE FROM guild_rental_uses WHERE borrower_id=$1 AND game_day<$2`, int64(borrower), day)
	return err
}
