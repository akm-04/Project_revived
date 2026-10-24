//go:build linux

package blobstore

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	port "gxb.local/backend/v2/internal/application/profileasset"
	asset "gxb.local/backend/v2/internal/domain/profileasset"
	"io"
	"os"
	"path/filepath"
	"sync"
	"syscall"
	"time"
)

const format = "{\"format\":\"PROFILE_ASSET_STORE_V1\"}\n"
const pinMax = 4096

// Local is composed once per configured shared store. Independent instances or
// processes share filesystem coordination; admission slots are per instance.
type Local struct {
	root     string
	slots    chan struct{}
	syncFile func(*os.File) error
}

var _ port.Store = (*Local)(nil)

func NewLocal(root string) (*Local, error) {
	if !filepath.IsAbs(root) {
		return nil, fmt.Errorf("asset root must be absolute")
	}
	l := &Local{root: filepath.Clean(root), slots: make(chan struct{}, asset.PrepareSlots), syncFile: func(f *os.File) error { return f.Sync() }}
	if e := os.MkdirAll(l.root, 0700); e != nil {
		return nil, e
	}
	if e := privateDir(l.root); e != nil {
		return nil, e
	}
	lock, e := l.lock(context.Background(), true)
	if e != nil {
		return nil, e
	}
	defer unlock(lock)
	for _, n := range []string{"staging", "blobs", "pins"} {
		p := l.path(n)
		if e = os.Mkdir(p, 0700); e != nil && !errors.Is(e, os.ErrExist) {
			return nil, e
		}
		if e = privateDir(p); e != nil {
			return nil, e
		}
		a, _ := os.Stat(l.root)
		b, _ := os.Stat(p)
		if a.Sys().(*syscall.Stat_t).Dev != b.Sys().(*syscall.Stat_t).Dev {
			return nil, fmt.Errorf("asset paths must share filesystem")
		}
	}
	p := l.path("format.json")
	f, e := openPrivate(p, syscall.O_RDONLY, 0)
	if errors.Is(e, os.ErrNotExist) {
		t, er := os.CreateTemp(l.root, ".format-")
		if er != nil {
			return nil, er
		}
		defer os.Remove(t.Name())
		if _, er = t.WriteString(format); er == nil {
			er = l.syncFile(t)
		}
		ce := t.Close()
		if er != nil {
			return nil, er
		}
		if ce != nil {
			return nil, ce
		}
		if er = os.Link(t.Name(), p); er != nil {
			return nil, er
		}
		if er = l.syncDir(l.root); er != nil {
			return nil, er
		}
	} else if e != nil {
		return nil, e
	} else {
		raw, er := io.ReadAll(io.LimitReader(f, 128))
		f.Close()
		if er != nil || !bytes.Equal(raw, []byte(format)) {
			return nil, asset.ErrIntegrity
		}
	}
	if e = l.syncDir(l.root); e != nil {
		return nil, e
	}
	return l, nil
}
func (l *Local) path(n string) string { return filepath.Join(l.root, n) }
func privateDir(p string) error {
	fi, e := os.Lstat(p)
	if e != nil {
		return e
	}
	if !fi.IsDir() || fi.Mode().Perm()&0077 != 0 || fi.Sys().(*syscall.Stat_t).Uid != uint32(os.Geteuid()) {
		return asset.ErrIntegrity
	}
	return nil
}
func openPrivate(p string, flags int, mode uint32) (*os.File, error) {
	fd, e := syscall.Open(p, flags|syscall.O_NOFOLLOW|syscall.O_CLOEXEC, mode)
	if e != nil {
		return nil, e
	}
	f := os.NewFile(uintptr(fd), p)
	fi, e := f.Stat()
	if e != nil || !fi.Mode().IsRegular() || fi.Mode().Perm()&0077 != 0 || fi.Sys().(*syscall.Stat_t).Uid != uint32(os.Geteuid()) {
		f.Close()
		return nil, asset.ErrIntegrity
	}
	return f, nil
}
func (l *Local) syncDir(p string) error {
	f, e := os.Open(p)
	if e != nil {
		return e
	}
	defer f.Close()
	return l.syncFile(f)
}
func (l *Local) lock(ctx context.Context, exclusive bool) (*os.File, error) {
	if e := ctx.Err(); e != nil {
		return nil, e
	}
	f, e := openPrivate(l.path(".coord.lock"), syscall.O_RDWR|syscall.O_CREAT, 0600)
	if e != nil {
		return nil, e
	}
	how := syscall.LOCK_SH
	if exclusive {
		how = syscall.LOCK_EX
	}
	for {
		e = syscall.Flock(int(f.Fd()), how|syscall.LOCK_NB)
		if e == nil {
			if e = ctx.Err(); e == nil {
				return f, nil
			}
			unlock(f)
			return nil, e
		}
		if e != syscall.EWOULDBLOCK && e != syscall.EAGAIN {
			f.Close()
			return nil, e
		}
		timer := time.NewTimer(5 * time.Millisecond)
		select {
		case <-ctx.Done():
			timer.Stop()
			f.Close()
			return nil, ctx.Err()
		case <-timer.C:
		}
	}
}
func unlock(f *os.File) error {
	if f == nil {
		return nil
	}
	return errors.Join(syscall.Flock(int(f.Fd()), syscall.LOCK_UN), f.Close())
}
func (l *Local) pinPath(r asset.Reservation) string {
	return l.path("pins/" + r.Operation.String() + ".json")
}
func (l *Local) writePin(p asset.Pin) error {
	f, e := openPrivate(l.pinPath(p.Reservation), syscall.O_WRONLY|syscall.O_CREAT|syscall.O_EXCL, 0600)
	if errors.Is(e, os.ErrExist) {
		return asset.ErrConflict
	}
	if e != nil {
		return e
	}
	raw, _ := json.Marshal(p)
	_, e = f.Write(raw)
	if e == nil {
		e = l.syncFile(f)
	}
	ce := f.Close()
	if e == nil {
		e = ce
	}
	if e == nil {
		e = l.syncDir(l.path("pins"))
	}
	return e
}
func (l *Local) readPin(p string) (asset.Pin, error) {
	var pin asset.Pin
	f, e := openPrivate(p, syscall.O_RDONLY, 0)
	if e != nil {
		return pin, errors.Join(asset.ErrIntegrity, e)
	}
	defer f.Close()
	raw, e := io.ReadAll(io.LimitReader(f, pinMax+1))
	if e != nil || len(raw) > pinMax {
		return pin, asset.ErrIntegrity
	}
	d := json.NewDecoder(bytes.NewReader(raw))
	d.DisallowUnknownFields()
	if d.Decode(&pin) != nil || d.Decode(new(any)) != io.EOF || pin.Validate() != nil || filepath.Base(p) != pin.Reservation.Operation.String()+".json" {
		return pin, asset.ErrIntegrity
	}
	return pin, nil
}

type prepared struct {
	mu       sync.Mutex
	local    *Local
	pin      asset.Pin
	lock     *os.File
	closed   bool
	closeErr error
}

func (p *prepared) Descriptor() (asset.Descriptor, error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.closed {
		return asset.Descriptor{}, asset.ErrBinding
	}
	return p.pin.Asset, nil
}
func (p *prepared) ValidateBinding(s port.Store, r asset.Reservation) error {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.closed || s != p.local || r != p.pin.Reservation {
		return asset.ErrBinding
	}
	return nil
}
func (p *prepared) Close(out asset.Outcome) error {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.closed {
		return p.closeErr
	}
	p.closed = true
	if out == asset.DefiniteAbort || out == asset.VerifiedCommit {
		p.closeErr = p.local.removePin(p.pin)
	}

	p.closeErr = errors.Join(p.closeErr, unlock(p.lock))
	p.lock = nil
	return p.closeErr
}

// removePin verifies the exact protection record and restores it on uncertain
// cleanup durability. A missing expected pin is an integrity failure, not proof
// that an earlier semantic operation rolled back.
func (l *Local) removePin(pin asset.Pin) error {
	got, e := l.readPin(l.pinPath(pin.Reservation))
	if e != nil {
		if errors.Is(e, os.ErrNotExist) {
			return errors.Join(e, l.writePin(pin))
		}
		return e
	}
	if got != pin {
		return asset.ErrIntegrity
	}
	if e = os.Remove(l.pinPath(pin.Reservation)); e != nil {
		return e
	}
	if e = l.syncDir(l.path("pins")); e != nil {
		return errors.Join(e, l.writePin(pin))
	}
	return nil
}
