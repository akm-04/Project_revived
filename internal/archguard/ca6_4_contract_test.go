package archguard

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

func TestCA64AutoRoutingAndProjectionAreExact(t *testing.T) {
	root := repoRoot(t)
	mainBytes, err := os.ReadFile(filepath.Join(root, "cmd", "gxb-api", "main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	main := string(mainBytes)
	re := regexp.MustCompile(`(?s)for _, mid := range \[\]uint16\{([^}]*)\} \{\s*mustRegister\(mid, practiceD\)`)
	m := re.FindStringSubmatch(main)
	if len(m) != 2 {
		t.Fatal("Practice route list not found")
	}
	got := strings.NewReplacer(" ", "", "\n", "", "\t", "").Replace(m[1])
	if got != "124,125,126,127,128,129,130,131,132,133" {
		t.Fatalf("Practice route list=%q", got)
	}
	if strings.Contains(got, "134") {
		t.Fatal("AUTO routing captured MID134")
	}

	decoderBytes, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "stockruntime", "practice_auto_decoder.go"))
	if err != nil {
		t.Fatal(err)
	}
	decoder := string(decoderBytes)
	for _, need := range []string{"case 127:", "case 132:", `"practice_num"`, `"save_types"`, "locked Practice AUTO axis must be selected"} {
		if !strings.Contains(decoder, need) {
			t.Errorf("AUTO decoder missing %q", need)
		}
	}

	projectionBytes, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "stockruntime", "practice_auto_dispatcher.go"))
	if err != nil {
		t.Fatal(err)
	}
	projection := string(projectionBytes)
	for _, need := range []string{"d.Service.Auto", `"info"`, `"add_attrs"`, `"is_adds"`, `"practice_attr"`} {
		if !strings.Contains(projection, need) {
			t.Errorf("AUTO projection missing %q", need)
		}
	}
}

func TestCA64AutoCompositionReusesOwnersAndHasNoProposalOrSQLOwnership(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "internal", "application", "characterpractice", "auto_service.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	for _, need := range []string{
		"gxb.ca6.practice-auto.v1", "receipt.Resolver", "FenceActorTx", "lockTarget", "LockPracticeRootTx",
		"planAutoBatchV1", "AuthorizeLevelAndDebitScalarTx", "SaveAccountingTx", "applyPracticeTx", "putAutoReceipt",
	} {
		if !strings.Contains(s, need) {
			t.Errorf("AUTO service missing %q", need)
		}
	}
	for _, bad := range []string{"ProposalTx", "UpsertHeroProposal", "UpsertPetProposal", "DeleteHeroProposal", "DeletePetProposal", "SELECT ", "INSERT INTO ", "UPDATE ", "DELETE FROM "} {
		if strings.Contains(s, bad) {
			t.Errorf("AUTO service leaked forbidden ownership/lifecycle marker %q", bad)
		}
	}
	autoStart := strings.Index(s, "func (s Service) Auto(")
	if autoStart < 0 {
		t.Fatal("AUTO service method not found")
	}
	autoBody := s[autoStart:]
	order := []string{"FenceActorTx", "lockTarget", "LockPracticeRootTx", "planAutoBatchV1", "AuthorizeLevelAndDebitScalarTx", "SaveAccountingTx", "applyPracticeTx", "putAutoReceipt"}
	last := -1
	for _, tok := range order {
		i := strings.Index(autoBody, tok)
		if i < 0 || i <= last {
			t.Fatalf("AUTO service ordering marker %q out of order", tok)
		}
		last = i
	}
}
