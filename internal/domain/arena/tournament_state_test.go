package arena

import (
	"encoding/json"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

func admissionFixture(t *testing.T, player identity.PlayerID) identity.ActorContext {
	t.Helper()
	identifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	account, _ := identity.AccountIDFrom(identifier)
	session, _ := identity.SessionIDFrom(identifier)
	contextIdentifier, _ := identity.ContextIDFrom(identifier)
	return identity.ActorContext{AccountID: account, AccountUID: "fixture", SessionID: session, ContextID: contextIdentifier, PlayerID: player, LogicalServerID: 1, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}

func TestTournamentAdmissionSurvivesJSONWithoutPrivateIdentityLoss(t *testing.T) {
	actor := admissionFixture(t, 100001)
	raw, err := json.Marshal(AdmissionFrom(actor))
	if err != nil {
		t.Fatal(err)
	}
	var recovered AdmissionContext
	if err := json.Unmarshal(raw, &recovered); err != nil {
		t.Fatal(err)
	}
	actual, err := recovered.Actor()
	if err != nil || actual != actor {
		t.Fatal("admission provenance lost during durable serialization", err)
	}
	recovered.ContextID = ids.UUID{}
	if _, err := recovered.Actor(); err == nil {
		t.Fatal("missing context accepted")
	}
}

func TestTournamentCatalogPinsSourceAndRejectsMalformedRewardOrder(t *testing.T) {
	compiled := catalog(t)
	if compiled.Tournament == nil || compiled.Tournament.Validate() != nil {
		t.Fatal("compiled tournament missing")
	}
	for _, check := range []struct {
		rank    int64
		casual  bool
		crystal int64
		mana    int64
	}{{1, false, 0, 20000000}, {1, true, 2000, 2000000}, {1000, true, 300, 300000}} {
		reward, found := compiled.Tournament.RewardFor(check.rank, check.casual)
		if !found || reward.Crystal != check.crystal || reward.Mana != check.mana {
			t.Fatal("source reward mismatch", reward)
		}
	}
	if _, found := compiled.Tournament.RewardFor(1001, true); found {
		t.Fatal("invented reward beyond source bands")
	}
	compiled.Tournament.CasualRewards[1].Rank = 1
	if compiled.Tournament.Validate() == nil {
		t.Fatal("duplicate rank band accepted")
	}
}

func TestTournamentRoomRefusesUnfrozenTerminalAndMissingAdmission(t *testing.T) {
	first, second := admissionFixture(t, 100001), admissionFixture(t, 100002)
	identifier, _ := ids.NewUUID()
	at := time.Date(2026, 10, 31, 10, 0, 0, 0, time.UTC)
	selection, _ := NewSelectionRoom(first.PlayerID, second.PlayerID, at)
	room := TournamentRoom{Identifier: identifier, Casual: true, CasualWeekDay: CasualPeriodAt(at).WeekDay, Actors: [2]AdmissionContext{AdmissionFrom(first), AdmissionFrom(second)}, Selection: selection, Status: RoomSelecting, StartsAt: at, ContentRevision: strings.Repeat("a", 64), Contest: 1, StateVersion: 1}
	if room.Validate() != nil {
		t.Fatal("valid pending room rejected")
	}
	room.Status = RoomSettled
	if room.Validate() == nil {
		t.Fatal("unfrozen room claimed terminal")
	}
	room.Status = RoomSelecting
	room.Actors[1].SessionID = ids.UUID{}
	if room.Validate() == nil {
		t.Fatal("invalid persisted provenance accepted")
	}
}
