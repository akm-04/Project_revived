package operator

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"strings"
	"unicode"
	"unicode/utf8"

	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	// MaxServerNameDisplayUnits is the client label budget: the client's own
	// player-name maximum is 16, where one non-ASCII character counts as two
	// (data/tables/misc.lua:130).
	MaxServerNameDisplayUnits = 16
	// CodeServerNotFound is server.rename's permanent refusal for an id that is
	// not a registered logical server.
	CodeServerNotFound = "OPERATOR_SERVER_NOT_FOUND"
)

// ErrServerNotFound is the owner's signal that server_id names no row.
var ErrServerNotFound = errors.New("operator: no such logical server")

// ServerRename is the server.rename result.
type ServerRename struct {
	ServerID int64  `json:"server_id"`
	OldName  string `json:"old_name"`
	NewName  string `json:"new_name"`
}

// ServerRenamer is the logicalserver owner's write port; the handler calls it
// inside the command bus transaction.
type ServerRenamer interface {
	RenameServerTx(context.Context, tx.Tx, int64, string) (ServerRename, error)
}

type serverRenamePayload struct {
	ServerID int64  `json:"server_id"`
	Name     string `json:"name"`
}

// ServerRenameHandler is server.rename (S5): the name MID 18 returns for the
// client server-select popup (RegionWindow.lua:256) and server.list shows.
func ServerRenameHandler(renamer ServerRenamer) Handler {
	return func(ctx context.Context, scope tx.Scope, command Command) (any, error) {
		if renamer == nil || scope.Tx == nil {
			return nil, ErrUnavailable
		}
		var payload serverRenamePayload
		decoder := json.NewDecoder(bytes.NewReader(command.Payload))
		decoder.DisallowUnknownFields()
		if err := decoder.Decode(&payload); err != nil {
			return nil, Refuse(CodePayloadInvalid, "the payload must be {server_id, name}", nil)
		}
		if payload.ServerID <= 0 {
			return nil, Refuse(CodePayloadInvalid, "server_id must be a positive id", nil)
		}
		name, err := NormalizeServerName(payload.Name)
		if err != nil {
			return nil, err
		}
		result, err := renamer.RenameServerTx(ctx, scope.Tx, payload.ServerID, name)
		if errors.Is(err, ErrServerNotFound) {
			return nil, Refuse(CodeServerNotFound, "server_id does not name a registered server", nil)
		}
		return result, err
	}
}

// NormalizeServerName trims the name and enforces the client label budget: 1 to
// 16 display units (a non-ASCII rune counts as two) and no control character.
func NormalizeServerName(raw string) (string, error) {
	name := strings.TrimSpace(raw)
	if name == "" {
		return "", Refuse(CodePayloadInvalid, "the server name is required", nil)
	}
	if !utf8.ValidString(name) {
		return "", Refuse(CodePayloadInvalid, "the server name is not valid UTF-8", nil)
	}
	units := 0
	for _, character := range name {
		if unicode.IsControl(character) {
			return "", Refuse(CodePayloadInvalid, "the server name must not contain control characters", nil)
		}
		if character > 0x7F {
			units += 2
		} else {
			units++
		}
	}
	if units > MaxServerNameDisplayUnits {
		return "", Refuse(CodePayloadInvalid, "the server name is longer than 16 characters (a non-ASCII character counts as two)", nil)
	}
	return name, nil
}
