package postgres

import (
	"context"

	"gxb.local/backend/v2/internal/application/guildcore"
	wake "gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// GuildApplyNoticeEmitter writes the guild application notice wakeup through
// the caller's transaction, so the push is visible only after the guild change
// commits. Replayed receipts never reach this emitter.
type GuildApplyNoticeEmitter struct{}

func (GuildApplyNoticeEmitter) ApplicationFiledTx(c context.Context, t tx.Tx, gid guild.ID, applicant identity.PlayerID, generation int64) error {
	ref, err := guildcore.ApplicationFiledNoticeRef(gid, applicant, generation)
	if err != nil {
		return err
	}
	return EmitRealtimeWakeup(c, t, wake.Envelope{Version: wake.EnvelopeVersion, Route: guildcore.ApplyNoticeRoute, Ref: ref})
}

func (GuildApplyNoticeEmitter) ApplicationResolvedTx(c context.Context, t tx.Tx, recipient identity.PlayerID) error {
	ref, err := guildcore.ApplicationResolvedNoticeRef(recipient)
	if err != nil {
		return err
	}
	return EmitRealtimeWakeup(c, t, wake.Envelope{Version: wake.EnvelopeVersion, Route: guildcore.ApplyNoticeRoute, Ref: ref})
}

var _ guildcore.ApplyNoticeEmitter = GuildApplyNoticeEmitter{}
