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
	"gxb.local/backend/v2/internal/adapters/pgtoolchain"
	"gxb.local/backend/v2/internal/adapters/processcontrol"
	appoperator "gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatoragent"
)

func runAgent(root string, args []string) error {
	if len(args) != 0 {
		return errors.New("agent takes no arguments besides --root")
	}
	config, err := operatoragent.LoadConfig(root)
	if err != nil {
		return err
	}
	logsDirectory := filepath.Join(root, operatoragent.LogsDirectoryName)
	operationsDirectory := filepath.Join(root, operatoragent.OperationsDirectory)
	backupDirectory := config.BackupDirectory(root)
	for _, directory := range []string{logsDirectory, operationsDirectory, backupDirectory} {
		if err := os.MkdirAll(directory, 0o700); err != nil {
			return err
		}
	}
	logWriter := operatoragent.NewDatedLogWriter(logsDirectory, operatoragent.ToolLogPrefix, time.Now)
	defer logWriter.Close()
	toolLog := operatoragent.NewToolLog(logWriter, time.Now)
	operations := operatoragent.NewOperations(operationsDirectory, toolLog, time.Now)
	if err := operations.Recover(); err != nil {
		return err
	}
	tokens := &operatoragent.TokenHolder{}
	backend := processcontrol.New(processcontrol.Options{
		Binary:        config.Backend.Binary,
		EnvFile:       config.Backend.EnvFile,
		OperatorAddr:  config.Backend.OperatorAddr,
		OTARoot:       config.OTARoot,
		LogsDirectory: logsDirectory,
		ReadyTimeout:  config.Backend.ReadyTimeout(),
		StopGrace:     config.Backend.StopGrace(),
	})
	operator := operatorclient.New(config.Backend.OperatorAddr, tokens)
	logService := &operatoragent.LogService{
		Directory:       logsDirectory,
		DatabaseLogPath: config.DatabaseLog,
		Operator:        operator,
		Now:             time.Now,
	}
	backendGuard := &operatoragent.BackendGuard{}
	backupTools, toolsErr := pgtoolchain.Resolve(config.ToolchainPath)
	var tools operatoragent.DatabaseTools
	if toolsErr == nil {
		tools = backupTools
	}
	backup := &operatoragent.BackupService{
		Directory:       backupDirectory,
		Keep:            config.BackupKeepValue(),
		EnvironmentFile: config.Backend.EnvFile,
		Tools:           tools,
		ToolsError:      toolsErr,
		Operator:        operator,
		Backend:         backend,
		Tokens:          tokens,
		Operations:      operations,
		Guard:           backendGuard,
		Log:             toolLog,
		Now:             time.Now,
	}
	if tools != nil {
		if err := backup.RecoverRestore(context.Background()); err != nil {
			toolLog.Write("backup", "recover", "failed", map[string]any{"error": err.Error()})
		}
	}
	buildOperation := operatoragent.Build{Config: config, Operator: operator, Operations: operations}
	settings := &operatoragent.SettingsService{Root: root, OTARoot: config.OTARoot}
	moduleCatalog := operatoragent.ModuleCatalog{Backend: operator, Local: []appoperator.Module{operatoragent.ServerModule(), operatoragent.AgentOTAModule(), operatoragent.AgentSettingsModule(), operatoragent.DashboardModule(), operatoragent.BackupModule(), operatoragent.AgentLogsModule()}}
	dashboard := operatoragent.Dashboard{
		Backend:    backend,
		Operator:   operator,
		Version:    operator,
		PublicURLs: config.PublicURLs,
		Settings:   settings,
		Backups:    backup,
		Now:        time.Now,
	}
	handler := agentapi.Handler{
		Credentials: operatoragent.NewCredentials(root),
		Sessions:    operatoragent.NewSessions(time.Now),
		Backend:     backend,
		Operator:    operator,
		Tokens:      tokens,
		Maintenance: operatoragent.Maintenance{Backend: backend, Operator: operator, Tokens: tokens, Operations: operations, Guard: backendGuard},
		Backup:      backup,
		Operations:  operations,
		Build:       buildOperation,
		Modules:     moduleCatalog,
		Dashboard:   dashboard,
		ToolLog:     toolLog,
		Logs:        logService,
		Settings:    settings,
		OTARoot:     config.OTARoot,
		Listen:      config.Listen,
		Guard:       backendGuard,
	}
	listener, err := net.Listen("tcp", config.Listen)
	if err != nil {
		return err
	}
	server := &http.Server{Handler: handler, ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 5 * time.Minute, WriteTimeout: 30 * time.Minute, IdleTimeout: time.Minute}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	go operatoragent.RunLogRetention(ctx, logsDirectory, config.ToolLogRetentionDays(), time.Now, time.Hour)
	toolLog.Write("agent", "start", "ok", map[string]any{"listen": config.Listen})
	if err := agentapi.Serve(ctx, server, listener, backend); err != nil {
		return err
	}
	toolLog.Write("agent", "stop", "ok", nil)
	return nil
}
