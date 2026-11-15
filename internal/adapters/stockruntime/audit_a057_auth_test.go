package stockruntime

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
	"gxb.local/backend/v2/internal/domain/identity"
)

type auditUnavailableAuthority struct{ cause error }

func (authority auditUnavailableAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return identity.ActorContext{}, authority.cause
}

func TestAuditA057BearerLookupFaultDoesNotRestartSession(t *testing.T) {
	for name, cause := range map[string]error{
		"deadline":            context.DeadlineExceeded,
		"canceled":            context.Canceled,
		"database restarting": &pgconn.PgError{Code: "57P01"},
		"pool exhausted":      &pgconn.PgError{Code: "53300"},
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
