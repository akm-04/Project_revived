package librarystore

import (
	"context"
	"encoding/json"

	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fact interface {
	Validate() error
}

func listFacts[T fact](ctx context.Context, q tx.Queryer, query string, args ...any) ([]T, error) {
	if q == nil {
		return nil, library.ErrInvalidFacts
	}
	var raw string
	if e := q.QueryRow(ctx, query, args...).Scan(&raw); e != nil {
		return nil, e
	}
	var out []T
	if e := json.Unmarshal([]byte(raw), &out); e != nil {
		return nil, e
	}
	for i := range out {
		if e := out[i].Validate(); e != nil {
			return nil, e
		}
	}
	return out, nil
}

func (Store) ListDialogsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) ([]library.DialogFact, error) {
	if !pid.Valid() {
		return nil, library.ErrInvalidFacts
	}
	return listFacts[library.DialogFact](ctx, q, `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY partner_id,dialog_id),'[]'::jsonb)::text FROM player_library_dialogs t WHERE player_id=$1`, int64(pid))
}

func (Store) ListMissionsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) ([]library.MissionFact, error) {
	if !pid.Valid() {
		return nil, library.ErrInvalidFacts
	}
	return listFacts[library.MissionFact](ctx, q, `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY partner_id,mission_id),'[]'::jsonb)::text FROM player_library_partner_missions t WHERE player_id=$1`, int64(pid))
}

func (Store) ListActAwardsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) ([]library.ActAwardFact, error) {
	if !pid.Valid() {
		return nil, library.ErrInvalidFacts
	}
	return listFacts[library.ActAwardFact](ctx, q, `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY partner_id,act_id),'[]'::jsonb)::text FROM player_library_act_awards t WHERE player_id=$1`, int64(pid))
}

func (Store) ListTalkClaimsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) ([]library.TalkClaimFact, error) {
	if !pid.Valid() {
		return nil, library.ErrInvalidFacts
	}
	return listFacts[library.TalkClaimFact](ctx, q, `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY talk_id),'[]'::jsonb)::text FROM player_library_talk_claims t WHERE player_id=$1`, int64(pid))
}

func (Store) ListCGClaimsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) ([]library.CGClaimFact, error) {
	if !pid.Valid() {
		return nil, library.ErrInvalidFacts
	}
	return listFacts[library.CGClaimFact](ctx, q, `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY cg_id),'[]'::jsonb)::text FROM player_library_cg_claims t WHERE player_id=$1`, int64(pid))
}

func (Store) ListBackgroundsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) ([]library.BackgroundFact, error) {
	if !pid.Valid() {
		return nil, library.ErrInvalidFacts
	}
	return listFacts[library.BackgroundFact](ctx, q, `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY bg_id),'[]'::jsonb)::text FROM player_library_backgrounds t WHERE player_id=$1`, int64(pid))
}

func (Store) SaveDialogTx(ctx context.Context, t tx.Tx, f library.DialogFact) error {
	if t == nil || f.Validate() != nil {
		return library.ErrInvalidFacts
	}
	_, e := t.Exec(ctx, `INSERT INTO player_library_dialogs(player_id,partner_id,dialog_id,is_read,is_awarded,select_id,updated_at)VALUES($1,$2,$3,$4,$5,$6,$7)ON CONFLICT(player_id,partner_id,dialog_id)DO UPDATE SET is_read=EXCLUDED.is_read,is_awarded=EXCLUDED.is_awarded,select_id=EXCLUDED.select_id,updated_at=EXCLUDED.updated_at`, int64(f.PlayerID), f.PartnerID, f.DialogID, f.IsRead, f.IsAwarded, f.SelectID, f.UpdatedAt.UTC())
	return e
}

func (Store) SaveMissionTx(ctx context.Context, t tx.Tx, f library.MissionFact) error {
	if t == nil || f.Validate() != nil {
		return library.ErrInvalidFacts
	}
	_, e := t.Exec(ctx, `INSERT INTO player_library_partner_missions(player_id,partner_id,mission_id,process,mission_state,updated_at)VALUES($1,$2,$3,$4,$5,$6)ON CONFLICT(player_id,partner_id,mission_id)DO UPDATE SET process=EXCLUDED.process,mission_state=EXCLUDED.mission_state,updated_at=EXCLUDED.updated_at`, int64(f.PlayerID), f.PartnerID, f.MissionID, f.Process, f.MissionState, f.UpdatedAt.UTC())
	return e
}

// InsertActAwardTx reports whether this call inserted the once-per-hero/act award.
func (Store) InsertActAwardTx(ctx context.Context, t tx.Tx, f library.ActAwardFact) (bool, error) {
	if t == nil || f.Validate() != nil {
		return false, library.ErrInvalidFacts
	}
	tag, e := t.Exec(ctx, `INSERT INTO player_library_act_awards(player_id,partner_id,act_id,awarded_at)VALUES($1,$2,$3,$4)ON CONFLICT(player_id,partner_id,act_id)DO NOTHING`, int64(f.PlayerID), f.PartnerID, f.ActID, f.AwardedAt.UTC())
	if e != nil {
		return false, e
	}
	return tag.RowsAffected() == 1, nil
}

// InsertTalkClaimTx reports whether this call inserted the once-per-player talk claim.
func (Store) InsertTalkClaimTx(ctx context.Context, t tx.Tx, f library.TalkClaimFact) (bool, error) {
	if t == nil || f.Validate() != nil {
		return false, library.ErrInvalidFacts
	}
	tag, e := t.Exec(ctx, `INSERT INTO player_library_talk_claims(player_id,talk_id,claimed_at)VALUES($1,$2,$3)ON CONFLICT(player_id,talk_id)DO NOTHING`, int64(f.PlayerID), f.TalkID, f.ClaimedAt.UTC())
	if e != nil {
		return false, e
	}
	return tag.RowsAffected() == 1, nil
}

// InsertCGClaimTx reports whether this call inserted the once-per-player CG claim.
func (Store) InsertCGClaimTx(ctx context.Context, t tx.Tx, f library.CGClaimFact) (bool, error) {
	if t == nil || f.Validate() != nil {
		return false, library.ErrInvalidFacts
	}
	tag, e := t.Exec(ctx, `INSERT INTO player_library_cg_claims(player_id,cg_id,claimed_at)VALUES($1,$2,$3)ON CONFLICT(player_id,cg_id)DO NOTHING`, int64(f.PlayerID), f.CGID, f.ClaimedAt.UTC())
	if e != nil {
		return false, e
	}
	return tag.RowsAffected() == 1, nil
}

// UnlockBackgroundTx reports whether this call inserted the paid background ownership.
func (Store) UnlockBackgroundTx(ctx context.Context, t tx.Tx, f library.BackgroundFact) (bool, error) {
	if t == nil || f.Validate() != nil {
		return false, library.ErrInvalidFacts
	}
	tag, e := t.Exec(ctx, `INSERT INTO player_library_backgrounds(player_id,bg_id,unlocked_at)VALUES($1,$2,$3)ON CONFLICT(player_id,bg_id)DO NOTHING`, int64(f.PlayerID), f.BgID, f.UnlockedAt.UTC())
	if e != nil {
		return false, e
	}
	return tag.RowsAffected() == 1, nil
}
