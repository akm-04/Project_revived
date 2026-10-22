package stockruntime

import (
	"context"
	"errors"
	"net/http"

	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// CA6-3 owns only the source-qualified non-AUTO Practice wire partition.
// 127/132 remain CA6-4 and 134 remains CA3-3 Pet EXP.
type practiceWireKind uint8

const (
	practiceWireGet practiceWireKind = iota + 1
	practiceWireManual
	practiceWireSave
	practiceWireTicket
)

type practiceWireRequest struct {
	Kind         practiceWireKind
	Hero         bool
	ActorID      int64
	Locks        [3]int64
	PracticeType int64
}

func practiceWireMID(mid uint16) (practiceWireKind, bool, bool) {
	switch mid {
	case 124:
		return practiceWireGet, true, true
	case 125:
		return practiceWireManual, true, true
	case 126:
		return practiceWireSave, true, true
	case 128:
		return practiceWireTicket, true, true
	case 129:
		return practiceWireGet, false, true
	case 130:
		return practiceWireManual, false, true
	case 131:
		return practiceWireSave, false, true
	case 133:
		return practiceWireTicket, false, true
	default:
		return 0, false, false
	}
}

func decodePracticeLocks(raw any) ([3]int64, error) {
	var out [3]int64
	values, ok := raw.([]any)
	if !ok || len(values) != len(out) {
		return out, errors.New("invalid Practice lock vector")
	}
	for i, rawValue := range values {
		v, err := requiredInt64(map[string]any{"value": rawValue}, "value")
		if err != nil || (v != 0 && v != 1) {
			return [3]int64{}, errors.New("invalid Practice lock bit")
		}
		out[i] = v
	}
	return out, nil
}

func decodePracticeWireRequest(mid uint16, params map[string]any) (practiceWireRequest, error) {
	kind, hero, ok := practiceWireMID(mid)
	if !ok {
		return practiceWireRequest{}, errors.New("not a CA6-3 non-AUTO Practice MID")
	}
	if kind == practiceWireGet {
		if !onlyStockGameplayParams(params) {
			return practiceWireRequest{}, errors.New("invalid Practice GET params")
		}
		return practiceWireRequest{Kind: kind, Hero: hero}, nil
	}
	actorKey := "pet_id"
	if hero {
		actorKey = "partner_id"
	}
	if kind == practiceWireManual {
		if !onlyStockGameplayParams(params, actorKey, "locks", "practice_type") {
			return practiceWireRequest{}, errors.New("invalid Practice manual params")
		}
		actorID, err := requiredInt64(params, actorKey)
		if err != nil || actorID <= 0 {
			return practiceWireRequest{}, errors.New("invalid Practice actor")
		}
		locks, err := decodePracticeLocks(params["locks"])
		if err != nil {
			return practiceWireRequest{}, err
		}
		method, err := requiredInt64(params, "practice_type")
		if err != nil || method < 1 || method > 3 {
			return practiceWireRequest{}, errors.New("invalid Practice method")
		}
		return practiceWireRequest{Kind: kind, Hero: hero, ActorID: actorID, Locks: locks, PracticeType: method}, nil
	}
	if !onlyStockGameplayParams(params, actorKey) {
		return practiceWireRequest{}, errors.New("invalid Practice actor-only params")
	}
	actorID, err := requiredInt64(params, actorKey)
	if err != nil || actorID <= 0 {
		return practiceWireRequest{}, errors.New("invalid Practice actor")
	}
	return practiceWireRequest{Kind: kind, Hero: hero, ActorID: actorID}, nil
}

type PracticeGameplayPort interface {
	GetInfo(context.Context, identity.PlayerID, operationContext) (apppractice.Info, error)
	Manual(context.Context, identity.ActorContext, apppractice.ManualCommand, operationContext) (apppractice.ManualResult, error)
	Save(context.Context, identity.ActorContext, apppractice.Target, operationContext) (apppractice.SaveResult, error)
	Ticket(context.Context, identity.ActorContext, apppractice.Target, operationContext) (apppractice.ManualResult, error)
	Auto(context.Context, identity.ActorContext, apppractice.AutoCommand, operationContext) (apppractice.AutoResult, error)
}

// operationContext is an alias kept local to make the dispatcher port concise
// without wrapping or transforming the authoritative edge-created context.
type operationContext = operation.Context

// PracticeDispatcher owns the qualified Practice wire family. The CA6-3
// non-AUTO partition remains decoded here; CA6-4 AUTO is isolated in its own
// adapter helper so historical partition/source guards remain independently
// enforceable. It owns no gameplay facts.
type PracticeDispatcher struct {
	Authority apprealtime.GameplayAuthorityPort
	Service   PracticeGameplayPort
	Tracker   *lobby.BootTracker
}

func practiceInfoBody(info apppractice.Info) map[string]any {
	attrs := []any{info.PracticeAttr[0], info.PracticeAttr[1], info.PracticeAttr[2]}
	locks := make([]any, len(info.Lock))
	for i, v := range info.Lock {
		locks[i] = v
	}
	return map[string]any{
		"last_time": info.LastTime, "practice_attr": attrs, "lock": locks,
		"times": info.Times, "base_crystal": info.BaseCrystal, "base_mana": info.BaseMana,
		"bless_value": info.BlessValue,
	}
}

func practiceDeltaBody(d apppractice.PracticeDelta) []any { return []any{d[0], d[1], d[2]} }

func (d PracticeDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	actor, fail := d.practiceActor(ctx, req)
	if fail != nil {
		return *fail
	}
	if _, ok := practiceAutoMID(req.Envelope.MID); ok {
		return d.dispatchPracticeAuto(ctx, req, actor)
	}
	wire, err := decodePracticeWireRequest(req.Envelope.MID, req.Envelope.Params)
	if err != nil {
		if _, _, ok := practiceWireMID(req.Envelope.MID); !ok {
			return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_practice_mid"}}
		}
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "invalid_practice_request"}}
	}
	if d.Service == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "practice_unavailable"}}
	}

	target := apppractice.Target{Hero: wire.Hero, ActorID: wire.ActorID}
	switch wire.Kind {
	case practiceWireGet:
		info, err := d.Service.GetInfo(ctx, actor.PlayerID, req.Envelope.Operation)
		if err != nil {
			return practiceFailure(err)
		}
		// MID124 historically participates in BootLegitTimer telemetry. Record
		// only after bearer/region validation and a qualified projection; this
		// remains observation, never gameplay authority.
		if req.Envelope.MID == 124 && d.Tracker != nil {
			_ = d.Tracker.Record(d.Tracker.Correlate(lobby.BootEvent{MID: 124, Kind: lobby.BootLegitTimer, Phase: lobby.PhaseClientRequestObserved, At: req.Envelope.ReceivedAt}, actor.SessionID.UUID().String(), actor.ContextID.UUID().String(), ""))
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: practiceInfoBody(info)}
	case practiceWireManual:
		locks := apppractice.PracticeLocks{wire.Locks[0] == 1, wire.Locks[1] == 1, wire.Locks[2] == 1}
		out, err := d.Service.Manual(ctx, actor, apppractice.ManualCommand{Target: target, Locks: locks, Method: wire.PracticeType}, req.Envelope.Operation)
		if err != nil {
			return practiceFailure(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"info": practiceInfoBody(out.Info), "add_attr": practiceDeltaBody(out.AddAttr)}}
	case practiceWireSave:
		out, err := d.Service.Save(ctx, actor, target, req.Envelope.Operation)
		if err != nil {
			return practiceFailure(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"practice_attr": []any{out.PracticeAttr[0], out.PracticeAttr[1], out.PracticeAttr[2]}}}
	case practiceWireTicket:
		out, err := d.Service.Ticket(ctx, actor, target, req.Envelope.Operation)
		if err != nil {
			return practiceFailure(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"info": practiceInfoBody(out.Info), "add_attr": practiceDeltaBody(out.AddAttr)}}
	default:
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_practice_mid"}}
	}
}

func practiceFailure(err error) httpedge.Response {
	if err == nil {
		err = errors.New("character practice failed")
	}
	var conflict *receipt.ConflictError
	var unknown *tx.UnknownCommitError
	switch {
	case errors.As(err, &unknown):
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "practice_commit_unknown"}}
	case errors.As(err, &conflict), errors.Is(err, apppractice.ErrActorStaleVersion), errors.Is(err, apppractice.ErrStaleVersion), errors.Is(err, apppractice.ErrCandidateMissing):
		return httpedge.Response{HTTPStatus: http.StatusConflict, Body: map[string]any{"error": "practice_state_conflict"}}
	case errors.Is(err, apppractice.ErrPracticeAdmission), errors.Is(err, apppractice.ErrPracticePrivilege), errors.Is(err, apppractice.ErrPracticeBless), errors.Is(err, appi5.ErrLevelRequirement), errors.Is(err, economy.ErrInsufficientBalance), errors.Is(err, economy.ErrUnknownResource), errors.Is(err, apppractice.ErrAllPracticeAttrsAtCap), errors.Is(err, apppractice.ErrInvalidPracticeMethod), errors.Is(err, apppractice.ErrEmptyRollSupport):
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "practice_rejected"}}
	default:
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "practice_unavailable"}}
	}
}

func (d PracticeDispatcher) practiceActor(ctx context.Context, req httpedge.DispatchRequest) (identity.ActorContext, *httpedge.Response) {
	if d.Authority == nil || req.Envelope.Claims.Token == "" {
		r := httpedge.Response{HTTPStatus: http.StatusUnauthorized, Body: map[string]any{"error": "gameplay_auth_required"}}
		return identity.ActorContext{}, &r
	}
	actor, err := d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt)
	if err != nil {
		r := authFailure(err)
		return identity.ActorContext{}, &r
	}
	if req.Envelope.Claims.Region != int64(actor.LogicalServerID) {
		r := httpedge.Response{HTTPStatus: http.StatusForbidden, Body: map[string]any{"error": "region_mismatch"}}
		return identity.ActorContext{}, &r
	}
	return actor, nil
}
