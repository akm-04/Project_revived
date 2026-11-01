//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/socialgiftstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/roominvite"
	"gxb.local/backend/v2/internal/application/socialdismiss"
	"gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	"gxb.local/backend/v2/internal/application/socialrelation"
	da "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	di "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/socialview"
)

func roomInviteMaterializer(t *testing.T, p *pg.Pool) roominvite.Service {
	t.Helper()
	return roominvite.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}},
		Players: i4store.PlayerRootLocker{}, Roots: socialrelation.RootService{Store: socialrelationstore.Store{}}, Store: socialinboxstore.Store{}}
}

// socialNoticePage is the production LOAD_FRIEND_INFO list_type NOTICE path.
func socialNoticePage(t *testing.T, p *pg.Pool, recipient identity.ActorContext) []socialview.Notice {
	t.Helper()
	reads := sp.Service{Runner: tx.Runner{DB: p}, PlayerRoots: i4store.PlayerRootLocker{}, Relations: socialrelationstore.Store{}, Inbox: socialinboxstore.Store{}, NoticePages: socialinboxstore.Store{},
		Directory: i4store.TransactionDiscoveryReader{}, Presentation: socialpresentation.TransactionReader{}, Observer: socialpresentation.TransactionReader{},
		Gifts: socialgift.Service{Store: socialgiftstore.Store{}, Content: contentstore.Store{Queryer: p}}}
	result, err := reads.LoadList(ctx, recipient, sp.Notice, op())
	if err != nil {
		t.Fatal("notice read", err)
	}
	page, err := socialpresentation.MapList(result, sp.Notice)
	if err != nil {
		t.Fatal("notice wire", err)
	}
	return page.([]socialview.Notice)
}

// guildBundleReads is the read service once a guild bundle is installed
// (cmd/gxb-api/guild_invite_river.go): room rows then pass prepareInviteWindow.
func guildBundleReads(p *pg.Pool) sp.Service {
	return sp.Service{Runner: tx.Runner{DB: p}, PlayerRoots: i4store.PlayerRootLocker{}, Relations: socialrelationstore.Store{}, Inbox: socialinboxstore.Store{}, NoticePages: socialinboxstore.Store{},
		Directory: i4store.TransactionDiscoveryReader{}, Presentation: socialpresentation.TransactionReader{}, Observer: socialpresentation.TransactionReader{},
		Gifts:   socialgift.Service{Store: socialgiftstore.Store{}, Content: contentstore.Store{Queryer: p}},
		Invites: refusingInviteReader{}, PresentationAt: socialpresentation.TransactionReader{}}
}

type refusingInviteReader struct{ socialinbox.InviteNoticeReader }

type acceptingAdmission struct{}

func (acceptingAdmission) ValidateActor(context.Context, identity.ActorContext, time.Time) error {
	return nil
}

// roomInviteClaimService is the production READ_NOTICE owner while gifts are active.
func roomInviteClaimService(p *pg.Pool) socialgift.Service {
	relations := socialrelationstore.Store{}
	return socialgift.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Reads: tx.Runner{DB: p}, Store: socialgiftstore.Store{}, Content: contentstore.Store{Queryer: p},
		Players: i4store.PlayerRootLocker{}, Relations: relations, Privacy: socialrelation.FriendDMPrivacyProvider{Store: relations}, Inbox: socialinbox.GiftService{Store: socialinboxstore.Store{}},
		NoticeEvidence: socialinboxstore.Store{}, Grants: compositeI5(p), Admission: acceptingAdmission{}, Fence: i5store.Store{Queryer: p}}
}

func noticeOfType(page []socialview.Notice, noticeType int16) (socialview.Notice, bool) {
	for _, row := range page {
		if row.Type == noticeType {
			return row, true
		}
	}
	return socialview.Notice{}, false
}

func dismissRoomInvite(t *testing.T, p *pg.Pool, actor identity.ActorContext, noticeID int64) {
	t.Helper()
	service := socialdismiss.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}},
		PlayerRoots: i4store.PlayerRootLocker{}, Roots: socialrelationstore.Store{}, Inbox: socialinboxstore.Store{}}
	ids, err := service.Dismiss(ctx, actor, []socialinbox.NoticeID{socialinbox.NoticeID(noticeID)}, op())
	if err != nil || len(ids) != 1 || ids[0] != socialinbox.NoticeID(noticeID) {
		t.Fatalf("READ_NOTICE ids %v %v", ids, err)
	}
}

func requireRoomInviteFields(t *testing.T, row socialview.Notice, inviter identity.PlayerID, roomID int64, paradise int64, chapter int64) {
	t.Helper()
	if row.Player.PlayerID != int64(inviter) || row.Player.Level <= 0 || row.ID <= 0 {
		t.Fatalf("common notice fields %+v", row)
	}
	if row.RoomID == nil || *row.RoomID != roomID {
		t.Fatalf("room_id %+v", row.RoomID)
	}
	if row.Type == socialinbox.RoomInviteIllusionNoticeType && (row.ParadiseID == nil || *row.ParadiseID != paradise) {
		t.Fatalf("paradise_id %+v", row.ParadiseID)
	}
	if row.Type == socialinbox.RoomInviteOccultNoticeType && (row.ChapterID == nil || *row.ChapterID != chapter || row.Force == nil || *row.Force <= 0) {
		t.Fatalf("occult fields %+v", row)
	}
}

func TestI9_8ERoomInviteIllusionNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := illusionTime(t)
	mode := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	owner, _ := illusionTeamOwner(t, p, server, 10001002)
	target, _ := illusionOwner(t, p, server)
	created, err := mode.CreateRoom(ctx, owner, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := illusionRoomID(t, created)
	if _, err = mode.Invite(ctx, owner, target.PlayerID, op()); err != nil {
		t.Fatal("invite", err)
	}
	page := socialNoticePage(t, p, target)
	row, found := noticeOfType(page, socialinbox.RoomInviteIllusionNoticeType)
	if !found {
		t.Fatalf("illusion invite missing %+v", page)
	}
	requireRoomInviteFields(t, row, owner.PlayerID, roomID, int64(di.FirstCampaignID), 0)

	dismissRoomInvite(t, p, target, row.ID)
	if _, found = noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteIllusionNoticeType); found {
		t.Fatal("READ_NOTICE did not remove the illusion invite")
	}

	// With gifts active READ_NOTICE is the gift Claim, and a guild bundle reads
	// through the invite window.
	if _, err = mode.Invite(ctx, owner, target.PlayerID, op()); err != nil {
		t.Fatal("re-invite before claim", err)
	}
	bundled, err := guildBundleReads(p).LoadList(ctx, target, sp.Notice, op())
	if err != nil {
		t.Fatal("invite window read", err)
	}
	bundledPage, err := socialpresentation.MapList(bundled, sp.Notice)
	if err != nil {
		t.Fatal("invite window wire", err)
	}
	row, found = noticeOfType(bundledPage.([]socialview.Notice), socialinbox.RoomInviteIllusionNoticeType)
	if !found {
		t.Fatal("illusion invite missing from the invite window")
	}
	requireRoomInviteFields(t, row, owner.PlayerID, roomID, int64(di.FirstCampaignID), 0)
	claimed, err := roomInviteClaimService(p).Claim(ctx, target, []socialinbox.NoticeID{socialinbox.NoticeID(row.ID)}, op())
	if err != nil {
		t.Fatal("READ_NOTICE claim", err)
	}
	if len(claimed.NoticeIDs) != 1 || int64(claimed.NoticeIDs[0]) != row.ID || claimed.Amount != 0 {
		t.Fatalf("READ_NOTICE claim result %+v", claimed)
	}
	if _, found = noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteIllusionNoticeType); found {
		t.Fatal("the gift Claim did not remove the illusion invite")
	}
	if _, err = mode.Invite(ctx, owner, target.PlayerID, op()); err != nil {
		t.Fatal("re-invite", err)
	}
	row, found = noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteIllusionNoticeType)
	if !found {
		t.Fatal("re-invite did not reappear")
	}

	// Aged past the PRIVATE_POLICY window: hidden, then deleted by the next invite.
	exec(t, p, `UPDATE social_notices SET notice_time=clock_timestamp()-interval '25 hours' WHERE recipient_player_id=$1 AND source_kind='social-room-invite.v1'`, int64(target.PlayerID))
	if _, found = noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteIllusionNoticeType); found {
		t.Fatal("an aged invite stayed visible")
	}
	if _, err = mode.Invite(ctx, owner, target.PlayerID, op()); err != nil {
		t.Fatal("invite after retention", err)
	}
	if n := scalar(t, p, `SELECT count(*) FROM social_notices WHERE notice_id=$1`, row.ID); n != 0 {
		t.Fatal("the aged invite row was not deleted")
	}
	if _, found = noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteIllusionNoticeType); !found {
		t.Fatal("the fresh invite is missing")
	}

	other, _ := illusionOwner(t, p, rankingServer(t, p))
	if _, err = mode.Invite(ctx, owner, other.PlayerID, op()); err == nil {
		t.Fatal("a recipient on another logical server was accepted")
	}
}

func TestI9_8ERoomInviteOccultNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	mode, clock := occultTestMode(t, p)
	owner, _ := occultOwner(t, p, server, 2)
	target, _ := occultOwner(t, p, server, 2)
	clock.at = time.Now().UTC()
	created, err := mode.CreateTeam(ctx, owner, 2, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := occultRoomID(t, created)
	if _, err = mode.Invite(ctx, owner, target.PlayerID, op()); err != nil {
		t.Fatal("invite", err)
	}
	row, found := noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteOccultNoticeType)
	if !found {
		t.Fatal("occult invite missing")
	}
	requireRoomInviteFields(t, row, owner.PlayerID, roomID, 0, 2)
	dismissRoomInvite(t, p, target, row.ID)
	if _, found = noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteOccultNoticeType); found {
		t.Fatal("READ_NOTICE did not remove the occult invite")
	}
	if _, err = mode.Invite(ctx, owner, target.PlayerID, op()); err != nil {
		t.Fatal("re-invite", err)
	}
	if _, found = noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteOccultNoticeType); !found {
		t.Fatal("occult re-invite did not reappear")
	}
	other, _ := occultOwner(t, p, rankingServer(t, p), 2)
	if _, err = mode.Invite(ctx, owner, other.PlayerID, op()); err == nil {
		t.Fatal("a recipient on another logical server was accepted")
	}
}

func TestI9_8ERoomInviteCoopNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	owner, _ := adventureOwner(t, p, server, 100, 10001001)
	target, _ := adventureOwner(t, p, server, 100, 10001001)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	opContext := opPinned(installed(t, p))
	opContext.StartedAt = clock.at
	putAdventureOccurrence(t, p, owner.PlayerID, da.EventIllusion, da.IllusionHiddenBoss, clock.at, clock.at.Add(2*time.Hour), "invite-coop")
	created, err := mode.CreateCoop(ctx, owner, opContext)
	if err != nil {
		t.Fatal("create coop", err)
	}
	roomID := adventureRoomIDFrom(created)
	if _, err = mode.InviteCoop(ctx, owner, target.PlayerID, opContext); err != nil {
		t.Fatal("coop invite", err)
	}
	row, found := noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteCoopNoticeType)
	if !found {
		t.Fatal("co-op invite missing")
	}
	requireRoomInviteFields(t, row, owner.PlayerID, roomID, 0, 0)
	dismissRoomInvite(t, p, target, row.ID)
	if _, found = noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteCoopNoticeType); found {
		t.Fatal("READ_NOTICE did not remove the co-op invite")
	}
	if _, err = mode.InviteCoop(ctx, owner, target.PlayerID, opContext); err != nil {
		t.Fatal("co-op re-invite", err)
	}
	if _, found = noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteCoopNoticeType); !found {
		t.Fatal("co-op re-invite did not reappear")
	}
	other, _ := adventureOwner(t, p, rankingServer(t, p), 100, 10001001)
	if _, err = mode.InviteCoop(ctx, owner, other.PlayerID, opContext); err == nil {
		t.Fatal("a recipient on another logical server was accepted")
	}
}

func TestI9_8ERoomInviteDefenseNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	owner, _ := adventureOwner(t, p, server, 11, 10001001)
	target, _ := adventureOwner(t, p, server, 11, 10001001)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	opContext := opPinned(installed(t, p))
	opContext.StartedAt = clock.at
	putAdventureOccurrence(t, p, owner.PlayerID, da.EventDefense, 0, clock.at, clock.at.Add(time.Hour), "invite-defense")
	info, err := mode.Info(ctx, owner, da.EventDefense, opContext)
	if err != nil {
		t.Fatal("defense info", err)
	}
	roomID := adventureRoomID(t, info)
	if _, err = mode.InviteDefense(ctx, owner, target.PlayerID, opContext); err != nil {
		t.Fatal("defense invite", err)
	}
	row, found := noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteDefenseNoticeType)
	if !found {
		t.Fatal("defense invite missing")
	}
	requireRoomInviteFields(t, row, owner.PlayerID, roomID, 0, 0)
	dismissRoomInvite(t, p, target, row.ID)
	if _, found = noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteDefenseNoticeType); found {
		t.Fatal("READ_NOTICE did not remove the defense invite")
	}
	if _, err = mode.InviteDefense(ctx, owner, target.PlayerID, opContext); err != nil {
		t.Fatal("defense re-invite", err)
	}
	if _, found = noticeOfType(socialNoticePage(t, p, target), socialinbox.RoomInviteDefenseNoticeType); !found {
		t.Fatal("defense re-invite did not reappear")
	}
	other, _ := adventureOwner(t, p, rankingServer(t, p), 11, 10001001)
	if _, err = mode.InviteDefense(ctx, owner, other.PlayerID, opContext); err == nil {
		t.Fatal("a recipient on another logical server was accepted")
	}
}
