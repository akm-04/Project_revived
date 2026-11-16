package stockruntime

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
)

type auditUnavailableAuthority struct{ cause error }

func (authority auditUnavailableAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return identity.ActorContext{}, authority.cause
}

func TestAuditA057AuthPolicyControls(t *testing.T) {
	for _, test := range []struct {
		name    string
		cause   error
		status  int
		code    int64
		message string
	}{
		{"session", errors.New("bearer not live"), http.StatusUnauthorized, sessionFailureCode, sessionFailureMessage},
		{"superseded", i4store.ErrContextSuperseded, http.StatusConflict, unprovenRefusalCode, ""},
		{"region", apprealtime.ErrRegionMismatch, http.StatusConflict, unprovenRefusalCode, ""},
		{"room", domainrt.ErrRoomNotAuthorized, http.StatusConflict, unprovenRefusalCode, ""},
		{"endpoint", apprealtime.ErrNoEndpoint, http.StatusInternalServerError, unprovenRefusalCode, ""},
	} {
		t.Run(test.name, func(t *testing.T) {
			response := authFailure(test.cause)
			if response.HTTPStatus != test.status || response.Body["error_code"] != test.code || response.Body["error_msg"] != test.message {
				t.Fatalf("status=%d body=%v", response.HTTPStatus, response.Body)
			}
		})
	}
}

func TestAuditA057BearerLookupFaultDoesNotRestartSession(t *testing.T) {
	for name, cause := range map[string]error{
		"deadline":            context.DeadlineExceeded,
		"canceled":            context.Canceled,
		"database restarting": auditSQLStateError("57P01"),
		"pool exhausted":      auditSQLStateError("53300"),
	} {
		t.Run(name, func(t *testing.T) {
			dispatcher := LobbyDispatcher{Authority: auditUnavailableAuthority{cause: fmt.Errorf("bearer lookup: %w", cause)}}
			response := dispatcher.Dispatch(context.Background(), env(2784, nil, time.Unix(200, 0)))
			if response.HTTPStatus != http.StatusServiceUnavailable || response.Body["error_code"] != serverBusyCode || response.Body["error_msg"] != "" {
				t.Fatalf("lookup fault must preserve session: status=%d body=%v", response.HTTPStatus, response.Body)
			}
			if !errors.Is(response.Cause, cause) {
				t.Fatalf("lookup cause was lost: %v", response.Cause)
			}
		})
	}
}

// auditSQLStateError stands in for a driver error; pgx stays adapter-only (archguard).
type auditSQLStateError string

func (e auditSQLStateError) Error() string    { return "sqlstate " + string(e) }
func (e auditSQLStateError) SQLState() string { return string(e) }
