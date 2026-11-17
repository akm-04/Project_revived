package archguard

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"testing"
)

type servedMIDClasses struct {
	MIDs []struct {
		MID int `json:"mid"`
	} `json:"mids"`
}

type replyConsumerCallback struct {
	Status string `json:"status"`
	Reason string `json:"reason"`
}

type replyConsumerRecord struct {
	Status    string                                      `json:"status"`
	Reason    string                                      `json:"reason"`
	Callbacks []replyConsumerCallback                     `json:"callbacks"`
	Branches  map[string]map[string]replyConsumerCallback `json:"branches"`
}

type replyConsumerDocument struct {
	MIDs map[string]replyConsumerRecord `json:"mids"`
}

// TestEveryServedMIDHasReplyConsumers fails when the gxb-api dispatcher table
// serves a MID the generated reply-consumer evidence does not mention. An
// UNKNOWN row must carry its reason; it is reported separately and never
// counted as checked (REPLY_CONFORMANCE_EDGE_V1 ruling 6).
func TestEveryServedMIDHasReplyConsumers(t *testing.T) {
	root := repoRoot(t)
	served := readServedMIDs(t, filepath.Join(root, "docs", "architecture", "system_map", "MID_CLASSES.json"))
	consumers := readReplyConsumers(t, filepath.Join(root, "docs", "architecture", "reply_consumers", "REPLY_CONSUMERS.json"))

	var missing, checked, unreasoned, unknown []int
	for _, mid := range served {
		record, present := consumers[strconv.Itoa(mid)]
		if !present {
			missing = append(missing, mid)
			continue
		}
		if record.Status != "UNKNOWN" && !hasUnknownBucket(record) {
			checked = append(checked, mid)
			continue
		}
		unknown = append(unknown, mid)
		if !unknownIsReasoned(record) {
			unreasoned = append(unreasoned, mid)
		}
	}

	sort.Ints(missing)
	sort.Ints(unreasoned)
	sort.Ints(checked)
	sort.Ints(unknown)
	t.Logf("reply consumers: %d served MIDs, %d CHECKED, %d UNKNOWN reported separately", len(served), len(checked), len(unknown))
	if len(unknown) > 0 {
		t.Logf("UNKNOWN reply-consumer rows (present and reasoned, not checked): %v", unknown)
	}
	for _, mid := range unreasoned {
		t.Errorf("MID %d is UNKNOWN without a reason", mid)
	}
	if len(missing) > 0 {
		t.Fatalf("served MIDs without a reply-consumer row: %v", missing)
	}
}

func readServedMIDs(t *testing.T, path string) []int {
	t.Helper()
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var document servedMIDClasses
	if err := json.Unmarshal(raw, &document); err != nil {
		t.Fatalf("%s: %v", path, err)
	}
	served := make([]int, 0, len(document.MIDs))
	for _, row := range document.MIDs {
		served = append(served, row.MID)
	}
	return served
}

func readReplyConsumers(t *testing.T, path string) map[string]replyConsumerRecord {
	t.Helper()
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var document replyConsumerDocument
	if err := json.Unmarshal(raw, &document); err != nil {
		t.Fatalf("%s: %v", path, err)
	}
	return document.MIDs
}

func hasUnknownCallback(record replyConsumerRecord) bool {
	for _, callback := range record.Callbacks {
		if callback.Status == "UNKNOWN" {
			return true
		}
	}
	return false
}

func hasUnknownBucket(record replyConsumerRecord) bool {
	if hasUnknownCallback(record) {
		return true
	}
	for _, values := range record.Branches {
		for _, branch := range values {
			if branch.Status == "UNKNOWN" {
				return true
			}
		}
	}
	return false
}

// An UNKNOWN branch bucket is an unattributed consumer population: the row must
// count as UNKNOWN even when every callback resolved.
func TestReplyConsumerUnknownBranchBucketIsNotChecked(t *testing.T) {
	record := replyConsumerRecord{
		Status:    "CHECKED",
		Callbacks: []replyConsumerCallback{{Status: "CHECKED"}},
		Branches: map[string]map[string]replyConsumerCallback{
			"table_id": {"unknown": {Status: "UNKNOWN", Reason: "unattributed site"}},
		},
	}
	if !hasUnknownBucket(record) {
		t.Fatal("a record with an UNKNOWN branch bucket was counted CHECKED")
	}
}

func unknownIsReasoned(record replyConsumerRecord) bool {
	if record.Status == "UNKNOWN" && strings.TrimSpace(record.Reason) == "" {
		return false
	}
	for _, callback := range record.Callbacks {
		if callback.Status == "UNKNOWN" && strings.TrimSpace(callback.Reason) == "" {
			return false
		}
	}
	return true
}
