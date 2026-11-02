package guildcore

import (
	"context"
	"errors"
	"strconv"
	"strings"

	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ApplyNoticeRoute carries the stock GUILD_BE_APPLYED (notice_type 7) red-dot
// wakeup. The frame has no params; the client reloads MID 581 itself.
const ApplyNoticeRoute = "guild.apply.notice.v1"

const (
	applyNoticeFiledMarker    = "f"
	applyNoticeResolvedMarker = "r"
)

var ErrInvalidApplyNoticeRef = errors.New("invalid guild apply notice reference")

// ApplyNoticeEmitter writes the transactional wakeup of one guild application
// notice. The receipt that the guild command writes in the same transaction is
// the replay fence: a replayed command never reaches this call.
type ApplyNoticeEmitter interface {
	ApplicationFiledTx(context.Context, tx.Tx, guild.ID) error
	ApplicationResolvedTx(context.Context, tx.Tx, identity.PlayerID) error
}

// ApplyNoticeRef is one decoded wakeup reference. Filed references name the
// guild; resolved references name the officer who acted.
type ApplyNoticeRef struct {
	GuildID   guild.ID
	Recipient identity.PlayerID
	Resolved  bool
}

func ApplicationFiledNoticeRef(gid guild.ID) (string, error) {
	if gid <= 0 {
		return "", ErrInvalidApplyNoticeRef
	}
	return applyNoticeFiledMarker + ":" + strconv.FormatInt(int64(gid), 10), nil
}

func ApplicationResolvedNoticeRef(recipient identity.PlayerID) (string, error) {
	if !recipient.Valid() {
		return "", ErrInvalidApplyNoticeRef
	}
	return applyNoticeResolvedMarker + ":" + strconv.FormatInt(int64(recipient), 10), nil
}

func DecodeApplyNoticeRef(raw string) (ApplyNoticeRef, error) {
	marker, rawValue, found := strings.Cut(raw, ":")
	if !found {
		return ApplyNoticeRef{}, ErrInvalidApplyNoticeRef
	}
	value, err := strconv.ParseInt(rawValue, 10, 64)
	if err != nil || value <= 0 || strconv.FormatInt(value, 10) != rawValue {
		return ApplyNoticeRef{}, ErrInvalidApplyNoticeRef
	}
	switch marker {
	case applyNoticeResolvedMarker:
		return ApplyNoticeRef{Recipient: identity.PlayerID(value), Resolved: true}, nil
	case applyNoticeFiledMarker:
		return ApplyNoticeRef{GuildID: guild.ID(value)}, nil
	default:
		return ApplyNoticeRef{}, ErrInvalidApplyNoticeRef
	}
}

func (s Service) emitApplicationFiledNoticeTx(c context.Context, t tx.Tx, gid guild.ID) error {
	if s.Notices == nil {
		return nil
	}
	return s.Notices.ApplicationFiledTx(c, t, gid)
}

func (s Service) emitApplicationResolvedNoticeTx(c context.Context, t tx.Tx, actor identity.PlayerID) error {
	if s.Notices == nil {
		return nil
	}
	return s.Notices.ApplicationResolvedTx(c, t, actor)
}
