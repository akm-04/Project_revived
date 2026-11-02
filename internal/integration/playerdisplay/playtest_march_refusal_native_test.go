//go:build postgres

package playerdisplay_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	appMarch "gxb.local/backend/v2/internal/application/march"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type playtestAuthority struct{ actor identity.ActorContext }

func (a playtestAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

func playtestRequest(a identity.ActorContext, mid uint16, params map[string]any) httpedge.DispatchRequest {
	params["v_"] = "1.0.0"
	params["app_v"] = "1.0.0"
	params["platform"] = "android"
	var r httpedge.DispatchRequest
	r.Envelope.MID = mid
	r.Envelope.Params = params
	r.Envelope.Operation = op()
	r.Envelope.ReceivedAt = time.Now().UTC()
	r.Envelope.Claims.Token = "playtest-admitted-actor"
	r.Envelope.Claims.Region = int64(a.LogicalServerID)
	return r
}

func playtestStatuses(statuses []cd.ActorStatus, allies bool) []any {
	rows := make([]any, 0, len(statuses))
	for _, status := range statuses {
		row := map[string]any{"hero_id": status.Identity, "hp": status.HP, "mp": status.MP, "is_reborn": status.Reborn}
		if allies {
			row["player_id"] = status.Player
		}
		rows = append(rows, row)
	}
	return rows
}

func playtestReport(q appMarch.Result) map[string]any {
	return map[string]any{"win": q.Report.Win, "is_reborn": int64(0),
		"hero_status": playtestStatuses(q.Report.Allies, true), "enemy_status": playtestStatuses(q.Report.Enemies, false), "cost_drink": q.CostDrink}
}

func playtestConflict(t *testing.T, response httpedge.Response, path string) {
	t.Helper()
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("%s reached the success callback: %+v", path, response)
	}
}

func playtestMarchLocator(a identity.ActorContext) cd.Locator {
	return cd.Locator{DomainKind: "CHAMPION_MARCH", AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID), DomainLocator: fmt.Sprintf("player:%d", a.PlayerID)}
}

func TestPlaytestMarchRefusalsAreConflictsAndCloseTheAttempt(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := bornActor(t, p)
	mode := marchMode(t, p)
	bornHero(t, p, a, revision, 10001001, 1)
	compositeLevel(t, p, a, revision, 30)
	dispatcher := stockruntime.MarchDispatcher{Authority: playtestAuthority{a}, Service: mode}
	team := []int64{1, 0, 0, 0, 0}

	noAttempt := appMarch.Result{Report: cd.Report{Win: true,
		Allies:  []cd.ActorStatus{{Player: int64(a.PlayerID), Identity: 1, HP: 1, MP: 1}},
		Enemies: []cd.ActorStatus{{Identity: 2, HP: 0, MP: 0}}}}
	playtestConflict(t, dispatcher.Dispatch(ctx, playtestRequest(a, 338, playtestReport(noAttempt))), "no pending attempt")

	start := playtestRequest(a, 340, map[string]any{"campaign_type": int64(5), "formation": "1|0|0|0|0"})
	if response := dispatcher.Dispatch(ctx, start); response.HTTPStatus != 200 {
		t.Fatalf("START %+v", response)
	}
	rejected := marchReport(marchRecord(t, p, a), int64(a.PlayerID), team, true)
	rejected.Report.Enemies = rejected.Report.Enemies[:len(rejected.Report.Enemies)-1]
	playtestConflict(t, dispatcher.Dispatch(ctx, playtestRequest(a, 338, playtestReport(rejected))), "rejected summary")
	if record := marchRecord(t, p, a); record.Pending != "" || len(record.Heroes) != 0 {
		t.Fatalf("rejected attempt not closed: %+v", record)
	}
	if response := dispatcher.Dispatch(ctx, playtestRequest(a, 340, map[string]any{"campaign_type": int64(5), "formation": "1|0|0|0|0"})); response.HTTPStatus != 200 {
		t.Fatalf("START after rejection %+v", response)
	}

	pending := marchRecord(t, p, a).Pending
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = combatService(t, p).CloseTx(ctx, tr, appcombat.TerminalRequest{Locator: playtestMarchLocator(a), GenerationRef: pending,
		TerminalKind: "MARCH_RESULT", SemanticReceiptID: "playtest-drain:" + pending, At: time.Now().UTC()}); err != nil {
		tr.Rollback(ctx)
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	valid := marchReport(marchRecord(t, p, a), int64(a.PlayerID), team, true)
	playtestConflict(t, dispatcher.Dispatch(ctx, playtestRequest(a, 338, playtestReport(valid))), "drained summary")
	if record := marchRecord(t, p, a); record.Pending != "" {
		t.Fatalf("drained attempt not closed: %+v", record)
	}
	if response := dispatcher.Dispatch(ctx, playtestRequest(a, 340, map[string]any{"campaign_type": int64(5), "formation": "1|0|0|0|0"})); response.HTTPStatus != 200 {
		t.Fatalf("START after drain %+v", response)
	}
}
