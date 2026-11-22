package agentapi

import (
	"context"
	"net"
	"net/http"
	"os/exec"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

type processBackend struct {
	command *exec.Cmd
	running bool
}

func (backend *processBackend) Start(bool, string) error {
	backend.command = exec.Command("sleep", "30")
	if err := backend.command.Start(); err != nil {
		return err
	}
	backend.running = true
	return nil
}

func (backend *processBackend) Stop() error {
	if backend.command == nil || !backend.running {
		return nil
	}
	_ = backend.command.Process.Kill()
	_ = backend.command.Wait()
	backend.running = false
	return nil
}

func (backend *processBackend) Status() operatoragent.BackendStatus {
	return operatoragent.BackendStatus{Running: backend.running}
}

func TestServeStopsBackendOnContextEnd(t *testing.T) {
	backend := &processBackend{}
	if err := backend.Start(false, "token"); err != nil {
		t.Fatal(err)
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	server := &http.Server{Handler: http.HandlerFunc(func(http.ResponseWriter, *http.Request) {})}
	ctx, cancel := context.WithCancel(context.Background())
	finished := make(chan error, 1)
	go func() { finished <- Serve(ctx, server, listener, backend) }()
	cancel()
	select {
	case serveErr := <-finished:
		if serveErr != nil {
			t.Fatal(serveErr)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("the agent run did not return")
	}
	if backend.running {
		t.Fatal("the backend child survived the agent run")
	}
}
