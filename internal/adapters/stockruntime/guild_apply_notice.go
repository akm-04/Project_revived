package stockruntime

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

// GuildApplyNoticeType is the stock GUILD_BE_APPLYED red-dot notice
// (common/enums.lua:2063). The client reads no params and reloads MID 581.
const GuildApplyNoticeType int64 = 7

func ValidateGuildApplyNotice(value any) error {
	object, valid := value.(*amf3.Object)
	if !valid || object == nil {
		return rt.ErrInvalidS2CPayload
	}
	fields, err := object.StrictMap()
	if err != nil || len(fields) != 2 {
		return rt.ErrInvalidS2CPayload
	}
	noticeType, valid := fields["notice_type"].(int64)
	params, paramsValid := fields["params"].(*amf3.Object)
	if !valid || noticeType != GuildApplyNoticeType || !paramsValid || params == nil {
		return rt.ErrInvalidS2CPayload
	}
	body, err := params.StrictMap()
	if err != nil || len(body) != 0 {
		return rt.ErrInvalidS2CPayload
	}
	return nil
}

func NewGuildApplyNoticeRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry(nil, []rt.NoticeRegistration{{ParentMID: mids.MIDPlayerNotice, Namespace: rt.NoticeNamespaceGeneric, NoticeType: GuildApplyNoticeType, Roles: []rt.Role{rt.World}, Validate: ValidateGuildApplyNotice}})
}

func guildApplyNoticeFrame() *amf3.Object {
	return &amf3.Object{Properties: []amf3.Property{{Name: "notice_type", Value: GuildApplyNoticeType}, {Name: "params", Value: &amf3.Object{}}}}
}

type GuildApplyNoticeMembers interface {
	ListMemberships(context.Context, guild.ID) ([]guild.Membership, error)
}

// GuildApplyNoticeHandler pushes notice 7 to the online officers of a guild, or
// to the online officer whose accept/refuse just committed.
type GuildApplyNoticeHandler struct {
	Members  GuildApplyNoticeMembers
	Delivery RoomDelivery
}

func (h GuildApplyNoticeHandler) ReloadAndDeliver(c context.Context, raw string) error {
	if h.Members == nil || h.Delivery.Registry == nil || h.Delivery.Authority == nil || h.Delivery.Time == nil || h.Delivery.MaxHandles < 1 {
		return errors.New("guild apply notice unavailable")
	}
	ref, err := guildcore.DecodeApplyNoticeRef(raw)
	if err != nil {
		return err
	}
	frame := guildApplyNoticeFrame()
	if ref.Resolved {
		return h.Delivery.Deliver(c, ref.Recipient, mids.MIDPlayerNotice, frame)
	}
	members, err := h.Members.ListMemberships(c, ref.GuildID)
	if err != nil {
		return err
	}
	for _, member := range members {
		if member.Role != guild.Leader && member.Role != guild.Deputy {
			continue
		}
		if err := h.Delivery.Deliver(c, member.PlayerID, mids.MIDPlayerNotice, frame); err != nil {
			return err
		}
	}
	return nil
}
