package publicprofilestore

import (
	"context"
	"encoding/json"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var _ app.ShowcaseStore = Store{}

func (Store) ReadSelectionTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (app.Selection, error) {
	var s app.Selection
	if q == nil || !pid.Valid() {
		return s, app.ErrSelection
	}

	var raw string
	e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_array(slot_ordinal,hero_partner_id,pet_id) ORDER BY slot_ordinal),'[]'::jsonb)::text FROM player_public_profile_showcase_slots WHERE player_id=$1`, int64(pid)).Scan(&raw)
	if e != nil {
		return s, e
	}
	var rows [][]*int64
	if e = json.Unmarshal([]byte(raw), &rows); e != nil {
		return s, e
	}
	seen := map[int64]bool{}
	for _, r := range rows {
		if len(r) != 3 || r[0] == nil || *r[0] < 1 || *r[0] > 6 || seen[*r[0]] || (r[1] == nil) == (r[2] == nil) {
			return s, app.ErrSelection
		}
		i := *r[0]
		seen[i] = true
		if r[1] != nil {
			if *r[1] <= 0 {
				return s, app.ErrSelection
			}
			s[i-1] = *r[1]
		} else {
			if *r[2] <= 0 {
				return s, app.ErrSelection
			}
			s[i-1] = -*r[2]
		}
	}

	return s, s.Validate()
}
func (Store) ReplaceSelectionTx(c context.Context, t tx.Tx, pid identity.PlayerID, s app.Selection) error {
	if t == nil || !pid.Valid() || s.Validate() != nil {
		return app.ErrSelection
	}
	if _, e := t.Exec(c, `DELETE FROM player_public_profile_showcase_slots WHERE player_id=$1`, int64(pid)); e != nil {
		return e
	}
	for i, id := range s {
		if id == 0 {
			continue
		}
		var h, p any
		if id > 0 {
			h = id
		} else {
			p = -id
		}
		tag, e := t.Exec(c, `INSERT INTO player_public_profile_showcase_slots(player_id,slot_ordinal,hero_partner_id,pet_id) VALUES($1,$2,$3,$4)`, int64(pid), i+1, h, p)
		if e != nil {
			return e
		}
		if tag.RowsAffected() != 1 {
			return app.ErrSelection
		}
	}
	return nil
}
func (Store) ReferencesHeroTx(c context.Context, q tx.Queryer, pid identity.PlayerID, id int64) (bool, error) {
	if q == nil || !pid.Valid() || id <= 0 {
		return false, app.ErrSelection
	}
	var b bool
	e := q.QueryRow(c, `SELECT EXISTS(SELECT 1 FROM player_public_profile_showcase_slots WHERE player_id=$1 AND hero_partner_id=$2)`, int64(pid), id).Scan(&b)
	return b, e
}
func (Store) ReferencesPetTx(c context.Context, q tx.Queryer, pid identity.PlayerID, id int64) (bool, error) {
	if q == nil || !pid.Valid() || id <= 0 {
		return false, app.ErrSelection
	}
	var b bool
	e := q.QueryRow(c, `SELECT EXISTS(SELECT 1 FROM player_public_profile_showcase_slots WHERE player_id=$1 AND pet_id=$2)`, int64(pid), id).Scan(&b)
	return b, e
}
