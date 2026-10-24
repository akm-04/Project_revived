package playerpresentation

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
)

var ErrInvalidMinimalPresentation = errors.New("invalid minimal player presentation")

// PlayerTypeReader is the narrow I5-owned read seam required by I7A. It exposes
// only canonical PlayerType and deliberately carries no wire/protocol concerns.
type PlayerTypeReader interface {
	PlayerType(context.Context, identity.PlayerID) (int64, bool, error)
}

type Minimal struct {
	PlayerID      identity.PlayerID
	Name          string
	Level         int64
	AvatarID      int64
	AvatarFrameID int64
	ConquerLevel  int64
	ConquerLoopID int64
	PlayerType    int64
	TitleInfo     string
	BubbleInfo    string
}

func (m Minimal) Validate() error {
	if m.TitleInfo != "" && !player.ValidateChatCosmeticString(m.TitleInfo, true) || m.BubbleInfo != "" && !player.ValidateChatCosmeticString(m.BubbleInfo, false) {
		return ErrInvalidMinimalPresentation
	}
	if !m.PlayerID.Valid() || m.Level < 1 || m.AvatarID < 0 || m.AvatarFrameID < 0 || m.ConquerLevel < 0 || m.ConquerLoopID < 0 {
		return ErrInvalidMinimalPresentation
	}
	// PlayerType intentionally has no inferred range. Canonical I5 storage is
	// returned verbatim until source/original-server evidence qualifies one.
	return nil
}

type Service struct {
	Directory playerdirectory.Reader
	Types     PlayerTypeReader
}

func (s Service) Read(ctx context.Context, pid identity.PlayerID) (Minimal, bool, error) {
	if s.Directory == nil || s.Types == nil || !pid.Valid() {
		return Minimal{}, false, ErrInvalidMinimalPresentation
	}
	profile, ok, err := s.Directory.Profile(ctx, pid)
	if err != nil || !ok {
		return Minimal{}, ok, err
	}
	playerType, ok, err := s.Types.PlayerType(ctx, pid)
	if err != nil || !ok {
		return Minimal{}, ok, err
	}
	out := Minimal{
		PlayerID: profile.PlayerID, Name: profile.Name, Level: profile.Level,
		AvatarID: profile.AvatarID, AvatarFrameID: profile.AvatarFrameID,
		ConquerLevel: profile.ConquerLevel, ConquerLoopID: profile.ConquerLoopID,
		PlayerType: playerType,
	}
	if err := out.Validate(); err != nil {
		return Minimal{}, false, err
	}
	return out, true, nil
}
