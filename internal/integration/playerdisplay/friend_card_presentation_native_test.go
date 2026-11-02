//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/socialview"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type fixedSocialAuthority struct{ actor identity.ActorContext }

func (a fixedSocialAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

type noInviteNotices struct{}

func (noInviteNotices) ReadImmutableInviteNoticeTx(context.Context, tx.Queryer, socialinbox.Notice) (gi.Issue, error) {
	return gi.Issue{}, nil
}
func (noInviteNotices) ReadCurrentInviteNoticeTx(context.Context, tx.Queryer, socialinbox.Notice) (gi.Snapshot, error) {
	return gi.Snapshot{}, nil
}

type noGifts struct{}

func (noGifts) GiftSnapshotTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, at time.Time) (socialgift.Snapshot, error) {
	day, e := socialgift.Day(at)
	return socialgift.Snapshot{Day: day, Policy: socialgift.DayPolicy}, e
}
func (noGifts) GiftNoticeValidityTx(context.Context, tx.Queryer, identity.PlayerID, []socialinbox.Notice) (map[socialinbox.NoticeID]bool, error) {
	return map[socialinbox.NoticeID]bool{}, nil
}

// TestPlaytestFriendCardVIPFrameAndSkinAvatar reproduces the live friend list:
// one friend wears avatar 110007200 (a type-7 skin avatar) and VIP frame
// 120001003. MID 176 and MID 189 list 1 must return 200 with the card present.
func TestPlaytestFriendCardVIPFrameAndSkinAvatar(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	requester := bornActor(t, p)
	friend := bornActor(t, p)
	exec(t, p, `UPDATE player_profiles SET display_name=$2,avatar_id=110007200,avatar_frame_id=120001003 WHERE player_id=$1`, int64(friend.PlayerID), "Hoper")
	exec(t, p, `UPDATE player_profiles SET display_name=$2 WHERE player_id=$1`, int64(requester.PlayerID), "Moppleton")
	exec(t, p, `UPDATE player_directory_profiles SET name=$2,avatar_id=110007200,avatar_frame_id=120001003 WHERE player_id=$1`, int64(friend.PlayerID), "Hoper")
	exec(t, p, `INSERT INTO player_display_selections(player_id,avatar_table_id,avatar_category,title_id,title_unique_id,bubble_id)VALUES($1,110007200,5,0,0,10001)
		ON CONFLICT(player_id) DO UPDATE SET avatar_table_id=110007200,avatar_category=5,bubble_id=10001`, int64(friend.PlayerID))
	skillHero(t, p, friend, rev, 10001200, 10073)
	exec(t, p, `INSERT INTO player_hero_skin_entitlements(player_id,partner_id,model_id,expires_at)VALUES($1,10073,40001200,NULL)`, int64(friend.PlayerID))
	if _, e := privilegeService(p, p).ImportManual(ctx, authority(), importQ(friend, uuid().String(), maximumCharge), op()); e != nil {
		t.Fatalf("friend VIP frame privilege: %v", e)
	}
	low, high, e := sr.CanonicalPair(requester.PlayerID, friend.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	exec(t, p, `INSERT INTO player_social_roots(player_id,created_at,updated_at)VALUES($1,clock_timestamp(),clock_timestamp()),($2,clock_timestamp(),clock_timestamp())ON CONFLICT DO NOTHING`, int64(requester.PlayerID), int64(friend.PlayerID))
	exec(t, p, `INSERT INTO social_friendships(player_low_id,player_high_id,generation,active,activated_at,updated_at)VALUES($1,$2,1,true,clock_timestamp(),clock_timestamp())`, int64(low), int64(high))

	presentation := socialpresentation.TransactionReader{Display: display4a(p)}
	projection := sp.Service{Runner: tx.Runner{DB: p}, PlayerRoots: i4store.PlayerRootLocker{}, Relations: socialrelationstore.Store{}, Inbox: socialinboxstore.Store{},
		Directory: i4store.TransactionDiscoveryReader{}, Presentation: presentation, PresentationAt: presentation, Observer: presentation,
		Invites: noInviteNotices{}, Gifts: noGifts{}, NoticePages: socialinboxstore.Store{}}
	dispatcher := stockruntime.SocialDispatcher{Authority: fixedSocialAuthority{actor: requester}, Projection: projection}

	requests := []struct {
		mid    uint16
		params map[string]any
	}{
		{176, map[string]any{}},
		{189, map[string]any{"list_type": int64(1)}},
	}
	for _, request := range requests {
		response := dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: request.mid, Operation: op(), ReceivedAt: time.Now().UTC(),
			Claims: wire.CredentialClaims{Token: "fixture", Region: int64(requester.LogicalServerID)}, Params: request.params}})
		if response.HTTPStatus != 200 {
			t.Fatalf("MID %d status=%d body=%v cause=%v", request.mid, response.HTTPStatus, response.Body, response.Cause)
		}
		var cards []socialview.Friend
		switch body := response.JSON.(type) {
		case socialview.Base:
			cards = body.Friends
		case []socialview.Friend:
			cards = body
		default:
			t.Fatalf("MID %d response shape %T", request.mid, response.JSON)
		}
		if len(cards) != 1 || cards[0].PlayerID != int64(friend.PlayerID) {
			t.Fatalf("MID %d friend cards %+v", request.mid, cards)
		}
		if cards[0].AvatarID != 110007200 || cards[0].AvatarFrameID != 120001003 {
			t.Fatalf("MID %d avatar=%d frame=%d", request.mid, cards[0].AvatarID, cards[0].AvatarFrameID)
		}
	}
}
