//go:build postgres

package playerdisplay_test

import (
	"net/http"
	"testing"
	"time"
)

func TestI9I11ANativeTunedSkillTunablesDriveReplyAndCap(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	actor := privilegeActor(t, database, revision)
	if _, err := privilegeService(database, database).ImportManual(ctx, authority(), importQ(actor, uuid().String(), 300), op()); err != nil {
		t.Fatal(err)
	}
	i911aSetScalar(t, database, actor, "crystal", 100000)
	i911aSetSkillPoint(t, database, actor, 10)
	i911aStack(t, database, actor, 50001538, 5)
	exec(t, database, `INSERT INTO items_energy_tuning(payload,payload_version,updated_at)VALUES($1::jsonb,1,clock_timestamp()) ON CONFLICT(singleton)DO UPDATE SET payload=excluded.payload,payload_version=excluded.payload_version,updated_at=excluded.updated_at`,
		`{"version":1,"buy_skill_cost":[123],"vip_skill_max":{"2":50},"skill_point_item_amount":25}`)
	t.Cleanup(func() { exec(t, database, `DELETE FROM items_energy_tuning`) })
	dispatcher := i911aComposition(database, actor).Dispatcher

	buy := i911aDispatch(t, dispatcher, actor, 99, map[string]any{}, op())
	i911aExpect(t, buy, http.StatusOK, 0)
	if i911aScalar(t, database, actor, "crystal") != 100000-123 || buy.Body["skill_point"] != int64(20) {
		t.Fatalf("tuned price reply %#v crystal %d", buy.Body, i911aScalar(t, database, actor, "crystal"))
	}
	use := i911aDispatch(t, dispatcher, actor, 90, map[string]any{"item_id": int64(50001538), "item_num": int64(1)}, op())
	i911aExpect(t, use, http.StatusOK, 0)
	if use.Body["skill_point"] != int64(45) {
		t.Fatalf("tuned item amount reply %#v", use.Body)
	}

	exec(t, database, `INSERT INTO commerce_charge_cards(player_id,month_card_start,month_card_end,privilege_card_end,updated_at)VALUES($1,0,0,$2,clock_timestamp())`, int64(actor.PlayerID), time.Now().Add(time.Hour).Unix())
	exec(t, database, `INSERT INTO commerce_recharge_tuning(singleton,payload,payload_version,updated_at)VALUES(true,$1::jsonb,1,clock_timestamp()) ON CONFLICT(singleton)DO UPDATE SET payload=excluded.payload,payload_version=excluded.payload_version,updated_at=excluded.updated_at`,
		`{"version":1,"mode":"GRANT","privilege_skill_max":25}`)
	t.Cleanup(func() { exec(t, database, `DELETE FROM commerce_recharge_tuning`) })
	snapshot, err := privilegeProvider(database).SnapshotTx(ctx, database, actor.PlayerID, time.Now())
	if err != nil {
		t.Fatal(err)
	}
	if snapshot.SkillPointNaturalCap != 35 {
		t.Fatalf("tuned privilege cap %d, want VIP2 source 10 + tuned 25", snapshot.SkillPointNaturalCap)
	}
}
