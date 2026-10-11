//go:build linux

package blobstore

import (
	"bufio"
	"bytes"
	"context"
	"errors"
	"fmt"
	port "gxb.local/backend/v2/internal/application/profileasset"
	asset "gxb.local/backend/v2/internal/domain/profileasset"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestNativeHelper(t *testing.T) {
	root := os.Getenv("GXB_ASSET_TEST_ROOT")
	if root == "" {
		t.Skip("subprocess-only")
	}
	s, e := NewLocal(root)
	if e != nil {
		t.Fatal(e)
	}
	mode := os.Getenv("GXB_ASSET_TEST_CRASH")
	old := s.syncFile
	signal := func() { fmt.Println("ASSET_CRASH_POINT"); select {} }
	s.syncFile = func(f *os.File) error {
		base := filepath.Base(f.Name())
		if (mode == "before-install" && strings.HasPrefix(base, "png-")) || (mode == "after-link" && base == "blobs") || (mode == "after-pin-before-ready" && base == "pins") {
			signal()
		}
		return old(f)
	}
	p, e := s.Prepare(context.Background(), bytes.NewReader(sample(t)), reservation(900))
	if e != nil {
		t.Fatal(e)
	}
	if p == nil {
		t.Fatal("no permit")
	}
	signal()
}
func TestNativeProcessKillRestartAndProtectedInventory(t *testing.T) {
	for _, mode := range []string{"before-install", "after-link", "after-pin-before-ready", "ready-held"} {
		t.Run(mode, func(t *testing.T) {
			root := filepath.Join(t.TempDir(), "store")
			cmd := exec.Command(os.Args[0], "-test.run=^TestNativeHelper$", "-test.timeout=20s")
			cmd.Env = append(os.Environ(), "GXB_ASSET_TEST_ROOT="+root, "GXB_ASSET_TEST_CRASH="+mode)
			var stderr bytes.Buffer
			cmd.Stderr = &stderr
			out, e := cmd.StdoutPipe()
			if e != nil {
				t.Fatal(e)
			}
			if e = cmd.Start(); e != nil {
				t.Fatal(e)
			}
			defer cmd.Process.Kill()
			ready := make(chan string, 1)
			go func() { line, _ := bufio.NewReader(out).ReadString('\n'); ready <- line }()
			select {
			case line := <-ready:
				if strings.TrimSpace(line) != "ASSET_CRASH_POINT" {
					t.Fatal(line, stderr.String())
				}
			case <-time.After(5 * time.Second):
				t.Fatal("child did not reach crash point", stderr.String())
			}
			probe := &Local{root: root, slots: make(chan struct{}, 2), syncFile: func(f *os.File) error { return f.Sync() }}
			ctx, cancel := context.WithTimeout(context.Background(), 25*time.Millisecond)
			defer cancel()
			if e = probe.WithMaintenance(ctx, func(port.Maintenance) error { return errors.New("unexpected exclusive") }); !errors.Is(e, context.DeadlineExceeded) {
				t.Fatal("child permit did not block maintenance", e)
			}
			if e = cmd.Process.Kill(); e != nil {
				t.Fatal(e)
			}
			if e = cmd.Wait(); e == nil {
				t.Fatal("child did not die")
			}
			restarted, e := NewLocal(root)
			if e != nil {
				t.Fatal(e)
			}
			blobs, pins := 0, 0
			var d asset.Descriptor
			e = restarted.WithMaintenance(context.Background(), func(m port.Maintenance) error {
				if e := m.Inventory(func(v asset.Descriptor) error { blobs++; d = v; return nil }, func(asset.Pin) error { pins++; return nil }); e != nil {
					return e
				}
				return m.CleanStaging()
			})
			if e != nil {
				t.Fatal(e)
			}
			wantBlobs, wantPins := 1, 0
			if mode == "before-install" {
				wantBlobs = 0
			}
			if mode == "after-pin-before-ready" || mode == "ready-held" {
				wantPins = 1
			}
			if blobs != wantBlobs || pins != wantPins {
				t.Fatal(mode, blobs, pins)
			}
			staging, _ := os.ReadDir(restarted.path("staging"))
			if len(staging) != 0 {
				t.Fatal("abandoned staging")
			}
			if pins == 1 {
				if e = restarted.WithMaintenance(context.Background(), func(m port.Maintenance) error { return m.Delete(d) }); !errors.Is(e, asset.ErrConflict) {
					t.Fatal("kill lost protection", e)
				}
				r, e := restarted.OpenValidated(context.Background(), d)
				if e != nil {
					t.Fatal(e)
				}
				raw, e := io.ReadAll(r)
				r.Close()
				if e != nil || !bytes.Equal(raw, sample(t)) {
					t.Fatal("restart identity", e)
				}
			}
		})
	}
}
func TestStoreRelocationPreservesDescriptorAndPins(t *testing.T) {
	s := store(t)
	p := prepare(t, s, sample(t), 1)
	d := descriptor(t, p)
	p.Close(asset.Unknown)
	to := filepath.Join(t.TempDir(), "relocated")
	if e := os.Mkdir(to, 0700); e != nil {
		t.Fatal(e)
	}
	for _, name := range []string{"staging", "blobs", "pins"} {
		os.Mkdir(filepath.Join(to, name), 0700)
	}
	// Physical component relocation only, not a database/blob backup acceptance.
	for _, name := range []string{"format.json", "blobs/" + d.SHA256 + ".png", "pins/" + reservation(1).Operation.String() + ".json"} {
		b, e := os.ReadFile(s.path(name))
		if e != nil {
			t.Fatal(e)
		}
		mode := os.FileMode(0600)
		if strings.HasPrefix(name, "blobs/") {
			mode = 0400
		}
		if e = os.WriteFile(filepath.Join(to, name), b, mode); e != nil {
			t.Fatal(e)
		}
	}
	moved, e := NewLocal(to)
	if e != nil {
		t.Fatal(e)
	}
	r, e := moved.OpenValidated(context.Background(), d)
	if e != nil {
		t.Fatal(e)
	}
	r.Close()
	if e = moved.WithMaintenance(context.Background(), func(m port.Maintenance) error { return m.Delete(d) }); !errors.Is(e, asset.ErrConflict) {
		t.Fatal(e)
	}
}
func FuzzBoundedPNGMetadata(f *testing.F) {
	var b bytes.Buffer /* valid PNG fixture without testing.T */
	b.Write(adam7())
	f.Add(b.Bytes())
	f.Add([]byte("not PNG"))
	f.Add(header(2049, 1))
	f.Fuzz(func(t *testing.T, b []byte) {
		if len(b) > 1<<20 {
			t.Skip()
		}
		file, e := os.CreateTemp(t.TempDir(), "png-")
		if e != nil {
			t.Fatal(e)
		}
		defer file.Close()
		if _, e = file.Write(b); e != nil {
			t.Fatal(e)
		}
		d, e := metadata(context.Background(), file)
		if e == nil {
			if d.Validate() != nil {
				t.Fatal("invalid qualified descriptor")
			}
			if d.Size != int64(len(b)) {
				t.Fatal("wrong identity size")
			}
		}
	})
}
