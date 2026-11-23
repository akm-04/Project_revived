package otabuild

import (
	"crypto/md5"
	"encoding/hex"
	"os"
	"path/filepath"
	"strconv"
	"testing"
)

func extraCatalogueFixture(t *testing.T, body string) resRoot {
	t.Helper()
	root := t.TempDir()
	nested := filepath.Join(root, "web", "sound", "legacy2018", "x")
	if err := os.MkdirAll(nested, 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	content := []byte("fake ogg payload")
	if err := os.WriteFile(filepath.Join(nested, "x_voice1.ogg"), content, 0o644); err != nil {
		t.Fatalf("write asset: %v", err)
	}
	digest := md5.Sum(content)
	line := "path,md5,size\nres/web/sound/legacy2018/x/x_voice1.ogg," + hex.EncodeToString(digest[:]) + "," +
		strconv.Itoa(len(content)) + "\n"
	if body != "" {
		line = body
	}
	if err := os.WriteFile(filepath.Join(root, extraCatalogueFile), []byte(line), 0o644); err != nil {
		t.Fatalf("write catalogue: %v", err)
	}
	resolved, err := resolveResRoot(root)
	if err != nil {
		t.Fatalf("resolve root: %v", err)
	}
	return resolved
}

func TestExtraCatalogueAddsRows(t *testing.T) {
	root := extraCatalogueFixture(t, "")
	extras, err := readExtraCatalogue(root)
	if err != nil {
		t.Fatalf("read: %v", err)
	}
	if len(extras) != 1 || extras[0].Path != "res/web/sound/legacy2018/x/x_voice1.ogg" {
		t.Fatalf("unexpected extras: %#v", extras)
	}
	rows, sidecar, err := appendExtraRows([]catalogRow{{Path: "res/web/sound/old.ogg", MD5: "0", Size: 0, Force: 1}}, nil, extras)
	if err != nil {
		t.Fatalf("append: %v", err)
	}
	if len(rows) != 2 || rows[1].Force != 0 || rows[1].Path != extras[0].Path {
		t.Fatalf("unexpected rows: %#v", rows)
	}
	if len(sidecar) != 1 || sidecar[0].Path != "web/sound/legacy2018/x/x_voice1.ogg" {
		t.Fatalf("unexpected sidecar: %#v", sidecar)
	}
}

func TestExtraCatalogueAbsentIsNoOp(t *testing.T) {
	root, err := resolveResRoot(t.TempDir())
	if err != nil {
		t.Fatalf("resolve root: %v", err)
	}
	extras, err := readExtraCatalogue(root)
	if err != nil || len(extras) != 0 {
		t.Fatalf("expected no extras, err=%v", err)
	}
}

func TestExtraCatalogueRejectsMismatch(t *testing.T) {
	root := extraCatalogueFixture(t, "path,md5,size\nres/web/sound/legacy2018/x/x_voice1.ogg,"+
		"0123456789abcdef0123456789abcdef,17\n")
	if _, err := readExtraCatalogue(root); err == nil {
		t.Fatal("expected a mismatch error")
	}
}

func TestExtraCatalogueRejectsDuplicateStockRow(t *testing.T) {
	root := extraCatalogueFixture(t, "")
	extras, err := readExtraCatalogue(root)
	if err != nil {
		t.Fatalf("read: %v", err)
	}
	if _, _, err := appendExtraRows([]catalogRow{{Path: extras[0].Path}}, nil, extras); err == nil {
		t.Fatal("expected a duplicate error")
	}
}
