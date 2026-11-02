# v1 to v2 import map

Every top-level field and every second-level field under `player` in the three preserved v1 saves, with its v2 home or the reason it is not imported. `_meta` is the save file envelope, included for completeness. Source of truth: `test_harness/preserve/server_state/players/<id>/player.json`; v2 tables: the active backend at test_harness/backend.

This file is generated from the save shape and the importer's own reason table (`import_legacy.NOT_IMPORTED_REASONS`); edit the importer when a mapping changes.

| v1 path | v2 home |
|---|---|
| `player` | container (the v2 player is born by MID18/MID1, never inserted) |
| `player.domains` | container |
| `player.domains.adventure_list` | NOT IMPORTED: v2 adventure owner has a different shape |
| `player.domains.arena_info` | NOT IMPORTED: v2 arena owner has a different shape |
| `player.domains.arena_mode_info` | NOT IMPORTED: v2 arena owner has a different shape |
| `player.domains.arena_records` | NOT IMPORTED: v2 arena owner has a different shape |
| `player.domains.auction_by_type` | NOT IMPORTED: no v2 auction owner |
| `player.domains.awakening_state` | NOT IMPORTED: raw awakening stage is imported per hero; v1 mission slots have no v2 owner shape |
| `player.domains.battle_formation` | NOT IMPORTED: no v2 battle-formation owner |
| `player.domains.battle_pass_info` | NOT IMPORTED: no v2 battle-pass owner |
| `player.domains.building_list` | NOT IMPORTED: v1 town buildings do not map to the v2 book or workplace owners |
| `player.domains.class_info` | NOT IMPORTED: no v2 owner |
| `player.domains.commerce_state` | NOT IMPORTED: qualifying charge is imported; product counters have no v2 owner |
| `player.domains.daily_consume_state` | NOT IMPORTED: v2 daily consumption is event-driven; v1 counts are empty |
| `player.domains.daily_reset_state` | NOT IMPORTED: v2 recomputes the game day on read |
| `player.domains.gift_box_info` | NOT IMPORTED: no v2 owner |
| `player.domains.hero_recommend_scores` | NOT IMPORTED: no v2 owner |
| `player.domains.horcrux_state` | player_spirit_roots.facts.programs (collocations); instances come from inventory.spirit_list |
| `player.domains.hunqi_start_info` | NOT IMPORTED: no v2 owner |
| `player.domains.invite_infos` | NOT IMPORTED: social owner has a different shape |
| `player.domains.march_info` | NOT IMPORTED: v2 march owner payload has a different shape |
| `player.domains.occult_state` | NOT IMPORTED: v2 occult owner payload has a different shape |
| `player.domains.offline_info` | NOT IMPORTED: no v2 owner |
| `player.domains.peak_records` | NOT IMPORTED: v2 peak arena owner has a different shape |
| `player.domains.persistence_state` | NOT IMPORTED: v1 persistence receipts/migrations; not imported |
| `player.domains.practice_info` | NOT IMPORTED: practice owner has its own shape; v1 blob is empty |
| `player.domains.study_infos` | NOT IMPORTED: no v2 owner |
| `player.domains.tea_talk_info` | NOT IMPORTED: guild tea owner has a different shape |
| `player.domains.trial_infos` | NOT IMPORTED: v2 trial owner has a different shape |
| `player.domains.white_album_state` | NOT IMPORTED: v2 library special claims are already seeded; v1 blob is empty |
| `player.domains.workshop_state` | NOT IMPORTED: v1 book/cabinet facts do not map to the v2 workplace owner |
| `player.domains.world_boss` | NOT IMPORTED: world-boss owner has a different shape |
| `player.economy` | container |
| `player.economy.arena_coin` | player_currency_balances(resource_key='arena_coin').amount |
| `player.economy.buy_energy_times` | NOT IMPORTED: purchase counters have no v2 owner |
| `player.economy.buy_glue_times` | NOT IMPORTED: purchase counters have no v2 owner |
| `player.economy.buy_mana_times` | NOT IMPORTED: purchase counters have no v2 owner |
| `player.economy.buy_skill_times` | NOT IMPORTED: purchase counters have no v2 owner |
| `player.economy.buy_spirit_energy_times` | NOT IMPORTED: purchase counters have no v2 owner |
| `player.economy.charge` | commerce_privilege_roots.qualifying_charge |
| `player.economy.crystal` | player_currency_balances(resource_key='crystal').amount |
| `player.economy.energy` | player_temporal_resources(resource_key='energy').stored_amount |
| `player.economy.energy_time` | NOT IMPORTED: regen anchor is reset to the import time |
| `player.economy.friend_medal` | player_currency_balances(resource_key='friend_medal').amount |
| `player.economy.friendship_coin` | player_currency_balances(resource_key='friendship_coin').amount |
| `player.economy.glory` | player_currency_balances(resource_key='glory').amount |
| `player.economy.glue` | player_currency_balances(resource_key='glue').amount |
| `player.economy.god_war_coin` | player_currency_balances(resource_key='god_war_coin').amount |
| `player.economy.guild_coin` | player_currency_balances(resource_key='guild_coin').amount |
| `player.economy.honor_coin` | player_currency_balances(resource_key='honor_coin').amount |
| `player.economy.ice_core` | player_currency_balances(resource_key='ice_core').amount |
| `player.economy.invitation` | NOT IMPORTED: catalog status PARTIAL / FAIL_CLOSED; no active v2 owner |
| `player.economy.invitation_time` | NOT IMPORTED: catalog status PARTIAL / FAIL_CLOSED; no active v2 owner |
| `player.economy.king_coin` | player_currency_balances(resource_key='king_coin').amount |
| `player.economy.left_card_day` | NOT IMPORTED: card state has no v2 owner |
| `player.economy.left_month_tili_day` | NOT IMPORTED: card state has no v2 owner |
| `player.economy.left_week_card_day` | NOT IMPORTED: card state has no v2 owner |
| `player.economy.lucky_coin` | player_currency_balances(resource_key='lucky_coin').amount |
| `player.economy.lvbu_coin` | player_currency_balances(resource_key='lvbu_coin').amount |
| `player.economy.magic_dust` | player_currency_balances(resource_key='magic_dust').amount |
| `player.economy.magic_energy` | player_currency_balances(resource_key='magic_energy').amount |
| `player.economy.magic_exp` | player_currency_balances(resource_key='magic_exp').amount |
| `player.economy.magic_liquid` | player_currency_balances(resource_key='magic_liquid').amount |
| `player.economy.mana` | player_currency_balances(resource_key='mana').amount |
| `player.economy.march_coin` | player_currency_balances(resource_key='march_coin').amount |
| `player.economy.max_energy` | NOT IMPORTED: v2 derives the energy cap from level and content |
| `player.economy.max_invitation` | NOT IMPORTED: catalog status PARTIAL / FAIL_CLOSED; no active v2 owner |
| `player.economy.month_card_end` | NOT IMPORTED: card state has no v2 owner |
| `player.economy.month_card_start` | NOT IMPORTED: card state has no v2 owner |
| `player.economy.occult_ticket` | player_currency_balances(resource_key='occult_ticket').amount |
| `player.economy.paradise_coin` | player_currency_balances(resource_key='paradise_coin').amount |
| `player.economy.privilege_left_card_day` | NOT IMPORTED: card state has no v2 owner |
| `player.economy.privilege_month_card_end` | NOT IMPORTED: card state has no v2 owner |
| `player.economy.region_coin` | player_currency_balances(resource_key='region_coin').amount |
| `player.economy.skill_time` | NOT IMPORTED: regen anchor is reset to the import time |
| `player.economy.skin_coin` | player_currency_balances(resource_key='skin_coin').amount |
| `player.economy.skin_fragment` | player_currency_balances(resource_key='skin_fragment').amount |
| `player.economy.social` | player_currency_balances(resource_key='social').amount |
| `player.economy.spirit_energy` | player_temporal_resources(resource_key='spirit_energy').stored_amount |
| `player.economy.spirit_energy_time` | NOT IMPORTED: regen anchor is reset to the import time |
| `player.economy.spirit_stone` | player_currency_balances(resource_key='spirit_stone').amount |
| `player.economy.summon_coin` | player_currency_balances(resource_key='summon_coin').amount |
| `player.economy.team_dungeon_coin` | player_currency_balances(resource_key='team_dungeon_coin').amount |
| `player.economy.top_coin` | player_currency_balances(resource_key='top_coin').amount |
| `player.economy.tutor_coin` | player_currency_balances(resource_key='tutor_coin').amount |
| `player.heroes` | container |
| `player.heroes.collected_heros` | player_heroes for owned tables; collected-but-unowned ids are reported in content_refused |
| `player.heroes.formation` | NOT IMPORTED: no v2 representative-hero owner |
| `player.heroes.hero_next_partner_id` | player_hero_roots.next_partner_id |
| `player.heroes.hero_pieces` | NOT IMPORTED: no v2 hero-piece owner |
| `player.heroes.hero_sort_type` | player_hero_roots.sort_type |
| `player.heroes.heroes` | player_heroes plus every per-hero owner row (library, dorm, course, inscription, element, spirit, evolution, raw awakening, skins) |
| `player.heroes.save_pet` | NOT IMPORTED: v1 saved-team payload; no v2 owner-shaped conversion |
| `player.heroes.save_team` | NOT IMPORTED: v1 saved-team payload; no v2 owner-shaped conversion |
| `player.heroes.save_team_name` | NOT IMPORTED: v1 saved-team payload; no v2 owner-shaped conversion |
| `player.identity` | container |
| `player.identity.account_uid` | NOT IMPORTED: v2 links players by the harness account and session, not the v1 uid |
| `player.identity.avatar_frame_id` | player_profiles.avatar_frame_id, player_directory_profiles.avatar_frame_id |
| `player.identity.avatar_id` | player_profiles.avatar_id, player_directory_profiles.avatar_id |
| `player.identity.guild_id` | NOT IMPORTED: guild membership has its own owner; v1 value is zero |
| `player.identity.player_id` | NOT IMPORTED: v2 allocates the player id inside the logical server |
| `player.identity.player_name` | player_profiles.display_name, player_directory_profiles.name |
| `player.identity.player_type` | player_profiles.player_type |
| `player.identity.region` | NOT IMPORTED: v2 uses logical server 1; the v1 region 194/197 has no v2 server |
| `player.identity.region_name` | NOT IMPORTED: v2 derives the logical-server name |
| `player.identity.token` | NOT IMPORTED: v1 local token; v2 issues its own gameplay bearer |
| `player.inventory` | container |
| `player.inventory.backpack_items` | player_item_stacks(item_id,quantity) |
| `player.inventory.essences` | NOT IMPORTED: no active v2 essence owner |
| `player.inventory.runes` | NOT IMPORTED: no active v2 rune owner |
| `player.inventory.scrolls` | NOT IMPORTED: no active v2 scroll owner |
| `player.inventory.spirit_list` | player_spirit_roots.facts.instances |
| `player.library` | NOT IMPORTED: UNKNOWN: no v2 owner placed for this field |
| `player.library.bg_has_buy` | NOT IMPORTED: no v2 library background owner |
| `player.library.bg_main` | NOT IMPORTED: no v2 library background owner |
| `player.library.bg_room` | NOT IMPORTED: no v2 library background owner |
| `player.library.library_cg_infos` | NOT IMPORTED: no v2 library CG owner |
| `player.library.library_infos` | NOT IMPORTED: v2 derives favor/marriage from player_library_heroes |
| `player.library.library_talk_infos` | NOT IMPORTED: no v2 library talk owner |
| `player.lobby` | container |
| `player.lobby.activities` | NOT IMPORTED: no v2 activity owner for the v1 blob |
| `player.lobby.board_contents` | NOT IMPORTED: no v2 board-content owner |
| `player.lobby.bubble_info` | NOT IMPORTED: v2 projects bubbles from player_display_selections |
| `player.lobby.comment_open` | NOT IMPORTED: no v2 owner |
| `player.lobby.fbshare_open` | NOT IMPORTED: no v2 owner |
| `player.lobby.friends` | NOT IMPORTED: social owner exists but has no v1 friend import shape |
| `player.lobby.illusion` | NOT IMPORTED: illusion owner exists but the v1 blob has no convertible run |
| `player.lobby.is_commented` | NOT IMPORTED: no v2 owner |
| `player.lobby.mails` | NOT IMPORTED: v2 mail owner has its own receipt-backed shape |
| `player.lobby.message_pushes` | NOT IMPORTED: no v2 owner |
| `player.lobby.mission_state` | NOT IMPORTED: v2 mission programs use different ids; v1 story mission 80001 has no owner program |
| `player.lobby.missions` | NOT IMPORTED: v2 mission programs use different ids |
| `player.lobby.pets` | NOT IMPORTED: empty in all three saves; player_pet_roots is seeded at birth |
| `player.lobby.redmarks` | NOT IMPORTED: client UI state; no v2 owner |
| `player.lobby.shop_statuses` | NOT IMPORTED: no v2 shop owner for the v1 blob |
| `player.lobby.shops` | NOT IMPORTED: no v2 shop owner for the v1 blob |
| `player.lobby.summon` | summon_players |
| `player.lobby.title_info` | NOT IMPORTED: v2 projects titles from player_display_selections |
| `player.lobby.vip_awards` | NOT IMPORTED: no v2 VIP-award owner |
| `player.progression` | container |
| `player.progression.arena_beat_flag` | NOT IMPORTED: no v2 arena-beat owner |
| `player.progression.boss_incr_exp` | NOT IMPORTED: no v2 owner |
| `player.progression.conquer_lev` | player_directory_profiles.conquer_lev |
| `player.progression.conquer_loop_id` | player_directory_profiles.conquer_loop_id |
| `player.progression.conquer_region` | NOT IMPORTED: no v2 owner |
| `player.progression.crab_times` | NOT IMPORTED: no v2 owner |
| `player.progression.degree_cer` | player_currency_balances(resource_key='degree_cer').amount |
| `player.progression.exp` | player_progression.exp |
| `player.progression.first_main_touch` | NOT IMPORTED: client UI flag; no v2 owner |
| `player.progression.func_ids` | player_function_unlocks, player_function_eligibility |
| `player.progression.function_state` | NOT IMPORTED: v2 derives eligibility; announced/pending have no owner |
| `player.progression.graduate_cer` | player_currency_balances(resource_key='graduate_cer').amount |
| `player.progression.guide_function_ids` | player_guide_return_state.guide_function_ids |
| `player.progression.guide_id` | player_story_cursors.guide_id |
| `player.progression.guide_return_id` | player_guide_return_state.guide_return_id |
| `player.progression.lev` | player_progression.level, player_directory_profiles.lev |
| `player.progression.main_scene_type` | NOT IMPORTED: client UI state; no v2 owner |
| `player.progression.max_color` | NOT IMPORTED: v2 derives max color from content |
| `player.progression.max_lev` | NOT IMPORTED: v2 derives max level from content |
| `player.progression.patent_cer` | player_currency_balances(resource_key='patent_cer').amount |
| `player.progression.skill_point` | player_temporal_resources(resource_key='skill_point').stored_amount |
| `player.progression.story_id` | player_story_cursors.story_id |
| `player.progression.story_state` | player_story_cursors.story_state |
| `player.progression.tutorial_state` | NOT IMPORTED: no v2 tutorial milestone owner; first-entry flag is cleared instead |
| `player.progression.vip` | commerce_privilege_roots.vip_level, player_directory_profiles.vip |
| `player.world` | container |
| `player.world.active_campaign_battle` | NOT IMPORTED: in-flight v1 battle; not imported |
| `player.world.world_map` | campaign_nodes, campaign_players |

## Per-hero fields

`player.heroes.heroes` is a partner-id map; these are its fields, beyond the second-level table above.

| v1 hero field | v2 home |
|---|---|
| `partner_id` | player_heroes.partner_id |
| `table_id` | player_heroes.table_id |
| `star` | player_heroes.star |
| `lev` | player_heroes.level |
| `exp` | player_heroes.exp |
| `color` | player_heroes.color |
| `skills` | player_heroes.raw_skill_1..6 |
| `skill_ids` | player_heroes.raw_skill_id_1..6 |
| `equips` | player_heroes.equip_1..6 (Normal: collected bit 0/1; Super: enhancement+1) |
| `fumos` | player_heroes.fumo_1..6 |
| `practice_attr` | player_heroes.practice_str/practice_int/practice_agi |
| `is_like` | player_heroes.is_like |
| `current_skin_id` | player_heroes.current_skin_id |
| `illusion_skin_id` | player_heroes.illusion_skin_id (0 becomes -1) |
| `skin_ids` | player_hero_skin_entitlements(model_id, expires_at NULL) |
| `feed_attrs` | player_library_heroes.feed_attrs |
| `favor_degree` | player_library_heroes.favor_degree |
| `is_married` | player_library_heroes.is_married |
| `collect_quality_stage` | player_library_heroes.collect_quality_stage |
| `collect_star_stage` | player_library_heroes.collect_star_stage |
| `evo_stage` | player_hero_evolution.facts.evo_stage |
| `evo_attr_points` | player_hero_evolution.facts.evo_attr_points |
| `twice_awake_stage` | player_hero_raw_awakening.raw_stage |
| `element_equips` | player_element_heroes.facts.slots |
| `element_levels` | player_element_heroes.facts.levels |
| `element_bak_equips` | player_element_heroes.facts.backup (keys) |
| `element_bak_levels` | player_element_heroes.facts.backup (values) |
| `spirit_equip` | player_spirit_heroes.facts.slots |
| `inscript_items` | player_inscription_heroes.facts.Slots |
| `courses` | player_course_heroes.facts.courses.id |
| `courses_progress` | player_course_heroes.facts.courses.progress |
| `courses_skill` | player_course_heroes.facts.courses.add_skill |
| `courses_quality` | player_course_heroes.facts.courses.quality |
| `courses_exp` | player_course_heroes.facts.courses.exp |
| `player_id` | NOT IMPORTED: v2 allocates the player id |
| `board_card` | NOT IMPORTED: no v2 board owner |
| `board_model_id` | NOT IMPORTED: no v2 board owner |
| `book_shelf_lev` | NOT IMPORTED: v2 book owner has no per-hero shelf level |
| `buffs` | NOT IMPORTED: no v2 per-hero buff owner |
| `conquer_lev` | NOT IMPORTED: v2 conquest belongs to player_conquer_facts, not a hero |
| `conquer_loop_id` | NOT IMPORTED: v2 conquest belongs to player_conquer_facts, not a hero |
| `dynamic_card_state` | NOT IMPORTED: v2 projects LIVE card models from entitlements; v1 string has no owner |
| `force` | NOT IMPORTED: v2 computes force from owned state |
| `fumo_levels` | NOT IMPORTED: v2 derives fumo levels from raw fumo and content |
| `house_comfort` | NOT IMPORTED: v2 dorm comfort is derived from room furniture |
| `house_equips` | NOT IMPORTED: v2 dorm room ownership has a different shape |
| `house_expand_lev` | NOT IMPORTED: v2 dorm room ownership has a different shape |
| `house_id` | NOT IMPORTED: v2 dorm room ownership has a different shape; dorm facet is seeded |
| `house_table_id` | NOT IMPORTED: v2 dorm room ownership has a different shape; dorm facet is seeded |
| `is_board` | NOT IMPORTED: no v2 board owner |
| `player_id` | NOT IMPORTED: v2 allocates the player id |
| `region_arena_times` | NOT IMPORTED: no v2 owner |
| `skill_book_info` | NOT IMPORTED: v2 book owner has no per-hero skill fact |
| `spirit_item` | NOT IMPORTED: v2 derives spirit item wires from imported spirit instances |
| `unlocked_dynamic_card` | NOT IMPORTED: v2 projects LIVE card models from entitlements; v1 string has no owner |
