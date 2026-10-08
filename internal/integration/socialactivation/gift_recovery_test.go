//go:build postgres && socialintegration

package socialactivation_test

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	sg "gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"
)

type giftRecovery struct {
	ActorAccount, ActorSession, ActorContext, ActorUID     string
	ActorPlayer                                            identity.PlayerID
	ActorServer                                            identity.LogicalServerID
	SenderAccount, SenderSession, SenderContext, SenderUID string
	SenderPlayer                                           identity.PlayerID
	SenderServer                                           identity.LogicalServerID
	Claim                                                  operation.Context
	ClaimInput, Old, Current, Deleted                      []socialinbox.NoticeID
	Result                                                 sg.Result
	Snapshot                                               string
	Sequence                                               int64
	At                                                     time.Time
}

func actorRecovery(account, session, context, uid string, p identity.PlayerID, server identity.LogicalServerID) identity.ActorContext {
	a, _ := ids.ParseUUID(account)
	b, _ := ids.ParseUUID(session)
	c, _ := ids.ParseUUID(context)
	aa, _ := identity.AccountIDFrom(a)
	bb, _ := identity.SessionIDFrom(b)
	cc, _ := identity.ContextIDFrom(c)
	return identity.ActorContext{AccountID: aa, AccountUID: identity.AccountUID(uid), SessionID: bb, ContextID: cc, PlayerID: p, LogicalServerID: server, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func Test7A_RecoverySeedCompare(t *testing.T) {
	mode := os.Getenv("GXB_I7A7A_RECOVERY_MODE")
	if mode == "" {
		t.Skip("explicit dump/restore orchestration only; ordinary suite is not restore proof")
	}
	dir := os.Getenv("GXB_I7A7A_RECOVERY_OUTPUT")
	if dir == "" {
		t.Fatal("recovery output required")
	}
	path := filepath.Join(dir, "gift-recovery.json")
	if mode == "seed" {
		f, s, a, b := giftFixture(t)
		past := f.now().Add(-24 * time.Hour)
		f.sql(`UPDATE player_social_roots SET created_at=$1,updated_at=$1`, past.Add(-time.Hour))
		f.sql(`UPDATE social_friendships SET activated_at=$1,updated_at=$1`, past.Add(-time.Hour))
		s.Timed.Binder.Time = fixedDMClock{past}
		old, e := s.Send(ctx, a, b.PlayerID, f.op())
		if e != nil {
			t.Fatal(e)
		}
		now := f.now()
		s.Timed.Binder.Time = fixedDMClock{now}
		var claimed []socialinbox.NoticeID
		for n := 0; n < 9; n++ {
			pid := identity.PlayerID(300001 + n)
			f.player(pid)
			f.friend(pid, b.PlayerID)
			sender, _ := f.live(pid)
			s.Timed.Binder.Time = fixedDMClock{f.now()}
			r, e := s.Send(ctx, sender, b.PlayerID, f.op())
			if e != nil {
				t.Fatal(e)
			}
			claimed = append(claimed, r.NoticeIDs...)
		}
		op := f.op()
		s.Timed.Binder.Time = fixedDMClock{f.now()}
		got, e := s.Claim(ctx, b, claimed, op)
		if e != nil || got.Amount != 45 {
			t.Fatal(got, e)
		}
		s.Timed.Binder.Time = fixedDMClock{f.now()}
		current, e := s.Send(ctx, a, b.PlayerID, f.op())
		if e != nil {
			t.Fatal(e)
		}
		f.player(500001)
		f.friend(500001, b.PlayerID)
		deletedSender, _ := f.live(500001)
		s.Timed.Binder.Time = fixedDMClock{f.now()}
		gone, e := s.Send(ctx, deletedSender, b.PlayerID, f.op())
		if e != nil {
			t.Fatal(e)
		}
		f.sql(`DELETE FROM gameplay_context_credentials WHERE context_id IN(SELECT context_id FROM gameplay_contexts WHERE player_id=500001)`)
		f.sql(`DELETE FROM gameplay_contexts WHERE player_id=500001`)
		f.sql(`DELETE FROM player_directory_profiles WHERE player_id=500001`)
		f.sql(`DELETE FROM players WHERE player_id=500001`)
		// Synthetic future immutable gift revision: exact same vector/catalog, no
		// assertion about an original server or a full future content installation.
		rev := strings.Repeat("e", 64)
		f.sql(`INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest)SELECT $1,decode($1,'hex'),schema_version,compiler_version,parser_version,jsonb_set(manifest,'{revision_id}',to_jsonb($1::text)) FROM gxb_content_revisions WHERE revision_id=$2 ON CONFLICT DO NOTHING`, rev, got.Revision)
		f.sql(`INSERT INTO content_social_gift_catalogs SELECT $1,payload FROM content_social_gift_catalogs WHERE revision_id=$2 ON CONFLICT DO NOTHING`, rev, got.Revision)
		f.sql(`UPDATE social_gift_transfers SET reward_revision=$1 WHERE recipient_player_id=200001 AND claim_operation_id IS NULL AND sender_player_id=500001`, rev)
		sequence := f.number(`SELECT last_value FROM social_notice_id_seq`)
		rec := giftRecovery{ActorAccount: b.AccountID.UUID().String(), ActorSession: b.SessionID.UUID().String(), ActorContext: b.ContextID.UUID().String(), ActorUID: string(b.AccountUID), ActorPlayer: b.PlayerID, ActorServer: b.LogicalServerID, SenderAccount: a.AccountID.UUID().String(), SenderSession: a.SessionID.UUID().String(), SenderContext: a.ContextID.UUID().String(), SenderUID: string(a.AccountUID), SenderPlayer: a.PlayerID, SenderServer: a.LogicalServerID, Claim: op, ClaimInput: claimed, Old: old.NoticeIDs, Current: current.NoticeIDs, Deleted: gone.NoticeIDs, Result: got, Snapshot: f.giftState(), Sequence: sequence, At: f.now()}
		raw, _ := json.MarshalIndent(rec, "", "  ")
		if e = os.WriteFile(path, raw, 0600); e != nil {
			t.Fatal(e)
		}
		t.Log("REAL_PG nonempty restore seed: nine current claimed, old unclaimed, current unclaimed, deleted sender with synthetic equivalent issued revision, full semantic operation and sequence witness")
		return
	}
	if mode != "compare" {
		t.Fatal("unknown mode")
	}
	raw, e := os.ReadFile(path)
	if e != nil {
		t.Fatal(e)
	}
	var rec giftRecovery
	if e = json.Unmarshal(raw, &rec); e != nil {
		t.Fatal(e)
	}
	f := existing(t)
	s := f.gift()
	b := actorRecovery(rec.ActorAccount, rec.ActorSession, rec.ActorContext, rec.ActorUID, rec.ActorPlayer, rec.ActorServer)
	a := actorRecovery(rec.SenderAccount, rec.SenderSession, rec.SenderContext, rec.SenderUID, rec.SenderPlayer, rec.SenderServer)
	if f.giftState() != rec.Snapshot || f.number(`SELECT last_value FROM social_notice_id_seq`) != rec.Sequence {
		t.Fatal("restore bytes/sequence differ")
	}
	got, e := s.Claim(ctx, b, rec.ClaimInput, rec.Claim)
	if e != nil || !reflect.DeepEqual(got, rec.Result) {
		t.Fatal("restored exact replay", got, e)
	}
	s.Timed.Binder.Time = fixedDMClock{rec.At.Add(time.Second)}
	if _, e = s.Send(ctx, a, b.PlayerID, f.op()); e != sg.ErrDuplicate {
		t.Fatal("restored same-day uniqueness", e)
	}
	last, e := s.Claim(ctx, b, rec.Old, f.op())
	if e != nil || last.Amount != 5 {
		t.Fatal(last, e)
	}
	before := f.giftState()
	if _, e = s.Claim(ctx, b, rec.Current, f.op()); e != sg.ErrQuota || f.giftState() != before {
		t.Fatal("restored quota", e)
	}
	s.Timed.Binder.Time = fixedDMClock{rec.At.Add(24 * time.Hour)}
	mixed := append(append([]socialinbox.NoticeID{}, rec.Current...), rec.Deleted...)
	next, e := s.Claim(ctx, b, mixed, f.op())
	if e != nil || next.Amount != 10 || f.number(`SELECT amount FROM player_currency_balances WHERE player_id=200001 AND resource_key='friendship_coin'`) != 60 {
		t.Fatal("rollover mixed equivalent source revisions/tombstone", next, e)
	}
	t.Log("REAL_PG separately restored full backup: all facts+sequence identical, claimed replay/no recredit, natural uniqueness, last-slot quota, next-day mixed issued revisions and deleted sender value")
}
func Test7A_UpgradeActivationCompatibility(t *testing.T) {
	if os.Getenv("GXB_I7A7A_UPGRADE_MODE") == "" {
		t.Skip("explicit accepted35 upgrade database only")
	}
	f := existing(t)
	old, e := (contentstore.Store{}).ActiveRevision(ctx, f.p)
	if e != nil {
		t.Fatal(e)
	}
	if old != "66dddbab1c548555e244c670bc994e9a17c604ba5462e38eb6610c956943b3af" {
		t.Fatal("wrong accepted content base", old)
	}
	svc := registry.Service{Runner: tx.Runner{DB: f.p}, Repo: contentstore.Store{}, Fresh: f.p, Providers: registry.DefaultProviderSet()}
	summary, e := registry.Initialize(ctx, svc, operation.Factory{Clock: clock.System{}})
	if e != nil || summary.Activation.RevisionID != old {
		t.Fatal("old activation changed", summary, e)
	}
	if _, e = (contentstore.Store{}).ReadGiftContent(ctx, f.p, old); e == nil {
		t.Fatal("old revision incorrectly gift capable")
	}
	bundle, e := registry.LoadBuiltinBundle()
	if e != nil {
		t.Fatal(e)
	}
	if _, e = svc.ActivateBuiltin(ctx, f.op(), bundle, summary.Activation, "i7a7a-qualified-upgrade-fixture"); e != nil {
		t.Fatal(e)
	}
	newrev, e := (contentstore.Store{}).ActiveRevision(ctx, f.p)
	if e != nil || newrev != bundle.RevisionID() {
		t.Fatal(newrev, e)
	}
	if _, e = (contentstore.Store{}).ReadGiftContent(ctx, f.p, newrev); e != nil {
		t.Fatal(e)
	}
	t.Log("REAL_PG accepted35 nonempty upgrade: old immutable revision/activation preserved; new Gift content installed but explicit owning activation required")
}

var _ = policy.Ref{}
