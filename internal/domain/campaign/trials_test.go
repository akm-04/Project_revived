package campaign

import (
	"errors"
	"gxb.local/backend/v2/internal/domain/modes"
	"reflect"
	"testing"
)

func TestTrialCalendarQuotaAndFactions(t *testing.T) {
	c := loadCatalog(t)
	p := Progress{}
	for day := int64(0); day < 42; day++ {
		current := c.Prophecy(day)
		next, _ := c.Group(current)
		if c.Prophecy(day+1) != next.NextID {
			t.Fatal("rotation successor drift")
		}
		for _, g := range c.TrialGroups {
			row := c.TrialRow(p, g, day, 0, true)
			if row["left_times"] != g.DailyLimit || row["last_id"] != g.LastID {
				t.Fatalf("group %+v", row)
			}
			n, _ := c.Node(g.Nodes[0])
			_, err := c.AdmitTrial(p, g.ID, n.ID, 100, day, 0, true)
			if (err == nil) != g.Scheduled(c, day) {
				t.Fatalf("schedule %d day%d: %v", g.ID, day, err)
			}
			if _, err = c.AdmitTrial(p, g.ID, n.ID, n.OpenLevel-1, day, 0, true); !errors.Is(err, ErrRefused) {
				t.Fatal("level guard", err)
			}
		}
	}
	g, _ := c.Group(11)
	day := int64(4) // Monday
	n, _ := c.Node(g.Nodes[0])
	for i := int64(0); i < g.DailyLimit; i++ {
		out, e := c.Settle(p, n, 1, day, true)
		if e != nil {
			t.Fatal(e)
		}
		p = out.Progress
	}
	if _, e := c.AdmitTrial(p, 11, n.ID, 100, day, 0, true); !errors.Is(e, ErrRefused) {
		t.Fatal("shared quota", e)
	}
	if _, e := c.AdmitTrial(p, 11, g.Nodes[1], 100, day, 1, true); e != nil {
		t.Fatal("purchased quota", e)
	}
	if c.TrialRemaining(p, g, day-1, 0) != 0 || c.TrialRemaining(p, g, day+1, 0) != 5 {
		t.Fatal("counter rollover/rollback")
	}
	lost, e := c.Settle(p, n, 0, day, true)
	if e != nil || !reflect.DeepEqual(lost.Progress.TrialWins, p.TrialWins) {
		t.Fatal("loss spent quota")
	}
	if c.AllowFaction(11, 0) || c.AllowFaction(12, 0) || c.AllowFaction(13, 0) {
		t.Fatal("unknown template accepted")
	}
	for id, f := range c.HeroFactions {
		if c.AllowFaction(11, id) != (f != 3) || c.AllowFaction(12, id) != (f != 2) || c.AllowFaction(13, id) != (f == 2 || f == 3) {
			t.Fatalf("faction guard %d/%d", id, f)
		}
	}
	g, _ = c.Group(40)
	if _, e := c.AdmitTrial(Progress{}, 40, g.Nodes[1], 100, day, 0, true); !errors.Is(e, ErrRefused) {
		t.Fatal("Cloud predecessor", e)
	}
	p = Progress{Nodes: map[int64]NodeState{g.Nodes[0]: {CampaignID: g.Nodes[0], Star: 1}}}
	if _, e := c.AdmitTrial(p, 40, g.Nodes[1], 100, day, 0, true); e != nil {
		t.Fatal(e)
	}
	p.TrialWins = map[int64]modes.Counter{40: {Period: day + 1, Used: 1}}
	if c.TrialRemaining(p, g, day, 1) != 0 {
		t.Fatal("future quota grants value")
	}
}

func TestChallengeBranchOpeningAndFirstClearDrops(t *testing.T) {
	c := loadCatalog(t)
	p := Progress{Nodes: map[int64]NodeState{}}
	for _, id := range []int64{c.ChallengeGateCampaignID, 100001, 100002, 100004} {
		p.Nodes[id] = NodeState{CampaignID: id, Star: 3}
	}
	n, e := c.Admit(p, Challenge, 24111, 80, 1, true)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = c.Admit(p, Challenge, 24111, 79, 1, true); !errors.Is(e, ErrRefused) {
		t.Fatal("Challenge level", e)
	}
	if _, e = c.Admit(p, Challenge, 24112, 100, 1, true); !errors.Is(e, ErrRefused) {
		t.Fatal("parent guard", e)
	}
	out, e := c.Settle(p, n, 3, 1, true)
	if e != nil {
		t.Fatal(e)
	}
	if len(out.Touched) != 3 || out.Touched[0] != 24111 || out.Touched[1] != 24112 || out.Touched[2] != 24121 {
		t.Fatalf("branch touched %v", out.Touched)
	}
	if n.BattleBox(out.Progress) != 0 {
		t.Fatal("repeat Challenge dropbox")
	}
	for _, id := range out.Touched[1:] {
		if _, e := c.Admit(out.Progress, Challenge, id, 80, 1, true); e != nil {
			t.Fatal(id, e)
		}
	}
}
