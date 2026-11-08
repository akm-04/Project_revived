package stockruntime

import (
	"context"
	"errors"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/broadcaststore"
	app "gxb.local/backend/v2/internal/application/broadcast"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

var ErrInvalidBroadcastPayload = errors.New("invalid broadcast payload")

// broadcastFields is the exact client-indexed field set per announce row. The
// client callback reads only these keys for its msg_type.
func broadcastFields(mid uint16, msgType int64) []string {
	switch {
	case mid == app.SystemMID && msgType == app.SXHero:
		return []string{"msg_type", "player_name", "partner_id"}
	case mid == app.SystemMID && msgType == app.ArenaWins:
		return []string{"msg_type", "player_name", "keep_win_times"}
	case mid == app.SystemMID && msgType == app.ArenaTop3:
		return []string{"msg_type", "player_name", "enemy_name", "rank"}
	case mid == app.SystemMID && msgType == app.Married:
		return []string{"msg_type", "player_name", "hero_table_id"}
	case mid == app.SystemMID && msgType == app.ConquerSchool:
		return []string{"msg_type", "player_name", "region", "conquer_loop_id", "conquer_lev"}
	case mid == app.SystemMID && msgType == app.TreasureDiamond:
		return []string{"msg_type", "player_name", "crystal_award"}
	case mid == app.SystemMID && (msgType == app.GetDormKey || msgType == app.GetDormKeyNew):
		return []string{"msg_type", "player_name", "key_item"}
	case mid == app.SystemMID && msgType == app.UnlockCG:
		return []string{"msg_type", "region", "player_name", "cg_id"}
	case mid == app.SystemMID && msgType == app.SuperPartner:
		return []string{"msg_type", "region", "player_name", "table_id"}
	case mid == app.ActivityMID && msgType == app.DormExpand:
		return []string{"msg_type", "region_id", "player_name"}
	default:
		return nil
	}
}

func broadcastNumber(value any) (int64, bool) {
	switch number := value.(type) {
	case int64:
		return number, true
	case int32:
		return int64(number), true
	case float64:
		return int64(number), number == float64(int64(number))
	default:
		return 0, false
	}
}

func validateBroadcastPayload(mid uint16, value any) error {
	object, ok := value.(*amf3.Object)
	if !ok || object == nil {
		return ErrInvalidBroadcastPayload
	}
	outer, err := object.StrictMap()
	if err != nil || len(outer) != 1 {
		return ErrInvalidBroadcastPayload
	}
	msg, ok := outer["msg"].(*amf3.Object)
	if !ok || msg == nil {
		return ErrInvalidBroadcastPayload
	}
	body, err := msg.StrictMap()
	if err != nil {
		return ErrInvalidBroadcastPayload
	}
	msgType, ok := broadcastNumber(body["msg_type"])
	if !ok {
		return ErrInvalidBroadcastPayload
	}
	required := broadcastFields(mid, msgType)
	if required == nil || len(body) != len(required) {
		return ErrInvalidBroadcastPayload
	}
	for _, key := range required {
		value, present := body[key]
		if !present {
			return ErrInvalidBroadcastPayload
		}
		if key == "player_name" || key == "enemy_name" {
			if _, ok := value.(string); !ok {
				return ErrInvalidBroadcastPayload
			}
			continue
		}
		if _, ok := broadcastNumber(value); !ok {
			return ErrInvalidBroadcastPayload
		}
	}
	return nil
}

func ValidateSystemBroadcast(value any) error {
	return validateBroadcastPayload(app.SystemMID, value)
}

func ValidateActivityBroadcast(value any) error {
	return validateBroadcastPayload(app.ActivityMID, value)
}

func NewBroadcastNoticeRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry([]rt.DirectRegistration{
		{MID: mids.MIDSystemBroadcast, Roles: []rt.Role{rt.World}, Validate: ValidateSystemBroadcast},
		{MID: mids.MIDActivityBroadcast, Roles: []rt.Role{rt.World}, Validate: ValidateActivityBroadcast},
	}, nil)
}

func broadcastProperty(name string, value any) amf3.Property {
	return amf3.Property{Name: name, Value: value}
}

// broadcastFrame shapes exactly the fields the stock client callback indexes.
// region is the source server number for 3010/3012 and 3011, and the Conquer
// region id for 3005.
func broadcastFrame(m app.Message, playerName, enemyName string) *amf3.Object {
	properties := []amf3.Property{broadcastProperty("msg_type", m.MsgType), broadcastProperty("player_name", playerName)}
	switch m.MsgType {
	case app.SXHero:
		properties = append(properties, broadcastProperty("partner_id", m.Fields.HeroTableID))
	case app.ArenaWins:
		properties = append(properties, broadcastProperty("keep_win_times", m.Fields.KeepWinTimes))
	case app.ArenaTop3:
		properties = append(properties, broadcastProperty("enemy_name", enemyName), broadcastProperty("rank", m.Fields.Rank))
	case app.Married:
		properties = append(properties, broadcastProperty("hero_table_id", m.Fields.HeroTableID))
	case app.ConquerSchool:
		properties = append(properties, broadcastProperty("region", m.Fields.Region), broadcastProperty("conquer_loop_id", m.Fields.ConquerLoopID), broadcastProperty("conquer_lev", m.Fields.ConquerLev))
	case app.TreasureDiamond:
		properties = append(properties, broadcastProperty("crystal_award", m.Fields.CrystalAward))
	case app.GetDormKey, app.GetDormKeyNew:
		properties = append(properties, broadcastProperty("key_item", m.Fields.KeyItem))
	case app.UnlockCG:
		properties = append(properties, broadcastProperty("region", int64(m.Server)), broadcastProperty("cg_id", m.Fields.CGID))
	case app.SuperPartner:
		properties = append(properties, broadcastProperty("region", int64(m.Server)), broadcastProperty("table_id", m.Fields.TableID))
	case app.DormExpand:
		properties = append(properties, broadcastProperty("region_id", int64(m.Server)))
	}
	return &amf3.Object{Properties: []amf3.Property{broadcastProperty("msg", &amf3.Object{Properties: properties})}}
}

type BroadcastNames interface {
	ReadNameSnapshotTx(context.Context, tx.Queryer, identity.PlayerID) (playerroot.NameSnapshot, error)
}

// BroadcastNoticeHandler is the broadcast.announce.v1 route: one queued
// announcement is removed and pushed to every live World session of its own
// logical server only.
type BroadcastNoticeHandler struct {
	DB              tx.Beginner
	Names           BroadcastNames
	Registry        *ConnectionRegistry
	Publisher       RealtimePublisher
	MaxHandles      int
	OnDeliveryError func(error)
}

func (h BroadcastNoticeHandler) ReloadAndDeliver(ctx context.Context, raw string) error {
	id, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || id <= 0 || strconv.FormatInt(id, 10) != raw {
		return errors.New("invalid broadcast reference")
	}
	if h.DB == nil || h.Names == nil || h.Registry == nil || h.MaxHandles < 1 {
		return errors.New("broadcast route unavailable")
	}
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	// shortcut: the row is taken before fanout and wakeups are not replayed, so a
	// crash or a listener outage loses that announcement; upgrade if lobby
	// announcements must survive a realtime restart.
	t, err := h.DB.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		return err
	}
	m, found, err := (broadcaststore.Store{}).TakeTx(ctx, t, id)
	if err != nil {
		t.Rollback(ctx)
		return err
	}
	if !found {
		t.Rollback(ctx)
		return nil
	}
	snapshot, err := h.Names.ReadNameSnapshotTx(ctx, t, m.Player)
	if err != nil {
		t.Rollback(ctx)
		return err
	}
	enemyName := ""
	if m.Enemy.Valid() {
		enemy, e := h.Names.ReadNameSnapshotTx(ctx, t, m.Enemy)
		if e != nil {
			t.Rollback(ctx)
			return e
		}
		enemyName = enemy.Name
	}
	if err = t.Commit(ctx); err != nil {
		return err
	}
	handles, within := h.Registry.ByRoomRoleBounded(int64(m.Server), domainrt.World, h.MaxHandles)
	if !within {
		return errors.New("broadcast fanout exceeds serving connection bound")
	}
	frame := broadcastFrame(m, snapshot.Name, enemyName)
	for _, handle := range handles {
		meta, ok := handle.Metadata()
		if !ok || !h.Registry.IsCurrent(handle) || meta.PhysicalRole != domainrt.World || meta.RoomID != int64(m.Server) {
			continue
		}
		if e := h.Publisher.PublishDirect(ctx, handle, m.MID, frame); e != nil && h.OnDeliveryError != nil {
			h.OnDeliveryError(e)
		}
	}
	return nil
}
