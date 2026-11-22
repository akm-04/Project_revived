package processcontrol

import (
	"encoding/json"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"
)

const fakeBackendSource = `package main

import (
	"encoding/json"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

func main() {
	record := os.Getenv("GXB_TEST_RECORD")
	if record != "" {
		encoded, _ := json.Marshal(map[string]string{
			"token":    os.Getenv("GXB_OPERATOR_TOKEN"),
			"listener": os.Getenv("GXB_GAME_LISTENER"),
		})
		_ = os.WriteFile(record, encoded, 0o600)
	}
	if os.Getenv("GXB_TEST_EXIT_EARLY") == "1" {
		os.Exit(3)
	}
	if milliseconds, err := strconv.Atoi(os.Getenv("GXB_TEST_DELAY_MS")); err == nil && milliseconds > 0 {
		time.Sleep(time.Duration(milliseconds) * time.Millisecond)
	}
	address := os.Getenv("GXB_OPERATOR_ADDR")
	http.HandleFunc("/operator/v1/version", func(writer http.ResponseWriter, request *http.Request) {
		if !strings.HasPrefix(request.Header.Get("Authorization"), "Bearer ") {
			writer.WriteHeader(http.StatusUnauthorized)
			return
		}
		_ = json.NewEncoder(writer).Encode(map[string]string{"backend_version": "fake"})
	})
	_ = http.ListenAndServe(address, nil)
}
`

func buildFakeBackend(t *testing.T) string {
	t.Helper()
	sourceDirectory := t.TempDir()
	module := "module fakebackend\n\ngo 1.27.0\n"
	if err := os.WriteFile(filepath.Join(sourceDirectory, "go.mod"), []byte(module), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(sourceDirectory, "main.go"), []byte(fakeBackendSource), 0o600); err != nil {
		t.Fatal(err)
	}
	binary := filepath.Join(t.TempDir(), "fake-backend")
	command := exec.Command("go", "build", "-o", binary, ".")
	command.Dir = sourceDirectory
	command.Env = append(os.Environ(), "GOTOOLCHAIN=local", "GO111MODULE=on", "GOPROXY=off")
	if output, err := command.CombinedOutput(); err != nil {
		t.Fatalf("build the fake backend: %v\n%s", err, output)
	}
	return binary
}

func freeAddress(t *testing.T) string {
	t.Helper()
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	address := listener.Addr().String()
	_ = listener.Close()
	return address
}

func writeEnvFile(t *testing.T, entries ...string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "backend.env")
	if err := os.WriteFile(path, []byte(strings.Join(entries, "\n")+"\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

type childRecord struct {
	Token    string `json:"token"`
	Listener string `json:"listener"`
}

func readRecord(t *testing.T, path string) childRecord {
	t.Helper()
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var record childRecord
	if err := json.Unmarshal(contents, &record); err != nil {
		t.Fatal(err)
	}
	return record
}

func newController(t *testing.T, binary, envFile, address string) *Controller {
	t.Helper()
	return New(Options{
		Binary:       binary,
		EnvFile:      envFile,
		OperatorAddr: address,
		OTARoot:      t.TempDir(),
		LogPath:      filepath.Join(t.TempDir(), "backend.log"),
		ReadyTimeout: 10 * time.Second,
		StopGrace:    2 * time.Second,
	})
}

func TestStartWaitsForReadinessAndUsesFreshTokens(t *testing.T) {
	binary := buildFakeBackend(t)
	recordPath := filepath.Join(t.TempDir(), "record.json")
	controller := newController(t, binary, writeEnvFile(t, "GXB_TEST_RECORD="+recordPath), freeAddress(t))

	if err := controller.Start(false, "token-one"); err != nil {
		t.Fatal(err)
	}
	if !controller.Status().Running {
		t.Fatal("the backend must be running after Start")
	}
	first := readRecord(t, recordPath)
	if first.Token != "token-one" || first.Listener != "open" {
		t.Fatalf("first start saw %+v", first)
	}
	if err := controller.Stop(); err != nil {
		t.Fatal(err)
	}
	if controller.Status().Running {
		t.Fatal("the backend must not be running after Stop")
	}

	if err := controller.Start(true, "token-two"); err != nil {
		t.Fatal(err)
	}
	second := readRecord(t, recordPath)
	if second.Token != "token-two" || second.Listener != "closed" {
		t.Fatalf("second start saw %+v", second)
	}
	if first.Token == second.Token {
		t.Fatal("the per-start token did not change")
	}
	if err := controller.Stop(); err != nil {
		t.Fatal(err)
	}
}

func TestStartReportsEarlyExit(t *testing.T) {
	binary := buildFakeBackend(t)
	recordPath := filepath.Join(t.TempDir(), "record.json")
	controller := newController(t, binary, writeEnvFile(t, "GXB_TEST_RECORD="+recordPath, "GXB_TEST_EXIT_EARLY=1"), freeAddress(t))
	err := controller.Start(false, "token")
	if err == nil || !strings.Contains(err.Error(), "before it was ready") {
		t.Fatalf("want an early-exit report, got %v", err)
	}
	if controller.Status().Running {
		t.Fatal("a child that exited must not report running")
	}
}

func TestStartWaitsForDelayedReadiness(t *testing.T) {
	binary := buildFakeBackend(t)
	recordPath := filepath.Join(t.TempDir(), "record.json")
	controller := newController(t, binary, writeEnvFile(t, "GXB_TEST_RECORD="+recordPath, "GXB_TEST_DELAY_MS=300"), freeAddress(t))
	startedAt := time.Now()
	if err := controller.Start(false, "token"); err != nil {
		t.Fatal(err)
	}
	if elapsed := time.Since(startedAt); elapsed < 200*time.Millisecond {
		t.Fatalf("Start returned before the child answered: %s", elapsed)
	}
	if err := controller.Stop(); err != nil {
		t.Fatal(err)
	}
}

func TestStartOpenDropsStaleListener(t *testing.T) {
	t.Setenv("GXB_GAME_LISTENER", "closed")
	binary := buildFakeBackend(t)
	recordPath := filepath.Join(t.TempDir(), "record.json")
	controller := newController(t, binary, writeEnvFile(t, "GXB_TEST_RECORD="+recordPath, "GXB_GAME_LISTENER=closed"), freeAddress(t))
	if err := controller.Start(false, "token"); err != nil {
		t.Fatal(err)
	}
	defer func() { _ = controller.Stop() }()
	if got := readRecord(t, recordPath).Listener; got != "open" {
		t.Fatalf("the child saw listener %q, want open", got)
	}
}

func TestConcurrentStartAndStopStayConsistent(t *testing.T) {
	binary := buildFakeBackend(t)
	for iteration := 0; iteration < 5; iteration++ {
		recordPath := filepath.Join(t.TempDir(), "record.json")
		controller := newController(t, binary, writeEnvFile(t, "GXB_TEST_RECORD="+recordPath, "GXB_TEST_DELAY_MS=200"), freeAddress(t))
		var wait sync.WaitGroup
		wait.Add(2)
		go func() {
			defer wait.Done()
			_ = controller.Start(false, "token")
		}()
		go func() {
			defer wait.Done()
			_ = controller.Stop()
		}()
		wait.Wait()
		if err := controller.Stop(); err != nil {
			t.Fatal(err)
		}
		if controller.Status().Running {
			t.Fatal("a stopped controller still reports a running child")
		}
		controller.mutex.Lock()
		child := controller.child
		controller.mutex.Unlock()
		if child != nil {
			t.Fatal("a stopped controller still holds a child")
		}
	}
}
