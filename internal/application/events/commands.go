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
	ActivityID   int64    `json:"activity_id"`
	Revision     int64    `json:"revision"`
	Archetype    string   `json:"archetype"`
	SHA256       string   `json:"sha256"`
	DeployedAt   string   `json:"deployed_at"`
	Readiness    string   `json:"readiness"`
	MissingPaths []string `json:"missing_paths,omitempty"`
	DefaultDays  int64    `json:"default_days"`
	Name         string   `json:"name,omitempty"`
	Icon         string   `json:"icon,omitempty"`
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
	LogicalServerIDs []int64 `json:"logical_server_ids"`
	Start            string  `json:"start,omitempty"`
	Duration         string  `json:"duration"`
}

type scheduleResult struct {
	Occurrences []OccurrenceView `json:"occurrences"`
}

func (commands Commands) scheduleHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload schedulePayload
	if err := decodePayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	if payload.ActivityID <= 0 {
		return nil, operator.Refuse(CodePayloadInvalid, "activity_id must be a positive client activity id", nil)
	}
	owned, err := scopedServers(payload.LogicalServerIDs, command.Envelope.Scope)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
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
	definition, err := commands.Store.LatestDefinitionTx(ctx, transaction, activityID)
	if err != nil {
		return scheduleResult{}, err
	}
	if definition == nil {
		return scheduleResult{}, operator.Refuse(CodeDefinitionUnknown, "no definition revision is deployed for this activity", map[string]int64{"activity_id": activityID})
	}
	readiness, err := EvaluateReadiness(ctx, definition.Body, commands.Hooks, commands.Coverage)
	if err != nil {
		return scheduleResult{}, err
	}
	if refusal := readiness.Refusal(); refusal != nil {
		return scheduleResult{}, refusal
	}
	result := scheduleResult{Occurrences: make([]OccurrenceView, 0, len(servers))}
	for _, server := range servers {
		settings, err := commands.Store.EnsureSettingsTx(ctx, transaction, server, at)
		if err != nil {
			if errors.Is(err, ErrServerUnknown) {
				return scheduleResult{}, unknownServerRefusal(server)
			}
			return scheduleResult{}, err
		}
		occurrence := events.Occurrence{
			LogicalServerID: server, ActivityID: activityID, DefinitionRevision: definition.Revision,
			StartsAt: start, Source: "OPERATOR", Revision: 1, CreatedByCommand: commandKey, CreatedAt: at,
		}
		if !duration.Permanent {
			end := start.Add(duration.Span)
			claimUntil := end.Add(settings.ClaimWindow)
			occurrence.EndsAt = &end
			occurrence.ClaimUntil = &claimUntil
		}
		if _, err := commands.Store.LockOccurrencesTx(ctx, transaction, server, activityID); err != nil {
			return scheduleResult{}, err
		}
		overlaps, err := commands.Store.OverlapsTx(ctx, transaction, server, activityID, start, occurrence.ClaimUntil, 0)
		if err != nil {
			return scheduleResult{}, err
		}
		if overlaps {
			return scheduleResult{}, overlapRefusal(server, activityID)
		}
		id, err := commands.Store.InsertOccurrenceTx(ctx, transaction, occurrence, commandKey, at)
		if err != nil {
			switch {
			case errors.Is(err, ErrOccurrenceOverlap):
				return scheduleResult{}, overlapRefusal(server, activityID)
			case errors.Is(err, ErrServerUnknown):
				return scheduleResult{}, unknownServerRefusal(server)
			}
			return scheduleResult{}, err
		}
		occurrence.ID = id
		result.Occurrences = append(result.Occurrences, viewOf(occurrence, at))
	}
	return result, nil
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
	OccurrenceID int64 `json:"occurrence_id"`
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

func decodeOccurrence(payload json.RawMessage) (int64, error) {
	var decoded occurrencePayload
	if err := decodePayload(payload, &decoded); err != nil {
		return 0, err
	}
	if decoded.OccurrenceID <= 0 {
		return 0, errors.New("occurrence_id is required")
	}
	return decoded.OccurrenceID, nil
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
	occurrenceID, err := decodeOccurrence(command.Payload)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	return commands.mutate(ctx, scope.Tx, occurrenceID, command.Envelope.ExpectedRevision, scope.Operation.StartedAt.UTC(), false, func(occurrence *events.Occurrence, at time.Time) error {
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
	occurrenceID, err := decodeOccurrence(command.Payload)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	return commands.mutate(ctx, scope.Tx, occurrenceID, command.Envelope.ExpectedRevision, scope.Operation.StartedAt.UTC(), true, func(occurrence *events.Occurrence, at time.Time) error {
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
