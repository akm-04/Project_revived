package main

import (
	"context"
	"errors"
	"net"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"gxb.local/backend/v2/internal/adapters/agentapi"
	"gxb.local/backend/v2/internal/adapters/operatorclient"
	"gxb.local/backend/v2/internal/adapters/processcontrol"
	"gxb.local/backend/v2/internal/application/operatoragent"
)

func runAgent(args []string) error {
	root, remaining, err := extractRoot(args)
	if err != nil {
		return err
	}
	if len(remaining) != 0 {
		return errors.New("agent takes no arguments besides --root")
	}
	config, err := operatoragent.LoadConfig(root)
	if err != nil {
		return err
	}
	logsDirectory := filepath.Join(root, operatoragent.LogsDirectoryName)
	operationsDirectory := filepath.Join(root, operatoragent.OperationsDirectory)
	for _, directory := range []string{logsDirectory, operationsDirectory} {
		if err := os.MkdirAll(directory, 0o700); err != nil {
			return err
		}
	}
	logFile, err := os.OpenFile(filepath.Join(logsDirectory, operatoragent.ToolLogFileName), os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		return err
	}
	defer logFile.Close()
	toolLog := operatoragent.NewToolLog(logFile, time.Now)
	operations := operatoragent.NewOperations(operationsDirectory, toolLog, time.Now)
	if err := operations.Recover(); err != nil {
		return err
	}
	tokens := &operatoragent.TokenHolder{}
	backend := processcontrol.New(processcontrol.Options{
		Binary:       config.Backend.Binary,
		EnvFile:      config.Backend.EnvFile,
		OperatorAddr: config.Backend.OperatorAddr,
		OTARoot:      config.OTARoot,
		LogPath:      filepath.Join(logsDirectory, operatoragent.BackendLogFileName),
	})
	operator := operatorclient.New(config.Backend.OperatorAddr, tokens)
	handler := agentapi.Handler{
		Credentials: operatoragent.NewCredentials(root),
		Sessions:    operatoragent.NewSessions(time.Now),
		Backend:     backend,
		Operator:    operator,
		Tokens:      tokens,
		Maintenance: operatoragent.Maintenance{Backend: backend, Operator: operator, Tokens: tokens, Operations: operations},
		Operations:  operations,
		ToolLog:     toolLog,
		ToolLogPath: filepath.Join(logsDirectory, operatoragent.ToolLogFileName),
	}
	listener, err := net.Listen("tcp", config.Listen)
	if err != nil {
		return err
	}
	server := &http.Server{Handler: handler, ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 5 * time.Minute, WriteTimeout: 30 * time.Minute, IdleTimeout: time.Minute}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	go func() {
		<-ctx.Done()
		shutdownContext, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = server.Shutdown(shutdownContext)
	}()
	toolLog.Write("agent", "start", "ok", map[string]any{"listen": config.Listen})
	if err := server.Serve(listener); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	toolLog.Write("agent", "stop", "ok", nil)
	return nil
}
