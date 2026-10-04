package playerpresentation

import (
	"context"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
)

type directoryStub struct {
	profile playerdirectory.Profile
	ok      bool
	err     error
}

func (s directoryStub) Profile(context.Context, identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return s.profile, s.ok, s.err
}

type typeStub struct {
	value int64
	ok    bool
	err   error
}

func (s typeStub) PlayerType(context.Context, identity.PlayerID) (int64, bool, error) {
	return s.value, s.ok, s.err
}

func TestMinimalPresentationComposesI4AndI5WithoutInventingPlayerTypeRange(t *testing.T) {
	pid := identity.PlayerID(100001)
	s := Service{
		Directory: directoryStub{profile: playerdirectory.Profile{PlayerID: pid, Name: "A", Level: 12, AvatarID: 110001001, AvatarFrameID: 9, ConquerLevel: 2, ConquerLoopID: 3}, ok: true},
		Types:     typeStub{value: -7, ok: true},
	}
	got, ok, err := s.Read(context.Background(), pid)
	if err != nil || !ok {
		t.Fatalf("ok=%v err=%v", ok, err)
	}
	if got.PlayerID != pid || got.Name != "A" || got.Level != 12 || got.AvatarID != 110001001 || got.AvatarFrameID != 9 || got.ConquerLevel != 2 || got.ConquerLoopID != 3 || got.PlayerType != -7 {
		t.Fatalf("got=%+v", got)
	}
}

func TestMinimalPresentationPropagatesOwnerAbsenceAndErrors(t *testing.T) {
	pid := identity.PlayerID(100001)
	boom := errors.New("boom")
	if _, ok, err := (Service{Directory: directoryStub{ok: false}, Types: typeStub{ok: true}}).Read(context.Background(), pid); err != nil || ok {
		t.Fatalf("directory absence ok=%v err=%v", ok, err)
	}
	profile := playerdirectory.Profile{PlayerID: pid, Level: 1, AvatarID: 1}
	if _, ok, err := (Service{Directory: directoryStub{profile: profile, ok: true}, Types: typeStub{err: boom}}).Read(context.Background(), pid); !errors.Is(err, boom) || ok {
		t.Fatalf("type error ok=%v err=%v", ok, err)
	}
}
