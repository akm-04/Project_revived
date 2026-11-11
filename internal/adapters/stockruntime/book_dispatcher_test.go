package stockruntime

import (
	"context"
	"net/http"
	"testing"

	app "gxb.local/backend/v2/internal/application/bookskill"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type fakeBookService struct{ err error }

func (s fakeBookService) Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error) {
	return app.Result{}, s.err
}

func (s fakeBookService) Read(context.Context, identity.ActorContext, uint16, operation.Context) (map[string]any, error) {
	return nil, s.err
}

func TestBookComposeRefusalIs409WithCode(t *testing.T) {
	dispatcher := BookDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: fakeBookService{err: app.ErrRejected}}
	got := dispatcher.Dispatch(context.Background(), heroReq(t, 83, map[string]any{"item_id": int64(1001)}))
	if got.HTTPStatus != http.StatusConflict {
		t.Fatalf("book compose refusal status=%d body=%#v", got.HTTPStatus, got.Body)
	}
	code, hasCode := got.Body["error_code"]
	if !hasCode || code == nil {
		t.Fatalf("book compose refusal carries no error_code: %#v", got.Body)
	}
}

func TestBookFailureRowTable(t *testing.T) {
	rows := []struct {
		name       string
		err        error
		wantStatus int
		wantCode   int64
	}{
		{"rejected", app.ErrRejected, http.StatusConflict, unprovenRefusalCode},
		{"invalid", book.ErrInvalid, http.StatusBadRequest, 0},
		{"insufficient", economy.ErrInsufficientBalance, http.StatusConflict, unprovenRefusalCode},
	}
	for _, row := range rows {
		t.Run(row.name, func(t *testing.T) {
			got := failBook(row.err)
			if got.HTTPStatus != row.wantStatus {
				t.Fatalf("status=%d want=%d body=%#v", got.HTTPStatus, row.wantStatus, got.Body)
			}
			if row.wantCode == 0 {
				if _, hasCode := got.Body["error_code"]; hasCode {
					t.Fatalf("unexpected error_code: %#v", got.Body)
				}
				return
			}
			if got.Body["error_code"] != row.wantCode {
				t.Fatalf("error_code=%#v want=%d", got.Body["error_code"], row.wantCode)
			}
		})
	}
	fallback := failBook(anonymousFailure{})
	if fallback.HTTPStatus != http.StatusServiceUnavailable || fallback.Body["error_code"] != serverBusyCode || fallback.Body["error_msg"] != "" {
		t.Fatalf("fallback=%+v", fallback)
	}
}

type anonymousFailure struct{}

func (anonymousFailure) Error() string { return "operation failed" }
