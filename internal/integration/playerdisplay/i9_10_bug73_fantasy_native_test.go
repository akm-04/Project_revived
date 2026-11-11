//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	il "gxb.local/backend/v2/internal/application/illusion"
	"gxb.local/backend/v2/internal/domain/friendmessage"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	di "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

// bug73MasterPet grants and hatches the master pet the stock picker sends as
// pet_id, so the pick fixtures exercise the owned-pet path.
func bug73MasterPet(t *testing.T, p *pg.Pool, master identity.ActorContext) {
	t.Helper()
	revision := installed(t, p)
	definition, err := (contentstore.Store{Queryer: p}).PetAcquisitionTx(ctx, p, revision, 10010001)
	if err != nil {
		t.Fatal(err)
	}
	grantGenuine(t, p, master, revision, "bug73 master pet", []grant.Line{
		{Kind: grant.StackItem, ItemID: definition.EggItemID, Amount: 1},
		{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 10000}})
	pets := genuinePetService(p)
	hatched := must(pets.Summon(ctx, master, 10010001, op()))(t, "pet summon")
	must(pets.CleanCD(ctx, master, hatched.PetID, op()))(t, "pet hatch")
}

type bug73Authority struct{ actor identity.ActorContext }

func (a bug73Authority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

func bug73Notice(t *testing.T, p *pg.Pool, roomID int64) stockruntime.IllusionRoomNotice {
	t.Helper()
	reader := stockruntime.IllusionRoomNoticeReader{Store: sharedroomstore.Store{}, Directory: i4store.PlayerDirectoryReader{}, Queryer: p}
	notice, found, err := reader.ReadRoomNotice(ctx, fmt.Sprint(roomID))
	if err != nil || !found {
		t.Fatalf("518 read %v %v", found, err)
	}
	return notice
}

func bug73TeamInfo(t *testing.T, notice stockruntime.IllusionRoomNotice) map[string]any {
	t.Helper()
	var info map[string]any
	if err := json.Unmarshal(notice.TeamInfo, &info); err != nil {
		t.Fatal(err)
	}
	return info
}

func TestBug73ThreeMembersReachSelectionTogetherNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	a, _ := illusionTeamOwner(t, p, server, 10001002)
	b, _ := illusionTeamOwner(t, p, server, 10001003, 10001004)
	c, _ := illusionTeamOwner(t, p, server, 10001005, 10001006)

	created, err := s.CreateRoom(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := illusionRoomID(t, created)
	for _, member := range []identity.ActorContext{b, c} {
		if _, err = s.EnterRoom(ctx, member, roomID, op()); err != nil {
			t.Fatal("join", err)
		}
	}
	// Three seated members still wait in the prepare room until the master 1351.
	notice := bug73Notice(t, p, roomID)
	if notice.Status != di.StagePrepare || len(notice.Seated) != 3 {
		t.Fatalf("premature selection %+v", notice)
	}
	if _, err = s.Prepare(ctx, b, op()); !errors.Is(err, di.ErrRefused) {
		t.Fatalf("a mate opened selection: %v", err)
	}
	if _, err = s.Prepare(ctx, a, op()); err != nil {
		t.Fatal("1351", err)
	}
	notice = bug73Notice(t, p, roomID)
	if notice.Status != di.StageSelectHero {
		t.Fatalf("selection status %d", notice.Status)
	}
	if len(notice.Seated) != 3 || notice.Seated[0] != a.PlayerID || notice.Seated[1] != b.PlayerID || notice.Seated[2] != c.PlayerID {
		t.Fatalf("selection seats %v", notice.Seated)
	}
}

func TestBug73PickOrderNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	a, _ := illusionTeamOwner(t, p, server, 10001002)
	b, _ := illusionTeamOwner(t, p, server, 10001003, 10001004)
	c, _ := illusionTeamOwner(t, p, server, 10001005, 10001006)
	bug73MasterPet(t, p, a)

	created, err := s.CreateRoom(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := illusionRoomID(t, created)
	for _, member := range []identity.ActorContext{b, c} {
		if _, err = s.EnterRoom(ctx, member, roomID, op()); err != nil {
			t.Fatal(err)
		}
	}
	if _, err = s.Prepare(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = s.SetPartner(ctx, b, il.PartnerRequest{Heroes: []int64{10001003, 10001004}}, op()); !errors.Is(err, di.ErrRefused) {
		t.Fatalf("mate one picked before the master: %v", err)
	}
	if _, err = s.SetPartner(ctx, c, il.PartnerRequest{Heroes: []int64{10001005, 10001006}}, op()); !errors.Is(err, di.ErrRefused) {
		t.Fatalf("mate two picked before the master: %v", err)
	}
	dispatcher := stockruntime.IllusionRoomDispatcher{Authority: bug73Authority{actor: c}, Service: s}
	params := map[string]any{"partner_str": "10001005|10001006", "pet_id": int64(0), "token": "bearer", "region": int64(server)}
	request := httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: op(), MID: 1356, ReceivedAt: clock.at, Params: params,
		Claims: wire.CredentialClaims{Token: "bearer", Region: int64(server)}}}
	refused := dispatcher.Dispatch(ctx, request)
	if refused.HTTPStatus != 409 || refused.Body["error_code"] != int64(35028) {
		t.Fatalf("out-of-turn HTTP %d %#v", refused.HTTPStatus, refused.Body)
	}

	for _, step := range []struct {
		name  string
		actor identity.ActorContext
		pick  il.PartnerRequest
	}{
		{"master hero", a, il.PartnerRequest{Heroes: []int64{10001002}}},
		{"master pet", a, il.PartnerRequest{Heroes: []int64{10001002}, PetID: 10010001}},
		{"mate one first slot", b, il.PartnerRequest{Heroes: []int64{0, 10001004}}},
		{"mate one full", b, il.PartnerRequest{Heroes: []int64{10001003, 10001004}}},
		{"mate two first slot", c, il.PartnerRequest{Heroes: []int64{10001005, 0}}},
		{"mate two full", c, il.PartnerRequest{Heroes: []int64{10001005, 10001006}}},
	} {
		if _, err = s.SetPartner(ctx, step.actor, step.pick, op()); err != nil {
			t.Fatal(step.name, err)
		}
	}
}

func TestBug73PickPushShapeNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	a, _ := illusionTeamOwner(t, p, server, 10001002)
	b, _ := illusionTeamOwner(t, p, server, 10001003, 10001004)
	c, _ := illusionTeamOwner(t, p, server, 10001005, 10001006)
	bug73MasterPet(t, p, a)

	created, err := s.CreateRoom(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := illusionRoomID(t, created)
	for _, member := range []identity.ActorContext{b, c} {
		if _, err = s.EnterRoom(ctx, member, roomID, op()); err != nil {
			t.Fatal(err)
		}
	}
	if _, err = s.Prepare(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	for _, step := range []struct {
		actor identity.ActorContext
		pick  il.PartnerRequest
	}{
		{a, il.PartnerRequest{Heroes: []int64{10001002}}},
		{a, il.PartnerRequest{Heroes: []int64{10001002}, PetID: 10010001}},
		{b, il.PartnerRequest{Heroes: []int64{10001003, 10001004}}},
		{c, il.PartnerRequest{Heroes: []int64{10001005, 10001006}}},
	} {
		if _, err = s.SetPartner(ctx, step.actor, step.pick, op()); err != nil {
			t.Fatal(err)
		}
	}
	info := bug73TeamInfo(t, bug73Notice(t, p, roomID))
	if info["status"] != float64(di.StageSelectHero) || info["mate_1_partner"] != "10001003|10001004" || info["mate_2_partner"] != "10001005|10001006" {
		t.Fatalf("pick push %#v", info)
	}
	details, ok := info["mate_1_partner_detail"].([]any)
	if !ok || len(details) != 2 {
		t.Fatalf("mate one detail %#v", info["mate_1_partner_detail"])
	}
	for index, wanted := range []float64{10001003, 10001004} {
		row, ok := details[index].(map[string]any)
		if !ok || row["table_id"] != wanted || row["partner_id"] == nil {
			t.Fatalf("mate one detail %d %#v", index, details[index])
		}
	}
	pet, ok := info["master_pet_detail"].(map[string]any)
	if !ok || pet["table_id"] == nil {
		t.Fatalf("master pet detail %#v", info["master_pet_detail"])
	}
}

func TestBug73TeamChatReachesBothMatesNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	a, _ := illusionTeamOwner(t, p, server, 10001002)
	b, _ := illusionTeamOwner(t, p, server, 10001003, 10001004)
	c, _ := illusionTeamOwner(t, p, server, 10001005, 10001006)

	created, err := s.CreateRoom(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := illusionRoomID(t, created)
	for _, member := range []identity.ActorContext{b, c} {
		if _, err = s.EnterRoom(ctx, member, roomID, op()); err != nil {
			t.Fatal(err)
		}
	}
	message := friendmessage.Message{Kind: 0, Text: "team hello", SelectType: friendmessage.SelectIllusion}
	for _, mate := range []identity.ActorContext{b, c} {
		if err = s.SendRoomChat(ctx, a, mate.PlayerID, message, op()); err != nil {
			t.Fatal("room chat", err)
		}
	}
	if err = s.SendRoomChat(ctx, a, a.PlayerID, message, op()); !errors.Is(err, di.ErrInvalid) {
		t.Fatalf("self chat %v", err)
	}
	outsider, _ := illusionOwner(t, p, rankingServer(t, p))
	if err = s.SendRoomChat(ctx, a, outsider.PlayerID, message, op()); !errors.Is(err, di.ErrRefused) {
		t.Fatalf("outsider chat %v", err)
	}
	notice := bug73Notice(t, p, roomID)
	if len(notice.Chats) != 2 {
		t.Fatalf("chat rows %#v", notice.Chats)
	}
	wanted := map[identity.PlayerID]bool{b.PlayerID: true, c.PlayerID: true}
	for _, chat := range notice.Chats {
		if chat.Sender != int64(a.PlayerID) || len(chat.Recipients) != 1 || !wanted[identity.PlayerID(chat.Recipients[0])] {
			t.Fatalf("chat recipient %#v", chat)
		}
		if chat.Message != `{"msgType":0,"message":"team hello","selectType":1}` {
			t.Fatalf("chat payload %q", chat.Message)
		}
	}
}
