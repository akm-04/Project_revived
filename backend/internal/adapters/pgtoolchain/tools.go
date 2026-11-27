// Package pgtoolchain runs pg_dump, pg_restore, psql and the goose migration
// runner for the operator agent. The executables come from the configured P2
// tools folder when one is set, otherwise from the agent's own PATH; no system
// path is hard-coded.
package pgtoolchain

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

const (
	DumpExecutable    = "pg_dump"
	RestoreExecutable = "pg_restore"
	SQLExecutable     = "psql"
	GooseExecutable   = "goose"
)

// Tools are the resolved executables.
type Tools struct {
	DumpPath    string
	RestorePath string
	SQLPath     string
	// GoosePath is empty when the tools folder or PATH has no goose binary; a
	// restore of an older snapshot then refuses the forward migration.
	GoosePath string
}

// Resolve finds the backup executables in the tools folder, or on PATH when
// the folder is unset (P2: portable bundle or system-wide tools). goose is
// optional, so an older install without it still keeps its snapshot and prune
// commands.
func Resolve(directory string) (Tools, error) {
	dump, err := resolveExecutable(directory, DumpExecutable)
	if err != nil {
		return Tools{}, err
	}
	restore, err := resolveExecutable(directory, RestoreExecutable)
	if err != nil {
		return Tools{}, err
	}
	sql, err := resolveExecutable(directory, SQLExecutable)
	if err != nil {
		return Tools{}, err
	}
	goose, _ := resolveExecutable(directory, GooseExecutable)
	return Tools{DumpPath: dump, RestorePath: restore, SQLPath: sql, GoosePath: goose}, nil
}

func resolveExecutable(directory, name string) (string, error) {
	if directory == "" {
		path, err := exec.LookPath(name)
		if err != nil {
			return "", fmt.Errorf("%s is not on PATH", name)
		}
		return path, nil
	}
	path := filepath.Join(directory, name)
	info, err := os.Stat(path)
	if err != nil || info.IsDir() {
		return "", fmt.Errorf("%s is missing from the tools folder", name)
	}
	return path, nil
}

// Dump writes a custom-format dump of dsn to destination.
func (tools Tools) Dump(ctx context.Context, dsn, destination string) error {
	return tools.run(ctx, tools.DumpPath, "-Fc", "-f", destination, dsn)
}

// VerifyDump checks that pg_restore can read the archive's table of contents.
func (tools Tools) VerifyDump(ctx context.Context, path string) error {
	return tools.run(ctx, tools.RestorePath, "--list", path)
}

// Restore loads an archive into the database dsn points at.
func (tools Tools) Restore(ctx context.Context, dsn, path string) error {
	return tools.run(ctx, tools.RestorePath, "--no-owner", "--no-privileges", "--dbname", dsn, path)
}

// Execute runs one SQL statement, stopping on the first error.
func (tools Tools) Execute(ctx context.Context, dsn, statement string) error {
	return tools.run(ctx, tools.SQLPath, "-X", "-q", "-v", "ON_ERROR_STOP=1", "-d", dsn, "-c", statement)
}

// Query runs one SQL statement and returns its unaligned tuples-only answer.
func (tools Tools) Query(ctx context.Context, dsn, statement string) (string, error) {
	var stdout bytes.Buffer
	if err := tools.output(ctx, &stdout, tools.SQLPath, "-X", "-q", "-tA", "-v", "ON_ERROR_STOP=1", "-d", dsn, "-c", statement); err != nil {
		return "", err
	}
	return stdout.String(), nil
}

// Migrate runs the same forward-only goose runner the deployment uses, up to
// the newest migration in directory.
func (tools Tools) Migrate(ctx context.Context, dsn, directory string) error {
	if tools.GoosePath == "" {
		return errors.New("the goose migration runner is not on PATH or in the tools folder")
	}
	if directory == "" {
		return errors.New("the migrations folder is not configured")
	}
	return tools.run(ctx, tools.GoosePath, "-dir", directory, "postgres", dsn, "up")
}

func (tools Tools) run(ctx context.Context, executable string, arguments ...string) error {
	return tools.output(ctx, nil, executable, arguments...)
}

func (tools Tools) output(ctx context.Context, stdout *bytes.Buffer, executable string, arguments ...string) error {
	if executable == "" {
		return errors.New("the pg toolchain is not resolved")
	}
	command := exec.CommandContext(ctx, executable, arguments...)
	var stderr bytes.Buffer
	if stdout != nil {
		command.Stdout = stdout
	}
	command.Stderr = &stderr
	if err := command.Run(); err != nil {
		return fmt.Errorf("%s failed: %w: %s", filepath.Base(executable), err, bytes.TrimSpace(stderr.Bytes()))
	}
	return nil
}
