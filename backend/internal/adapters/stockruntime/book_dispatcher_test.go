package stockruntime

import (
	"context"
	"net/http"
	"testing"

	app "gxb.local/backend/v2/internal/application/bookskill"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/economy"
	ec "gxb.local/backend/v2/internal/domain/eventcentre"
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

func (s fakeBookService) OwnsComposeItem(context.Context, int64, operation.Context) (bool, error) {
	return false, s.err
}

func TestBookComposeRefusalIs409WithCode(t *testing.T) {
	dispatcher := ComposeDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Book: &composeBookFake{owned: true, commandErr: app.ErrRejected}, Furniture: &composeFurnitureFake{}, Awakening: &composeAwakeningFake{}, Equipment: &composeEquipmentFake{}}
	got := dispatcher.Dispatch(context.Background(), heroReq(t, 83, map[string]any{"item_id": int64(1001)}))
	if got.HTTPStatus != http.StatusConflict {
		t.Fatalf("book compose refusal status=%d body=%#v", got.HTTPStatus, got.Body)
	}
	code, hasCode := got.Body["error_code"]
	if !hasCode || code == nil {
		t.Fatalf("book compose refusal carries no error_code: %#v", got.Body)
	}
}

func TestBookDomainRefusalAnswers409(t *testing.T) {
	dispatcher := BookDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: fakeBookService{err: book.ErrInvalid}}
	for _, mid := range []uint16{1060, 1077} {
		params := map[string]any{"skill_id": int64(10010001)}
		if mid == 1077 {
			params = map[string]any{"type": int64(3)}
		}
		got := dispatcher.Dispatch(context.Background(), heroReq(t, mid, params))
		if got.HTTPStatus != http.StatusConflict || got.Body["error_code"] != unprovenRefusalCode || got.Body["error_msg"] != "" {
			t.Fatalf("MID %d domain refusal status=%d body=%#v", mid, got.HTTPStatus, got.Body)
		}
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
		{"invalid", book.ErrInvalid, http.StatusConflict, unprovenRefusalCode},
		{"insufficient", economy.ErrInsufficientBalance, http.StatusConflict, unprovenRefusalCode},
		{"book unqualified", book.ErrUnqualified, http.StatusConflict, unprovenRefusalCode},
		{"book stale time", book.ErrStaleTime, http.StatusConflict, staleConflictCode},
		{"application stale", app.ErrStale, http.StatusConflict, staleConflictCode},
		{"event centre unqualified", ec.ErrUnqualified, http.StatusConflict, unprovenRefusalCode},
		{"event centre stale time", ec.ErrStaleTime, http.StatusConflict, staleConflictCode},
	}
	for _, row := range rows {
		t.Run(row.name, func(t *testing.T) {
			got := failBook(row.err)
			if got.HTTPStatus != row.wantStatus {
				t.Fatalf("status=%d want=%d body=%#v", got.HTTPStatus, row.wantStatus, got.Body)
			}
			if got.Body["error_code"] != row.wantCode {
				t.Fatalf("error_code=%#v want=%d", got.Body["error_code"], row.wantCode)
			}
			if got.Body["error_msg"] != "" {
				t.Fatalf("refusal body: %#v", got.Body)
			}
		})
	}
	fallback := failBook(anonymousFailure{})
	if fallback.HTTPStatus != http.StatusInternalServerError || fallback.Body["error_code"] != unprovenRefusalCode || fallback.Body["error_msg"] != "" {
		t.Fatalf("fallback=%+v", fallback)
	}
}

func TestBookApplicationStaleOnReadIs409(t *testing.T) {
	for _, mid := range []uint16{1056, 1059} {
		dispatcher := BookDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: fakeBookService{err: app.ErrStale}}
		got := dispatcher.Dispatch(context.Background(), heroReq(t, mid, nil))
		if got.HTTPStatus != http.StatusConflict || got.Body["error_code"] != staleConflictCode {
			t.Fatalf("MID %d status=%d body=%#v", mid, got.HTTPStatus, got.Body)
		}
	}
}

type anonymousFailure struct{}

func (anonymousFailure) Error() string { return "operation failed" }
