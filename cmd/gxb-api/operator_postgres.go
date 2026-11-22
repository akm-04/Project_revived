//go:build postgres

package main

import (
	"context"
	"errors"
	"log"
	"net"
	"net/http"
	"os"
	"time"

	"gxb.local/backend/v2/internal/adapters/operatorapi"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const defaultOperatorAddress = "127.0.0.1:8091"

// startOperator opens the operator listener (I11A_ARCHITECTURE_V1 ruling 1,
// I11A_OPERATOR_COMMANDS_V1 ruling 7) when the agent passed its per-start
// token in GXB_OPERATOR_TOKEN; without a token there is no operator surface.
func startOperator(ctx context.Context, runner tx.Runner, handlers map[string]operator.Handler) {
	token := os.Getenv("GXB_OPERATOR_TOKEN")
	if token == "" {
		log.Printf("operator listener disabled: GXB_OPERATOR_TOKEN is not set")
		return
	}
	// Keep the secret out of any child process environment.
	_ = os.Unsetenv("GXB_OPERATOR_TOKEN")
	address := os.Getenv("GXB_OPERATOR_ADDR")
	if address == "" {
		address = defaultOperatorAddress
	}
	listener, err := net.Listen("tcp", address)
	if err != nil {
		log.Fatalf("operator listener: %v", err)
	}
	bound, ok := listener.Addr().(*net.TCPAddr)
	if !ok || !bound.IP.IsLoopback() {
		log.Fatalf("operator listener must bind a loopback address, got %s", listener.Addr())
	}
	bus := operator.Bus{Runner: runner, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: handlers}
	server := &http.Server{Handler: operatorapi.Handler{Bus: bus, Token: token}, ReadHeaderTimeout: 5 * time.Second, ReadTimeout: time.Minute, WriteTimeout: 5 * time.Minute, IdleTimeout: time.Minute}
	go func() {
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = server.Shutdown(shutdownCtx)
	}()
	go func() {
		log.Printf("operator listener on %s", listener.Addr())
		if err := server.Serve(listener); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("operator listener: %v", err)
		}
	}()
}
