// Command gxb-mid-coverage maps every stock MID to what the backend does with it (I8.5-5 D57): the edge class an unauthenticated
// probe observes, and what the scenario journals recorded for it. I9 reads the map to plan which stock MIDs a mode needs.
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
)

// Edge classes, in the order the edge decides them before any dispatcher (and so before any authentication) runs.
const (
	classUncatalogued  = "uncatalogued"  // 404 unknown_mid
	classSocket        = "socket"        // 400 wrong_transport
	classUndecodable   = "not_ordinary"  // 400 before routing: a multipart MID or one the ordinary form cannot carry
	classUnimplemented = "unimplemented" // 501 unimplemented_mid
	classImplemented   = "implemented"   // reached a dispatcher
)

var stockMID = regexp.MustCompile(`(?m)^xyd\.mid\.(\w+)\s*=\s*(\d+)`)

type exercise struct {
	Requests   int            `json:"requests"`
	Players    int            `json:"players"`
	Outcomes   map[string]int `json:"outcomes"`
	ErrorCodes map[string]int `json:"error_codes,omitempty"`
}

type entry struct {
	MID       int       `json:"mid"`
	Name      string    `json:"name"`
	EdgeClass string    `json:"edge_class"`
	Exercised *exercise `json:"exercised,omitempty"`
	// SentBy counts, per scenario, the HTTP statuses the stock client got for this MID (from the run reports).
	SentBy map[string]map[string]int `json:"sent_by,omitempty"`
}

func main() {
	midTable := flag.String("mid-table", "", "stock src_64 app/common/network/mid.lua")
	engine := flag.String("engine", "", "gxb-api engine URL (the stock engine_url, e.g. http://127.0.0.1:18853/engine)")
	databaseURL := flag.String("database", "", "database whose request_journal holds the scenario runs (empty: probe only)")
	reports := flag.String("reports", "", "comma-separated gxb-virtual-client report.json files; the scenario is the report's directory name")
	out := flag.String("out", "", "MID_COVERAGE.json path")
	flag.Parse()
	if err := run(*midTable, *engine, *databaseURL, *reports, *out); err != nil {
		fmt.Fprintln(os.Stderr, "gxb-mid-coverage:", err)
		os.Exit(1)
	}
}

func run(midTable, engine, databaseURL, reports, out string) error {
	table, err := os.ReadFile(midTable)
	if err != nil {
		return err
	}
	names := map[int]string{}
	for _, match := range stockMID.FindAllStringSubmatch(string(table), -1) {
		var mid int
		fmt.Sscan(match[2], &mid)
		names[mid] = match[1]
	}
	if len(names) == 0 {
		return fmt.Errorf("no xyd.mid entries in %s", midTable)
	}
	exercised := map[int]*exercise{}
	if databaseURL != "" {
		if exercised, err = journal(databaseURL); err != nil {
			return fmt.Errorf("journal: %w", err)
		}
	}
	sent, err := sentByScenario(reports)
	if err != nil {
		return err
	}
	client := &http.Client{Timeout: 10 * time.Second}
	entries := make([]entry, 0, len(names))
	counts := map[string]int{}
	for mid, name := range names {
		class, err := probe(client, engine, mid)
		if err != nil {
			return fmt.Errorf("probe MID%d: %w", mid, err)
		}
		counts[class]++
		entries = append(entries, entry{MID: mid, Name: name, EdgeClass: class, Exercised: exercised[mid], SentBy: sent[mid]})
	}
	sort.Slice(entries, func(left, right int) bool { return entries[left].MID < entries[right].MID })
	var unnamed []int
	for mid := range exercised {
		if _, named := names[mid]; !named {
			unnamed = append(unnamed, mid)
		}
	}
	for mid := range sent {
		if _, named := names[mid]; !named && exercised[mid] == nil {
			unnamed = append(unnamed, mid)
		}
	}
	sort.Ints(unnamed)
	report := struct {
		Generated      string         `json:"generated"`
		StockMIDs      int            `json:"stock_mids"`
		EdgeClasses    map[string]int `json:"edge_classes"`
		ExercisedMIDs  int            `json:"exercised_mids"`
		UnnamedJournal []int          `json:"sent_mids_without_stock_name"`
		MIDs           []entry        `json:"mids"`
	}{time.Now().UTC().Format(time.RFC3339), len(names), counts, len(exercised), unnamed, entries}
	encoded, err := json.MarshalIndent(report, "", " ")
	if err != nil {
		return err
	}
	fmt.Printf("stock MIDs %d, edge classes %v, exercised %d\n", len(names), counts, len(exercised))
	return os.WriteFile(out, append(encoded, '\n'), 0o644)
}

// probe sends the stock ordinary form with no credentials: the edge classifies the MID before dispatch, and every dispatcher
// refuses an unauthenticated actor, so the probe changes nothing.
func probe(client *http.Client, engine string, mid int) (string, error) {
	form := url.Values{"payload": {fmt.Sprintf(`{"mid":%d}`, mid)}}
	response, err := client.PostForm(engine, form)
	if err != nil {
		return "", err
	}
	defer response.Body.Close()
	body, err := io.ReadAll(io.LimitReader(response.Body, 1<<16))
	if err != nil {
		return "", err
	}
	var edge struct {
		Error string `json:"error"`
	}
	json.Unmarshal(body, &edge)
	switch {
	case response.StatusCode == http.StatusNotFound && edge.Error == "unknown_mid":
		return classUncatalogued, nil
	case response.StatusCode == http.StatusBadRequest && edge.Error == "wrong_transport":
		return classSocket, nil
	case response.StatusCode == http.StatusNotImplemented && edge.Error == "unimplemented_mid":
		return classUnimplemented, nil
	case response.StatusCode == http.StatusBadRequest && edge.Error == "bad_request":
		return classUndecodable, nil
	}
	return classImplemented, nil
}

func sentByScenario(reports string) (map[int]map[string]map[string]int, error) {
	sent := map[int]map[string]map[string]int{}
	if reports == "" {
		return sent, nil
	}
	for _, path := range strings.Split(reports, ",") {
		content, err := os.ReadFile(path)
		if err != nil {
			return nil, err
		}
		var run struct {
			Report struct {
				Requests []struct {
					MID    int `json:"mid"`
					Status int `json:"status"`
				} `json:"requests"`
			} `json:"report"`
		}
		if err := json.Unmarshal(content, &run); err != nil {
			return nil, fmt.Errorf("%s: %w", path, err)
		}
		scenario := filepath.Base(filepath.Dir(path))
		for _, request := range run.Report.Requests {
			if request.MID == 0 {
				continue
			}
			if sent[request.MID] == nil {
				sent[request.MID] = map[string]map[string]int{}
			}
			if sent[request.MID][scenario] == nil {
				sent[request.MID][scenario] = map[string]int{}
			}
			sent[request.MID][scenario][strconv.Itoa(request.Status)]++
		}
	}
	return sent, nil
}

func journal(databaseURL string) (map[int]*exercise, error) {
	ctx := context.Background()
	connection, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		return nil, err
	}
	defer connection.Close(ctx)
	rows, err := connection.Query(ctx, `SELECT mid, count(*), count(DISTINCT player_id),
		(SELECT jsonb_object_agg(outcome, total) FROM (SELECT outcome, count(*) total FROM request_journal o
			WHERE o.mid = j.mid AND o.account_uid IS NOT NULL GROUP BY 1) outcomes),
		(SELECT jsonb_object_agg(error_code::text, total) FROM (SELECT error_code, count(*) total FROM request_journal e
			WHERE e.mid = j.mid AND e.account_uid IS NOT NULL AND e.error_code IS NOT NULL GROUP BY 1) codes)
		FROM request_journal j WHERE mid IS NOT NULL AND account_uid IS NOT NULL GROUP BY mid`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	result := map[int]*exercise{}
	for rows.Next() {
		var mid int
		seen := &exercise{}
		if err := rows.Scan(&mid, &seen.Requests, &seen.Players, &seen.Outcomes, &seen.ErrorCodes); err != nil {
			return nil, err
		}
		result[mid] = seen
	}
	return result, rows.Err()
}
