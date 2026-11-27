package operatoragent

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func writeDatedLog(t *testing.T, directory, name string, lines ...string) {
	t.Helper()
	body := strings.Join(lines, "\n") + "\n"
	if err := os.WriteFile(filepath.Join(directory, name), []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
}

func TestDatedLogWriterRollsAtUTCMidnight(t *testing.T) {
	directory := t.TempDir()
	current := time.Date(2026, 11, 22, 23, 59, 0, 0, time.UTC)
	writer := NewDatedLogWriter(directory, ToolLogPrefix, func() time.Time { return current })
	if _, err := writer.Write([]byte("first\n")); err != nil {
		t.Fatal(err)
	}
	current = current.Add(2 * time.Minute)
	if _, err := writer.Write([]byte("second\n")); err != nil {
		t.Fatal(err)
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	first, err := os.ReadFile(filepath.Join(directory, "tool-2026-11-22.log"))
	if err != nil || string(first) != "first\n" {
		t.Fatalf("first file = %q err=%v", first, err)
	}
	second, err := os.ReadFile(filepath.Join(directory, "tool-2026-11-23.log"))
	if err != nil || string(second) != "second\n" {
		t.Fatalf("second file = %q err=%v", second, err)
	}
}

func TestRetainDatedLogsRemovesOnlyOldToolAndBackendFiles(t *testing.T) {
	directory := t.TempDir()
	for _, name := range []string{"tool-2026-10-01.log", "backend-2026-10-01.log", "tool-2026-11-22.log", "backend-2026-11-22.log", "tool.log", "root.passwd"} {
		writeDatedLog(t, directory, name, "line")
	}
	removed, err := RetainDatedLogs(directory, 30, time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC))
	if err != nil {
		t.Fatal(err)
	}
	if removed != 2 {
		t.Fatalf("removed = %d", removed)
	}
	for _, name := range []string{"tool-2026-10-01.log", "backend-2026-10-01.log"} {
		if _, err := os.Stat(filepath.Join(directory, name)); !os.IsNotExist(err) {
			t.Fatalf("%s was not removed", name)
		}
	}
	for _, name := range []string{"tool-2026-11-22.log", "backend-2026-11-22.log", "tool.log", "root.passwd"} {
		if _, err := os.Stat(filepath.Join(directory, name)); err != nil {
			t.Fatalf("%s was removed: %v", name, err)
		}
	}
}

func TestRetainDatedLogsKeepsTheMinimumWindow(t *testing.T) {
	directory := t.TempDir()
	writeDatedLog(t, directory, "tool-2026-11-08.log", "line")
	removed, err := RetainDatedLogs(directory, 5, time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC))
	if err != nil || removed != 0 {
		t.Fatalf("removed = %d err = %v", removed, err)
	}
	if _, err := os.Stat(filepath.Join(directory, "tool-2026-11-08.log")); err != nil {
		t.Fatalf("a log inside the 15-day floor was removed: %v", err)
	}
}

func TestTailCursorPagesAcrossRotationAndFiltersLevel(t *testing.T) {
	directory := t.TempDir()
	writeDatedLog(t, directory, "tool-2026-11-21.log",
		`{"at":"2026-11-21T10:00:00Z","level":"info","op":"a","step":"s","outcome":"ok"}`,
		`{"at":"2026-11-21T10:00:01Z","level":"error","op":"b","step":"s","outcome":"failed"}`)
	writeDatedLog(t, directory, "tool-2026-11-22.log",
		`{"at":"2026-11-22T10:00:00Z","level":"info","op":"c","step":"s","outcome":"ok"}`,
		`{"at":"2026-11-22T10:00:01Z","level":"warn","op":"d","step":"s","outcome":"refused"}`)
	service := &LogService{Directory: directory, Now: time.Now}

	tail, err := service.Tail(context.Background(), LogSourceTool, "", "", 2)
	if err != nil {
		t.Fatal(err)
	}
	if len(tail.Lines) != 2 || tail.Lines[0].Text == "" || tail.NextCursor == "" {
		t.Fatalf("newest tail = %+v", tail)
	}
	first, err := service.Tail(context.Background(), LogSourceTool, "", "", 1)
	if err != nil || len(first.Lines) != 1 {
		t.Fatalf("first page = %+v err=%v", first, err)
	}
	all, err := service.Tail(context.Background(), LogSourceTool, tail.NextCursor, "", 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(all.Lines) != 0 {
		t.Fatalf("cursor at end replayed lines: %+v", all)
	}

	cursor := "2026-11-21|0"
	page, err := service.Tail(context.Background(), LogSourceTool, cursor, "error", 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(page.Lines) != 1 || page.Lines[0].Level != "error" || !strings.Contains(page.Lines[0].Text, `"op":"b"`) {
		t.Fatalf("error page = %+v", page)
	}
	if !strings.HasPrefix(page.NextCursor, "2026-11-22|") {
		t.Fatalf("page did not advance across rotation: %s", page.NextCursor)
	}
}

func TestSearchReturnsNewestFirstAndMasksSecrets(t *testing.T) {
	directory := t.TempDir()
	writeDatedLog(t, directory, "backend-2026-11-21.log",
		"2026/11/21 10:00:00 first ERROR password=hunter2",
		"2026/11/21 10:00:01 routine")
	writeDatedLog(t, directory, "backend-2026-11-22.log",
		"2026/11/22 10:00:00 second token=abcd")
	service := &LogService{Directory: directory, Now: time.Now}

	search, err := service.Search(context.Background(), LogSourceBackend, "", "", "", "error", 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(search.Entries) != 1 {
		t.Fatalf("entries = %+v", search.Entries)
	}
	line := search.Entries[0].(LogLine)
	if line.Level != "error" || strings.Contains(line.Text, "hunter2") {
		t.Fatalf("error line = %+v", line)
	}
	all, err := service.Search(context.Background(), LogSourceBackend, "", "", "", "", 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(all.Entries) != 3 {
		t.Fatalf("entries = %+v", all.Entries)
	}
	newest := all.Entries[0].(LogLine)
	if !strings.Contains(newest.Text, "2026/11/22") || strings.Contains(newest.Text, "abcd") {
		t.Fatalf("first entry = %+v", newest)
	}
}

func TestDatabaseSourceIsAbsentWhenNotConfiguredOrUnreadable(t *testing.T) {
	service := &LogService{Directory: t.TempDir(), Now: time.Now}
	tail, err := service.Tail(context.Background(), LogSourceDatabase, "", "", 10)
	if err != nil || !tail.Absent || tail.Lines == nil {
		t.Fatalf("unset database tail = %+v err=%v", tail, err)
	}
	service.DatabaseLogPath = filepath.Join(t.TempDir(), "missing.log")
	tail, err = service.Tail(context.Background(), LogSourceDatabase, "", "", 10)
	if err != nil || !tail.Absent {
		t.Fatalf("missing database tail = %+v err=%v", tail, err)
	}
	configured := filepath.Join(t.TempDir(), "postgresql.log")
	writeDatedLog(t, filepath.Dir(configured), filepath.Base(configured), "2026-11-22 10:00:00 UTC [1] LOG: ready")
	service.DatabaseLogPath = configured
	tail, err = service.Tail(context.Background(), LogSourceDatabase, "", "", 10)
	if err != nil || tail.Absent || len(tail.Lines) != 1 {
		t.Fatalf("configured database tail = %+v err=%v", tail, err)
	}
}

func TestClearFilesScopesAndNeverClearsTheToolLog(t *testing.T) {
	directory := t.TempDir()
	writeDatedLog(t, directory, "backend-2026-11-01.log", "old")
	writeDatedLog(t, directory, "backend-2026-11-22.log", "new")
	writeDatedLog(t, directory, "tool-2026-11-22.log", "audit")
	service := &LogService{Directory: directory, Now: time.Now}

	if _, err := service.ClearFiles(LogClearRequest{Source: LogSourceTool, Scope: "all"}); err == nil {
		t.Fatal("the tool log was cleared by command")
	}
	if _, err := service.ClearFiles(LogClearRequest{Source: LogSourceBackend, Scope: "player"}); err == nil {
		t.Fatal("a player clear of the process log was accepted")
	}
	result, err := service.ClearFiles(LogClearRequest{Source: LogSourceBackend, Scope: "older_than", OlderThan: "2026-11-10T00:00:00Z"})
	if err != nil || result.RemovedFiles != 1 {
		t.Fatalf("older_than = %+v err=%v", result, err)
	}
	if _, err := os.Stat(filepath.Join(directory, "backend-2026-11-22.log")); err != nil {
		t.Fatal("the newer backend file was removed")
	}
	result, err = service.ClearFiles(LogClearRequest{Source: LogSourceBackend, Scope: "all"})
	if err != nil || result.RemovedFiles != 1 {
		t.Fatalf("all = %+v err=%v", result, err)
	}
	if _, err := os.Stat(filepath.Join(directory, "tool-2026-11-22.log")); err != nil {
		t.Fatal("the tool log was removed by a backend clear")
	}
}
