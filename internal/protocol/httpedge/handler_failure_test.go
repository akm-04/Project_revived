package httpedge

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"gxb.local/backend/v2/internal/protocol/wire"
)

func TestEdgeFailureClasses(t *testing.T) {
	cases := []struct {
		class  wire.ErrorClass
		status int
		code   float64
	}{
		{wire.ErrMalformed, http.StatusBadRequest, float64(edgeRefusalCode)},
		{wire.ErrTooLarge, http.StatusRequestEntityTooLarge, float64(edgeRefusalCode)},
		{wire.ErrUnknownMID, http.StatusConflict, float64(edgeRefusalCode)},
		{wire.ErrUnimplemented, http.StatusConflict, float64(edgeRefusalCode)},
		{wire.ErrSaturated, http.StatusServiceUnavailable, float64(edgeTransientCode)},
		{wire.ErrInternal, http.StatusInternalServerError, float64(edgeRefusalCode)},
	}
	for _, tc := range cases {
		t.Run(string(tc.class), func(t *testing.T) {
			writer := httptest.NewRecorder()
			edgeFailure(writer, tc.class, "public_code")
			if writer.Code != tc.status {
				t.Fatalf("status=%d want=%d", writer.Code, tc.status)
			}
			var body map[string]any
			if err := json.Unmarshal(writer.Body.Bytes(), &body); err != nil {
				t.Fatal(err)
			}
			if body["error_code"] != tc.code || body["error_msg"] != "" || body["error"] != "public_code" {
				t.Fatalf("body=%#v", body)
			}
		})
	}
}

func TestEdgeUnknownAndUnimplementedMIDsAreRefusals(t *testing.T) {
	handler := journalHandler(t, nil, func(_ context.Context, _ DispatchRequest) Response { return Response{} })
	unknown := post(handler, `{"mid":65000,"token":"bearer"}`)
	if unknown.Code != http.StatusConflict {
		t.Fatalf("unknown status=%d body=%q", unknown.Code, unknown.Body)
	}
	var body map[string]any
	if err := json.Unmarshal(unknown.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	if body["error_code"] != float64(edgeRefusalCode) || body["error"] != "unknown_mid" {
		t.Fatalf("unknown body=%#v", body)
	}
}
