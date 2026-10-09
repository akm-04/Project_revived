package guildbroadcast

import (
	"gxb.local/backend/v2/internal/foundation/finitejson"
	"gxb.local/backend/v2/internal/foundation/ids"
)

func decodeSubmitResult(raw []byte) (SubmitResult, error) {
	m, e := finitejson.Decode(string(raw), 256, 2, 3, 2)
	if e != nil || len(m) != 2 {
		return SubmitResult{}, ErrConflict
	}
	idText, ok := m["source_id"].(string)
	if !ok {
		return SubmitResult{}, ErrConflict
	}
	id, e := ids.ParseUUID(idText)
	if e != nil || id.IsZero() || idText != id.String() {
		return SubmitResult{}, ErrConflict
	}
	count, ok := m["recipient_count"].(int64)
	if !ok || count < 1 || count > 50 {
		return SubmitResult{}, ErrConflict
	}
	return SubmitResult{SourceID: id, RecipientCount: int(count)}, nil
}
