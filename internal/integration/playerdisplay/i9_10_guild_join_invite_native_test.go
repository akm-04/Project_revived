//go:build postgres

package playerdisplay_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/guildinvitebundle"
	"gxb.local/backend/v2/internal/adapters/guildpolicybridge"
	"gxb.local/backend/v2/internal/adapters/guildviewread"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildinvitestore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialgiftstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/guildcore"
	appinvite "gxb.local/backend/v2/internal/application/guildinvite"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	"gxb.local/backend/v2/internal/content/guildpolicy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/socialview"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type guildJoinAuthority map[string]identity.ActorContext

func (a guildJoinAuthority) ResolveGameplayBearer(_ context.Context, token string, _ time.Time) (identity.ActorContext, error) {
	actor, ok := a[token]
	if !ok {
		return identity.ActorContext{}, fmt.Errorf("unknown token")
	}
	return actor, nil
}

type guildJoinQueue struct{}

func (guildJoinQueue) InsertTx(context.Context, tx.Tx, obligation.Obligation) error { return nil }

func guildJoinRequest(mid uint16, actor identity.ActorContext, params map[string]any, at time.Time) httpedge.DispatchRequest {
	copied := map[string]any{}
	for key, value := range params {
		copied[key] = value
	}
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		Operation: op(), MID: mid, ReceivedAt: at, Params: copied,
		Claims: wire.CredentialClaims{Token: fmt.Sprintf("%d", actor.PlayerID), Region: int64(actor.LogicalServerID)},
	}}
}

// guildJoinService is cmd/gxb-api/guild_invite_river.go plus the I6C core
// construction of internal/adapters/stockruntime/guild_apply_notice_native_test.go.
func guildJoinService(t *testing.T, p *pg.Pool, revision string) (guildcore.Service, guildinvitebundle.Bundle) {
	t.Helper()
	runner := tx.Runner{DB: p}
	bundle, err := guildinvitebundle.Prepare(ctx, p, runner, revision)
	if err != nil {
		t.Fatal(err)
	}
	if !bundle.Present {
		t.Fatal("guild invite schema missing")
	}
	projection := &appinvite.SourceService{Reads: runner, Store: guildinvitestore.Store{}, Bindings: guildstore.Store{Queryer: p}, History: kernelstore.Store{}, Reader: bundle.Source, Content: contentstore.Store{}, Queryer: p, Enqueue: guildJoinQueue{}}
	artifact, err := guildpolicy.LoadBuiltin()
	if err != nil {
		t.Fatal(err)
	}
	binding, err := guildpolicybridge.FromBuiltin(artifact)
	if err != nil {
		t.Fatal(err)
	}
	i5 := appi5.CrossOwner{Store: i5store.Store{}}
	return guildcore.Service{
		Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner},
		Store: guildstore.Store{Queryer: p}, Fencer: i5store.Store{}, PlayerRoots: i4store.PlayerRootLocker{},
		Level: i5, Scalar: i5, LevelAndScalar: i5,
		Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p},
		Policy: binding, InviteProjection: projection, Notices: pg.GuildApplyNoticeEmitter{},
	}, bundle
}

func guildJoinSocialReads(t *testing.T, p *pg.Pool, invites socialinbox.InviteNoticeReader) sp.Service {
	t.Helper()
	return sp.Service{Runner: tx.Runner{DB: p}, PlayerRoots: i4store.PlayerRootLocker{}, Relations: socialrelationstore.Store{}, Inbox: socialinboxstore.Store{}, NoticePages: socialinboxstore.Store{},
		Directory: i4store.TransactionDiscoveryReader{}, Presentation: socialpresentation.TransactionReader{}, Observer: socialpresentation.TransactionReader{},
		Gifts:   socialgift.Service{Store: socialgiftstore.Store{}, Content: contentstore.Store{Queryer: p}},
		Invites: invites, PresentationAt: socialpresentation.TransactionReader{}}
}

func TestI9_10GuildlessListApplyAndInviteNotice(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	applicant, leader, invitee := bornActor(t, p), bornActor(t, p), bornActor(t, p)
	core, bundle := guildJoinService(t, p, revision)
	gid := guildFixture(t, p, leader)
	// A Guild created by the production Create writes the active I6C policy
	// revision; the shared raw fixture needs it for the Invite source binding.
	exec(t, p, `UPDATE guilds SET policy_revision=$2 WHERE guild_id=$1`, int64(gid), core.Policy.Revision)
	now := time.Now().UTC()

	authority := guildJoinAuthority{
		fmt.Sprintf("%d", applicant.PlayerID): applicant,
		fmt.Sprintf("%d", leader.PlayerID):    leader,
		fmt.Sprintf("%d", invitee.PlayerID):   invitee,
	}
	guilds := stockruntime.GuildDispatcher{Authority: authority, Core: core, View: guildviewread.Reader{Runner: tx.Runner{DB: p}}}

	list := guilds.Dispatch(ctx, guildJoinRequest(576, applicant, nil, now))
	if list.HTTPStatus != 200 {
		t.Fatalf("576 status=%d body=%v", list.HTTPStatus, list.Body)
	}
	infos, ok := list.Body["guild_infos"].([]any)
	if !ok {
		t.Fatalf("576 guild_infos=%#v", list.Body)
	}
	var listed map[string]any
	for _, info := range infos {
		row, isRow := info.(map[string]any)
		if isRow && row["guild_id"] == int64(gid) {
			listed = row
		}
	}
	if listed == nil {
		t.Fatalf("576 does not list guild %d: %#v", gid, list.Body)
	}
	row := listed
	if row["guild_id"] != int64(gid) || row["name"] == "" || row["icon"] == int64(0) || row["apply_type"] != int64(0) || row["min_allow_level"] != int64(1) || row["member_num"] != int64(1) || row["des"] == nil {
		t.Fatalf("576 row=%#v", row)
	}

	apply := guildJoinRequest(580, applicant, map[string]any{"guild_id": int64(gid)}, now)
	if got := guilds.Dispatch(ctx, apply); got.HTTPStatus != 200 {
		t.Fatalf("580 status=%d body=%v cause=%v", got.HTTPStatus, got.Body, got.Cause)
	}
	pending := guilds.Dispatch(ctx, guildJoinRequest(598, applicant, nil, now))
	rows, ok := pending.JSON.([]any)
	if got := pending.HTTPStatus; got != 200 || !ok || len(rows) != 1 || rows[0].(map[string]any)["guild_id"] != int64(gid) {
		t.Fatalf("598 status=%d rows=%#v", got, pending.JSON)
	}

	invite := guildJoinRequest(2563, leader, map[string]any{"player_id": int64(invitee.PlayerID)}, now)
	if got := guilds.Dispatch(ctx, invite); got.HTTPStatus != 200 {
		t.Fatalf("2563 status=%d body=%v cause=%v", got.HTTPStatus, got.Body, got.Cause)
	}
	var sourceID string
	if err := p.QueryRow(ctx, `SELECT source_id::text FROM guild_invite_projection_sources WHERE guild_id=$1 AND recipient_player_id=$2 ORDER BY source_serial DESC LIMIT 1`, int64(gid), int64(invitee.PlayerID)).Scan(&sourceID); err != nil {
		t.Fatal("invite source", err)
	}
	id, err := ids.ParseUUID(sourceID)
	if err != nil {
		t.Fatal(err)
	}
	delivery := appinvite.Delivery{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Reads: tx.Runner{DB: p}, Store: guildinvitestore.Store{}, Sources: bundle.Source, Players: i4store.PlayerRootLocker{}, Target: bundle.Target}
	if err := delivery.Deliver(ctx, id); err != nil {
		t.Fatal("invite delivery", err)
	}

	social := stockruntime.SocialDispatcher{Authority: authority, Projection: guildJoinSocialReads(t, p, bundle.Target)}
	notices := social.Dispatch(ctx, guildJoinRequest(189, invitee, map[string]any{"list_type": int64(4)}, now))
	if notices.HTTPStatus != 200 {
		t.Fatalf("189 status=%d body=%v", notices.HTTPStatus, notices.Body)
	}
	page, ok := notices.JSON.([]socialview.Notice)
	if !ok {
		t.Fatalf("189 page=%#v", notices.JSON)
	}
	var inviteRow *socialview.Notice
	for i := range page {
		if page[i].Type == 10 {
			inviteRow = &page[i]
		}
	}
	if inviteRow == nil || inviteRow.GuildID == nil || *inviteRow.GuildID != int64(gid) || inviteRow.GuildName == nil || inviteRow.Player.PlayerID != int64(leader.PlayerID) {
		t.Fatalf("189 guild invite missing page=%+v", page)
	}
}
