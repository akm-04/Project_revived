package otarelease

import (
	"encoding/json"
	"errors"
	"strings"
	"testing"
)

const (
	testSHA256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	testMD5    = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	testEngine = "https://engine.example"
)

func testRow(t *testing.T, version, lane string, size int64, manifestPaths ...string) RawRelease {
	t.Helper()
	volumeName := version + "-" + testSHA256[:12] + ".zip.001"
	packageFiles, err := json.Marshal([]PackageVolume{{Name: volumeName, Size: size, MD5: testMD5, SHA256: testSHA256}})
	if err != nil {
		t.Fatal(err)
	}
	files := make([]ManifestEntry, 0, len(manifestPaths))
	for _, path := range manifestPaths {
		files = append(files, ManifestEntry{Path: path, Size: 1, MD5: testMD5})
	}
	manifest, err := json.Marshal(map[string]any{"files": files})
	if err != nil {
		t.Fatal(err)
	}
	return RawRelease{
		Version: version, Lane: lane, State: string(StateActive),
		PackageFiles: packageFiles, TotalSize: size, MD5: testMD5, SHA256: testSHA256, Manifest: manifest,
	}
}

func stockRequest(clientVersion string) PlanRequest {
	return PlanRequest{ClientVersion: clientVersion, AppVersion: StockAppVersion, Platform: 3}
}

func descriptorVersions(plan UpdatePlan) []string {
	versions := make([]string, 0, len(plan.Descriptors))
	for _, descriptor := range plan.Descriptors {
		versions = append(versions, descriptor.Version)
	}
	return versions
}

func TestPlanUpdateNoActiveRelease(t *testing.T) {
	plan, err := PlanUpdate(stockRequest("1.631.0"), testEngine, nil)
	if err != nil || len(plan.Descriptors) != 0 || plan.IsReview || plan.UnknownAppVersion {
		t.Fatalf("plan=%+v err=%v", plan, err)
	}
}

func TestPlanUpdateAssetBootstrapOnly(t *testing.T) {
	rows := []RawRelease{testRow(t, "1.631.1", "assets", 1000, "src_64/app/a.lua")}
	plan, err := PlanUpdate(stockRequest("1.631.0"), testEngine, rows)
	if err != nil {
		t.Fatal(err)
	}
	if got := descriptorVersions(plan); len(got) != 1 || got[0] != "1.631.1" {
		t.Fatalf("versions=%v", got)
	}
	if plan.IsReview {
		t.Fatal("an asset release is loud, not review")
	}
	descriptor := plan.Descriptors[0]
	if descriptor.Volume != 1 || descriptor.Size != 1000 || descriptor.MD5 != testMD5 {
		t.Fatalf("descriptor=%+v", descriptor)
	}
	want := testEngine + "/updates/assets/1.631.1-" + testSHA256[:12] + ".zip"
	if descriptor.Resource != want {
		t.Fatalf("resource=%q want %q", descriptor.Resource, want)
	}
}

func TestPlanUpdateBootstrapAndNewerCode(t *testing.T) {
	rows := []RawRelease{
		testRow(t, "1.631.2", "code", 2000, "src_64/app/a.lua"),
		testRow(t, "1.631.1", "assets", 1000, "src_64/app/a.lua"),
	}
	plan, err := PlanUpdate(stockRequest("1.631.0"), testEngine, rows)
	if err != nil {
		t.Fatal(err)
	}
	if got := descriptorVersions(plan); len(got) != 2 || got[0] != "1.631.1" || got[1] != "1.631.2" {
		t.Fatalf("versions=%v", got)
	}
	if plan.IsReview {
		t.Fatal("an asset plus code plan is loud")
	}
}

func TestPlanUpdateClientAlreadyOnNewestCode(t *testing.T) {
	rows := []RawRelease{
		testRow(t, "1.631.1", "assets", 1000),
		testRow(t, "1.631.2", "code", 2000),
	}
	plan, err := PlanUpdate(stockRequest("1.631.2"), testEngine, rows)
	if err != nil || len(plan.Descriptors) != 0 || plan.IsReview {
		t.Fatalf("plan=%+v err=%v", plan, err)
	}
}

func TestPlanUpdateAllCodePlanIsReview(t *testing.T) {
	rows := []RawRelease{testRow(t, "1.631.2", "code", 2000)}
	plan, err := PlanUpdate(stockRequest("1.631.0"), testEngine, rows)
	if err != nil || !plan.IsReview || len(plan.Descriptors) != 1 {
		t.Fatalf("plan=%+v err=%v", plan, err)
	}
}

func TestPlanUpdateTwoCatalogReleasesInVersionOrder(t *testing.T) {
	rows := []RawRelease{
		testRow(t, "1.631.4", "catalog", 4000),
		testRow(t, "1.631.3", "catalog", 3000),
	}
	plan, err := PlanUpdate(stockRequest("1.631.0"), testEngine, rows)
	if err != nil {
		t.Fatal(err)
	}
	if got := descriptorVersions(plan); len(got) != 2 || got[0] != "1.631.3" || got[1] != "1.631.4" {
		t.Fatalf("versions=%v", got)
	}
	if plan.IsReview {
		t.Fatal("catalog releases are loud")
	}
}

func TestPlanUpdateUnknownAppVersion(t *testing.T) {
	rows := []RawRelease{testRow(t, "1.631.2", "code", 2000)}
	request := stockRequest("1.631.0")
	request.AppVersion = "1.630.0"
	plan, err := PlanUpdate(request, testEngine, rows)
	if err != nil || !plan.UnknownAppVersion || len(plan.Descriptors) != 0 {
		t.Fatalf("plan=%+v err=%v", plan, err)
	}
}

func TestPlanUpdateEmptyClientVersionIsOlderThanEveryRelease(t *testing.T) {
	rows := []RawRelease{
		testRow(t, "1.631.1", "assets", 1000),
		testRow(t, "1.631.2", "code", 2000),
	}
	plan, err := PlanUpdate(stockRequest(""), testEngine, rows)
	if err != nil {
		t.Fatal(err)
	}
	if got := descriptorVersions(plan); len(got) != 2 || got[0] != "1.631.1" || got[1] != "1.631.2" {
		t.Fatalf("versions=%v", got)
	}
}

func TestPlanUpdateMalformedRowFailsClosed(t *testing.T) {
	row := testRow(t, "1.631.2", "code", 2000)
	volumes := []PackageVolume{{Name: "1.631.2-" + testSHA256[:12] + ".zip.002", Size: 2000, MD5: testMD5, SHA256: testSHA256}}
	raw, err := json.Marshal(volumes)
	if err != nil {
		t.Fatal(err)
	}
	row.PackageFiles = raw
	plan, err := PlanUpdate(stockRequest("1.631.0"), testEngine, []RawRelease{row})
	if !errors.Is(err, ErrInvalidRelease) || len(plan.Descriptors) != 0 {
		t.Fatalf("plan=%+v err=%v", plan, err)
	}
}

func TestParseReleaseRejectsUnsortedManifest(t *testing.T) {
	row := testRow(t, "1.631.2", "code", 2000, "src_64/b.lua", "src_64/a.lua")
	if _, err := ParseRelease(row); !errors.Is(err, ErrInvalidRelease) {
		t.Fatalf("err=%v", err)
	}
}

func TestVersionCompareIsNumeric(t *testing.T) {
	lower, err := ParseVersion("1.631.9")
	if err != nil {
		t.Fatal(err)
	}
	higher, err := ParseVersion("1.631.10")
	if err != nil {
		t.Fatal(err)
	}
	if higher.Compare(lower) <= 0 || lower.Compare(higher) >= 0 {
		t.Fatalf("1.631.10 must sort above 1.631.9")
	}
	for _, text := range []string{"", "1.631", "1.631.0.1", "1.631.x", " 1.631.0", "1.631.-1"} {
		if _, err := ParseVersion(text); err == nil {
			t.Fatalf("version %q was accepted", text)
		}
	}
	if got := (Version{Major: 1, Minor: 2, Patch: 3}).String(); got != "1.2.3" {
		t.Fatalf("String=%q", got)
	}
}

func TestActiveSetUnionsManifestPaths(t *testing.T) {
	rows := []RawRelease{
		testRow(t, "1.631.1", "assets", 1000, "src_64/a.lua", "src_64/b.lua"),
		testRow(t, "1.631.2", "code", 2000, "src_64/b.lua", "src_64/c.lua"),
	}
	active, err := ActiveSet(rows)
	if err != nil {
		t.Fatal(err)
	}
	if active.AssetVersion == nil || active.AssetVersion.String() != "1.631.1" || active.CodeVersion == nil || active.CodeVersion.String() != "1.631.2" {
		t.Fatalf("active=%+v", active)
	}
	want := []string{"src_64/a.lua", "src_64/b.lua", "src_64/c.lua"}
	if strings.Join(active.ClientPaths, ",") != strings.Join(want, ",") {
		t.Fatalf("paths=%v want %v", active.ClientPaths, want)
	}
}

func TestPlanUpdateRefusesVolumeNotFloat32Exact(t *testing.T) {
	rows := []RawRelease{testRow(t, "1.631.2", "code", 16_777_217)}
	if _, err := PlanUpdate(stockRequest("1.631.0"), testEngine, rows); !errors.Is(err, ErrInvalidRelease) {
		t.Fatalf("err=%v", err)
	}
}

func TestPlanUpdateAcceptsFloat32ExactVolumeLimits(t *testing.T) {
	for _, size := range []int64{16_777_216, 99_000_000} {
		rows := []RawRelease{testRow(t, "1.631.2", "code", size)}
		plan, err := PlanUpdate(stockRequest("1.631.0"), testEngine, rows)
		if err != nil || len(plan.Descriptors) != 1 || plan.Descriptors[0].Size != size {
			t.Fatalf("size %d: plan=%+v err=%v", size, plan, err)
		}
	}
}

func TestParseReleaseAcceptsZeroByteManifestEntry(t *testing.T) {
	row := testRow(t, "1.631.2", "code", 2000)
	manifest, err := json.Marshal(map[string]any{"files": []ManifestEntry{{Path: "src_64/app/empty.lua", Size: 0, MD5: testMD5}}})
	if err != nil {
		t.Fatal(err)
	}
	row.Manifest = manifest
	release, err := ParseRelease(row)
	if err != nil {
		t.Fatal(err)
	}
	if len(release.Manifest) != 1 || release.Manifest[0].Size != 0 {
		t.Fatalf("manifest=%+v", release.Manifest)
	}
}

func TestParseReleaseRefusesNegativeManifestSize(t *testing.T) {
	row := testRow(t, "1.631.2", "code", 2000)
	manifest, err := json.Marshal(map[string]any{"files": []ManifestEntry{{Path: "src_64/app/a.lua", Size: -1, MD5: testMD5}}})
	if err != nil {
		t.Fatal(err)
	}
	row.Manifest = manifest
	if _, err := ParseRelease(row); !errors.Is(err, ErrInvalidRelease) {
		t.Fatalf("err=%v", err)
	}
}

func TestPlanUpdateIgnoresUnselectedMalformedRelease(t *testing.T) {
	code := testRow(t, "1.631.2", "code", 2000)
	catalog := testRow(t, "1.631.5", "catalog", 4000, "src_64/b.lua", "src_64/a.lua")
	plan, err := PlanUpdate(stockRequest("1.631.9"), testEngine, []RawRelease{code, catalog})
	if err != nil || len(plan.Descriptors) != 0 {
		t.Fatalf("plan=%+v err=%v", plan, err)
	}
	if _, err := ActiveSet([]RawRelease{code, catalog}); !errors.Is(err, ErrInvalidRelease) {
		t.Fatalf("ActiveSet err=%v", err)
	}
}

func TestParseReleaseWithoutManifestSkipsManifestValidation(t *testing.T) {
	row := testRow(t, "1.631.2", "code", 2000, "src_64/b.lua", "src_64/a.lua")
	if _, err := ParseRelease(row); !errors.Is(err, ErrInvalidRelease) {
		t.Fatalf("ParseRelease err=%v", err)
	}
	release, err := ParseReleaseWithoutManifest(row)
	if err != nil || release.Manifest != nil {
		t.Fatalf("release=%+v err=%v", release, err)
	}
}
