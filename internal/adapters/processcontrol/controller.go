// Package processcontrol runs the gxb-api child process for the agent: one
// child at a time, a fresh operator token per start, readiness by
// GET /operator/v1/version, and a reported crash that is never restarted
// silently (I11A_1_PLAN "Agent decisions").
package processcontrol

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"sync"
	"time"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

const (
	defaultReadyTimeout = 60 * time.Second
	defaultStopGrace    = 15 * time.Second
	readinessInterval   = 50 * time.Millisecond
	readinessTimeout    = time.Second
)

// Options are the process-control settings taken from agent.json.
type Options struct {
	Binary       string
	EnvFile      string
	OperatorAddr string
	OTARoot      string
	LogPath      string
	ReadyTimeout time.Duration
	StopGrace    time.Duration
}

// Controller owns the single backend child.
type Controller struct {
	options Options

	mutex sync.Mutex
	child *childProcess

	startGuard sync.Mutex
}

type childProcess struct {
	command *exec.Cmd
	done    chan struct{}

	mutex   sync.Mutex
	exited  bool
	waitErr error
}

func (child *childProcess) markExited(err error) {
	child.mutex.Lock()
	defer child.mutex.Unlock()
	child.exited = true
	child.waitErr = err
}

func (child *childProcess) state() (bool, error) {
	child.mutex.Lock()
	defer child.mutex.Unlock()
	return child.exited, child.waitErr
}

// New takes the settings; zero timeouts fall back to the defaults.
func New(options Options) *Controller {
	if options.ReadyTimeout <= 0 {
		options.ReadyTimeout = defaultReadyTimeout
	}
	if options.StopGrace <= 0 {
		options.StopGrace = defaultStopGrace
	}
	return &Controller{options: options}
}

// Start launches the backend with a fresh operator token and waits until the
// operator listener answers. A child that exits first is reported.
func (controller *Controller) Start(closed bool, token string) error {
	controller.startGuard.Lock()
	defer controller.startGuard.Unlock()

	controller.mutex.Lock()
	if controller.child != nil {
		exited, _ := controller.child.state()
		if !exited {
			controller.mutex.Unlock()
			return operatoragent.Refuse(operatoragent.CodeBackendRunning, "one backend child at a time")
		}
	}
	controller.mutex.Unlock()

	if controller.options.Binary == "" {
		return operatoragent.Refuse(operatoragent.CodeBackendUnavailable, "agent.json backend.binary is empty")
	}
	environment, err := controller.environment(closed, token)
	if err != nil {
		return err
	}
	logFile, err := os.OpenFile(controller.options.LogPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		return fmt.Errorf("open the backend log: %w", err)
	}
	command := exec.Command(controller.options.Binary)
	command.Env = environment
	command.Stdout = logFile
	command.Stderr = logFile
	prepare(command)
	if err := command.Start(); err != nil {
		_ = logFile.Close()
		return fmt.Errorf("start the backend: %w", err)
	}
	child := &childProcess{command: command, done: make(chan struct{})}
	go func() {
		waitErr := command.Wait()
		child.markExited(waitErr)
		_ = logFile.Close()
		close(child.done)
	}()

	controller.mutex.Lock()
	controller.child = child
	controller.mutex.Unlock()

	if err := controller.waitUntilReady(child, token); err != nil {
		_ = controller.Stop()
		return err
	}
	return nil
}

func (controller *Controller) environment(closed bool, token string) ([]string, error) {
	entries := []string{}
	if controller.options.EnvFile != "" {
		loaded, err := operatoragent.ReadEnvFile(controller.options.EnvFile)
		if err != nil {
			return nil, err
		}
		entries = loaded
	}
	environment := append(os.Environ(), entries...)
	environment = append(environment, "GXB_OPERATOR_TOKEN="+token)
	environment = append(environment, "GXB_OPERATOR_ADDR="+controller.options.OperatorAddr)
	if controller.options.OTARoot != "" {
		environment = append(environment, "GXB_OTA_ROOT="+controller.options.OTARoot)
	}
	if closed {
		environment = append(environment, "GXB_GAME_LISTENER=closed")
	}
	return environment, nil
}

func (controller *Controller) waitUntilReady(child *childProcess, token string) error {
	deadline := time.Now().Add(controller.options.ReadyTimeout)
	ticker := time.NewTicker(readinessInterval)
	defer ticker.Stop()
	for {
		if exited, waitErr := child.state(); exited {
			return fmt.Errorf("the backend exited before it was ready: %v", waitErr)
		}
		if controller.versionAnswers(token) {
			return nil
		}
		if time.Now().After(deadline) {
			return fmt.Errorf("the backend did not answer /operator/v1/version within %s", controller.options.ReadyTimeout)
		}
		<-ticker.C
	}
}

func (controller *Controller) versionAnswers(token string) bool {
	request, err := http.NewRequest(http.MethodGet, "http://"+controller.options.OperatorAddr+"/operator/v1/version", nil)
	if err != nil {
		return false
	}
	request.Header.Set("Authorization", "Bearer "+token)
	client := &http.Client{Timeout: readinessTimeout}
	response, err := client.Do(request)
	if err != nil {
		return false
	}
	_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, 1<<20))
	_ = response.Body.Close()
	return response.StatusCode == http.StatusOK
}

// Stop asks the child to terminate, waits the grace period, then kills it.
func (controller *Controller) Stop() error {
	controller.mutex.Lock()
	child := controller.child
	controller.mutex.Unlock()
	if child == nil {
		return nil
	}
	if exited, _ := child.state(); !exited {
		terminate(child.command)
		select {
		case <-child.done:
		case <-time.After(controller.options.StopGrace):
			_ = child.command.Process.Kill()
			<-child.done
		}
	}
	controller.mutex.Lock()
	if controller.child == child {
		controller.child = nil
	}
	controller.mutex.Unlock()
	return nil
}

// Status reports the child without changing it.
func (controller *Controller) Status() operatoragent.BackendStatus {
	controller.mutex.Lock()
	child := controller.child
	controller.mutex.Unlock()
	if child == nil {
		return operatoragent.BackendStatus{Running: false}
	}
	exited, waitErr := child.state()
	if exited {
		state := "exited"
		if waitErr != nil {
			state = "crashed"
		}
		return operatoragent.BackendStatus{Running: false, State: state}
	}
	return operatoragent.BackendStatus{Running: true, PID: child.command.Process.Pid, State: "running"}
}
