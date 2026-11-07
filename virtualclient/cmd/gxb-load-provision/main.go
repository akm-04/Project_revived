// Command gxb-load-provision raises load-test accounts to a scenario level through
// the same production I5 owner the virtual client uses, and reports the hero
// summons the client must still make itself through stock MID 59.
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"strings"
	"sync"
	"time"

	"gxb.local/backend/v2/virtualclient/provision"
)

func retryable(err error) bool {
	text := err.Error()
	return strings.Contains(text, "40001") || strings.Contains(text, "55P03")
}

type account struct {
	AccountID string `json:"account_id"`
}

type outcome struct {
	AccountID string             `json:"account_id"`
	Summons   []provision.Summon `json:"summons"`
	Error     string             `json:"error,omitempty"`
}

func main() {
	dsn := flag.String("dsn", "", "PostgreSQL DSN")
	accountsPath := flag.String("accounts", "", "JSON file holding [{\"account_id\":...}]")
	level := flag.Int64("level", 0, "scenario player level")
	tables := flag.String("tables", "", "comma-separated hero table ids to grant fragments for")
	parallel := flag.Int("parallel", 4, "concurrent provisioning jobs")
	outPath := flag.String("out", "", "result JSON path (default stdout)")
	flag.Parse()
	if *dsn == "" || *accountsPath == "" || *level < 2 {
		fmt.Fprintln(os.Stderr, "gxb-load-provision: -dsn, -accounts and -level >= 2 are required")
		os.Exit(2)
	}
	raw, err := os.ReadFile(*accountsPath)
	if err != nil {
		fmt.Fprintln(os.Stderr, "gxb-load-provision:", err)
		os.Exit(1)
	}
	var accounts []account
	if err = json.Unmarshal(raw, &accounts); err != nil {
		fmt.Fprintln(os.Stderr, "gxb-load-provision:", err)
		os.Exit(1)
	}
	heroTables := []int64{}
	for _, field := range strings.Split(*tables, ",") {
		field = strings.TrimSpace(field)
		if field == "" {
			continue
		}
		var table int64
		if _, err = fmt.Sscan(field, &table); err != nil || table <= 0 {
			fmt.Fprintf(os.Stderr, "gxb-load-provision: invalid hero table %q\n", field)
			os.Exit(2)
		}
		heroTables = append(heroTables, table)
	}
	results := make([]outcome, len(accounts))
	jobs := make(chan int)
	var wait sync.WaitGroup
	for worker := 0; worker < *parallel; worker++ {
		wait.Add(1)
		go func() {
			defer wait.Done()
			for index := range jobs {
				var summons []provision.Summon
				var progressErr error
				// The admin grant is SERIALIZABLE; concurrent grants conflict with 40001.
				for attempt := 0; attempt < 8; attempt++ {
					summons, progressErr = provision.Progress(context.Background(), *dsn, accounts[index].AccountID, *level, heroTables, false)
					if progressErr == nil || !retryable(progressErr) {
						break
					}
					time.Sleep(time.Duration(100*(attempt+1)) * time.Millisecond)
				}
				results[index] = outcome{AccountID: accounts[index].AccountID, Summons: summons}
				if progressErr != nil {
					results[index].Error = progressErr.Error()
				}
			}
		}()
	}
	for index := range accounts {
		jobs <- index
	}
	close(jobs)
	wait.Wait()
	encoded, err := json.Marshal(results)
	if err != nil {
		fmt.Fprintln(os.Stderr, "gxb-load-provision:", err)
		os.Exit(1)
	}
	if *outPath == "" {
		fmt.Println(string(encoded))
		return
	}
	if err = os.WriteFile(*outPath, append(encoded, '\n'), 0o600); err != nil {
		fmt.Fprintln(os.Stderr, "gxb-load-provision:", err)
		os.Exit(1)
	}
}
