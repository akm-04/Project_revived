package conquerschool_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/broadcast"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
)

// Lead reproduction (contract recovery, C5E/PASS758): the 3005 announcement a
// promotion builds must carry the cleared mission's region. The attribute-open
// region count is 0 for loop-1 mission 1, so broadcasting it rolled RESULT back.
func TestPromotionBroadcastCarriesClearedMissionRegion(t *testing.T) {
	c := modeCatalog(t)
	cases := []struct {
		name    string
		run     d.Run
		mission d.Mission
		want    int64
	}{
		{"loop-1 mission 1", d.Run{Loop: 1, CurrentID: 10001, Generation: "g"}, c.Missions[0], 1},
		{"region-2 mission", d.Run{Loop: 1, CurrentID: c.Missions[39].ID, PassedID: c.Missions[38].ID, Generation: "g"}, c.Missions[39], 2},
		{"loop-2 mission 1", d.Run{Loop: 2, CurrentID: 10001, Generation: "g"}, c.Missions[0], 1},
	}
	for _, x := range cases {
		t.Run(x.name, func(t *testing.T) {
			if x.mission.Region != x.want {
				t.Fatalf("fixture mission %d region=%d want %d", x.mission.ID, x.mission.Region, x.want)
			}
			m := c.NewMode(100001, time.Unix(1_800_000_000, 0))
			m.BeatenTeams = make([]int64, 0, x.mission.Teams)
			for team := int64(1); team < x.mission.Teams; team++ {
				m.BeatenTeams = append(m.BeatenTeams, team)
			}
			out, err := c.Settle(m, x.run, d.Progress{Level: x.mission.Level, Loop: x.run.Loop}, d.Result{CampaignID: x.run.CurrentID, TeamID: x.mission.Teams, Formation: []int64{1}, Win: true}, "attempt")
			if err != nil || !out.Promoted {
				t.Fatalf("not promoted: %+v %v", out, err)
			}
			if out.Region != x.want {
				t.Fatalf("announcement region=%d want %d", out.Region, x.want)
			}
			message := broadcast.Message{MID: broadcast.SystemMID, MsgType: broadcast.ConquerSchool, Server: 1, Player: 100001,
				Fields: broadcast.Fields{Region: out.Region, ConquerLoopID: out.Attempt.Loop, ConquerLev: out.Progress.Level}}
			if err := message.Validate(); err != nil {
				t.Fatalf("announcement cannot be broadcast: %v", err)
			}
		})
	}
}
