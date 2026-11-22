package operatoragent

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"
)

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
