package socialgiftstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	sg "gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadEpoch(c context.Context, q tx.Queryer, p identity.PlayerID, day string) (sg.Epoch, bool, error) {
	var raw []byte
	e := q.QueryRow(c, `SELECT to_jsonb(e) FROM social_gift_epochs e WHERE player_id=$1 AND policy_id=$2 AND day_token=$3`, int64(p), sg.DayPolicy, day).Scan(&raw)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return sg.Epoch{}, false, nil
	}
	if e != nil {
		return sg.Epoch{}, false, e
	}
	var w epochWire
	if e = json.Unmarshal(raw, &w); e != nil {
		return sg.Epoch{}, false, e
	}
	v, e := w.value()
	return v, e == nil, e
}
