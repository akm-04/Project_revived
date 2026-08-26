local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("HeroTable")
local var_0_3 = {
	"click_dialog1",
	"click_dialog2",
	"click_dialog3",
	"click_dialog4",
	"click_dialog5",
	"chosen_dialog",
	"dialog",
	"dead_dialog",
	"skill_dialog"
}
local var_0_4 = {
	"click_sound1",
	"click_sound2",
	"click_sound3",
	"click_sound4",
	"click_sound5",
	"chosen_sound",
	"dialog_sound",
	"dead_sound",
	"sound_skill"
}

function var_0_2.ctor(arg_1_0)
	arg_1_0.heros_ = {}
	arg_1_0.heroIDs = {}
	arg_1_0.originHeroIds = {}
	arg_1_0.monsters_ = {}
	arg_1_0.unparsedMonsters_ = {}
	arg_1_0.pets_ = {}
	arg_1_0.stoneID_ = {}
	arg_1_0.partnerDisType_ = {}
	arg_1_0.petIds_ = {}
	arg_1_0.id_to_egg_ = {}
	arg_1_0.treasure_locations_ = {}
	arg_1_0.activityHeros_ = {}
	arg_1_0.checkTable_ = {}
	arg_1_0.superHeros_ = {}
	arg_1_0.superHeroIDs = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("partner.lua", var_0_0.handler(arg_1_0, arg_1_0.parsePartner))
		var_0_0.import("app.common.tables.TableParser").parse("pet.lua", var_0_0.handler(arg_1_0, arg_1_0.parsePet))
		var_0_0.import("app.common.tables.TableParser").parse("activity_partner.lua", var_0_0.handler(arg_1_0, arg_1_0.parseActivityPartner))
		var_0_0.import("app.common.tables.TableParser").parse("monster.lua", var_0_0.handler(arg_1_0, arg_1_0.saveMonster))
		var_0_0.import("app.common.tables.TableParser").parse("super_partner.lua", var_0_0.handler(arg_1_0, arg_1_0.parseSuperPartner))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("partner", var_0_0.handler(arg_1_0, arg_1_0.parsePartner))
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("pet", var_0_0.handler(arg_1_0, arg_1_0.parsePet))
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("activity_partner", var_0_0.handler(arg_1_0, arg_1_0.parseActivityPartner))
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("monster", var_0_0.handler(arg_1_0, arg_1_0.serverParseMonster))
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("super_partner.lua", var_0_0.handler(arg_1_0, arg_1_0.parseSuperPartner))
	end
end

function var_0_2.Parsecommon(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	local var_2_0 = tonumber(arg_2_1[1])

	if arg_2_0:isDuplicatedID(var_2_0) then
		error(var_2_0 .. " duplicated")
	end

	local var_2_1 = {
		name = arg_2_1[arg_2_2.name],
		des1 = arg_2_1[arg_2_2.des1],
		des2 = arg_2_1[arg_2_2.des2],
		type = tonumber(arg_2_1[arg_2_2.type]),
		gender = tonumber(arg_2_1[arg_2_2.gender]),
		modelid = tonumber(arg_2_1[arg_2_2.modelid]),
		modelids = var_0_1.splitToNumber(arg_2_1[arg_2_2.modelids], "|"),
		ini_star = tonumber(arg_2_1[arg_2_2.ini_star]),
		distance = tonumber(arg_2_1[arg_2_2.distance]),
		distance_type = tonumber(arg_2_1[arg_2_2.distance_type]),
		interval = tonumber(arg_2_1[arg_2_2.interval]),
		speed = tonumber(arg_2_1[arg_2_2.speed]),
		buff_skill = var_0_1.splitToNumber(arg_2_1[arg_2_2.buff_skill], "|"),
		delay_skill = tonumber(arg_2_1[arg_2_2.delay_skill]),
		enter_skill = tonumber(arg_2_1[arg_2_2.enter_skill]),
		class_name = arg_2_1[arg_2_2.class_name],
		first_table_id = tonumber(arg_2_1[arg_2_2.first_table_id]),
		awaken_table_id = tonumber(arg_2_1[arg_2_2.awaken_table_id]),
		awanken_item = tonumber(arg_2_1[arg_2_2.awanken_item]),
		awaken = tonumber(arg_2_1[arg_2_2.awaken]),
		pugong = tonumber(arg_2_1[arg_2_2.skill0]),
		circle = var_0_1.splitToNumber(arg_2_1[arg_2_2.circle], "|"),
		start_circle = var_0_1.splitToNumber(arg_2_1[arg_2_2.start_circle], "|"),
		attributes = arg_2_0:parseAttributes(arg_2_1, arg_2_2),
		attr_grow = arg_2_0:parseAttrGrows(arg_2_1, arg_2_2),
		skills = arg_2_0:parseSkills(arg_2_1, arg_2_2),
		skill0 = arg_2_0:getSkillID(arg_2_1, arg_2_2, 0),
		skill1 = arg_2_0:getSkillID(arg_2_1, arg_2_2, 1),
		skill2 = arg_2_0:getSkillID(arg_2_1, arg_2_2, 2),
		skill3 = arg_2_0:getSkillID(arg_2_1, arg_2_2, 3),
		skill4 = arg_2_0:getSkillID(arg_2_1, arg_2_2, 4),
		skill5 = arg_2_0:getSkillID(arg_2_1, arg_2_2, 5),
		skill6 = arg_2_0:getSkillID(arg_2_1, arg_2_2, 6),
		attr_rates = arg_2_0:parseAttrRates(arg_2_1, arg_2_2),
		die_skill = tonumber(arg_2_1[arg_2_2.die_skill])
	}

	if not arg_2_0.checkTable_[var_2_0] then
		arg_2_0.checkTable_[var_2_0] = {}
	end

	arg_2_0.checkTable_[var_2_0].interval = var_2_1.interval
	arg_2_0.checkTable_[var_2_0].attrs = var_2_1.attributes
	arg_2_0.checkTable_[var_2_0].attr_grow = var_2_1.attr_grow

	if not arg_2_3 then
		var_2_1.equip_list = arg_2_0:parseEquipList(arg_2_1, arg_2_2)
		arg_2_0.checkTable_[var_2_0].equips = var_2_1.equip_list
	end

	return var_2_1
end

function var_0_2.parsePartner(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = tonumber(arg_3_1[1])

	if arg_3_0:getRowTable(var_3_0) then
		error(var_3_0 .. " duplicated")
	end

	local var_3_1 = arg_3_0:Parsecommon(arg_3_1, arg_3_2)

	var_3_1.des3 = arg_3_1[arg_3_2.des3]
	var_3_1.stone_id = tonumber(arg_3_1[arg_3_2.stone_id])
	var_3_1.skin_item = var_0_1.splitToNumber(arg_3_1[arg_3_2.skin_item], "|")
	var_3_1.is_show = tonumber(arg_3_1[arg_3_2.is_show])
	var_3_1.is_sx = tonumber(arg_3_1[arg_3_2.is_sx])
	var_3_1.librart_show = tonumber(arg_3_1[arg_3_2.librart_show])
	var_3_1.exchange_show = tonumber(arg_3_1[arg_3_2.exchange_show])
	var_3_1.is_open_dialog = tonumber(arg_3_1[arg_3_2.is_open_dialog])
	var_3_1.from = tonumber(arg_3_1[arg_3_2.from])
	var_3_1.stone_campaign = var_0_1.splitToNumber(arg_3_1[arg_3_2.stone_campaign], "|")
	var_3_1.chosen_sound = arg_3_1[arg_3_2.chosen_sound]
	var_3_1.dialog_sound = arg_3_1[arg_3_2.dialog_sound]
	var_3_1.dialog = arg_3_1[arg_3_2.dialog]
	var_3_1.x = tonumber(arg_3_1[arg_3_2.x])
	var_3_1.y = tonumber(arg_3_1[arg_3_2.y])
	var_3_1.awaken = tonumber(arg_3_1[arg_3_2.awaken])
	var_3_1.bloodline_item = tonumber(arg_3_1[arg_3_2.bloodline_item])
	var_3_1.bloodline = tonumber(arg_3_1[arg_3_2.bloodline])
	var_3_1.dorm_item = var_0_1.splitToNumber(arg_3_1[arg_3_2.dorm_item], "|")
	var_3_1.can_guild_request = tonumber(arg_3_1[arg_3_2.can_guild_request])
	var_3_1.gift_like_type = tonumber(arg_3_1[arg_3_2.gift_like_type])
	var_3_1.gift_dislike_type = tonumber(arg_3_1[arg_3_2.gift_dislike_type])
	var_3_1.treasure_desc = arg_3_1[arg_3_2.treasure_desc]
	var_3_1.treasure_location = tonumber(arg_3_1[arg_3_2.treasure_location])
	var_3_1.treasure_skill = tonumber(arg_3_1[arg_3_2.treasure_skill])
	var_3_1.init_power = tonumber(arg_3_1[arg_3_2.init_power])
	var_3_1.search_name = var_0_1.split(arg_3_1[arg_3_2.search_name], "|")
	var_3_1.skin_hide = var_0_1.splitToNumber(arg_3_1[arg_3_2.skin_hide], "|")
	var_3_1.stone_ticket = tonumber(arg_3_1[arg_3_2.stone_ticket])
	var_3_1.cv = arg_3_1[arg_3_2.cv]
	var_3_1.guild_request_cross_service = tonumber(arg_3_1[arg_3_2.guild_request_cross_service])
	var_3_1.sound_times = {}
	var_3_1.sound_dialogs = {}
	var_3_1.sound_files = {}

	for iter_3_0 = 1, 9 do
		var_3_1.sound_times[iter_3_0] = tonumber(arg_3_1[arg_3_2["time_sound" .. iter_3_0]])
		var_3_1.sound_dialogs[iter_3_0] = arg_3_1[arg_3_2[var_0_3[iter_3_0]]]
		var_3_1.sound_files[iter_3_0] = arg_3_1[arg_3_2[var_0_4[iter_3_0]]]
	end

	if var_3_1.treasure_location ~= 0 and tonumber(arg_3_1[arg_3_2.first_table_id]) == 0 then
		local var_3_2 = var_3_1.treasure_location

		if not arg_3_0.treasure_locations_[var_3_2] then
			arg_3_0.treasure_locations_[var_3_2] = {}
		end

		table.insert(arg_3_0.treasure_locations_[var_3_2], var_3_0)
	end

	var_3_1.practice_needs = {
		tonumber(arg_3_1[arg_3_2.practice_liliang_need]),
		tonumber(arg_3_1[arg_3_2.practice_zhili_need]),
		tonumber(arg_3_1[arg_3_2.practice_minjie_need])
	}
	var_3_1.practice_types = {
		tonumber(arg_3_1[arg_3_2.practice_liliang_type]),
		tonumber(arg_3_1[arg_3_2.practice_zhili_type]),
		tonumber(arg_3_1[arg_3_2.practice_minjie_type])
	}
	var_3_1.practice_values = {
		tonumber(arg_3_1[arg_3_2.practice_liliang_value]),
		tonumber(arg_3_1[arg_3_2.practice_zhili_value]),
		tonumber(arg_3_1[arg_3_2.practice_minjie_value])
	}

	if not arg_3_0.checkTable_[var_3_0] then
		arg_3_0.checkTable_[var_3_0] = {}
	end

	arg_3_0.checkTable_[var_3_0].practice = var_3_1.practice_values

	if isClient then
		local var_3_3 = {}

		for iter_3_1 = 1, var_0_1.HERO_TOTAL_STARS do
			local var_3_4 = {
				[var_0_1.HeroType.WISE] = crypto.md5(arg_3_1[arg_3_2["zhili_star" .. iter_3_1]] .. var_0_1.TableCryptoKey),
				[var_0_1.HeroType.STRENGTH] = crypto.md5(arg_3_1[arg_3_2["liliang_star" .. iter_3_1]] .. var_0_1.TableCryptoKey),
				[var_0_1.HeroType.AGILE] = crypto.md5(arg_3_1[arg_3_2["minjie_star" .. iter_3_1]] .. var_0_1.TableCryptoKey)
			}

			table.insert(var_3_3, var_3_4)
		end

		var_3_1.attrs_md5 = var_3_3
	end

	var_3_1.click_diaglogs = {}
	var_3_1.click_sounds = {}
	var_3_1.time_sounds = {}

	local function var_3_5(arg_4_0, arg_4_1, arg_4_2)
		if arg_3_1[arg_3_2[arg_4_0]] ~= "" and arg_3_1[arg_3_2[arg_4_0]] ~= nil then
			table.insert(var_3_1.click_diaglogs, arg_3_1[arg_3_2[arg_4_0]])
			table.insert(var_3_1.click_sounds, arg_3_1[arg_3_2[arg_4_1]])
			table.insert(var_3_1.time_sounds, tonumber(arg_3_1[arg_3_2[arg_4_2]]) or 0)
		end
	end

	var_3_5("click_dialog1", "click_sound1", "time_sound1")
	var_3_5("click_dialog2", "click_sound2", "time_sound2")
	var_3_5("click_dialog3", "click_sound3", "time_sound3")
	var_3_5("click_dialog4", "click_sound4", "time_sound4")
	var_3_5("click_dialog5", "click_sound5", "time_sound5")

	arg_3_0.partnerDisType_[var_3_0] = tonumber(arg_3_1[arg_3_2.distance_type])
	arg_3_0.stoneID_[var_3_0] = tonumber(arg_3_1[arg_3_2.stone_id])
	arg_3_0.heros_[var_3_0] = var_3_1

	if var_3_0 < var_0_1.NORMAL_HERO_END_ID then
		table.insert(arg_3_0.heroIDs, var_3_0)
	end

	if var_3_0 < var_0_1.AWAKEN_HERO_START_ID then
		table.insert(arg_3_0.originHeroIds, var_3_0)
	end
end

function var_0_2.parsePet(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = tonumber(arg_5_1[1])

	if arg_5_0:getRowTable(var_5_0) then
		error(var_5_0 .. " duplicated")
	end

	local var_5_1 = arg_5_0:Parsecommon(arg_5_1, arg_5_2)

	var_5_1.summon_type = tonumber(arg_5_1[arg_5_2.summon_type])
	var_5_1.stone_id = tonumber(arg_5_1[arg_5_2.stone_id])
	var_5_1.skin_item = var_0_1.splitToNumber(arg_5_1[arg_5_2.skin_item], "|")
	var_5_1.is_show = tonumber(arg_5_1[arg_5_2.is_show])
	var_5_1.librart_show = tonumber(arg_5_1[arg_5_2.librart_show])
	var_5_1.from = tonumber(arg_5_1[arg_5_2.from])
	var_5_1.stone_campaign = var_0_1.splitToNumber(arg_5_1[arg_5_2.stone_campaign], "|")
	var_5_1.chosen_sound = arg_5_1[arg_5_2.chosen_sound]
	var_5_1.dialog_sound = arg_5_1[arg_5_2.dialog_sound]
	var_5_1.dialog = arg_5_1[arg_5_2.dialog]
	var_5_1.search_name = var_0_1.split(arg_5_1[arg_5_2.search_name], "|")
	var_5_1.x = tonumber(arg_5_1[arg_5_2.x])
	var_5_1.y = tonumber(arg_5_1[arg_5_2.y])
	var_5_1.holy_attr = var_0_1.splitToNumber(arg_5_1[arg_5_2.holy_attr], ",")
	var_5_1.egg_item = tonumber(arg_5_1[arg_5_2.egg_item])
	var_5_1.icon = arg_5_1[arg_5_2.icon]
	var_5_1.hatch_time = tonumber(arg_5_1[arg_5_2.hatch_time])
	var_5_1.hero_recommend = var_0_1.splitToNumber(arg_5_1[arg_5_2.hero_recommend], "|")
	var_5_1.table_item_id = var_0_1.split(arg_5_1[arg_5_2.table_item_id], "@")
	var_5_1.home_color = var_0_1.split(arg_5_1[arg_5_2.home_color], "|")
	var_5_1.home_id = var_0_1.splitToNumber(arg_5_1[arg_5_2.home_id], "|")
	var_5_1.lev_txt_color = var_0_1.split(arg_5_1[arg_5_2.lev_txt_color], "|")
	var_5_1.practice_needs = {
		tonumber(arg_5_1[arg_5_2.practice_liliang_need]),
		tonumber(arg_5_1[arg_5_2.practice_zhili_need]),
		tonumber(arg_5_1[arg_5_2.practice_minjie_need])
	}
	var_5_1.practice_types = {
		tonumber(arg_5_1[arg_5_2.practice_liliang_type]),
		tonumber(arg_5_1[arg_5_2.practice_zhili_type]),
		tonumber(arg_5_1[arg_5_2.practice_minjie_type])
	}
	var_5_1.practice_values = {
		tonumber(arg_5_1[arg_5_2.practice_liliang_value]),
		tonumber(arg_5_1[arg_5_2.practice_zhili_value]),
		tonumber(arg_5_1[arg_5_2.practice_minjie_value])
	}

	table.insert(arg_5_0.petIds_, var_5_0)

	arg_5_0.id_to_egg_[var_5_1.egg_item] = var_5_0

	if isClient then
		local var_5_2 = {}

		for iter_5_0 = 1, var_0_1.HERO_TOTAL_STARS do
			local var_5_3 = {
				[var_0_1.HeroType.WISE] = crypto.md5(arg_5_1[arg_5_2["zhili_star" .. iter_5_0]] .. var_0_1.TableCryptoKey),
				[var_0_1.HeroType.STRENGTH] = crypto.md5(arg_5_1[arg_5_2["liliang_star" .. iter_5_0]] .. var_0_1.TableCryptoKey),
				[var_0_1.HeroType.AGILE] = crypto.md5(arg_5_1[arg_5_2["minjie_star" .. iter_5_0]] .. var_0_1.TableCryptoKey)
			}

			table.insert(var_5_2, var_5_3)
		end

		var_5_1.attrs_md5 = var_5_2
	end

	arg_5_0.partnerDisType_[var_5_0] = tonumber(arg_5_1[arg_5_2.distance_type])
	arg_5_0.stoneID_[var_5_0] = tonumber(arg_5_1[arg_5_2.stone_id])
	arg_5_0.pets_[var_5_0] = var_5_1
end

function var_0_2.saveMonster(arg_6_0, arg_6_1)
	arg_6_0.unparsedMonsters_ = arg_6_1.rows
	arg_6_0.unparsedMonsters_.keys = arg_6_1.keys
end

function var_0_2.parseMonster(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_0.unparsedMonsters_[arg_7_1]

	if not var_7_0 then
		return
	end

	local var_7_1 = loadstring(var_7_0)()
	local var_7_2 = arg_7_0.unparsedMonsters_.keys
	local var_7_3 = arg_7_0:Parsecommon(var_7_1, var_7_2)

	var_7_3.star = tonumber(var_7_1[var_7_2.star])
	var_7_3.level = tonumber(var_7_1[var_7_2.level])
	var_7_3.color = tonumber(var_7_1[var_7_2.color])
	var_7_3.skin_item = var_0_1.splitToNumber(var_7_1[var_7_2.skin_item], "|")
	var_7_3.fumo = var_0_1.splitToNumber(var_7_1[var_7_2.fumo], "|")
	var_7_3.equip = var_0_1.splitToNumber(var_7_1[var_7_2.equip], "|")
	var_7_3.init_mp = tonumber(var_7_1[var_7_2.init_mp])
	var_7_3.summon_type = tonumber(var_7_1[var_7_2.summon_type])
	var_7_3.total_hp = tonumber(var_7_1[var_7_2.total_hp])
	var_7_3.awaken_id = tonumber(var_7_1[var_7_2.awaken_id])
	var_7_3.boss = tonumber(var_7_1[var_7_2.boss])
	var_7_3.avoid_hero_move_behind = tonumber(var_7_1[var_7_2.avoid_hero_move_behind])
	var_7_3.partner_id = tonumber(var_7_1[var_7_2.partner_id])
	var_7_3.move = tonumber(var_7_1[var_7_2.move])
	var_7_3.element = tonumber(var_7_1[var_7_2.element])
	var_7_3.element_equip = var_0_1.splitToNumber(var_7_1[var_7_2.element_equip], "|")
	var_7_3.element_strth = var_0_1.splitToNumber(var_7_1[var_7_2.element_strth], "|")
	arg_7_0.monsters_[arg_7_1] = var_7_3

	return var_7_3
end

function var_0_2.serverParseMonster(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = tonumber(arg_8_1[1])

	if arg_8_0:getRowTable(var_8_0) then
		error(var_8_0 .. " duplicated")
	end

	local var_8_1 = arg_8_0:Parsecommon(arg_8_1, arg_8_2)

	var_8_1.star = tonumber(arg_8_1[arg_8_2.star])
	var_8_1.level = tonumber(arg_8_1[arg_8_2.level])
	var_8_1.color = tonumber(arg_8_1[arg_8_2.color])
	var_8_1.skin_item = var_0_1.splitToNumber(arg_8_1[arg_8_2.skin_item], "|")
	var_8_1.fumo = var_0_1.splitToNumber(arg_8_1[arg_8_2.fumo], "|")
	var_8_1.equip = var_0_1.splitToNumber(arg_8_1[arg_8_2.equip], "|")
	var_8_1.init_mp = tonumber(arg_8_1[arg_8_2.init_mp])
	var_8_1.summon_type = tonumber(arg_8_1[arg_8_2.summon_type])
	var_8_1.total_hp = tonumber(arg_8_1[arg_8_2.total_hp])
	var_8_1.awaken_id = tonumber(arg_8_1[arg_8_2.awaken_id])
	var_8_1.boss = tonumber(arg_8_1[arg_8_2.boss])
	var_8_1.avoid_hero_move_behind = tonumber(arg_8_1[arg_8_2.avoid_hero_move_behind])
	var_8_1.partner_id = tonumber(arg_8_1[arg_8_2.partner_id])
	var_8_1.move = tonumber(arg_8_1[arg_8_2.move])
	var_8_1.element = tonumber(arg_8_1[arg_8_2.element])
	var_8_1.element_equip = var_0_1.splitToNumber(arg_8_1[arg_8_2.element_equip], "|")
	var_8_1.element_strth = var_0_1.splitToNumber(arg_8_1[arg_8_2.element_strth], "|")
	arg_8_0.monsters_[var_8_0] = var_8_1

	return var_8_1
end

function var_0_2.parseActivityPartner(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = tonumber(arg_9_1[1])

	if arg_9_0:getRowTable(var_9_0) then
		error(var_9_0 .. " duplicated")
	end

	local var_9_1 = arg_9_0:Parsecommon(arg_9_1, arg_9_2, true)

	var_9_1.init_power = tonumber(arg_9_1[arg_9_2.init_power])
	var_9_1.color_lev = var_0_1.splitToNumber(arg_9_1[arg_9_2.color_levels], "|")
	var_9_1.level_item = tonumber(arg_9_1[arg_9_2.level_item])
	var_9_1.level_item_exp = tonumber(arg_9_1[arg_9_2.level_item_exp])
	var_9_1.attr_item = tonumber(arg_9_1[arg_9_2.attr_item])
	var_9_1.promote_attr = var_0_1.splitToNumber(arg_9_1[arg_9_2.promote_attr], "|")
	var_9_1.max_attr_point = var_0_1.splitToNumber(arg_9_1[arg_9_2.max_attr_point], "|")
	var_9_1.attr_star = var_0_1.splitToNumber(arg_9_1[arg_9_2.attr_star], "|")

	if isClient then
		local var_9_2 = {}

		for iter_9_0 = 1, var_0_1.HERO_TOTAL_STARS do
			local var_9_3 = {
				[var_0_1.HeroType.WISE] = crypto.md5(arg_9_1[arg_9_2["zhili_star" .. iter_9_0]] .. var_0_1.TableCryptoKey),
				[var_0_1.HeroType.STRENGTH] = crypto.md5(arg_9_1[arg_9_2["liliang_star" .. iter_9_0]] .. var_0_1.TableCryptoKey),
				[var_0_1.HeroType.AGILE] = crypto.md5(arg_9_1[arg_9_2["minjie_star" .. iter_9_0]] .. var_0_1.TableCryptoKey)
			}

			table.insert(var_9_2, var_9_3)
		end

		var_9_1.attrs_md5 = var_9_2
	end

	arg_9_0.partnerDisType_[var_9_0] = tonumber(arg_9_1[arg_9_2.distance_type])
	arg_9_0.activityHeros_[var_9_0] = var_9_1
end

function var_0_2.parseSuperPartner(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = tonumber(arg_10_1[1])

	if arg_10_0:isDuplicatedID(var_10_0) then
		error(var_10_0 .. " duplicated")
	end

	local var_10_1 = {
		name = arg_10_1[arg_10_2.name],
		des1 = arg_10_1[arg_10_2.des1],
		des2 = arg_10_1[arg_10_2.des2],
		type = tonumber(arg_10_1[arg_10_2.type]),
		gender = tonumber(arg_10_1[arg_10_2.gender]),
		modelid = tonumber(arg_10_1[arg_10_2.modelid]),
		modelids = var_0_1.splitToNumber(arg_10_1[arg_10_2.modelids], "|"),
		ini_star = tonumber(arg_10_1[arg_10_2.ini_star]),
		distance = tonumber(arg_10_1[arg_10_2.distance]),
		distance_type = tonumber(arg_10_1[arg_10_2.distance_type]),
		interval = tonumber(arg_10_1[arg_10_2.interval]),
		speed = tonumber(arg_10_1[arg_10_2.speed]),
		buff_skill = var_0_1.splitToNumber(arg_10_1[arg_10_2.buff_skill], "|"),
		delay_skill = tonumber(arg_10_1[arg_10_2.delay_skill]),
		enter_skill = tonumber(arg_10_1[arg_10_2.enter_skill]),
		class_name = arg_10_1[arg_10_2.class_name],
		first_table_id = tonumber(arg_10_1[arg_10_2.first_table_id]),
		awaken_table_id = tonumber(arg_10_1[arg_10_2.awaken_table_id]),
		awanken_item = tonumber(arg_10_1[arg_10_2.awanken_item]),
		awaken = tonumber(arg_10_1[arg_10_2.awaken]),
		pugong = tonumber(arg_10_1[arg_10_2.skill0]),
		circle = var_0_1.splitToNumber(arg_10_1[arg_10_2.circle], "|"),
		start_circle = var_0_1.splitToNumber(arg_10_1[arg_10_2.start_circle], "|"),
		attributes = arg_10_0:parseAttributes(arg_10_1, arg_10_2),
		attr_grow = arg_10_0:parseSuperAttrGrows(arg_10_1, arg_10_2),
		skills = arg_10_0:parseSkills(arg_10_1, arg_10_2),
		skill0 = arg_10_0:getSkillID(arg_10_1, arg_10_2, 0),
		skill1 = arg_10_0:getSkillID(arg_10_1, arg_10_2, 1),
		skill2 = arg_10_0:getSkillID(arg_10_1, arg_10_2, 2),
		skill3 = arg_10_0:getSkillID(arg_10_1, arg_10_2, 3),
		skill4 = arg_10_0:getSkillID(arg_10_1, arg_10_2, 4),
		skill5 = arg_10_0:getSkillID(arg_10_1, arg_10_2, 5),
		skill6 = arg_10_0:getSkillID(arg_10_1, arg_10_2, 6),
		attr_rates = arg_10_0:parseAttrRates(arg_10_1, arg_10_2),
		die_skill = tonumber(arg_10_1[arg_10_2.die_skill])
	}

	if not arg_10_0.checkTable_[var_10_0] then
		arg_10_0.checkTable_[var_10_0] = {}
	end

	arg_10_0.checkTable_[var_10_0].interval = var_10_1.interval
	arg_10_0.checkTable_[var_10_0].attrs = var_10_1.attributes
	arg_10_0.checkTable_[var_10_0].attr_grow = var_10_1.attr_grow

	if not noEquip then
		var_10_1.equip_list = arg_10_0:parseSuperEquipList(arg_10_1, arg_10_2)
		arg_10_0.checkTable_[var_10_0].equips = var_10_1.equip_list
	end

	var_10_1.des3 = arg_10_1[arg_10_2.des3]
	var_10_1.stone_id = tonumber(arg_10_1[arg_10_2.stone_id])
	var_10_1.skin_item = var_0_1.splitToNumber(arg_10_1[arg_10_2.skin_item], "|")
	var_10_1.is_show = tonumber(arg_10_1[arg_10_2.is_show])
	var_10_1.librart_show = tonumber(arg_10_1[arg_10_2.librart_show])
	var_10_1.exchange_show = tonumber(arg_10_1[arg_10_2.exchange_show])
	var_10_1.is_open_dialog = tonumber(arg_10_1[arg_10_2.is_open_dialog])
	var_10_1.from = tonumber(arg_10_1[arg_10_2.from])
	var_10_1.stone_campaign = var_0_1.splitToNumber(arg_10_1[arg_10_2.stone_campaign], "|")
	var_10_1.chosen_sound = arg_10_1[arg_10_2.chosen_sound]
	var_10_1.dialog_sound = arg_10_1[arg_10_2.dialog_sound]
	var_10_1.dialog = arg_10_1[arg_10_2.dialog]
	var_10_1.x = tonumber(arg_10_1[arg_10_2.x])
	var_10_1.y = tonumber(arg_10_1[arg_10_2.y])
	var_10_1.awaken = tonumber(arg_10_1[arg_10_2.awaken])
	var_10_1.bloodline_item = tonumber(arg_10_1[arg_10_2.bloodline_item])
	var_10_1.bloodline = tonumber(arg_10_1[arg_10_2.bloodline])
	var_10_1.dorm_item = var_0_1.splitToNumber(arg_10_1[arg_10_2.dorm_item], "|")
	var_10_1.can_guild_request = tonumber(arg_10_1[arg_10_2.can_guild_request])
	var_10_1.gift_like_type = tonumber(arg_10_1[arg_10_2.gift_like_type])
	var_10_1.gift_dislike_type = tonumber(arg_10_1[arg_10_2.gift_dislike_type])
	var_10_1.treasure_desc = arg_10_1[arg_10_2.treasure_desc]
	var_10_1.treasure_location = tonumber(arg_10_1[arg_10_2.treasure_location])
	var_10_1.treasure_skill = tonumber(arg_10_1[arg_10_2.treasure_skill])
	var_10_1.init_power = tonumber(arg_10_1[arg_10_2.init_power])
	var_10_1.search_name = var_0_1.split(arg_10_1[arg_10_2.search_name], "|")
	var_10_1.skin_hide = var_0_1.splitToNumber(arg_10_1[arg_10_2.skin_hide], "|")
	var_10_1.stone_ticket = tonumber(arg_10_1[arg_10_2.stone_ticket])
	var_10_1.cv = arg_10_1[arg_10_2.cv]
	var_10_1.material_hero = var_0_1.splitToNumber(arg_10_1[arg_10_2.material_hero], "|")
	var_10_1.sound_times = {}
	var_10_1.sound_dialogs = {}
	var_10_1.sound_files = {}

	for iter_10_0 = 1, 9 do
		var_10_1.sound_times[iter_10_0] = tonumber(arg_10_1[arg_10_2["time_sound" .. iter_10_0]])
		var_10_1.sound_dialogs[iter_10_0] = arg_10_1[arg_10_2[var_0_3[iter_10_0]]]
		var_10_1.sound_files[iter_10_0] = arg_10_1[arg_10_2[var_0_4[iter_10_0]]]
	end

	if var_10_1.treasure_location ~= 0 and tonumber(arg_10_1[arg_10_2.first_table_id]) == 0 then
		local var_10_2 = var_10_1.treasure_location

		if not arg_10_0.treasure_locations_[var_10_2] then
			arg_10_0.treasure_locations_[var_10_2] = {}
		end

		table.insert(arg_10_0.treasure_locations_[var_10_2], var_10_0)
	end

	var_10_1.practice_needs = {
		tonumber(arg_10_1[arg_10_2.practice_liliang_need]),
		tonumber(arg_10_1[arg_10_2.practice_zhili_need]),
		tonumber(arg_10_1[arg_10_2.practice_minjie_need])
	}
	var_10_1.practice_types = {
		tonumber(arg_10_1[arg_10_2.practice_liliang_type]),
		tonumber(arg_10_1[arg_10_2.practice_zhili_type]),
		tonumber(arg_10_1[arg_10_2.practice_minjie_type])
	}
	var_10_1.practice_values = {
		tonumber(arg_10_1[arg_10_2.practice_liliang_value]),
		tonumber(arg_10_1[arg_10_2.practice_zhili_value]),
		tonumber(arg_10_1[arg_10_2.practice_minjie_value])
	}

	if not arg_10_0.checkTable_[var_10_0] then
		arg_10_0.checkTable_[var_10_0] = {}
	end

	arg_10_0.checkTable_[var_10_0].practice = var_10_1.practice_values

	if isClient then
		local var_10_3 = {}

		for iter_10_1 = 1, 10 do
			local var_10_4 = {}
			local var_10_5 = var_0_1.splitToNumber(arg_10_1[arg_10_2["star" .. iter_10_1]], "|")

			var_10_4[var_0_1.HeroType.WISE] = crypto.md5(var_10_5[var_0_1.HeroType.WISE] .. var_0_1.TableCryptoKey)
			var_10_4[var_0_1.HeroType.STRENGTH] = crypto.md5(var_10_5[var_0_1.HeroType.STRENGTH] .. var_0_1.TableCryptoKey)
			var_10_4[var_0_1.HeroType.AGILE] = crypto.md5(var_10_5[var_0_1.HeroType.AGILE] .. var_0_1.TableCryptoKey)

			table.insert(var_10_3, var_10_4)
		end

		var_10_1.attrs_md5 = var_10_3
	end

	var_10_1.click_diaglogs = {}
	var_10_1.click_sounds = {}
	var_10_1.time_sounds = {}

	local function var_10_6(arg_11_0, arg_11_1, arg_11_2)
		if arg_10_1[arg_10_2[arg_11_0]] ~= "" and arg_10_1[arg_10_2[arg_11_0]] ~= nil then
			table.insert(var_10_1.click_diaglogs, arg_10_1[arg_10_2[arg_11_0]])
			table.insert(var_10_1.click_sounds, arg_10_1[arg_10_2[arg_11_1]])
			table.insert(var_10_1.time_sounds, tonumber(arg_10_1[arg_10_2[arg_11_2]]) or 0)
		end
	end

	var_10_6("click_dialog1", "click_sound1", "time_sound1")
	var_10_6("click_dialog2", "click_sound2", "time_sound2")
	var_10_6("click_dialog3", "click_sound3", "time_sound3")
	var_10_6("click_dialog4", "click_sound4", "time_sound4")
	var_10_6("click_dialog5", "click_sound5", "time_sound5")

	arg_10_0.partnerDisType_[var_10_0] = tonumber(arg_10_1[arg_10_2.distance_type])
	arg_10_0.stoneID_[var_10_0] = tonumber(arg_10_1[arg_10_2.stone_id])
	arg_10_0.superHeros_[var_10_0] = var_10_1

	table.insert(arg_10_0.superHeroIDs, var_10_0)
end

function var_0_2.getRowTable(arg_12_0, arg_12_1)
	if isClient then
		return arg_12_0.heros_[arg_12_1] or arg_12_0.pets_[arg_12_1] or arg_12_0.monsters_[arg_12_1] or arg_12_0:parseMonster(arg_12_1) or arg_12_0.activityHeros_[arg_12_1] or arg_12_0.superHeros_[arg_12_1]
	end

	return arg_12_0.heros_[arg_12_1] or arg_12_0.pets_[arg_12_1] or arg_12_0.monsters_[arg_12_1] or arg_12_0.activityHeros_[arg_12_1] or arg_12_0.superHeros_[arg_12_1]
end

function var_0_2.hasHero(arg_13_0, arg_13_1)
	return arg_13_0:getRowTable(arg_13_1) ~= nil
end

function var_0_2.isDuplicatedID(arg_14_0, arg_14_1)
	return (arg_14_0.heros_[arg_14_1] or arg_14_0.pets_[arg_14_1] or arg_14_0.monsters_[arg_14_1] or arg_14_0.activityHeros_[arg_14_1]) ~= nil
end

function var_0_2.name(arg_15_0, arg_15_1)
	return arg_15_0:getRowTable(arg_15_1).name or ""
end

function var_0_2.searchName(arg_16_0, arg_16_1)
	return arg_16_0:getRowTable(arg_16_1).search_name
end

function var_0_2.heroType(arg_17_0, arg_17_1)
	return arg_17_0:getRowTable(arg_17_1).type or 0
end

function var_0_2.gender(arg_18_0, arg_18_1)
	return arg_18_0:getRowTable(arg_18_1).gender or 0
end

function var_0_2.modelID(arg_19_0, arg_19_1)
	return arg_19_0:getRowTable(arg_19_1).modelid or 0
end

function var_0_2.modelIDs(arg_20_0, arg_20_1)
	return arg_20_0:getRowTable(arg_20_1).modelids or {}
end

function var_0_2.equipList(arg_21_0, arg_21_1)
	return arg_21_0:getRowTable(arg_21_1).equip_list or {}
end

function var_0_2.initialStar(arg_22_0, arg_22_1)
	return arg_22_0:getRowTable(arg_22_1).ini_star or 1
end

function var_0_2.distance(arg_23_0, arg_23_1)
	return arg_23_0:getRowTable(arg_23_1).distance or 0
end

function var_0_2.distanceType(arg_24_0, arg_24_1)
	return arg_24_0:getRowTable(arg_24_1).distance_type or 0
end

function var_0_2.getHeroAttrGrow(arg_25_0, arg_25_1, arg_25_2, arg_25_3)
	local var_25_0 = arg_25_0:getRowTable(arg_25_1)

	if isClient and var_25_0.attrs_md5 and var_25_0.attr_grow[arg_25_3][arg_25_2] and var_25_0.attrs_md5[arg_25_3][arg_25_2] and crypto.md5(tostring(var_25_0.attr_grow[arg_25_3][arg_25_2]) .. var_0_1.TableCryptoKey) ~= var_25_0.attrs_md5[arg_25_3][arg_25_2] then
		var_0_1.exitProgram()
	end

	return var_25_0.attr_grow[arg_25_3][arg_25_2] or 0
end

function var_0_2.getHeroMainAttr(arg_26_0, arg_26_1, arg_26_2, arg_26_3, arg_26_4)
	if not arg_26_2 or arg_26_2 > 3 then
		return 0
	end

	return arg_26_4 * arg_26_0:getHeroAttrGrow(arg_26_1, arg_26_2, arg_26_3)
end

function var_0_2.getInitialAttr(arg_27_0, arg_27_1, arg_27_2)
	return arg_27_0:getRowTable(arg_27_1).attributes[arg_27_2] or 0
end

function var_0_2.getDes(arg_28_0, arg_28_1)
	return arg_28_0:getRowTable(arg_28_1).des1 or ""
end

function var_0_2.getTalkText(arg_29_0, arg_29_1)
	return arg_29_0:getRowTable(arg_29_1).des2
end

function var_0_2.getCharacterSetting(arg_30_0, arg_30_1)
	return arg_30_0:getRowTable(arg_30_1).des3
end

function var_0_2.pugong(arg_31_0, arg_31_1)
	return arg_31_0:getRowTable(arg_31_1).pugong or 0
end

function var_0_2.getSkill(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = arg_32_0:getRowTable(arg_32_1).skills

	if arg_32_2 then
		return tonumber(var_32_0[arg_32_2] or 0)
	else
		return var_32_0 or {}
	end
end

function var_0_2.interval(arg_33_0, arg_33_1)
	return arg_33_0:getRowTable(arg_33_1).interval or 0
end

function var_0_2.circle(arg_34_0, arg_34_1)
	return arg_34_0:getRowTable(arg_34_1).circle or {}
end

function var_0_2.startCircle(arg_35_0, arg_35_1)
	return arg_35_0:getRowTable(arg_35_1).start_circle or {}
end

function var_0_2.speed(arg_36_0, arg_36_1)
	return arg_36_0:getRowTable(arg_36_1).speed or 0
end

function var_0_2.buffSkill(arg_37_0, arg_37_1)
	return arg_37_0:getRowTable(arg_37_1).buff_skill or {}
end

function var_0_2.star(arg_38_0, arg_38_1)
	return arg_38_0:getRowTable(arg_38_1).star or 1
end

function var_0_2.level(arg_39_0, arg_39_1)
	return arg_39_0:getRowTable(arg_39_1).level or 1
end

function var_0_2.color(arg_40_0, arg_40_1)
	return arg_40_0:getRowTable(arg_40_1).color or 1
end

function var_0_2.equip(arg_41_0, arg_41_1)
	return arg_41_0:getRowTable(arg_41_1).equip or {}
end

function var_0_2.fumo(arg_42_0, arg_42_1)
	return arg_42_0:getRowTable(arg_42_1).fumo or {}
end

function var_0_2.skinItem(arg_43_0, arg_43_1)
	local var_43_0 = arg_43_0:getRowTable(arg_43_1)

	if not var_43_0.skin_item or not var_43_0.skin_item[1] or var_43_0.skin_item[1] == 0 then
		return {}
	end

	return var_43_0.skin_item or {}
end

function var_0_2.stoneID(arg_44_0, arg_44_1)
	return arg_44_0:getRowTable(arg_44_1).stone_id or 0
end

function var_0_2.isShow(arg_45_0, arg_45_1)
	return arg_45_0:getRowTable(arg_45_1).is_show == 1
end

function var_0_2.isSX(arg_46_0, arg_46_1)
	return arg_46_0:getRowTable(arg_46_1).is_sx == 1
end

function var_0_2.isLibraryShow(arg_47_0, arg_47_1)
	return arg_47_0:getRowTable(arg_47_1).librart_show == 1
end

function var_0_2.isExchangeShow(arg_48_0, arg_48_1)
	return arg_48_0:getRowTable(arg_48_1).exchange_show == 1
end

function var_0_2.isOpenDialog(arg_49_0, arg_49_1)
	return arg_49_0:getRowTable(arg_49_1).is_open_dialog == 1
end

function var_0_2.attrRate(arg_50_0, arg_50_1, arg_50_2)
	return arg_50_0:attrRates(arg_50_1)[arg_50_2] or 0
end

function var_0_2.attrRates(arg_51_0, arg_51_1)
	return arg_51_0:getRowTable(arg_51_1).attr_rates
end

function var_0_2.clickDialog(arg_52_0, arg_52_1)
	return arg_52_0:getRowTable(arg_52_1).click_diaglogs
end

function var_0_2.delaySkill(arg_53_0, arg_53_1)
	return arg_53_0:getRowTable(arg_53_1).delay_skill or 0
end

function var_0_2.stoneCampain(arg_54_0, arg_54_1)
	local var_54_0 = arg_54_0:getRowTable(arg_54_1).stone_campaign

	if not var_54_0 or var_54_0[1] == 0 then
		return nil
	end

	return var_54_0 or {}
end

function var_0_2.initMp(arg_55_0, arg_55_1)
	return arg_55_0:getRowTable(arg_55_1).init_mp or 0
end

function var_0_2.from(arg_56_0, arg_56_1)
	return arg_56_0:getRowTable(arg_56_1).from or 0
end

function var_0_2.getPartnerDistanceType(arg_57_0)
	return arg_57_0.partnerDisType_
end

function var_0_2.chosenSound(arg_58_0, arg_58_1)
	return arg_58_0:getRowTable(arg_58_1).chosen_sound
end

function var_0_2.summonSound(arg_59_0, arg_59_1)
	return arg_59_0:getRowTable(arg_59_1).dialog_sound
end

function var_0_2.dialogSounds(arg_60_0, arg_60_1)
	return arg_60_0:getRowTable(arg_60_1).click_sounds
end

function var_0_2.dialog(arg_61_0, arg_61_1)
	return arg_61_0:getRowTable(arg_61_1).dialog
end

function var_0_2.getEggImgByEggId(arg_62_0, arg_62_1)
	return arg_62_0:getEggImg(arg_62_0.id_to_egg_[arg_62_1])
end

function var_0_2.getEgg(arg_63_0, arg_63_1)
	return arg_63_0:getRowTable(arg_63_1).egg_item
end

function var_0_2.getEggImg(arg_64_0, arg_64_1)
	return arg_64_0:getRowTable(arg_64_1).icon
end

function var_0_2.getHatchTime(arg_65_0, arg_65_1)
	return arg_65_0:getRowTable(arg_65_1).hatch_time
end

function var_0_2.soundTimes(arg_66_0, arg_66_1)
	return arg_66_0:getRowTable(arg_66_1).time_sounds
end

function var_0_2.enterSkill(arg_67_0, arg_67_1)
	return arg_67_0:getRowTable(arg_67_1).enter_skill or 0
end

function var_0_2.summonType(arg_68_0, arg_68_1)
	return arg_68_0:getRowTable(arg_68_1).summon_type or 0
end

function var_0_2.getPosX(arg_69_0, arg_69_1)
	return arg_69_0:getRowTable(arg_69_1).x or 0
end

function var_0_2.getPosY(arg_70_0, arg_70_1)
	return arg_70_0:getRowTable(arg_70_1).y or 0
end

function var_0_2.totalHp(arg_71_0, arg_71_1)
	return arg_71_0:getRowTable(arg_71_1).total_hp or 1
end

function var_0_2.className(arg_72_0, arg_72_1)
	local var_72_0 = arg_72_0:getRowTable(arg_72_1)

	if not var_72_0.class_name or var_72_0.class_name == "" then
		error("invalid class name of table id " .. arg_72_1)
	end

	return var_72_0.class_name
end

function var_0_2.awakenID(arg_73_0, arg_73_1)
	return arg_73_0:getRowTable(arg_73_1).awaken_id or 0
end

function var_0_2.boss(arg_74_0, arg_74_1)
	return arg_74_0:getRowTable(arg_74_1).boss or 0
end

function var_0_2.beforeAwaken(arg_75_0, arg_75_1)
	return arg_75_0:getRowTable(arg_75_1).first_table_id or 0
end

function var_0_2.afterAwaken(arg_76_0, arg_76_1)
	return arg_76_0:getRowTable(arg_76_1).awaken_table_id or 0
end

function var_0_2.awakenItemID(arg_77_0, arg_77_1)
	return arg_77_0:getRowTable(arg_77_1).awanken_item or 0
end

function var_0_2.isCanAwaken(arg_78_0, arg_78_1)
	return arg_78_0:getRowTable(arg_78_1).awaken or 0
end

function var_0_2.awakeTwiceItem(arg_79_0, arg_79_1)
	return arg_79_0:getRowTable(arg_79_1).bloodline_item or 0
end

function var_0_2.isCanAwakeTwice(arg_80_0, arg_80_1)
	return arg_80_0:getRowTable(arg_80_1).bloodline or 0
end

function var_0_2.dormItem(arg_81_0, arg_81_1)
	return arg_81_0:getRowTable(arg_81_1).dorm_item or {}
end

function var_0_2.initPower(arg_82_0, arg_82_1)
	return arg_82_0:getRowTable(arg_82_1).init_power or 0
end

function var_0_2.treasureDesc(arg_83_0, arg_83_1)
	return arg_83_0:getRowTable(arg_83_1).treasure_desc or ""
end

function var_0_2.treasureSkill(arg_84_0, arg_84_1)
	return arg_84_0:getRowTable(arg_84_1).treasure_skill or 0
end

function var_0_2.treasureLocation(arg_85_0, arg_85_1)
	return arg_85_0:getRowTable(arg_85_1).treasure_location or 0
end

function var_0_2.canGuildRequest(arg_86_0, arg_86_1)
	return arg_86_0:getRowTable(arg_86_1).can_guild_request or 0
end

function var_0_2.giftLikeType(arg_87_0, arg_87_1)
	return arg_87_0:getRowTable(arg_87_1).gift_like_type
end

function var_0_2.giftDislikeType(arg_88_0, arg_88_1)
	return arg_88_0:getRowTable(arg_88_1).gift_dislike_type
end

function var_0_2.avoidHeroMoveBehind(arg_89_0, arg_89_1)
	return (arg_89_0:getRowTable(arg_89_1).avoid_hero_move_behind or 0) == 1
end

function var_0_2.getStoneTable(arg_90_0)
	return arg_90_0.stoneID_ or {}
end

function var_0_2.getPracticeNeeds(arg_91_0, arg_91_1)
	return arg_91_0:getRowTable(arg_91_1).practice_needs or {}
end

function var_0_2.getPracticeAttrType(arg_92_0, arg_92_1)
	return arg_92_0:getRowTable(arg_92_1).practice_types or {}
end

function var_0_2.getPracticeAttrValue(arg_93_0, arg_93_1)
	return arg_93_0:getRowTable(arg_93_1).practice_values or {}
end

function var_0_2.monster2PartnerID(arg_94_0, arg_94_1)
	local var_94_0 = arg_94_0:getRowTable(arg_94_1).partner_id

	if not var_94_0 or var_94_0 < 1 then
		return arg_94_1
	end

	return var_94_0
end

function var_0_2.canMove(arg_95_0, arg_95_1)
	local var_95_0 = arg_95_0:getRowTable(arg_95_1).move

	if var_95_0 and var_95_0 == 0 then
		return false
	else
		return true
	end
end

function var_0_2.getHolyAttr(arg_96_0, arg_96_1)
	return arg_96_0:getRowTable(arg_96_1).holy_attr or {}
end

function var_0_2.getHeroRecommend(arg_97_0, arg_97_1)
	return arg_97_0:getRowTable(arg_97_1).hero_recommend or {}
end

function var_0_2.getTableItemId(arg_98_0, arg_98_1, arg_98_2)
	local var_98_0 = arg_98_0:getRowTable(arg_98_1)

	return var_0_1.splitToNumber(var_98_0.table_item_id[arg_98_2], "|") or {}
end

function var_0_2.getPetsIgnoreShow(arg_99_0)
	return arg_99_0.petIds_ or {}
end

function var_0_2.getTreasureHeros(arg_100_0, arg_100_1)
	return arg_100_0.treasure_locations_[arg_100_1] or {}
end

function var_0_2.getPetHomeID(arg_101_0, arg_101_1)
	return arg_101_0:getRowTable(arg_101_1).home_id or {}
end

function var_0_2.getPetHomeColor(arg_102_0, arg_102_1)
	return arg_102_0:getRowTable(arg_102_1).home_color or {}
end

function var_0_2.getPetLevTxtColor(arg_103_0, arg_103_1)
	return arg_103_0:getRowTable(arg_103_1).lev_txt_color or {}
end

function var_0_2.dieSkill(arg_104_0, arg_104_1)
	return arg_104_0:getRowTable(arg_104_1).die_skill or 0
end

function var_0_2.colorLev(arg_105_0, arg_105_1, arg_105_2)
	local var_105_0 = arg_105_0:getRowTable(arg_105_1)

	if arg_105_2 and var_105_0 and var_105_0.color_lev then
		return var_105_0.color_lev[arg_105_2] or 0
	end

	return var_105_0.color_lev or {}
end

function var_0_2.levelItem(arg_106_0, arg_106_1)
	return arg_106_0:getRowTable(arg_106_1).level_item or 0
end

function var_0_2.levelItemExp(arg_107_0, arg_107_1)
	return arg_107_0:getRowTable(arg_107_1).level_item_exp or 0
end

function var_0_2.attrItem(arg_108_0, arg_108_1)
	return arg_108_0:getRowTable(arg_108_1).attr_item or 0
end

function var_0_2.promoteAttr(arg_109_0, arg_109_1)
	return arg_109_0:getRowTable(arg_109_1).promote_attr or {}
end

function var_0_2.maxAttrPoint(arg_110_0, arg_110_1)
	return arg_110_0:getRowTable(arg_110_1).max_attr_point or {}
end

function var_0_2.attrStar(arg_111_0, arg_111_1)
	return arg_111_0:getRowTable(arg_111_1).attr_star or {}
end

function var_0_2.skinHide(arg_112_0, arg_112_1)
	return arg_112_0:getRowTable(arg_112_1).skin_hide or {}
end

function var_0_2.stoneTicket(arg_113_0, arg_113_1)
	return arg_113_0:getRowTable(arg_113_1).stone_ticket or {}
end

function var_0_2.guildRequestCrossService(arg_114_0, arg_114_1)
	return arg_114_0:getRowTable(arg_114_1).guild_request_cross_service or 0
end

function var_0_2.parseEquipList(arg_115_0, arg_115_1, arg_115_2)
	return {
		[var_0_1.EquipQuality.WHITE] = var_0_1.splitToNumber(arg_115_1[arg_115_2.white], "|"),
		[var_0_1.EquipQuality.GREEN] = var_0_1.splitToNumber(arg_115_1[arg_115_2.green], "|"),
		[var_0_1.EquipQuality.GREEN1] = var_0_1.splitToNumber(arg_115_1[arg_115_2.green1], "|"),
		[var_0_1.EquipQuality.BLUE] = var_0_1.splitToNumber(arg_115_1[arg_115_2.blue], "|"),
		[var_0_1.EquipQuality.BLUE1] = var_0_1.splitToNumber(arg_115_1[arg_115_2.blue1], "|"),
		[var_0_1.EquipQuality.BLUE2] = var_0_1.splitToNumber(arg_115_1[arg_115_2.blue2], "|"),
		[var_0_1.EquipQuality.PURPLE] = var_0_1.splitToNumber(arg_115_1[arg_115_2.purple], "|"),
		[var_0_1.EquipQuality.PURPLE1] = var_0_1.splitToNumber(arg_115_1[arg_115_2.purple1], "|"),
		[var_0_1.EquipQuality.PURPLE2] = var_0_1.splitToNumber(arg_115_1[arg_115_2.purple2], "|"),
		[var_0_1.EquipQuality.PURPLE3] = var_0_1.splitToNumber(arg_115_1[arg_115_2.purple3], "|"),
		[var_0_1.EquipQuality.PURPLE4] = var_0_1.splitToNumber(arg_115_1[arg_115_2.purple4], "|"),
		[var_0_1.EquipQuality.ORANGE] = var_0_1.splitToNumber(arg_115_1[arg_115_2.orange], "|"),
		[var_0_1.EquipQuality.ORANGE1] = var_0_1.splitToNumber(arg_115_1[arg_115_2.orange1], "|"),
		[var_0_1.EquipQuality.ORANGE2] = var_0_1.splitToNumber(arg_115_1[arg_115_2.orange2], "|"),
		[var_0_1.EquipQuality.RED] = var_0_1.splitToNumber(arg_115_1[arg_115_2.red], "|"),
		[var_0_1.EquipQuality.RED1] = var_0_1.splitToNumber(arg_115_1[arg_115_2.red1], "|")
	}
end

function var_0_2.parseSuperEquipList(arg_116_0, arg_116_1, arg_116_2)
	return {
		[var_0_1.EquipQuality.WHITE] = var_0_1.splitToNumber(arg_116_1[arg_116_2.equipment], "|")
	}
end

function var_0_2.parseAttributes(arg_117_0, arg_117_1, arg_117_2)
	return {
		[var_0_1.AttributeType.STRENGTH] = tonumber(arg_117_1[arg_117_2.liliang]) or 0,
		[var_0_1.AttributeType.WISE] = tonumber(arg_117_1[arg_117_2.zhili]) or 0,
		[var_0_1.AttributeType.AGILE] = tonumber(arg_117_1[arg_117_2.minjie]) or 0,
		[var_0_1.AttributeType.HP] = tonumber(arg_117_1[arg_117_2.hp]) or 0,
		[var_0_1.AttributeType.AD] = tonumber(arg_117_1[arg_117_2.ad]) or 0,
		[var_0_1.AttributeType.AP] = tonumber(arg_117_1[arg_117_2.ap]) or 0,
		[var_0_1.AttributeType.HUJIA] = tonumber(arg_117_1[arg_117_2.hujia]) or 0,
		[var_0_1.AttributeType.MOKANG] = tonumber(arg_117_1[arg_117_2.mokang]) or 0,
		[var_0_1.AttributeType.AD_BAOJI] = tonumber(arg_117_1[arg_117_2.ad_baoji]) or 0,
		[var_0_1.AttributeType.AP_BAOJI] = tonumber(arg_117_1[arg_117_2.ap_baoji]) or 0,
		[var_0_1.AttributeType.REHP] = tonumber(arg_117_1[arg_117_2.re_hp]) or 0,
		[var_0_1.AttributeType.REMP] = tonumber(arg_117_1[arg_117_2.re_mp]) or 0,
		[var_0_1.AttributeType.MINGZHONG] = tonumber(arg_117_1[arg_117_2.mingzhong]) or 0,
		[var_0_1.AttributeType.AD_BAOJIHARM] = tonumber(arg_117_1[arg_117_2.ad_baoji_harm]) or 0,
		[var_0_1.AttributeType.AP_BAOJIHARM] = tonumber(arg_117_1[arg_117_2.ap_baoji_harm]) or 0,
		[var_0_1.AttributeType.D_MP] = tonumber(arg_117_1[arg_117_2.d_mp]) or 0,
		[var_0_1.AttributeType.GETMP] = tonumber(arg_117_1[arg_117_2.get_mp]) or 0,
		[var_0_1.AttributeType.SPEED] = tonumber(arg_117_1[arg_117_2.speed]) or 0,
		[var_0_1.AttributeType.CURE] = tonumber(arg_117_1[arg_117_2.cure]) or 0,
		[var_0_1.AttributeType.ACK_SPEED] = tonumber(arg_117_1[arg_117_2.ack_speed]) or 0,
		[var_0_1.AttributeType.AD_HIT_RATE] = tonumber(arg_117_1[arg_117_2.ad_hit_rate]) or 1,
		[var_0_1.AttributeType.AD_JIANSHANG] = tonumber(arg_117_1[arg_117_2.ad_d_harm]) or 1,
		[var_0_1.AttributeType.AP_JIANSHANG] = tonumber(arg_117_1[arg_117_2.ap_d_harm]) or 1,
		[var_0_1.AttributeType.KILLING_MP] = tonumber(arg_117_1[arg_117_2.killing_mp]) or 300,
		[var_0_1.AttributeType.COUNT_REMP] = tonumber(arg_117_1[arg_117_2.count_remp]) or 0,
		[var_0_1.AttributeType.SHANBI] = tonumber(arg_117_1[arg_117_2.shanbi]) or 0,
		[var_0_1.AttributeType.D_HUJIA] = tonumber(arg_117_1[arg_117_2.d_hujia]) or 0,
		[var_0_1.AttributeType.D_MOKANG] = tonumber(arg_117_1[arg_117_2.d_mokang]) or 0,
		[var_0_1.AttributeType.XIXUE] = tonumber(arg_117_1[arg_117_2.xixue]) or 0,
		[var_0_1.AttributeType.AD_BAOJI_JIANSHANG] = tonumber(arg_117_1[arg_117_2.ad_d_crit]) or 1,
		[var_0_1.AttributeType.AP_BAOJI_JIANSHANG] = tonumber(arg_117_1[arg_117_2.ap_d_crit]) or 1,
		[var_0_1.AttributeType.D_CURE] = tonumber(arg_117_1[arg_117_2.d_cure]) or 1,
		[var_0_1.AttributeType.ATTACKED_RE_ENERGY] = tonumber(arg_117_1[arg_117_2.attacked_re_energy]) or 1,
		[var_0_1.AttributeType.BUFF_HARM_RATE] = tonumber(arg_117_1[arg_117_2.buff_harm_rate]) or 1
	}
end

function var_0_2.parseAttrGrows(arg_118_0, arg_118_1, arg_118_2)
	local var_118_0 = {}

	for iter_118_0 = 1, var_0_1.HERO_TOTAL_STARS do
		local var_118_1 = {
			[var_0_1.HeroType.WISE] = tonumber(arg_118_1[arg_118_2["zhili_star" .. iter_118_0]]) or 0,
			[var_0_1.HeroType.STRENGTH] = tonumber(arg_118_1[arg_118_2["liliang_star" .. iter_118_0]]) or 0,
			[var_0_1.HeroType.AGILE] = tonumber(arg_118_1[arg_118_2["minjie_star" .. iter_118_0]]) or 0
		}

		table.insert(var_118_0, var_118_1)
	end

	return var_118_0
end

function var_0_2.parseSuperAttrGrows(arg_119_0, arg_119_1, arg_119_2)
	local var_119_0 = {}

	for iter_119_0 = 1, 10 do
		local var_119_1 = var_0_1.splitToNumber(arg_119_1[arg_119_2["star" .. iter_119_0]], "|")
		local var_119_2 = {
			[var_0_1.HeroType.WISE] = tonumber(var_119_1[var_0_1.HeroType.WISE]) or 0,
			[var_0_1.HeroType.STRENGTH] = tonumber(var_119_1[var_0_1.HeroType.STRENGTH]) or 0,
			[var_0_1.HeroType.AGILE] = tonumber(var_119_1[var_0_1.HeroType.AGILE]) or 0
		}

		table.insert(var_119_0, var_119_2)
	end

	return var_119_0
end

function var_0_2.parseSkills(arg_120_0, arg_120_1, arg_120_2)
	return {
		[var_0_1.SKILL_INDEX.Energy] = arg_120_0:getSkillID(arg_120_1, arg_120_2, 1)[1] or 0,
		[var_0_1.SKILL_INDEX.Green] = arg_120_0:getSkillID(arg_120_1, arg_120_2, 2)[1] or 0,
		[var_0_1.SKILL_INDEX.Blue] = arg_120_0:getSkillID(arg_120_1, arg_120_2, 3)[1] or 0,
		[var_0_1.SKILL_INDEX.Purple] = arg_120_0:getSkillID(arg_120_1, arg_120_2, 4)[1] or 0,
		[var_0_1.SKILL_INDEX.Awake] = arg_120_0:getSkillID(arg_120_1, arg_120_2, 5)[1] or 0,
		[var_0_1.SKILL_INDEX.AwakeTwice] = arg_120_0:getSkillID(arg_120_1, arg_120_2, 6)[1] or 0
	}
end

function var_0_2.getSkillID(arg_121_0, arg_121_1, arg_121_2, arg_121_3)
	return var_0_1.splitToNumber(arg_121_1[arg_121_2["skill" .. arg_121_3]], "|") or {
		0
	}
end

function var_0_2.getSkillTable(arg_122_0, arg_122_1, arg_122_2)
	return arg_122_0:getRowTable(arg_122_1)["skill" .. arg_122_2] or {}
end

function var_0_2.setSkill(arg_123_0, arg_123_1, arg_123_2, arg_123_3)
	local var_123_0 = arg_123_0:getRowTable(arg_123_1)

	if arg_123_2 then
		var_123_0.skills[arg_123_2] = arg_123_3
	end
end

function var_0_2.parseAttrRates(arg_124_0, arg_124_1, arg_124_2)
	return {
		[var_0_1.AttrRateIndex.ATTACK] = tonumber(arg_124_1[arg_124_2.attr_1_rate]) or 0,
		[var_0_1.AttrRateIndex.DEFENSE] = tonumber(arg_124_1[arg_124_2.attr_2_rate]) or 0,
		[var_0_1.AttrRateIndex.BOSS] = tonumber(arg_124_1[arg_124_2.attr_3_rate]) or 0,
		[var_0_1.AttrRateIndex.MARCH] = tonumber(arg_124_1[arg_124_2.attr_4_rate]) or 0,
		[var_0_1.AttrRateIndex.ARENA] = tonumber(arg_124_1[arg_124_2.attr_5_rate]) or 0,
		[var_0_1.AttrRateIndex.ASSIST] = tonumber(arg_124_1[arg_124_2.attr_6_rate]) or 0
	}
end

function var_0_2.getCheckTable(arg_125_0, arg_125_1)
	return arg_125_0.checkTable_[arg_125_1] or {}
end

function var_0_2.getSoundDelayTime(arg_126_0, arg_126_1, arg_126_2)
	return arg_126_0:getRowTable(arg_126_1).sound_times[arg_126_2] or 0
end

function var_0_2.getAllVoiceInfo(arg_127_0, arg_127_1)
	local var_127_0 = arg_127_0:getRowTable(arg_127_1)

	return var_127_0.sound_files or {}, var_127_0.sound_dialogs or {}, var_127_0.sound_times or {}
end

function var_0_2.getSingleVoiceInfo(arg_128_0, arg_128_1, arg_128_2)
	local var_128_0 = arg_128_0:getRowTable(arg_128_1)

	return var_128_0.sound_files[arg_128_2] or "", var_128_0.sound_dialogs[arg_128_2] or "", var_128_0.sound_times[arg_128_2] or 0
end

function var_0_2.getCV(arg_129_0, arg_129_1)
	return arg_129_0:getRowTable(arg_129_1).cv or ""
end

function var_0_2.getSuperHeros(arg_130_0)
	return arg_130_0.superHeroIDs
end

function var_0_2.materialHero(arg_131_0, arg_131_1)
	return arg_131_0:getRowTable(arg_131_1).material_hero or {}
end

function var_0_2.elementType(arg_132_0, arg_132_1)
	return arg_132_0:getRowTable(arg_132_1).element or 0
end

function var_0_2.elementEquips(arg_133_0, arg_133_1)
	return arg_133_0:getRowTable(arg_133_1).element_equip or {}
end

function var_0_2.elementEquipsLevel(arg_134_0, arg_134_1)
	return arg_134_0:getRowTable(arg_134_1).element_strth or {
		0,
		0,
		0,
		0,
		0,
		0
	}
end

function var_0_2.getAllHeroes(arg_135_0)
	return var_0_1.mergeTable(arg_135_0.heroIDs, arg_135_0.superHeroIDs)
end

function var_0_2.getWholeHeroes(arg_136_0)
	return var_0_1.mergeTable(arg_136_0.originHeroIds, arg_136_0.superHeroIDs)
end

function var_0_2.getOriginHeroIds(arg_137_0)
	return arg_137_0.originHeroIds or {}
end

return var_0_2
