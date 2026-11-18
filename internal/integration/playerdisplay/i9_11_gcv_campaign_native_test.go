//go:build postgres

package playerdisplay_test

import (
	"net/http"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	app "gxb.local/backend/v2/internal/application/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func gcvDispatch(t *testing.T, f campaignFixture, a identity.ActorContext, mid uint16, params map[string]any) httpedge.Response {
	t.Helper()
	all := map[string]any{"token": "bearer", "region": int64(f.server)}
	for key, value := range params {
		all[key] = value
	}
	request := httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		Operation: f.op(), MID: mid, Params: all,
		Claims:     wire.CredentialClaims{Token: "bearer", Region: int64(f.server)},
		ReceivedAt: f.at,
	}}
	return stockruntime.GuildCampaignDispatcher{Authority: fixedSocialAuthority{actor: a}, Service: f.mode}.Dispatch(ctx, request)
}

func gcvChapterRow(t *testing.T, response httpedge.Response, chapterID int64) map[string]any {
	t.Helper()
	if response.HTTPStatus != http.StatusOK {
		t.Fatalf("reply %d %+v", response.HTTPStatus, response.Body)
	}
	rows, ok := response.Body["chapter_list"].([]any)
	if !ok {
		t.Fatalf("chapter_list %#v", response.Body["chapter_list"])
	}
	for _, entry := range rows {
		row, ok := entry.(map[string]any)
		if ok && row["chapter_id"] == chapterID {
			return row
		}
	}
	t.Fatalf("chapter %d missing from %v", chapterID, rows)
	return nil
}

func gcvSeedAward(t *testing.T, f campaignFixture) int64 {
	t.Helper()
	chapterID, _ := f.copyID(t)
	info := f.chapter(t)
	tr := f.openTx(t)
	if err := f.store().SaveChapterProgressTx(ctx, tr, int64(f.guild), chapterID, 1, 1, true, &f.at); err != nil {
		t.Fatal("chapter win", err)
	}
	seed := app.AwardSeed{AwardID: info.Items[0], Remaining: 3, ExpiresAt: f.at.Add(time.Duration(f.settings.RewardTimeLimitSecond) * time.Second), NextSlot: f.nextSlot(f.at)}
	if err := f.store().InsertAwardsTx(ctx, tr, int64(f.guild), chapterID, 1, []app.AwardSeed{seed}); err != nil {
		t.Fatal("award seed", err)
	}
	if err := tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		exec(t, f.pool, `UPDATE guild_campaign_awards SET remaining=0 WHERE guild_id=$1 AND chapter_id=$2 AND run=1`, int64(f.guild), chapterID)
	})
	return chapterID
}

func TestGCVDefaultPolicyKeepsChapterVersionOne(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	chapterID := gcvSeedAward(t, f)
	info := f.chapter(t)

	for _, mid := range []uint16{601, 603} {
		response := gcvDispatch(t, f, f.leader, mid, map[string]any{})
		row := gcvChapterRow(t, response, 7)
		if row["chapter_version"] != int64(1) {
			t.Fatalf("MID %d chapter 7 version %#v", mid, row["chapter_version"])
		}
		rows := response.Body["chapter_list"].([]any)
		for _, entry := range rows {
			if version := entry.(map[string]any)["chapter_version"]; version != int64(1) {
				t.Fatalf("MID %d row %v carries version %#v", mid, entry, version)
			}
		}
	}

	awardRead := gcvDispatch(t, f, f.second, 605, map[string]any{"chapter_id": chapterID})
	if awardRead.HTTPStatus != http.StatusOK {
		t.Fatalf("MID 605 at the default policy: %+v", awardRead)
	}
	applied := gcvDispatch(t, f, f.second, 606, map[string]any{"chapter_id": chapterID, "award_id": info.Items[0]})
	if applied.HTTPStatus != http.StatusOK {
		t.Fatalf("MID 606 at the default policy: %+v", applied)
	}
}

func TestGCVChapterVersionTwoRefusesAwardQueue(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	f.mode.Settings.ChapterVersions = map[int64]int64{7: 2}
	chapterID := gcvSeedAward(t, f)
	info := f.chapter(t)

	row := gcvChapterRow(t, gcvDispatch(t, f, f.leader, 601, map[string]any{}), 7)
	if row["chapter_version"] != int64(2) {
		t.Fatalf("chapter 7 version %#v", row["chapter_version"])
	}
	other := gcvChapterRow(t, gcvDispatch(t, f, f.leader, 601, map[string]any{}), 8)
	if other["chapter_version"] != int64(1) {
		t.Fatalf("chapter 8 version %#v", other["chapter_version"])
	}

	for mid, params := range map[uint16]map[string]any{
		605: {"chapter_id": chapterID},
		606: {"chapter_id": chapterID, "award_id": info.Items[0]},
	} {
		response := gcvDispatch(t, f, f.second, mid, params)
		if response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != int64(35028) {
			t.Fatalf("MID %d on a version 2 chapter: %d %+v", mid, response.HTTPStatus, response.Body)
		}
	}
	if rows := scalar(t, f.pool, `SELECT count(*) FROM guild_campaign_applications WHERE guild_id=$1 AND chapter_id=$2`, int64(f.guild), chapterID); rows != 0 {
		t.Fatalf("refused 606 wrote %d application rows", rows)
	}
	if remaining := scalar(t, f.pool, `SELECT remaining FROM guild_campaign_awards WHERE guild_id=$1 AND chapter_id=$2 AND run=1`, int64(f.guild), chapterID); remaining != 3 {
		t.Fatalf("refused 606 changed the award pool to %d", remaining)
	}
}
