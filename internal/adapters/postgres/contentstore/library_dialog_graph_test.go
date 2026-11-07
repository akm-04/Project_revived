package contentstore

import (
	"encoding/json"
	"testing"

	"gxb.local/backend/v2/internal/content/builtin"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
)

func dialogNodes(domain library.Catalog, relationshipSourceID, dialogGroup int64) map[int64]library.DialogNode {
	return domain.DialogNodes[library.DialogGroupKey{RelationshipSourceID: relationshipSourceID, DialogGroup: dialogGroup}]
}

func TestLibraryCatalogRetainsDialogGraph(t *testing.T) {
	domain := domainFrom(t, loadedLibraryInputs(t))

	group := dialogNodes(domain, 10001006, 2)
	branch := group[201004]
	if len(branch.TurnIDs) != 2 || branch.TurnIDs[0] != 202001 || branch.TurnIDs[1] != 203001 {
		t.Fatalf("branch node = %+v", branch)
	}
	if got := group[202001].IsReward; got == nil || *got != 3 {
		t.Fatalf("raw 3 reward = %v", got)
	}
	if got := group[203001].IsReward; got == nil || *got != 2 {
		t.Fatalf("raw 2 reward = %v", got)
	}
	zero := dialogNodes(domain, 10001006, 4)[403001]
	if zero.IsReward == nil || *zero.IsReward != 0 {
		t.Fatalf("zero branch = %+v", zero)
	}
	terminal := dialogNodes(domain, 10001001, 12)[1201001]
	if terminal.IsReward == nil || *terminal.IsReward != 5 || len(terminal.TurnIDs) != 1 || terminal.TurnIDs[0] != -1 {
		t.Fatalf("raw 5 terminal = %+v", terminal)
	}
	if absent := dialogNodes(domain, 10001044, 7)[701005]; absent.IsReward != nil {
		t.Fatalf("absent source reward decoded as %v", *absent.IsReward)
	}

	total := 0
	for _, nodes := range domain.DialogNodes {
		total += len(nodes)
		for nodeID, node := range nodes {
			if nodeID <= 0 || node.NodeID != nodeID || len(node.TurnIDs) == 0 {
				t.Fatalf("dialog node identity = %d %+v", nodeID, node)
			}
		}
	}
	if total != 13281 {
		t.Fatalf("dialog nodes = %d", total)
	}
	if len(domain.DialogSourceUnknowns) != 1 || domain.DialogSourceUnknowns[0] != 11001209 {
		t.Fatalf("dialog source unknowns = %v", domain.DialogSourceUnknowns)
	}
}

func TestLibraryCatalogOldRevisionWithoutDialogNodes(t *testing.T) {
	payload := loadedLibraryInputs(t)
	raw, e := json.Marshal(payload)
	if e != nil {
		t.Fatal(e)
	}
	var generic map[string]any
	if e = json.Unmarshal(raw, &generic); e != nil {
		t.Fatal(e)
	}
	delete(generic, "dialog_nodes")
	delete(generic, "dialog_source_unknowns")
	oldRaw, e := json.Marshal(generic)
	if e != nil {
		t.Fatal(e)
	}
	var old builtin.LibraryInputCatalog
	if e = json.Unmarshal(oldRaw, &old); e != nil {
		t.Fatal(e)
	}
	domain := domainFrom(t, old)
	if len(domain.DialogNodes) != 0 || len(domain.DialogSourceUnknowns) != 0 {
		t.Fatalf("old revision dialog metadata = %d/%d", len(domain.DialogNodes), len(domain.DialogSourceUnknowns))
	}
	if len(domain.Gifts) != 10 || len(domain.Talks) != 23 || len(domain.DialogConfigs) != 19 {
		t.Fatalf("unrelated catalogs changed gifts=%d talks=%d dialogs=%d", len(domain.Gifts), len(domain.Talks), len(domain.DialogConfigs))
	}
}

func TestLibraryCatalogRejectsMalformedDialogMetadata(t *testing.T) {
	negativeReward := int64(-1)
	for name, mutate := range map[string]func(*builtin.LibraryInputCatalog){
		"duplicate node":       func(p *builtin.LibraryInputCatalog) { p.DialogNodes = append(p.DialogNodes, p.DialogNodes[0]) },
		"zero dialog group":    func(p *builtin.LibraryInputCatalog) { p.DialogNodes[0].DialogGroup = 0 },
		"zero node id":         func(p *builtin.LibraryInputCatalog) { p.DialogNodes[0].NodeID = 0 },
		"empty turn ids":       func(p *builtin.LibraryInputCatalog) { p.DialogNodes[0].TurnIDs = nil },
		"zero turn id":         func(p *builtin.LibraryInputCatalog) { p.DialogNodes[0].TurnIDs = []int64{0} },
		"terminal with option": func(p *builtin.LibraryInputCatalog) { p.DialogNodes[0].TurnIDs = []int64{-1, 101002} },
		"negative reward":      func(p *builtin.LibraryInputCatalog) { p.DialogNodes[0].IsReward = &negativeReward },
		"duplicate unknown":    func(p *builtin.LibraryInputCatalog) { p.DialogSourceUnknowns = []int64{11001209, 11001209} },
	} {
		t.Run(name, func(t *testing.T) {
			payload := loadedLibraryInputs(t)
			mutate(&payload)
			if _, e := libraryCatalogDomain(payload, metadataRevision); e != library.ErrUnqualified {
				t.Fatalf("error = %v", e)
			}
		})
	}
}
