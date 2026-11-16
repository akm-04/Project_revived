package profilefeedback

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

type directoryStub struct {
	profile playerdirectory.Profile
	found   bool
	err     error
}

func (d directoryStub) ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return d.profile, d.found, d.err
}

func authorBasis(pid identity.PlayerID) i5.PublicPlayerBasis {
	return i5.PublicPlayerBasis{
		Profile:     player.Profile{PlayerID: pid, DisplayName: "author", AvatarID: 1},
		Progression: player.Progression{PlayerID: pid, Level: 5},
	}
}

func TestAuthorProjectsDirectoryConquerFacts(t *testing.T) {
	pid := identity.PlayerID(100001)
	directory := directoryStub{found: true, profile: playerdirectory.Profile{PlayerID: pid, Name: "author", Level: 5, AvatarID: 1, ConquerLevel: 21, ConquerLoopID: 23}}
	got, e := (Service{Directory: directory}).author(context.Background(), nil, authorBasis(pid), "rev", time.Unix(100, 0), 1)
	if e != nil || got.Level != 5 || got.ConquerLevel != 21 || got.ConquerLoopID != 23 {
		t.Fatalf("author projection %+v %v", got, e)
	}
}

func TestAuthorRefusesMissingDirectoryRow(t *testing.T) {
	pid := identity.PlayerID(100001)
	_, e := (Service{Directory: directoryStub{}}).author(context.Background(), nil, authorBasis(pid), "rev", time.Unix(100, 0), 1)
	if !errors.Is(e, ErrProvider) {
		t.Fatalf("missing directory row accepted: %v", e)
	}
}
