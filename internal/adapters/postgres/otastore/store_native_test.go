//go:build postgres

package otastore_test

import (
	"context"
	"encoding/json"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/otastore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appota "gxb.local/backend/v2/internal/application/otarelease"
	ota "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
	"gxb.local/backend/v2/internal/protocol/wire"
)

const (
	assetVersion = "9.100.1"
	codeVersion  = "9.100.2"
	querySHA     = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
	queryMD5     = "dddddddddddddddddddddddddddddddd"
	engineURL    = "https://engine.example"
)

func nativePool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I11A_L1_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_L1_DSN required (ops/testing/fresh_db.sh i11a_l1_otarelease)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func insertCommand(t *testing.T, pool *pg.Pool, moduleCommand string, at time.Time) string {
	t.Helper()
	key, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	_, err = pool.Raw().Exec(context.Background(), `INSERT INTO operator_commands(
		semantic_key,module_command,payload_sha256,principal,role,scope,reason,state,result_json,created_at,finished_at)
		VALUES($1,$2,$3,'root','root','global','native test','APPLIED','{}'::jsonb,$4,$4)`,
		key.String(), moduleCommand, querySHA, at)
	if err != nil {
		t.Fatal(err)
	}
	return key.String()
}

func insertRelease(t *testing.T, pool *pg.Pool, version, lane string, size int64, builtBy string, at time.Time) {
	t.Helper()
	packageFiles, err := json.Marshal([]ota.PackageVolume{{
		Name: version + "-" + querySHA[:12] + ".zip.001", Size: size, MD5: queryMD5, SHA256: querySHA,
	}})
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := json.Marshal(map[string]any{"files": []ota.ManifestEntry{{Path: "src_64/app/a.lua", Size: 1, MD5: queryMD5}}})
	if err != nil {
		t.Fatal(err)
	}
	_, err = pool.Raw().Exec(context.Background(), `INSERT INTO ota_releases(
		version,lane,state,package_files,total_size,md5,sha256,manifest,built_by_command,built_at,published_by_command,published_at)
		VALUES($1,$2,'ACTIVE',$3::jsonb,$4,$5,$6,$7::jsonb,$8,$9,$8,$9)`,
		version, lane, string(packageFiles), size, queryMD5, querySHA, string(manifest), builtBy, at)
	if err != nil {
		t.Fatal(err)
	}
}

func seedActiveReleases(t *testing.T, pool *pg.Pool) {
	t.Helper()
	ctx := context.Background()
	versions := []string{assetVersion, codeVersion}
	if _, err := pool.Raw().Exec(ctx, `DELETE FROM ota_activations WHERE version = ANY($1)`, versions); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `DELETE FROM ota_releases WHERE version = ANY($1)`, versions); err != nil {
		t.Fatal(err)
	}
	at := time.Now().UTC().Truncate(time.Microsecond)
	assetCommand := insertCommand(t, pool, "ota.register_build", at)
	codeCommand := insertCommand(t, pool, "ota.register_build", at)
	insertRelease(t, pool, assetVersion, string(ota.LaneAssets), 1000, assetCommand, at)
	insertRelease(t, pool, codeVersion, string(ota.LaneCode), 2000, codeCommand, at)
}

func preloginFor(pool *pg.Pool) stockruntime.PreloginDispatcher {
	service := appota.Service{
		Runner:          tx.Runner{DB: pool},
		Store:           otastore.Store{},
		Operations:      operation.Factory{Clock: clock.System{}},
		PublicEngineURL: engineURL,
	}
	return stockruntime.PreloginDispatcher{PublicEngineURL: engineURL, Updates: service}
}

func dispatchVersion(t *testing.T, dispatcher stockruntime.PreloginDispatcher, clientVersion, appVersion string) httpedge.Response {
	t.Helper()
	return dispatcher.Dispatch(context.Background(), httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		MID: 2, Params: map[string]any{"v": clientVersion, "app_v": appVersion, "platform": int64(3)},
	}})
}

func TestMID2SchedulerThroughRealStoreAndService(t *testing.T) {
	pool := nativePool(t)
	seedActiveReleases(t, pool)
	dispatcher := preloginFor(pool)

	response := dispatchVersion(t, dispatcher, "9.100.0", ota.StockAppVersion)
	if response.HTTPStatus != 200 || response.Body["is_inapp"] != int64(1) || response.Body["is_review"] != int64(0) || response.Body["need_restart"] != int64(0) {
		t.Fatalf("response=%+v", response)
	}
	replyconformance.Check(t, 2, response.Body)
	descriptors, ok := response.Body["res"].([]any)
	if !ok || len(descriptors) != 2 {
		t.Fatalf("res=%#v", response.Body["res"])
	}
	first, ok := descriptors[0].(map[string]any)
	if !ok {
		t.Fatalf("descriptor=%#v", descriptors[0])
	}
	if first["version"] != assetVersion || first["volume"] != int64(1) || first["size"] != int64(1000) || first["md5"] != queryMD5 {
		t.Fatalf("first=%+v", first)
	}
	wantResource := engineURL + "/updates/assets/" + assetVersion + "-" + querySHA[:12] + ".zip"
	if first["resource"] != wantResource {
		t.Fatalf("resource=%q want %q", first["resource"], wantResource)
	}
	second, ok := descriptors[1].(map[string]any)
	if !ok || second["version"] != codeVersion {
		t.Fatalf("second=%#v", descriptors[1])
	}

	upToDate := dispatchVersion(t, dispatcher, codeVersion, ota.StockAppVersion)
	if upToDate.HTTPStatus != 200 || upToDate.Body["is_inapp"] != int64(0) {
		t.Fatalf("up-to-date response=%+v", upToDate)
	}
	if _, present := upToDate.Body["res"]; present {
		t.Fatalf("no-update reply carries res: %+v", upToDate.Body)
	}

	unknown := dispatchVersion(t, dispatcher, "9.100.0", "1.630.0")
	if unknown.HTTPStatus != 200 || unknown.Body["is_inapp"] != int64(0) {
		t.Fatalf("unknown app_v response=%+v", unknown)
	}

	active, err := appota.Service{
		Runner: tx.Runner{DB: pool}, Store: otastore.Store{},
		Operations: operation.Factory{Clock: clock.System{}}, PublicEngineURL: engineURL,
	}.ActiveRelease(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if active.AssetVersion == nil || active.AssetVersion.String() != assetVersion || active.CodeVersion == nil || active.CodeVersion.String() != codeVersion || active.CatalogVersion != nil {
		t.Fatalf("active=%+v", active)
	}
	if len(active.ClientPaths) != 1 || active.ClientPaths[0] != "src_64/app/a.lua" {
		t.Fatalf("paths=%v", active.ClientPaths)
	}
}
