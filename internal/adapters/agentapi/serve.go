package agentapi

import (
	"context"
	"errors"
	"net"
	"net/http"
	"time"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

const shutdownTimeout = 5 * time.Second

// Serve runs the agent HTTP server until ctx ends or the server stops, then
// stops the backend child so SIGTERM does not orphan it.
func Serve(ctx context.Context, server *http.Server, listener net.Listener, backend operatoragent.BackendControl) error {
	served := make(chan error, 1)
	go func() { served <- server.Serve(listener) }()

	var serveErr error
	select {
	case serveErr = <-served:
	case <-ctx.Done():
		shutdownContext, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
		defer cancel()
		_ = server.Shutdown(shutdownContext)
		serveErr = <-served
	}
	if errors.Is(serveErr, http.ErrServerClosed) {
		serveErr = nil
	}
	if stopErr := backend.Stop(); stopErr != nil && serveErr == nil {
		serveErr = stopErr
	}
	return serveErr
}
