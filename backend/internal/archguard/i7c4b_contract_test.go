package archguard

import (
	"os"
	"strings"
	"testing"
)

func TestI7C4BProductionOwnerAndProducerWiring(t *testing.T) {
	b, e := os.ReadFile("../../cmd/gxb-api/main_postgres.go")
	if e != nil {
		t.Fatal(e)
	}
	birth, e := os.ReadFile("../adapters/postgres/characterbirth/contributors.go")
	if e != nil {
		t.Fatal(e)
	}
	s := string(b) + string(birth)
	for _, v := range []string{"librarySvc.Achievements = appachievement.Service", "characterbirth.Contributors(contentstore.Store{Queryer: pool}, privileges, dormBundle.RevisionID())", "achievementstore.BootstrapContributor{Revision: revision}"} {
		if !strings.Contains(s, v) {
			t.Fatal("missing production achievement wiring", v)
		}
	}
}
