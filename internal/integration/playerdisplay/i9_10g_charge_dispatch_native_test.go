//go:build postgres

package playerdisplay_test

import (
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	ps "gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	cp "gxb.local/backend/v2/internal/application/commerceprivilege"
	d "gxb.local/backend/v2/internal/domain/privilege"
)

func revisionWithoutChargeCapability(t *testing.T, p *pg.Pool, revision string) string {
	t.Helper()
	var raw string
	if e := p.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		t.Fatal(e)
	}
	var manifest map[string]json.RawMessage
	if e := json.Unmarshal([]byte(raw), &manifest); e != nil {
		t.Fatal(e)
	}
	delete(manifest, "revision_id")
	var capabilities []string
	if e := json.Unmarshal(manifest["enabled_capabilities"], &capabilities); e != nil {
		t.Fatal(e)
	}
	kept := make([]string, 0, len(capabilities))
	for _, capability := range capabilities {
		if capability != "COMMERCE_CHARGE_I9_10G" {
			kept = append(kept, capability)
		}
	}
	manifest["enabled_capabilities"], _ = json.Marshal(kept)
	basis, e := json.Marshal(manifest)
	if e != nil {
		t.Fatal(e)
	}
	historical := fmt.Sprintf("%x", sha256.Sum256(basis))
	manifest["revision_id"], _ = json.Marshal(historical)
	payload, e := json.Marshal(manifest)
	if e != nil {
		t.Fatal(e)
	}
	exec(t, p, `INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest) SELECT $2,decode($2,'hex'),schema_version,compiler_version,parser_version,$3::jsonb FROM gxb_content_revisions WHERE revision_id=$1 ON CONFLICT DO NOTHING`, revision, historical, string(payload))
	exec(t, p, `INSERT INTO content_privilege_catalogs(revision_id,payload) SELECT $2,payload FROM content_privilege_catalogs WHERE revision_id=$1 ON CONFLICT DO NOTHING`, revision, historical)
	return historical
}

func TestI910GPrivilegeOldRevisionWithoutChargeCatalogLogsIn(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := bornActor(t, p)
	historical := revisionWithoutChargeCapability(t, p, revision)
	if _, e := (contentstore.Store{Queryer: p}).ChargeCatalogTx(ctx, p, historical); !errors.Is(e, d.ErrUnavailable) {
		t.Fatalf("historical revision still reads the charge catalog: %v", e)
	}
	exec(t, p, `INSERT INTO commerce_privilege_roots(player_id,logical_server_id,qualifying_charge,vip_level,monthly_state,content_revision,policy_version,origin_class,issuer,reason,state_version,created_at,updated_at)VALUES($1,$2,100,1,'QUALIFIED_ABSENT',$3,'C4A_MANUAL_PRIVILEGE_SNAPSHOT_V1','MANUAL_PRESERVATION','native','i910g old revision',1,clock_timestamp()-interval '1 day',clock_timestamp()-interval '1 day')`, int64(a.PlayerID), int64(a.LogicalServerID), historical)
	now := time.Now().UTC()
	snapshot, e := privilegeProvider(p).SnapshotTx(ctx, p, a.PlayerID, now)
	if e != nil || snapshot.VIPLevel != 1 || snapshot.SkillPointNaturalCap != 10 || snapshot.MonthlyPrivilegeActive {
		t.Fatalf("old revision snapshot: %+v %v", snapshot, e)
	}
	detail := map[string]any{"17": map[string]any{}}
	if e = (cp.BootstrapProjection{Provider: privilegeProvider(p)}).OverlayMID1(ctx, p, a, false, now, detail); e != nil {
		t.Fatalf("MID 1 projection on old revision: %v", e)
	}
	out := detail["17"].(map[string]any)
	if out["vip"] != int64(1) || out["charge"] != int64(100) {
		t.Fatalf("MID 1 VIP: %#v", out)
	}
	exec(t, p, `INSERT INTO commerce_charge_cards(player_id,month_card_start,month_card_end,privilege_card_end,updated_at)VALUES($1,0,0,$2,clock_timestamp())`, int64(a.PlayerID), now.Add(time.Hour).Unix())
	if _, e = privilegeProvider(p).SnapshotTx(ctx, p, a.PlayerID, now); !errors.Is(e, d.ErrUnavailable) {
		t.Fatalf("active card on the old revision must need the catalog: %v", e)
	}
}

func TestI910GChargeDispatcherProductionPath(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := bornActor(t, p)
	dispatcher := stockruntime.ChargeDispatcher{Authority: playtestAuthority{a}, Service: chargeService(p)}

	query := dispatcher.Dispatch(ctx, playtestRequest(a, 354, map[string]any{}))
	charges, ok := query.Body["charges"].([]d.Purchase)
	if query.HTTPStatus != 200 || !ok || len(charges) != 23 {
		t.Fatalf("354 through dispatcher: %d %#v", query.HTTPStatus, query.Body["charges"])
	}
	tap := dispatcher.Dispatch(ctx, playtestRequest(a, 32000, map[string]any{"charge_id": int64(80001007), "intent_id": "i910g-dispatcher-tap"}))
	if tap.HTTPStatus != 200 || number(t, segment(t, tap.Body)["delta"]) != 200 {
		t.Fatalf("32000 through dispatcher: %d %+v", tap.HTTPStatus, tap.Body)
	}
	root, rooted, e := (ps.Store{}).ReadPrivilegeTx(ctx, p, a.PlayerID, false)
	if e != nil || !rooted || root.ContentRevision != revision {
		t.Fatalf("tap did not pin the active revision: %+v %v", root, e)
	}
	claim := dispatcher.Dispatch(ctx, playtestRequest(a, 657, map[string]any{"id": int64(1)}))
	if claim.HTTPStatus != 200 || len(awardRows(t, claim.Body["awards"])) != 4 {
		t.Fatalf("657 through dispatcher: %d %+v", claim.HTTPStatus, claim.Body)
	}
	for _, level := range []int64{0, 16} {
		refused := dispatcher.Dispatch(ctx, playtestRequest(a, 657, map[string]any{"id": level}))
		if refused.HTTPStatus != 409 || refused.Body["error_code"] != int64(35028) {
			t.Fatalf("657 level %d: %d %+v", level, refused.HTTPStatus, refused.Body)
		}
	}
}

func TestI910GChargeDispatcherConflictIsNotUnavailable(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := bornActor(t, p)
	foreign := bornActor(t, p)
	exec(t, p, `INSERT INTO commerce_privilege_roots(player_id,logical_server_id,qualifying_charge,vip_level,monthly_state,content_revision,policy_version,origin_class,issuer,reason,state_version,created_at,updated_at)VALUES($1,$2,100,1,'QUALIFIED_ABSENT',$3,'I10_CHARGE_TAP_V1','PLAYER_TAP_PRESERVATION','native','i910g foreign root',1,clock_timestamp()-interval '1 day',clock_timestamp()-interval '1 day')`, int64(foreign.PlayerID), int64(a.LogicalServerID)+1000, revision)
	dispatcher := stockruntime.ChargeDispatcher{Authority: playtestAuthority{foreign}, Service: chargeService(p)}
	refused := dispatcher.Dispatch(ctx, playtestRequest(foreign, 32000, map[string]any{"charge_id": int64(80001007), "intent_id": "i910g-foreign-root"}))
	if refused.HTTPStatus != 409 || refused.Body["error_code"] != int64(40002) {
		t.Fatalf("foreign root: %d %+v", refused.HTTPStatus, refused.Body)
	}
}

func TestI910GChargeOverlayOffHidesProductAndRefusesTap(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := bornActor(t, p)
	exec(t, p, `INSERT INTO commerce_recharge_tuning(singleton,payload,updated_at)VALUES(true,$1::jsonb,clock_timestamp()) ON CONFLICT(singleton)DO UPDATE SET payload=excluded.payload,updated_at=excluded.updated_at`, `{"version":1,"mode":"GRANT","products":{"80001007":{"off":true}}}`)
	t.Cleanup(func() { exec(t, p, `DELETE FROM commerce_recharge_tuning`) })
	reply, e := chargeService(p).Query(ctx, a, time.Unix(1700000000, 0))
	if e != nil {
		t.Fatal(e)
	}
	charges, ok := reply["charges"].([]d.Purchase)
	if !ok || len(charges) != 22 {
		t.Fatalf("354 with an off product: %#v", reply["charges"])
	}
	for _, row := range charges {
		if row.ChargeID == 80001007 {
			t.Fatal("off product stayed in 354")
		}
	}
	if _, e = chargeService(p).Tap(ctx, a, cp.TapRequest{ChargeID: 80001007, IntentID: uuid().String()}, opPinned(revision)); !errors.Is(e, d.ErrChargeRefused) {
		t.Fatalf("off product tap: %v", e)
	}
	if _, e = chargeService(p).Tap(ctx, a, cp.TapRequest{ChargeID: 80001006, IntentID: uuid().String()}, opPinned(revision)); e != nil {
		t.Fatalf("source product tap: %v", e)
	}
}
