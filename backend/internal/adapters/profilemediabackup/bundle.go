// Package profilemediabackup implements explicitly offline operator recovery.
// Publishers/GC and other DB writers must be stopped for the whole operation.
package profilemediabackup

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	blob "gxb.local/backend/v2/internal/application/profileasset"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	asset "gxb.local/backend/v2/internal/domain/profileasset"
	"io"
	"os"
	"path/filepath"
	"reflect"
	"sort"
	"strings"
)

const Format = "I7B_JOINT_MEDIA_BUNDLE_V1"
const storeFormat = "{\"format\":\"PROFILE_ASSET_STORE_V1\"}\n"

type File struct {
	SHA256 string `json:"sha256"`
	Size   int64  `json:"size"`
	Mode   uint32 `json:"mode"`
}
type Manifest struct {
	Format  string          `json:"format"`
	Offline bool            `json:"offline"`
	Files   map[string]File `json:"files"`
}

func digest(path string) (File, error) {
	fi, e := os.Lstat(path)
	if e != nil || !fi.Mode().IsRegular() {
		return File{}, asset.ErrIntegrity
	}
	f, e := os.Open(path)
	if e != nil {
		return File{}, e
	}
	defer f.Close()
	h := sha256.New()
	n, e := io.Copy(h, f)
	if e != nil {
		return File{}, e
	}
	return File{SHA256: hex.EncodeToString(h.Sum(nil)), Size: n, Mode: uint32(fi.Mode().Perm())}, nil
}
func writeFile(path string, data []byte, mode os.FileMode) error {
	if e := os.MkdirAll(filepath.Dir(path), 0700); e != nil {
		return e
	}
	f, e := os.OpenFile(path, os.O_CREATE|os.O_EXCL|os.O_WRONLY, mode)
	if e != nil {
		return e
	}
	_, e = f.Write(data)
	if e == nil {
		e = f.Sync()
	}
	return errors.Join(e, f.Close())
}
func copyFile(dst string, src io.Reader, mode os.FileMode) error {
	if e := os.MkdirAll(filepath.Dir(dst), 0700); e != nil {
		return e
	}
	f, e := os.OpenFile(dst, os.O_CREATE|os.O_EXCL|os.O_WRONLY, mode)
	if e != nil {
		return e
	}
	_, e = io.Copy(f, src)
	if e == nil {
		e = f.Sync()
	}
	return errors.Join(e, f.Close())
}
func syncTree(root string) error {
	var dirs []string
	e := filepath.WalkDir(root, func(p string, d os.DirEntry, e error) error {
		if e != nil {
			return e
		}
		if d.IsDir() {
			dirs = append(dirs, p)
		}
		return nil
	})
	if e != nil {
		return e
	}
	sort.Sort(sort.Reverse(sort.StringSlice(dirs)))
	for _, p := range dirs {
		f, e := os.Open(p)
		if e != nil {
			return e
		}
		e = f.Sync()
		ce := f.Close()
		if e != nil {
			return e
		}
		if ce != nil {
			return ce
		}
	}
	return nil
}

// dump runs pg_dump in custom format, using the caller's stopped-service
// maintenance procedure. No gameplay transaction remains open during export.
func Backup(c context.Context, m app.MediaMaintenance, destination string, offline bool, dump func(context.Context, string) error) error {
	if !offline || dump == nil || !filepath.IsAbs(destination) {
		return app.ErrCommand
	}
	if _, e := os.Lstat(destination); !errors.Is(e, os.ErrNotExist) {
		return app.ErrCommand
	}
	parent := filepath.Dir(destination)
	if e := os.MkdirAll(parent, 0700); e != nil {
		return e
	}
	tmp, e := os.MkdirTemp(parent, ".joint-media-")
	if e != nil {
		return e
	}
	defer os.RemoveAll(tmp)
	e = m.WithSnapshot(c, func(s app.JointMediaSnapshot, p blob.Maintenance) error {
		if e := dump(c, filepath.Join(tmp, "database.dump")); e != nil {
			return e
		}
		// Offline DB state must stay byte-identical across dump. This is a useful
		// violation check, not a claim to prevent arbitrary noncooperating writers.
		var after app.JointMediaSnapshot
		// Compare the authoritative typed DB manifest again while holding the same
		// physical EX lease; this does not open another physical lease.
		after, e = m.SnapshotDatabase(c)
		if e != nil {
			return e
		}
		if !reflect.DeepEqual(s.Media, after.Media) || !reflect.DeepEqual(s.Receipts, after.Receipts) {
			return asset.ErrIntegrity
		}
		raw, e := json.MarshalIndent(s, "", "  ")
		if e != nil {
			return e
		}
		if e = writeFile(filepath.Join(tmp, "media.json"), append(raw, '\n'), 0600); e != nil {
			return e
		}
		if e = writeFile(filepath.Join(tmp, "assets/format.json"), []byte(storeFormat), 0600); e != nil {
			return e
		}
		for _, d := range s.Blobs {
			f, e := p.OpenValidated(d)
			if e != nil {
				return e
			}
			e = copyFile(filepath.Join(tmp, "assets/blobs/"+d.SHA256+".png"), f, 0400)
			ce := f.Close()
			if e != nil {
				return e
			}
			if ce != nil {
				return ce
			}
		}
		for _, pin := range s.Pins {
			raw, e := json.Marshal(pin)
			if e != nil {
				return e
			}
			if e = writeFile(filepath.Join(tmp, "assets/pins/"+pin.Reservation.Operation.String()+".json"), append(raw, '\n'), 0600); e != nil {
				return e
			}
		}
		// Empty blob/pin directories are part of a valid empty-store backup.
		for _, n := range []string{"assets/blobs", "assets/pins"} {
			if e = os.MkdirAll(filepath.Join(tmp, n), 0700); e != nil {
				return e
			}
		}
		return nil
	})
	if e != nil {
		return e
	}
	manifest := Manifest{Format: Format, Offline: true, Files: map[string]File{}}
	e = filepath.WalkDir(tmp, func(p string, d os.DirEntry, e error) error {
		if e != nil {
			return e
		}
		if d.IsDir() {
			return nil
		}
		v, e := digest(p)
		if e != nil {
			return e
		}
		n, e := filepath.Rel(tmp, p)
		if e != nil {
			return e
		}
		manifest.Files[filepath.ToSlash(n)] = v
		return nil
	})
	if e != nil {
		return e
	}
	raw, e := json.MarshalIndent(manifest, "", "  ")
	if e != nil {
		return e
	}
	if e = writeFile(filepath.Join(tmp, "MANIFEST.json"), append(raw, '\n'), 0600); e != nil {
		return e
	}
	if e = syncTree(tmp); e != nil {
		return e
	}
	if e = os.Rename(tmp, destination); e != nil {
		return e
	}
	f, e := os.Open(parent)
	if e != nil {
		return e
	}
	e = f.Sync()
	return errors.Join(e, f.Close())
}
func strictJSON(path string, dst any) error {
	f, e := os.Open(path)
	if e != nil {
		return e
	}
	defer f.Close()
	d := json.NewDecoder(f)
	d.DisallowUnknownFields()
	if e = d.Decode(dst); e != nil {
		return e
	}
	var tail any
	if d.Decode(&tail) != io.EOF {
		return asset.ErrIntegrity
	}
	return nil
}
func VerifyFiles(root string) (app.JointMediaSnapshot, error) {
	var out app.JointMediaSnapshot
	var mf Manifest
	if !filepath.IsAbs(root) {
		return out, app.ErrCommand
	}
	if e := strictJSON(filepath.Join(root, "MANIFEST.json"), &mf); e != nil {
		return out, e
	}
	if mf.Format != Format || !mf.Offline || len(mf.Files) < 3 {
		return out, asset.ErrIntegrity
	}
	if e := strictJSON(filepath.Join(root, "media.json"), &out); e != nil {
		return out, e
	}
	if out.Format != "I7B_JOINT_MEDIA_V1" {
		return out, asset.ErrIntegrity
	}
	required := map[string]bool{"database.dump": true, "media.json": true, "assets/format.json": true}
	for _, d := range out.Blobs {
		if d.Validate() != nil {
			return out, asset.ErrIntegrity
		}
		required["assets/blobs/"+d.SHA256+".png"] = true
	}
	for _, p := range out.Pins {
		if p.Validate() != nil {
			return out, asset.ErrIntegrity
		}
		required["assets/pins/"+p.Reservation.Operation.String()+".json"] = true
	}
	if len(required) != len(mf.Files) {
		return out, asset.ErrIntegrity
	}
	for n, v := range mf.Files {
		if !required[n] || strings.Contains(n, "\\") || filepath.IsAbs(n) || filepath.Clean(n) != n || strings.HasPrefix(n, "../") {
			return out, asset.ErrIntegrity
		}
		got, e := digest(filepath.Join(root, n))
		if e != nil || got != v {
			return out, asset.ErrIntegrity
		}
	}
	raw, e := os.ReadFile(filepath.Join(root, "assets/format.json"))
	if e != nil || string(raw) != storeFormat {
		return out, asset.ErrIntegrity
	}
	// Unexpected files/symlinks are refused; the manifest is a relocation recipe,
	// not an arbitrary path extractor.
	e = filepath.WalkDir(root, func(p string, d os.DirEntry, e error) error {
		if e != nil {
			return e
		}
		if d.Type()&os.ModeSymlink != 0 {
			return asset.ErrIntegrity
		}
		if d.IsDir() {
			return nil
		}
		n, e := filepath.Rel(root, p)
		if e != nil {
			return e
		}
		if n != "MANIFEST.json" && !required[filepath.ToSlash(n)] {
			return asset.ErrIntegrity
		}
		return nil
	})
	return out, e
}

// RestoreIntoEmpty copies immutable bytes/control pins and invokes pg_restore
// only into an independently checked empty DB. The caller must validate typed
// DB/blob coherence before restarting any process. Failure leaves offline
// recovery state and never authorizes serving a partially restored system.
func RestoreIntoEmpty(c context.Context, bundle, destination string, offline bool, restore func(context.Context, string) error) error {
	if !offline || !filepath.IsAbs(destination) || restore == nil {
		return app.ErrCommand
	}
	if _, e := os.Lstat(destination); !errors.Is(e, os.ErrNotExist) {
		return app.ErrCommand
	}
	if _, e := VerifyFiles(bundle); e != nil {
		return e
	}
	var mf Manifest
	if e := strictJSON(filepath.Join(bundle, "MANIFEST.json"), &mf); e != nil {
		return e
	}
	if e := os.MkdirAll(destination, 0700); e != nil {
		return e
	}
	for n, v := range mf.Files {
		if !strings.HasPrefix(n, "assets/") {
			continue
		}
		f, e := os.Open(filepath.Join(bundle, n))
		if e != nil {
			return e
		}
		e = copyFile(filepath.Join(destination, strings.TrimPrefix(n, "assets/")), f, os.FileMode(v.Mode))
		ce := f.Close()
		if e != nil {
			return e
		}
		if ce != nil {
			return ce
		}
	}
	for _, n := range []string{"blobs", "pins", "staging"} {
		if e := os.MkdirAll(filepath.Join(destination, n), 0700); e != nil {
			return e
		}
	}
	if e := syncTree(destination); e != nil {
		return e
	}
	return restore(c, filepath.Join(bundle, "database.dump"))
}
func VerifyRestored(c context.Context, m app.MediaMaintenance, bundle string) error {
	expected, e := VerifyFiles(bundle)
	if e != nil {
		return e
	}
	return m.WithSnapshot(c, func(actual app.JointMediaSnapshot, _ blob.Maintenance) error {
		// Sort physical inventory because directory enumeration has no ordering law.
		sort.Slice(expected.Blobs, func(i, j int) bool { return expected.Blobs[i].SHA256 < expected.Blobs[j].SHA256 })
		sort.Slice(actual.Blobs, func(i, j int) bool { return actual.Blobs[i].SHA256 < actual.Blobs[j].SHA256 })
		sort.Slice(expected.Pins, func(i, j int) bool {
			return expected.Pins[i].Reservation.Operation.String() < expected.Pins[j].Reservation.Operation.String()
		})
		sort.Slice(actual.Pins, func(i, j int) bool {
			return actual.Pins[i].Reservation.Operation.String() < actual.Pins[j].Reservation.Operation.String()
		})
		// RawMessage formatting changes when an operator manifest is indented.
		// Canonical JSON compares every typed field and compact receipt payload,
		// without confusing whitespace with changed durable evidence.
		a, e := json.Marshal(expected)
		if e != nil {
			return e
		}
		b, e := json.Marshal(actual)
		if e != nil {
			return e
		}
		if !bytes.Equal(a, b) {
			return asset.ErrIntegrity
		}
		return nil
	})
}
