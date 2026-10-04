package stockruntime

import (
	"context"
	"errors"
	"io"
	"net"
	"sync"
	"time"

	"gxb.local/backend/v2/internal/protocol/limits"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

var ErrRealtimeWriterClosed = errors.New("realtime writer closed")

type outboundWrite struct {
	data []byte
	done chan error
}

// connWriter is one bounded single-writer loop per admitted socket. Multiple
// callers may enqueue, but only this loop touches conn.Write.
type connWriter struct {
	conn         net.Conn
	writeTimeout time.Duration
	queue        chan outboundWrite
	maxBytes     int
	mu           sync.Mutex
	queuedBytes  int
	closed       bool
	cancel       context.CancelFunc
	done         chan struct{}
}

func newConnWriter(parent context.Context, conn net.Conn, cfg limits.Config, writeTimeout time.Duration) (*connWriter, error) {
	if conn == nil || cfg.WriterFrames <= 0 || cfg.WriterBytes <= 0 || writeTimeout <= 0 {
		return nil, errors.New("invalid realtime writer configuration")
	}
	ctx, cancel := context.WithCancel(parent)
	w := &connWriter{conn: conn, writeTimeout: writeTimeout, queue: make(chan outboundWrite, cfg.WriterFrames), maxBytes: cfg.WriterBytes, cancel: cancel, done: make(chan struct{})}
	go w.run(ctx)
	return w, nil
}

func (w *connWriter) reserve(n int) error {
	w.mu.Lock()
	defer w.mu.Unlock()
	if w.closed {
		return ErrRealtimeWriterClosed
	}
	if n <= 0 || n > w.maxBytes || w.queuedBytes+n > w.maxBytes {
		return wireRT.ErrQueueFull
	}
	w.queuedBytes += n
	return nil
}
func (w *connWriter) release(n int) {
	w.mu.Lock()
	w.queuedBytes -= n
	w.mu.Unlock()
}

func (w *connWriter) Send(ctx context.Context, frame wireRT.Frame, cfg limits.Config) error {
	done, err := w.enqueue(ctx, frame, cfg)
	if err != nil {
		return err
	}
	return w.await(ctx, done)
}

// enqueue performs bounded frame admission without waiting for network I/O.
// I7A-2 session retirement uses this narrow seam to linearize "may this stale
// handle enqueue?" without holding a lifecycle mutex while conn.Write blocks.
func (w *connWriter) enqueue(ctx context.Context, frame wireRT.Frame, cfg limits.Config) (<-chan error, error) {
	b, err := wireRT.EncodeFrameWithConfig(frame, cfg)
	if err != nil {
		return nil, err
	}
	if err := w.reserve(len(b)); err != nil {
		return nil, err
	}
	req := outboundWrite{data: b, done: make(chan error, 1)}
	select {
	case w.queue <- req:
		return req.done, nil
	case <-ctx.Done():
		w.release(len(b))
		return nil, ctx.Err()
	default:
		w.release(len(b))
		return nil, wireRT.ErrQueueFull
	}
}

func (w *connWriter) await(ctx context.Context, done <-chan error) error {
	if done == nil {
		return ErrRealtimeWriterClosed
	}
	select {
	case err := <-done:
		return err
	case <-ctx.Done():
		return ctx.Err()
	case <-w.done:
		return ErrRealtimeWriterClosed
	}
}

func (w *connWriter) run(ctx context.Context) {
	defer close(w.done)
	for {
		select {
		case <-ctx.Done():
			w.mu.Lock()
			w.closed = true
			w.mu.Unlock()
			return
		case req := <-w.queue:
			err := writeFrameBytes(w.conn, req.data, w.writeTimeout)
			w.release(len(req.data))
			req.done <- err
			if err != nil {
				w.mu.Lock()
				w.closed = true
				w.mu.Unlock()
				return
			}
		}
	}
}

func (w *connWriter) Close() {
	if w == nil {
		return
	}
	w.cancel()
	<-w.done
}

func writeFrameBytes(conn net.Conn, b []byte, timeout time.Duration) error {
	_ = conn.SetWriteDeadline(time.Now().Add(timeout))
	defer conn.SetWriteDeadline(time.Time{})
	for len(b) > 0 {
		n, err := conn.Write(b)
		if err != nil {
			return err
		}
		if n <= 0 {
			return io.ErrShortWrite
		}
		b = b[n:]
	}
	return nil
}
