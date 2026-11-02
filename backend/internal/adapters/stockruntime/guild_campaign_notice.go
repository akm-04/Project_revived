package stockruntime

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

// GuildCampaignNoticeRoute is the post-commit reference of C16.
const GuildCampaignNoticeRoute = "guild.campaign.fight.v1"

// GuildCampaignNoticeRef is the bounded reference the API emits after commit.
func GuildCampaignNoticeRef(guildID, chapterID, copyID int64, player identity.PlayerID) string {
	return fmt.Sprintf("%d:%d:%d:%d", guildID, chapterID, copyID, int64(player))
}

// GuildCampaignRegistered reads the fixed registration set of a chapter run.
type GuildCampaignRegistered interface {
	ListRegisteredTx(context.Context, tx.Queryer, int64, int64) ([]identity.PlayerID, error)
}

// GuildFightNoticeHandler delivers push 36853 to registered online members.
type GuildFightNoticeHandler struct {
	Registered GuildCampaignRegistered
	Queryer    tx.Queryer
	Registry   *ConnectionRegistry
	Publisher  RealtimePublisher
	MaxHandles int
}

func (h GuildFightNoticeHandler) ReloadAndDeliver(c context.Context, raw string) error {
	if h.Registered == nil || h.Queryer == nil || h.Registry == nil {
		return nil
	}
	guildID, chapterID, copyID, playerID, err := decodeGuildCampaignNoticeRef(raw)
	if err != nil {
		return nil
	}
	registered, err := h.Registered.ListRegisteredTx(c, h.Queryer, guildID, chapterID)
	if err != nil {
		return err
	}
	for _, member := range registered {
		handles := h.Registry.ByPlayerRole(member, domainrt.World)
		if len(handles) == 0 || len(handles) > h.MaxHandles {
			continue
		}
		for _, handle := range handles {
			metadata, valid := handle.Metadata()
			if !valid || !h.Registry.IsCurrent(handle) || metadata.PlayerID != member || metadata.PhysicalRole != domainrt.World {
				continue
			}
			frame := &amf3.Object{Properties: []amf3.Property{
				{Name: "copy_id", Value: copyID},
				{Name: "chapter_id", Value: chapterID},
				{Name: "player_id", Value: int64(playerID)},
			}}
			_ = h.Publisher.PublishDirect(c, handle, mids.MIDGuildFightNotice, frame)
		}
	}
	return nil
}

func decodeGuildCampaignNoticeRef(raw string) (int64, int64, int64, identity.PlayerID, error) {
	parts := strings.Split(raw, ":")
	if len(parts) != 4 {
		return 0, 0, 0, 0, rt.ErrInvalidS2CPayload
	}
	values := make([]int64, 4)
	for index, part := range parts {
		value, err := strconv.ParseInt(part, 10, 64)
		if err != nil || value <= 0 {
			return 0, 0, 0, 0, rt.ErrInvalidS2CPayload
		}
		values[index] = value
	}
	return values[0], values[1], values[2], identity.PlayerID(values[3]), nil
}
