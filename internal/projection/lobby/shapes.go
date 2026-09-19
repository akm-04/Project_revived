package lobby

import (
	"fmt"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
)

// EmbeddedMID1Records is the frozen Pass409/MainScene hydration set. Order is
// retained for evidence/debugging; stock lookup is by decimal MID key.
var EmbeddedMID1Records = [...]uint16{
	17, 780, 49, 81, 112, 115, 2561, 229, 289, 336, 352, 384, 2485,
	1408, 368, 56, 624, 612, 822, 530, 1056, 1152, 1808, 1304, 1856,
	836, 2137, 2139, 2416, 2501, 2560, 2984, 3101,
}

type BootstrapView struct {
	Actor      identity.ActorContext
	PlayerName string
	RegionName string
	Now        time.Time
}

func (v BootstrapView) Validate() error {
	if !v.Actor.LogicalServerID.Valid() || !v.Actor.PlayerID.Valid() || !v.Actor.AccountUID.Valid() || v.Now.IsZero() {
		return fmt.Errorf("invalid lobby bootstrap view")
	}
	return nil
}

// BuildMID1Detail projects only source-consumed compatibility state. It owns no
// gameplay authority: unopened later domains are represented by source-shaped
// inactive/empty values rather than fabricated durable rows.
func BuildMID1Detail(v BootstrapView) (map[string]any, error) {
	if err := v.Validate(); err != nil {
		return nil, err
	}
	out := make(map[string]any, len(EmbeddedMID1Records))
	for _, mid := range EmbeddedMID1Records {
		p, ok := baseline(mid, v)
		if !ok {
			return nil, fmt.Errorf("missing frozen Wave-S baseline for MID %d", mid)
		}
		out[strconv.Itoa(int(mid))] = p
	}
	return out, nil
}

// Explicit returns the I4 read-only lobby facade for source-observed explicit
// startup requests. Mutation-bearing and deep-domain MIDs remain unimplemented.
func Explicit(mid uint16, v BootstrapView) (any, bool) {
	switch mid {
	case 56, 612, 780, 1056:
		p, ok := baseline(mid, v)
		return p, ok
	case 176:
		return friends(v), true
	case 1302:
		return map[string]any{"achieve_list": []any{}, "base_info": map[string]any{
			"point_level": int64(1), "total_points": int64(0), "rank": int64(0),
			"award_status": []any{int64(-1), int64(-1)},
		}}, true
	case 1344:
		return map[string]any{"paradise_info": map[string]any{"paradise_id": int64(1), "count": int64(0)}, "challenge_times": int64(0), "buy_times": int64(0), "hurt": int64(0), "rank": int64(0)}, true
	case 2754:
		return map[string]any{}, true // source callback ignores response fields
	case 2784:
		return map[string]any{"is_award": int64(0)}, true
	case 8193:
		return map[string]any{"has_read": int64(1), "contents": []any{}}, true
	default:
		return nil, false
	}
}

func baseline(mid uint16, v BootstrapView) (any, bool) {
	zeroList := func() []any { return []any{} }
	zeroMap := func() map[string]any { return map[string]any{} }
	switch mid {
	case 17:
		// Empty player_name is a stock lifecycle signal: the naming UI handles it.
		// Do not synthesize Player<id>; RegionWindow independently falls back to id.
		// This is structural bootstrap state only: I4 supplies every scalar/container
		// SelfPlayer consumes during hydration, with honest inactive/zero values.
		return map[string]any{
			"player_id": int64(v.Actor.PlayerID), "uid": string(v.Actor.AccountUID), "player_name": v.PlayerName,
			"player_type": int64(0), "avatar_id": logicalserver.BootstrapDirectoryAvatarID, "avatar_frame_id": int64(0),
			"lev": int64(1), "exp": int64(0), "boss_incr_exp": int64(0), "max_lev": int64(1), "max_color": int64(0),
			"region": int64(v.Actor.LogicalServerID), "region_name": v.RegionName,

			"mana": int64(0), "crystal": int64(0), "lucky_coin": int64(0), "arena_coin": int64(0),
			"march_coin": int64(0), "top_coin": int64(0), "guild_coin": int64(0), "region_coin": int64(0),
			"king_coin": int64(0), "honor_coin": int64(0), "god_war_coin": int64(0), "friendship_coin": int64(0),
			"friend_medal": int64(0), "summon_coin": int64(0), "skin_fragment": int64(0), "glue": int64(0),
			"buy_glue_times": int64(0), "lvbu_coin": int64(0), "paradise_coin": int64(0), "team_dungeon_coin": int64(0),
			"ice_core": int64(0), "spirit_stone": int64(0),

			"energy": int64(0), "spirit_energy": int64(0), "invitation": int64(0), "social": int64(0),
			"energy_time": int64(0), "spirit_energy_time": int64(0), "invitation_time": int64(0),
			"max_energy": int64(0), "max_invitation": int64(0), "glory": int64(0), "vip": int64(0),
			"buy_mana_times": int64(0), "buy_energy_times": int64(0), "buy_spirit_energy_times": int64(0), "buy_skill_times": int64(0),

			"func_ids": zeroList(), "skill_point": int64(0), "skill_time": int64(0), "formation": zeroMap(),
			"guide_function_ids": zeroList(), "guide_return_id": int64(0),
			"save_team": "", "save_team_name": "", "save_pet": "", "message_pushes": zeroMap(),

			"arena_beat_flag": int64(0), "month_card_start": int64(0), "month_card_end": int64(0),
			"privilege_left_card_day": int64(0), "privilege_month_card_end": int64(0),
			"left_card_day": int64(0), "left_week_card_day": int64(0), "left_month_tili_day": int64(0),
			"charge": int64(0), "is_commented": int64(1), "comment_open": int64(0), "fbshare_open": int64(0),
			"guild_id": int64(0), "main_scene_type": int64(0),

			"magic_energy": int64(0), "magic_dust": int64(0), "magic_liquid": int64(0), "magic_exp": int64(0),
			"degree_cer": int64(0), "graduate_cer": int64(0), "patent_cer": int64(0), "title_info": zeroMap(),
			"vip_awards": zeroList(), "conquer_lev": int64(0), "conquer_loop_id": int64(1), "conquer_region": int64(0),
			"first_main_touch": int64(0), "occult_ticket": int64(0), "tutor_coin": int64(0), "skin_coin": int64(0),
			"bubble_info": zeroMap(), "crab_times": int64(0),
			"story_id": int64(0), "story_state": int64(0), "guide_id": int64(0),
		}, true
	case 49:
		return map[string]any{"sort_type": int64(0), "heros": zeroMap()}, true
	case 56:
		return map[string]any{"mana_free_time": int64(0), "crystal_free_time": int64(0), "second_ids": zeroList(), "main_ids": zeroList(), "mana_id": int64(0), "pet_id": int64(0), "partner_id": int64(0), "mana_free_num": int64(0)}, true
	case 81:
		return map[string]any{"sort_type": int64(0), "list": zeroList(), "spirit_list": zeroList()}, true
	case 112:
		return map[string]any{"normal": zeroList(), "super": zeroList(), "challenge": zeroList(), "chapter_events": zeroMap(), "chapter_info": map[string]any{"normal_chapter_id": int64(0), "normal_campaign_id": int64(0), "super_chapter_id": int64(0), "super_campaign_id": int64(0), "normal_stars": int64(0), "normal_bonus_id": int64(0), "super_stars": int64(0), "super_bonus_id": int64(0)}}, true
	case 115:
		return map[string]any{"trial_info": map[string]any{"trials": zeroList(), "campaigns": zeroList()}, "challenge_info": map[string]any{"challenges": zeroList(), "campaigns": zeroList()}}, true
	case 229:
		return map[string]any{"list": zeroList()}, true
	case 289:
		return map[string]any{"records": zeroList()}, true
	case 336:
		return map[string]any{"map_info": map[string]any{"is_reborn": int64(0), "is_external_award": int64(0), "stage_done": int64(0), "passed_stage": int64(0)}, "hero_status": zeroMap(), "enemies": zeroList(), "rewards": zeroList()}, true
	case 352:
		return map[string]any{"awards": zeroList(), "is_signed": int64(1), "partner_id": int64(0), "sign_times": int64(0), "month": int64(1), "is_skin": int64(0)}, true
	case 368:
		return map[string]any{"mail_list": zeroList(), "total": int64(0), "new_mail_total": int64(0)}, true
	case 384:
		return map[string]any{"missions": zeroList(), "invite_players": zeroList(), "invite_code": "", "invitor_id": int64(0), "invitor_name": ""}, true
	case 612:
		// Absence is the stock inactive guild state; do not create fake Guild rows.
		return map[string]any{"guild_info": map[string]any{"guild_id": int64(0)}}, true
	case 624:
		return map[string]any{"total_hurt": int64(0), "total_rank": int64(0), "challenge_times": int64(0), "boss_info": map[string]any{"boss_brave": int64(0), "current_boss": int64(0), "boss_id": int64(0)}, "can_sweep": int64(0), "buy_times": int64(0)}, true
	case 780:
		return map[string]any{"pets": zeroList()}, true
	case 822:
		return map[string]any{"now_floor": int64(0), "max_floor": int64(0), "begin_sweep_time": int64(0), "is_can_sweep": int64(0), "mission_sweep_times": int64(0), "can_sweep_times": int64(0), "challenge_times": int64(0)}, true
	case 836:
		return map[string]any{"library_infos": zeroMap(), "library_talk_infos": zeroMap(), "library_cg_infos": zeroList(), "library_bg_infos": map[string]any{"bg_main": int64(1), "bg_room": int64(2), "has_buy": zeroList(), "server_time": v.Now.Unix()}}, true
	case 1056:
		buildings := map[string]any{}
		for i := 1; i <= 7; i++ {
			buildings[strconv.Itoa(i)] = map[string]any{"lev": int64(1), "need_time": int64(0), "start_time": int64(0), "new_evolve": int64(0)}
		}
		return map[string]any{"building_list": buildings, "desk_info": map[string]any{"is_making": int64(0), "make_need_time": int64(0), "make_start_time": int64(0), "make_item": int64(0)}, "pet_cabin_info": map[string]any{"is_making": int64(0), "make_need_time": int64(0), "make_start_time": int64(0), "make_item": int64(0), "pet_id": int64(0)}, "cabinet_info": map[string]any{"cur_learn_skill": int64(0), "need_time": int64(0), "start_time": int64(0), "recent_complete_skill": int64(0)}}, true
	case 1152:
		// Lua treats numeric 0 as truthy. Boolean false is the honest inactive
		// enrollment value and avoids the historical 0-as-false V1 trap.
		return map[string]any{"is_enroll": false}, true
	case 1304:
		// Current SelfPlayer hydration applies length (#) directly to this record;
		// the inactive source-safe shape is therefore an array, not V1's old map.
		return zeroList(), true
	case 1408:
		return map[string]any{"daily_fight": int64(0), "defence_formation": zeroMap(), "index": int64(0), "win_times": int64(0), "total_fight": int64(0), "keep_win_times": int64(0), "point": int64(0), "star": int64(0), "total": int64(0), "my_rank": int64(0), "count": int64(0), "day_count": int64(0), "missions": zeroList(), "mission_time": int64(0), "awards": zeroList(), "pet_id": int64(0), "exchange_times_1": int64(0), "exchange_times_2": int64(0), "exchange_times_3": int64(0)}, true
	case 1808:
		return map[string]any{"self_wish_info": zeroMap()}, true
	case 1856:
		return map[string]any{"apply_list": zeroList(), "mission_list": zeroList()}, true
	case 2137:
		return map[string]any{"study_infos": zeroList()}, true
	case 2139:
		return map[string]any{"is_has_gift": int64(0), "study_infos": zeroList()}, true
	case 2416:
		return map[string]any{"adventure_list": map[string]any{"list": zeroMap()}}, true
	case 2485:
		return map[string]any{"records": zeroList()}, true
	case 2501:
		// Current HeroRecommend stores the response itself as the keyed score map.
		return zeroMap(), true
	case 2560:
		return zeroMap(), true
	case 2561:
		return map[string]any{"mission_list": zeroList()}, true
	case 2984:
		return map[string]any{"base_info": map[string]any{"point": int64(0), "awarded_lev": int64(0), "adv_awarded_lev": int64(0), "limit_purchase_buy": int64(0), "is_advanced": int64(0), "coin_num": int64(0)}, "mission_info": map[string]any{"mission_list": zeroList(), "mission_counts": zeroList(), "is_award": zeroList()}}, true
	case 3101:
		return map[string]any{"base_info": zeroMap()}, true
	case 530:
		return map[string]any{"teams_info": zeroList(), "sp_info": map[string]any{"sp": int64(0), "sp_last_refresh_time": int64(0)}}, true
	default:
		return nil, false
	}
}

func friends(v BootstrapView) map[string]any {
	return map[string]any{"server_time": v.Now.Unix(), "blacklist": []any{}, "friend_list": []any{}, "notice_list": []any{}, "request_list": []any{}, "offline_msg_list": []any{}, "send_gift_count": int64(0), "receive_gift_count": int64(0)}
}
