package operatoragent

import (
	"context"
	"encoding/json"
	"net/url"
	"os"
	"strconv"
	"time"
)

// LogClearRequest is the logs.clear payload (C4). Source is client or backend;
// scope is all, player or older_than; older_than is an RFC3339 boundary.
type LogClearRequest struct {
	Source    string `json:"source"`
	Scope     string `json:"scope"`
	Player    string `json:"player,omitempty"`
	PlayerID  int64  `json:"player_id,omitempty"`
	UID       string `json:"uid,omitempty"`
	OlderThan string `json:"older_than,omitempty"`
}

// LogClearResult is the logs.clear reply for the agent's own backend log files.
type LogClearResult struct {
	Source       string `json:"source"`
	Scope        string `json:"scope"`
	RemovedFiles int    `json:"removed_files"`
}

// Tail reads one source forward from afterCursor (C2).
func (service *LogService) Tail(ctx context.Context, source, afterCursor, level string, limit int) (LogTail, error) {
	if err := validateLogSource(source); err != nil {
		return LogTail{}, err
	}
	if source == LogSourceClient {
		return service.tailClient(ctx, afterCursor, level, limit)
	}
	return service.tailFiles(source, afterCursor, level, limit)
}

// Search answers newest-first matches. The client source resolves the player
// through player.find or player.summary and reads the journal timeline.
func (service *LogService) Search(ctx context.Context, source, player, fromText, toText, level string, limit int) (LogSearch, error) {
	if err := validateLogSource(source); err != nil {
		return LogSearch{}, err
	}
	if source == LogSourceClient {
		return service.searchClient(ctx, player, fromText, toText, level, limit)
	}
	if player != "" {
		return LogSearch{}, Refuse(CodeLogQueryInvalid, "the player filter applies to the client source")
	}
	return service.searchFiles(source, fromText, toText, level, limit)
}

func validateLogSource(source string) error {
	switch source {
	case LogSourceTool, LogSourceBackend, LogSourceDatabase, LogSourceClient:
		return nil
	default:
		return Refuse(CodeLogSourceInvalid, "source is one of tool, backend, database or client")
	}
}

// ClearFiles clears the agent's backend log files (C4). The tool log is never
// cleared by command (it is the audit trail) and a process log has no player
// attribution.
func (service *LogService) ClearFiles(request LogClearRequest) (LogClearResult, error) {
	if request.Source == LogSourceTool {
		return LogClearResult{}, Refuse(CodeLogToolProtected, "the tool log is the audit trail and is never cleared by command")
	}
	if request.Source != LogSourceBackend {
		return LogClearResult{}, Refuse(CodeLogSourceInvalid, "the agent clears the backend source; client logs are cleared through the backend")
	}
	files := datedLogFiles(service.Directory, BackendLogPrefix)
	switch request.Scope {
	case "all":
		return removeLogFiles(request, files, "")
	case "older_than":
		if request.OlderThan == "" {
			return LogClearResult{}, Refuse(CodeLogQueryInvalid, "older_than is required for the older_than scope")
		}
		boundary, err := time.Parse(time.RFC3339, request.OlderThan)
		if err != nil {
			return LogClearResult{}, Refuse(CodeLogQueryInvalid, "older_than must be RFC3339")
		}
		return removeLogFiles(request, files, boundary.UTC().Format("2006-01-02"))
	case "player":
		return LogClearResult{}, Refuse(CodeLogScopeInvalid, "the backend process log has no player attribution")
	default:
		return LogClearResult{}, Refuse(CodeLogScopeInvalid, "scope is one of all, player or older_than")
	}
}

func removeLogFiles(request LogClearRequest, files []datedLogFile, boundaryDate string) (LogClearResult, error) {
	removed := 0
	for _, file := range files {
		if boundaryDate != "" && file.Date >= boundaryDate {
			continue
		}
		if err := os.Remove(file.Path); err != nil && !os.IsNotExist(err) {
			return LogClearResult{}, err
		}
		removed++
	}
	return LogClearResult{Source: request.Source, Scope: request.Scope, RemovedFiles: removed}, nil
}

// ResolvePlayer turns a player id or name into the journal owner keys the
// backend timeline read needs (C2: player -> player.find).
func (service *LogService) ResolvePlayer(ctx context.Context, player string) (string, int64, error) {
	if player == "" {
		return "", 0, nil
	}
	if playerID, err := strconv.ParseInt(player, 10, 64); err == nil && playerID > 0 {
		response, err := service.read(ctx, "player.summary", url.Values{"player_id": {player}})
		if err != nil {
			return "", 0, err
		}
		var summary struct {
			PlayerID   int64  `json:"player_id"`
			AccountUID string `json:"account_uid"`
		}
		if err := json.Unmarshal(response, &summary); err != nil || summary.PlayerID == 0 {
			return "", 0, Refuse(CodeLogPlayerUnknown, "no player has this id")
		}
		return summary.AccountUID, summary.PlayerID, nil
	}
	response, err := service.read(ctx, "player.find", url.Values{"name_prefix": {player}, "limit": {"5"}})
	if err != nil {
		return "", 0, err
	}
	var page struct {
		Players []struct {
			PlayerID   int64  `json:"player_id"`
			AccountUID string `json:"account_uid"`
		} `json:"players"`
	}
	if err := json.Unmarshal(response, &page); err != nil {
		return "", 0, err
	}
	switch len(page.Players) {
	case 0:
		return "", 0, Refuse(CodeLogPlayerUnknown, "no player matches this name")
	case 1:
		return page.Players[0].AccountUID, page.Players[0].PlayerID, nil
	default:
		return "", 0, Refuse(CodeLogPlayerAmbiguous, "more than one player matches this name; use the id")
	}
}

func (service *LogService) tailClient(ctx context.Context, afterCursor, level string, limit int) (LogTail, error) {
	values := url.Values{}
	if afterCursor != "" {
		values.Set("after_cursor", afterCursor)
	}
	if level != "" {
		values.Set("level", level)
	}
	values.Set("limit", strconv.Itoa(normalizeLogLimit(limit)))
	response, err := service.read(ctx, "logs.tail", values)
	if err != nil {
		return LogTail{}, err
	}
	var reply struct {
		Entries    []json.RawMessage `json:"entries"`
		NextCursor string            `json:"next_cursor"`
	}
	if err := json.Unmarshal(response, &reply); err != nil {
		return LogTail{}, err
	}
	lines := make([]LogLine, 0, len(reply.Entries))
	for _, entry := range reply.Entries {
		lines = append(lines, clientLogLine(entry))
	}
	return LogTail{Source: LogSourceClient, Lines: lines, NextCursor: reply.NextCursor}, nil
}

func (service *LogService) searchClient(ctx context.Context, player, fromText, toText, level string, limit int) (LogSearch, error) {
	if _, err := normalizeLogLevel(level); err != nil {
		return LogSearch{}, err
	}
	uid, playerID, err := service.ResolvePlayer(ctx, player)
	if err != nil {
		return LogSearch{}, err
	}
	values := url.Values{"limit": {strconv.Itoa(normalizeLogLimit(limit))}}
	if uid != "" {
		values.Set("uid", uid)
	}
	if playerID != 0 {
		values.Set("player_id", strconv.FormatInt(playerID, 10))
	}
	if fromText != "" {
		values.Set("from", fromText)
	}
	if toText != "" {
		values.Set("to", toText)
	}
	if level != "" {
		values.Set("level", level)
	}
	response, err := service.read(ctx, "logs.timeline", values)
	if err != nil {
		return LogSearch{}, err
	}
	var reply struct {
		Entries []json.RawMessage `json:"entries"`
	}
	if err := json.Unmarshal(response, &reply); err != nil {
		return LogSearch{}, err
	}
	entries := make([]any, 0, len(reply.Entries))
	for _, entry := range reply.Entries {
		var decoded any
		if json.Unmarshal(entry, &decoded) == nil {
			entries = append(entries, MaskValue(decoded))
		}
	}
	return LogSearch{Source: LogSourceClient, Entries: entries}, nil
}

func clientLogLine(entry json.RawMessage) LogLine {
	line := LogLine{Text: MaskString(string(entry)), Level: "info"}
	if line.Text == "null" || line.Text == "" {
		line.Text = "{}"
	}
	var decoded struct {
		ReceivedAt time.Time `json:"received_at"`
		Outcome    string    `json:"outcome"`
	}
	if json.Unmarshal(entry, &decoded) == nil {
		if !decoded.ReceivedAt.IsZero() {
			line.At = decoded.ReceivedAt.UTC().Format(time.RFC3339Nano)
		}
		line.Level = clientLogLevel(decoded.Outcome)
	}
	return line
}

// clientLogLevel derives the display level from the journal outcome; C3 defines
// levels for tool and backend lines, and the journal outcome is the client fact.
func clientLogLevel(outcome string) string {
	switch outcome {
	case "SERVER_ERROR", "CLIENT_ERROR":
		return "error"
	case "UNKNOWN_MID", "UNDECODABLE":
		return "warn"
	default:
		return "info"
	}
}

func (service *LogService) read(ctx context.Context, name string, values url.Values) ([]byte, error) {
	if service.Operator == nil {
		return nil, Refuse(CodeLogBackendUnavailable, "the backend operator API is not configured")
	}
	response, err := service.Operator.Read(ctx, name, values.Encode())
	if err != nil {
		return nil, err
	}
	if response.Status != 200 {
		return nil, &BackendRefusal{Status: response.Status, Body: response.Body}
	}
	return response.Body, nil
}
