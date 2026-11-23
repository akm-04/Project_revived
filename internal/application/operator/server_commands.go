package operator

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"strconv"
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

// ServerNotFoundError names the missing server so a batch refusal can say
// which row stopped it. It matches ErrServerNotFound for errors.Is.
type ServerNotFoundError struct {
	ServerID int64
}

func (err *ServerNotFoundError) Error() string {
	return "operator: no such logical server " + strconv.FormatInt(err.ServerID, 10)
}

func (err *ServerNotFoundError) Is(target error) bool {
	return target == ErrServerNotFound
}

// ServerRename is one server.rename result row.
type ServerRename struct {
	ServerID int64  `json:"server_id"`
	OldName  string `json:"old_name"`
	NewName  string `json:"new_name"`
}

// ServerRenameBatch is the batch form's result: one row per server, in the
// order the operator sent them.
type ServerRenameBatch struct {
	Renames []ServerRename `json:"renames"`
}

// ServerNameChange is one row of the batch form.
type ServerNameChange struct {
	ServerID int64  `json:"server_id"`
	Name     string `json:"name"`
}

// ServerRenamer is the logicalserver owner's write port; the handler calls it
// inside the command bus transaction. One call is one transaction: it locks
// every named row before it updates any of them.
type ServerRenamer interface {
	RenameServersTx(context.Context, tx.Tx, []ServerNameChange) ([]ServerRename, error)
}

type serverRenamePayload struct {
	ServerID int64               `json:"server_id"`
	Name     string              `json:"name"`
	Names    *[]ServerNameChange `json:"names"`
}

// ServerRenameHandler is server.rename (S5): the name MID 18 returns for the
// client server-select popup (RegionWindow.lua:256) and server.list shows. The
// single form keeps its {server_id, name} reply; the batch form takes `names`
// and answers one old/new row per server.
func ServerRenameHandler(renamer ServerRenamer) Handler {
	return func(ctx context.Context, scope tx.Scope, command Command) (any, error) {
		if renamer == nil || scope.Tx == nil {
			return nil, ErrUnavailable
		}
		var payload serverRenamePayload
		decoder := json.NewDecoder(bytes.NewReader(command.Payload))
		decoder.DisallowUnknownFields()
		if err := decoder.Decode(&payload); err != nil {
			return nil, Refuse(CodePayloadInvalid, "the payload must be {server_id, name} or {names}", nil)
		}
		if payload.Names != nil {
			return renameServerBatch(ctx, renamer, scope.Tx, payload)
		}
		if payload.ServerID <= 0 {
			return nil, Refuse(CodePayloadInvalid, "server_id must be a positive id", nil)
		}
		name, err := NormalizeServerName(payload.Name)
		if err != nil {
			return nil, err
		}
		results, err := renamer.RenameServersTx(ctx, scope.Tx, []ServerNameChange{{ServerID: payload.ServerID, Name: name}})
		if err != nil {
			return nil, serverRenameError(err)
		}
		if len(results) != 1 {
			return nil, errors.New("operator: the server owner returned no rename")
		}
		return results[0], nil
	}
}

func renameServerBatch(ctx context.Context, renamer ServerRenamer, transaction tx.Tx, payload serverRenamePayload) (any, error) {
	if payload.ServerID != 0 || payload.Name != "" {
		return nil, Refuse(CodePayloadInvalid, "send either {server_id, name} or {names}, not both", nil)
	}
	changes, err := normalizeServerNameChanges(*payload.Names)
	if err != nil {
		return nil, err
	}
	results, err := renamer.RenameServersTx(ctx, transaction, changes)
	if err != nil {
		return nil, serverRenameError(err)
	}
	return ServerRenameBatch{Renames: results}, nil
}

// normalizeServerNameChanges checks the whole batch before the owner sees it,
// so a bad name or a repeated server never reaches a row lock.
func normalizeServerNameChanges(entries []ServerNameChange) ([]ServerNameChange, error) {
	if len(entries) == 0 {
		return nil, Refuse(CodePayloadInvalid, "names must list at least one server", nil)
	}
	seen := make(map[int64]struct{}, len(entries))
	changes := make([]ServerNameChange, 0, len(entries))
	for _, entry := range entries {
		if entry.ServerID <= 0 {
			return nil, Refuse(CodePayloadInvalid, "every names entry needs a positive server_id", nil)
		}
		if _, duplicate := seen[entry.ServerID]; duplicate {
			return nil, Refuse(CodePayloadInvalid, "server_id "+strconv.FormatInt(entry.ServerID, 10)+" appears twice in names", nil)
		}
		seen[entry.ServerID] = struct{}{}
		name, err := NormalizeServerName(entry.Name)
		if err != nil {
			return nil, serverNameRefusal(entry.ServerID, err)
		}
		changes = append(changes, ServerNameChange{ServerID: entry.ServerID, Name: name})
	}
	return changes, nil
}

func serverNameRefusal(serverID int64, err error) error {
	var refusal *Refusal
	if errors.As(err, &refusal) {
		return Refuse(refusal.Code, "server_id "+strconv.FormatInt(serverID, 10)+": "+refusal.Message, nil)
	}
	return err
}

func serverRenameError(err error) error {
	var missing *ServerNotFoundError
	if errors.As(err, &missing) {
		return Refuse(CodeServerNotFound, "server_id "+strconv.FormatInt(missing.ServerID, 10)+" does not name a registered server", nil)
	}
	if errors.Is(err, ErrServerNotFound) {
		return Refuse(CodeServerNotFound, "server_id does not name a registered server", nil)
	}
	return err
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
