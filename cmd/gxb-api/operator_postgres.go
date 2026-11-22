//go:build postgres

package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"runtime/debug"
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
func startOperator(ctx context.Context, runner tx.Runner, handlers map[string]operator.Handler, reads map[string]operatorapi.Read, version func(context.Context) (any, error), otaRoot string) {
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
	executor := postCommitExecutor{Next: bus, OTARoot: otaRoot}
	server := &http.Server{Handler: operatorapi.Handler{Bus: executor, Token: token, Reads: reads, Version: version}, ReadHeaderTimeout: 5 * time.Second, ReadTimeout: time.Minute, WriteTimeout: 5 * time.Minute, IdleTimeout: time.Minute}
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

// postCommitExecutor mirrors a committed OTA activation after the bus commit;
// the database stays the record, so a failed mirror only logs.
type postCommitExecutor struct {
	Next    operatorapi.Executor
	OTARoot string
}

func (executor postCommitExecutor) Execute(ctx context.Context, command operator.Command) (operator.Outcome, error) {
	outcome, err := executor.Next.Execute(ctx, command)
	if err != nil || outcome.State != operator.StateApplied || outcome.Replayed {
		return outcome, err
	}
	if command.ModuleCommand != "ota.publish" && command.ModuleCommand != "ota.withdraw" {
		return outcome, nil
	}
	if writeErr := mirrorActivation(executor.OTARoot, command.Envelope.SemanticKey, outcome.Result); writeErr != nil {
		log.Printf("ota history mirror: %v", writeErr)
	}
	return outcome, nil
}

type activationMirror struct {
	ID         int64     `json:"id"`
	Version    string    `json:"version"`
	Action     string    `json:"action"`
	CommandKey string    `json:"command_key"`
	At         time.Time `json:"at"`
}

func mirrorActivation(root, commandKey string, result json.RawMessage) error {
	if root == "" {
		return nil
	}
	var activation struct {
		ActivationID int64     `json:"activation_id"`
		Version      string    `json:"version"`
		Action       string    `json:"action"`
		At           time.Time `json:"at"`
	}
	if err := json.Unmarshal(result, &activation); err != nil {
		return err
	}
	if activation.ActivationID == 0 {
		return nil
	}
	document, err := json.Marshal(activationMirror{ID: activation.ActivationID, Version: activation.Version, Action: activation.Action, CommandKey: commandKey, At: activation.At})
	if err != nil {
		return err
	}
	directory := filepath.Join(root, "updates", "history")
	if err := os.MkdirAll(directory, 0o755); err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(directory, fmt.Sprintf("%d.json", activation.ActivationID)), document, 0o644)
}

// buildIdentity reports what the binary itself knows: the module version for a
// released build and the VCS revision Go embeds when built with buildvcs on.
// A source build embeds neither, so the value is null rather than invented.
func buildIdentity() (*string, *string) {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return nil, nil
	}
	var version *string
	if info.Main.Version != "" && info.Main.Version != "(devel)" {
		value := info.Main.Version
		version = &value
	}
	var commit *string
	for _, setting := range info.Settings {
		if setting.Key == "vcs.revision" && setting.Value != "" {
			value := setting.Value
			commit = &value
		}
	}
	return version, commit
}
