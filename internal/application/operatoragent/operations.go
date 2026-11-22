package operatoragent

import (
	"bytes"
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
	// SemanticKey and Request let a resend after an agent crash reuse the
	// backend command key instead of applying a second command.
	SemanticKey string          `json:"semantic_key,omitempty"`
	Request     json.RawMessage `json:"request,omitempty"`
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
	operation, guard, err := operations.claim(kind, "", nil)
	if err != nil {
		return Operation{}, err
	}
	defer guard.Unlock()
	return operations.execute(ctx, operation, steps)
}

// Start claims the kind's guard, records a RUNNING operation and runs the steps
// in the background, returning the operation at once (the agent API answers 202
// with its id). A second start of the same kind is refused while the first runs.
func (operations *Operations) Start(ctx context.Context, kind, semanticKey string, request json.RawMessage, steps []Step) (Operation, error) {
	operation, guard, err := operations.claim(kind, semanticKey, request)
	if err != nil {
		return Operation{}, err
	}
	go func() {
		defer guard.Unlock()
		_, _ = operations.execute(ctx, operation, steps)
	}()
	return operation, nil
}

// claim takes the kind's guard and writes the RUNNING record; the caller owns
// the guard until it unlocks.
func (operations *Operations) claim(kind, semanticKey string, request json.RawMessage) (Operation, *sync.Mutex, error) {
	guard := operations.guard(kind)
	if !guard.TryLock() {
		return Operation{}, nil, Refuse(CodeOperationRunning, "another "+kind+" operation is running")
	}
	id, err := NewToken()
	if err != nil {
		guard.Unlock()
		return Operation{}, nil, err
	}
	operation := Operation{ID: id, Kind: kind, StartedAt: operations.Now(), State: OperationRunning, SemanticKey: semanticKey, Request: request}
	if err := operations.write(operation); err != nil {
		guard.Unlock()
		return Operation{}, nil, err
	}
	operations.log(kind, "start", "running", id)
	return operation, guard, nil
}

func (operations *Operations) execute(ctx context.Context, operation Operation, steps []Step) (Operation, error) {
	for _, step := range steps {
		startedAt := operations.Now()
		operations.log(operation.Kind, step.Name, "start", operation.ID)
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
			operations.log(operation.Kind, step.Name, "failed", operation.ID)
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
		operations.log(operation.Kind, step.Name, "done", operation.ID)
	}
	operation.State = OperationDone
	if err := operations.write(operation); err != nil {
		return operation, err
	}
	operations.log(operation.Kind, "finish", "done", operation.ID)
	return operation, nil
}

// ReusableKey returns the semantic key of a FAILED operation with the same kind
// and request, so a resend after an agent crash replays the backend command
// instead of applying it twice.
func (operations *Operations) ReusableKey(kind string, request json.RawMessage) string {
	entries, err := os.ReadDir(operations.Directory)
	if err != nil {
		return ""
	}
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".json" {
			continue
		}
		contents, readErr := os.ReadFile(filepath.Join(operations.Directory, entry.Name()))
		if readErr != nil {
			continue
		}
		var operation Operation
		if json.Unmarshal(contents, &operation) != nil {
			continue
		}
		if operation.Kind == kind && operation.State == OperationFailed && operation.SemanticKey != "" && sameJSON(operation.Request, request) {
			return operation.SemanticKey
		}
	}
	return ""
}

// sameJSON compares two JSON documents after dropping insignificant whitespace;
// MarshalIndent rewrites the whitespace inside a stored RawMessage.
func sameJSON(left, right json.RawMessage) bool {
	var leftCompact, rightCompact bytes.Buffer
	if json.Compact(&leftCompact, left) != nil || json.Compact(&rightCompact, right) != nil {
		return false
	}
	return bytes.Equal(leftCompact.Bytes(), rightCompact.Bytes())
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

const (
	operationWriteAttempts = 3
	operationWriteDelay    = 50 * time.Millisecond
)

// operationWriteRecord is a variable so a test can inject a write fault.
var operationWriteRecord = writeOperationRecord

// write persists the record with retries. A write that keeps failing is logged
// before the error reaches the caller, so an operation is never left RUNNING
// silently (L4f fixes 5 and 6).
func (operations *Operations) write(operation Operation) error {
	encoded, err := json.MarshalIndent(operation, "", "  ")
	if err != nil {
		return err
	}
	path := filepath.Join(operations.Directory, operation.ID+".json")
	var lastErr error
	for attempt := range operationWriteAttempts {
		lastErr = operationWriteRecord(path, encoded)
		if lastErr == nil {
			return nil
		}
		if attempt+1 < operationWriteAttempts {
			time.Sleep(operationWriteDelay)
		}
	}
	if operations.Log != nil {
		operations.Log.Write(operation.Kind, "write", "failed", map[string]any{
			"operation_id": operation.ID,
			"state":        operation.State,
			"error":        MaskString(lastErr.Error()),
		})
	}
	return lastErr
}

// writeOperationRecord replaces the record atomically: temp file, fsync, close,
// rename, so a reader never sees a truncated JSON document (L4f fix 5).
func writeOperationRecord(path string, encoded []byte) error {
	directory := filepath.Dir(path)
	if err := os.MkdirAll(directory, 0o700); err != nil {
		return err
	}
	temporary, err := os.CreateTemp(directory, ".op-*.tmp")
	if err != nil {
		return err
	}
	temporaryName := temporary.Name()
	cleanup := func() {
		_ = temporary.Close()
		_ = os.Remove(temporaryName)
	}
	if _, err := temporary.Write(encoded); err != nil {
		cleanup()
		return err
	}
	if err := temporary.Sync(); err != nil {
		cleanup()
		return err
	}
	if err := temporary.Close(); err != nil {
		_ = os.Remove(temporaryName)
		return err
	}
	if err := os.Rename(temporaryName, path); err != nil {
		_ = os.Remove(temporaryName)
		return err
	}
	return nil
}

func (operations *Operations) log(kind, step, outcome, id string) {
	if operations.Log == nil {
		return
	}
	operations.Log.Write(kind, step, outcome, map[string]any{"operation_id": id})
}
