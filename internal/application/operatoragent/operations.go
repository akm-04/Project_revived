package operatoragent

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"regexp"
	"sync"
	"time"
)

const (
	OperationRunning = "RUNNING"
	OperationDone    = "DONE"
	OperationFailed  = "FAILED"
)

var operationIDPattern = regexp.MustCompile(`^[0-9a-f]{32,64}$`)

// OperationStep is one persisted step of a long operation.
type OperationStep struct {
	Name   string    `json:"name"`
	State  string    `json:"state"`
	At     time.Time `json:"at"`
	Detail string    `json:"detail,omitempty"`
}

// Operation is the ops/<id>.json document (L6).
type Operation struct {
	ID         string          `json:"id"`
	Kind       string          `json:"kind"`
	StartedAt  time.Time       `json:"started_at"`
	State      string          `json:"state"`
	Steps      []OperationStep `json:"steps"`
	Result     json.RawMessage `json:"result,omitempty"`
	FailedStep string          `json:"failed_step,omitempty"`
	Error      string          `json:"error,omitempty"`
}

// Step is one named unit of a long operation.
type Step struct {
	Name string
	Run  func(context.Context) (any, error)
}

// Operations runs and records long operations, one at a time per kind.
type Operations struct {
	Directory string
	Log       *ToolLog
	Now       func() time.Time

	mutex   sync.Mutex
	running map[string]*sync.Mutex
}

// NewOperations names the ops directory and its clock.
func NewOperations(directory string, log *ToolLog, now func() time.Time) *Operations {
	return &Operations{Directory: directory, Log: log, Now: now, running: map[string]*sync.Mutex{}}
}

// Recover turns an operation left RUNNING by an earlier agent process into
// FAILED "agent restarted". It runs at agent start.
func (operations *Operations) Recover() error {
	if err := os.MkdirAll(operations.Directory, 0o700); err != nil {
		return err
	}
	entries, err := os.ReadDir(operations.Directory)
	if err != nil {
		return err
	}
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".json" {
			continue
		}
		path := filepath.Join(operations.Directory, entry.Name())
		contents, readErr := os.ReadFile(path)
		if readErr != nil {
			continue
		}
		var operation Operation
		if json.Unmarshal(contents, &operation) != nil || operation.State != OperationRunning {
			continue
		}
		operation.State = OperationFailed
		operation.Error = "agent restarted"
		if writeErr := operations.write(operation); writeErr != nil {
			return writeErr
		}
		operations.log("recover", operation.Kind, "failed", operation.ID)
	}
	return nil
}

// Run executes the steps in order and persists the operation after every step.
// The returned error is the failing step's own error, so a backend refusal
// reaches the CLI unchanged; the operation document names the failed step.
func (operations *Operations) Run(ctx context.Context, kind string, steps []Step) (Operation, error) {
	guard := operations.guard(kind)
	if !guard.TryLock() {
		return Operation{}, Refuse(CodeOperationRunning, "another "+kind+" operation is running")
	}
	defer guard.Unlock()

	id, err := NewToken()
	if err != nil {
		return Operation{}, err
	}
	operation := Operation{ID: id, Kind: kind, StartedAt: operations.Now(), State: OperationRunning}
	if err := operations.write(operation); err != nil {
		return Operation{}, err
	}
	operations.log(kind, "start", "running", id)

	for _, step := range steps {
		startedAt := operations.Now()
		operations.log(kind, step.Name, "start", id)
		value, stepErr := step.Run(ctx)
		entry := OperationStep{Name: step.Name, State: OperationDone, At: startedAt}
		if stepErr != nil {
			entry.State = OperationFailed
			entry.Detail = MaskString(stepErr.Error())
			operation.Steps = append(operation.Steps, entry)
			operation.State = OperationFailed
			operation.FailedStep = step.Name
			operation.Error = MaskString(stepErr.Error())
			_ = operations.write(operation)
			operations.log(kind, step.Name, "failed", id)
			return operation, stepErr
		}
		operation.Steps = append(operation.Steps, entry)
		if value != nil {
			if encoded, encodeErr := json.Marshal(value); encodeErr == nil {
				operation.Result = encoded
			}
		}
		if err := operations.write(operation); err != nil {
			return operation, err
		}
		operations.log(kind, step.Name, "done", id)
	}
	operation.State = OperationDone
	if err := operations.write(operation); err != nil {
		return operation, err
	}
	operations.log(kind, "finish", "done", id)
	return operation, nil
}

// Status reads one operation document.
func (operations *Operations) Status(id string) (Operation, error) {
	if !operationIDPattern.MatchString(id) {
		return Operation{}, Refuse(CodeOperationUnknown, "no such operation")
	}
	contents, err := os.ReadFile(filepath.Join(operations.Directory, id+".json"))
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return Operation{}, Refuse(CodeOperationUnknown, "no such operation")
		}
		return Operation{}, err
	}
	var operation Operation
	if err := json.Unmarshal(contents, &operation); err != nil {
		return Operation{}, Refuse(CodeOperationUnknown, "the operation record is unreadable")
	}
	return operation, nil
}

func (operations *Operations) guard(kind string) *sync.Mutex {
	operations.mutex.Lock()
	defer operations.mutex.Unlock()
	guard, found := operations.running[kind]
	if !found {
		guard = &sync.Mutex{}
		operations.running[kind] = guard
	}
	return guard
}

func (operations *Operations) write(operation Operation) error {
	if err := os.MkdirAll(operations.Directory, 0o700); err != nil {
		return err
	}
	encoded, err := json.MarshalIndent(operation, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(operations.Directory, operation.ID+".json"), encoded, 0o600)
}

func (operations *Operations) log(kind, step, outcome, id string) {
	if operations.Log == nil {
		return
	}
	operations.Log.Write(kind, step, outcome, map[string]any{"operation_id": id})
}
