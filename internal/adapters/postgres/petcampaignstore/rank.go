package petcampaignstore

import (
	"context"
	"encoding/json"
	app "gxb.local/backend/v2/internal/application/petcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/petcampaign"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) RanksTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, self d.State) ([]app.RankCandidate, int64, error) {
	var raw string
	e := q.QueryRow(c, `SELECT COALESCE(json_agg(r)::text,'[]') FROM (SELECT player_id AS "Player",(payload->>'Max')::bigint AS "Floor" FROM petcampaign_players WHERE (payload->>'Server')::bigint=$1 AND (payload->>'Max')::bigint>0 ORDER BY (payload->>'Max')::bigint DESC,(payload->>'Attained')::bigint,player_id LIMIT 100)r`, int64(server)).Scan(&raw)
	if e != nil {
		return nil, 0, e
	}
	out := []app.RankCandidate{}
	if e = json.Unmarshal([]byte(raw), &out); e != nil {
		return nil, 0, e
	}
	my := int64(0)
	if self.Max > 0 {
		e = q.QueryRow(c, `SELECT 1+count(*) FROM petcampaign_players WHERE (payload->>'Server')::bigint=$1 AND ((payload->>'Max')::bigint>$2 OR ((payload->>'Max')::bigint=$2 AND ((payload->>'Attained')::bigint<$3 OR ((payload->>'Attained')::bigint=$3 AND player_id<$4))))`, int64(server), self.Max, self.Attained, self.Player).Scan(&my)
	}
	return out, my, e
}
