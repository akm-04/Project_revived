package kernelstore

import (
	"context"
	"fmt"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// GuildInviteGenerationHighWaterTx is a bounded statement-time Foundation
// aggregate, not a receipt dump. Every retained Invite identity in this Guild
// is checked before an exact target's high water is returned. Invalid history
// cannot silently disappear from a cursor seed through a permissive LIKE.
func (Store) GuildInviteGenerationHighWaterTx(c context.Context, q tx.Queryer, gid guild.ID, pid identity.PlayerID) (int64, error) {
	if q == nil || (gi.Tuple{GuildID: gid, Recipient: pid, Generation: 1}).Validate() != nil {
		return 0, gi.ErrEvidence
	}
	var bad, high int64
	e := q.QueryRow(c, `WITH facts AS (
 SELECT semantic_key, string_to_array(semantic_key,':') AS p
 FROM gxb_operation_receipts
 WHERE owner_kind='guild' AND owner_key=$1 AND domain='guild' AND operation='invite'
), shape AS (
 SELECT p, CASE WHEN semantic_key ~ '^actorver:[1-9][0-9]{0,18}:target:[1-9][0-9]{0,18}:gen:[1-9][0-9]{0,18}$'
 THEN p[2]::numeric<=9223372036854775807 AND p[4]::numeric<=9223372036854775807 AND p[6]::numeric<=9223372036854775807
 ELSE false END AS valid FROM facts
), typed AS (
 SELECT CASE WHEN valid THEN p[4]::bigint END AS target,
 CASE WHEN valid THEN p[6]::bigint END AS generation,valid FROM shape
)
SELECT count(*) FILTER (WHERE NOT valid OR target/100000<>$3),
 COALESCE(max(generation) FILTER (WHERE target=$2),0) FROM typed`, fmt.Sprint(gid), int64(pid), int64(gid)/1000000).Scan(&bad, &high)
	if e != nil {
		return 0, e
	}
	if bad != 0 || high < 0 {
		return 0, gi.ErrEvidence
	}
	return high, nil
}

var _ app.HistoricalGenerationReader = Store{}
