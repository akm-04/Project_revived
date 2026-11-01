package guildstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Tea rows are family player rows at lock rank 605, above the I5 economy locks
// (I9_GUILD_ACTIVITY_V1 C14, C15).

func scanWish(row tx.Row) (guild.Wish, bool, error) {
	var w guild.Wish
	var player int64
	err := row.Scan(&player, &w.GameDay, &w.ItemID, &w.NeedNum, &w.CurrentNum)
	if noRows(err) {
		return guild.Wish{}, false, nil
	}
	if err != nil {
		return guild.Wish{}, false, err
	}
	w.PlayerID = identity.PlayerID(player)
	return w, true, w.Validate()
}

func (Store) ReadWishTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, day int64) (guild.Wish, bool, error) {
	if q == nil || !player.Valid() || day <= 0 {
		return guild.Wish{}, false, errors.New("invalid guild tea wish read")
	}
	return scanWish(q.QueryRow(ctx, `SELECT player_id,game_day,item_id,need_num,current_num FROM guild_tea_wishes WHERE player_id=$1 AND game_day=$2`, int64(player), day))
}

func (Store) LockWishTx(ctx context.Context, t tx.Tx, player identity.PlayerID, day int64) (guild.Wish, bool, error) {
	if t == nil || !player.Valid() || day <= 0 {
		return guild.Wish{}, false, errors.New("invalid guild tea wish lock")
	}
	return scanWish(t.QueryRow(ctx, `SELECT player_id,game_day,item_id,need_num,current_num FROM guild_tea_wishes WHERE player_id=$1 AND game_day=$2 FOR UPDATE`, int64(player), day))
}

func (Store) InsertWishTx(ctx context.Context, t tx.Tx, w guild.Wish) error {
	if t == nil {
		return errors.New("nil guild tea wish tx")
	}
	if err := w.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `INSERT INTO guild_tea_wishes(player_id,game_day,item_id,need_num,current_num) VALUES($1,$2,$3,$4,0)
		ON CONFLICT(player_id,game_day) DO NOTHING`, int64(w.PlayerID), w.GameDay, w.ItemID, w.NeedNum)
	if err != nil {
		return err
	}
	return one(tag, "insert guild tea wish")
}

func (Store) AdvanceWishTx(ctx context.Context, t tx.Tx, player identity.PlayerID, day int64) (guild.Wish, bool, error) {
	if t == nil || !player.Valid() || day <= 0 {
		return guild.Wish{}, false, errors.New("invalid guild tea wish advance")
	}
	return scanWish(t.QueryRow(ctx, `UPDATE guild_tea_wishes SET current_num=current_num+1
		WHERE player_id=$1 AND game_day=$2 AND current_num<need_num
		RETURNING player_id,game_day,item_id,need_num,current_num`, int64(player), day))
}

// InsertGiftTx is the once-per-donor-receiver-day guard: a conflicting row means
// this donation already happened today (C14).
func (Store) InsertGiftTx(ctx context.Context, t tx.Tx, g guild.Gift) (bool, error) {
	if t == nil {
		return false, errors.New("nil guild tea gift tx")
	}
	if err := g.Validate(); err != nil {
		return false, err
	}
	tag, err := t.Exec(ctx, `INSERT INTO guild_tea_gifts(receiver_id,donor_id,game_day,item_id) VALUES($1,$2,$3,$4)
		ON CONFLICT(receiver_id,donor_id,game_day) DO NOTHING`, int64(g.ReceiverID), int64(g.DonorID), g.GameDay, g.ItemID)
	if err != nil {
		return false, err
	}
	return tag != nil && tag.RowsAffected() == 1, nil
}

func (Store) listGifts(ctx context.Context, q tx.Queryer, receiver identity.PlayerID, day int64) ([]guild.Gift, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object(
		'donor',donor_id,'day',game_day,'item',item_id) ORDER BY donor_id),'[]'::jsonb)::text
		FROM guild_tea_gifts WHERE receiver_id=$1 AND game_day=$2 AND claimed_at IS NULL`, int64(receiver), day).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		Donor int64 `json:"donor"`
		Day   int64 `json:"day"`
		Item  int64 `json:"item"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]guild.Gift, 0, len(rows))
	for _, row := range rows {
		out = append(out, guild.Gift{ReceiverID: receiver, DonorID: identity.PlayerID(row.Donor), GameDay: row.Day, ItemID: row.Item})
	}
	return out, nil
}

// ListUnclaimedGiftsTx returns the gifts a receiver has not claimed yet (C15).
func (Store) ListUnclaimedGiftsTx(ctx context.Context, q tx.Queryer, receiver identity.PlayerID, day int64) ([]guild.Gift, error) {
	if q == nil || !receiver.Valid() || day <= 0 {
		return nil, errors.New("invalid guild tea gift read")
	}
	return (Store{}).listGifts(ctx, q, receiver, day)
}

// ListWishesTx returns the current members' wishes for one day; the guild member
// cap bounds the list.
func (Store) ListWishesTx(ctx context.Context, q tx.Queryer, guildID guild.ID, day int64) ([]guild.Wish, error) {
	if q == nil || guildID <= 0 || day <= 0 {
		return nil, errors.New("invalid guild tea wish list")
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object(
		'player',w.player_id,'item',w.item_id,'need',w.need_num,'current',w.current_num) ORDER BY w.player_id),'[]'::jsonb)::text
		FROM guild_tea_wishes w JOIN guild_memberships m ON m.player_id=w.player_id
		WHERE m.guild_id=$1 AND w.game_day=$2`, int64(guildID), day).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		Player  int64 `json:"player"`
		Item    int64 `json:"item"`
		Need    int64 `json:"need"`
		Current int64 `json:"current"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]guild.Wish, 0, len(rows))
	for _, row := range rows {
		out = append(out, guild.Wish{PlayerID: identity.PlayerID(row.Player), GameDay: day, ItemID: row.Item, NeedNum: row.Need, CurrentNum: row.Current})
	}
	return out, nil
}

// ClaimGiftsTx marks the receiver's unclaimed day gifts claimed and returns how
// many it cleared; a second claim returns zero (C15).
func (Store) ClaimGiftsTx(ctx context.Context, t tx.Tx, receiver identity.PlayerID, day int64, at time.Time) (int64, error) {
	if t == nil || !receiver.Valid() || day <= 0 || at.IsZero() {
		return 0, errors.New("invalid guild tea claim")
	}
	var claimed int64
	err := t.QueryRow(ctx, `WITH claimed AS (
		UPDATE guild_tea_gifts SET claimed_at=$3 WHERE receiver_id=$1 AND game_day=$2 AND claimed_at IS NULL RETURNING 1
	) SELECT COUNT(*)::bigint FROM claimed`, int64(receiver), day, at.UTC()).Scan(&claimed)
	return claimed, err
}

// DeleteExpiredWishesTx removes a guild's expired wishes; a later command runs
// it, never a read path (C15).
func (Store) DeleteExpiredWishesTx(ctx context.Context, t tx.Tx, guildID guild.ID, day int64) error {
	if t == nil || guildID <= 0 || day <= 0 {
		return errors.New("invalid guild tea wish purge")
	}
	_, err := t.Exec(ctx, `DELETE FROM guild_tea_wishes WHERE game_day<$2
		AND player_id IN (SELECT player_id FROM guild_memberships WHERE guild_id=$1)`, int64(guildID), day)
	return err
}

// DeleteExpiredGiftsForPlayerTx removes a player's expired gifts; a later
// command runs it, never a read path (C15).
func (Store) DeleteExpiredGiftsForPlayerTx(ctx context.Context, t tx.Tx, player identity.PlayerID, day int64) error {
	if t == nil || !player.Valid() || day <= 0 {
		return errors.New("invalid guild tea gift purge")
	}
	_, err := t.Exec(ctx, `DELETE FROM guild_tea_gifts WHERE game_day<$2 AND (receiver_id=$1 OR donor_id=$1)`, int64(player), day)
	return err
}

// GiftedReceiversTx lists the receivers this donor already gave to today, so
// can_present_gift reflects the once-per-day guard.
func (Store) GiftedReceiversTx(ctx context.Context, q tx.Queryer, donor identity.PlayerID, day int64) (map[identity.PlayerID]bool, error) {
	if q == nil || !donor.Valid() || day <= 0 {
		return nil, errors.New("invalid guild tea gift donor read")
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(receiver_id),'[]'::jsonb)::text FROM guild_tea_gifts WHERE donor_id=$1 AND game_day=$2`, int64(donor), day).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var ids []int64
	if err := json.Unmarshal([]byte(raw), &ids); err != nil {
		return nil, err
	}
	out := make(map[identity.PlayerID]bool, len(ids))
	for _, id := range ids {
		out[identity.PlayerID(id)] = true
	}
	return out, nil
}
