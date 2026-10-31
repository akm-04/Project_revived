package illusion

import (
	"encoding/json"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/modes"
)

func TestValidateFormation(t *testing.T) {
	for _, bad := range [][]int64{nil, {}, {0}, {1, 1}, {1, 2, 3, 4, 5, 6}} {
		if validateFormation(bad) == nil {
			t.Fatalf("accepted %#v", bad)
		}
	}
	if validateFormation([]int64{5, 4, 3}) != nil {
		t.Fatal("valid formation refused")
	}
}

func TestParseFormationText(t *testing.T) {
	if got := parseFormationText("7|8|9"); len(got) != 3 || got[2] != 9 {
		t.Fatalf("got %#v", got)
	}
	if parseFormationText("7|x") != nil {
		t.Fatal("malformed text accepted")
	}
	if parseFormationText("") != nil {
		t.Fatal("empty text")
	}
}

func TestGuildScoresSumCurrentMemberBestHits(t *testing.T) {
	guilds := []GuildSummary{
		{ID: 2, Name: "second", Members: []identity.PlayerID{11, 12}},
		{ID: 1, Name: "first", Members: []identity.PlayerID{21, 22}},
		{ID: 3, Name: "third", Members: []identity.PlayerID{31}},
	}
	results := []d.Result{
		{PlayerID: 11, Hurt: 100, CostTime: 5},
		{PlayerID: 12, Hurt: 50, CostTime: 4},
		{PlayerID: 21, Hurt: 90, CostTime: 3},
		{PlayerID: 22, Hurt: 70, CostTime: 6},
		{PlayerID: 31, Hurt: 10, CostTime: 1},
		{PlayerID: 99, Hurt: 1000, CostTime: 1},
	}
	scores := guildScores(guilds, results)
	if len(scores) != 3 {
		t.Fatal(scores)
	}
	if scores[0].Guild.ID != 1 || scores[0].Total != 160 {
		t.Fatalf("leader %#v", scores[0])
	}
	if scores[1].Guild.ID != 2 || scores[1].Total != 150 {
		t.Fatalf("second %#v", scores[1])
	}
	if scores[2].Guild.ID != 3 || scores[2].Total != 10 {
		t.Fatalf("third %#v", scores[2])
	}
}

func TestPlayerRowCarriesSourceFields(t *testing.T) {
	profile := playerdirectory.Profile{PlayerID: 100001, Name: "name", Level: 70, AvatarID: 11, AvatarFrameID: 12, ConquerLevel: 3, ConquerLoopID: 2}
	row := playerRow(profile, 120, 4)
	for key, want := range map[string]int64{"player_id": 100001, "level": 70, "avatar_id": 11, "avatar_frame_id": 12, "conquer_lev": 3, "conquer_loop_id": 2, "hurt": 120, "rank": 4} {
		if row[key] != want {
			t.Fatalf("%s=%v want %d", key, row[key], want)
		}
	}
	if row["player_name"] != "name" {
		t.Fatalf("name=%v", row["player_name"])
	}
}

func TestClampDamageBoundedByPoolAndCap(t *testing.T) {
	if got := d.ClampDamage(d.DefaultPoolHP, 0, d.DamageCap+1); got != d.DamageCap {
		t.Fatalf("cap got=%d", got)
	}
	if got := d.ClampDamage(d.DefaultPoolHP, d.DefaultPoolHP-30, 100); got != 30 {
		t.Fatalf("pool got=%d", got)
	}
	if got := d.ClampDamage(d.DefaultPoolHP, 0, 0); got != 0 {
		t.Fatalf("zero got=%d", got)
	}
}

func generatedCatalog(t *testing.T) d.Catalog {
	t.Helper()
	raw, err := builtin.GeneratedFile("illusion_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog d.Catalog
	if err = json.Unmarshal(raw, &catalog); err != nil {
		t.Fatal(err)
	}
	if err = catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	return catalog
}

// clientNextBoss mirrors IllusionCampaignTable.nextBoss; ok is false when the
// client would spin forever on an unknown or terminal next id.
func clientNextBoss(catalog d.Catalog, id, count int64) (int64, bool) {
	if count == 0 {
		return id, true
	}
	for steps := 0; steps <= len(catalog.Campaigns); steps++ {
		campaign, found := catalog.Campaign(id)
		if !found || campaign.NextID == 0 {
			return 0, false
		}
		id = campaign.NextID
		next, found := catalog.Campaign(id)
		if found && !next.Hidden {
			return id, true
		}
	}
	return 0, false
}

func TestInfoBodyClientNextBossLandsOnThePhaseTarget(t *testing.T) {
	catalog := generatedCatalog(t)
	zone := time.FixedZone("GMT+8", 8*3600)
	open := time.Date(2026, 10, 31, 12, 0, 0, 0, zone)
	openDay := modes.Day(open)
	for _, phase := range []struct {
		name string
		at   time.Time
		want d.Phase
	}{
		{"waiting", open.Add(-24 * time.Hour), d.PhaseWaiting},
		{"open", open, d.PhaseOpen},
		{"closed", time.Date(2026, 10, 31, 21, 59, 0, 0, zone), d.PhaseClosed},
		{"settlement", time.Date(2026, 10, 31, 22, 30, 0, 0, zone), d.PhaseSettlement},
		{"rest", open.Add(24 * time.Hour), d.PhaseRest},
	} {
		for _, campaign := range catalog.Campaigns {
			occurrence := d.NewOccurrence(1, campaign.ID, openDay)
			if got := occurrence.PhaseAt(phase.at); got != phase.want {
				t.Fatalf("%d %s: phase %s", campaign.ID, phase.name, got)
			}
			paradise := infoBody(catalog, occurrence, d.Player{Chances: 5}, 0, 0, phase.at)["paradise_info"].(map[string]any)
			id, count := paradise["paradise_id"].(int64), paradise["count"].(int64)
			target := campaign.ID
			switch phase.want {
			case d.PhaseOpen:
				if id != campaign.ID || count != 0 {
					t.Fatalf("%d open: %d/%d", campaign.ID, id, count)
				}
			case d.PhaseWaiting:
				previous := catalog.PreviousCampaignID(campaign.ID)
				if previous == 0 {
					if id != campaign.ID || count != 0 {
						t.Fatalf("%d waiting terminal: %d/%d", campaign.ID, id, count)
					}
				} else if id != previous || count != 1 {
					t.Fatalf("%d waiting: %d/%d want %d/1", campaign.ID, id, count, previous)
				}
			default:
				if campaign.NextID == 0 {
					if id != campaign.ID || count != 0 {
						t.Fatalf("%d %s terminal: %d/%d", campaign.ID, phase.name, id, count)
					}
				} else {
					if id != campaign.ID || count != 1 {
						t.Fatalf("%d %s: %d/%d", campaign.ID, phase.name, id, count)
					}
					target = catalog.NextCampaignID(campaign.ID)
				}
			}
			landed, ok := clientNextBoss(catalog, id, count)
			if !ok || landed != target {
				t.Fatalf("%d %s: client lands %d/%v want %d", campaign.ID, phase.name, landed, ok, target)
			}
		}
	}
}
