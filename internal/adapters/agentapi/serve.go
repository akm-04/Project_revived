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

// operationShutdownTimeout bounds the wait for a detached operation, such as a
// restore, before the child is stopped; an unfinished operation is settled
// from its journal by the next agent process. It is a variable so a test can
// shorten it.
var operationShutdownTimeout = 30 * time.Second

// Serve runs the agent HTTP server until ctx ends or the server stops, then
// stops the backend child so SIGTERM does not orphan it. Shutdown closes
// admission first and waits for a detached operation before stopping the
// child, so a running restore is not cut at an arbitrary rename.
func Serve(ctx context.Context, server *http.Server, listener net.Listener, backend operatoragent.BackendControl, operations *operatoragent.Operations, log *operatoragent.ToolLog) error {
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
	if operations != nil {
		operationContext, cancel := context.WithTimeout(context.Background(), operationShutdownTimeout)
		if err := operations.Wait(operationContext); err != nil {
			if log != nil {
				log.Write("agent", "shutdown", "timeout", map[string]any{"pending_seconds": operationShutdownTimeout.Seconds(), "error": err.Error()})
			}
		}
		cancel()
	}
	if stopErr := backend.Stop(); stopErr != nil && serveErr == nil {
		serveErr = stopErr
	}
	return serveErr
}
