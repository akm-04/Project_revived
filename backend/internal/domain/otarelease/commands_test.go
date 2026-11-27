package otarelease

import (
	"encoding/json"
	"errors"
	"testing"
)

func validBuild(t *testing.T, version, lane string, size int64) BuildRequest {
	t.Helper()
	packageFiles, err := json.Marshal([]PackageVolume{{Name: version + "-" + testSHA256[:12] + ".zip.001", Size: size, MD5: testMD5, SHA256: testSHA256}})
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := json.Marshal(map[string]any{"files": []ManifestEntry{{Path: "src_64/app/a.lua", Size: 1, MD5: testMD5}}})
	if err != nil {
		t.Fatal(err)
	}
	return BuildRequest{Version: version, Lane: lane, PackageFiles: packageFiles, TotalSize: size, MD5: testMD5, SHA256: testSHA256, Manifest: manifest}
}

func TestBuildRequestValidatesLikeAReadRow(t *testing.T) {
	release, err := validBuild(t, "1.631.2", "code", 2000).Release()
	if err != nil {
		t.Fatal(err)
	}
	if release.State != StateBuilt || release.Lane != LaneCode || release.Version.String() != "1.631.2" || release.PackageBase != "1.631.2-"+testSHA256[:12]+".zip" {
		t.Fatalf("release=%+v", release)
	}
}

func TestBuildRequestRefusesBadRows(t *testing.T) {
	cases := map[string]func(*BuildRequest){
		"version": func(request *BuildRequest) { request.Version = "1.631" },
		"lane":    func(request *BuildRequest) { request.Lane = "apk" },
		"hash":    func(request *BuildRequest) { request.SHA256 = "short" },
		"total":   func(request *BuildRequest) { request.TotalSize = 2001 },
		"volume": func(request *BuildRequest) {
			request.PackageFiles = json.RawMessage(`[{"name":"x.zip.001","size":1,"md5":"` + testMD5 + `","sha256":"` + testSHA256 + `"}]`)
		},
		"manifest": func(request *BuildRequest) {
			request.Manifest = json.RawMessage(`{"files":[{"path":"src_64/b.lua","size":1,"md5":"` + testMD5 + `"},{"path":"src_64/a.lua","size":1,"md5":"` + testMD5 + `"}]}`)
		},
	}
	for name, corrupt := range cases {
		t.Run(name, func(t *testing.T) {
			request := validBuild(t, "1.631.2", "code", 2000)
			corrupt(&request)
			if _, err := request.Release(); err == nil {
				t.Fatal("bad build payload was accepted")
			}
		})
	}
	if _, err := (BuildRequest{}).Release(); !errors.Is(err, ErrInvalidBuild) && !errors.Is(err, ErrInvalidRelease) {
		t.Fatalf("empty payload err=%v", err)
	}
}

func TestLowersActive(t *testing.T) {
	active, err := ParseVersion("1.631.10")
	if err != nil {
		t.Fatal(err)
	}
	lower, _ := ParseVersion("1.631.9")
	higher, _ := ParseVersion("1.631.11")
	if !LowersActive(lower, &active) || LowersActive(higher, &active) || LowersActive(active, &active) {
		t.Fatal("LowersActive ordering is wrong")
	}
	if LowersActive(lower, nil) {
		t.Fatal("no active release cannot be lowered")
	}
	if RollbackWarning == "" {
		t.Fatal("rollback warning text is missing")
	}
}
