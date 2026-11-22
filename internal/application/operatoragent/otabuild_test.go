package operatoragent_test

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/operatorclient"
	"gxb.local/backend/v2/internal/application/operatoragent"
)

type fakeBuildOperator struct {
	mutex          sync.Mutex
	registers      int
	semanticKeys   []string
	failNext       int
	builtVersions  []string
	blockFirstRead bool
	readEntered    chan struct{}
	readRelease    chan struct{}
}

func (fake *fakeBuildOperator) statusBody() []byte {
	built := make([]map[string]string, 0, len(fake.builtVersions))
	for _, version := range fake.builtVersions {
		built = append(built, map[string]string{"version": version, "lane": "code"})
	}
	body, _ := json.Marshal(map[string]any{
		"revision": 0,
		"active":   map[string]any{"code": nil, "assets": nil, "catalog": []string{}},
		"built":    built,
	})
	return body
}

func (fake *fakeBuildOperator) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	switch {
	case request.URL.Path == "/operator/v1/reads/ota.status":
		fake.mutex.Lock()
		block := fake.blockFirstRead
		fake.blockFirstRead = false
		fake.mutex.Unlock()
		if block {
			close(fake.readEntered)
			<-fake.readRelease
		}
		fake.mutex.Lock()
		body := fake.statusBody()
		fake.mutex.Unlock()
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write(body)
	case request.URL.Path == "/operator/v1/commands/ota.register_build":
		body, _ := io.ReadAll(request.Body)
		var submitted struct {
			Envelope struct {
				SemanticKey string `json:"semantic_key"`
			} `json:"envelope"`
		}
		_ = json.Unmarshal(body, &submitted)
		fake.mutex.Lock()
		fake.registers++
		fake.semanticKeys = append(fake.semanticKeys, submitted.Envelope.SemanticKey)
		fail := fake.failNext > 0
		if fail {
			fake.failNext--
		}
		fake.mutex.Unlock()
		writer.Header().Set("Content-Type", "application/json")
		if fail {
			writer.WriteHeader(http.StatusInternalServerError)
			_, _ = writer.Write([]byte(`{"error_code":"AGENT_TEST","message":"injected register failure"}`))
			return
		}
		_, _ = writer.Write([]byte(`{"version":"1.631.2","lane":"code","state":"BUILT","rollback":false}`))
	default:
		http.NotFound(writer, request)
	}
}

func newBuildOperation(t *testing.T) (operatoragent.Build, *fakeBuildOperator, *operatoragent.Operations, string) {
	t.Helper()
	root := t.TempDir()
	baseline := filepath.Join(root, "baseline")
	clientTree := filepath.Join(root, "client")
	for _, directory := range []string{baseline, filepath.Join(clientTree, "src")} {
		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.WriteFile(filepath.Join(clientTree, "src", "Feature.lua"), []byte("return {}\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	fake := &fakeBuildOperator{readEntered: make(chan struct{}), readRelease: make(chan struct{})}
	server := httptest.NewServer(fake)
	t.Cleanup(server.Close)
	tokens := &operatoragent.TokenHolder{}
	tokens.Set("backend-token")
	operations := operatoragent.NewOperations(filepath.Join(root, "ops"), nil, time.Now)
	build := operatoragent.Build{
		Config: operatoragent.Config{
			OTARoot:       filepath.Join(root, "ota"),
			StockBaseline: baseline,
			ClientTree:    clientTree,
		},
		Operator:   operatorclient.New(server.URL, tokens),
		Operations: operations,
	}
	return build, fake, operations, root
}

func waitOperation(t *testing.T, operations *operatoragent.Operations, id string) operatoragent.Operation {
	t.Helper()
	deadline := time.Now().Add(15 * time.Second)
	for time.Now().Before(deadline) {
		operation, err := operations.Status(id)
		if err == nil && operation.State != operatoragent.OperationRunning {
			return operation
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("operation %s did not finish", id)
	return operatoragent.Operation{}
}

func TestBuildOperationRegistersOnce(t *testing.T) {
	build, fake, operations, _ := newBuildOperation(t)
	started, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2"})
	if err != nil {
		t.Fatal(err)
	}
	operation := waitOperation(t, operations, started.ID)
	if operation.State != operatoragent.OperationDone {
		t.Fatalf("operation = %+v", operation)
	}
	if fake.registers != 1 || len(fake.semanticKeys) != 1 || fake.semanticKeys[0] == "" {
		t.Fatalf("registers = %d, keys = %v", fake.registers, fake.semanticKeys)
	}
	if operation.SemanticKey != fake.semanticKeys[0] {
		t.Fatalf("the op record does not keep the semantic key")
	}
	var result struct {
		Release json.RawMessage `json:"release"`
		Report  struct {
			Exact int `json:"exact"`
		} `json:"report"`
	}
	if err := json.Unmarshal(operation.Result, &result); err != nil {
		t.Fatalf("result: %v (%s)", err, operation.Result)
	}
	if len(result.Release) == 0 || !strings.Contains(string(result.Release), "1.631.2") {
		t.Fatalf("registered release = %s", result.Release)
	}
}

func TestBuildOperationRegisterFailureRetriesIdempotently(t *testing.T) {
	build, fake, operations, root := newBuildOperation(t)
	fake.failNext = 1
	first, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2"})
	if err != nil {
		t.Fatal(err)
	}
	failed := waitOperation(t, operations, first.ID)
	if failed.State != operatoragent.OperationFailed || failed.FailedStep != "register_build" {
		t.Fatalf("first operation = %+v", failed)
	}
	if !strings.Contains(failed.Error, "AGENT_TEST") {
		t.Fatalf("the backend refusal was not passed through: %q", failed.Error)
	}
	updates := filepath.Join(root, "ota", "updates", "code")
	before := directoryBytes(t, updates)
	if len(before) == 0 {
		t.Fatal("the first build committed no volume")
	}

	second, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2"})
	if err != nil {
		t.Fatal(err)
	}
	done := waitOperation(t, operations, second.ID)
	if done.State != operatoragent.OperationDone {
		t.Fatalf("second operation = %+v", done)
	}
	if fake.registers != 2 {
		t.Fatalf("registers = %d", fake.registers)
	}
	if done.SemanticKey != failed.SemanticKey {
		t.Fatalf("the retry minted another semantic key: %q vs %q", done.SemanticKey, failed.SemanticKey)
	}
	if after := directoryBytes(t, updates); !equalBytes(before, after) {
		t.Fatal("the retry rebuilt different bytes")
	}
}

func TestBuildOperationRefusesVersionAlreadyListed(t *testing.T) {
	build, fake, operations, _ := newBuildOperation(t)
	fake.builtVersions = []string{"1.631.2"}
	started, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2"})
	if err != nil {
		t.Fatal(err)
	}
	failed := waitOperation(t, operations, started.ID)
	if failed.State != operatoragent.OperationFailed || failed.FailedStep != "read ota.status" {
		t.Fatalf("operation = %+v", failed)
	}
	if !strings.Contains(failed.Error, operatoragent.CodeVersionExists) {
		t.Fatalf("error = %q, want %s", failed.Error, operatoragent.CodeVersionExists)
	}
	if fake.registers != 0 {
		t.Fatalf("a listed version was registered %d times", fake.registers)
	}
}

func TestBuildOperationRefusesWhileAnotherRuns(t *testing.T) {
	build, fake, operations, _ := newBuildOperation(t)
	fake.blockFirstRead = true
	first, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2"})
	if err != nil {
		t.Fatal(err)
	}
	select {
	case <-fake.readEntered:
	case <-time.After(5 * time.Second):
		t.Fatal("the first build did not start")
	}
	_, err = build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2"})
	if err == nil {
		t.Fatal("a second build was admitted while the first ran")
	}
	var refusal *operatoragent.Refusal
	if !errors.As(err, &refusal) || refusal.Code != operatoragent.CodeOperationRunning {
		t.Fatalf("error = %v, want %s", err, operatoragent.CodeOperationRunning)
	}
	close(fake.readRelease)
	waitOperation(t, operations, first.ID)
}

func TestBuildOperationBackendNotRunning(t *testing.T) {
	build, _, operations, _ := newBuildOperation(t)
	build.Operator = operatorclient.New("127.0.0.1:1", &operatoragent.TokenHolder{})
	started, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2"})
	if err != nil {
		t.Fatal(err)
	}
	failed := waitOperation(t, operations, started.ID)
	if failed.State != operatoragent.OperationFailed || failed.FailedStep != "read ota.status" {
		t.Fatalf("operation = %+v", failed)
	}
	if !strings.Contains(failed.Error, operatoragent.CodeBackendUnavailable) {
		t.Fatalf("error = %q", failed.Error)
	}
}

func directoryBytes(t *testing.T, directory string) map[string][]byte {
	t.Helper()
	files := map[string][]byte{}
	entries, err := os.ReadDir(directory)
	if err != nil {
		t.Fatalf("read %s: %v", directory, err)
	}
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		content, err := os.ReadFile(filepath.Join(directory, entry.Name()))
		if err != nil {
			t.Fatal(err)
		}
		files[entry.Name()] = content
	}
	return files
}

func equalBytes(left, right map[string][]byte) bool {
	if len(left) != len(right) {
		return false
	}
	for name, content := range left {
		other, found := right[name]
		if !found || string(other) != string(content) {
			return false
		}
	}
	return true
}
