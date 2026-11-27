package identitylifecycle

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"math"
	"os"
	"slices"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// LogoutBatchSize bounds one revocation statement (I11A_1_PLAN "L6 logout on
// publish"): a set larger than this is applied in several batches.
const LogoutBatchSize = 1000

const (
	// DefaultSessionHoldSeconds is the safe default logout hold (G11): the
	// affected scope is refused MID 1 logins for this long.
	DefaultSessionHoldSeconds int64 = 5
	// MaxSessionHoldSeconds bounds an explicit hold_seconds.
	MaxSessionHoldSeconds int64 = 3600

	HoldScopeGlobal = "global"
	HoldScopeServer = "server"
	HoldScopePlayer = "player"
)

// LogoutStore is the owner-shaped write port of the operator logout commands.
// Every method runs in the bus transaction.
type LogoutStore interface {
	FindLiveSessionIDsForPlayersTx(context.Context, tx.Queryer, []identity.PlayerID) ([]identity.SessionID, error)
	// ListLiveSessionIDsTx pages live sessions in ascending session id order
	// after `after`; a nil server selects every logical server.
	ListLiveSessionIDsTx(context.Context, tx.Queryer, *identity.LogicalServerID, identity.SessionID, int) ([]identity.SessionID, error)
	RevokeSessionsTx(context.Context, tx.Tx, []identity.SessionID, time.Time, string) (int64, error)
	// PlayerIDsForSessionIDsTx resolves named sessions to their live player.
	PlayerIDsForSessionIDsTx(context.Context, tx.Queryer, []identity.SessionID) ([]identity.PlayerID, error)
	// InsertSessionHoldTx records one hold the MID 1 login check reads.
	InsertSessionHoldTx(context.Context, tx.Tx, SessionHold) error
}

// SessionHold is one active login hold. ScopeKey is 0 for global, the logical
// server id for server scope and the player id for player scope.
type SessionHold struct {
	ScopeKind  string
	ScopeKey   int64
	HeldUntil  time.Time
	Reason     string
	CommandKey string
}

// HoldChecker is the MID 1 login read: anything else never reads the hold table.
type HoldChecker interface {
	ActiveSessionHoldTx(context.Context, tx.Queryer, identity.LogicalServerID, identity.PlayerID, time.Time) (bool, error)
}

// SessionHoldSecondsTunable is the default hold of a command that omits
// hold_seconds (G11/F1: unset is never broken). The tuning overlay that will
// own this knob is not built yet, so an environment tunable with the same safe
// default stands in for it.
func SessionHoldSecondsTunable() int64 {
	raw := strings.TrimSpace(os.Getenv("GXB_SESSION_LOGOUT_HOLD_SECONDS"))
	if raw == "" {
		return DefaultSessionHoldSeconds
	}
	parsed, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || parsed < 0 || parsed > MaxSessionHoldSeconds {
		return DefaultSessionHoldSeconds
	}
	return parsed
}

// LogoutResult is the session.logout / session.logout_all reply.
type LogoutResult struct {
	Revoked int64 `json:"revoked"`
}

// LogoutCommands applies the session.logout and session.logout_all commands.
type LogoutCommands struct {
	Store LogoutStore
	// DefaultHoldSeconds is the hold applied when the payload omits
	// hold_seconds; zero means DefaultSessionHoldSeconds.
	DefaultHoldSeconds int64
}

func (commands LogoutCommands) holdSeconds(requested *int64) (int64, error) {
	if requested == nil {
		if commands.DefaultHoldSeconds < 0 || commands.DefaultHoldSeconds > MaxSessionHoldSeconds {
			return 0, operator.Refuse(operator.CodePayloadInvalid, "hold_seconds default is outside its bounds", nil)
		}
		if commands.DefaultHoldSeconds == 0 {
			return DefaultSessionHoldSeconds, nil
		}
		return commands.DefaultHoldSeconds, nil
	}
	if *requested < 0 || *requested > MaxSessionHoldSeconds {
		return 0, operator.Refuse(operator.CodePayloadInvalid, "hold_seconds must be between 0 and 3600", nil)
	}
	return *requested, nil
}

func (commands LogoutCommands) applyHold(ctx context.Context, transaction tx.Tx, hold SessionHold, commandKey string) error {
	if hold.HeldUntil.IsZero() {
		return nil
	}
	hold.CommandKey = commandKey
	return commands.Store.InsertSessionHoldTx(ctx, transaction, hold)
}

// Handlers registers both logout commands on the operator bus.
func (commands LogoutCommands) Handlers() map[string]operator.Handler {
	return map[string]operator.Handler{
		"session.logout":     commands.logoutHandler,
		"session.logout_all": commands.logoutAllHandler,
	}
}

type logoutPayload struct {
	PlayerIDs   []int64  `json:"player_ids,omitempty"`
	SessionIDs  []string `json:"session_ids,omitempty"`
	HoldSeconds *int64   `json:"hold_seconds,omitempty"`
}

type logoutAllPayload struct {
	ServerID    *int64 `json:"server_id,omitempty"`
	HoldSeconds *int64 `json:"hold_seconds,omitempty"`
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
	holdSeconds, err := commands.holdSeconds(request.HoldSeconds)
	if err != nil {
		return nil, err
	}
	return commands.Logout(ctx, scope.Tx, players, sessions, scope.Operation.StartedAt, holdSeconds, command.Envelope.SemanticKey)
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
	holdSeconds, err := commands.holdSeconds(request.HoldSeconds)
	if err != nil {
		return nil, err
	}
	return commands.LogoutAll(ctx, scope.Tx, server, scope.Operation.StartedAt, holdSeconds, command.Envelope.SemanticKey)
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

// Logout revokes every live session of the named players and sessions and
// holds their logins for holdSeconds.
func (commands LogoutCommands) Logout(ctx context.Context, transaction tx.Tx, players []identity.PlayerID, sessionIDs []identity.SessionID, at time.Time, holdSeconds int64, commandKey string) (LogoutResult, error) {
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
	result, err := commands.revokeAll(ctx, transaction, sortedSessions(found), identity.RevocationReasonOperatorLogout, at)
	if err != nil || holdSeconds <= 0 {
		return result, err
	}
	held := append([]identity.PlayerID(nil), players...)
	if len(sessionIDs) > 0 {
		resolvedPlayers, resolveErr := commands.Store.PlayerIDsForSessionIDsTx(ctx, transaction, sessionIDs)
		if resolveErr != nil {
			return LogoutResult{}, resolveErr
		}
		held = append(held, resolvedPlayers...)
	}
	for _, player := range distinctPlayers(held) {
		if applyErr := commands.applyHold(ctx, transaction, SessionHold{ScopeKind: HoldScopePlayer, ScopeKey: int64(player), HeldUntil: at.Add(time.Duration(holdSeconds) * time.Second), Reason: identity.RevocationReasonOperatorLogout}, commandKey); applyErr != nil {
			return LogoutResult{}, applyErr
		}
	}
	return result, nil
}

// LogoutAll revokes every live session, or only the live sessions of one
// logical server, in ascending session id batches, then holds the same scope.
func (commands LogoutCommands) LogoutAll(ctx context.Context, transaction tx.Tx, server *identity.LogicalServerID, at time.Time, holdSeconds int64, commandKey string) (LogoutResult, error) {
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
	if holdSeconds > 0 {
		hold := SessionHold{ScopeKind: HoldScopeGlobal, HeldUntil: at.Add(time.Duration(holdSeconds) * time.Second), Reason: identity.RevocationReasonOperatorLogoutAll}
		if server != nil {
			hold.ScopeKind = HoldScopeServer
			hold.ScopeKey = int64(*server)
		}
		if err := commands.applyHold(ctx, transaction, hold, commandKey); err != nil {
			return LogoutResult{}, err
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

func distinctPlayers(players []identity.PlayerID) []identity.PlayerID {
	seen := make(map[identity.PlayerID]struct{}, len(players))
	for _, player := range players {
		if player.Valid() {
			seen[player] = struct{}{}
		}
	}
	return sortedPlayers(seen)
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
