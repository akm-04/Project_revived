package pgtoolchain

import (
	"context"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func writeExecutable(t *testing.T, directory, name, body string) {
	t.Helper()
	path := filepath.Join(directory, name)
	if err := os.WriteFile(path, []byte("#!/bin/sh\n"+body+"\n"), 0o755); err != nil {
		t.Fatal(err)
	}
}

func TestResolveUsesTheToolsFolder(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("shell fixtures are POSIX only")
	}
	directory := t.TempDir()
	for _, name := range []string{DumpExecutable, RestoreExecutable, SQLExecutable} {
		writeExecutable(t, directory, name, "exit 0")
	}
	tools, err := Resolve(directory)
	if err != nil {
		t.Fatal(err)
	}
	if tools.DumpPath != filepath.Join(directory, DumpExecutable) || tools.SQLPath != filepath.Join(directory, SQLExecutable) {
		t.Fatalf("tools = %+v", tools)
	}
}

func TestResolveRefusesAMissingExecutable(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("shell fixtures are POSIX only")
	}
	directory := t.TempDir()
	writeExecutable(t, directory, DumpExecutable, "exit 0")
	if _, err := Resolve(directory); err == nil {
		t.Fatal("a missing pg_restore was accepted")
	}
}

func TestDumpAndQueryPassTheirArguments(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("shell fixtures are POSIX only")
	}
	directory := t.TempDir()
	record := filepath.Join(directory, "args")
	writeExecutable(t, directory, DumpExecutable, `printf '%s\n' "$@" > `+record)
	writeExecutable(t, directory, RestoreExecutable, "exit 0")
	writeExecutable(t, directory, SQLExecutable, `printf '1\n'`)
	tools, err := Resolve(directory)
	if err != nil {
		t.Fatal(err)
	}
	dsn := "postgres://postgres@/gxb_bk?host=127.0.0.1&port=55853"
	if err := tools.Dump(context.Background(), dsn, filepath.Join(directory, "out.dump")); err != nil {
		t.Fatal(err)
	}
	recorded, err := os.ReadFile(record)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(recorded), "-Fc") || !strings.Contains(string(recorded), dsn) {
		t.Fatalf("dump arguments = %s", recorded)
	}
	answer, err := tools.Query(context.Background(), dsn, "SELECT 1")
	if err != nil || strings.TrimSpace(answer) != "1" {
		t.Fatalf("query = %q (%v)", answer, err)
	}
}

func TestMigrateUsesTheGooseRunner(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("shell fixtures are POSIX only")
	}
	directory := t.TempDir()
	record := filepath.Join(directory, "args")
	for _, name := range []string{DumpExecutable, RestoreExecutable, SQLExecutable} {
		writeExecutable(t, directory, name, "exit 0")
	}
	writeExecutable(t, directory, GooseExecutable, `printf '%s\n' "$@" > `+record)
	tools, err := Resolve(directory)
	if err != nil {
		t.Fatal(err)
	}
	if tools.GoosePath != filepath.Join(directory, GooseExecutable) {
		t.Fatalf("goose path = %q", tools.GoosePath)
	}
	dsn := "postgres://postgres@/gxb_bk?host=127.0.0.1&port=55853"
	if err := tools.Migrate(context.Background(), dsn, "/srv/migrations"); err != nil {
		t.Fatal(err)
	}
	recorded, err := os.ReadFile(record)
	if err != nil {
		t.Fatal(err)
	}
	for _, wanted := range []string{"-dir", "/srv/migrations", "postgres", dsn, "up"} {
		if !strings.Contains(string(recorded), wanted) {
			t.Fatalf("migrate arguments = %s", recorded)
		}
	}
}

func TestMigrateRefusesWithoutARunnerOrFolder(t *testing.T) {
	if err := (Tools{}).Migrate(context.Background(), "postgres://postgres@/gxb_bk", "/srv/migrations"); err == nil {
		t.Fatal("a missing goose runner was accepted")
	}
	if err := (Tools{GoosePath: "goose"}).Migrate(context.Background(), "postgres://postgres@/gxb_bk", ""); err == nil {
		t.Fatal("a missing migrations folder was accepted")
	}
}

func TestToolFailureCarriesStderr(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("shell fixtures are POSIX only")
	}
	directory := t.TempDir()
	writeExecutable(t, directory, DumpExecutable, "echo 'connection refused' >&2; exit 2")
	writeExecutable(t, directory, RestoreExecutable, "exit 0")
	writeExecutable(t, directory, SQLExecutable, "exit 0")
	tools, err := Resolve(directory)
	if err != nil {
		t.Fatal(err)
	}
	err = tools.Dump(context.Background(), "postgres://postgres@/gxb_bk", filepath.Join(directory, "out.dump"))
	if err == nil || !strings.Contains(err.Error(), "connection refused") {
		t.Fatalf("error = %v", err)
	}
}
