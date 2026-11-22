package socialrecall

import (
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/foundation/ids"
)

func TestAwardMarkerBindsOncePerPlayerMilestone(t *testing.T) {
	operation, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	source := grant.SourceIdentity{Domain: "socialrecall", Operation: "milestone_award", BusinessKey: "125001:100001", PolicyVersion: RecallPolicyVersion}
	record := AwardRecord{Player: 125001, Server: 1, AwardID: 100001, GiftID: 90000001, OperationID: operation, Revision: strings.Repeat("a", 64), PolicyVersion: RecallPolicyVersion, GrantKey: source.SemanticKey(), EarnedAt: time.Unix(100, 0).UTC()}
	if record.Validate() != nil {
		t.Fatal("valid marker refused")
	}
	for _, name := range []string{"player", "award", "policy", "revision", "source"} {
		changed := record
		switch name {
		case "player":
			changed.Player++
		case "award":
			changed.AwardID++
		case "policy":
			changed.PolicyVersion = "unsupported"
		case "revision":
			changed.Revision = "missing"
		case "source":
			changed.GrantKey = strings.Repeat("b", 64)
		}
		if changed.Validate() == nil {
			t.Fatal("invalid marker accepted", name)
		}
	}
	replacement, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	record.OperationID = replacement
	record.Revision = strings.Repeat("b", 64)
	if record.Validate() != nil {
		t.Fatal("operation or content revision changed permanent entitlement identity")
	}
}
