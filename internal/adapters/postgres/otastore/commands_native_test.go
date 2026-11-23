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

// l3RefusalCode asserts a refused outcome and returns its stable code.
func l3RefusalCode(t *testing.T, outcome operator.Outcome) string {
	t.Helper()
	if outcome.State != operator.StateRefused {
		t.Fatalf("outcome = %s %s, want a refusal", outcome.State, outcome.Result)
	}
	var refusal operator.Refusal
	if err := json.Unmarshal(outcome.Result, &refusal); err != nil {
		t.Fatal(err)
	}
	return refusal.Code
}

// TestRegisterBuildKeepsTheLaneLineThroughTheRealStore proves G23 on the direct
// backend register path: the lane's line is the active release's major.minor,
// else the highest BUILT one, forward and rollback alike.
func TestRegisterBuildKeepsTheLaneLineThroughTheRealStore(t *testing.T) {
	pool := l3Pool(t)
	versions := []string{"9.340.0", "9.340.1", "9.340.2", "9.341.1", "9.339.9"}
	resetL3Releases(t, pool, versions)
	first := l3BuildRequest(t, "9.340.1", "code")
	sameLineForward := l3BuildRequest(t, "9.340.2", "code")
	crossLineForward := l3BuildRequest(t, "9.341.1", "code")
	crossLineRollback := l3BuildRequest(t, "9.339.9", "code")
	crossLineRollback.Rollback = true
	sameLineRollback := l3BuildRequest(t, "9.340.0", "code")
	sameLineRollback.Rollback = true
	bus := l3Bus(pool, l3Root(t, first, sameLineForward, crossLineForward, crossLineRollback, sameLineRollback))

	if outcome := l3Execute(t, bus, l3Command(t, "ota.register_build", nil, first)); outcome.State != operator.StateApplied {
		t.Fatalf("register first: %s %s", outcome.State, outcome.Result)
	}
	if code := l3RefusalCode(t, l3Execute(t, bus, l3Command(t, "ota.register_build", nil, crossLineForward))); code != appota.CodeBuildVersionNotNext {
		t.Fatalf("cross-line forward without an active release: %s", code)
	}
	if outcome := l3Execute(t, bus, l3Command(t, "ota.register_build", nil, sameLineForward)); outcome.State != operator.StateApplied {
		t.Fatalf("same-line forward: %s %s", outcome.State, outcome.Result)
	}
	revision := l3Revision(t, pool)
	if outcome := l3Execute(t, bus, l3Command(t, "ota.publish", &revision, map[string]string{"version": "9.340.1"})); outcome.State != operator.StateApplied {
		t.Fatalf("publish first: %s %s", outcome.State, outcome.Result)
	}
	if code := l3RefusalCode(t, l3Execute(t, bus, l3Command(t, "ota.register_build", nil, crossLineRollback))); code != appota.CodeBuildVersionNotNext {
		t.Fatalf("cross-line rollback beside the active release: %s", code)
	}
	rollback := l3Execute(t, bus, l3Command(t, "ota.register_build", nil, sameLineRollback))
	if rollback.State != operator.StateApplied {
		t.Fatalf("same-line rollback: %s %s", rollback.State, rollback.Result)
	}
	var result appota.BuildResult
	if err := json.Unmarshal(rollback.Result, &result); err != nil || !result.Rollback || result.Warning == "" {
		t.Fatalf("rollback result=%s err=%v", rollback.Result, err)
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

// TestReleaseExistsCoversEveryState proves the exact-version read (any state)
// that the agent's duplicate-number check uses (L4f fix 2).
func TestReleaseExistsCoversEveryState(t *testing.T) {
	pool := l3Pool(t)
	versions := []string{"9.302.1"}
	resetL3Releases(t, pool, versions)
	first := l3BuildRequest(t, "9.302.1", "code")
	bus := l3Bus(pool, l3Root(t, first))
	if outcome := l3Execute(t, bus, l3Command(t, "ota.register_build", nil, first)); outcome.State != operator.StateApplied {
		t.Fatalf("register: %s %s", outcome.State, outcome.Result)
	}
	revision := l3Revision(t, pool)
	if outcome := l3Execute(t, bus, l3Command(t, "ota.publish", &revision, map[string]string{"version": "9.302.1"})); outcome.State != operator.StateApplied {
		t.Fatalf("publish: %s %s", outcome.State, outcome.Result)
	}
	revision = l3Revision(t, pool)
	if outcome := l3Execute(t, bus, l3Command(t, "ota.withdraw", &revision, map[string]string{"version": "9.302.1"})); outcome.State != operator.StateApplied {
		t.Fatalf("withdraw: %s %s", outcome.State, outcome.Result)
	}
	lookup := appota.ReleaseLookup{Runner: tx.Runner{DB: pool}, Operations: operation.Factory{Clock: clock.System{}}, Store: otastore.Store{}}
	withdrawn, err := lookup.Exists(context.Background(), "9.302.1")
	if err != nil || !withdrawn.Exists || withdrawn.Lane != "code" || withdrawn.State != "WITHDRAWN" {
		t.Fatalf("a WITHDRAWN version was not reported with its lane and state: %+v err=%v", withdrawn, err)
	}
	unknown, err := lookup.Exists(context.Background(), "9.302.2")
	if err != nil || unknown.Exists {
		t.Fatalf("an unknown version was reported: %+v err=%v", unknown, err)
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

const (
	l3AltSHA = "abababababababababababababababababababababababababababababababab"
	l3AltMD5 = "acacacacacacacacacacacacacacacac"
)

func l3BuildRequestWithSHA(t *testing.T, version, lane, sha string) otarelease.BuildRequest {
	t.Helper()
	packageFiles, err := json.Marshal([]otarelease.PackageVolume{{Name: version + "-" + sha[:12] + ".zip.001", Size: 1000, MD5: l3MD5, SHA256: sha}})
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := json.Marshal(map[string]any{"files": []otarelease.ManifestEntry{{Path: "src_64/app/" + sha[:8] + ".lua", Size: 1, MD5: l3MD5}}})
	if err != nil {
		t.Fatal(err)
	}
	return otarelease.BuildRequest{Version: version, Lane: lane, PackageFiles: packageFiles, TotalSize: 1000, MD5: l3MD5, SHA256: sha, Manifest: manifest}
}

func l3RegisterAndPublish(t *testing.T, bus operator.Bus, pool *pg.Pool, request otarelease.BuildRequest) {
	t.Helper()
	if outcome := l3Execute(t, bus, l3Command(t, "ota.register_build", nil, request)); outcome.State != operator.StateApplied {
		t.Fatalf("register %s: %s %s", request.Version, outcome.State, outcome.Result)
	}
	revision := l3Revision(t, pool)
	if outcome := l3Execute(t, bus, l3Command(t, "ota.publish", &revision, map[string]string{"version": request.Version})); outcome.State != operator.StateApplied {
		t.Fatalf("publish %s: %s %s", request.Version, outcome.State, outcome.Result)
	}
}

// TestNumericOrderReadsOneSharedCounter proves G44 through the real store:
// 1.631.10 sorts above 1.631.9 in every release read, and next_version counts
// one counter across lanes.

// resetL3All clears every OTA row so a test's lane line and counter do not
// depend on another test file's leftovers.
func resetL3All(t *testing.T, pool *pg.Pool) {
	t.Helper()
	remove := func() {
		ctx := context.Background()
		if _, err := pool.Raw().Exec(ctx, `DELETE FROM ota_activations`); err != nil {
			t.Fatal(err)
		}
		if _, err := pool.Raw().Exec(ctx, `DELETE FROM ota_releases`); err != nil {
			t.Fatal(err)
		}
	}
	remove()
	t.Cleanup(remove)
}

func TestNumericOrderReadsOneSharedCounter(t *testing.T) {
	pool := l3Pool(t)
	resetL3All(t, pool)
	low := l3BuildRequestWithSHA(t, "1.631.9", "catalog", l3SHA)
	high := l3BuildRequestWithSHA(t, "1.631.10", "catalog", l3AltSHA)
	bus := l3Bus(pool, l3Root(t, low, high))
	l3RegisterAndPublish(t, bus, pool, low)
	l3RegisterAndPublish(t, bus, pool, high)

	snapshot, err := (otastore.Store{}).ReadStatusTx(context.Background(), pool)
	if err != nil {
		t.Fatal(err)
	}
	if len(snapshot.Active) != 2 || snapshot.Active[0].Version != "1.631.9" || snapshot.Active[1].Version != "1.631.10" {
		t.Fatalf("active order=%+v", snapshot.Active)
	}
	if len(snapshot.Versions) != 2 || snapshot.Versions[0] != "1.631.10" || snapshot.Versions[1] != "1.631.9" {
		t.Fatalf("versions order=%v", snapshot.Versions)
	}
	rows, err := (otastore.Store{}).ListActiveDescriptorsTx(context.Background(), pool)
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 2 || rows[0].Version != "1.631.9" || rows[1].Version != "1.631.10" {
		t.Fatalf("descriptor order=%+v", rows)
	}
	service := appota.StatusService{Runner: tx.Runner{DB: pool}, Operations: operation.Factory{Clock: clock.System{}}, Store: otastore.Store{}, Live: appota.NewSettingsValue(otarelease.DefaultSettings())}
	status, err := service.Status(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if status.NextVersion != "1.631.11" {
		t.Fatalf("next_version=%q", status.NextVersion)
	}
	if len(status.Active.Catalog) != 2 || status.Active.Catalog[0] != "1.631.9" || status.Active.Catalog[1] != "1.631.10" {
		t.Fatalf("catalog=%v", status.Active.Catalog)
	}
}

// TestRollbackReuseKeepsTheReplacedRowAndBothArtifacts proves OA-10 clauses 1-2
// and the scheduler order after a reuse (clause 3).
func TestRollbackReuseKeepsTheReplacedRowAndBothArtifacts(t *testing.T) {
	pool := l3Pool(t)
	resetL3All(t, pool)
	assets := l3BuildRequestWithSHA(t, "9.360.1", "assets", l3SHA)
	first := l3BuildRequestWithSHA(t, "9.360.2", "code", l3SHA)
	second := l3BuildRequestWithSHA(t, "9.360.3", "code", l3SHA)
	reuse := l3BuildRequestWithSHA(t, "9.360.2", "code", l3AltSHA)
	reuse.Rollback = true
	root := l3Root(t, assets, first, second, reuse)
	bus := l3Bus(pool, root)
	l3RegisterAndPublish(t, bus, pool, assets)
	l3RegisterAndPublish(t, bus, pool, first)
	l3RegisterAndPublish(t, bus, pool, second)
	if state := l3State(t, pool, "9.360.2"); state != "SUPERSEDED" {
		t.Fatalf("before reuse state=%s", state)
	}
	forward := reuse
	forward.Rollback = false
	refused := l3Execute(t, bus, l3Command(t, "ota.register_build", nil, forward))
	if code := l3RefusalCode(t, refused); code != appota.CodeVersionExists {
		t.Fatalf("forward reuse code=%s", code)
	}
	if outcome := l3Execute(t, bus, l3Command(t, "ota.register_build", nil, reuse)); outcome.State != operator.StateApplied {
		t.Fatalf("reuse: %s %s", outcome.State, outcome.Result)
	}

	rows, err := pool.Raw().Query(context.Background(), `SELECT id,state,replaced_by FROM ota_releases WHERE version=$1 ORDER BY id`, "9.360.2")
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	type releaseRow struct {
		id         int64
		state      string
		replacedBy *int64
	}
	var releaseRows []releaseRow
	for rows.Next() {
		var row releaseRow
		if err := rows.Scan(&row.id, &row.state, &row.replacedBy); err != nil {
			t.Fatal(err)
		}
		releaseRows = append(releaseRows, row)
	}
	if len(releaseRows) != 2 || releaseRows[0].state != "REPLACED" || releaseRows[0].replacedBy == nil || *releaseRows[0].replacedBy != releaseRows[1].id || releaseRows[1].state != "BUILT" {
		t.Fatalf("released rows=%+v", releaseRows)
	}
	lookup := appota.ReleaseLookup{Runner: tx.Runner{DB: pool}, Operations: operation.Factory{Clock: clock.System{}}, Store: otastore.Store{}}
	reused, err := lookup.Exists(context.Background(), "9.360.2")
	if err != nil || !reused.Exists || reused.Lane != "code" || reused.State != "BUILT" {
		t.Fatalf("the live row of a reused number was not reported: %+v err=%v", reused, err)
	}
	for _, volume := range []string{l3SHA[:12], l3AltSHA[:12]} {
		if _, err := os.Stat(filepath.Join(root, "updates", "code", "9.360.2-"+volume+".zip.001")); err != nil {
			t.Fatalf("artifact %s: %v", volume, err)
		}
	}

	revision := l3Revision(t, pool)
	if outcome := l3Execute(t, bus, l3Command(t, "ota.publish", &revision, map[string]string{"version": "9.360.2"})); outcome.State != operator.StateApplied {
		t.Fatalf("publish reuse: %s %s", outcome.State, outcome.Result)
	}
	if plan := l3PlanVersions(t, pool); len(plan) != 2 || plan[0] != "9.360.1" || plan[1] != "9.360.2" {
		t.Fatalf("plan after reuse=%v", plan)
	}
}

func TestReuseOfActiveOrBuiltNumberRefused(t *testing.T) {
	pool := l3Pool(t)
	resetL3All(t, pool)
	active := l3BuildRequestWithSHA(t, "9.361.2", "code", l3SHA)
	built := l3BuildRequestWithSHA(t, "9.361.3", "code", l3AltSHA)
	reuseActive := l3BuildRequestWithSHA(t, "9.361.2", "code", l3AltSHA)
	reuseActive.Rollback = true
	reuseBuilt := l3BuildRequestWithSHA(t, "9.361.3", "code", l3SHA)
	reuseBuilt.Rollback = true
	bus := l3Bus(pool, l3Root(t, active, built, reuseActive, reuseBuilt))
	l3RegisterAndPublish(t, bus, pool, active)
	if outcome := l3Execute(t, bus, l3Command(t, "ota.register_build", nil, built)); outcome.State != operator.StateApplied {
		t.Fatalf("register built: %s %s", outcome.State, outcome.Result)
	}
	for _, request := range []otarelease.BuildRequest{reuseActive, reuseBuilt} {
		if code := l3RefusalCode(t, l3Execute(t, bus, l3Command(t, "ota.register_build", nil, request))); code != appota.CodeVersionExists {
			t.Fatalf("reuse %s code=%s", request.Version, code)
		}
	}
}

func TestCodeRollbackBelowActiveAssetsRefused(t *testing.T) {
	pool := l3Pool(t)
	resetL3All(t, pool)
	assets := l3BuildRequestWithSHA(t, "9.362.4", "assets", l3SHA)
	code := l3BuildRequestWithSHA(t, "9.362.5", "code", l3SHA)
	rollback := l3BuildRequestWithSHA(t, "9.362.3", "code", l3AltSHA)
	rollback.Rollback = true
	bus := l3Bus(pool, l3Root(t, assets, code, rollback))
	l3RegisterAndPublish(t, bus, pool, assets)
	l3RegisterAndPublish(t, bus, pool, code)
	outcome := l3Execute(t, bus, l3Command(t, "ota.register_build", nil, rollback))
	if code := l3RefusalCode(t, outcome); code != appota.CodeRollbackBelowAssets {
		t.Fatalf("rollback below assets code=%s result=%s", code, outcome.Result)
	}
}
