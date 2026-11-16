//go:build postgres

package playerdisplay_test

import (
	"fmt"
	"strconv"
	"testing"
	"time"

	d "gxb.local/backend/v2/internal/domain/oneonone"
)

// TestI9_11OneOnOneTitleNoticeNative proves the Sunday settlement notifies rank 1
// with one text-only LEGEND_KUAFU_MAIL notice and a replay of the same settlement
// adds none (recipient, kind, key source dedup).
func TestI9_11OneOnOneTitleNoticeNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := oneOnOneService(t, p)
	actor, _ := oneOnOnePlayer(t, p, rankingServer(t, p))
	catalog := oneOnOneCatalog(t, p)
	if _, err := s.Load(ctx, actor, op()); err != nil {
		t.Fatal(err)
	}
	now := time.Now()
	sunday := d.LocalDay(now)
	for d.Weekday(sunday) != 7 || d.Instant(sunday, catalog.SettlementSeconds).After(now) {
		sunday--
	}
	exec(t, p, `UPDATE one_on_one_players SET level=5,slot=NULL,state_version=state_version+1 WHERE player_id<>$1 AND slot IS NOT NULL`, int64(actor.PlayerID))
	exec(t, p, `UPDATE one_on_one_players SET level=1,slot=1,state_version=state_version+1 WHERE player_id=$1`, int64(actor.PlayerID))
	exec(t, p, `DELETE FROM one_on_one_settlement_ranks WHERE day>=$1`, sunday)
	exec(t, p, `DELETE FROM one_on_one_settlements WHERE day>=$1`, sunday)
	week := catalog.LatestPromotion(now)
	exec(t, p, `UPDATE one_on_one_competitions SET settled_through=$1,opened_through=$2,closed_through=$2,state_version=state_version+1`, sunday-1, week)

	if settled, err := s.Due(ctx, op()); err != nil || settled != 1 {
		t.Fatalf("Sunday settlement: settled=%d err=%v", settled, err)
	}
	sourceKey := strconv.FormatInt(sunday, 10)
	countNotice := func() int64 {
		return scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ONE_ON_ONE_TITLE'`, int64(actor.PlayerID))
	}
	if countNotice() != 1 {
		t.Fatalf("title notices=%d want 1", countNotice())
	}
	var title, sender, body, key string
	if err := p.Raw().QueryRow(ctx, `SELECT title,sender,body,source_key FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ONE_ON_ONE_TITLE'`, int64(actor.PlayerID)).Scan(&title, &sender, &body, &key); err != nil {
		t.Fatal(err)
	}
	wantBody := fmt.Sprintf(catalog.Mail["LEGEND_KUAFU_MAIL_TEXT"], 1)
	if title != catalog.Mail["LEGEND_KUAFU_MAIL_TITLE"] || sender != catalog.Mail["LEGEND_KUAFU_MAIL_SENDER"] || body != wantBody || key != sourceKey {
		t.Fatalf("title notice title=%q sender=%q body=%q key=%q", title, sender, body, key)
	}
	if scalar(t, p, `SELECT count(*) FROM mail_attachments a JOIN mail_records r USING(mail_uuid) WHERE r.recipient_player_id=$1 AND r.source_kind='ONE_ON_ONE_TITLE'`, int64(actor.PlayerID)) != 0 {
		t.Fatal("the title notice must carry no attachments")
	}

	// Replay the same settlement: the source dedup reuses the notice.
	exec(t, p, `DELETE FROM one_on_one_settlement_ranks WHERE day=$1`, sunday)
	exec(t, p, `DELETE FROM one_on_one_settlements WHERE day=$1`, sunday)
	exec(t, p, `UPDATE one_on_one_competitions SET settled_through=$1,state_version=state_version+1`, sunday-1)
	if settled, err := s.Due(ctx, op()); err != nil || settled != 1 {
		t.Fatalf("settlement replay: settled=%d err=%v", settled, err)
	}
	if countNotice() != 1 {
		t.Fatalf("a replayed settlement added a second title notice: %d", countNotice())
	}
	if scalar(t, p, `SELECT count(*) FROM one_on_one_settlement_ranks WHERE day=$1 AND player_id=$2 AND title_id=100002`, sunday, int64(actor.PlayerID)) != 1 {
		t.Fatal("the replay must still record the Sunday title rank")
	}
}
