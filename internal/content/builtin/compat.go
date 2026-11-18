package builtin

import "errors"

// CompatMessagePushCatalog is the I9-11D compiled message-push preference id
// set. The artifact pins the exact source table and its sha256; the row count
// is checked against the compiled ids so a truncated catalog fails closed.
type CompatMessagePushCatalog struct {
	SchemaVersion int     `json:"schema_version"`
	Source        string  `json:"source"`
	SourceSHA256  string  `json:"source_sha256"`
	RowCount      int64   `json:"row_count"`
	IDs           []int64 `json:"ids"`
}

func (c CompatMessagePushCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.Source != "data/tables/message_push.lua" || len(c.SourceSHA256) != 64 {
		return errors.New("compat message push catalog profile")
	}
	if c.RowCount != int64(len(c.IDs)) || c.RowCount == 0 {
		return errors.New("compat message push catalog row count")
	}
	for index, id := range c.IDs {
		if id <= 0 {
			return errors.New("compat message push catalog id")
		}
		if index > 0 && c.IDs[index-1] >= id {
			return errors.New("compat message push catalog order")
		}
	}
	return nil
}
