package guildbroadcast

import (
	"bytes"
	"encoding/json"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/finitejson"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/obligation"
)

// DecodeMailObligation validates the selected finite route and exact canonical
// reference before a producer/worker may pass it to owner reload.
func DecodeMailObligation(o obligation.Obligation) (ids.UUID, identity.PlayerID, error) {
	if o.Kind != MailKind || o.Queue != Queue || o.Profile != WorkerProfile || o.Validate() != nil {
		return ids.UUID{}, 0, gb.ErrSource
	}
	m, e := finitejson.Decode(string(o.Args), 128, 2, 3, 2)
	if e != nil || len(m) != 2 {
		return ids.UUID{}, 0, gb.ErrSource
	}
	idText, ok := m["source_id"].(string)
	if !ok {
		return ids.UUID{}, 0, gb.ErrSource
	}
	id, e := ids.ParseUUID(idText)
	if e != nil || id.IsZero() || id.String() != idText {
		return ids.UUID{}, 0, gb.ErrSource
	}
	value, ok := m["recipient_id"].(int64)
	pid := identity.PlayerID(value)
	if !ok || !pid.Valid() {
		return ids.UUID{}, 0, gb.ErrSource
	}
	expected, e := MailObligation(id, pid, o.DueAt)
	if e != nil || expected.SemanticKey != o.SemanticKey {
		return ids.UUID{}, 0, gb.ErrSource
	}
	canonical, e := json.Marshal(MailReference{SourceID: idText, RecipientID: value})
	if e != nil || !bytes.Equal(canonical, o.Args) {
		return ids.UUID{}, 0, gb.ErrSource
	}
	return id, pid, nil
}

const ReconcileSemanticKey = "guild-broadcast:reconcile"

var reconcileArgs = []byte(`{"scope":"GUILD_BROADCAST_PENDING_V1"}`)

func ValidateObligation(o obligation.Obligation) error {
	if o.Kind == MailKind {
		_, _, e := DecodeMailObligation(o)
		return e
	}
	if o.Kind != ReconcileKind || o.Queue != Queue || o.Profile != WorkerProfile || o.SemanticKey != ReconcileSemanticKey || o.DueAt.IsZero() || !bytes.Equal(o.Args, reconcileArgs) {
		return gb.ErrSource
	}
	return o.Validate()
}

// NormalizeStoredObligation recognizes only the PostgreSQL JSONB representation
// of the two finite reference shapes. Producers still require canonical bytes
// before insertion. No unknown field, duplicate key or altered semantic key is
// normalized away; gameplay facts are subsequently reloaded from the owner.
func NormalizeStoredObligation(o obligation.Obligation) (obligation.Obligation, error) {
	if o.Queue != Queue || o.Profile != WorkerProfile || o.DueAt.IsZero() {
		return o, gb.ErrSource
	}
	switch o.Kind {
	case MailKind:
		m, e := finitejson.Decode(string(o.Args), 128, 2, 3, 2)
		if e != nil || len(m) != 2 {
			return o, gb.ErrSource
		}
		text, ok := m["source_id"].(string)
		if !ok {
			return o, gb.ErrSource
		}
		id, e := ids.ParseUUID(text)
		if e != nil || id.IsZero() || id.String() != text {
			return o, gb.ErrSource
		}
		value, ok := m["recipient_id"].(int64)
		pid := identity.PlayerID(value)
		if !ok || !pid.Valid() {
			return o, gb.ErrSource
		}
		canonical, e := MailObligation(id, pid, o.DueAt)
		if e != nil || canonical.SemanticKey != o.SemanticKey {
			return o, gb.ErrSource
		}
		o.Args = canonical.Args
	case ReconcileKind:
		m, e := finitejson.Decode(string(o.Args), 128, 2, 2, 1)
		if e != nil || len(m) != 1 || m["scope"] != "GUILD_BROADCAST_PENDING_V1" {
			return o, gb.ErrSource
		}
		o.Args = append([]byte(nil), reconcileArgs...)
	default:
		return o, gb.ErrSource
	}
	return o, ValidateObligation(o)
}
