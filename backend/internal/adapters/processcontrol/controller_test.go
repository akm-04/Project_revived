package processcontrol

import (
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operatoragent"
	appotarelease "gxb.local/backend/v2/internal/application/otarelease"
)

const fakeBackendSource = `package main

import (
	"encoding/json"
	"fmt"
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
			"token":      os.Getenv("GXB_OPERATOR_TOKEN"),
			"listener":   os.Getenv("GXB_GAME_LISTENER"),
			"media_root": os.Getenv("GXB_NOTICE_MEDIA_ROOT"),
			"ota_root":   os.Getenv("GXB_OTA_ROOT"),
		})
		_ = os.WriteFile(record, encoded, 0o600)
	}
	if os.Getenv("GXB_TEST_PRINT") == "1" {
		fmt.Println("backend-line")
	}
	if code, err := strconv.Atoi(os.Getenv("GXB_TEST_EXIT_EARLY")); err == nil && code > 0 {
		os.Exit(code)
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
	Token     string `json:"token"`
	Listener  string `json:"listener"`
	MediaRoot string `json:"media_root"`
	OTARoot   string `json:"ota_root"`
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
		Binary:        binary,
		EnvFile:       envFile,
		OperatorAddr:  address,
		OTARoot:       t.TempDir(),
		LogsDirectory: t.TempDir(),
		ReadyTimeout:  10 * time.Second,
		StopGrace:     2 * time.Second,
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

func TestStartPassesTheNoticeMediaRootUnlessTheEnvFileSetsIt(t *testing.T) {
	binary := buildFakeBackend(t)
	options := Options{
		Binary:          binary,
		OperatorAddr:    freeAddress(t),
		OTARoot:         t.TempDir(),
		LogsDirectory:   t.TempDir(),
		ReadyTimeout:    10 * time.Second,
		StopGrace:       2 * time.Second,
		NoticeMediaRoot: "/srv/pictures",
	}

	unsetRecord := filepath.Join(t.TempDir(), "record.json")
	options.EnvFile = writeEnvFile(t, "GXB_TEST_RECORD="+unsetRecord)
	controller := New(options)
	if err := controller.Start(false, "token"); err != nil {
		t.Fatal(err)
	}
	if got := readRecord(t, unsetRecord).MediaRoot; got != "/srv/pictures" {
		t.Fatalf("media root = %q, want the resolved folder", got)
	}
	if err := controller.Stop(); err != nil {
		t.Fatal(err)
	}

	fromFileRecord := filepath.Join(t.TempDir(), "record.json")
	options.EnvFile = writeEnvFile(t, "GXB_TEST_RECORD="+fromFileRecord, "GXB_NOTICE_MEDIA_ROOT=/from/env")
	controller = New(options)
	if err := controller.Start(false, "token"); err != nil {
		t.Fatal(err)
	}
	if got := readRecord(t, fromFileRecord).MediaRoot; got != "/from/env" {
		t.Fatalf("media root = %q, want the env file value", got)
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

// TestStartReportsTheNoAssetsRefusal proves the backend's guard reaches the
// agent as a permanent 409 refusal, not as a generic start failure.
func TestStartReportsTheNoAssetsRefusal(t *testing.T) {
	binary := buildFakeBackend(t)
	controller := newController(t, binary, writeEnvFile(t, "GXB_TEST_EXIT_EARLY="+strconv.Itoa(appotarelease.NoAssetsExitCode)), freeAddress(t))
	err := controller.Start(false, "token")
	var refusal *operatoragent.Refusal
	if !errors.As(err, &refusal) || refusal.Code != operatoragent.CodeBackendNoAssetsRelease {
		t.Fatalf("want the no-assets refusal, got %v", err)
	}
	if controller.Status().Running {
		t.Fatal("a refused child must not report running")
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

func TestStartReadsAgentJSONOnEachStart(t *testing.T) {
	binary := buildFakeBackend(t)
	address := freeAddress(t)
	root := t.TempDir()
	recordOne := filepath.Join(t.TempDir(), "record-one.json")
	recordTwo := filepath.Join(t.TempDir(), "record-two.json")
	otaOne, otaTwo := t.TempDir(), t.TempDir()
	writeControllerConfig(t, root, binary, writeEnvFile(t, "GXB_TEST_RECORD="+recordOne), address, otaOne)
	controller := New(Options{Root: root, LogsDirectory: t.TempDir(), ReadyTimeout: 10 * time.Second, StopGrace: 2 * time.Second})
	if err := controller.Start(false, "token-one"); err != nil {
		t.Fatal(err)
	}
	if record := readRecord(t, recordOne); record.OTARoot != otaOne {
		t.Fatalf("first start saw ota root %q", record.OTARoot)
	}
	if err := controller.Stop(); err != nil {
		t.Fatal(err)
	}

	// A binary that no longer exists proves the controller read agent.json
	// again instead of keeping its construction-time path.
	writeControllerConfig(t, root, filepath.Join(root, "missing-backend"), writeEnvFile(t, "GXB_TEST_RECORD="+recordOne), address, otaOne)
	if err := controller.Start(false, "token-two"); err == nil {
		t.Fatal("the missing binary from the live agent.json was not used")
	}

	writeControllerConfig(t, root, binary, writeEnvFile(t, "GXB_TEST_RECORD="+recordTwo), address, otaTwo)
	if err := controller.Start(false, "token-three"); err != nil {
		t.Fatal(err)
	}
	defer func() { _ = controller.Stop() }()
	record := readRecord(t, recordTwo)
	if record.Token != "token-three" || record.OTARoot != otaTwo {
		t.Fatalf("second live start saw %+v", record)
	}
}

// writeControllerConfig writes the agent.json the controller reloads at Start.
func writeControllerConfig(t *testing.T, root, binary, envFile, address, otaRoot string) {
	t.Helper()
	contents := fmt.Sprintf(
		`{"listen":"127.0.0.1:8090","ota_root":%q,"backend":{"binary":%q,"env_file":%q,"operator_addr":%q,"ready_timeout_seconds":10,"stop_grace_seconds":2}}`,
		otaRoot, binary, envFile, address,
	)
	if err := os.WriteFile(filepath.Join(root, operatoragent.AgentConfigFileName), []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
}

func TestBackendOutputIsCapturedInADatedFile(t *testing.T) {
	binary := buildFakeBackend(t)
	logsDirectory := t.TempDir()
	controller := New(Options{
		Binary:        binary,
		EnvFile:       writeEnvFile(t, "GXB_TEST_PRINT=1"),
		OperatorAddr:  freeAddress(t),
		OTARoot:       t.TempDir(),
		LogsDirectory: logsDirectory,
		ReadyTimeout:  10 * time.Second,
		StopGrace:     2 * time.Second,
	})
	if err := controller.Start(false, "token"); err != nil {
		t.Fatal(err)
	}
	if err := controller.Stop(); err != nil {
		t.Fatal(err)
	}
	name := "backend-" + time.Now().UTC().Format("2006-01-02") + ".log"
	contents, err := os.ReadFile(filepath.Join(logsDirectory, name))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(contents), "backend-line") {
		t.Fatalf("stdout missing from %s: %q", name, contents)
	}
}
