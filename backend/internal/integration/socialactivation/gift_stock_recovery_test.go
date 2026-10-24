//go:build postgres && socialintegration

package socialactivation_test

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/application/generaldm"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"os"
	"path/filepath"
	"reflect"
	"testing"
	"time"
)

type combined7Recovery struct {
	Gift                              giftRecovery
	FriendOperation, GeneralOperation operation.Context
	FriendMessages                    []frienddm.Projection
	General                           generaldm.Intent
	Snapshot                          string
}

func (f *fixture) combined7Snapshot() string {
	return f.text(`SELECT jsonb_build_object('gift',$1::jsonb,'friend',$2::jsonb,'general',(SELECT coalesce(jsonb_agg(to_jsonb(i) ORDER BY operation_id),'[]') FROM personal_dm_intents i),'general_payloads',(SELECT coalesce(jsonb_agg(to_jsonb(i) ORDER BY operation_id),'[]') FROM personal_dm_payloads i),'general_delivery',(SELECT coalesce(jsonb_agg(to_jsonb(i) ORDER BY operation_id),'[]') FROM personal_dm_delivery i),'notice_sequence',(SELECT row_to_json(q) FROM(SELECT last_value,is_called FROM social_notice_id_seq)q))::text`, f.giftState(), f.dmSnapshot())
}
func Test7B_CombinedRecoverySeedCompare(t *testing.T) {
	mode := os.Getenv("GXB_I7A7B_RECOVERY_MODE")
	if mode == "" {
		t.Skip("explicit nonempty dump/restore/restart orchestration")
	}
	dir := os.Getenv("GXB_I7A7B_RECOVERY_OUTPUT")
	if dir == "" {
		t.Fatal("recovery output required")
	}
	p := filepath.Join(dir, "combined7-recovery.json")
	if mode == "seed" {
		f, s, a, b := giftFixture(t)
		r, e := s.Send(ctx, a, b.PlayerID, f.op())
		if e != nil {
			t.Fatal(e)
		}
		claim := f.op()
		got, e := s.Claim(ctx, b, r.NoticeIDs, claim)
		if e != nil {
			t.Fatal(e)
		}
		// Reverse unclaimed gift coexists with claimed facts and current Friend views.
		if _, e = s.Send(ctx, b, a.PlayerID, f.op()); e != nil {
			t.Fatal(e)
		}
		_, _, base, _ := f.giftStock(s, f.scalar())
		f.dmSend(f.dm(), a.PlayerID, b.PlayerID, "restored already projected")
		projection := f.op()
		out, e := base.LoadBase(ctx, b, projection)
		if e != nil || len(out.PrivateMessages) != 1 {
			t.Fatal(out, e)
		}
		f.dmSend(f.dm(), a.PlayerID, b.PlayerID, "restore must preserve pending")
		fence, e := (presencestore.Store{Queryer: f.p}).ActivateRealtimeOwnerFence(ctx)
		if e != nil {
			t.Fatal(e)
		}
		instance, _ := ids.NewUUID()
		now := f.now()
		f.sql(`INSERT INTO player_social_presence(player_id,state_version,created_at,updated_at)VALUES(200001,1,$1,$1)`, now)
		f.sql(`INSERT INTO realtime_presence_leases(gameplay_context_id,player_id,physical_role,realtime_instance_id,connection_generation,realtime_owner_fence,connected_at,lease_expires_at,last_renewed_at)VALUES($1::uuid,200001,'WORLD',$2::uuid,1,$3,$4,$5,$4)`, b.ContextID.UUID().String(), instance.String(), fence, now, now.Add(time.Minute))
		generalOp := f.op()
		general, e := f.general().Accept(ctx, int64(a.PlayerID), int64(b.PlayerID), "restored finite General", generalOp)
		if e != nil {
			t.Fatal(e)
		}
		rec := combined7Recovery{Gift: giftRecovery{ActorAccount: b.AccountID.UUID().String(), ActorSession: b.SessionID.UUID().String(), ActorContext: b.ContextID.UUID().String(), ActorUID: string(b.AccountUID), ActorPlayer: b.PlayerID, ActorServer: b.LogicalServerID, SenderAccount: a.AccountID.UUID().String(), SenderSession: a.SessionID.UUID().String(), SenderContext: a.ContextID.UUID().String(), SenderUID: string(a.AccountUID), SenderPlayer: a.PlayerID, SenderServer: a.LogicalServerID, Claim: claim, ClaimInput: r.NoticeIDs, Result: got}, FriendOperation: projection, GeneralOperation: generalOp, FriendMessages: out.PrivateMessages, General: general, Snapshot: f.combined7Snapshot()}
		data, _ := json.MarshalIndent(rec, "", "  ")
		if e = os.WriteFile(p, data, 0600); e != nil {
			t.Fatal(e)
		}
		return
	}
	if mode != "compare" {
		t.Fatal(mode)
	}
	data, e := os.ReadFile(p)
	if e != nil {
		t.Fatal(e)
	}
	var rec combined7Recovery
	if e = json.Unmarshal(data, &rec); e != nil {
		t.Fatal(e)
	}
	f := existing(t)
	if f.combined7Snapshot() != rec.Snapshot {
		t.Fatal("full combined facts or sequence drift")
	}
	g := rec.Gift
	b := actorRecovery(g.ActorAccount, g.ActorSession, g.ActorContext, g.ActorUID, g.ActorPlayer, g.ActorServer)
	a := actorRecovery(g.SenderAccount, g.SenderSession, g.SenderContext, g.SenderUID, g.SenderPlayer, g.SenderServer)
	s := f.gift()
	_, _, base, _ := f.giftStock(s, f.scalar())
	got, e := s.Claim(ctx, b, g.ClaimInput, g.Claim)
	if e != nil || !reflect.DeepEqual(got, g.Result) {
		t.Fatal("Gift restored known replay", got, e)
	}
	out, e := base.LoadBase(ctx, b, rec.FriendOperation)
	if e != nil || !reflect.DeepEqual(out.PrivateMessages, rec.FriendMessages) || out.ReceiveCount != 1 || !out.Friends[0].IsSent {
		t.Fatal("combined restored projection known receipt", out, e)
	}
	general, e := f.general().Accept(ctx, int64(a.PlayerID), int64(b.PlayerID), "restored finite General", rec.GeneralOperation)
	if e != nil || !reflect.DeepEqual(general, rec.General) {
		t.Fatal("General restored replay", e)
	}
	if f.combined7Snapshot() != rec.Snapshot {
		t.Fatal("restore replay recredited/redrained/mutated durable truth")
	}
	t.Log("REAL_PG combinedGift claimed/unclaimed+I5+Friendprojected/pending+Generalfinite+sequence samebackup; knownreplays pure afterrestore/restart")
}
