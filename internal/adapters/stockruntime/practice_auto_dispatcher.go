package stockruntime

import (
	"context"
	"net/http"

	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// dispatchPracticeAuto is the CA6-4 stock projection for MIDs 127/132. Caller
// authentication/region validation has already succeeded in PracticeDispatcher.
func (d PracticeDispatcher) dispatchPracticeAuto(ctx context.Context, req httpedge.DispatchRequest, actor identity.ActorContext) httpedge.Response {
	wire, err := decodePracticeAutoWireRequest(req.Envelope.MID, req.Envelope.Params)
	if err != nil {
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "invalid_practice_request"}}
	}
	if d.Service == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "practice_unavailable"}}
	}
	locks := apppractice.PracticeLocks{wire.Locks[0] == 1, wire.Locks[1] == 1, wire.Locks[2] == 1}
	save := apppractice.AutoSavePredicates{wire.SaveTypes[0] == 1, wire.SaveTypes[1] == 1, wire.SaveTypes[2] == 1, wire.SaveTypes[3] == 1}
	out, err := d.Service.Auto(ctx, actor, apppractice.AutoCommand{
		Target:    apppractice.Target{Hero: wire.Hero, ActorID: wire.ActorID},
		Locks:     locks,
		Method:    wire.PracticeType,
		BatchSize: wire.PracticeNum,
		Save:      save,
	}, req.Envelope.Operation)
	if err != nil {
		return practiceFailure(err)
	}

	addAttrs := make([]any, len(out.AddAttrs))
	for i, delta := range out.AddAttrs {
		addAttrs[i] = practiceDeltaBody(delta)
	}
	isAdds := make([]any, len(out.IsAdds))
	for i, accepted := range out.IsAdds {
		isAdds[i] = accepted
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{
		"info":          practiceInfoBody(out.Info),
		"add_attrs":     addAttrs,
		"is_adds":       isAdds,
		"practice_attr": []any{out.PracticeAttr[0], out.PracticeAttr[1], out.PracticeAttr[2]},
	}}
}
