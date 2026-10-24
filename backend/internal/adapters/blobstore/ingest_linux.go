//go:build linux

package blobstore

import (
	"context"
	"crypto/md5"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	port "gxb.local/backend/v2/internal/application/profileasset"
	asset "gxb.local/backend/v2/internal/domain/profileasset"
	"image/png"
	"io"
	"os"
	"syscall"
	"time"
)

type checkedReader struct {
	ctx context.Context
	r   io.Reader
}

func (r checkedReader) Read(p []byte) (int, error) {
	if e := r.ctx.Err(); e != nil {
		return 0, e
	}
	n, e := r.r.Read(p)
	if ce := r.ctx.Err(); ce != nil {
		return n, ce
	}
	return n, e
}
func metadata(ctx context.Context, f *os.File) (asset.Descriptor, error) {
	var d asset.Descriptor
	if e := ctx.Err(); e != nil {
		return d, e
	}
	fi, e := f.Stat()
	if e != nil {
		return d, e
	}
	if fi.Size() < 1 || fi.Size() > asset.MaxBytes {
		return d, asset.ErrInvalid
	}
	if _, e = f.Seek(0, 0); e != nil {
		return d, e
	}
	cfg, e := png.DecodeConfig(checkedReader{ctx, f})
	if e != nil {
		return d, errors.Join(asset.ErrInvalid, e)
	}
	if cfg.Width < 1 || cfg.Height < 1 || cfg.Width > asset.MaxDimension || cfg.Height > asset.MaxDimension || uint64(cfg.Width)*uint64(cfg.Height) > asset.MaxPixels {
		return d, asset.ErrInvalid
	}
	if _, e = f.Seek(0, 0); e != nil {
		return d, e
	}
	if _, e = png.Decode(checkedReader{ctx, f}); e != nil {
		return d, errors.Join(asset.ErrInvalid, e)
	}
	var b [1]byte
	n, e := checkedReader{ctx, f}.Read(b[:])
	if n != 0 || e != io.EOF {
		return d, errors.Join(asset.ErrInvalid, e)
	}
	if _, e = f.Seek(0, 0); e != nil {
		return d, e
	}
	sha := sha256.New()
	md := md5.New()
	if _, e = io.Copy(io.MultiWriter(sha, md), checkedReader{ctx, f}); e != nil {
		return d, e
	}
	d = asset.Descriptor{Policy: asset.Policy, SHA256: hex.EncodeToString(sha.Sum(nil)), MD5: hex.EncodeToString(md.Sum(nil)), Size: fi.Size(), Width: cfg.Width, Height: cfg.Height}
	_, e = f.Seek(0, 0)
	return d, e
}
func (l *Local) Prepare(ctx context.Context, input io.Reader, r asset.Reservation) (port.PreparedAsset, error) {
	if r.Validate() != nil || input == nil {
		return nil, asset.ErrBinding
	}
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	select {
	case l.slots <- struct{}{}:
	case <-ctx.Done():
		return nil, ctx.Err()
	}
	defer func() { <-l.slots }()
	lock, e := l.lock(ctx, false)
	if e != nil {
		return nil, e
	}
	ready := false
	defer func() {
		if !ready {
			unlock(lock)
		}
	}()
	// Refuse any pre-existing operation, including matching content and malformed
	// records. Replays/reconciliation are the future business caller's task.
	if _, e = os.Lstat(l.pinPath(r)); e == nil {
		return nil, asset.ErrConflict
	} else if !errors.Is(e, os.ErrNotExist) {
		return nil, e
	}
	stage, e := os.CreateTemp(l.path("staging"), "png-")
	if e != nil {
		return nil, e
	}
	defer func() { stage.Close(); os.Remove(stage.Name()); l.syncDir(l.path("staging")) }()
	copySHA, copyMD5 := sha256.New(), md5.New()
	n, e := io.Copy(io.MultiWriter(stage, copySHA, copyMD5), io.LimitReader(checkedReader{ctx, input}, asset.MaxBytes+1))
	if e != nil {
		return nil, e
	}
	if n > asset.MaxBytes {
		return nil, asset.ErrInvalid
	}
	d, e := metadata(ctx, stage)
	if e == nil && (d.SHA256 != hex.EncodeToString(copySHA.Sum(nil)) || d.MD5 != hex.EncodeToString(copyMD5.Sum(nil))) {
		e = asset.ErrIntegrity
	}
	if e != nil {
		return nil, e
	}
	if e = ctx.Err(); e != nil {
		return nil, e
	}
	if e = stage.Chmod(0400); e != nil {
		return nil, e
	}
	if e = l.syncFile(stage); e != nil {
		return nil, e
	}
	target := l.path("blobs/" + d.SHA256 + ".png")
	e = os.Link(stage.Name(), target)
	if errors.Is(e, os.ErrExist) {
		f, er := l.openValidated(ctx, d)
		if er != nil {
			return nil, er
		}
		f.Close()
	} else if e != nil {
		return nil, e
	}
	if e = l.syncDir(l.path("blobs")); e != nil {
		return nil, e
	}
	if e = os.Remove(stage.Name()); e != nil {
		return nil, e
	}
	if e = l.syncDir(l.path("staging")); e != nil {
		return nil, e
	}
	if e = ctx.Err(); e != nil {
		return nil, e
	}
	pin := asset.Pin{Reservation: r, Asset: d}
	if e = l.writePin(pin); e != nil {
		return nil, e
	}
	if e = ctx.Err(); e != nil {
		return nil, e
	} // retain pin on uncertain cancellation
	ready = true
	return &prepared{local: l, pin: pin, lock: lock}, nil
}
func (l *Local) openValidated(ctx context.Context, d asset.Descriptor) (*os.File, error) {
	if d.Validate() != nil {
		return nil, asset.ErrIntegrity
	}
	f, e := openPrivate(l.path("blobs/"+d.SHA256+".png"), syscall.O_RDONLY, 0)
	if e != nil {
		return nil, errors.Join(asset.ErrIntegrity, e)
	}
	fi, e := f.Stat()
	if e != nil || fi.Mode().Perm() != 0400 {
		f.Close()
		return nil, asset.ErrIntegrity
	}
	got, e := metadata(ctx, f)
	if e != nil || got != d {
		f.Close()
		return nil, errors.Join(asset.ErrIntegrity, e)
	}
	return f, nil
}

type reader struct {
	file *os.File
	lock *os.File
	ctx  context.Context
}

func (r *reader) Read(p []byte) (int, error) { return checkedReader{r.ctx, r.file}.Read(p) }
func (r *reader) Seek(n int64, w int) (int64, error) {
	if e := r.ctx.Err(); e != nil {
		return 0, e
	}
	return r.file.Seek(n, w)
}
func (r *reader) Close() error { return errors.Join(r.file.Close(), unlock(r.lock)) }
func (l *Local) OpenValidated(ctx context.Context, d asset.Descriptor) (port.Reader, error) {
	lock, e := l.lock(ctx, false)
	if e != nil {
		return nil, e
	}
	f, e := l.openValidated(ctx, d)
	if e != nil {
		unlock(lock)
		return nil, e
	}
	return &reader{file: f, lock: lock, ctx: ctx}, nil
}
