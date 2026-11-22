//go:build postgres

package otastore_test

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"

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
	l3SHA = "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
	l3MD5 = "ffffffffffffffffffffffffffffffff"
)

func l3Pool(t *testing.T) *pg.Pool {
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

func l3BuildRequest(t *testing.T, version, lane string) otarelease.BuildRequest {
	t.Helper()
	packageFiles, err := json.Marshal([]otarelease.PackageVolume{{Name: version + "-" + l3SHA[:12] + ".zip.001", Size: 1000, MD5: l3MD5, SHA256: l3SHA}})
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := json.Marshal(map[string]any{"files": []otarelease.ManifestEntry{{Path: "src_64/app/" + version + ".lua", Size: 1, MD5: l3MD5}}})
	if err != nil {
		t.Fatal(err)
	}
	return otarelease.BuildRequest{Version: version, Lane: lane, PackageFiles: packageFiles, TotalSize: 1000, MD5: l3MD5, SHA256: l3SHA, Manifest: manifest}
}

func l3Root(t *testing.T, requests ...otarelease.BuildRequest) string {
	t.Helper()
	root := t.TempDir()
	for _, request := range requests {
		directory := filepath.Join(root, "updates", request.Lane)
		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatal(err)
		}
		file := filepath.Join(directory, request.Version+"-"+request.SHA256[:12]+".zip.001")
		if err := os.WriteFile(file, make([]byte, request.TotalSize), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	return root
}

func l3Command(t *testing.T, name string, revision *int64, payload any) operator.Command {
	t.Helper()
	key, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(name, operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "i11a l3 native", SemanticKey: key.String(), ExpectedRevision: revision}, raw)
	if err != nil {
		t.Fatal(err)
	}
	return command
}

func l3Bus(pool *pg.Pool, root string) operator.Bus {
	return operator.Bus{Runner: tx.Runner{DB: pool}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: appota.Commands{Store: otastore.Store{}, Root: root}.Handlers()}
}

func l3Execute(t *testing.T, bus operator.Bus, command operator.Command) operator.Outcome {
	t.Helper()
	outcome, err := bus.Execute(context.Background(), command)
	if err != nil {
		t.Fatalf("%s: %v", command.ModuleCommand, err)
	}
	return outcome
}

func l3State(t *testing.T, pool *pg.Pool, version string) string {
	t.Helper()
	var state string
	if err := pool.QueryRow(context.Background(), `SELECT state FROM ota_releases WHERE version=$1`, version).Scan(&state); err != nil {
		t.Fatal(err)
	}
	return state
}

func l3PlanVersions(t *testing.T, pool *pg.Pool) []string {
	t.Helper()
	service := appota.Service{Runner: tx.Runner{DB: pool}, Store: otastore.Store{}, Operations: operation.Factory{Clock: clock.System{}}, PublicEngineURL: "https://engine.example"}
	plan, err := service.Plan(context.Background(), otarelease.PlanRequest{ClientVersion: "1.631.0", AppVersion: otarelease.StockAppVersion, Platform: 3})
	if err != nil {
		t.Fatal(err)
	}
	versions := make([]string, 0, len(plan.Descriptors))
	for _, descriptor := range plan.Descriptors {
		versions = append(versions, descriptor.Version)
	}
	return versions
}

func l3Revision(t *testing.T, pool *pg.Pool) int64 {
	t.Helper()
	var revision int64
	if err := pool.QueryRow(context.Background(), `SELECT COALESCE(max(id),0) FROM ota_activations`).Scan(&revision); err != nil {
		t.Fatal(err)
	}
	return revision
}

func l3Contains(versions []string, wanted string) bool {
	for _, version := range versions {
		if version == wanted {
			return true
		}
	}
	return false
}

func TestOTACommandLifecycleThroughRealStore(t *testing.T) {
	pool := l3Pool(t)
	versions := []string{"9.300.1", "9.300.2"}
	resetL3Releases(t, pool, versions)
	first := l3BuildRequest(t, "9.300.1", "code")
	second := l3BuildRequest(t, "9.300.2", "code")
	bus := l3Bus(pool, l3Root(t, first, second))

	if outcome := l3Execute(t, bus, l3Command(t, "ota.register_build", nil, first)); outcome.State != operator.StateApplied {
		t.Fatalf("register first: %s %s", outcome.State, outcome.Result)
	}
	if outcome := l3Execute(t, bus, l3Command(t, "ota.register_build", nil, second)); outcome.State != operator.StateApplied {
		t.Fatalf("register second: %s %s", outcome.State, outcome.Result)
	}
	if state := l3State(t, pool, "9.300.1"); state != "BUILT" || l3State(t, pool, "9.300.2") != "BUILT" {
		t.Fatalf("registered states: %s", state)
	}
	if plan := l3PlanVersions(t, pool); l3Contains(plan, "9.300.1") || l3Contains(plan, "9.300.2") {
		t.Fatalf("plan before publish = %v", plan)
	}

	revision := l3Revision(t, pool)
	published := l3Execute(t, bus, l3Command(t, "ota.publish", &revision, map[string]string{"version": "9.300.1"}))
	if published.State != operator.StateApplied {
		t.Fatalf("publish first: %s %s", published.State, published.Result)
	}
	if state := l3State(t, pool, "9.300.1"); state != "ACTIVE" {
		t.Fatalf("first state=%s", state)
	}
	if plan := l3PlanVersions(t, pool); !l3Contains(plan, "9.300.1") {
		t.Fatalf("plan after first publish = %v", plan)
	}

	revision = l3Revision(t, pool)
	published = l3Execute(t, bus, l3Command(t, "ota.publish", &revision, map[string]string{"version": "9.300.2"}))
	if published.State != operator.StateApplied {
		t.Fatalf("publish second: %s %s", published.State, published.Result)
	}
	var result appota.Activation
	if err := json.Unmarshal(published.Result, &result); err != nil || len(result.Superseded) != 1 || result.Superseded[0] != "9.300.1" {
		t.Fatalf("second publish result=%s err=%v", published.Result, err)
	}
	if l3State(t, pool, "9.300.1") != "SUPERSEDED" || l3State(t, pool, "9.300.2") != "ACTIVE" {
		t.Fatalf("states after second publish: %s/%s", l3State(t, pool, "9.300.1"), l3State(t, pool, "9.300.2"))
	}
	if plan := l3PlanVersions(t, pool); !l3Contains(plan, "9.300.2") || l3Contains(plan, "9.300.1") {
		t.Fatalf("plan after second publish = %v", plan)
	}

	revision = l3Revision(t, pool)
	withdrawn := l3Execute(t, bus, l3Command(t, "ota.withdraw", &revision, map[string]string{"version": "9.300.2"}))
	if withdrawn.State != operator.StateApplied || l3State(t, pool, "9.300.2") != "WITHDRAWN" {
		t.Fatalf("withdraw: %s %s state=%s", withdrawn.State, withdrawn.Result, l3State(t, pool, "9.300.2"))
	}
	if l3State(t, pool, "9.300.1") != "SUPERSEDED" {
		t.Fatalf("withdraw reactivated the superseded release: %s", l3State(t, pool, "9.300.1"))
	}
	if plan := l3PlanVersions(t, pool); l3Contains(plan, "9.300.1") || l3Contains(plan, "9.300.2") {
		t.Fatalf("plan after withdraw = %v", plan)
	}

	var activations int
	var actions []string
	if err := pool.QueryRow(context.Background(), `SELECT count(*) FROM ota_activations WHERE version = ANY($1)`, versions).Scan(&activations); err != nil {
		t.Fatal(err)
	}
	rows, err := pool.Raw().Query(context.Background(), `SELECT action FROM ota_activations WHERE version = ANY($1) ORDER BY id`, versions)
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	for rows.Next() {
		var action string
		if err := rows.Scan(&action); err != nil {
			t.Fatal(err)
		}
		actions = append(actions, action)
	}
	if activations != 3 || len(actions) != 3 || actions[0] != "PUBLISH" || actions[1] != "PUBLISH" || actions[2] != "WITHDRAW" {
		t.Fatalf("activations=%d actions=%v", activations, actions)
	}

	refused := l3Execute(t, bus, l3Command(t, "ota.register_build", nil, second))
	var refusal operator.Refusal
	if refused.State != operator.StateRefused || json.Unmarshal(refused.Result, &refusal) != nil || refusal.Code != appota.CodeVersionExists {
		t.Fatalf("equal number: %s %s", refused.State, refused.Result)
	}
}

func TestPublishNeedsTheGlobalRevisionAcrossACatalogPublish(t *testing.T) {
	pool := l3Pool(t)
	versions := []string{"9.320.1", "9.320.2", "9.320.3"}
	resetL3Releases(t, pool, versions)
	first := l3BuildRequest(t, "9.320.1", "code")
	catalog := l3BuildRequest(t, "9.320.2", "catalog")
	second := l3BuildRequest(t, "9.320.3", "code")
	bus := l3Bus(pool, l3Root(t, first, catalog, second))
	for _, request := range []otarelease.BuildRequest{first, catalog, second} {
		if outcome := l3Execute(t, bus, l3Command(t, "ota.register_build", nil, request)); outcome.State != operator.StateApplied {
			t.Fatalf("register %s: %s %s", request.Version, outcome.State, outcome.Result)
		}
	}
	revision := l3Revision(t, pool)
	if outcome := l3Execute(t, bus, l3Command(t, "ota.publish", &revision, map[string]string{"version": "9.320.1"})); outcome.State != operator.StateApplied {
		t.Fatalf("publish code: %s %s", outcome.State, outcome.Result)
	}
	stale := l3Revision(t, pool)
	revision = stale
	if outcome := l3Execute(t, bus, l3Command(t, "ota.publish", &revision, map[string]string{"version": "9.320.2"})); outcome.State != operator.StateApplied {
		t.Fatalf("publish catalog: %s %s", outcome.State, outcome.Result)
	}
	current := l3Revision(t, pool)
	if current == stale {
		t.Fatal("the catalog publish did not advance the active revision")
	}
	refused := l3Execute(t, bus, l3Command(t, "ota.publish", &stale, map[string]string{"version": "9.320.3"}))
	if refused.State != operator.StateRefused {
		t.Fatalf("stale publish: %s %s", refused.State, refused.Result)
	}
	var refusal struct {
		Code   string `json:"error_code"`
		Detail struct {
			CurrentRevision int64 `json:"current_revision"`
		} `json:"detail"`
	}
	if err := json.Unmarshal(refused.Result, &refusal); err != nil || refusal.Code != operator.CodeRevisionStale || refusal.Detail.CurrentRevision != current {
		t.Fatalf("refusal=%s err=%v want current=%d", refused.Result, err, current)
	}
	if state := l3State(t, pool, "9.320.3"); state != "BUILT" {
		t.Fatalf("stale publish changed state: %s", state)
	}
}

func TestConcurrentRegisterOfOneVersionRefusesTheLoser(t *testing.T) {
	pool := l3Pool(t)
	const version = "9.330.1"
	resetL3Releases(t, pool, []string{version})
	request := l3BuildRequest(t, version, "code")
	bus := l3Bus(pool, l3Root(t, request))
	commands := []operator.Command{
		l3Command(t, "ota.register_build", nil, request),
		l3Command(t, "ota.register_build", nil, request),
	}
	type attempt struct {
		outcome operator.Outcome
		err     error
	}
	results := make(chan attempt, len(commands))
	start := make(chan struct{})
	for _, command := range commands {
		go func(command operator.Command) {
			<-start
			outcome, err := bus.Execute(context.Background(), command)
			results <- attempt{outcome: outcome, err: err}
		}(command)
	}
	close(start)
	applied, refused := 0, 0
	for range commands {
		result := <-results
		if result.err != nil {
			t.Fatalf("concurrent register returned an error instead of a refusal: %v", result.err)
		}
		switch result.outcome.State {
		case operator.StateApplied:
			applied++
		case operator.StateRefused:
			var refusal operator.Refusal
			if err := json.Unmarshal(result.outcome.Result, &refusal); err != nil || refusal.Code != appota.CodeVersionExists {
				t.Fatalf("refusal=%s err=%v", result.outcome.Result, err)
			}
			refused++
		default:
			t.Fatalf("unexpected state %q result=%s", result.outcome.State, result.outcome.Result)
		}
	}
	if applied != 1 || refused != 1 {
		t.Fatalf("applied=%d refused=%d", applied, refused)
	}
	var count int
	if err := pool.QueryRow(context.Background(), `SELECT count(*) FROM ota_releases WHERE version=$1`, version).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Fatalf("release rows=%d", count)
	}
}

func resetL3Releases(t *testing.T, pool *pg.Pool, versions []string) {
	t.Helper()
	remove := func() {
		ctx := context.Background()
		if _, err := pool.Raw().Exec(ctx, `DELETE FROM ota_activations WHERE version = ANY($1)`, versions); err != nil {
			t.Fatal(err)
		}
		if _, err := pool.Raw().Exec(ctx, `DELETE FROM ota_releases WHERE version = ANY($1)`, versions); err != nil {
			t.Fatal(err)
		}
	}
	remove()
	t.Cleanup(remove)
}
