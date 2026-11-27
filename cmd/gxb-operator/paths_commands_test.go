package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

func writeCLIAgentRoot(t *testing.T, listen string) string {
	t.Helper()
	root := t.TempDir()
	config := fmt.Sprintf(`{"listen":%q,"backend":{"operator_addr":"127.0.0.1:1"}}`, listen)
	if err := os.WriteFile(filepath.Join(root, operatoragent.AgentConfigFileName), []byte(config), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, operatoragent.SessionFileName), []byte("session-token\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	return root
}

func TestPathsSetArguments(t *testing.T) {
	change, err := parsePathsSetArguments([]string{"set", "client_tree", "/srv/client/ota"})
	if err != nil || change.Key != "client_tree" || change.Path != "/srv/client/ota" {
		t.Fatalf("change = %+v, err = %v", change, err)
	}
	for _, args := range [][]string{{}, {"set"}, {"set", "client_tree"}, {"get", "client_tree", "/x"}} {
		if _, err := parsePathsSetArguments(args); err == nil {
			t.Fatalf("%v was accepted", args)
		}
	}
}

func TestSilentPatchArguments(t *testing.T) {
	parsed, err := parseSilentPatchArguments([]string{"-s", "/srv/gxb", "--publish"})
	if err != nil || parsed.Tree != "/srv/gxb" || !parsed.Publish {
		t.Fatalf("parsed = %+v, err = %v", parsed, err)
	}
	parsed, err = parseSilentPatchArguments([]string{"-s", "/srv/gxb"})
	if err != nil || parsed.Publish {
		t.Fatalf("parsed = %+v, err = %v", parsed, err)
	}
	if _, err := parseSilentPatchArguments(nil); err == nil {
		t.Fatal("a missing tree was accepted")
	}
}

func TestResArgumentsAndLaneMapping(t *testing.T) {
	parsed, err := parseResArguments([]string{"-s", "/srv/assets"})
	if err != nil || parsed.Directory != "/srv/assets" || parsed.Lane != "recovered" {
		t.Fatalf("parsed = %+v, err = %v", parsed, err)
	}
	parsed, err = parseResArguments([]string{"-s", "/srv/assets", "--lane", "apk"})
	if err != nil || parsed.Lane != "apk" {
		t.Fatalf("parsed = %+v, err = %v", parsed, err)
	}
	if _, err := parseResArguments([]string{"-s", "/srv/assets", "--lane", "bundle"}); err == nil {
		t.Fatal("an unknown lane was accepted")
	}
	for lane, want := range map[string]string{"recovered": "recovered_res_path", "res": "res_path", "apk": "apk_res_path"} {
		field, err := resPathField(lane)
		if err != nil || field != want {
			t.Fatalf("%s -> %q, %v", lane, field, err)
		}
	}
}

func TestResolveClientTree(t *testing.T) {
	direct := filepath.Join(t.TempDir(), "ota")
	if err := os.MkdirAll(filepath.Join(direct, "src"), 0o755); err != nil {
		t.Fatal(err)
	}
	resolved, err := resolveClientTree(direct)
	if err != nil || resolved != direct {
		t.Fatalf("direct tree = %q, %v", resolved, err)
	}
	wrapper := t.TempDir()
	nested := filepath.Join(wrapper, "client", "ota")
	if err := os.MkdirAll(filepath.Join(nested, "src"), 0o755); err != nil {
		t.Fatal(err)
	}
	resolved, err = resolveClientTree(wrapper)
	if err != nil || resolved != nested {
		t.Fatalf("nested tree = %q, %v", resolved, err)
	}
	if _, err := resolveClientTree(t.TempDir()); err == nil {
		t.Fatal("a folder without a client tree was accepted")
	}
}

func TestOperationReleaseVersionReadsTheRegisteredRelease(t *testing.T) {
	operation := operatoragent.Operation{Result: json.RawMessage(`{"release":{"version":"1.631.9","lane":"code"},"report":{}}`)}
	version, err := operationReleaseVersion(operation)
	if err != nil || version != "1.631.9" {
		t.Fatalf("version = %q, err = %v", version, err)
	}
	if _, err := operationReleaseVersion(operatoragent.Operation{}); err == nil {
		t.Fatal("an empty operation result yielded a version")
	}
}

func TestBackupDashSIsTheBackupPathSet(t *testing.T) {
	var captured struct {
		Path string `json:"path"`
	}
	var mutex sync.Mutex
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		body, _ := io.ReadAll(request.Body)
		mutex.Lock()
		if request.Method != http.MethodPost || request.URL.Path != "/agent/v1/backup/path" {
			t.Errorf("unexpected request %s %s", request.Method, request.URL.Path)
		}
		if err := json.Unmarshal(body, &captured); err != nil {
			t.Errorf("body = %s", body)
		}
		mutex.Unlock()
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"path":"saved"}`))
	}))
	defer server.Close()
	root := writeCLIAgentRoot(t, strings.TrimPrefix(server.URL, "http://"))
	directory := t.TempDir()
	if err := runBackup(root, []string{"-s", directory}); err != nil {
		t.Fatal(err)
	}
	mutex.Lock()
	defer mutex.Unlock()
	if captured.Path != directory {
		t.Fatalf("backup path = %q", captured.Path)
	}
}

func TestResSendsTheFullOTASettingsWithOnePathReplaced(t *testing.T) {
	current := `{"lazy_fetch":"auto","res_path":"/old/res","apk_res_path":"","recovered_res_path":"/old/recovered","download_base_seconds":35,"download_min_kib_per_second":32,"cache_max_age_seconds":31536000,"serving_refresh_seconds":5,"volume_mb":99}`
	var captured struct {
		Payload map[string]any `json:"payload"`
	}
	var mutex sync.Mutex
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		switch request.URL.Path {
		case "/agent/v1/reads/agent.settings":
			_, _ = fmt.Fprintf(writer, `{"ota_settings":%s}`, current)
		case "/agent/v1/commands/ota.settings.set":
			body, _ := io.ReadAll(request.Body)
			mutex.Lock()
			if err := json.Unmarshal(body, &captured); err != nil {
				t.Errorf("body = %s", body)
			}
			mutex.Unlock()
			_, _ = writer.Write([]byte(`{"revision":2}`))
		default:
			t.Errorf("unexpected request %s", request.URL.Path)
		}
	}))
	defer server.Close()
	root := writeCLIAgentRoot(t, strings.TrimPrefix(server.URL, "http://"))
	directory := t.TempDir()
	if err := runRes(root, []string{"-s", directory, "--lane", "apk"}); err != nil {
		t.Fatal(err)
	}
	mutex.Lock()
	defer mutex.Unlock()
	if captured.Payload["apk_res_path"] != directory {
		t.Fatalf("apk_res_path = %v", captured.Payload["apk_res_path"])
	}
	if captured.Payload["res_path"] != "/old/res" || captured.Payload["recovered_res_path"] != "/old/recovered" {
		t.Fatalf("a path other than the lane changed: %+v", captured.Payload)
	}
}

func TestSilentPatchSetsTheTreeBuildsTheNextVersionAndPublishes(t *testing.T) {
	tree := filepath.Join(t.TempDir(), "ota")
	if err := os.MkdirAll(filepath.Join(tree, "src"), 0o755); err != nil {
		t.Fatal(err)
	}
	operationID := strings.Repeat("a", 32)
	var mutex sync.Mutex
	var pathsKey, pathsPath, buildLane, buildVersion, published string
	var lazyRefresh bool
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		body, _ := io.ReadAll(request.Body)
		writer.Header().Set("Content-Type", "application/json")
		mutex.Lock()
		defer mutex.Unlock()
		switch request.URL.Path {
		case "/agent/v1/commands/agent.paths.set":
			var command struct {
				Payload struct {
					Key  string `json:"key"`
					Path string `json:"path"`
				} `json:"payload"`
			}
			_ = json.Unmarshal(body, &command)
			pathsKey, pathsPath = command.Payload.Key, command.Payload.Path
			_, _ = writer.Write([]byte(`{"message":"saved"}`))
		case "/agent/v1/ota/build":
			var command struct {
				Lane        string `json:"lane"`
				Version     string `json:"version"`
				LazyRefresh bool   `json:"lazy_refresh"`
			}
			_ = json.Unmarshal(body, &command)
			buildLane, buildVersion, lazyRefresh = command.Lane, command.Version, command.LazyRefresh
			writer.WriteHeader(http.StatusAccepted)
			_, _ = fmt.Fprintf(writer, `{"operation_id":%q}`, operationID)
		case "/agent/v1/ops/" + operationID:
			_, _ = fmt.Fprintf(writer, `{"id":%q,"kind":"ota.build","state":"DONE","result":{"release":{"version":"1.631.9"},"report":{}}}`, operationID)
		case "/agent/v1/ota/publish":
			var command struct {
				Version string `json:"version"`
			}
			_ = json.Unmarshal(body, &command)
			published = command.Version
			_, _ = writer.Write([]byte(`{"version":"1.631.9","state":"ACTIVE"}`))
		default:
			t.Errorf("unexpected request %s", request.URL.Path)
		}
	}))
	defer server.Close()
	root := writeCLIAgentRoot(t, strings.TrimPrefix(server.URL, "http://"))
	if err := runSilentPatch(root, []string{"-s", tree, "--publish"}); err != nil {
		t.Fatal(err)
	}
	mutex.Lock()
	defer mutex.Unlock()
	if pathsKey != "client_tree" || pathsPath != tree {
		t.Fatalf("paths.set saw %q %q", pathsKey, pathsPath)
	}
	if buildLane != "code" || buildVersion != "" || !lazyRefresh {
		t.Fatalf("build saw lane %q version %q lazy %v", buildLane, buildVersion, lazyRefresh)
	}
	if published != "1.631.9" {
		t.Fatalf("published %q", published)
	}
}
