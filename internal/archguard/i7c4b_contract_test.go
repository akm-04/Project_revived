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
	s := string(b)
	for _, v := range []string{"librarySvc.Achievements = appachievement.Service", "achievementstore.BootstrapContributor{Revision: dormBundle.RevisionID()}"} {
		if !strings.Contains(s, v) {
			t.Fatal("missing production achievement wiring", v)
		}
	}
}
