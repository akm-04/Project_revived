package stockruntime

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/protocol/httpedge"
)

func TestOperationLogAcknowledgesAuthenticatedStat(t *testing.T) {
	now := time.Unix(400, 0).UTC()
	d := OperationLogDispatcher{Authority: httpAuthority{actorForHTTP(t)}}
	stat := func(operationID any) httpedge.DispatchRequest {
		request := env(121, nil, now)
		if operationID != nil {
			request.Envelope.Params["operation_id"] = operationID
		}
		return request
	}
	if r := d.Dispatch(context.Background(), stat(float64(1003))); r.HTTPStatus != 200 {
		t.Fatalf("operation log: %+v", r)
	}
	if r := d.Dispatch(context.Background(), stat(nil)); r.HTTPStatus != 400 {
		t.Fatalf("missing operation_id: %+v", r)
	}
	anonymous := stat(float64(1003))
	anonymous.Envelope.Claims.Token = ""
	if r := d.Dispatch(context.Background(), anonymous); r.HTTPStatus != 401 {
		t.Fatalf("anonymous: %+v", r)
	}
}
