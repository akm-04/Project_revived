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
	ApplicationFiledTx(context.Context, tx.Tx, guild.ID, identity.PlayerID, int64) error
	ApplicationResolvedTx(context.Context, tx.Tx, identity.PlayerID) error
}

// ApplyNoticeRef is one decoded wakeup reference. Filed references name the
// pending application; resolved references name the officer who acted.
type ApplyNoticeRef struct {
	GuildID    guild.ID
	Applicant  identity.PlayerID
	Generation int64
	Recipient  identity.PlayerID
	Resolved   bool
}

func ApplicationFiledNoticeRef(gid guild.ID, applicant identity.PlayerID, generation int64) (string, error) {
	if gid <= 0 || !applicant.Valid() || generation <= 0 {
		return "", ErrInvalidApplyNoticeRef
	}
	return applyNoticeFiledMarker + ":" + strconv.FormatInt(int64(gid), 10) + ":" + strconv.FormatInt(int64(applicant), 10) + ":" + strconv.FormatInt(generation, 10), nil
}

func ApplicationResolvedNoticeRef(recipient identity.PlayerID) (string, error) {
	if !recipient.Valid() {
		return "", ErrInvalidApplyNoticeRef
	}
	return applyNoticeResolvedMarker + ":" + strconv.FormatInt(int64(recipient), 10), nil
}

func DecodeApplyNoticeRef(raw string) (ApplyNoticeRef, error) {
	parts := strings.Split(raw, ":")
	if len(parts) < 2 {
		return ApplyNoticeRef{}, ErrInvalidApplyNoticeRef
	}
	switch parts[0] {
	case applyNoticeResolvedMarker:
		if len(parts) != 2 {
			return ApplyNoticeRef{}, ErrInvalidApplyNoticeRef
		}
		recipient, err := positiveInt64(parts[1])
		if err != nil {
			return ApplyNoticeRef{}, ErrInvalidApplyNoticeRef
		}
		return ApplyNoticeRef{Recipient: identity.PlayerID(recipient), Resolved: true}, nil
	case applyNoticeFiledMarker:
		if len(parts) != 4 {
			return ApplyNoticeRef{}, ErrInvalidApplyNoticeRef
		}
		guildID, err := positiveInt64(parts[1])
		if err != nil {
			return ApplyNoticeRef{}, ErrInvalidApplyNoticeRef
		}
		applicant, err := positiveInt64(parts[2])
		if err != nil {
			return ApplyNoticeRef{}, ErrInvalidApplyNoticeRef
		}
		generation, err := positiveInt64(parts[3])
		if err != nil {
			return ApplyNoticeRef{}, ErrInvalidApplyNoticeRef
		}
		return ApplyNoticeRef{GuildID: guild.ID(guildID), Applicant: identity.PlayerID(applicant), Generation: generation}, nil
	default:
		return ApplyNoticeRef{}, ErrInvalidApplyNoticeRef
	}
}

func positiveInt64(raw string) (int64, error) {
	value, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || value <= 0 || strconv.FormatInt(value, 10) != raw {
		return 0, ErrInvalidApplyNoticeRef
	}
	return value, nil
}

func (s Service) emitApplicationFiledNoticeTx(c context.Context, t tx.Tx, gid guild.ID, applicant identity.PlayerID, generation int64) error {
	if s.Notices == nil {
		return nil
	}
	return s.Notices.ApplicationFiledTx(c, t, gid, applicant, generation)
}

func (s Service) emitApplicationResolvedNoticeTx(c context.Context, t tx.Tx, actor identity.PlayerID) error {
	if s.Notices == nil {
		return nil
	}
	return s.Notices.ApplicationResolvedTx(c, t, actor)
}
