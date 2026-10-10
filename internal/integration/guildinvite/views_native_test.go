//go:build postgres && river

package guildinvite_test

import (
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/guildinvitebundle"
	"gxb.local/backend/v2/internal/adapters/guildpolicybridge"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildinvitestore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialgiftstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/guildcore"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialprojection"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/application/socialreload"
	ref "gxb.local/backend/v2/internal/application/socialreloadref"
	"gxb.local/backend/v2/internal/content/guildpolicy"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"

	"os"
	"reflect"
	"testing"
	"time"
)

type inviteEmitter struct{ refs []ref.ReloadReference }

func (v *inviteEmitter) Emit(_ context.Context, r []ref.ReloadReference) {
	v.refs = append(v.refs, r...)
}

type observedInvites struct {
	socialinbox.InviteNoticeReader
	observed *bool
}

func (v observedInvites) ReadCurrentInviteNoticeTx(c context.Context, q tx.Queryer, n socialinbox.Notice) (gi.Snapshot, error) {
	if *v.observed {
		panic("Guild read after response observation")
	}
	return v.InviteNoticeReader.ReadCurrentInviteNoticeTx(c, q, n)
}

type countedObserver struct {
	seen  *bool
	calls *int
}

func (v countedObserver) ObserveTx(c context.Context, t tx.Tx) (time.Time, error) {
	*v.seen = true
	*v.calls++
	return (socialpresentation.TransactionReader{}).ObserveTx(c, t)
}
func TestWorkingP4SharedObservationMixedClaimAndInviteReload(t *testing.T) {
	dsn := os.Getenv("GXB_I7A8B_VIEWS_DSN")
	if dsn == "" {
		t.Skip("fresh working target2 fixture required")
	}
	c, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	// Source-only fixtures intentionally omitted presentation; seed the required
	// existing owner projections in this disposable consumer fixture only.
	for _, sql := range []string{
		`INSERT INTO player_directory_profiles(player_id,name,created_at,updated_at) SELECT player_id,'consumer-'||player_id::text,created_at,created_at FROM players WHERE bootstrap_profile_version='working-source8b-fixture' ON CONFLICT DO NOTHING`,
		`INSERT INTO player_profiles(player_id,display_name,avatar_id,created_at,updated_at) SELECT player_id,'consumer-'||player_id::text,110001001,created_at,created_at FROM players WHERE bootstrap_profile_version='working-source8b-fixture' ON CONFLICT DO NOTHING`,
	} {
		if _, e = p.Raw().Exec(c, sql); e != nil {
			t.Fatal(e)
		}
	}
	runner := tx.Runner{DB: p}
	content := contentstore.Store{Queryer: p}
	rev, e := content.ActiveRevision(c, p)
	if e != nil {
		t.Fatal(e)
	}
	bundle, e := guildinvitebundle.Prepare(c, p, runner, rev)
	if e != nil || !bundle.Present || !bundle.Qualified {
		t.Fatal(bundle, e)
	}
	rows, e := p.Raw().Query(c, `SELECT s.source_id::text FROM guild_invite_projection_sources s LEFT JOIN social_guild_invite_materializations t USING(source_id) WHERE t.source_id IS NULL ORDER BY source_serial`)
	if e != nil {
		t.Fatal(e)
	}
	var candidate ids.UUID
	for rows.Next() {
		var raw string
		rows.Scan(&raw)
		candidate, _ = ids.ParseUUID(raw)
	}
	rows.Close()
	if candidate.IsZero() {
		t.Fatal("no unmaterialized source")
	}
	emitter := &inviteEmitter{}
	target := bundle.Target
	target.Emitter = emitter
	proof, e := target.Materialize(c, candidate)
	if e != nil || proof.State != gi.Materialized || len(emitter.refs) != 1 {
		t.Fatal(proof, e, emitter.refs)
	}
	if _, e = target.Materialize(c, candidate); e != nil || len(emitter.refs) != 1 {
		t.Fatal("replay emitted hint", e, emitter.refs)
	}
	source, e := bundle.Source.ReadIssueEvidenceTx(c, p, candidate)
	if e != nil {
		t.Fatal(e)
	}
	actor := savedActor(t, c, p, source.Tuple.Recipient)
	sender := savedActor(t, c, p, source.Inviter)
	timed := gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: runner}
	inbox := socialinboxstore.Store{}
	relations := socialrelationstore.Store{}
	i5db := i5store.Store{Queryer: p}
	gift := socialgift.Service{InviteConsumption: inbox, Invites: target, Timed: timed, Reads: runner, Store: socialgiftstore.Store{}, Content: content, Players: i4store.PlayerRootLocker{}, Relations: relations, Privacy: socialrelation.FriendDMPrivacyProvider{Store: relations}, Inbox: socialinbox.GiftService{Store: inbox}, NoticeEvidence: inbox, Grants: i5.Service{Runner: runner, Store: i5db, Content: content, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}, Admission: i4store.RealtimeAuthority{Queryer: p}, Fence: i5db}
	commands := socialrelation.Service{Timed: timed, PlayerRoots: i4store.PlayerRootLocker{}, Store: relations, Inbox: socialinbox.RelationService{Store: inbox}, Presentation: socialpresentation.TransactionReader{}}
	for _, v := range []struct {
		actor  identity.ActorContext
		kind   socialrelation.CommandKind
		target identity.PlayerID
	}{{sender, socialrelation.RequestFriend, actor.PlayerID}, {actor, socialrelation.AcceptRequest, sender.PlayerID}} {
		if _, e = commands.Execute(c, v.actor, socialrelation.Command{Kind: v.kind, Targets: []identity.PlayerID{v.target}}, mustOp(t, policy.Set{})); e != nil {
			t.Fatal(e)
		}
	}
	sent, e := gift.Send(c, sender, actor.PlayerID, mustOp(t, policy.Set{}))
	if e != nil {
		t.Fatal("real Gift issue", e)
	}
	if _, e = commands.Execute(c, sender, socialrelation.Command{Kind: socialrelation.DeleteFriend, Targets: []identity.PlayerID{actor.PlayerID}}, mustOp(t, policy.Set{})); e != nil {
		t.Fatal(e)
	}
	seen, calls := false, 0
	views := socialprojection.Service{Invites: observedInvites{InviteNoticeReader: target, observed: &seen}, PresentationAt: socialpresentation.TransactionReader{}, Gifts: gift, NoticePages: inbox, Runner: runner, PlayerRoots: i4store.PlayerRootLocker{}, Relations: relations, Inbox: inbox, Directory: i4store.TransactionDiscoveryReader{}, Presentation: socialpresentation.TransactionReader{}, Observer: countedObserver{seen: &seen, calls: &calls}}
	result, e := views.LoadBase(c, actor, mustOp(t, policy.Set{}))
	if e != nil || calls != 1 {
		t.Fatal("single shared observation", e, calls)
	}
	wire := socialpresentation.MapBase(result)
	raw, e := json.Marshal(wire)
	if e != nil {
		t.Fatal(e)
	}
	var doc map[string]json.RawMessage
	json.Unmarshal(raw, &doc)
	var noticeRows []map[string]json.RawMessage
	json.Unmarshal(doc["notice_list"], &noticeRows)
	found := false
	for _, n := range noticeRows {
		var typ int
		json.Unmarshal(n["notice_type"], &typ)
		if typ == 10 {
			found = true
			if n["guild_id"] == nil || n["guild_name"] == nil {
				t.Fatal("missing Invite stock fields", string(raw))
			}
		} else if n["guild_id"] != nil || n["guild_name"] != nil {
			t.Fatal("changed old notice DTO", string(raw))
		}
	}
	if !found {
		t.Fatal("eligible Invite missing", string(raw))
	}
	reloader := socialreload.Service{Invites: target, Gifts: gift, Runner: runner, Relations: relations, Inbox: inbox, Observer: socialpresentation.TransactionReader{}}
	if _, ok, e := reloader.Reload(c, emitter.refs[0], mustOp(t, policy.Set{})); e != nil || !ok {
		t.Fatal("canonical u1 reload", ok, e)
	}
	idsToClaim := []socialinbox.NoticeID{socialinbox.NoticeID(proof.NoticeID), sent.NoticeIDs[0]}
	for _, n := range result.Notices {
		if socialinbox.RelationFamily(n.Notice.Source) {
			idsToClaim = append(idsToClaim, n.Notice.NoticeID)
		}
	}
	idsToClaim = append(idsToClaim, socialinbox.NoticeID(proof.NoticeID))
	claim := mustOp(t, policy.Set{})
	key, _ := source.Tuple.SourceKey()
	if _, e = p.Raw().Exec(c, `UPDATE social_notices SET source_key='malformed' WHERE recipient_player_id=$1 AND notice_id=$2`, int64(actor.PlayerID), proof.NoticeID); e != nil {
		t.Fatal(e)
	}
	snapshot := func() string {
		var raw string
		e := p.QueryRow(c, `SELECT jsonb_build_object('notes',(SELECT jsonb_agg(to_jsonb(n) ORDER BY notice_id) FROM social_notices n WHERE recipient_player_id=$1),'gifts',(SELECT jsonb_agg(to_jsonb(g) ORDER BY transfer_id) FROM social_gift_transfers g WHERE recipient_player_id=$1),'root',(SELECT to_jsonb(r) FROM player_social_roots r WHERE player_id=$1),'balance',(SELECT jsonb_agg(to_jsonb(b) ORDER BY resource_key) FROM player_currency_balances b WHERE player_id=$1),'claims',(SELECT jsonb_agg(to_jsonb(o) ORDER BY operation_id) FROM social_gift_claim_operations o WHERE recipient_player_id=$1))::text`, int64(actor.PlayerID)).Scan(&raw)
		if e != nil {
			t.Fatal(e)
		}
		return raw
	}
	before := snapshot()
	if _, e = gift.Claim(c, actor, idsToClaim, mustOp(t, policy.Set{})); e == nil || snapshot() != before {
		t.Fatal("malformed recognized type10 failed whole mixed rollback", e)
	}
	if _, e = p.Raw().Exec(c, `UPDATE social_notices SET source_key=$3 WHERE recipient_player_id=$1 AND notice_id=$2`, int64(actor.PlayerID), proof.NoticeID, key); e != nil {
		t.Fatal(e)
	}
	got, e := gift.Claim(c, actor, idsToClaim, claim)
	if e != nil || got.Amount != 5 || len(got.TransferIDs) != 1 || len(got.NoticeIDs) < 2 {
		t.Fatal("mixed claim", got, e)
	}
	again, e := gift.Claim(c, actor, idsToClaim, claim)
	if e != nil || !reflect.DeepEqual(got, again) {
		t.Fatal("complete mixed replay", again, e)
	}
	if _, ok, e := reloader.Reload(c, emitter.refs[0], mustOp(t, policy.Set{})); e != nil || ok {
		t.Fatal("dismissed u1 reference remained live", ok, e)
	}
	// Lifecycle changes cannot turn a committed mixed claim into new value.
	policyArtifact, e := guildpolicy.LoadBuiltin()
	if e != nil {
		t.Fatal(e)
	}
	binding, e := guildpolicybridge.FromBuiltin(policyArtifact)
	if e != nil {
		t.Fatal(e)
	}
	gs := guildstore.Store{Queryer: p}
	queue, e := riveradapter.NewGuildInsertOnly(p.Raw())
	if e != nil {
		t.Fatal(e)
	}
	projection := app.SourceService{Reads: runner, Store: guildinvitestore.Store{}, Bindings: gs, History: kernelstore.Store{}, Reader: bundle.Source, Content: content, Queryer: p, Enqueue: queue}
	cross := i5.CrossOwner{Store: i5db}
	core := guildcore.Service{Timed: timed, Store: gs, Fencer: i5db, PlayerRoots: i4store.PlayerRootLocker{}, Level: cross, Scalar: cross, LevelAndScalar: cross, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Policy: binding, InviteProjection: &projection}
	if _, e = core.AcceptInvite(c, actor, guild.ID(source.Tuple.GuildID), mustOp(t, policy.Set{})); e != nil {
		t.Fatal(e)
	}
	afterJoin, e := gift.Claim(c, actor, idsToClaim, claim)
	if e != nil || !reflect.DeepEqual(got, afterJoin) {
		t.Fatal("complete replay after JOIN", e)
	}
	// Isolated FK-null presentation simulation, not an account deletion feature.
	if _, e = p.Raw().Exec(c, `UPDATE social_notices SET related_player_id=NULL WHERE recipient_player_id=$1 AND notice_id=$2`, int64(actor.PlayerID), proof.NoticeID); e != nil {
		t.Fatal(e)
	}
	afterNull, e := gift.Claim(c, actor, idsToClaim, claim)
	if e != nil || !reflect.DeepEqual(got, afterNull) {
		t.Fatal("complete replay after simulated deleted related presentation", e)
	}
	if len(emitter.refs) != 1 {
		t.Fatal("MID184 emitted source hint")
	}
	var live int64
	if e = p.QueryRow(c, `SELECT count(*) FROM guild_invites WHERE guild_id=$1 AND invited_player_id=$2 AND invite_generation=$3`, int64(source.Tuple.GuildID), int64(actor.PlayerID), source.Tuple.Generation).Scan(&live); e != nil || live != 0 {
		t.Fatal("JOIN did not consume its actual Guild invite", live, e)
	}
}
