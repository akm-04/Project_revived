//go:build linux

package blobstore

import (
	"context"
	"errors"
	port "gxb.local/backend/v2/internal/application/profileasset"
	asset "gxb.local/backend/v2/internal/domain/profileasset"
	"io"
	"os"
	"strings"
	"sync"
)

type maintenance struct {
	mu    sync.Mutex
	local *Local
	ctx   context.Context
	live  bool
}

func (l *Local) WithMaintenance(ctx context.Context, fn func(port.Maintenance) error) (err error) {
	if fn == nil {
		return asset.ErrBinding
	}
	lock, e := l.lock(ctx, true)
	if e != nil {
		return e
	}
	m := &maintenance{local: l, ctx: ctx, live: true}
	defer func() { m.mu.Lock(); m.live = false; m.mu.Unlock(); err = errors.Join(err, unlock(lock)) }()
	return fn(m)
}
func entries(ctx context.Context, path string, fn func(os.DirEntry) error) error {
	d, e := os.Open(path)
	if e != nil {
		return e
	}
	defer d.Close()
	for {
		if e = ctx.Err(); e != nil {
			return e
		}
		es, e := d.ReadDir(64)
		if e != nil && e != io.EOF {
			return e
		}
		for _, x := range es {
			if er := fn(x); er != nil {
				return er
			}
		}
		if e == io.EOF {
			return nil
		}
	}
}
func (m *maintenance) valid() error {
	if !m.live {
		return asset.ErrBinding
	}
	return m.ctx.Err()
}
func (m *maintenance) pins(fn func(asset.Pin) error) error {
	return entries(m.ctx, m.local.path("pins"), func(x os.DirEntry) error {
		p, e := m.local.readPin(m.local.path("pins/" + x.Name()))
		if e != nil {
			return e
		}
		if fn != nil {
			return fn(p)
		}
		return nil
	})
}

// walk checks lifetime around directory I/O and lets callbacks use other ports.
func (m *maintenance) walk(dir string, fn func(os.DirEntry) error) error {
	m.mu.Lock()
	if e := m.valid(); e != nil {
		m.mu.Unlock()
		return e
	}
	d, e := os.Open(m.local.path(dir))
	m.mu.Unlock()
	if e != nil {
		return e
	}
	defer d.Close()
	for {
		m.mu.Lock()
		if e = m.valid(); e != nil {
			m.mu.Unlock()
			return e
		}
		es, er := d.ReadDir(64)
		m.mu.Unlock()
		if er != nil && er != io.EOF {
			return er
		}
		for _, x := range es {
			if e = fn(x); e != nil {
				return e
			}
		}
		if er == io.EOF {
			return nil
		}
	}
}
func (m *maintenance) Inventory(blob func(asset.Descriptor) error, pin func(asset.Pin) error) error {
	m.mu.Lock()
	e := m.valid()
	if e == nil {
		e = m.pins(nil)
	}
	m.mu.Unlock()
	if e != nil {
		return e
	}
	if e = m.walk("pins", func(x os.DirEntry) error {
		m.mu.Lock()
		e := m.valid()
		var p asset.Pin
		if e == nil {
			p, e = m.local.readPin(m.local.path("pins/" + x.Name()))
		}
		m.mu.Unlock()
		if e != nil {
			return e
		}
		if pin != nil {
			return pin(p)
		}
		return nil
	}); e != nil {
		return e
	}
	return m.walk("blobs", func(x os.DirEntry) error {
		m.mu.Lock()
		e := m.valid()
		var d asset.Descriptor
		if e == nil {
			name := x.Name()
			if !strings.HasSuffix(name, ".png") {
				e = asset.ErrIntegrity
			} else {
				f, er := openPrivate(m.local.path("blobs/"+name), 0, 0)
				e = er
				if e == nil {
					d, e = metadata(m.ctx, f)
					if e == nil && name != d.SHA256+".png" {
						e = asset.ErrIntegrity
					}
					fi, er := f.Stat()
					if er != nil || fi.Mode().Perm() != 0400 {
						e = asset.ErrIntegrity
					}
					f.Close()
				}
			}
		}
		m.mu.Unlock()
		if e != nil {
			return errors.Join(asset.ErrIntegrity, e)
		}
		if blob != nil {
			return blob(d)
		}
		return nil
	})
}
func (m *maintenance) OpenValidated(d asset.Descriptor) (io.ReadSeekCloser, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if e := m.valid(); e != nil {
		return nil, e
	}
	f, e := m.local.openValidated(m.ctx, d)
	if e != nil {
		return nil, e
	}
	return &maintenanceReader{m: m, f: f}, nil
}

// Every read/seek checks the maintenance lifetime; exporting a handle never
// grants usable filesystem access after the exclusive callback has ended.
type maintenanceReader struct {
	m *maintenance
	f *os.File
}

func (r *maintenanceReader) Read(b []byte) (int, error) {
	r.m.mu.Lock()
	defer r.m.mu.Unlock()
	if e := r.m.valid(); e != nil {
		return 0, e
	}
	return checkedReader{r.m.ctx, r.f}.Read(b)
}
func (r *maintenanceReader) Seek(n int64, w int) (int64, error) {
	r.m.mu.Lock()
	defer r.m.mu.Unlock()
	if e := r.m.valid(); e != nil {
		return 0, e
	}
	return r.f.Seek(n, w)
}
func (r *maintenanceReader) Close() error { return r.f.Close() }
func (m *maintenance) Delete(d asset.Descriptor) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if e := m.valid(); e != nil {
		return e
	}
	protected := false
	if e := m.pins(func(p asset.Pin) error {
		if p.Asset.SHA256 == d.SHA256 {
			protected = true
		}
		return nil
	}); e != nil {
		return e
	}
	if protected {
		return asset.ErrConflict
	}
	f, e := m.local.openValidated(m.ctx, d)
	if e != nil {
		return e
	}
	f.Close()
	if e = os.Remove(m.local.path("blobs/" + d.SHA256 + ".png")); e != nil {
		return e
	}
	return m.local.syncDir(m.local.path("blobs"))
}
func (m *maintenance) CleanStaging() error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if e := m.valid(); e != nil {
		return e
	}
	if e := m.pins(nil); e != nil {
		return e
	}
	e := entries(m.ctx, m.local.path("staging"), func(x os.DirEntry) error {
		if !strings.HasPrefix(x.Name(), "png-") {
			return asset.ErrIntegrity
		}
		f, e := openPrivate(m.local.path("staging/"+x.Name()), 0, 0)
		if e != nil {
			return e
		}
		f.Close()
		return os.Remove(m.local.path("staging/" + x.Name()))
	})
	if e != nil {
		return e
	}
	return m.local.syncDir(m.local.path("staging"))
}

func (m *maintenance) ResolvePin(pin asset.Pin, out asset.Outcome) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if e := m.valid(); e != nil {
		return e
	}
	if pin.Validate() != nil || (out != asset.DefiniteAbort && out != asset.VerifiedCommit) {
		return asset.ErrBinding
	}
	// Fail closed for any corrupt physical protection metadata before cleanup.
	if e := m.pins(nil); e != nil {
		return e
	}
	return m.local.removePin(pin)
}
