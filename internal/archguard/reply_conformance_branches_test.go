package archguard

import (
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"testing"
)

type branchedReplyConsumerDocument struct {
	SiteFiles []string `json:"site_files"`
	MIDs      map[string]struct {
		Paths    []json.RawMessage `json:"paths"`
		Branches map[string]map[string]struct {
			Status string            `json:"status"`
			Reason string            `json:"reason"`
			Paths  []json.RawMessage `json:"paths"`
		} `json:"branches"`
	} `json:"mids"`
}

var activityWindowFile = regexp.MustCompile(`^app/windows/activities/Activity\d+\.lua$`)

// branchPolicyExemptions are MIDs whose reply is split by an activity id but
// whose branches the reply-only checker cannot select. Each needs its reason.
var branchPolicyExemptions = map[int]string{
	1:   "RETRIEVE_TOKEN's detail is a per-MID map: Activity windows read their own entry and the request carries no activity discriminator, so the union is the batch model, not a selectable branch",
	231: "request-discriminated at getActivityReward call sites; the reply carries no selectable discriminator and the MID is inactive",
	629: "the NIAN_BOSS reply is one shape (the request carries no discriminator); Activity1038 and Activity1065 read the same shared NianBoss model fields, so their union is required and no per-branch set exists",
}

// TestReplyConsumerActivityBranchesCoverSplitMIDs fails when a MID consumed by
// two or more Activity<table_id> windows has neither per-branch obligations nor
// a reasoned exemption, so a new discriminator split cannot stay one union
// obligation set (PROVENANCE_AND_COVERAGE_V1 law C).
func TestReplyConsumerActivityBranchesCoverSplitMIDs(t *testing.T) {
	root := repoRoot(t)
	path := filepath.Join(root, "docs", "architecture", "reply_consumers", "REPLY_CONSUMERS.json")
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var document branchedReplyConsumerDocument
	if err := json.Unmarshal(raw, &document); err != nil {
		t.Fatalf("%s: %v", path, err)
	}

	var uncovered, unreasoned []int
	for text, record := range document.MIDs {
		mid, err := strconv.Atoi(text)
		if err != nil {
			continue
		}
		windows := windowFileSet{}
		collectWindowFiles(document.SiteFiles, record.Paths, windows)
		for _, values := range record.Branches {
			for _, branch := range values {
				collectWindowFiles(document.SiteFiles, branch.Paths, windows)
				if branch.Status == "UNKNOWN" && strings.TrimSpace(branch.Reason) == "" {
					unreasoned = append(unreasoned, mid)
				}
			}
		}
		if len(windows) < 2 {
			continue
		}
		if _, present := record.Branches["table_id"]; present {
			continue
		}
		if _, exempt := branchPolicyExemptions[mid]; !exempt {
			uncovered = append(uncovered, mid)
		}
	}
	for _, mid := range unreasoned {
		t.Errorf("MID %d has an UNKNOWN reply branch without a reason", mid)
	}
	if len(uncovered) > 0 {
		t.Fatalf("MIDs split across Activity windows without branch obligations: %v", uncovered)
	}
}

type windowFileSet map[string]bool

func collectWindowFiles(files []string, paths []json.RawMessage, windows windowFileSet) {
	for _, rawEntry := range paths {
		var entry []json.RawMessage
		if json.Unmarshal(rawEntry, &entry) != nil || len(entry) < 3 {
			continue
		}
		var sites []json.RawMessage
		if json.Unmarshal(entry[2], &sites) != nil {
			continue
		}
		for _, rawSite := range sites {
			var site []json.RawMessage
			if json.Unmarshal(rawSite, &site) != nil || len(site) < 1 {
				continue
			}
			var index int
			if json.Unmarshal(site[0], &index) != nil || index < 0 || index >= len(files) {
				continue
			}
			if activityWindowFile.MatchString(files[index]) {
				windows[files[index]] = true
			}
		}
	}
}
