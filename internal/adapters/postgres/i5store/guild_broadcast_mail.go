package i5store

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var errBroadcastWireOverflow = errors.New("Guild broadcast Mail wire ID overflow")

// Exact source lookup includes attachments and mutable read/shown state. It
// never uses an expiry-filtered mailbox list to prove semantic completion.
func (Store) ReadGuildBroadcastMailTx(c context.Context, q tx.Queryer, pid identity.PlayerID, source ids.UUID) (mail.Record, bool, error) {
	var raw string
	e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object(
 'mail_uuid',m.mail_uuid::text,'recipient',m.recipient_player_id,'namespace',m.namespace,'wire_id',m.wire_id,
 'source_kind',m.source_kind,'source_key',m.source_key,'category',m.category,'title',m.title,'sender',m.sender,'body',m.body,
 'created_at',m.created_at,'expires_at',m.expires_at,'read_at',m.read_at,'shown',m.shown,'claimed_at',m.claimed_at,
 'platform',m.platform_eligibility,'policy',m.compatibility_policy_version,'state_version',m.state_version,
 'attachments',(SELECT COALESCE(jsonb_agg(jsonb_build_object('ordinal',a.ordinal,'kind',a.grant_line_kind,'resource_key',a.resource_key,'item_id',a.item_id,'amount',a.amount,'metadata',a.metadata) ORDER BY a.ordinal),'[]'::jsonb) FROM mail_attachments a WHERE a.mail_uuid=m.mail_uuid))),'[]'::jsonb)::text
 FROM mail_records m WHERE m.recipient_player_id=$1 AND m.source_kind='GUILD_BROADCAST' AND m.source_key=$2`, int64(pid), source.String()).Scan(&raw)
	if e != nil {
		return mail.Record{}, false, e
	}
	rows, e := decodeMailRows(json.RawMessage(raw))
	if e != nil {
		return mail.Record{}, false, e
	}
	if len(rows) == 0 {
		return mail.Record{}, false, nil
	}
	if len(rows) != 1 {
		return mail.Record{}, false, errors.New("Guild broadcast Mail source uniqueness conflict")
	}
	return rows[0], true, nil
}

// Called only after the NORMAL namespace lock; fails before any allocation.
func (Store) CheckGuildBroadcastWireCapacityTx(c context.Context, t tx.Tx, pid identity.PlayerID) error {
	var next int64
	e := t.QueryRow(c, `SELECT next_wire_id FROM mail_namespace_counters WHERE recipient_player_id=$1 AND namespace='NORMAL'`, int64(pid)).Scan(&next)
	if e != nil {
		return e
	}
	if next <= 0 || next > 9007199254740991 {
		return errBroadcastWireOverflow
	}
	return nil
}
