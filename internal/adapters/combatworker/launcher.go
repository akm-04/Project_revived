// Package combatworker runs one gxb-combat-worker process per resolution with
// an empty environment and working directory, no inherited descriptors beyond
// stdio, enforced resource limits, a process-group wall deadline and bounded
// output. It classifies failures for the Combat owner.
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
	"syscall"
	"time"

	"gxb.local/backend/v2/internal/adapters/combatresolver"
	app "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/combat"
)

const maxStderrBytes = 64 << 10

type Launcher struct {
	Binary         string
	Deadline       time.Duration
	AddressSpace   uint64
	CPUSeconds     uint64
	OpenFiles      uint64
	MaxOutputBytes int64
	ExpectedCorpus string
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

func (l Launcher) Resolve(ctx context.Context, snapshot []byte, snapshotHash string, root [32]byte) (app.WorkerOutput, error) {
	if l.Binary == "" || l.Deadline <= 0 || l.AddressSpace == 0 || l.CPUSeconds == 0 || l.OpenFiles == 0 || l.MaxOutputBytes <= 0 || len(l.ExpectedCorpus) != 64 {
		return app.WorkerOutput{}, permanent("launcher limits are not configured")
	}
	request, err := json.Marshal(combatresolver.Request{Snapshot: snapshot, SnapshotHash: snapshotHash, EntropyRoot: hex.EncodeToString(root[:])})
	if err != nil || len(request) > combatresolver.MaxRequestBytes {
		return app.WorkerOutput{}, permanent("request encoding or bound")
	}
	workdir, err := os.MkdirTemp("", "gxb-combat-worker-")
	if err != nil {
		return app.WorkerOutput{}, retryable("workdir: %v", err)
	}
	defer os.RemoveAll(workdir)
	deadline, cancel := context.WithTimeout(ctx, l.Deadline)
	defer cancel()
	cmd := exec.Command(l.Binary,
		"-max-address-space", strconv.FormatUint(l.AddressSpace, 10),
		"-max-cpu-seconds", strconv.FormatUint(l.CPUSeconds, 10),
		"-max-open-files", strconv.FormatUint(l.OpenFiles, 10))
	cmd.Env = []string{}
	cmd.Dir = workdir
	cmd.Stdin = bytes.NewReader(request)
	stdout := &cappedBuffer{limit: int(l.MaxOutputBytes) + 1}
	stderr := &cappedBuffer{limit: maxStderrBytes}
	cmd.Stdout, cmd.Stderr = stdout, stderr
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true, Pdeathsig: syscall.SIGKILL}
	if err = cmd.Start(); err != nil {
		return app.WorkerOutput{}, retryable("start: %v", err)
	}
	done := make(chan error, 1)
	go func() { done <- cmd.Wait() }()
	select {
	case err = <-done:
	case <-deadline.Done():
		_ = syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL)
		<-done
		return app.WorkerOutput{}, retryable("wall deadline %s exceeded", l.Deadline)
	}
	if err != nil {
		return app.WorkerOutput{}, retryable("worker exit: %v: %s", err, stderr.String())
	}
	if stdout.overflow || stdout.Len() > int(l.MaxOutputBytes) {
		return app.WorkerOutput{}, permanent("worker output exceeds %d bytes", l.MaxOutputBytes)
	}
	return l.decode(stdout.Bytes())
}

// decode revalidates worker output before it reaches persistence.
func (l Launcher) decode(raw []byte) (app.WorkerOutput, error) {
	var response combatresolver.Response
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&response); err != nil {
		return app.WorkerOutput{}, retryable("garbled worker output: %v", err)
	}
	if _, err := decoder.Token(); !errors.Is(err, io.EOF) {
		return app.WorkerOutput{}, retryable("trailing worker output")
	}
	if response.CorpusID != l.ExpectedCorpus {
		return app.WorkerOutput{}, permanent("worker corpus %q differs from %q", response.CorpusID, l.ExpectedCorpus)
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
