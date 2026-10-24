//go:build linux

package blobstore

import (
	"bytes"
	"compress/zlib"
	"context"
	"crypto/md5"
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"errors"
	port "gxb.local/backend/v2/internal/application/profileasset"
	"gxb.local/backend/v2/internal/domain/identity"
	asset "gxb.local/backend/v2/internal/domain/profileasset"
	"gxb.local/backend/v2/internal/foundation/ids"
	"hash/crc32"
	"image"
	"image/color"
	"image/png"
	"io"
	"os"
	"path/filepath"
	"sync"
	"testing"
	"time"
)

func store(t *testing.T) *Local {
	t.Helper()
	s, e := NewLocal(filepath.Join(t.TempDir(), "assets"))
	if e != nil {
		t.Fatal(e)
	}
	return s
}
func reservation(n int) asset.Reservation {
	var u ids.UUID
	binary.BigEndian.PutUint64(u[8:], uint64(n))
	return asset.Reservation{Operation: u, Actor: identity.PlayerID(20000001), Server: identity.LogicalServerID(1)}
}
func encoded(t *testing.T, im image.Image) []byte {
	t.Helper()
	var b bytes.Buffer
	if e := png.Encode(&b, im); e != nil {
		t.Fatal(e)
	}
	return b.Bytes()
}
func sample(t *testing.T) []byte { return encoded(t, image.NewNRGBA(image.Rect(0, 0, 150, 150))) }
func prepare(t *testing.T, s *Local, b []byte, n int) port.PreparedAsset {
	t.Helper()
	p, e := s.Prepare(context.Background(), bytes.NewReader(b), reservation(n))
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(func() { p.Close(asset.Unknown) })
	return p
}
func descriptor(t *testing.T, p port.PreparedAsset) asset.Descriptor {
	t.Helper()
	d, e := p.Descriptor()
	if e != nil {
		t.Fatal(e)
	}
	return d
}
func chunk(name string, b []byte) []byte {
	out := make([]byte, 12+len(b))
	binary.BigEndian.PutUint32(out, uint32(len(b)))
	copy(out[4:8], name)
	copy(out[8:], b)
	binary.BigEndian.PutUint32(out[8+len(b):], crc32.ChecksumIEEE(out[4:8+len(b)]))
	return out
}
func header(w, h uint32) []byte {
	b := make([]byte, 13)
	binary.BigEndian.PutUint32(b, w)
	binary.BigEndian.PutUint32(b[4:], h)
	b[8] = 8
	b[9] = 6
	return append([]byte("\x89PNG\r\n\x1a\n"), chunk("IHDR", b)...)
}
func adam7() []byte {
	const w, h = 9, 9
	ih := make([]byte, 13)
	binary.BigEndian.PutUint32(ih, w)
	binary.BigEndian.PutUint32(ih[4:], h)
	ih[8] = 16
	ih[9] = 6
	ih[12] = 1
	var scan bytes.Buffer
	for _, p := range [][4]int{{0, 0, 8, 8}, {4, 0, 8, 8}, {0, 4, 4, 8}, {2, 0, 4, 4}, {0, 2, 2, 4}, {1, 0, 2, 2}, {0, 1, 1, 2}} {
		for y := p[1]; y < h; y += p[3] {
			scan.WriteByte(0)
			for x := p[0]; x < w; x += p[2] {
				scan.Write([]byte{0, byte(x), 0, byte(y), 0, 2, 255, 255})
			}
		}
	}
	var compressed bytes.Buffer
	z := zlib.NewWriter(&compressed)
	z.Write(scan.Bytes())
	z.Close()
	b := append([]byte("\x89PNG\r\n\x1a\n"), chunk("IHDR", ih)...)
	b = append(b, chunk("IDAT", compressed.Bytes())...)
	return append(b, chunk("IEND", nil)...)
}
func TestPNGVariantsBoundsAndInvalid(t *testing.T) {
	cases := []struct {
		name string
		im   image.Image
	}{{"rgba", image.NewRGBA(image.Rect(0, 0, 3, 2))}, {"rgb-opaque", image.NewUniform(color.RGBA{1, 2, 3, 255})}, {"gray", image.NewGray(image.Rect(0, 0, 4, 3))}, {"gray16", image.NewGray16(image.Rect(0, 0, 3, 3))}, {"rgba16", image.NewNRGBA64(image.Rect(0, 0, 2, 4))}, {"palette", image.NewPaletted(image.Rect(0, 0, 8, 2), color.Palette{color.Black, color.White})}}
	// Uniform's infinite bounds are replaced by an opaque finite image.
	rgb := image.NewRGBA(image.Rect(0, 0, 3, 2))
	for y := 0; y < 2; y++ {
		for x := 0; x < 3; x++ {
			rgb.Set(x, y, color.RGBA{1, 2, 3, 255})
		}
	}
	cases[1].im = rgb
	for i, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			s := store(t)
			b := encoded(t, c.im)
			p := prepare(t, s, b, i+1)
			d := descriptor(t, p)
			if d.Width != c.im.Bounds().Dx() || d.Height != c.im.Bounds().Dy() {
				t.Fatal(d)
			}
			p.Close(asset.DefiniteAbort)
		})
	}
	t.Run("adam7-rgba64", func(t *testing.T) {
		s := store(t)
		p := prepare(t, s, adam7(), 1)
		if descriptor(t, p).Width != 9 {
			t.Fatal("wrong Adam7")
		}
		p.Close(asset.DefiniteAbort)
	})
	b := sample(t)
	badCRC := append([]byte(nil), b...)
	badCRC[len(badCRC)-1] ^= 1
	badZlib := append([]byte(nil), b...)
	for i := 8; i < len(badZlib); {
		n := int(binary.BigEndian.Uint32(badZlib[i:]))
		if string(badZlib[i+4:i+8]) == "IDAT" {
			badZlib[i+8] ^= 0xff
			binary.BigEndian.PutUint32(badZlib[i+8+n:], crc32.ChecksumIEEE(badZlib[i+4:i+8+n]))
			break
		}
		i += 12 + n
	}
	for i, v := range [][]byte{nil, []byte("fake"), b[:20], b[:len(b)-4], append(append([]byte(nil), b...), 1), badCRC, badZlib, header(2049, 1), header(1, 2049), header(^uint32(0), ^uint32(0))} {
		s := store(t)
		if p, e := s.Prepare(context.Background(), bytes.NewReader(v), reservation(i+1)); e == nil || p != nil {
			t.Fatalf("bad %d accepted", i)
		}
	}
	t.Run("maximum-pixels", func(t *testing.T) {
		s := store(t)
		p := prepare(t, s, encoded(t, image.NewGray(image.Rect(0, 0, 2048, 2048))), 1)
		if d := descriptor(t, p); d.Width*d.Height != int(asset.MaxPixels) {
			t.Fatal(d)
		}
		p.Close(asset.DefiniteAbort)
	})
	t.Run("encoded-boundary", func(t *testing.T) {
		s := store(t)
		padding := make([]byte, int(asset.MaxBytes)-len(b)-12)
		large := append(append(append([]byte(nil), b[:len(b)-12]...), chunk("paDd", padding)...), b[len(b)-12:]...)
		p := prepare(t, s, large, 1)
		if descriptor(t, p).Size != asset.MaxBytes {
			t.Fatal("wrong size")
		}
		p.Close(asset.DefiniteAbort)
		if p, e := s.Prepare(context.Background(), bytes.NewReader(append(large, 0)), reservation(2)); p != nil || !errors.Is(e, asset.ErrInvalid) {
			t.Fatal(e)
		}
	})
}
func TestExactIdentityBindingAndLifecycle(t *testing.T) {
	s := store(t)
	b := sample(t)
	p := prepare(t, s, b, 1)
	d := descriptor(t, p)
	sha := sha256.Sum256(b)
	md := md5.Sum(b)
	if d.SHA256 != hex.EncodeToString(sha[:]) || d.MD5 != hex.EncodeToString(md[:]) {
		t.Fatal(d)
	}
	if p.ValidateBinding(s, reservation(1)) != nil || p.ValidateBinding(s, reservation(2)) == nil {
		t.Fatal("binding")
	}
	other := store(t)
	if p.ValidateBinding(other, reservation(1)) == nil {
		t.Fatal("store binding")
	}
	copyD := d
	copyD.MD5 = "ffffffffffffffffffffffffffffffff"
	if r, e := s.OpenValidated(context.Background(), copyD); r != nil || !errors.Is(e, asset.ErrIntegrity) {
		t.Fatal(e)
	}
	r, e := s.OpenValidated(context.Background(), d)
	if e != nil {
		t.Fatal(e)
	}
	raw, e := io.ReadAll(r)
	r.Close()
	if e != nil || !bytes.Equal(raw, b) {
		t.Fatal("changed bytes", e)
	}
	if second, e := s.Prepare(context.Background(), bytes.NewReader(b), reservation(1)); second != nil || !errors.Is(e, asset.ErrConflict) {
		t.Fatal(e)
	}
	if e = p.Close(asset.Unknown); e != nil {
		t.Fatal(e)
	}
	if e = p.Close(asset.DefiniteAbort); e != nil {
		t.Fatal(e)
	}
	if _, e = p.Descriptor(); !errors.Is(e, asset.ErrBinding) {
		t.Fatal("closed")
	}
	if _, e = s.readPin(s.pinPath(reservation(1))); e != nil {
		t.Fatal("unknown protection lost", e)
	}
	if e = s.WithMaintenance(context.Background(), func(m port.Maintenance) error { return m.Delete(d) }); !errors.Is(e, asset.ErrConflict) {
		t.Fatal(e)
	}
}
func TestIndependentPermitsAndMaintenanceLifetime(t *testing.T) {
	s := store(t)
	b := sample(t)
	p := prepare(t, s, b, 1)
	q := prepare(t, s, b, 2)
	d := descriptor(t, p)
	inode, _ := os.Stat(s.path(".coord.lock"))
	p.Close(asset.DefiniteAbort)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Millisecond)
	defer cancel()
	if e := s.WithMaintenance(ctx, func(port.Maintenance) error { t.Fatal("exclusive while live"); return nil }); !errors.Is(e, context.DeadlineExceeded) {
		t.Fatal(e)
	}
	q.Close(asset.VerifiedCommit)
	var escaped port.Maintenance
	var reader io.ReadSeekCloser
	e := s.WithMaintenance(context.Background(), func(m port.Maintenance) error {
		escaped = m
		return m.Inventory(func(got asset.Descriptor) error { var e error; reader, e = m.OpenValidated(got); return e }, nil)
	})
	if e != nil {
		t.Fatal(e)
	}
	if _, e = reader.Read(make([]byte, 1)); !errors.Is(e, asset.ErrBinding) {
		t.Fatal("escaped reader", e)
	}
	reader.Close()
	if e = escaped.Delete(d); !errors.Is(e, asset.ErrBinding) {
		t.Fatal("escaped delete", e)
	}
	after, _ := os.Stat(s.path(".coord.lock"))
	if !os.SameFile(inode, after) {
		t.Fatal("lock inode changed")
	}
	if e = s.WithMaintenance(context.Background(), func(m port.Maintenance) error { return m.Delete(d) }); e != nil {
		t.Fatal(e)
	}
	if r, e := s.OpenValidated(context.Background(), d); r != nil || !errors.Is(e, asset.ErrIntegrity) {
		t.Fatal("missing did not fail", e)
	}
}
func TestConcurrentDedupAndExclusiveOperation(t *testing.T) {
	s := store(t)
	b := sample(t)
	var wg sync.WaitGroup
	errs := make(chan error, 16)
	for i := 1; i <= 16; i++ {
		wg.Add(1)
		go func(n int) {
			defer wg.Done()
			p, e := s.Prepare(context.Background(), bytes.NewReader(b), reservation(n))
			if e == nil {
				e = p.Close(asset.Unknown)
			}
			errs <- e
		}(i)
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	blobs, pins := 0, 0
	if e := s.WithMaintenance(context.Background(), func(m port.Maintenance) error {
		return m.Inventory(func(asset.Descriptor) error { blobs++; return nil }, func(asset.Pin) error { pins++; return nil })
	}); e != nil || blobs != 1 || pins != 16 {
		t.Fatal(blobs, pins, e)
	}
	s2 := store(t)
	results := make(chan port.PreparedAsset, 8)
	errs2 := make(chan error, 8)
	for i := 0; i < 8; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			p, e := s2.Prepare(context.Background(), bytes.NewReader(b), reservation(1))
			results <- p
			errs2 <- e
		}()
	}
	wg.Wait()
	close(results)
	close(errs2)
	count := 0
	for p := range results {
		if p != nil {
			count++
			p.Close(asset.Unknown)
		}
	}
	if count != 1 {
		t.Fatal("duplicate permits", count)
	}
	for e := range errs2 {
		if e != nil && !errors.Is(e, asset.ErrConflict) {
			t.Fatal(e)
		}
	}
}
func TestIntegrityPinsAndUnpinFailure(t *testing.T) {
	for _, mode := range []string{"bytes", "symlink", "writable"} {
		t.Run(mode, func(t *testing.T) {
			s := store(t)
			b := sample(t)
			p := prepare(t, s, b, 1)
			d := descriptor(t, p)
			p.Close(asset.DefiniteAbort)
			path := s.path("blobs/" + d.SHA256 + ".png")
			switch mode {
			case "bytes":
				os.Chmod(path, 0600)
				os.WriteFile(path, []byte("bad"), 0400)
				os.Chmod(path, 0400)
			case "symlink":
				os.Remove(path)
				os.Symlink(filepath.Join(t.TempDir(), "outside"), path)
			case "writable":
				os.Chmod(path, 0600)
			}
			if r, e := s.OpenValidated(context.Background(), d); r != nil || !errors.Is(e, asset.ErrIntegrity) {
				t.Fatal(e)
			}
			if p, e := s.Prepare(context.Background(), bytes.NewReader(b), reservation(2)); p != nil || !errors.Is(e, asset.ErrIntegrity) {
				t.Fatal("dedup trusted corrupt target", e)
			}
		})
	}
	s := store(t)
	p := prepare(t, s, sample(t), 1)
	d := descriptor(t, p)
	fail := true
	old := s.syncFile
	s.syncFile = func(f *os.File) error {
		if filepath.Base(f.Name()) == "pins" && fail {
			fail = false
			return errors.New("injected directory sync failure")
		}
		return old(f)
	}
	if e := p.Close(asset.DefiniteAbort); e == nil {
		t.Fatal("cleanup should fail")
	}
	if _, e := s.readPin(s.pinPath(reservation(1))); e != nil {
		t.Fatal("failed unpin lost protection", e)
	}
	os.WriteFile(s.pinPath(reservation(1)), []byte("bad pin"), 0600)
	if e := s.WithMaintenance(context.Background(), func(m port.Maintenance) error { return m.Inventory(nil, nil) }); !errors.Is(e, asset.ErrIntegrity) {
		t.Fatal(e)
	}
	if e := s.WithMaintenance(context.Background(), func(m port.Maintenance) error { return m.Delete(d) }); !errors.Is(e, asset.ErrIntegrity) {
		t.Fatal(e)
	}
}
func TestDurabilityFailureNoReady(t *testing.T) {
	for _, at := range []string{"staging-file", "blobs", "pins-file", "pins"} {
		t.Run(at, func(t *testing.T) {
			s := store(t)
			old := s.syncFile
			s.syncFile = func(f *os.File) error {
				base := filepath.Base(f.Name())
				if (at == "staging-file" && len(base) > 4 && base[:4] == "png-") || (at == "pins-file" && filepath.Ext(base) == ".json") || base == at {
					return errors.New("injected sync failure")
				}
				return old(f)
			}
			p, e := s.Prepare(context.Background(), bytes.NewReader(sample(t)), reservation(1))
			if p != nil || e == nil {
				t.Fatal("Ready on durability failure")
			}
		})
	}
}

type blocked struct {
	started chan struct{}
	release chan struct{}
	r       io.Reader
	once    sync.Once
}

func (b *blocked) Read(p []byte) (int, error) {
	b.once.Do(func() { close(b.started); <-b.release })
	return b.r.Read(p)
}
func TestAdmissionAndCancellation(t *testing.T) {
	s := store(t)
	b := sample(t)
	var wg sync.WaitGroup
	blocks := []*blocked{}
	errc := make(chan error, 2)
	for i := 0; i < 2; i++ {
		x := &blocked{started: make(chan struct{}), release: make(chan struct{}), r: bytes.NewReader(b)}
		blocks = append(blocks, x)
		wg.Add(1)
		go func(n int) {
			defer wg.Done()
			p, e := s.Prepare(context.Background(), x, reservation(n+1))
			if p != nil {
				p.Close(asset.DefiniteAbort)
			}
			errc <- e
		}(i)
		<-x.started
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Millisecond)
	defer cancel()
	if p, e := s.Prepare(ctx, bytes.NewReader(b), reservation(3)); p != nil || !errors.Is(e, context.DeadlineExceeded) {
		t.Fatal("admission", e)
	}
	for _, x := range blocks {
		close(x.release)
	}
	wg.Wait()
	close(errc)
	for e := range errc {
		if e != nil {
			t.Fatal(e)
		}
	}
	ctx2, stop := context.WithCancel(context.Background())
	x := &blocked{started: make(chan struct{}), release: make(chan struct{}), r: bytes.NewReader(b)}
	done := make(chan error, 1)
	go func() {
		p, e := s.Prepare(ctx2, x, reservation(4))
		if p != nil {
			e = errors.New("Ready after cancellation")
		}
		done <- e
	}()
	<-x.started
	stop()
	close(x.release)
	if e := <-done; !errors.Is(e, context.Canceled) {
		t.Fatal(e)
	}
	if _, e := os.Stat(s.pinPath(reservation(4))); !errors.Is(e, os.ErrNotExist) {
		t.Fatal("cancelled pin", e)
	}
	lock, e := s.lock(context.Background(), true)
	if e != nil {
		t.Fatal(e)
	}
	ctx3, c3 := context.WithTimeout(context.Background(), 20*time.Millisecond)
	defer c3()
	if p, e := s.Prepare(ctx3, bytes.NewReader(b), reservation(5)); p != nil || !errors.Is(e, context.DeadlineExceeded) {
		t.Fatal("shared wait", e)
	}
	unlock(lock)
}
func TestQualifiedPinResolutionAndMissingExpectedPin(t *testing.T) {
	s := store(t)
	p := prepare(t, s, sample(t), 1)
	d := descriptor(t, p)
	p.Close(asset.Unknown)
	pin := asset.Pin{Reservation: reservation(1), Asset: d}
	if e := s.WithMaintenance(context.Background(), func(m port.Maintenance) error { return m.ResolvePin(pin, asset.Unknown) }); !errors.Is(e, asset.ErrBinding) {
		t.Fatal(e)
	}
	altered := pin
	altered.Reservation.Actor++
	if e := s.WithMaintenance(context.Background(), func(m port.Maintenance) error { return m.ResolvePin(altered, asset.VerifiedCommit) }); !errors.Is(e, asset.ErrIntegrity) {
		t.Fatal(e)
	}
	if e := s.WithMaintenance(context.Background(), func(m port.Maintenance) error {
		if e := m.ResolvePin(pin, asset.DefiniteAbort); e != nil {
			return e
		}
		return m.Delete(d)
	}); e != nil {
		t.Fatal(e)
	}
	q := prepare(t, s, sample(t), 2)
	os.Remove(s.pinPath(reservation(2)))
	if e := q.Close(asset.VerifiedCommit); !errors.Is(e, asset.ErrIntegrity) {
		t.Fatal(e)
	}
	if _, e := s.readPin(s.pinPath(reservation(2))); e != nil {
		t.Fatal("missing expected pin not restored", e)
	}
}
