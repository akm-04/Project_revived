package otarelease

import "testing"

func TestEvaluateCoversCovered(t *testing.T) {
	code := Version{Major: 1, Minor: 631, Patch: 2}
	request := CoversRequest{
		ClientPaths:    []string{"src_64/app/a.lua"},
		LazyAssets:     []LazyAsset{{Path: "res/web/a.png", MD5: testMD5}},
		MinCodeVersion: "1.631.2",
	}
	result := EvaluateCovers(request, []string{"src_64/app/a.lua", "src_64/b.lua"}, &code, func(LazyAsset) bool { return true })
	if result.Status != CoversCovered || len(result.MissingClientPaths) != 0 || len(result.MissingLazyAssets) != 0 || result.MissingCodeVersion != "" {
		t.Fatalf("result=%+v", result)
	}
}

func TestEvaluateCoversMissingLists(t *testing.T) {
	code := Version{Major: 1, Minor: 631, Patch: 1}
	request := CoversRequest{
		ClientPaths:    []string{"src_64/missing.lua"},
		LazyAssets:     []LazyAsset{{Path: "res/web/missing.png", MD5: testMD5}},
		MinCodeVersion: "1.631.2",
	}
	result := EvaluateCovers(request, []string{"src_64/app/a.lua"}, &code, func(LazyAsset) bool { return false })
	if result.Status != CoversMissing {
		t.Fatalf("result=%+v", result)
	}
	if len(result.MissingClientPaths) != 1 || result.MissingClientPaths[0] != "src_64/missing.lua" {
		t.Fatalf("missing paths=%v", result.MissingClientPaths)
	}
	if len(result.MissingLazyAssets) != 1 || result.MissingLazyAssets[0].Path != "res/web/missing.png" {
		t.Fatalf("missing lazy=%v", result.MissingLazyAssets)
	}
	if result.MissingCodeVersion != "1.631.2" {
		t.Fatalf("missing code=%q", result.MissingCodeVersion)
	}
}

func TestEvaluateCoversNoActiveCodeReleaseFailsClosed(t *testing.T) {
	result := EvaluateCovers(CoversRequest{MinCodeVersion: "1.631.2"}, nil, nil, nil)
	if result.Status != CoversMissing || result.MissingCodeVersion != "1.631.2" {
		t.Fatalf("result=%+v", result)
	}
}
