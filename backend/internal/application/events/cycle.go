package events

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/application/operator"
	domainevents "gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// CodeCycleInvalid is the refusal of an unreadable or non-monotonic cycle body.
const CodeCycleInvalid = "EVENT_CYCLE_INVALID"

// CycleModeAuto and CycleModeOff are the per-server materialiser modes (F1).
const (
	CycleModeAuto = "AUTO"
	CycleModeOff  = "OFF"
)

// CycleSettingView is the operator reply for one server's cycle settings.
type CycleSettingView struct {
	LogicalServerID int64  `json:"logical_server_id"`
	Mode            string `json:"mode"`
	CycleRevision   int64  `json:"cycle_revision"`
	Lookahead       int    `json:"lookahead"`
}

type cycleSettingsResult struct {
	Settings []CycleSettingView `json:"settings"`
}

func cycleView(server int64, settings Settings) CycleSettingView {
	return CycleSettingView{LogicalServerID: server, Mode: settings.Mode, CycleRevision: settings.CycleRevision, Lookahead: settings.Lookahead}
}

type cycleModePayload struct {
	LogicalServerIDs []int64 `json:"logical_server_ids"`
	Mode             string  `json:"mode"`
}

func (commands Commands) cycleModeHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload cycleModePayload
	if err := decodePayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	if payload.Mode != CycleModeAuto && payload.Mode != CycleModeOff {
		return nil, operator.Refuse(CodePayloadInvalid, "mode must be AUTO or OFF", nil)
	}
	servers, err := scopedServers(payload.LogicalServerIDs, command.Envelope.Scope)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	if commands.Store == nil {
		return nil, operator.ErrUnavailable
	}
	at := scope.Operation.StartedAt.UTC()
	result := cycleSettingsResult{Settings: make([]CycleSettingView, 0, len(servers))}
	for _, server := range servers {
		settings, err := commands.Store.SetCycleModeTx(ctx, scope.Tx, server, payload.Mode, command.Envelope.SemanticKey, at)
		if err != nil {
			if errors.Is(err, ErrServerUnknown) {
				return nil, unknownServerRefusal(server)
			}
			return nil, err
		}
		result.Settings = append(result.Settings, cycleView(server, settings))
	}
	return result, nil
}

type cycleSetPayload struct {
	LogicalServerIDs []int64         `json:"logical_server_ids"`
	Cycle            json.RawMessage `json:"cycle"`
}

func (commands Commands) cycleSetHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload cycleSetPayload
	if err := decodePayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	servers, err := scopedServers(payload.LogicalServerIDs, command.Envelope.Scope)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	cycle, err := domainevents.ParseCycle(payload.Cycle)
	if err != nil {
		return nil, operator.Refuse(CodeCycleInvalid, err.Error(), nil)
	}
	expected := command.Envelope.ExpectedRevision
	if expected == nil {
		return nil, operator.Refuse(CodePayloadInvalid, "expected_revision is required to replace the cycle", nil)
	}
	if cycle.Revision <= *expected {
		return nil, operator.Refuse(CodeCycleInvalid, "the cycle revision must increase", map[string]int64{"current_revision": *expected, "new_revision": cycle.Revision})
	}
	body, err := cycle.Body()
	if err != nil {
		return nil, err
	}
	return commands.writeCycle(ctx, scope, command, servers, *expected, cycle.Revision, body)
}

type cycleResetPayload struct {
	LogicalServerIDs []int64 `json:"logical_server_ids"`
}

func (commands Commands) cycleResetHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload cycleResetPayload
	if err := decodePayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	servers, err := scopedServers(payload.LogicalServerIDs, command.Envelope.Scope)
	if err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	expected := command.Envelope.ExpectedRevision
	if expected == nil {
		return nil, operator.Refuse(CodePayloadInvalid, "expected_revision is required to reset the cycle", nil)
	}
	return commands.writeCycle(ctx, scope, command, servers, *expected, 0, nil)
}

func (commands Commands) writeCycle(ctx context.Context, scope tx.Scope, command operator.Command, servers []int64, expected, revision int64, body json.RawMessage) (any, error) {
	if commands.Store == nil {
		return nil, operator.ErrUnavailable
	}
	at := scope.Operation.StartedAt.UTC()
	result := cycleSettingsResult{Settings: make([]CycleSettingView, 0, len(servers))}
	for _, server := range servers {
		settings, applied, err := commands.Store.SetCycleBodyTx(ctx, scope.Tx, server, expected, revision, body, command.Envelope.SemanticKey, at)
		if err != nil {
			if errors.Is(err, ErrServerUnknown) {
				return nil, unknownServerRefusal(server)
			}
			return nil, err
		}
		if !applied {
			return nil, operator.Refuse(CodeStale, "the cycle changed since it was read", map[string]int64{"logical_server_id": server, "current_revision": settings.CycleRevision})
		}
		result.Settings = append(result.Settings, cycleView(server, settings))
	}
	return result, nil
}
