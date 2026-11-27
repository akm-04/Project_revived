package otarelease

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func mustJSON(t *testing.T, value any) json.RawMessage {
	t.Helper()
	encoded, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	return encoded
}

func commandScope(at time.Time) tx.Scope {
	return tx.Scope{Tx: fakeTx{}, Operation: operation.Context{StartedAt: at}}
}

func runCommand(t *testing.T, commands Commands, at time.Time, key string, revision *int64, name string, payload json.RawMessage) (any, error) {
	t.Helper()
	command := operator.Command{Envelope: operator.Envelope{SemanticKey: key, ExpectedRevision: revision}, Payload: payload}
	handler := commands.Handlers()[name]
	return handler(context.Background(), commandScope(at), command)
}

func TestWithdrawThroughTheReleaseFile(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	request := buildPayload(t, "1.631.2", "code", 2000)
	root := rootWithVolumes(t, request)
	store := NewStateFile(root)
	commands := Commands{Store: store, Root: root}
	if _, err := runCommand(t, commands, at, "build-key", nil, "ota.register_build", mustJSON(t, request)); err != nil {
		t.Fatal(err)
	}
	revision := int64(0)
	if _, err := runCommand(t, commands, at, "publish-key", &revision, "ota.publish", json.RawMessage(`{"version":"1.631.2"}`)); err != nil {
		t.Fatal(err)
	}
	revision = 1
	result, err := runCommand(t, commands, at, "withdraw-key", &revision, "ota.withdraw", json.RawMessage(`{"version":"1.631.2"}`))
	if err != nil {
		t.Fatal(err)
	}
	activation, ok := result.(Activation)
	if !ok || activation.Action != "WITHDRAW" || activation.ActivationID != 2 || activation.State != string(domain.StateWithdrawn) {
		t.Fatalf("withdraw reply = %#v", result)
	}
	document, err := store.Load()
	if err != nil {
		t.Fatal(err)
	}
	if document.Releases[0].State != string(domain.StateWithdrawn) || document.Releases[0].WithdrawnAt == nil {
		t.Fatalf("release row = %+v", document.Releases[0])
	}
	if len(document.Activations) != 2 || document.Activations[1].Action != "WITHDRAW" || document.Activations[1].ID != 2 {
		t.Fatalf("activations = %+v", document.Activations)
	}
	if revision, err := store.ActiveRevisionTx(context.Background(), nil); err != nil || revision != 2 {
		t.Fatalf("revision = %d err=%v", revision, err)
	}
	if len(document.Applied) != 3 {
		t.Fatalf("applied replies = %+v", document.Applied)
	}
}

func TestSupersedeLiveActiveThroughTheReleaseFile(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	first := buildPayload(t, "1.631.5", "code", 2000)
	second := buildPayload(t, "1.631.6", "code", 2000)
	root := rootWithVolumes(t, first, second)
	store := NewStateFile(root)
	commands := Commands{Store: store, Root: root}
	for _, request := range []domain.BuildRequest{first, second} {
		if _, err := runCommand(t, commands, at, "build-"+request.Version, nil, "ota.register_build", mustJSON(t, request)); err != nil {
			t.Fatal(err)
		}
	}
	revision := int64(0)
	if _, err := runCommand(t, commands, at, "publish-1", &revision, "ota.publish", json.RawMessage(`{"version":"1.631.5"}`)); err != nil {
		t.Fatal(err)
	}
	revision = 1
	result, err := runCommand(t, commands, at, "publish-2", &revision, "ota.publish", json.RawMessage(`{"version":"1.631.6"}`))
	if err != nil {
		t.Fatal(err)
	}
	activation, ok := result.(Activation)
	if !ok || len(activation.Superseded) != 1 || activation.Superseded[0] != "1.631.5" {
		t.Fatalf("publish reply = %#v", result)
	}
	document, err := store.Load()
	if err != nil {
		t.Fatal(err)
	}
	states := map[string]StoredRelease{}
	for _, release := range document.Releases {
		states[release.Version] = release
	}
	if states["1.631.5"].State != string(domain.StateSuperseded) || states["1.631.5"].SupersededAt == nil {
		t.Fatalf("superseded row = %+v", states["1.631.5"])
	}
	if states["1.631.6"].State != string(domain.StateActive) || states["1.631.6"].PublishedAt == nil {
		t.Fatalf("active row = %+v", states["1.631.6"])
	}
}

func TestSupersedeLaneReturnsVersionsInNumericOrder(t *testing.T) {
	store := NewStateFile(t.TempDir())
	at := time.Unix(1000, 0).UTC()
	for _, version := range []string{"1.631.10", "1.631.6"} {
		if err := store.InsertBuildTx(context.Background(), nil, stateRelease(version, domain.LaneCode), "build-"+version, at); err != nil {
			t.Fatal(err)
		}
		if err := store.ActivateTx(context.Background(), nil, version, "publish-"+version, at); err != nil {
			t.Fatal(err)
		}
	}
	versions, err := store.SupersedeLaneTx(context.Background(), nil, domain.LaneCode, at.Add(time.Second))
	if err != nil {
		t.Fatal(err)
	}
	if fmt.Sprint(versions) != "[1.631.6 1.631.10]" {
		t.Fatalf("superseded = %v", versions)
	}
}

func TestConcurrentRegisterBuildRefusesTheLoser(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	request := buildPayload(t, "1.631.2", "code", 2000)
	root := rootWithVolumes(t, request)
	store := NewStateFile(root)
	commands := Commands{Store: store, Root: root}
	payload := mustJSON(t, request)
	errorsByWorker := make([]error, 2)
	var wait sync.WaitGroup
	for worker := 0; worker < 2; worker++ {
		wait.Add(1)
		go func(worker int) {
			defer wait.Done()
			command := operator.Command{Envelope: operator.Envelope{SemanticKey: fmt.Sprintf("build-%d", worker)}, Payload: payload}
			_, errorsByWorker[worker] = commands.registerBuildHandler(context.Background(), commandScope(at), command)
		}(worker)
	}
	wait.Wait()
	succeeded := 0
	refused := 0
	for _, err := range errorsByWorker {
		switch {
		case err == nil:
			succeeded++
		case refusalCode(t, err) == CodeVersionExists:
			refused++
		default:
			t.Fatalf("unexpected error: %v", err)
		}
	}
	if succeeded != 1 || refused != 1 {
		t.Fatalf("succeeded=%d refused=%d errors=%v", succeeded, refused, errorsByWorker)
	}
	document, err := store.Load()
	if err != nil || len(document.Releases) != 1 {
		t.Fatalf("releases = %+v err=%v", document.Releases, err)
	}
}

func TestActiveReadsFailClosedAboveTheBound(t *testing.T) {
	store := NewStateFile(t.TempDir())
	document, err := store.Load()
	if err != nil {
		t.Fatal(err)
	}
	for index := 1; index <= maxActiveStateReleases; index++ {
		document.Releases = append(document.Releases, StoredRelease{RawRelease: domain.RawRelease{
			ID: int64(index), Version: fmt.Sprintf("1.640.%d", index), Lane: string(domain.LaneCatalog), State: string(domain.StateActive),
		}})
	}
	if err := store.Save(document); err != nil {
		t.Fatal(err)
	}
	for _, read := range []func(context.Context, tx.Queryer) ([]domain.RawRelease, error){store.ListActiveTx, store.ListActiveDescriptorsTx} {
		rows, err := read(context.Background(), nil)
		if err != nil || len(rows) != maxActiveStateReleases {
			t.Fatalf("16 ACTIVE rows = %d err=%v", len(rows), err)
		}
	}
	document.Releases = append(document.Releases, StoredRelease{RawRelease: domain.RawRelease{
		ID: 17, Version: "1.640.17", Lane: string(domain.LaneCatalog), State: string(domain.StateActive),
	}})
	if err := store.Save(document); err != nil {
		t.Fatal(err)
	}
	for _, read := range []func(context.Context, tx.Queryer) ([]domain.RawRelease, error){store.ListActiveTx, store.ListActiveDescriptorsTx} {
		if _, err := read(context.Background(), nil); !errors.Is(err, errInvalidState) {
			t.Fatalf("17 ACTIVE rows err=%v, want invalid state", err)
		}
	}
}

func TestReleaseReadsCoverWithdrawnAndSupersededRows(t *testing.T) {
	store := NewStateFile(t.TempDir())
	at := time.Unix(1000, 0).UTC()
	withdrawn := StoredRelease{RawRelease: domain.RawRelease{ID: 1, Version: "1.631.2", Lane: string(domain.LaneCode), State: string(domain.StateWithdrawn)}, WithdrawnAt: &at}
	superseded := StoredRelease{RawRelease: domain.RawRelease{ID: 2, Version: "1.631.3", Lane: string(domain.LaneCode), State: string(domain.StateSuperseded)}, SupersededAt: &at}
	replaced := StoredRelease{RawRelease: domain.RawRelease{ID: 3, Version: "1.631.4", Lane: string(domain.LaneCode), State: string(domain.StateReplaced)}}
	if err := store.Save(StateDocument{Releases: []StoredRelease{withdrawn, superseded, replaced}}); err != nil {
		t.Fatal(err)
	}
	for _, testCase := range []struct {
		version string
		lane    string
		state   string
	}{{"1.631.2", string(domain.LaneCode), string(domain.StateWithdrawn)}, {"1.631.3", string(domain.LaneCode), string(domain.StateSuperseded)}} {
		exists, lane, state, err := store.ReleaseStatusTx(context.Background(), nil, testCase.version)
		if err != nil || !exists || lane != testCase.lane || state != testCase.state {
			t.Fatalf("%s status = %v %q %q err=%v", testCase.version, exists, lane, state, err)
		}
		row, err := store.ReleaseTx(context.Background(), nil, testCase.version)
		if err != nil || row == nil || row.Version != testCase.version {
			t.Fatalf("%s row = %+v err=%v", testCase.version, row, err)
		}
	}
	if exists, _, _, err := store.ReleaseStatusTx(context.Background(), nil, "1.631.4"); err != nil || exists {
		t.Fatalf("REPLACED row reported: %v %v", exists, err)
	}
	if row, err := store.ReleaseTx(context.Background(), nil, "1.631.4"); err != nil || row != nil {
		t.Fatalf("REPLACED row read = %+v err=%v", row, err)
	}
}

func TestNumericOrderingThroughTheReleaseFile(t *testing.T) {
	store := NewStateFile(t.TempDir())
	document := StateDocument{}
	for _, row := range []struct {
		id                   int64
		version, lane, state string
	}{
		{1, "1.632.9", string(domain.LaneCatalog), string(domain.StateActive)},
		{2, "1.632.10", string(domain.LaneCatalog), string(domain.StateActive)},
		{3, "1.631.9", string(domain.LaneCode), string(domain.StateBuilt)},
		{4, "1.631.10", string(domain.LaneAssets), string(domain.StateBuilt)},
	} {
		document.Releases = append(document.Releases, StoredRelease{RawRelease: domain.RawRelease{
			ID: row.id, Version: row.version, Lane: row.lane, State: row.state,
		}})
	}
	if err := store.Save(document); err != nil {
		t.Fatal(err)
	}
	rows, err := store.ListActiveTx(context.Background(), nil)
	if err != nil || fmt.Sprint(versionTexts(rows)) != "[1.632.9 1.632.10]" {
		t.Fatalf("active order = %v err=%v", versionTexts(rows), err)
	}
	descriptors, err := store.ListActiveDescriptorsTx(context.Background(), nil)
	if err != nil || fmt.Sprint(versionTexts(descriptors)) != "[1.632.9 1.632.10]" {
		t.Fatalf("descriptor order = %v err=%v", versionTexts(descriptors), err)
	}
	snapshot, err := store.ReadStatusTx(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(snapshot.Built) != 2 || snapshot.Built[0].Version != "1.631.9" || snapshot.Built[1].Version != "1.631.10" {
		t.Fatalf("built order = %+v", snapshot.Built)
	}
	status, err := foldStatus(snapshot)
	if err != nil {
		t.Fatal(err)
	}
	if status.NextVersion != "1.632.11" {
		t.Fatalf("next version = %q", status.NextVersion)
	}
	if len(snapshot.Versions) == 0 || snapshot.Versions[0] != "1.632.10" {
		t.Fatalf("versions = %v", snapshot.Versions)
	}
}

func versionTexts(rows []domain.RawRelease) []string {
	versions := make([]string, 0, len(rows))
	for _, row := range rows {
		versions = append(versions, row.Version)
	}
	return versions
}

func TestRollbackReuseKeepsTheReplacedRowAndItsLink(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	oldest := buildPayload(t, "1.631.4", "code", 2000)
	newest := buildPayload(t, "1.631.5", "code", 2000)
	root := rootWithVolumes(t, oldest, newest)
	store := NewStateFile(root)
	commands := Commands{Store: store, Root: root}
	if _, err := runCommand(t, commands, at, "build-oldest", nil, "ota.register_build", mustJSON(t, oldest)); err != nil {
		t.Fatal(err)
	}
	revision := int64(0)
	if _, err := runCommand(t, commands, at, "publish-oldest", &revision, "ota.publish", json.RawMessage(`{"version":"1.631.4"}`)); err != nil {
		t.Fatal(err)
	}
	if _, err := runCommand(t, commands, at, "build-newest", nil, "ota.register_build", mustJSON(t, newest)); err != nil {
		t.Fatal(err)
	}
	revision = 1
	if _, err := runCommand(t, commands, at, "publish-newest", &revision, "ota.publish", json.RawMessage(`{"version":"1.631.5"}`)); err != nil {
		t.Fatal(err)
	}
	reuse := oldest
	reuse.Rollback = true
	if _, err := runCommand(t, commands, at, "reuse-oldest", nil, "ota.register_build", mustJSON(t, reuse)); err != nil {
		t.Fatal(err)
	}
	document, err := store.Load()
	if err != nil {
		t.Fatal(err)
	}
	var replaced, rebuilt []StoredRelease
	for _, release := range document.Releases {
		if release.Version != "1.631.4" {
			continue
		}
		if release.State == string(domain.StateReplaced) {
			replaced = append(replaced, release)
		} else {
			rebuilt = append(rebuilt, release)
		}
	}
	if len(replaced) != 1 || len(rebuilt) != 1 {
		t.Fatalf("1.631.4 artifacts = %+v", document.Releases)
	}
	if replaced[0].ReplacedAt == nil || replaced[0].ReplacedBy == nil || *replaced[0].ReplacedBy != rebuilt[0].ID {
		t.Fatalf("replaced link = %+v -> %+v", replaced[0], rebuilt[0])
	}
	row, err := store.ReleaseTx(context.Background(), nil, "1.631.4")
	if err != nil || row == nil || row.State != string(domain.StateBuilt) || row.ID != rebuilt[0].ID {
		t.Fatalf("live 1.631.4 = %+v err=%v", row, err)
	}
}

func TestPublishRefusesResultsBelowTheAssetBootstrap(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	assets := buildPayload(t, "1.631.1", "assets", 2000)
	code := buildPayload(t, "1.631.6", "code", 2000)
	rollback := buildPayload(t, "1.631.4", "code", 2000)
	rollback.Rollback = true
	newerAssets := buildPayload(t, "1.631.5", "assets", 2000)
	aboveCode := buildPayload(t, "1.631.7", "assets", 2000)
	root := rootWithVolumes(t, assets, code, rollback, newerAssets, aboveCode)
	store := NewStateFile(root)
	commands := Commands{Store: store, Root: root}
	register := func(request domain.BuildRequest, key string) {
		t.Helper()
		if _, err := runCommand(t, commands, at, key, nil, "ota.register_build", mustJSON(t, request)); err != nil {
			t.Fatal(err)
		}
	}
	publish := func(request domain.BuildRequest, key string, revision int64) error {
		t.Helper()
		_, err := runCommand(t, commands, at, key, &revision, "ota.publish", mustJSON(t, map[string]string{"version": request.Version}))
		return err
	}
	register(assets, "assets-build")
	if err := publish(assets, "assets-publish", 0); err != nil {
		t.Fatal(err)
	}
	register(code, "code-build")
	if err := publish(code, "code-publish", 1); err != nil {
		t.Fatal(err)
	}
	register(rollback, "rollback-build")
	register(newerAssets, "newer-assets-build")
	register(aboveCode, "above-code-build")
	if err := publish(newerAssets, "newer-assets-publish", 2); err != nil {
		t.Fatal(err)
	}
	if err := publish(rollback, "rollback-publish", 3); refusalCode(t, err) != CodeRollbackBelowAssets {
		t.Fatalf("delayed rollback publish err=%v", err)
	}
	if err := publish(aboveCode, "above-code-publish", 3); refusalCode(t, err) != CodeRollbackBelowAssets {
		t.Fatalf("assets publish above the active code err=%v", err)
	}
	document, err := store.Load()
	if err != nil {
		t.Fatal(err)
	}
	states := map[string]StoredRelease{}
	for _, release := range document.Releases {
		states[release.Version] = release
	}
	if states["1.631.4"].State != string(domain.StateBuilt) || states["1.631.7"].State != string(domain.StateBuilt) {
		t.Fatalf("refused publications changed the state: %+v", states)
	}
	if states["1.631.5"].State != string(domain.StateActive) || states["1.631.6"].State != string(domain.StateActive) {
		t.Fatalf("active set = %+v", states)
	}
	if revision, err := store.ActiveRevisionTx(context.Background(), nil); err != nil || revision != 3 {
		t.Fatalf("revision = %d err=%v", revision, err)
	}
	rows := make([]domain.RawRelease, 0, len(document.Releases))
	for _, release := range document.Releases {
		rows = append(rows, release.RawRelease)
	}
	plan, err := domain.PlanUpdate(domain.PlanRequest{ClientVersion: domain.StockAppVersion, AppVersion: domain.StockAppVersion}, "https://example.invalid", rows)
	if err != nil {
		t.Fatal(err)
	}
	versions := make([]string, 0, len(plan.Descriptors))
	for _, descriptor := range plan.Descriptors {
		versions = append(versions, descriptor.Version)
	}
	if fmt.Sprint(versions) != "[1.631.5 1.631.6]" {
		t.Fatalf("cleared-client plan = %v", versions)
	}
}

func TestPublishNeedsTheGlobalRevisionThroughTheFile(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	catalog := buildPayload(t, "1.640.1", "catalog", 2000)
	code := buildPayload(t, "1.640.2", "code", 2000)
	root := rootWithVolumes(t, catalog, code)
	store := NewStateFile(root)
	commands := Commands{Store: store, Root: root}
	for _, request := range []domain.BuildRequest{catalog, code} {
		if _, err := runCommand(t, commands, at, "build-"+request.Version, nil, "ota.register_build", mustJSON(t, request)); err != nil {
			t.Fatal(err)
		}
	}
	revision := int64(0)
	if _, err := runCommand(t, commands, at, "publish-code", &revision, "ota.publish", json.RawMessage(`{"version":"1.640.2"}`)); err != nil {
		t.Fatal(err)
	}
	_, err := runCommand(t, commands, at, "publish-catalog-stale", &revision, "ota.publish", json.RawMessage(`{"version":"1.640.1"}`))
	var refusal *operator.Refusal
	if !errors.As(err, &refusal) || refusal.Code != operator.CodeRevisionStale {
		t.Fatalf("stale publish err=%v", err)
	}
	revision = 1
	if _, err := runCommand(t, commands, at, "publish-catalog", &revision, "ota.publish", json.RawMessage(`{"version":"1.640.1"}`)); err != nil {
		t.Fatal(err)
	}
	if revision, err := store.ActiveRevisionTx(context.Background(), nil); err != nil || revision != 2 {
		t.Fatalf("revision = %d err=%v", revision, err)
	}
}

func TestMID2SchedulerThroughTheReleaseFile(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	assets := buildPayload(t, "1.631.1", "assets", 2000)
	assets.Manifest = mustJSON(t, map[string]any{"files": []domain.ManifestEntry{{Path: "src_64/assets/a.lua", Size: 1, MD5: commandMD5}}})
	code := buildPayload(t, "1.631.5", "code", 2000)
	code.Manifest = mustJSON(t, map[string]any{"files": []domain.ManifestEntry{{Path: "src_64/code/b.lua", Size: 1, MD5: commandMD5}}})
	catalog := buildPayload(t, "1.631.7", "catalog", 2000)
	catalog.Manifest = mustJSON(t, map[string]any{"files": []domain.ManifestEntry{{Path: "src_64/catalog/c.lua", Size: 1, MD5: commandMD5}}})
	root := rootWithVolumes(t, assets, code, catalog)
	store := NewStateFile(root)
	commands := Commands{Store: store, Root: root}
	for _, request := range []domain.BuildRequest{assets, code, catalog} {
		if _, err := runCommand(t, commands, at, "build-"+request.Version, nil, "ota.register_build", mustJSON(t, request)); err != nil {
			t.Fatal(err)
		}
	}
	for index, request := range []domain.BuildRequest{assets, code, catalog} {
		revision := int64(index)
		if _, err := runCommand(t, commands, at, "publish-"+request.Version, &revision, "ota.publish", mustJSON(t, map[string]string{"version": request.Version})); err != nil {
			t.Fatal(err)
		}
	}
	service := Service{Store: store, PublicEngineURL: "https://engine.example"}
	plan, err := service.Plan(context.Background(), domain.PlanRequest{ClientVersion: "1.631.0", AppVersion: domain.StockAppVersion})
	if err != nil {
		t.Fatal(err)
	}
	if len(plan.Descriptors) != 3 {
		t.Fatalf("descriptors = %+v", plan.Descriptors)
	}
	wantOrder := []string{"1.631.1", "1.631.5", "1.631.7"}
	for index, descriptor := range plan.Descriptors {
		if descriptor.Version != wantOrder[index] {
			t.Fatalf("descriptor order = %+v", plan.Descriptors)
		}
	}
	if plan.Descriptors[0].Resource != "https://engine.example/updates/assets/1.631.1-"+commandSHA[:12]+".zip" {
		t.Fatalf("resource URL = %q", plan.Descriptors[0].Resource)
	}
	upToDate, err := service.Plan(context.Background(), domain.PlanRequest{ClientVersion: "1.631.7", AppVersion: domain.StockAppVersion})
	if err != nil || len(upToDate.Descriptors) != 0 {
		t.Fatalf("up-to-date plan = %+v err=%v", upToDate, err)
	}
	unknown, err := service.Plan(context.Background(), domain.PlanRequest{ClientVersion: "1.631.0", AppVersion: "9.9.9"})
	if err != nil || !unknown.UnknownAppVersion || len(unknown.Descriptors) != 0 {
		t.Fatalf("unknown app_v plan = %+v err=%v", unknown, err)
	}
	active, err := service.ActiveRelease(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if active.AssetVersion == nil || active.AssetVersion.String() != "1.631.1" || active.CodeVersion == nil || active.CodeVersion.String() != "1.631.5" || active.CatalogVersion == nil || active.CatalogVersion.String() != "1.631.7" {
		t.Fatalf("active release = %+v", active)
	}
	if fmt.Sprint(active.ClientPaths) != "[src_64/assets/a.lua src_64/catalog/c.lua src_64/code/b.lua]" {
		t.Fatalf("client paths = %v", active.ClientPaths)
	}
}
