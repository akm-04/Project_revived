// Package combatworker runs each resolution in its own single-use
// gxb-combat-worker process with an empty environment and working directory,
// no inherited descriptors beyond stdio, enforced resource limits, a
// process-group wall deadline and bounded output. At most a configured number
// of worker processes are alive; a spare prepares its attempt-independent
// state before any attempt is handed to it (I8-2B). It classifies failures for
// the Combat owner.
package combatworker

import (
	"bytes"
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strconv"
	"sync"
	"syscall"
	"time"

	"gxb.local/backend/v2/internal/adapters/combatresolver"
	app "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/combat"
)

const maxStderrBytes = 64 << 10

type Limits struct {
	Binary         string
	Deadline       time.Duration
	AddressSpace   uint64
	CPUSeconds     uint64
	OpenFiles      uint64
	MaxOutputBytes int64
	ExpectedCorpus string
}

func (l Limits) configured() bool {
	return l.Binary != "" && l.Deadline > 0 && l.AddressSpace != 0 && l.CPUSeconds != 0 && l.OpenFiles != 0 && l.MaxOutputBytes > 0 && len(l.ExpectedCorpus) == 64
}

// Launcher admits at most `workers` live processes. Every slot token is one
// live or starting process; an idle spare keeps its token in spares.
type Launcher struct {
	limits        Limits
	admissionWait time.Duration
	slots         chan struct{}
	spares        chan *process
	mutex         sync.Mutex
	closed        bool
}

func New(limits Limits, workers int, admissionWait time.Duration) *Launcher {
	return &Launcher{limits: limits, admissionWait: admissionWait, slots: make(chan struct{}, max(workers, 0)), spares: make(chan *process, max(workers, 0))}
}

type process struct {
	command *exec.Cmd
	workdir string
	stdin   io.WriteCloser
	stdout  *cappedBuffer
	stderr  *cappedBuffer
	done    chan error
}

type cappedBuffer struct {
	bytes.Buffer
	limit    int
	overflow bool
}

func (b *cappedBuffer) Write(p []byte) (int, error) {
	room := b.limit - b.Len()
	if len(p) > room {
		b.overflow = true
		p = p[:max(room, 0)]
	}
	b.Buffer.Write(p)
	return len(p), nil
}

func retryable(format string, args ...any) error {
	return fmt.Errorf("%w: %s", d.ErrResolverRetryable, fmt.Sprintf(format, args...))
}

func permanent(format string, args ...any) error {
	return fmt.Errorf("%w: %s", d.ErrResolverPermanent, fmt.Sprintf(format, args...))
}

func (l *Launcher) Resolve(ctx context.Context, snapshot []byte, snapshotHash string, root [32]byte) (app.WorkerOutput, error) {
	if !l.limits.configured() || cap(l.slots) == 0 || l.admissionWait <= 0 {
		return app.WorkerOutput{}, permanent("launcher limits are not configured")
	}
	request, err := json.Marshal(combatresolver.Request{Snapshot: snapshot, SnapshotHash: snapshotHash, EntropyRoot: hex.EncodeToString(root[:])})
	if err != nil || len(request) > combatresolver.MaxRequestBytes {
		return app.WorkerOutput{}, permanent("request encoding or bound")
	}
	p, err := l.take(ctx)
	if err != nil {
		return app.WorkerOutput{}, err
	}
	defer l.refill()
	return l.run(ctx, p, request)
}

// take hands out an idle spare, or starts a process when a slot is free, and
// refuses once the admission wait elapses with every slot busy.
func (l *Launcher) take(ctx context.Context) (*process, error) {
	timer := time.NewTimer(l.admissionWait)
	defer timer.Stop()
	select {
	case p := <-l.spares:
		return p, nil
	case l.slots <- struct{}{}:
	case <-timer.C:
		return nil, fmt.Errorf("%w: %d workers busy for %s", app.ErrWorkerSaturated, cap(l.slots), l.admissionWait)
	case <-ctx.Done():
		return nil, retryable("admission: %v", ctx.Err())
	}
	p, err := l.start()
	if err != nil {
		<-l.slots
		return nil, err
	}
	l.fill()
	return p, nil
}

// fill starts a spare for every free slot, so only attempts arriving before
// the first spares finish preparing pay the cold start.
func (l *Launcher) fill() {
	for {
		select {
		case l.slots <- struct{}{}:
			l.refill()
		default:
			return
		}
	}
}

// refill prepares a spare in the background under a slot token the caller
// holds; the token passes to the spare.
// shortcut: a spare is offered as soon as it starts, so an attempt may wait out
// the rest of its preparation; add a readiness signal if load nears pool capacity.
func (l *Launcher) refill() {
	go func() {
		p, err := l.start()
		if err != nil {
			<-l.slots
			return
		}
		l.mutex.Lock()
		defer l.mutex.Unlock()
		if l.closed {
			p.kill()
			<-l.slots
			return
		}
		l.spares <- p
	}()
}

// Close kills idle spares; attempts in flight finish under their own deadline.
func (l *Launcher) Close() {
	l.mutex.Lock()
	defer l.mutex.Unlock()
	l.closed = true
	for {
		select {
		case p := <-l.spares:
			p.kill()
			<-l.slots
		default:
			return
		}
	}
}

func (l *Launcher) start() (*process, error) {
	workdir, err := os.MkdirTemp("", "gxb-combat-worker-")
	if err != nil {
		return nil, retryable("workdir: %v", err)
	}
	command := exec.Command(l.limits.Binary,
		"-max-address-space", strconv.FormatUint(l.limits.AddressSpace, 10),
		"-max-cpu-seconds", strconv.FormatUint(l.limits.CPUSeconds, 10),
		"-max-open-files", strconv.FormatUint(l.limits.OpenFiles, 10))
	command.Env = []string{}
	command.Dir = workdir
	p := &process{command: command, workdir: workdir, stdout: &cappedBuffer{limit: int(l.limits.MaxOutputBytes) + 1}, stderr: &cappedBuffer{limit: maxStderrBytes}, done: make(chan error, 1)}
	command.Stdout, command.Stderr = p.stdout, p.stderr
	command.SysProcAttr = &syscall.SysProcAttr{Setpgid: true, Pdeathsig: syscall.SIGKILL}
	if p.stdin, err = command.StdinPipe(); err != nil {
		os.RemoveAll(workdir)
		return nil, retryable("stdin: %v", err)
	}
	if err = command.Start(); err != nil {
		os.RemoveAll(workdir)
		return nil, retryable("start: %v", err)
	}
	go func() { p.done <- command.Wait() }()
	return p, nil
}

func (p *process) kill() {
	_ = syscall.Kill(-p.command.Process.Pid, syscall.SIGKILL)
	<-p.done
	os.RemoveAll(p.workdir)
}

// run hands one attempt to a taken process; the wall deadline starts here.
func (l *Launcher) run(ctx context.Context, p *process, request []byte) (app.WorkerOutput, error) {
	deadline, cancel := context.WithTimeout(ctx, l.limits.Deadline)
	defer cancel()
	go func() {
		_, _ = p.stdin.Write(request)
		_ = p.stdin.Close()
	}()
	var err error
	select {
	case err = <-p.done:
		os.RemoveAll(p.workdir)
	case <-deadline.Done():
		p.kill()
		return app.WorkerOutput{}, retryable("wall deadline %s exceeded", l.limits.Deadline)
	}
	if err != nil {
		return app.WorkerOutput{}, retryable("worker exit: %v: %s", err, p.stderr.String())
	}
	if p.stdout.overflow || p.stdout.Len() > int(l.limits.MaxOutputBytes) {
		return app.WorkerOutput{}, permanent("worker output exceeds %d bytes", l.limits.MaxOutputBytes)
	}
	return l.decode(p.stdout.Bytes())
}

// decode revalidates worker output before it reaches persistence.
func (l *Launcher) decode(raw []byte) (app.WorkerOutput, error) {
	var response combatresolver.Response
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&response); err != nil {
		return app.WorkerOutput{}, retryable("garbled worker output: %v", err)
	}
	if _, err := decoder.Token(); !errors.Is(err, io.EOF) {
		return app.WorkerOutput{}, retryable("trailing worker output")
	}
	if response.CorpusID != l.limits.ExpectedCorpus {
		return app.WorkerOutput{}, permanent("worker corpus %q differs from %q", response.CorpusID, l.limits.ExpectedCorpus)
	}
	switch response.Status {
	case combatresolver.StatusPermanent:
		return app.WorkerOutput{}, permanent("%s", response.Failure)
	case combatresolver.StatusResolved:
	default:
		return app.WorkerOutput{}, retryable("unknown worker status %q", response.Status)
	}
	if response.Report == "" || !json.Valid([]byte(response.Report)) || response.Outcome.Frames <= 0 {
		return app.WorkerOutput{}, permanent("resolved output shape")
	}
	return app.WorkerOutput{CorpusID: response.CorpusID, Outcome: response.Outcome, Report: []byte(response.Report), EntropyDraws: response.EntropyDraws, EntropyReseeds: response.EntropyReseeds}, nil
}
