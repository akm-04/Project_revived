package operatoragent_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"reflect"
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
	volumeCounts   []int
	semanticKeys   []string
	failNext       int
	builtVersions  []string
	releaseExists  bool
	releaseLane    string
	releaseState   string
	blockFirstRead bool
	readEntered    chan struct{}
	readRelease    chan struct{}
	activeAssets   string
	blockRelease   bool
	releaseEntered chan struct{}
	releaseGate    chan struct{}
	calls          []string
}

func (fake *fakeBuildOperator) statusBody() []byte {
	built := make([]map[string]string, 0, len(fake.builtVersions))
	for _, version := range fake.builtVersions {
		built = append(built, map[string]string{"version": version, "lane": "code"})
	}
	active := map[string]any{"code": nil, "assets": nil, "catalog": []string{}}
	if fake.activeAssets != "" {
		active["assets"] = fake.activeAssets
	}
	body, _ := json.Marshal(map[string]any{
		"revision": 0,
		"active":   active,
		"built":    built,
	})
	return body
}

func (fake *fakeBuildOperator) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	fake.mutex.Lock()
	fake.calls = append(fake.calls, strings.TrimPrefix(request.URL.Path, "/operator/v1/"))
	fake.mutex.Unlock()
	switch {
	case request.URL.Path == "/operator/v1/reads/ota.status":
		fake.mutex.Lock()
		body := fake.statusBody()
		fake.mutex.Unlock()
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write(body)
	case request.URL.Path == "/operator/v1/reads/ota.release":
		fake.mutex.Lock()
		block := fake.blockRelease
		fake.blockRelease = false
		fake.mutex.Unlock()
		if block {
			close(fake.releaseEntered)
			<-fake.releaseGate
		}
		fake.mutex.Lock()
		exists := fake.releaseExists
		lane := fake.releaseLane
		state := fake.releaseState
		fake.mutex.Unlock()
		writer.Header().Set("Content-Type", "application/json")
		if !exists {
			_, _ = fmt.Fprintf(writer, `{"version":%q,"exists":false}`, request.URL.Query().Get("version"))
			return
		}
		_, _ = fmt.Fprintf(writer, `{"version":%q,"exists":true,"lane":%q,"state":%q}`, request.URL.Query().Get("version"), lane, state)
	case request.URL.Path == "/operator/v1/commands/ota.register_build":
		body, _ := io.ReadAll(request.Body)
		var submitted struct {
			Envelope struct {
				SemanticKey string `json:"semantic_key"`
			} `json:"envelope"`
			Payload struct {
				PackageFiles []json.RawMessage `json:"package_files"`
			} `json:"payload"`
		}
		_ = json.Unmarshal(body, &submitted)
		fake.mutex.Lock()
		fake.registers++
		fake.semanticKeys = append(fake.semanticKeys, submitted.Envelope.SemanticKey)
		fake.volumeCounts = append(fake.volumeCounts, len(submitted.Payload.PackageFiles))
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
	fake := &fakeBuildOperator{releaseEntered: make(chan struct{}), releaseGate: make(chan struct{})}
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

// Stage builds and registers only; it never restarts the backend and never
// logs anyone out (owner ruling Q4).
func TestStageNeverRestartsOrLogsOut(t *testing.T) {
	build, fake, operations, _ := newBuildOperation(t)
	started, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2"})
	if err != nil {
		t.Fatal(err)
	}
	operation := waitOperation(t, operations, started.ID)
	if operation.State != operatoragent.OperationDone {
		t.Fatalf("operation = %+v", operation)
	}
	fake.mutex.Lock()
	calls := append([]string(nil), fake.calls...)
	fake.mutex.Unlock()
	want := []string{"reads/ota.status", "reads/ota.status", "reads/ota.release", "commands/ota.register_build"}
	if !reflect.DeepEqual(calls, want) {
		t.Fatalf("stage calls = %v, want %v", calls, want)
	}
}

func TestBuildOperationUsesTheSettingsVolumeCap(t *testing.T) {
	build, fake, operations, root := newBuildOperation(t)
	if err := os.MkdirAll(build.Config.OTARoot, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(build.Config.OTARoot, "settings.json"), []byte(`{"lazy_fetch":"auto","res_path":"","volume_mb":1}`), 0o644); err != nil {
		t.Fatal(err)
	}
	large := make([]byte, 1_200_000)
	state := uint32(2463534242)
	for index := range large {
		state ^= state << 13
		state ^= state >> 17
		state ^= state << 5
		large[index] = byte(state)
	}
	if err := os.WriteFile(filepath.Join(root, "client", "src", "Large.lua"), large, 0o644); err != nil {
		t.Fatal(err)
	}

	started, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2"})
	if err != nil {
		t.Fatal(err)
	}
	operation := waitOperation(t, operations, started.ID)
	if operation.State != operatoragent.OperationDone {
		t.Fatalf("operation = %+v", operation)
	}
	fake.mutex.Lock()
	defer fake.mutex.Unlock()
	if len(fake.volumeCounts) != 1 || fake.volumeCounts[0] < 2 {
		t.Fatalf("the 1 MB settings cap did not split the package: %v", fake.volumeCounts)
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
	fake.releaseExists = true
	fake.releaseLane = "code"
	fake.releaseState = "ACTIVE"
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
	fake.blockRelease = true
	first, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2"})
	if err != nil {
		t.Fatal(err)
	}
	select {
	case <-fake.releaseEntered:
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
	close(fake.releaseGate)
	waitOperation(t, operations, first.ID)
}

func TestBuildOperationBackendNotRunning(t *testing.T) {
	build, _, _, _ := newBuildOperation(t)
	build.Operator = operatorclient.New("127.0.0.1:1", &operatoragent.TokenHolder{})
	_, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2"})
	var refusal *operatoragent.Refusal
	if !errors.As(err, &refusal) || refusal.Code != operatoragent.CodeBackendUnavailable {
		t.Fatalf("error = %v, want %s", err, operatoragent.CodeBackendUnavailable)
	}
}

func TestBuildRefusesExistingReleaseOutsideStatusList(t *testing.T) {
	build, fake, operations, root := newBuildOperation(t)
	fake.releaseExists = true
	fake.releaseLane = "code"
	fake.releaseState = "BUILT"
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
		t.Fatalf("the existing release was registered again %d times", fake.registers)
	}
	if _, err := os.Stat(filepath.Join(root, "ota", "updates", "code")); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("a refused version started build work: %v", err)
	}
}

func TestBuildRollbackReusesOnlyInactiveNumber(t *testing.T) {
	for _, state := range []string{"SUPERSEDED", "WITHDRAWN"} {
		t.Run(state, func(t *testing.T) {
			build, fake, operations, _ := newBuildOperation(t)
			fake.releaseExists = true
			fake.releaseLane = "code"
			fake.releaseState = state
			started, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2", Rollback: true})
			if err != nil {
				t.Fatal(err)
			}
			operation := waitOperation(t, operations, started.ID)
			if operation.State != operatoragent.OperationDone {
				t.Fatalf("operation = %+v", operation)
			}
			if fake.registers != 1 {
				t.Fatalf("registers = %d", fake.registers)
			}
		})
	}
}

func TestBuildRefusesReusedNumberUnlessRollbackReusesAnInactiveOne(t *testing.T) {
	cases := []struct {
		name     string
		state    string
		rollback bool
	}{
		{name: "rollback_over_ACTIVE", state: "ACTIVE", rollback: true},
		{name: "rollback_over_BUILT", state: "BUILT", rollback: true},
		{name: "forward_over_SUPERSEDED", state: "SUPERSEDED", rollback: false},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			build, fake, operations, root := newBuildOperation(t)
			fake.releaseExists = true
			fake.releaseLane = "code"
			fake.releaseState = testCase.state
			started, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2", Rollback: testCase.rollback})
			if err != nil {
				t.Fatal(err)
			}
			failed := waitOperation(t, operations, started.ID)
			if failed.State != operatoragent.OperationFailed || failed.FailedStep != "read ota.status" {
				t.Fatalf("operation = %+v", failed)
			}
			want := "already used by the code release (" + testCase.state + ")"
			if !strings.Contains(failed.Error, operatoragent.CodeVersionExists) || !strings.Contains(failed.Error, want) {
				t.Fatalf("error = %q, want %s and %q", failed.Error, operatoragent.CodeVersionExists, want)
			}
			if fake.registers != 0 {
				t.Fatalf("registers = %d", fake.registers)
			}
			if _, statErr := os.Stat(filepath.Join(root, "ota", "updates", "code")); !errors.Is(statErr, os.ErrNotExist) {
				t.Fatalf("a refused version started build work: %v", statErr)
			}
		})
	}
}

func TestBuildAllowsUnusedNumber(t *testing.T) {
	build, fake, operations, _ := newBuildOperation(t)
	started, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2", Rollback: true})
	if err != nil {
		t.Fatal(err)
	}
	operation := waitOperation(t, operations, started.ID)
	if operation.State != operatoragent.OperationDone {
		t.Fatalf("operation = %+v", operation)
	}
	if fake.registers != 1 {
		t.Fatalf("registers = %d", fake.registers)
	}
}

func TestBuildLazyRefreshWithoutAssetsRelease(t *testing.T) {
	build, fake, operations, _ := newBuildOperation(t)
	started, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2", LazyRefresh: true})
	if err != nil {
		t.Fatal(err)
	}
	failed := waitOperation(t, operations, started.ID)
	if failed.State != operatoragent.OperationFailed || failed.FailedStep != "build" {
		t.Fatalf("operation = %+v", failed)
	}
	if !strings.Contains(failed.Error, operatoragent.CodeBuildNoAssetsRelease) {
		t.Fatalf("error = %q, want %s", failed.Error, operatoragent.CodeBuildNoAssetsRelease)
	}
	if fake.registers != 0 {
		t.Fatalf("registers = %d", fake.registers)
	}
}

// TestBuildLazyRefreshUsesStockCatalog proves agent.json's stock_catalog reaches
// the code-lane lazy refresh end to end, even when the stock baseline carries no
// version.json (OA-8).
func TestBuildLazyRefreshUsesStockCatalog(t *testing.T) {
	build, fake, operations, root := newBuildOperation(t)
	fake.activeAssets = "1.631.1"
	recoveredPath := prepareLazyRefreshRelease(t, build.Config.OTARoot, root)
	writeBuildTestFile(t, filepath.Join(recoveredPath, "web", "images", "recovered.png"), []byte("recovered"))

	catalogDirectory := filepath.Join(root, "catalog")
	rows := []map[string]any{
		{"path": "res/web/images/delivered.png", "md5": strings.Repeat("d", 32), "size": 5, "force": 0},
		{"path": "res/web/images/recovered.png", "md5": strings.Repeat("c", 32), "size": 4, "force": 0},
	}
	encoded, err := json.Marshal(rows)
	if err != nil {
		t.Fatal(err)
	}
	for _, prefix := range []string{"assets/src_32", "assets/src_64"} {
		writeBuildTestFile(t, filepath.Join(catalogDirectory, filepath.FromSlash(prefix), "version.json"), encoded)
	}
	build.Config.StockCatalog = catalogDirectory

	started, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2", LazyRefresh: true})
	if err != nil {
		t.Fatal(err)
	}
	operation := waitOperation(t, operations, started.ID)
	if operation.State != operatoragent.OperationDone {
		t.Fatalf("operation = %+v", operation)
	}
	var result struct {
		Report struct {
			LazySupplied  int `json:"lazy_supplied"`
			LazyRetained  int `json:"lazy_retained"`
			LazyRecovered int `json:"lazy_recovered"`
		} `json:"report"`
	}
	if err := json.Unmarshal(operation.Result, &result); err != nil {
		t.Fatalf("result: %v (%s)", err, operation.Result)
	}
	if result.Report.LazySupplied != 1 || result.Report.LazyRetained != 1 || result.Report.LazyRecovered != 1 {
		t.Fatalf("report = %+v", result.Report)
	}
	if fake.registers != 1 {
		t.Fatalf("registers = %d", fake.registers)
	}
}

// TestBuildLazyRefreshRefusesWithoutCatalogue proves a lazy refresh with no
// usable stock catalogue is a permanent AGENT_BUILD_CATALOG_INVALID refusal.
func TestBuildLazyRefreshRefusesWithoutCatalogue(t *testing.T) {
	build, fake, operations, root := newBuildOperation(t)
	fake.activeAssets = "1.631.1"
	prepareLazyRefreshRelease(t, build.Config.OTARoot, root)

	started, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2", LazyRefresh: true})
	if err != nil {
		t.Fatal(err)
	}
	failed := waitOperation(t, operations, started.ID)
	if failed.State != operatoragent.OperationFailed || failed.FailedStep != "build" {
		t.Fatalf("operation = %+v", failed)
	}
	if !strings.Contains(failed.Error, operatoragent.CodeBuildCatalogInvalid) {
		t.Fatalf("error = %q, want %s", failed.Error, operatoragent.CodeBuildCatalogInvalid)
	}
	if fake.registers != 0 {
		t.Fatalf("registers = %d", fake.registers)
	}
}

// prepareLazyRefreshRelease writes the ACTIVE assets release's sidecar and the
// settings recovered_res_path a code lazy refresh reads.
func prepareLazyRefreshRelease(t *testing.T, otaRoot, root string) string {
	t.Helper()
	assetsDirectory := filepath.Join(otaRoot, "updates", "assets")
	if err := os.MkdirAll(assetsDirectory, 0o755); err != nil {
		t.Fatal(err)
	}
	sidecar := map[string]any{"entries": []map[string]any{
		{"path": "web/images/delivered.png", "md5": strings.Repeat("d", 32), "size": 5},
	}}
	encoded, err := json.Marshal(sidecar)
	if err != nil {
		t.Fatal(err)
	}
	writeBuildTestFile(t, filepath.Join(assetsDirectory, "1.631.1-abcdefabcdef.zip.res.json"), encoded)

	recoveredPath := filepath.Join(root, "recovered")
	if err := os.MkdirAll(recoveredPath, 0o755); err != nil {
		t.Fatal(err)
	}
	settings, err := json.Marshal(map[string]any{"lazy_fetch": "auto", "res_path": "", "recovered_res_path": recoveredPath, "volume_mb": 99})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(otaRoot, 0o755); err != nil {
		t.Fatal(err)
	}
	writeBuildTestFile(t, filepath.Join(otaRoot, "settings.json"), settings)
	return recoveredPath
}

const (
	buildLedgerMD5 = "0123456789abcdef0123456789abcdef"
	buildLedgerSHA = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
)

// ledgerRelease is one valid releases.json row; manifestFiles is the release's
// manifest "files" array.
func ledgerRelease(version, state string, manifestFiles []map[string]any) map[string]any {
	return map[string]any{
		"id":      1,
		"version": version,
		"lane":    "code",
		"state":   state,
		"package_files": []map[string]any{{
			"name":   version + "-" + buildLedgerSHA[:12] + ".zip.001",
			"size":   1000,
			"md5":    buildLedgerMD5,
			"sha256": buildLedgerSHA,
		}},
		"total_size": 1000,
		"md5":        buildLedgerMD5,
		"sha256":     buildLedgerSHA,
		"manifest":   map[string]any{"files": manifestFiles},
	}
}

func writeReleaseLedger(t *testing.T, otaRoot string, releases []map[string]any) {
	t.Helper()
	encoded, err := json.Marshal(map[string]any{"version": 1, "releases": releases})
	if err != nil {
		t.Fatalf("encode release ledger: %v", err)
	}
	writeBuildTestFile(t, filepath.Join(otaRoot, "releases.json"), encoded)
}

// TestBuildRestoresPathsFromTheReleaseLedger proves the agent reads earlier
// code-lane manifests from releases.json and passes their paths to the build.
func TestBuildRestoresPathsFromTheReleaseLedger(t *testing.T) {
	build, fake, operations, root := newBuildOperation(t)
	stock := []byte("return {}\n")
	writeBuildTestFile(t, filepath.Join(root, "stock", "app", "example", "Feature.lua"), stock)
	build.Config.StockSource = filepath.Join(root, "stock")
	if err := os.Remove(filepath.Join(root, "client", "src", "Feature.lua")); err != nil {
		t.Fatal(err)
	}
	writeBuildTestFile(t, filepath.Join(root, "client", "src", "Kept.lua"), []byte("return {}\n"))
	writeReleaseLedger(t, build.Config.OTARoot, []map[string]any{
		ledgerRelease("1.631.1", "SUPERSEDED", []map[string]any{
			{"path": "src_32/app/example/Feature.lua", "size": len(stock), "md5": buildLedgerMD5},
			{"path": "src_64/app/example/Feature.lua", "size": len(stock), "md5": buildLedgerMD5},
		}),
	})

	started, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2"})
	if err != nil {
		t.Fatal(err)
	}
	operation := waitOperation(t, operations, started.ID)
	if operation.State != operatoragent.OperationDone {
		t.Fatalf("operation = %+v", operation)
	}
	var result struct {
		Report struct {
			Reverted       int      `json:"reverted"`
			RevertedSample []string `json:"reverted_sample"`
		} `json:"report"`
	}
	if err := json.Unmarshal(operation.Result, &result); err != nil {
		t.Fatalf("result: %v (%s)", err, operation.Result)
	}
	if result.Report.Reverted != 1 || !containsText(result.Report.RevertedSample, "app/example/Feature.lua") {
		t.Fatalf("report = %+v", result.Report)
	}
	if fake.registers != 1 {
		t.Fatalf("registers = %d", fake.registers)
	}
}

// TestBuildRefusesAnUnreadableReleaseManifest proves an earlier code-lane row
// whose manifest cannot be read refuses the build instead of being skipped.
func TestBuildRefusesAnUnreadableReleaseManifest(t *testing.T) {
	build, fake, operations, _ := newBuildOperation(t)
	broken := ledgerRelease("1.631.1", "SUPERSEDED", nil)
	broken["manifest"] = map[string]any{"files": []map[string]any{{"path": "", "size": 1, "md5": buildLedgerMD5}}}
	writeReleaseLedger(t, build.Config.OTARoot, []map[string]any{broken})

	started, err := build.Start(context.Background(), operatoragent.BuildRequest{Lane: "code", Version: "1.631.2"})
	if err != nil {
		t.Fatal(err)
	}
	operation := waitOperation(t, operations, started.ID)
	if operation.State != operatoragent.OperationFailed || operation.FailedStep != "build" {
		t.Fatalf("operation = %+v", operation)
	}
	if !strings.Contains(operation.Error, operatoragent.CodeBuildConfig) || !strings.Contains(operation.Error, "1.631.1") {
		t.Fatalf("error = %q", operation.Error)
	}
	if fake.registers != 0 {
		t.Fatalf("registers = %d", fake.registers)
	}
}

func containsText(values []string, want string) bool {
	for _, value := range values {
		if value == want {
			return true
		}
	}
	return false
}

func writeBuildTestFile(t *testing.T, path string, content []byte) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, content, 0o644); err != nil {
		t.Fatal(err)
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
