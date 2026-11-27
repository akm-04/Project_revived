package stockruntime

import (
	"context"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"

	appotarelease "gxb.local/backend/v2/internal/application/otarelease"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

const otaServingSHA = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

func otaMD5(data []byte) string {
	sum := md5.Sum(data)
	return hex.EncodeToString(sum[:])
}

func otaVolumeName(version string) string {
	return version + "-" + otaServingSHA[:12] + ".zip.001"
}

func otaRow(t *testing.T, version string, lane domain.Lane, state domain.State, size int64) domain.RawRelease {
	t.Helper()
	volumes, err := json.Marshal([]domain.PackageVolume{{Name: otaVolumeName(version), Size: size, MD5: otaMD5([]byte("volume")), SHA256: otaServingSHA}})
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := json.Marshal(map[string]any{"files": []domain.ManifestEntry{{Path: "src_64/app/a.lua", Size: 1, MD5: otaMD5([]byte("a"))}}})
	if err != nil {
		t.Fatal(err)
	}
	return domain.RawRelease{
		Version: version, Lane: string(lane), State: string(state),
		PackageFiles: volumes, TotalSize: size, MD5: otaMD5([]byte("zip")), SHA256: otaServingSHA, Manifest: manifest,
	}
}

type otaHarness struct {
	serving *appotarelease.Serving
	root    string
	res     string
	volume  []byte
	asset   []byte
}

func newOTAHarness(t *testing.T, rows []domain.RawRelease, lazyFetch domain.LazyFetch) otaHarness {
	t.Helper()
	root := t.TempDir()
	res := t.TempDir()
	volumeBytes := []byte("0123456789abcdefghij")
	assetBytes := []byte("asset-bytes")
	for _, row := range rows {
		if row.State != string(domain.StateActive) {
			continue
		}
		directory := filepath.Join(root, "updates", row.Lane)
		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(directory, otaVolumeName(row.Version)), volumeBytes, 0o644); err != nil {
			t.Fatal(err)
		}
		base := otaVolumeName(row.Version)[:len(otaVolumeName(row.Version))-4]
		sidecar, err := json.Marshal(map[string]any{"entries": []map[string]any{{
			"path": "res/web/a.png", "md5": otaMD5(assetBytes), "size": int64(len(assetBytes)),
		}}})
		if err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(directory, base+".res.json"), sidecar, 0o644); err != nil {
			t.Fatal(err)
		}
	}
	assetPath := filepath.Join(res, "res", "web", "a.png")
	if err := os.MkdirAll(filepath.Dir(assetPath), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(assetPath, assetBytes, 0o644); err != nil {
		t.Fatal(err)
	}
	settings := domain.DefaultSettings()
	settings.LazyFetch = lazyFetch
	settings.ResPath = res
	serving := &appotarelease.Serving{
		Load:            func(context.Context) ([]domain.RawRelease, error) { return rows, nil },
		Root:            root,
		Settings:        appotarelease.NewSettingsValue(settings),
		PublicEngineURL: "https://engine.example",
	}
	if err := serving.Refresh(context.Background()); err != nil {
		t.Fatal(err)
	}
	return otaHarness{serving: serving, root: root, res: res, volume: volumeBytes, asset: assetBytes}
}

func TestOTAUpdatesHandlerServesActiveVolumeWithRange(t *testing.T) {
	rows := []domain.RawRelease{otaRow(t, "1.631.1", domain.LaneAssets, domain.StateActive, 20)}
	harness := newOTAHarness(t, rows, domain.LazyFetchAuto)
	handler := OTAUpdatesGET{Serving: harness.serving}
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/updates/assets/"+otaVolumeName("1.631.1"), nil))
	if response.Code != http.StatusOK || response.Body.String() != string(harness.volume) {
		t.Fatalf("status=%d body=%q", response.Code, response.Body.String())
	}

	ranged := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/updates/assets/"+otaVolumeName("1.631.1"), nil)
	request.Header.Set("Range", "bytes=10-")
	handler.ServeHTTP(ranged, request)
	if ranged.Code != http.StatusPartialContent || ranged.Body.String() != string(harness.volume[10:]) {
		t.Fatalf("range status=%d body=%q", ranged.Code, ranged.Body.String())
	}
	if got := ranged.Header().Get("Content-Range"); got != "bytes 10-19/20" {
		t.Fatalf("content-range=%q", got)
	}
}

func TestOTAUpdatesHandlerRefusesNonActiveAndTricks(t *testing.T) {
	rows := []domain.RawRelease{
		otaRow(t, "1.631.2", domain.LaneCode, domain.StateBuilt, 20),
		otaRow(t, "1.631.3", domain.LaneCode, domain.StateWithdrawn, 20),
	}
	harness := newOTAHarness(t, rows, domain.LazyFetchOff)
	handler := OTAUpdatesGET{Serving: harness.serving}
	for _, target := range []string{
		"/updates/code/" + otaVolumeName("1.631.2"),
		"/updates/code/" + otaVolumeName("1.631.3"),
		"/updates/assets/" + otaVolumeName("1.631.2"),
		"/updates/assets/../settings.json",
		"/updates/assets/..%2fsettings.json",
	} {
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, httptest.NewRequest(http.MethodGet, target, nil))
		if response.Code != http.StatusNotFound {
			t.Fatalf("%s status=%d", target, response.Code)
		}
	}
}

func TestOTAResHandlerServesIndexedAssetAndRefusesUnknown(t *testing.T) {
	rows := []domain.RawRelease{otaRow(t, "1.631.1", domain.LaneAssets, domain.StateActive, 20)}
	harness := newOTAHarness(t, rows, domain.LazyFetchOn)
	handler := OTAResGET{Serving: harness.serving}

	response := httptest.NewRecorder()
	handler.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/res/a.png."+otaMD5(harness.asset), nil))
	if response.Code != http.StatusOK || response.Body.String() != string(harness.asset) {
		t.Fatalf("hit status=%d body=%q", response.Code, response.Body.String())
	}
	missing := httptest.NewRecorder()
	handler.ServeHTTP(missing, httptest.NewRequest(http.MethodGet, "/res/unknown.png."+otaMD5([]byte("x")), nil))
	if missing.Code != http.StatusNotFound {
		t.Fatalf("unknown status=%d", missing.Code)
	}
	mismatch := httptest.NewRecorder()
	handler.ServeHTTP(mismatch, httptest.NewRequest(http.MethodGet, "/res/a.png."+otaMD5([]byte("wrong")), nil))
	if mismatch.Code != http.StatusNotFound {
		t.Fatalf("mismatch status=%d", mismatch.Code)
	}
}

func TestOTADownloadWriteDeadlineFollowsSize(t *testing.T) {
	now := time.Unix(1_000, 0)
	settings := domain.DefaultSettings()
	if got := settings.DownloadWriteDeadline(now, 0).Sub(now); got != 35*time.Second {
		t.Fatalf("empty deadline=%s", got)
	}
	if got := settings.DownloadWriteDeadline(now, 32*1024).Sub(now); got != 36*time.Second {
		t.Fatalf("32 KiB deadline=%s", got)
	}
	huge := int64(99_000_000)
	if got := settings.DownloadWriteDeadline(now, huge).Sub(now); got != 35*time.Second+time.Duration(huge)*time.Second/(32*1024) {
		t.Fatalf("99 MB deadline=%s", got)
	}
	if !settings.DownloadWriteDeadline(now, huge).After(settings.DownloadWriteDeadline(now, 32*1024)) {
		t.Fatal("the deadline does not grow with the size")
	}
	slower := settings
	slower.DownloadMinKiBPerSecond = 1
	if got := slower.DownloadWriteDeadline(now, 32*1024).Sub(now); got != 35*time.Second+32*time.Second {
		t.Fatalf("1 KiB/s deadline=%s", got)
	}
}

type deadlineRecorder struct {
	*httptest.ResponseRecorder
	set      bool
	deadline time.Time
}

func (r *deadlineRecorder) SetWriteDeadline(deadline time.Time) error {
	r.set = true
	r.deadline = deadline
	return nil
}

func TestOTAHandlersReplaceTheSharedWriteDeadline(t *testing.T) {
	rows := []domain.RawRelease{otaRow(t, "1.631.1", domain.LaneAssets, domain.StateActive, 20)}
	harness := newOTAHarness(t, rows, domain.LazyFetchOn)
	cases := []struct {
		name    string
		handler http.Handler
		target  string
	}{
		{"updates", OTAUpdatesGET{Serving: harness.serving}, "/updates/assets/" + otaVolumeName("1.631.1")},
		{"res", OTAResGET{Serving: harness.serving}, "/res/a.png." + otaMD5(harness.asset)},
	}
	for _, test := range cases {
		writer := &deadlineRecorder{ResponseRecorder: httptest.NewRecorder()}
		test.handler.ServeHTTP(writer, httptest.NewRequest(http.MethodGet, test.target, nil))
		if writer.Code != http.StatusOK {
			t.Fatalf("%s status=%d", test.name, writer.Code)
		}
		if !writer.set || writer.deadline.IsZero() {
			t.Fatalf("%s did not set a write deadline", test.name)
		}
	}
}

func TestOTACacheControlFollowsTheLiveSetting(t *testing.T) {
	rows := []domain.RawRelease{otaRow(t, "1.631.1", domain.LaneAssets, domain.StateActive, 20)}
	harness := newOTAHarness(t, rows, domain.LazyFetchOn)
	updates := OTAUpdatesGET{Serving: harness.serving}
	res := OTAResGET{Serving: harness.serving}
	volumePath := "/updates/assets/" + otaVolumeName("1.631.1")
	assetPath := "/res/a.png." + otaMD5(harness.asset)

	const immutable = "public, max-age=31536000, immutable"
	for _, target := range []string{volumePath, assetPath} {
		response := httptest.NewRecorder()
		if target == volumePath {
			updates.ServeHTTP(response, httptest.NewRequest(http.MethodGet, target, nil))
		} else {
			res.ServeHTTP(response, httptest.NewRequest(http.MethodGet, target, nil))
		}
		if response.Code != http.StatusOK || response.Header().Get("Cache-Control") != immutable {
			t.Fatalf("%s status=%d cache=%q", target, response.Code, response.Header().Get("Cache-Control"))
		}
	}

	ranged := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, volumePath, nil)
	request.Header.Set("Range", "bytes=10-")
	updates.ServeHTTP(ranged, request)
	if ranged.Code != http.StatusPartialContent || ranged.Header().Get("Cache-Control") != immutable {
		t.Fatalf("range status=%d cache=%q", ranged.Code, ranged.Header().Get("Cache-Control"))
	}

	noStoreSettings := harness.serving.Settings.Get()
	noStoreSettings.CacheMaxAgeSeconds = 0
	harness.serving.Settings.Set(noStoreSettings)
	for _, target := range []string{volumePath, assetPath} {
		response := httptest.NewRecorder()
		if target == volumePath {
			updates.ServeHTTP(response, httptest.NewRequest(http.MethodGet, target, nil))
		} else {
			res.ServeHTTP(response, httptest.NewRequest(http.MethodGet, target, nil))
		}
		if response.Code != http.StatusOK || response.Header().Get("Cache-Control") != "no-store" {
			t.Fatalf("%s status=%d cache=%q", target, response.Code, response.Header().Get("Cache-Control"))
		}
	}

	for _, target := range []string{"/updates/assets/missing.zip.001", "/res/missing.png." + otaMD5([]byte("x"))} {
		response := httptest.NewRecorder()
		if target[:8] == "/updates" {
			updates.ServeHTTP(response, httptest.NewRequest(http.MethodGet, target, nil))
		} else {
			res.ServeHTTP(response, httptest.NewRequest(http.MethodGet, target, nil))
		}
		if response.Code != http.StatusNotFound || response.Header().Get("Cache-Control") != "no-store" {
			t.Fatalf("%s status=%d cache=%q", target, response.Code, response.Header().Get("Cache-Control"))
		}
	}
}

func TestOTALiveSettingsChangeTheNextWriteDeadline(t *testing.T) {
	rows := []domain.RawRelease{otaRow(t, "1.631.1", domain.LaneAssets, domain.StateActive, 20)}
	harness := newOTAHarness(t, rows, domain.LazyFetchOn)
	now := time.Unix(1_000, 0)
	harness.serving.Now = func() time.Time { return now }
	handler := OTAUpdatesGET{Serving: harness.serving}
	target := "/updates/assets/" + otaVolumeName("1.631.1")
	bodyBytes := int64(len(harness.volume))

	first := &deadlineRecorder{ResponseRecorder: httptest.NewRecorder()}
	handler.ServeHTTP(first, httptest.NewRequest(http.MethodGet, target, nil))
	if first.Code != http.StatusOK || !first.set {
		t.Fatalf("first status=%d set=%v", first.Code, first.set)
	}
	if want := now.Add(35*time.Second + time.Duration(bodyBytes)*time.Second/(32*1024)); !first.deadline.Equal(want) {
		t.Fatalf("deadline=%s want=%s", first.deadline, want)
	}

	shorter := harness.serving.Settings.Get()
	shorter.DownloadBaseSeconds = 5
	shorter.DownloadMinKiBPerSecond = 1
	harness.serving.Settings.Set(shorter)
	second := &deadlineRecorder{ResponseRecorder: httptest.NewRecorder()}
	handler.ServeHTTP(second, httptest.NewRequest(http.MethodGet, target, nil))
	if second.Code != http.StatusOK || !second.set {
		t.Fatalf("second status=%d set=%v", second.Code, second.set)
	}
	if want := now.Add(5*time.Second + time.Duration(bodyBytes)*time.Second/1024); !second.deadline.Equal(want) {
		t.Fatalf("live deadline=%s want=%s", second.deadline, want)
	}
}

func TestOTAResHandlerRefusesWhenLazyFetchIsOff(t *testing.T) {
	rows := []domain.RawRelease{otaRow(t, "1.631.1", domain.LaneAssets, domain.StateActive, 20)}
	harness := newOTAHarness(t, rows, domain.LazyFetchOff)
	handler := OTAResGET{Serving: harness.serving}
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/res/a.png."+otaMD5(harness.asset), nil))
	if response.Code != http.StatusNotFound {
		t.Fatalf("lazy_fetch off status=%d", response.Code)
	}
}

func TestPreloginDiscoveryAdvertisesResOnlyWhenLazyFetchIsEffective(t *testing.T) {
	at := time.Unix(1, 0)
	discovery := func(resourceURL func(context.Context) (string, error)) httpedge.Response {
		return PreloginDispatcher{PublicEngineURL: "https://engine.example", ResourceDownloadURL: resourceURL}.
			Dispatch(context.Background(), httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 20480, ReceivedAt: at, Params: map[string]any{"area": "tw"}}})
	}
	codeOnly := []domain.RawRelease{otaRow(t, "1.631.2", domain.LaneCode, domain.StateActive, 20)}
	noAssets := newOTAHarness(t, codeOnly, domain.LazyFetchAuto)
	response := discovery(noAssets.serving.ResDownloadURL)
	if response.HTTPStatus != 200 || response.Body["res_download_url"] != "" {
		t.Fatalf("auto without assets response=%+v", response.Body)
	}

	assetsRows := []domain.RawRelease{otaRow(t, "1.631.1", domain.LaneAssets, domain.StateActive, 20)}
	withAssets := newOTAHarness(t, assetsRows, domain.LazyFetchAuto)
	response = discovery(withAssets.serving.ResDownloadURL)
	if response.HTTPStatus != 200 || response.Body["res_download_url"] != "https://engine.example/res/" {
		t.Fatalf("auto with assets response=%+v", response.Body)
	}

	offSettings := domain.DefaultSettings()
	offSettings.LazyFetch = domain.LazyFetchOff
	offSettings.ResPath = withAssets.res
	withAssets.serving.Settings = appotarelease.NewSettingsValue(offSettings)
	response = discovery(withAssets.serving.ResDownloadURL)
	if response.HTTPStatus != 200 || response.Body["res_download_url"] != "" {
		t.Fatalf("off response=%+v", response.Body)
	}
}

// S1 item 3: an unloadable release set is "no update" for /updates and a 404
// for /res, never a 503 the client retries forever.
func TestOTAHandlersAnswerNoUpdateWhenServingCannotLoad(t *testing.T) {
	serving := &appotarelease.Serving{
		Load:     func(context.Context) ([]domain.RawRelease, error) { return nil, errors.New("corrupt releases.json") },
		Root:     t.TempDir(),
		Settings: appotarelease.NewSettingsValue(domain.DefaultSettings()),
	}
	updates := OTAUpdatesGET{Serving: serving}
	recorder := httptest.NewRecorder()
	updates.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/updates/assets/"+otaVolumeName("1.631.1"), nil))
	if recorder.Code != http.StatusNotFound {
		t.Fatalf("/updates status=%d want 404", recorder.Code)
	}
	res := OTAResGET{Serving: serving}
	recorder = httptest.NewRecorder()
	res.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/res/a.png."+otaMD5([]byte("asset")), nil))
	if recorder.Code != http.StatusNotFound {
		t.Fatalf("/res status=%d want 404", recorder.Code)
	}
}
