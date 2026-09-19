package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"gxb.local/backend/v2/internal/projection/lobby"
)

func main() {
	dir := flag.String("dir", "", "Wave-S evidence directory")
	runID := flag.String("run-id", "", "run identifier used by API/realtime/client harness")
	required := flag.Duration("required", 60*time.Second, "required quiescence duration")
	flag.Parse()
	if *dir == "" || *runID == "" || filepath.Base(*runID) != *runID {
		fmt.Fprintln(os.Stderr, "-dir and a path-safe -run-id are required")
		os.Exit(2)
	}
	paths := []string{
		filepath.Join(*dir, *runID+"-api.jsonl"),
		filepath.Join(*dir, *runID+"-realtime.jsonl"),
	}
	client := filepath.Join(*dir, *runID+"-client.jsonl")
	if _, err := os.Stat(client); err == nil {
		paths = append(paths, client)
	} else if !os.IsNotExist(err) {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	t, err := lobby.LoadBootTrackerJSONL(paths...)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	now := time.Now().UTC()
	out := t.EvaluateWaveS(*runID, now, *required)
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	if err := enc.Encode(out); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	if !out.AcceptanceGreen {
		fmt.Fprintf(os.Stderr, "Wave-S verdict: %s\n", out.Verdict)
		os.Exit(1)
	}
}
