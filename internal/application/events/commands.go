package events

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/events"
	otadomain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Handlers registers the E1 command surface (I11A_EVENTS_V1 "Commands").
func (commands Commands) Handlers() map[string]operator.Handler {
	return map[string]operator.Handler{
		"events.definition.deploy": commands.deployHandler,
		"events.definition.list":   commands.definitionListHandler,
		"events.definition.reload": commands.reloadHandler,
		"events.schedule":          commands.scheduleHandler,
		"events.cancel":            commands.cancelHandler,
		"events.end_now":           commands.endNowHandler,
		"events.extend":            commands.extendHandler,
		"events.set_permanent":     commands.setPermanentHandler,
		"events.occurrence.show":   commands.occurrenceShowHandler,
		"events.cycle.mode":        commands.cycleModeHandler,
		"events.cycle.set":         commands.cycleSetHandler,
		"events.cycle.reset":       commands.cycleResetHandler,
	}
}

func decodePayload(payload json.RawMessage, target any) error {
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return err
	}
	if err := decoder.Decode(&struct{}{}); err == nil {
		return errors.New("trailing data after the payload")
	}
	return nil
}

func stale(current int64) *operator.Refusal {
	return operator.Refuse(CodeStale, "the occurrence changed since it was read", map[string]int64{"current_revision": current})
}

func requireRevision(expected *int64, current int64) *operator.Refusal {
	if expected == nil || *expected != current {
		return stale(current)
	}
	return nil
}

// DeployResult is the events.definition.deploy reply.
type DeployResult struct {
	ActivityID int64  `json:"activity_id"`
	Revision   int64  `json:"revision"`
	SHA256     string `json:"sha256"`
	Created    bool   `json:"created"`
}

func (commands Commands) deployHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	definition, err := events.ParseDefinition(command.Payload)
	if err != nil {
		return nil, operator.Refuse(CodeDefinitionInvalid, err.Error(), nil)
	}
	return commands.Deploy(ctx, scope.Tx, command.Envelope.SemanticKey, definition, scope.Operation.StartedAt)
}

// Deploy validates, expands gifts and stores one immutable revision. The same
// revision with the same stored body is idempotent; another body is refused.
func (commands Commands) Deploy(ctx context.Context, transaction tx.Tx, commandKey string, definition events.Definition, at time.Time) (DeployResult, error) {
	if transaction == nil || commandKey == "" || at.IsZero() || commands.Store == nil {
		return DeployResult{}, operator.ErrUnavailable
	}
	if commands.Gifts == nil || commands.Catalogue == nil {
		return DeployResult{}, operator.ErrUnavailable
	}
	for _, giftID := range definition.GiftIDs() {
		lines, found, err := commands.Gifts.GiftTx(ctx, transaction, giftID)
		if err != nil {
			return DeployResult{}, err
		}
		if !found || len(lines) == 0 {
			return DeployResult{}, operator.Refuse(CodeGiftUnsupported, "the backend content cannot expand this gift", map[string]int64{"gift_id": giftID})
		}
		definition.ExpandGift(giftID, lines)
	}
	if err := definition.Validate(); err != nil {
		return DeployResult{}, operator.Refuse(CodeDefinitionInvalid, err.Error(), nil)
	}
	if err := commands.checkRewards(ctx, transaction, definition); err != nil {
		return DeployResult{}, err
	}
	body, err := definition.Body()
	if err != nil {
		return DeployResult{}, err
	}
	digest := sha256.Sum256(body)
	sha := hex.EncodeToString(digest[:])
	existing, err := commands.Store.DefinitionTx(ctx, transaction, definition.ActivityID, definition.Revision)
	if err != nil {
		return DeployResult{}, err
	}
	if existing != nil {
		return deployReplay(existing, sha)
	}
	record := DefinitionRecord{ActivityID: definition.ActivityID, Revision: definition.Revision, Body: definition, SHA256: sha, DeployedByCommand: commandKey, DeployedAt: at}
	if err := commands.Store.InsertDefinitionTx(ctx, transaction, record, commandKey, at); err != nil {
		if errors.Is(err, ErrRevisionExists) {
			existing, readErr := commands.Store.DefinitionTx(ctx, transaction, definition.ActivityID, definition.Revision)
			if readErr != nil {
				return DeployResult{}, readErr
			}
			return deployReplay(existing, sha)
		}
		return DeployResult{}, err
	}
	if err := commands.Store.ClearDefinitionConflictTx(ctx, transaction, definition.ActivityID, definition.Revision); err != nil {
		return DeployResult{}, err
	}
	return DeployResult{ActivityID: definition.ActivityID, Revision: definition.Revision, SHA256: sha, Created: true}, nil
}

func deployReplay(existing *DefinitionRecord, sha string) (DeployResult, error) {
	if existing == nil {
		return DeployResult{}, operator.ErrUnavailable
	}
	if existing.SHA256 == sha {
		return DeployResult{ActivityID: existing.ActivityID, Revision: existing.Revision, SHA256: existing.SHA256}, nil
	}
	return DeployResult{}, operator.Refuse(CodeRevisionExists, "the revision is immutable and already holds another body", map[string]any{"activity_id": existing.ActivityID, "revision": existing.Revision, "sha256": existing.SHA256})
}

func (commands Commands) checkRewards(ctx context.Context, q tx.Queryer, definition events.Definition) error {
	var lines []events.RewardLine
	for _, tier := range definition.Tiers {
		for _, choice := range tier.Choices {
			lines = append(lines, choice.Lines...)
		}
	}
	if len(lines) == 0 {
		return nil
	}
	if err := commands.Catalogue.CheckRewardsTx(ctx, q, lines); err != nil {
		if errors.Is(err, economy.ErrUnknownResource) {
			return operator.Refuse(CodeDefinitionInvalid, "a reward line is not in the operator item catalogue", map[string]string{"error": err.Error()})
		}
		return err
	}
	return nil
}

// DefinitionSummary is one events.definition.list row.
type DefinitionSummary struct {
	ActivityID         int64    `json:"activity_id"`
	Revision           int64    `json:"revision"`
	Archetype          string   `json:"archetype"`
	SHA256             string   `json:"sha256"`
	DeployedAt         string   `json:"deployed_at"`
	Readiness          string   `json:"readiness"`
	MissingPaths       []string `json:"missing_paths,omitempty"`
	MissingCodeVersion string   `json:"missing_code_version,omitempty"`
	DefaultDays        int64    `json:"default_days"`
	Name               string   `json:"name,omitempty"`
	Icon               string   `json:"icon,omitempty"`
}

type definitionListPayload struct {
	ActivityID int64 `json:"activity_id,omitempty"`
	Limit      int   `json:"limit,omitempty"`
}

type definitionListResult struct {
	Definitions []DefinitionSummary `json:"definitions"`
}

func (commands Commands) definitionListHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload definitionListPayload
	if err := decodePayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	if payload.ActivityID < 0 {
		return nil, operator.Refuse(CodePayloadInvalid, "activity_id must not be negative", nil)
	}
	limit, err := boundedLimit(payload.Limit)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	rows, err := commands.Store.ListDefinitionsTx(ctx, scope.Tx, payload.ActivityID, limit)
	if err != nil {
		return nil, err
	}
	result := definitionListResult{Definitions: make([]DefinitionSummary, 0, len(rows))}
	for _, row := range rows {
		summary := DefinitionSummary{ActivityID: row.ActivityID, Revision: row.Revision, Archetype: string(row.Body.Archetype), SHA256: row.SHA256, DeployedAt: row.DeployedAt.UTC().Format(time.RFC3339Nano), DefaultDays: row.Body.DefaultDays}
		readiness, err := EvaluateReadiness(ctx, row.Body, commands.Hooks, commands.Coverage)
		if err != nil {
			return nil, err
		}
		summary.Readiness = readiness.State
		if readiness.State == ReadinessClientContentMissing {
			summary.MissingPaths = readiness.MissingPaths
			summary.MissingCodeVersion = readiness.MissingCodeVersion
		}
		if readiness.State == ReadinessReady && row.SyncConflictSHA256 != "" {
			summary.Readiness = ReadinessSyncConflict
		}
		if entry, found := commands.OperatorCatalogue.Lookup(strconv.FormatInt(row.ActivityID, 10)); found {
			summary.Name, summary.Icon = entry.Name, entry.Icon
		}
		result.Definitions = append(result.Definitions, summary)
	}
	return result, nil
}

type schedulePayload struct {
	ActivityID       int64   `json:"activity_id"`
	Scope            string  `json:"scope,omitempty"`
	LogicalServerIDs []int64 `json:"logical_server_ids,omitempty"`
	Start            string  `json:"start,omitempty"`
	Duration         string  `json:"duration"`
}

// scheduleResult is the events.schedule reply. Group is set for a global
// schedule, whose per-server occurrences are still listed in Occurrences.
type scheduleResult struct {
	Occurrences []OccurrenceView `json:"occurrences"`
	Group       *groupResult     `json:"group,omitempty"`
}

const (
	scheduleScopeServer = "server"
	scheduleScopeGlobal = "global"
)

func (commands Commands) scheduleHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload schedulePayload
	if err := decodePayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	if payload.ActivityID <= 0 {
		return nil, operator.Refuse(CodePayloadInvalid, "activity_id must be a positive client activity id", nil)
	}
	payloadScope := payload.Scope
	if payloadScope == "" {
		payloadScope = scheduleScopeServer
	}
	if payloadScope != scheduleScopeServer && payloadScope != scheduleScopeGlobal {
		return nil, operator.Refuse(CodePayloadInvalid, "scope must be server or global", nil)
	}
	duration, err := ParseDuration(payload.Duration)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	at := scope.Operation.StartedAt.UTC()
	start, err := scheduleStart(payload.Start, at)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	if payloadScope == scheduleScopeGlobal {
		if len(payload.LogicalServerIDs) != 0 {
			return nil, operator.Refuse(CodePayloadInvalid, "a global schedule takes no logical_server_ids; every current server joins", nil)
		}
		return commands.ScheduleGlobal(ctx, scope.Tx, command.Envelope.SemanticKey, payload.ActivityID, start, duration, at)
	}
	owned, err := scopedServers(payload.LogicalServerIDs, command.Envelope.Scope)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	return commands.Schedule(ctx, scope.Tx, command.Envelope.SemanticKey, payload.ActivityID, owned, start, duration, at)
}

func scopedServers(servers []int64, scope string) ([]int64, error) {
	if len(servers) == 0 || len(servers) > 100 {
		return nil, errors.New("logical_server_ids needs one to one hundred servers")
	}
	var scoped int64
	global := scope == "global"
	if !global {
		if _, err := fmt.Sscanf(scope, "server:%d", &scoped); err != nil || scoped <= 0 {
			return nil, errors.New("the envelope scope is neither global nor a server")
		}
	}
	seen := make(map[int64]struct{}, len(servers))
	out := make([]int64, 0, len(servers))
	for _, server := range servers {
		if server <= 0 {
			return nil, errors.New("a logical server id must be positive")
		}
		if !global && server != scoped {
			return nil, errors.New("a server-scoped command may only schedule its own server")
		}
		if _, duplicate := seen[server]; duplicate {
			continue
		}
		seen[server] = struct{}{}
		out = append(out, server)
	}
	return out, nil
}

func scheduleStart(text string, now time.Time) (time.Time, error) {
	if text == "" {
		return NextDayBoundary(now), nil
	}
	start, err := time.Parse(time.RFC3339, text)
	if err != nil {
		return time.Time{}, fmt.Errorf("start must be RFC3339: %w", err)
	}
	return start.UTC(), nil
}

// Schedule creates one occurrence per server after the scheduling gate
// (ruling 4) and the overlap check (ruling 2).
func (commands Commands) Schedule(ctx context.Context, transaction tx.Tx, commandKey string, activityID int64, servers []int64, start time.Time, duration Duration, at time.Time) (scheduleResult, error) {
	if transaction == nil || commandKey == "" || start.IsZero() || at.IsZero() || commands.Store == nil {
		return scheduleResult{}, operator.ErrUnavailable
	}
	if activityID <= 0 || len(servers) == 0 {
		return scheduleResult{}, operator.Refuse(CodePayloadInvalid, "activity_id and at least one logical server are required", nil)
	}
	definition, err := commands.schedulableDefinition(ctx, transaction, activityID)
	if err != nil {
		return scheduleResult{}, err
	}
	result := scheduleResult{Occurrences: make([]OccurrenceView, 0, len(servers))}
	for _, server := range servers {
		occurrence, err := commands.preparedOccurrence(ctx, transaction, definition.Revision, activityID, server, start, duration, at)
		if err != nil {
			return scheduleResult{}, err
		}
		id, err := commands.Store.InsertOccurrenceTx(ctx, transaction, occurrence, commandKey, at)
		if err != nil {
			return scheduleResult{}, occurrenceWriteRefusal(err, server, activityID)
		}
		occurrence.ID = id
		result.Occurrences = append(result.Occurrences, viewOf(occurrence, at))
	}
	return result, nil
}

// ScheduleGlobal creates one group and an occurrence on every current logical
// server in one transaction, all or nothing (EA-15 item 3). A server already
// holding an overlapping occurrence refuses the whole schedule and is named.
func (commands Commands) ScheduleGlobal(ctx context.Context, transaction tx.Tx, commandKey string, activityID int64, start time.Time, duration Duration, at time.Time) (scheduleResult, error) {
	if transaction == nil || commandKey == "" || start.IsZero() || at.IsZero() || commands.Store == nil || commands.Servers == nil {
		return scheduleResult{}, operator.ErrUnavailable
	}
	if activityID <= 0 {
		return scheduleResult{}, operator.Refuse(CodePayloadInvalid, "activity_id is required", nil)
	}
	definition, err := commands.schedulableDefinition(ctx, transaction, activityID)
	if err != nil {
		return scheduleResult{}, err
	}
	directory, err := commands.Servers.OperatorServersTx(ctx, transaction)
	if err != nil {
		return scheduleResult{}, err
	}
	occurrences := make([]events.Occurrence, 0, len(directory))
	for _, server := range directory {
		occurrence, err := commands.preparedOccurrence(ctx, transaction, definition.Revision, activityID, server.ServerID, start, duration, at)
		if err != nil {
			return scheduleResult{}, err
		}
		occurrences = append(occurrences, occurrence)
	}
	group := GlobalGroup{GlobalGroup: events.GlobalGroup{
		ActivityID: activityID, DefinitionRevision: definition.Revision, StartsAt: start,
		State: groupStateFor(start, at), Revision: 1, CreatedAt: at, CreatedByCommand: commandKey,
	}}
	if !duration.Permanent {
		end := start.Add(duration.Span)
		group.EndsAt = &end
	}
	groupID, err := commands.Store.InsertGlobalGroupTx(ctx, transaction, group, commandKey, at)
	if err != nil {
		return scheduleResult{}, err
	}
	group.ID = groupID
	result := scheduleResult{Occurrences: make([]OccurrenceView, 0, len(occurrences))}
	for index := range occurrences {
		occurrences[index].GlobalGroupID = &group.ID
		id, err := commands.Store.InsertOccurrenceTx(ctx, transaction, occurrences[index], commandKey, at)
		if err != nil {
			return scheduleResult{}, occurrenceWriteRefusal(err, occurrences[index].LogicalServerID, activityID)
		}
		occurrences[index].ID = id
		result.Occurrences = append(result.Occurrences, viewOf(occurrences[index], at))
	}
	view := groupResultOf(group, len(occurrences))
	result.Group = &view
	return result, nil
}

// schedulableDefinition is the one scheduling gate of ruling 4.
func (commands Commands) schedulableDefinition(ctx context.Context, transaction tx.Tx, activityID int64) (*DefinitionRecord, error) {
	definition, err := commands.Store.LatestDefinitionTx(ctx, transaction, activityID)
	if err != nil {
		return nil, err
	}
	if definition == nil {
		return nil, operator.Refuse(CodeDefinitionUnknown, "no definition revision is deployed for this activity", map[string]int64{"activity_id": activityID})
	}
	readiness, err := EvaluateReadiness(ctx, definition.Body, commands.Hooks, commands.Coverage)
	if err != nil {
		return nil, err
	}
	if refusal := readiness.Refusal(); refusal != nil {
		return nil, refusal
	}
	return definition, nil
}

// preparedOccurrence validates the server and the overlap law and builds the
// occurrence a schedule inserts (ruling 2).
func (commands Commands) preparedOccurrence(ctx context.Context, transaction tx.Tx, definitionRevision, activityID, server int64, start time.Time, duration Duration, at time.Time) (events.Occurrence, error) {
	settings, err := commands.Store.EnsureSettingsTx(ctx, transaction, server, at)
	if err != nil {
		if errors.Is(err, ErrServerUnknown) {
			return events.Occurrence{}, unknownServerRefusal(server)
		}
		return events.Occurrence{}, err
	}
	occurrence := events.Occurrence{
		LogicalServerID: server, ActivityID: activityID, DefinitionRevision: definitionRevision,
		StartsAt: start, Source: "OPERATOR", Revision: 1, CreatedByCommand: "", CreatedAt: at,
	}
	if !duration.Permanent {
		end := start.Add(duration.Span)
		claimUntil := end.Add(settings.ClaimWindow)
		occurrence.EndsAt = &end
		occurrence.ClaimUntil = &claimUntil
	}
	if _, err := commands.Store.LockOccurrencesTx(ctx, transaction, server, activityID); err != nil {
		return events.Occurrence{}, err
	}
	overlaps, err := commands.Store.OverlapsTx(ctx, transaction, server, activityID, start, occurrence.ClaimUntil, 0)
	if err != nil {
		return events.Occurrence{}, err
	}
	if overlaps {
		return events.Occurrence{}, overlapRefusal(server, activityID)
	}
	return occurrence, nil
}

func occurrenceWriteRefusal(err error, server, activityID int64) error {
	switch {
	case errors.Is(err, ErrOccurrenceOverlap):
		return overlapRefusal(server, activityID)
	case errors.Is(err, ErrServerUnknown):
		return unknownServerRefusal(server)
	}
	return err
}

func groupStateFor(start, at time.Time) string {
	if at.Before(start) {
		return events.GroupScheduled
	}
	return events.GroupRunning
}

func unknownServerRefusal(server int64) *operator.Refusal {
	return operator.Refuse(CodeServerUnknown, "the logical server does not exist", map[string]int64{"logical_server_id": server})
}

func overlapRefusal(server, activityID int64) *operator.Refusal {
	return operator.Refuse(CodeOverlap, "another occurrence of this activity overlaps on the server", map[string]any{"logical_server_id": server, "activity_id": activityID})
}

func hookGate(definition events.Definition, registry HookRegistry) *operator.Refusal {
	for _, hook := range definition.Hooks {
		if !registry.Registered(hook.Kind) {
			return operator.Refuse(CodeHookUnbuilt, "a hook kind of this definition has no built owner", map[string]string{"hook": hook.Kind})
		}
	}
	return nil
}

func coverageGate(coverage otadomain.CoversResult) *operator.Refusal {
	if coverage.Status == otadomain.CoversCovered {
		return nil
	}
	return operator.Refuse(CodeClientContentMissed, "the OTA release does not cover this event's client content", map[string]any{
		"missing_client_paths": coverage.MissingClientPaths,
		"missing_lazy_assets":  coverage.MissingLazyAssets,
		"missing_code_version": coverage.MissingCodeVersion,
	})
}

type occurrencePayload struct {
	OccurrenceID int64 `json:"occurrence_id,omitempty"`
	GroupID      int64 `json:"group_id,omitempty"`
}

func decodeOccurrence(payload json.RawMessage) (int64, error) {
	var decoded occurrencePayload
	if err := decodePayload(payload, &decoded); err != nil {
		return 0, err
	}
	if decoded.OccurrenceID <= 0 || decoded.GroupID != 0 {
		return 0, errors.New("occurrence_id is required and group_id is not allowed here")
	}
	return decoded.OccurrenceID, nil
}

// decodeMutation reads the one target of events.end_now and
// events.set_permanent: a single occurrence, or a global group (EA-15 item 6).
func decodeMutation(payload json.RawMessage) (occurrenceID, groupID int64, err error) {
	var decoded occurrencePayload
	if err := decodePayload(payload, &decoded); err != nil {
		return 0, 0, err
	}
	switch {
	case decoded.OccurrenceID > 0 && decoded.GroupID > 0:
		return 0, 0, errors.New("give either occurrence_id or group_id, not both")
	case decoded.OccurrenceID <= 0 && decoded.GroupID <= 0:
		return 0, 0, errors.New("occurrence_id or group_id is required")
	}
	return decoded.OccurrenceID, decoded.GroupID, nil
}

// mutate locks one occurrence FOR UPDATE, checks its revision, applies the
// command-specific change and saves it. The caller holds the bus row lock.
func (commands Commands) mutate(ctx context.Context, transaction tx.Tx, occurrenceID int64, expected *int64, at time.Time, checkOverlap bool, apply func(*events.Occurrence, time.Time) error) (OccurrenceView, error) {
	if transaction == nil || occurrenceID <= 0 || at.IsZero() {
		return OccurrenceView{}, operator.ErrUnavailable
	}
	occurrence, err := commands.Store.LockOccurrenceTx(ctx, transaction, occurrenceID)
	if err != nil {
		return OccurrenceView{}, err
	}
	if occurrence == nil {
		return OccurrenceView{}, operator.Refuse(CodeOccurrenceUnknown, "the occurrence does not exist", map[string]int64{"occurrence_id": occurrenceID})
	}
	if refusal := requireRevision(expected, occurrence.Revision); refusal != nil {
		return OccurrenceView{}, refusal
	}
	if err := apply(occurrence, at); err != nil {
		return OccurrenceView{}, err
	}
	if checkOverlap {
		overlaps, err := commands.Store.OverlapsTx(ctx, transaction, occurrence.LogicalServerID, occurrence.ActivityID, occurrence.StartsAt, occurrence.ClaimUntil, occurrence.ID)
		if err != nil {
			return OccurrenceView{}, err
		}
		if overlaps {
			return OccurrenceView{}, overlapRefusal(occurrence.LogicalServerID, occurrence.ActivityID)
		}
	}
	if err := commands.Store.SaveOccurrenceTx(ctx, transaction, *occurrence); err != nil {
		if errors.Is(err, ErrOccurrenceOverlap) {
			return OccurrenceView{}, overlapRefusal(occurrence.LogicalServerID, occurrence.ActivityID)
		}
		return OccurrenceView{}, err
	}
	return viewOf(*occurrence, at), nil
}

func (commands Commands) cancelHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	occurrenceID, err := decodeOccurrence(command.Payload)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	return commands.mutate(ctx, scope.Tx, occurrenceID, command.Envelope.ExpectedRevision, scope.Operation.StartedAt.UTC(), false, func(occurrence *events.Occurrence, at time.Time) error {
		if occurrence.State(at) != events.PhaseScheduled {
			return operator.Refuse(CodeStateInvalid, "only a SCHEDULED occurrence can be cancelled", map[string]string{"state": string(occurrence.State(at))})
		}
		occurrence.CancelledAt = &at
		occurrence.CancelledByCommand = command.Envelope.SemanticKey
		occurrence.Revision++
		return nil
	})
}

func (commands Commands) endNowHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	occurrenceID, groupID, err := decodeMutation(command.Payload)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	at := scope.Operation.StartedAt.UTC()
	if groupID > 0 {
		return commands.endGroupNow(ctx, scope.Tx, groupID, command.Envelope.ExpectedRevision, command.Envelope.SemanticKey, at)
	}
	return commands.mutate(ctx, scope.Tx, occurrenceID, command.Envelope.ExpectedRevision, at, false, func(occurrence *events.Occurrence, at time.Time) error {
		if !occurrence.Active(at) {
			return operator.Refuse(CodeStateInvalid, "only a RUNNING or CLAIM_WINDOW occurrence can be ended now", map[string]string{"state": string(occurrence.State(at))})
		}
		settings, err := commands.Store.EnsureSettingsTx(ctx, scope.Tx, occurrence.LogicalServerID, at)
		if err != nil {
			return err
		}
		claimUntil := at.Add(settings.ClaimWindow)
		occurrence.EndsAt = &at
		occurrence.ClaimUntil = &claimUntil
		occurrence.EndedEarlyByCommand = command.Envelope.SemanticKey
		occurrence.Revision++
		return nil
	})
}

type extendPayload struct {
	OccurrenceID int64  `json:"occurrence_id"`
	Duration     string `json:"duration"`
}

func (commands Commands) extendHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload extendPayload
	if err := decodePayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	if payload.OccurrenceID <= 0 {
		return nil, operator.Refuse(CodePayloadInvalid, "occurrence_id is required", nil)
	}
	duration, err := ParseDuration(payload.Duration)
	if err != nil || duration.Permanent {
		return nil, operator.Refuse(CodePayloadInvalid, "extend needs a timed duration", nil)
	}
	return commands.mutate(ctx, scope.Tx, payload.OccurrenceID, command.Envelope.ExpectedRevision, scope.Operation.StartedAt.UTC(), true, func(occurrence *events.Occurrence, at time.Time) error {
		if occurrence.Permanent() {
			return operator.Refuse(CodeStateInvalid, "a permanent occurrence has no end to move", nil)
		}
		if phase := occurrence.State(at); phase != events.PhaseScheduled && phase != events.PhaseRunning {
			return operator.Refuse(CodeStateInvalid, "only a SCHEDULED or RUNNING occurrence can be extended", map[string]string{"state": string(phase)})
		}
		end := occurrence.EndsAt.Add(duration.Span)
		claimUntil := occurrence.ClaimUntil.Add(duration.Span)
		occurrence.EndsAt = &end
		occurrence.ClaimUntil = &claimUntil
		occurrence.Revision++
		return nil
	})
}

func (commands Commands) setPermanentHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	occurrenceID, groupID, err := decodeMutation(command.Payload)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	at := scope.Operation.StartedAt.UTC()
	if groupID > 0 {
		return commands.setGroupPermanent(ctx, scope.Tx, groupID, command.Envelope.ExpectedRevision, at)
	}
	return commands.mutate(ctx, scope.Tx, occurrenceID, command.Envelope.ExpectedRevision, at, true, func(occurrence *events.Occurrence, at time.Time) error {
		if phase := occurrence.State(at); phase != events.PhaseScheduled && phase != events.PhaseRunning {
			return operator.Refuse(CodeStateInvalid, "only a SCHEDULED or RUNNING occurrence can become permanent", map[string]string{"state": string(phase)})
		}
		if occurrence.Permanent() {
			return nil
		}
		occurrence.EndsAt = nil
		occurrence.ClaimUntil = nil
		occurrence.Revision++
		return nil
	})
}

// groupResult is the reply of a global group command.
type groupResult struct {
	GroupID         int64      `json:"group_id"`
	State           string     `json:"state"`
	Revision        int64      `json:"revision"`
	StartsAt        time.Time  `json:"starts_at"`
	EndsAt          *time.Time `json:"ends_at"`
	EndedAt         *time.Time `json:"ended_at"`
	OccurrenceCount int        `json:"occurrence_count"`
}

func groupResultOf(group GlobalGroup, occurrenceCount int) groupResult {
	return groupResult{
		GroupID: group.ID, State: group.State, Revision: group.Revision,
		StartsAt: group.StartsAt.UTC(), EndsAt: utcPtr(group.EndsAt), EndedAt: utcPtr(group.EndedAt), OccurrenceCount: occurrenceCount,
	}
}

func groupUnknownRefusal(groupID int64) *operator.Refusal {
	return operator.Refuse(CodeGroupUnknown, "the global event group does not exist", map[string]int64{"group_id": groupID})
}

// endGroupNow ends the group and every one of its occurrences in one
// transaction, all or nothing (EA-15 item 6). An ended group stops joining.
func (commands Commands) endGroupNow(ctx context.Context, transaction tx.Tx, groupID int64, expected *int64, commandKey string, at time.Time) (groupResult, error) {
	if transaction == nil || groupID <= 0 || at.IsZero() || commandKey == "" || commands.Store == nil {
		return groupResult{}, operator.ErrUnavailable
	}
	group, err := commands.Store.LockGlobalGroupTx(ctx, transaction, groupID)
	if err != nil {
		return groupResult{}, err
	}
	if group == nil {
		return groupResult{}, groupUnknownRefusal(groupID)
	}
	if refusal := requireRevision(expected, group.Revision); refusal != nil {
		return groupResult{}, refusal
	}
	if phase := group.Phase(at); phase != events.PhaseRunning && phase != events.PhaseClaimWindow {
		return groupResult{}, operator.Refuse(CodeStateInvalid, "only a RUNNING group can be ended now", map[string]string{"state": string(phase)})
	}
	occurrences, err := commands.Store.LockGroupOccurrencesTx(ctx, transaction, groupID)
	if err != nil {
		return groupResult{}, err
	}
	if err := commands.endGroupOccurrences(ctx, transaction, occurrences, commandKey, at); err != nil {
		return groupResult{}, err
	}
	group.EndsAt = &at
	group.EndedAt = &at
	group.State = events.GroupEnded
	group.Revision++
	if err := commands.Store.SaveGlobalGroupTx(ctx, transaction, *group); err != nil {
		return groupResult{}, err
	}
	return groupResultOf(*group, len(occurrences)), nil
}

func (commands Commands) endGroupOccurrences(ctx context.Context, transaction tx.Tx, occurrences []events.Occurrence, commandKey string, at time.Time) error {
	for index := range occurrences {
		settings, err := commands.Store.EnsureSettingsTx(ctx, transaction, occurrences[index].LogicalServerID, at)
		if err != nil {
			return err
		}
		claimUntil := at.Add(settings.ClaimWindow)
		occurrences[index].EndsAt = &at
		occurrences[index].ClaimUntil = &claimUntil
		occurrences[index].EndedEarlyByCommand = commandKey
		occurrences[index].Revision++
		if err := commands.Store.SaveOccurrenceTx(ctx, transaction, occurrences[index]); err != nil {
			return err
		}
	}
	return nil
}

// setGroupPermanent makes the group and all its occurrences permanent in one
// transaction (EA-15 item 6).
func (commands Commands) setGroupPermanent(ctx context.Context, transaction tx.Tx, groupID int64, expected *int64, at time.Time) (groupResult, error) {
	if transaction == nil || groupID <= 0 || at.IsZero() || commands.Store == nil {
		return groupResult{}, operator.ErrUnavailable
	}
	group, err := commands.Store.LockGlobalGroupTx(ctx, transaction, groupID)
	if err != nil {
		return groupResult{}, err
	}
	if group == nil {
		return groupResult{}, groupUnknownRefusal(groupID)
	}
	if refusal := requireRevision(expected, group.Revision); refusal != nil {
		return groupResult{}, refusal
	}
	if phase := group.Phase(at); phase != events.PhaseScheduled && phase != events.PhaseRunning {
		return groupResult{}, operator.Refuse(CodeStateInvalid, "only a SCHEDULED or RUNNING group can become permanent", map[string]string{"state": string(phase)})
	}
	occurrences, err := commands.Store.LockGroupOccurrencesTx(ctx, transaction, groupID)
	if err != nil {
		return groupResult{}, err
	}
	if group.EndsAt == nil {
		return groupResultOf(*group, len(occurrences)), nil
	}
	for index := range occurrences {
		occurrences[index].EndsAt = nil
		occurrences[index].ClaimUntil = nil
		occurrences[index].Revision++
		if err := commands.Store.SaveOccurrenceTx(ctx, transaction, occurrences[index]); err != nil {
			return groupResult{}, err
		}
	}
	group.EndsAt = nil
	group.State = groupStateFor(group.StartsAt, at)
	group.Revision++
	if err := commands.Store.SaveGlobalGroupTx(ctx, transaction, *group); err != nil {
		return groupResult{}, err
	}
	return groupResultOf(*group, len(occurrences)), nil
}

type occurrenceShowPayload struct {
	OccurrenceID int64 `json:"occurrence_id"`
	Limit        int   `json:"limit,omitempty"`
}

// ClaimView is one bounded occurrence.show claim row.
type ClaimView struct {
	PlayerID  int64     `json:"player_id"`
	Tier      int64     `json:"tier"`
	Period    string    `json:"period"`
	Choice    int       `json:"choice"`
	ClaimedAt time.Time `json:"claimed_at"`
}

type occurrenceShowResult struct {
	Occurrence OccurrenceView `json:"occurrence"`
	ClaimCount int            `json:"claim_count"`
	Truncated  bool           `json:"truncated"`
	Claims     []ClaimView    `json:"claims"`
}

func (commands Commands) occurrenceShowHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload occurrenceShowPayload
	if err := decodePayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	if payload.OccurrenceID <= 0 {
		return nil, operator.Refuse(CodePayloadInvalid, "occurrence_id is required", nil)
	}
	limit, err := boundedLimit(payload.Limit)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	occurrence, err := commands.Store.OccurrenceTx(ctx, scope.Tx, payload.OccurrenceID)
	if err != nil {
		return nil, err
	}
	if occurrence == nil {
		return nil, operator.Refuse(CodeOccurrenceUnknown, "the occurrence does not exist", map[string]int64{"occurrence_id": payload.OccurrenceID})
	}
	claims, err := commands.Store.OccurrenceClaimsTx(ctx, scope.Tx, payload.OccurrenceID, limit+1)
	if err != nil {
		return nil, err
	}
	count, err := commands.Store.CountOccurrenceClaimsTx(ctx, scope.Tx, payload.OccurrenceID)
	if err != nil {
		return nil, err
	}
	result := occurrenceShowResult{Occurrence: viewOf(*occurrence, scope.Operation.StartedAt), ClaimCount: count, Claims: make([]ClaimView, 0, limit)}
	if len(claims) > limit {
		claims = claims[:limit]
		result.Truncated = true
	}
	for _, claim := range claims {
		result.Claims = append(result.Claims, ClaimView{PlayerID: claim.PlayerID, Tier: claim.Tier, Period: claim.Period, Choice: claim.Choice, ClaimedAt: claim.ClaimedAt.UTC()})
	}
	return result, nil
}
