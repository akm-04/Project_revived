//go:build postgres

package operatorapi_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/operatorapi"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	"gxb.local/backend/v2/internal/adapters/postgres/otastore"
	"gxb.local/backend/v2/internal/application/operator"
	appota "gxb.local/backend/v2/internal/application/otarelease"
	"gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	nativeSHA = "1212121212121212121212121212121212121212121212121212121212121212"
	nativeMD5 = "34343434343434343434343434343434"
)

func nativePool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I11A_L3_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_L3_DSN required (ops/testing/fresh_db.sh i11a_l3_commands)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func nativeBuild(version string) otarelease.BuildRequest {
	packageFiles, _ := json.Marshal([]otarelease.PackageVolume{{Name: version + "-" + nativeSHA[:12] + ".zip.001", Size: 1000, MD5: nativeMD5, SHA256: nativeSHA}})
	manifest, _ := json.Marshal(map[string]any{"files": []otarelease.ManifestEntry{{Path: "src_64/app/a.lua", Size: 1, MD5: nativeMD5}}})
	return otarelease.BuildRequest{Version: version, Lane: "code", PackageFiles: packageFiles, TotalSize: 1000, MD5: nativeMD5, SHA256: nativeSHA, Manifest: manifest}
}

func nativeRoot(t *testing.T, versions ...string) string {
	t.Helper()
	root := t.TempDir()
	directory := filepath.Join(root, "updates", "code")
	if err := os.MkdirAll(directory, 0o755); err != nil {
		t.Fatal(err)
	}
	for _, version := range versions {
		if err := os.WriteFile(filepath.Join(directory, version+"-"+nativeSHA[:12]+".zip.001"), make([]byte, 1000), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	return root
}

type nativeEnvelope struct {
	Principal        string `json:"principal"`
	Role             string `json:"role"`
	Scope            string `json:"scope"`
	Reason           string `json:"reason"`
	SemanticKey      string `json:"semantic_key"`
	ExpectedRevision *int64 `json:"expected_revision,omitempty"`
}

func nativeBody(t *testing.T, envelope nativeEnvelope, payload any) string {
	t.Helper()
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	document, err := json.Marshal(map[string]any{"envelope": envelope, "payload": json.RawMessage(raw)})
	if err != nil {
		t.Fatal(err)
	}
	return string(document)
}

func nativePost(t *testing.T, handler operatorapi.Handler, name, body string) *httptest.ResponseRecorder {
	t.Helper()
	request := httptest.NewRequest(http.MethodPost, "/operator/v1/commands/"+name, strings.NewReader(body))
	request.RemoteAddr = "127.0.0.1:5000"
	request.Header.Set("Authorization", "Bearer secret")
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, request)
	return recorder
}

func nativeGet(t *testing.T, handler operatorapi.Handler, path string) *httptest.ResponseRecorder {
	t.Helper()
	request := httptest.NewRequest(http.MethodGet, path, nil)
	request.RemoteAddr = "127.0.0.1:5000"
	request.Header.Set("Authorization", "Bearer secret")
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, request)
	return recorder
}

func newKey(t *testing.T) string {
	t.Helper()
	key, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return key.String()
}

func nativeHandler(t *testing.T, pool *pg.Pool, root string) operatorapi.Handler {
	t.Helper()
	bus := operator.Bus{Runner: tx.Runner{DB: pool}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: appota.Commands{Store: otastore.Store{}, Root: root}.Handlers()}
	reads := map[string]operatorapi.Read{
		"ota.status":          operatorapi.OTAStatus(appota.StatusService{Runner: tx.Runner{DB: pool}, Operations: operation.Factory{Clock: clock.System{}}, Store: otastore.Store{}}),
		"operator.audit.list": operatorapi.AuditList(operator.AuditService{Runner: tx.Runner{DB: pool}, Operations: operation.Factory{Clock: clock.System{}}, Reader: operatorstore.Store{}}),
	}
	return operatorapi.Handler{Bus: bus, Token: "secret", Reads: reads}
}

func TestPublishReplayMakesOneActivationAndKeyReuseIsRefused(t *testing.T) {
	pool := nativePool(t)
	const version = "9.310.1"
	resetNativeRelease(t, pool, version)
	handler := nativeHandler(t, pool, nativeRoot(t, version))

	registered := nativePost(t, handler, "ota.register_build", nativeBody(t, nativeEnvelope{Principal: "root", Role: "root", Scope: "global", Reason: "native", SemanticKey: newKey(t)}, nativeBuild(version)))
	if registered.Code != http.StatusOK {
		t.Fatalf("register: %d %s", registered.Code, registered.Body)
	}

	var revision int64
	if err := pool.QueryRow(context.Background(), `SELECT COALESCE(max(id),0) FROM ota_activations`).Scan(&revision); err != nil {
		t.Fatal(err)
	}
	envelope := nativeEnvelope{Principal: "root", Role: "root", Scope: "global", Reason: "native publish", SemanticKey: newKey(t), ExpectedRevision: &revision}
	body := nativeBody(t, envelope, map[string]string{"version": version})
	first := nativePost(t, handler, "ota.publish", body)
	if first.Code != http.StatusOK {
		t.Fatalf("publish: %d %s", first.Code, first.Body)
	}
	replay := nativePost(t, handler, "ota.publish", body)
	if replay.Code != http.StatusOK || !strings.Contains(replay.Body.String(), `"replayed":true`) {
		t.Fatalf("replay: %d %s", replay.Code, replay.Body)
	}
	var firstReply, replayReply struct {
		Result json.RawMessage `json:"result"`
	}
	if err := json.Unmarshal(first.Body.Bytes(), &firstReply); err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(replay.Body.Bytes(), &replayReply); err != nil {
		t.Fatal(err)
	}
	var firstResult, replayResult any
	if json.Unmarshal(firstReply.Result, &firstResult) != nil || json.Unmarshal(replayReply.Result, &replayResult) != nil || !reflect.DeepEqual(firstResult, replayResult) {
		t.Fatalf("replay result %s != %s", replayReply.Result, firstReply.Result)
	}
	var activation appota.Activation
	if err := json.Unmarshal(firstReply.Result, &activation); err != nil || activation.ActivationID == 0 {
		t.Fatalf("publish activation=%s err=%v", firstReply.Result, err)
	}
	var activations int
	if err := pool.QueryRow(context.Background(), `SELECT count(*) FROM ota_activations WHERE version=$1`, version).Scan(&activations); err != nil {
		t.Fatal(err)
	}
	if activations != 1 {
		t.Fatalf("activation rows = %d", activations)
	}

	reused := nativeBody(t, envelope, map[string]string{"version": version + "9"})
	conflict := nativePost(t, handler, "ota.withdraw", reused)
	var refusal operator.Refusal
	if conflict.Code != http.StatusConflict || json.Unmarshal(conflict.Body.Bytes(), &refusal) != nil || refusal.Code != operator.CodeKeyReused {
		t.Fatalf("reused key: %d %s", conflict.Code, conflict.Body)
	}

	status := nativeGet(t, handler, "/operator/v1/reads/ota.status")
	if status.Code != http.StatusOK {
		t.Fatalf("ota.status: %d %s", status.Code, status.Body)
	}
	var report struct {
		Revision int64 `json:"revision"`
		Active   struct {
			Code *string `json:"code"`
		} `json:"active"`
	}
	if err := json.Unmarshal(status.Body.Bytes(), &report); err != nil || report.Revision != activation.ActivationID || report.Active.Code == nil || *report.Active.Code != version {
		t.Fatalf("ota.status body=%s err=%v", status.Body, err)
	}
	var lanes struct {
		Lanes []struct {
			Lane          string  `json:"lane"`
			ActiveVersion *string `json:"active_version"`
			PublishedAt   *string `json:"published_at"`
		} `json:"lanes"`
	}
	if err := json.Unmarshal(status.Body.Bytes(), &lanes); err != nil || len(lanes.Lanes) != 3 {
		t.Fatalf("ota.status lanes=%s err=%v", status.Body, err)
	}
	codeLane := false
	for _, lane := range lanes.Lanes {
		if lane.Lane != "code" {
			continue
		}
		codeLane = lane.ActiveVersion != nil && *lane.ActiveVersion == version && lane.PublishedAt != nil
	}
	if !codeLane {
		t.Fatalf("the code lane summary is missing from %s", status.Body)
	}
}

func resetNativeRelease(t *testing.T, pool *pg.Pool, version string) {
	t.Helper()
	remove := func() {
		ctx := context.Background()
		if _, err := pool.Raw().Exec(ctx, `DELETE FROM ota_activations WHERE version=$1`, version); err != nil {
			t.Fatal(err)
		}
		if _, err := pool.Raw().Exec(ctx, `DELETE FROM ota_releases WHERE version=$1`, version); err != nil {
			t.Fatal(err)
		}
	}
	remove()
	t.Cleanup(remove)
}

func TestAuditReadPagesNewestFirstWithCursor(t *testing.T) {
	pool := nativePool(t)
	handler := nativeHandler(t, pool, t.TempDir())
	keys := []string{"audit-a", "audit-b", "audit-c"}
	removeAudit := func() {
		if _, err := pool.Raw().Exec(context.Background(), `DELETE FROM operator_commands WHERE semantic_key = ANY($1)`, keys); err != nil {
			t.Fatal(err)
		}
	}
	removeAudit()
	t.Cleanup(removeAudit)
	base := time.Now().UTC().Truncate(time.Microsecond)
	for index, key := range keys {
		at := base.Add(time.Duration(index) * time.Second)
		if _, err := pool.Raw().Exec(context.Background(), `INSERT INTO operator_commands(
			semantic_key,module_command,payload_sha256,principal,role,scope,reason,state,result_json,created_at,finished_at)
			VALUES($1,'audit.test',$2,'root','root','global','native audit','APPLIED','{}'::jsonb,$3,$3)`,
			key, nativeSHA, at); err != nil {
			t.Fatal(err)
		}
	}

	first := nativeGet(t, handler, "/operator/v1/reads/operator.audit.list?module=audit.test&limit=2")
	if first.Code != http.StatusOK {
		t.Fatalf("first page: %d %s", first.Code, first.Body)
	}
	var page struct {
		Commands   []operator.Record `json:"commands"`
		NextCursor string            `json:"next_cursor"`
	}
	if err := json.Unmarshal(first.Body.Bytes(), &page); err != nil {
		t.Fatal(err)
	}
	if len(page.Commands) != 2 || page.Commands[0].SemanticKey != "audit-c" || page.Commands[1].SemanticKey != "audit-b" || page.NextCursor == "" {
		t.Fatalf("first page=%s", first.Body)
	}
	second := nativeGet(t, handler, "/operator/v1/reads/operator.audit.list?module=audit.test&limit=2&cursor="+page.NextCursor)
	if second.Code != http.StatusOK {
		t.Fatalf("second page: %d %s", second.Code, second.Body)
	}
	var next struct {
		Commands []operator.Record `json:"commands"`
	}
	if err := json.Unmarshal(second.Body.Bytes(), &next); err != nil {
		t.Fatal(err)
	}
	if len(next.Commands) != 1 || next.Commands[0].SemanticKey != "audit-a" {
		t.Fatalf("second page=%s", second.Body)
	}

	unauthorized := httptest.NewRequest(http.MethodGet, "/operator/v1/reads/operator.audit.list", nil)
	unauthorized.RemoteAddr = "127.0.0.1:5000"
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, unauthorized)
	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("read without token: %d", recorder.Code)
	}
}
