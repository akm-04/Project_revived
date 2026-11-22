package operatoragent

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/otabuild"
)

// TestOperationWriteNeverExposesTruncatedJSON polls the record while it is
// rewritten; the atomic temp+rename must never show a partial document (L4f
// fix 5).
func TestOperationWriteNeverExposesTruncatedJSON(t *testing.T) {
	directory := filepath.Join(t.TempDir(), OperationsDirectory)
	operations := NewOperations(directory, nil, time.Now)
	id, err := NewToken()
	if err != nil {
		t.Fatal(err)
	}
	operation := Operation{ID: id, Kind: "test", StartedAt: time.Now(), State: OperationRunning}
	if err := operations.write(operation); err != nil {
		t.Fatal(err)
	}
	done := make(chan struct{})
	go func() {
		defer close(done)
		for index := range 100 {
			operation.Steps = append(operation.Steps, OperationStep{Name: fmt.Sprintf("step-%d", index), State: OperationDone, At: time.Now(), Detail: strings.Repeat("x", 4096)})
			_ = operations.write(operation)
		}
	}()
	for {
		select {
		case <-done:
			return
		default:
			if _, err := operations.Status(id); err != nil {
				t.Fatalf("a poll during a write saw an unreadable record: %v", err)
			}
		}
	}
}

func TestOperationWriteRetriesThenSucceeds(t *testing.T) {
	previous := operationWriteRecord
	t.Cleanup(func() { operationWriteRecord = previous })
	failures := 2
	operationWriteRecord = func(path string, encoded []byte) error {
		if failures > 0 {
			failures--
			return errors.New("injected write fault")
		}
		return writeOperationRecord(path, encoded)
	}
	operations := NewOperations(filepath.Join(t.TempDir(), OperationsDirectory), nil, time.Now)
	operation, err := operations.Run(context.Background(), "test", []Step{
		{Name: "one", Run: func(context.Context) (any, error) { return nil, nil }},
	})
	if err != nil || operation.State != OperationDone {
		t.Fatalf("operation = %+v err = %v", operation, err)
	}
}

func TestOperationWriteFailureIsLogged(t *testing.T) {
	previous := operationWriteRecord
	t.Cleanup(func() { operationWriteRecord = previous })
	operationWriteRecord = func(string, []byte) error { return errors.New("disk full") }
	var output bytes.Buffer
	log := NewToolLog(&output, time.Now)
	operations := NewOperations(filepath.Join(t.TempDir(), OperationsDirectory), log, time.Now)
	if _, err := operations.Run(context.Background(), "test", []Step{
		{Name: "one", Run: func(context.Context) (any, error) { return nil, nil }},
	}); err == nil {
		t.Fatal("a persistently failing write was not reported")
	}
	if !strings.Contains(output.String(), `"step":"write"`) || !strings.Contains(output.String(), `"outcome":"failed"`) {
		t.Fatalf("the discarded state write was not logged:\n%s", output.String())
	}
}

func TestBuildRefusalMapsIOToTemporary(t *testing.T) {
	err := buildRefusal(fmt.Errorf("%w: short copy", otabuild.ErrBuildIO))
	var transient *Transient
	if !errors.As(err, &transient) || transient.Code != CodeBuildIO {
		t.Fatalf("an I/O defect was not a temporary refusal: %v", err)
	}
}

func TestOperationsPersistStepsAndRecoverRunning(t *testing.T) {
	directory := filepath.Join(t.TempDir(), OperationsDirectory)
	operations := NewOperations(directory, nil, time.Now)
	first := 0
	operation, err := operations.Run(context.Background(), "test", []Step{
		{Name: "one", Run: func(context.Context) (any, error) { first++; return map[string]int{"value": 7}, nil }},
		{Name: "two", Run: func(context.Context) (any, error) { return nil, nil }},
	})
	if err != nil {
		t.Fatal(err)
	}
	if operation.State != OperationDone || len(operation.Steps) != 2 || first != 1 {
		t.Fatalf("operation = %+v", operation)
	}
	var result map[string]int
	if err := json.Unmarshal(operation.Result, &result); err != nil || result["value"] != 7 {
		t.Fatalf("result = %s (%v)", operation.Result, err)
	}
	if _, err := os.Stat(filepath.Join(directory, operation.ID+".json")); err != nil {
		t.Fatal(err)
	}
	if _, err := operations.Status(operation.ID); err != nil {
		t.Fatal(err)
	}

	failed, err := operations.Run(context.Background(), "test", []Step{
		{Name: "boom", Run: func(context.Context) (any, error) { return nil, errors.New("step failed") }},
		{Name: "unreachable", Run: func(context.Context) (any, error) { t.Error("the runner continued after a failure"); return nil, nil }},
	})
	if err == nil || failed.State != OperationFailed || failed.FailedStep != "boom" {
		t.Fatalf("failed operation = %+v, err = %v", failed, err)
	}
	if _, err := operations.Status("not-an-id"); err == nil {
		t.Fatal("an invalid id must be refused")
	}

	restartedID, err := NewToken()
	if err != nil {
		t.Fatal(err)
	}
	running := Operation{ID: restartedID, Kind: "ota.publish", StartedAt: time.Now(), State: OperationRunning}
	encoded, _ := json.Marshal(running)
	if err := os.WriteFile(filepath.Join(directory, restartedID+".json"), encoded, 0o600); err != nil {
		t.Fatal(err)
	}
	if err := operations.Recover(); err != nil {
		t.Fatal(err)
	}
	recovered, err := operations.Status(restartedID)
	if err != nil {
		t.Fatal(err)
	}
	if recovered.State != OperationFailed || recovered.Error != "agent restarted" {
		t.Fatalf("recovered = %+v", recovered)
	}
}
