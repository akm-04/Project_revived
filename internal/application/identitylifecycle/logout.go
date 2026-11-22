package identitylifecycle

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"math"
	"slices"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// LogoutBatchSize bounds one revocation statement (I11A_1_PLAN "L6 logout on
// publish"): a set larger than this is applied in several batches.
const LogoutBatchSize = 1000

// LogoutStore is the owner-shaped write port of the operator logout commands.
// Every method runs in the bus transaction.
type LogoutStore interface {
	FindLiveSessionIDsForPlayersTx(context.Context, tx.Queryer, []identity.PlayerID) ([]identity.SessionID, error)
	// ListLiveSessionIDsTx pages live sessions in ascending session id order
	// after `after`; a nil server selects every logical server.
	ListLiveSessionIDsTx(context.Context, tx.Queryer, *identity.LogicalServerID, identity.SessionID, int) ([]identity.SessionID, error)
	RevokeSessionsTx(context.Context, tx.Tx, []identity.SessionID, time.Time, string) (int64, error)
}

// LogoutResult is the session.logout / session.logout_all reply.
type LogoutResult struct {
	Revoked int64 `json:"revoked"`
}

// LogoutCommands applies the session.logout and session.logout_all commands.
type LogoutCommands struct {
	Store LogoutStore
}

// Handlers registers both logout commands on the operator bus.
func (commands LogoutCommands) Handlers() map[string]operator.Handler {
	return map[string]operator.Handler{
		"session.logout":     commands.logoutHandler,
		"session.logout_all": commands.logoutAllHandler,
	}
}

type logoutPayload struct {
	PlayerIDs  []int64  `json:"player_ids,omitempty"`
	SessionIDs []string `json:"session_ids,omitempty"`
}

type logoutAllPayload struct {
	ServerID *int64 `json:"server_id,omitempty"`
}

func decodeLogoutPayload(payload json.RawMessage, target any) error {
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return operator.Refuse(operator.CodePayloadInvalid, "the payload does not match the command: "+err.Error(), nil)
	}
	return nil
}

func (commands LogoutCommands) logoutHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var request logoutPayload
	if err := decodeLogoutPayload(command.Payload, &request); err != nil {
		return nil, err
	}
	players, sessions, err := parseLogoutTargets(request)
	if err != nil {
		return nil, err
	}
	return commands.Logout(ctx, scope.Tx, players, sessions, scope.Operation.StartedAt)
}

func (commands LogoutCommands) logoutAllHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var request logoutAllPayload
	if err := decodeLogoutPayload(command.Payload, &request); err != nil {
		return nil, err
	}
	server, err := parseLogoutAllServer(request.ServerID)
	if err != nil {
		return nil, err
	}
	return commands.LogoutAll(ctx, scope.Tx, server, scope.Operation.StartedAt)
}

func parseLogoutTargets(request logoutPayload) ([]identity.PlayerID, []identity.SessionID, error) {
	if len(request.PlayerIDs) == 0 && len(request.SessionIDs) == 0 {
		return nil, nil, operator.Refuse(operator.CodePayloadInvalid, "name at least one player_id or session_id", nil)
	}
	players := make(map[identity.PlayerID]struct{}, len(request.PlayerIDs))
	for _, raw := range request.PlayerIDs {
		if raw <= 0 {
			return nil, nil, operator.Refuse(operator.CodePayloadInvalid, "player_ids must be positive", nil)
		}
		players[identity.PlayerID(raw)] = struct{}{}
	}
	sessions := make(map[identity.SessionID]struct{}, len(request.SessionIDs))
	for _, raw := range request.SessionIDs {
		parsed, err := ids.ParseUUID(raw)
		if err != nil {
			return nil, nil, operator.Refuse(operator.CodePayloadInvalid, "session_ids must be uuids", nil)
		}
		session, err := identity.SessionIDFrom(parsed)
		if err != nil {
			return nil, nil, operator.Refuse(operator.CodePayloadInvalid, "session_ids must be uuids", nil)
		}
		sessions[session] = struct{}{}
	}
	return sortedPlayers(players), sortedSessions(sessions), nil
}

func parseLogoutAllServer(raw *int64) (*identity.LogicalServerID, error) {
	if raw == nil {
		return nil, nil
	}
	if *raw <= 0 || *raw > math.MaxInt32 {
		return nil, operator.Refuse(operator.CodePayloadInvalid, "server_id must be a positive logical server id", nil)
	}
	server := identity.LogicalServerID(*raw)
	return &server, nil
}

// Logout revokes every live session of the named players and sessions.
func (commands LogoutCommands) Logout(ctx context.Context, transaction tx.Tx, players []identity.PlayerID, sessionIDs []identity.SessionID, at time.Time) (LogoutResult, error) {
	if transaction == nil || at.IsZero() {
		return LogoutResult{}, operator.ErrUnavailable
	}
	found := make(map[identity.SessionID]struct{}, len(sessionIDs))
	for _, session := range sessionIDs {
		found[session] = struct{}{}
	}
	if len(players) > 0 {
		resolved, err := commands.Store.FindLiveSessionIDsForPlayersTx(ctx, transaction, players)
		if err != nil {
			return LogoutResult{}, err
		}
		for _, session := range resolved {
			found[session] = struct{}{}
		}
	}
	return commands.revokeAll(ctx, transaction, sortedSessions(found), identity.RevocationReasonOperatorLogout, at)
}

// LogoutAll revokes every live session, or only the live sessions of one
// logical server, in ascending session id batches.
func (commands LogoutCommands) LogoutAll(ctx context.Context, transaction tx.Tx, server *identity.LogicalServerID, at time.Time) (LogoutResult, error) {
	if transaction == nil || at.IsZero() {
		return LogoutResult{}, operator.ErrUnavailable
	}
	var revoked int64
	var after identity.SessionID
	for {
		batch, err := commands.Store.ListLiveSessionIDsTx(ctx, transaction, server, after, LogoutBatchSize)
		if err != nil {
			return LogoutResult{}, err
		}
		if len(batch) == 0 {
			break
		}
		after = batch[len(batch)-1]
		count, err := commands.Store.RevokeSessionsTx(ctx, transaction, batch, at, identity.RevocationReasonOperatorLogoutAll)
		if err != nil {
			return LogoutResult{}, err
		}
		revoked += count
		if len(batch) < LogoutBatchSize {
			break
		}
	}
	return LogoutResult{Revoked: revoked}, nil
}

func (commands LogoutCommands) revokeAll(ctx context.Context, transaction tx.Tx, sessionIDs []identity.SessionID, reason string, at time.Time) (LogoutResult, error) {
	var revoked int64
	for start := 0; start < len(sessionIDs); start += LogoutBatchSize {
		end := min(start+LogoutBatchSize, len(sessionIDs))
		count, err := commands.Store.RevokeSessionsTx(ctx, transaction, sessionIDs[start:end], at, reason)
		if err != nil {
			return LogoutResult{}, err
		}
		revoked += count
	}
	return LogoutResult{Revoked: revoked}, nil
}

// SessionTarget is one revocation target. A player target names the session
// its live context resolved to; the kind and key feed the gxb-admin audit row.
type SessionTarget struct {
	Session identity.SessionID
	Player  identity.PlayerID
}

func (target SessionTarget) Kind() string {
	if target.Player.Valid() {
		return "player"
	}
	return "session"
}

func (target SessionTarget) Key() string {
	if target.Player.Valid() {
		return strconv.FormatInt(int64(target.Player), 10)
	}
	return target.Session.UUID().String()
}

// ResolveSessionTarget turns a gxb-admin revoke target into one session. A
// player must hold exactly one live context; more than one needs -session.
func (s Service) ResolveSessionTarget(ctx context.Context, queryer tx.Queryer, player identity.PlayerID, session identity.SessionID) (SessionTarget, error) {
	if player <= 0 {
		return SessionTarget{Session: session}, nil
	}
	sessions, err := s.Store.FindLiveSessionsByPlayer(ctx, queryer, player)
	if err != nil {
		return SessionTarget{}, fmt.Errorf("revoke-session: player %d sessions: %w", player, err)
	}
	switch len(sessions) {
	case 0:
		return SessionTarget{}, fmt.Errorf("revoke-session refused: player %d has no live session", player)
	case 1:
		return SessionTarget{Player: player, Session: sessions[0]}, nil
	default:
		return SessionTarget{}, fmt.Errorf("revoke-session refused: player %d has %d live sessions; name one with -session", player, len(sessions))
	}
}

func sortedPlayers(players map[identity.PlayerID]struct{}) []identity.PlayerID {
	out := make([]identity.PlayerID, 0, len(players))
	for player := range players {
		out = append(out, player)
	}
	slices.Sort(out)
	return out
}

func sortedSessions(sessions map[identity.SessionID]struct{}) []identity.SessionID {
	out := make([]identity.SessionID, 0, len(sessions))
	for session := range sessions {
		out = append(out, session)
	}
	slices.SortFunc(out, func(left, right identity.SessionID) int {
		leftUUID, rightUUID := left.UUID(), right.UUID()
		return bytes.Compare(leftUUID[:], rightUUID[:])
	})
	return out
}
