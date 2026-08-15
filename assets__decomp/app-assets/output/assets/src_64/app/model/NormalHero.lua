local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("NormalHero", import("app.model.Hero"))
local var_0_4 = isClient and var_0_0.import("app.model.Item") or var_0_0.import("lib.battle.app.model.Item")
local var_0_5

if not isClient then
	var_0_5 = require("lib.spirit.spirit_item")
end

local var_0_6 = require("framework.scheduler")
local var_0_7 = var_0_2.tables.cabinetSkillTable
local var_0_8 = var_0_2.tables.hero
local var_0_9 = var_0_2.tables.skill
local var_0_10 = var_0_2.tables.model
local var_0_11 = var_0_2.tables.item
local var_0_12 = var_0_2.tables.heroExp
local var_0_13 = var_0_2.tables.dormHouse
local var_0_14 = var_0_2.tables.elementEquip
local var_0_15 = var_0_2.tables.elementStrth
local var_0_16 = var_0_2.tables.spirit
local var_0_17 = var_0_2.tables.spiritEquip
local var_0_18 = var_0_2.tables.spiritSuit
local var_0_19 = -1
local var_0_20 = 6
local var_0_21 = 20001453

function var_0_3.ctor(arg_1_0)
	arg_1_0.heroID_ = var_0_19
	arg_1_0.playerID_ = 0
	arg_1_0.exp_ = 0
	arg_1_0.isPet_ = false
	arg_1_0.selfSkillIDs_ = {}
	arg_1_0.partnerType = var_0_2.PartnerType.NORMAL

	if isClient then
		arg_1_0.selfPlayer = var_0_2.ModelManager.get():loadModel(var_0_2.ModelType.SELF_PLAYER)
	else
		arg_1_0.spiritItems_ = {}
	end
end

function var_0_3.initUnCollected_(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	arg_2_3 = arg_2_3 or {}
	arg_2_0.tableID_ = arg_2_1
	arg_2_0.heroID_ = arg_2_2 or var_0_19
	arg_2_0.star_ = arg_2_3.star or var_0_8:initialStar(arg_2_1)
	arg_2_0.level_ = arg_2_3.lev or 1
	arg_2_0.color_ = arg_2_3.color or 1
	arg_2_0.isCollected_ = arg_2_3.isCollected or false
	arg_2_0.exp_ = arg_2_3.exp or 0
	arg_2_0.practice_attr_ = {
		0,
		0,
		0
	}
	arg_2_0.region_arena_times = tonumber(arg_2_3.region_arena_times) or 0
	arg_2_0.skill_book_ = {}
	arg_2_0.bookshelfLev = 0

	local var_2_0 = arg_2_3.skills or {
		1,
		1,
		1,
		1,
		1,
		1
	}

	arg_2_0.skillLev_ = {}
	arg_2_0.skillLev_[var_0_2.SKILL_INDEX.Energy] = tonumber(var_2_0[var_0_2.SKILL_INDEX.Energy]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Energy]

	if arg_2_0.color_ >= var_0_2.EquipQuality.GREEN then
		arg_2_0.skillLev_[var_0_2.SKILL_INDEX.Green] = tonumber(var_2_0[var_0_2.SKILL_INDEX.Green]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Green]
	else
		arg_2_0.skillLev_[var_0_2.SKILL_INDEX.Green] = false
	end

	if arg_2_0.color_ >= var_0_2.EquipQuality.BLUE then
		arg_2_0.skillLev_[var_0_2.SKILL_INDEX.Blue] = tonumber(var_2_0[var_0_2.SKILL_INDEX.Blue]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Blue]
	else
		arg_2_0.skillLev_[var_0_2.SKILL_INDEX.Blue] = false
	end

	if arg_2_0.color_ >= var_0_2.EquipQuality.PURPLE then
		arg_2_0.skillLev_[var_0_2.SKILL_INDEX.Purple] = tonumber(var_2_0[var_0_2.SKILL_INDEX.Purple]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Purple]
	else
		arg_2_0.skillLev_[var_0_2.SKILL_INDEX.Purple] = false
	end

	if arg_2_0:isAwaken() then
		arg_2_0.skillLev_[var_0_2.SKILL_INDEX.Awake] = tonumber(var_2_0[var_0_2.SKILL_INDEX.Awake]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Awake]
	else
		arg_2_0.skillLev_[var_0_2.SKILL_INDEX.Awake] = false
	end

	if arg_2_0:isAwakeTwice() then
		arg_2_0.skillLev_[var_0_2.SKILL_INDEX.AwakeTwice] = tonumber(var_2_0[var_0_2.SKILL_INDEX.AwakeTwice]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.AwakeTwice]
	else
		arg_2_0.skillLev_[var_0_2.SKILL_INDEX.AwakeTwice] = false
	end

	local var_2_1 = arg_2_3.equip or {
		0,
		0,
		0,
		0,
		0,
		0
	}

	arg_2_0.equips_ = {}

	for iter_2_0 = 1, var_0_20 do
		table.insert(arg_2_0.equips_, tonumber(var_2_1[iter_2_0]))
	end

	local var_2_2 = arg_2_3.fumos or {
		0,
		0,
		0,
		0,
		0,
		0
	}

	arg_2_0.fumo_ = {}

	for iter_2_1 = 1, var_0_20 do
		table.insert(arg_2_0.fumo_, tonumber(var_2_2[iter_2_1]))
	end

	arg_2_0.unlockedDynamicCards = {}
	arg_2_0.dynamicCardState = {}
	arg_2_0.collectQualityStage = 0
	arg_2_0.collectStarStage = 0
end

function var_0_3.populate_(arg_3_0, arg_3_1)
	arg_3_0.playerID_ = tonumber(arg_3_1.player_id or 0)
	arg_3_0.heroID_ = arg_3_1.partner_id
	arg_3_0.tableID_ = tonumber(arg_3_1.table_id)
	arg_3_0.star_ = tonumber(arg_3_1.star)
	arg_3_0.level_ = tonumber(arg_3_1.lev or 1)

	if isClient then
		arg_3_0.exp_ = tonumber(arg_3_1.exp) or var_0_2.tables.partnerExp:totalExp(arg_3_0.level_)
	else
		arg_3_0.exp_ = tonumber(arg_3_1.exp) or 0
	end

	arg_3_0.color_ = tonumber(arg_3_1.color or 1)

	arg_3_0:apartSkinIds(arg_3_1.skin_ids)

	arg_3_0.skinId_ = tonumber(arg_3_1.current_skin_id or 0)
	arg_3_0.illusionSkinId_ = tonumber(arg_3_1.illusion_skin_id or -1)
	arg_3_0.elementEquips_ = arg_3_1.element_equips
	arg_3_0.elementEquipsLevel_ = arg_3_1.element_levels
	arg_3_0.elementBindingEquips_ = arg_3_1.element_bak_equips
	arg_3_0.elementBindingEquipsLevel_ = arg_3_1.element_bak_levels
	arg_3_0.spiritEquip_ = arg_3_1.spirit_equip or {}
	arg_3_0.spiritItems_ = arg_3_1.spirit_item

	arg_3_0:updateSkinInfo()

	arg_3_0.isBoard = tonumber(arg_3_1.is_board or 0)
	arg_3_0.boardCard = tonumber(arg_3_1.board_card) or 1
	arg_3_0.boardModelID = tonumber(arg_3_1.board_model_id or 0)
	arg_3_0.favorDegree = tonumber(arg_3_1.favor_degree or 0)
	arg_3_0.isMarried = tonumber(arg_3_1.is_married or 0)
	arg_3_0.feedAttrs = arg_3_1.feed_attrs or {}
	arg_3_0.awakeTwiceStage_ = tonumber(arg_3_1.twice_awake_stage) or 0
	arg_3_0.practice_attr_ = arg_3_1.practice_attr or {
		0,
		0,
		0
	}
	arg_3_0.skill_book_ = arg_3_1.skill_book_info or {}
	arg_3_0.region_arena_times = tonumber(arg_3_1.region_arena_times) or 0
	arg_3_0.bookshelfLev = tonumber(arg_3_1.book_shelf_lev) or 0
	arg_3_0.inscriptItems_ = arg_3_1.inscript_items or {}
	arg_3_0.conquerSchoolLev = tonumber(arg_3_1.conquer_lev or 0)
	arg_3_0.conquerLoopID = tonumber(arg_3_1.conquer_loop_id or 1)
	arg_3_0.courses = arg_3_1.courses or {}
	arg_3_0.coursesProgress = arg_3_1.courses_progress or {}
	arg_3_0.coursesSkill = arg_3_1.courses_skill or {}
	arg_3_0.coursesQuality = arg_3_1.courses_quality or {}
	arg_3_0.coursesExp = arg_3_1.courses_exp or {}
	arg_3_0.evoAttrPoints = arg_3_1.evo_attr_points or {}
	arg_3_0.evoStage = tonumber(arg_3_1.evo_stage) or 1
	arg_3_0.isLike = arg_3_1.is_like or 0
	arg_3_0.houseId = arg_3_1.house_id
	arg_3_0.houseTableId = arg_3_1.house_table_id
	arg_3_0.houseComfort = arg_3_1.house_comfort
	arg_3_0.houseEquips = arg_3_1.house_equips
	arg_3_0.houseExpandLev = tonumber(arg_3_1.house_expand_lev or 0)
	arg_3_0.unlockedDynamicCards = var_0_2.splitToNumber(arg_3_1.unlocked_dynamic_card or "", "|")
	arg_3_0.dynamicCardState = var_0_2.splitToNumber(arg_3_1.dynamic_card_state or "", "|")
	arg_3_0.collectQualityStage = tonumber(arg_3_1.collect_quality_stage) or 0
	arg_3_0.collectStarStage = tonumber(arg_3_1.collect_star_stage) or 0
	arg_3_0.force_ = math.ceil(tonumber(arg_3_1.force) or 0)
	arg_3_0.skillIDs_ = arg_3_1.skill_ids or {
		0,
		0,
		0,
		0,
		0,
		0
	}

	arg_3_0:updatePracticeAwardAttr()

	arg_3_0.isCollected_ = true
	arg_3_0.buffs_ = arg_3_1.buffs or {}
	arg_3_0.coursesInfo = {}

	for iter_3_0 = 1, #arg_3_0.courses do
		local var_3_0 = {
			progress = arg_3_0.coursesProgress[iter_3_0],
			quality = arg_3_0.coursesQuality[iter_3_0],
			add_skill = arg_3_0.coursesSkill[iter_3_0],
			exp = arg_3_0.coursesExp[iter_3_0]
		}

		arg_3_0.coursesInfo[arg_3_0.courses[iter_3_0]] = var_3_0
	end

	if arg_3_0:checkIsZhuge() then
		for iter_3_1, iter_3_2 in ipairs(arg_3_0.skillIDs_) do
			if iter_3_2 ~= 0 then
				arg_3_0.selfSkillIDs_[iter_3_1] = iter_3_2
			else
				arg_3_0.selfSkillIDs_[iter_3_1] = var_0_8:getSkillTable(arg_3_0.tableID_, iter_3_1)[1] or 0
			end
		end
	end

	local var_3_1 = arg_3_1.skills or {
		1,
		1,
		1,
		1,
		1,
		1
	}

	arg_3_0.skillLev_ = {}
	arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Energy] = tonumber(var_3_1[var_0_2.SKILL_INDEX.Energy]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Energy]

	if arg_3_0.color_ >= var_0_2.EquipQuality.GREEN then
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Green] = tonumber(var_3_1[var_0_2.SKILL_INDEX.Green]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Green]
	else
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Green] = false
	end

	if arg_3_0.color_ >= var_0_2.EquipQuality.BLUE then
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Blue] = tonumber(var_3_1[var_0_2.SKILL_INDEX.Blue]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Blue]
	else
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Blue] = false
	end

	if arg_3_0.color_ >= var_0_2.EquipQuality.PURPLE then
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Purple] = tonumber(var_3_1[var_0_2.SKILL_INDEX.Purple]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Purple]
	else
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Purple] = false
	end

	if arg_3_0:isAwaken() then
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Awake] = tonumber(var_3_1[var_0_2.SKILL_INDEX.Awake]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Awake]
	else
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Awake] = false
	end

	if arg_3_0:isAwakeTwice() then
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.AwakeTwice] = tonumber(var_3_1[var_0_2.SKILL_INDEX.AwakeTwice]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.AwakeTwice]
	else
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.AwakeTwice] = false
	end

	local var_3_2 = arg_3_1.equips or {
		0,
		0,
		0,
		0,
		0,
		0
	}

	arg_3_0.equips_ = {}

	for iter_3_3 = 1, var_0_20 do
		table.insert(arg_3_0.equips_, tonumber(var_3_2[iter_3_3]))
	end

	local var_3_3 = arg_3_1.fumos or {
		0,
		0,
		0,
		0,
		0,
		0
	}

	arg_3_0.fumo_ = {}

	for iter_3_4 = 1, var_0_20 do
		table.insert(arg_3_0.fumo_, tonumber(var_3_3[iter_3_4]))
	end

	local var_3_4 = arg_3_1.fumo_levels

	if var_3_4 and next(var_3_4) then
		arg_3_0.fumoLev_ = {}

		for iter_3_5 = 1, var_0_20 do
			table.insert(arg_3_0.fumoLev_, tonumber(var_3_4[iter_3_5]))
		end
	end
end

function var_0_3.checkIsZhuge(arg_4_0)
	if arg_4_0.tableID_ == 10001144 or arg_4_0.tableID_ == 11001144 then
		return true
	end
end

function var_0_3.populateWithTableID_(arg_5_0, arg_5_1, arg_5_2)
	arg_5_2 = arg_5_2 or {}
	arg_5_0.tableID_ = arg_5_1
	arg_5_0.heroID_ = arg_5_2.partner_id or var_0_19
	arg_5_0.star_ = arg_5_2.star or var_0_8:initialStar(arg_5_1)
	arg_5_0.level_ = arg_5_2.level or var_0_8:level(arg_5_1)
	arg_5_0.color_ = arg_5_2.color or var_0_8:color(arg_5_1)
	arg_5_0.equips_ = arg_5_2.equips or var_0_8:equip(arg_5_1) or {
		0,
		0,
		0,
		0,
		0,
		0
	}
	arg_5_0.fumo_ = {
		0,
		0,
		0,
		0,
		0,
		0
	}
	arg_5_0.practice_attr_ = {
		0,
		0,
		0
	}
	arg_5_0.skill_book_ = {}
	arg_5_0.bookshelfLev = 0
	arg_5_0.skillLev_ = {}
	arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Energy] = arg_5_0.level_
	arg_5_0.inscriptItems_ = {}

	if arg_5_0.color_ >= var_0_2.EquipQuality.GREEN then
		arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Green] = arg_5_0.level_
	else
		arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Green] = false
	end

	if arg_5_0.color_ >= var_0_2.EquipQuality.BLUE then
		arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Blue] = arg_5_0.level_
	else
		arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Blue] = false
	end

	if arg_5_0.color_ >= var_0_2.EquipQuality.PURPLE then
		arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Purple] = arg_5_0.level_
	else
		arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Purple] = false
	end

	if var_0_8:getSkill(arg_5_1, var_0_2.SKILL_INDEX.Awake) > 0 then
		arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Awake] = arg_5_0.level_
	else
		arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Awake] = false
	end

	if var_0_8:getSkill(arg_5_1, var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		arg_5_0.skillLev_[var_0_2.SKILL_INDEX.AwakeTwice] = arg_5_0.level_
	else
		arg_5_0.skillLev_[var_0_2.SKILL_INDEX.AwakeTwice] = false
	end
end

function var_0_3.toParams(arg_6_0)
	local var_6_0 = {
		player_id = arg_6_0.playerID_,
		partner_id = arg_6_0.heroID_,
		table_id = arg_6_0.tableID_,
		star = arg_6_0.star_,
		lev = arg_6_0.level_,
		exp = arg_6_0.exp_,
		color = arg_6_0.color_,
		equips = arg_6_0.equips_,
		fumos = arg_6_0.fumo_,
		current_skin_id = arg_6_0.skinId_,
		illusion_skin_id = arg_6_0.illusionSkinId_,
		skin_ids = arg_6_0:mergeSkinIds(),
		element_equips = arg_6_0.elementEquips_,
		element_levels = arg_6_0.elementEquipsLevel_,
		element_bak_equips = arg_6_0.elementBindingEquips_,
		element_bak_levels = arg_6_0.elementBindingEquipsLevel_,
		spirit_equip = arg_6_0.spiritEquip_,
		spirit_item = arg_6_0.spiritItems_,
		practice_attr = arg_6_0.practice_attr_,
		skill_book_info = arg_6_0.skill_book_,
		book_shelf_lev = arg_6_0.bookshelfLev,
		twice_awake_stage = arg_6_0.awakeTwiceStage_,
		inscript_items = arg_6_0.inscriptItems_,
		courses = arg_6_0.courses,
		courses_progress = arg_6_0.coursesProgress,
		courses_skill = arg_6_0.coursesSkill,
		courses_quality = arg_6_0.coursesQuality,
		skill_ids = arg_6_0.skillIDs_,
		favor_degree = arg_6_0.favorDegree,
		feed_attrs = arg_6_0.feedAttrs,
		is_married = arg_6_0.isMarried,
		is_like = arg_6_0.isLike,
		house_id = arg_6_0.houseId,
		house_table_id = arg_6_0.houseTableId,
		house_comfort = arg_6_0.houseComfort,
		house_equips = arg_6_0.houseEquips,
		house_expand_lev = arg_6_0.houseExpandLev,
		region_arena_times = arg_6_0.region_arena_times,
		unlocked_dynamic_card = var_0_2.catToString(arg_6_0.unlockedDynamicCards, "|"),
		dynamic_card_state = var_0_2.catToString(arg_6_0.dynamicCardState, "|"),
		collect_quality_stage = arg_6_0.collectQualityStage,
		collect_star_stage = arg_6_0.collectStarStage
	}

	if arg_6_0.fumoLev_ then
		var_6_0.fumo_levels = arg_6_0.fumoLev_
	end

	if arg_6_0.conquerSchoolLev and arg_6_0.conquerSchoolLev > 0 then
		var_6_0.conquer_lev = arg_6_0.conquerSchoolLev
	end

	if arg_6_0.conquerLoopID and arg_6_0.conquerLoopID > 0 then
		var_6_0.conquer_loop_id = arg_6_0.conquerLoopID
	end

	local var_6_1 = var_0_0.clone(arg_6_0.skillLev_)

	for iter_6_0, iter_6_1 in ipairs(var_6_1) do
		var_6_1[iter_6_0] = (iter_6_1 or var_0_2.SKILL_EXTRA[iter_6_0]) + 1 - var_0_2.SKILL_EXTRA[iter_6_0]
	end

	var_6_0.skills = var_6_1

	return var_6_0
end

function var_0_3.setSkillsLevel(arg_7_0, arg_7_1)
	if not arg_7_1 or next(arg_7_1) == nil then
		return nil
	end

	local var_7_0 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_1) do
		var_7_0["skill" .. iter_7_0] = iter_7_1
	end

	var_7_0.partner_id = arg_7_0.heroID_

	arg_7_0.selfPlayer:setSkillsLevel(var_7_0, function()
		return
	end)
end

function var_0_3.toString(arg_9_0)
	return json.encode(arg_9_0:toParams())
end

function var_0_3.getPlayerID(arg_10_0)
	return arg_10_0.playerID_
end

function var_0_3.setPlayerID(arg_11_0, arg_11_1)
	arg_11_0.playerID_ = arg_11_1
end

function var_0_3.getHeroID(arg_12_0)
	return arg_12_0.heroID_
end

function var_0_3.getTableID(arg_13_0)
	return arg_13_0.tableID_
end

function var_0_3.getFirstTableID(arg_14_0)
	local var_14_0 = arg_14_0:getTableID()

	if arg_14_0:isAwaken() then
		var_14_0 = arg_14_0:beforeAwakenID()
	end

	return var_14_0
end

function var_0_3.getStar(arg_15_0)
	return arg_15_0.star_ or 0
end

function var_0_3.setStar(arg_16_0, arg_16_1)
	arg_16_0.star_ = arg_16_1
end

function var_0_3.setIsPet(arg_17_0, arg_17_1)
	arg_17_0.isPet_ = arg_17_1
end

function var_0_3.setAttrMD5(arg_18_0, arg_18_1)
	arg_18_0.attrMD5_ = arg_18_1
end

function var_0_3.setTotalAttrs(arg_19_0, arg_19_1)
	arg_19_0.totalAttrs_ = arg_19_1
end

function var_0_3.setBookshelfLevel(arg_20_0, arg_20_1)
	arg_20_0.bookshelfLev = arg_20_1
end

function var_0_3.getLevel(arg_21_0)
	return arg_21_0.level_
end

function var_0_3.getPracticeAttr(arg_22_0, arg_22_1)
	return arg_22_0.practice_attr_[arg_22_1] or 0
end

function var_0_3.getSkillBookAttr(arg_23_0, arg_23_1)
	local var_23_0 = 0

	for iter_23_0, iter_23_1 in pairs(arg_23_0.skill_book_) do
		if arg_23_1 == var_0_7:attrIds(tonumber(iter_23_0)) then
			var_23_0 = var_23_0 + var_0_7:attrValues(tonumber(iter_23_0)) * iter_23_1
		end
	end

	return var_23_0
end

function var_0_3.setConquerSchoolLev(arg_24_0, arg_24_1, arg_24_2)
	arg_24_0.conquerSchoolLev = arg_24_1
	arg_24_0.conquerLoopID = arg_24_2 or arg_24_0.selfPlayer.conquerLoopID or 1
end

function var_0_3.getConquerSchoolAttr(arg_25_0, arg_25_1)
	local var_25_0 = 0

	if not arg_25_0.conquerSchoolLev or arg_25_0.conquerSchoolLev <= 0 then
		return 0
	end

	local var_25_1 = arg_25_0.conquerLoopID
	local var_25_2 = var_0_2.tables.conquerSchoolCampaign:getRegionByLev(arg_25_0.conquerSchoolLev, var_25_1)

	for iter_25_0 = 1, var_25_2 do
		if var_0_2.tables.conquerSchoolCampaign:checkAttrOpen(iter_25_0, arg_25_0.conquerSchoolLev, var_25_1) then
			var_25_0 = var_25_0 + tonumber(var_0_2.tables.conquerSchool:attrValues(iter_25_0, arg_25_1))
		end
	end

	return var_25_0
end

function var_0_3.getFeedAttr(arg_26_0, arg_26_1)
	for iter_26_0, iter_26_1 in pairs(arg_26_0.feedAttrs or {}) do
		if var_0_2.tables.libraryFeedAttr:attrType(iter_26_0) == arg_26_1 then
			return iter_26_1
		end
	end

	return 0
end

function var_0_3.getPractice(arg_27_0)
	return arg_27_0.practice_attr_ or {
		0,
		0,
		0
	}
end

function var_0_3.getSuiPian(arg_28_0)
	if not arg_28_0:getSuiPianID() or arg_28_0:getSuiPianID() == 0 then
		return 0
	end

	local var_28_0 = arg_28_0.selfPlayer:getBackpack()

	if var_28_0 == nil then
		return 0
	end

	return var_28_0:getItemNumByID(arg_28_0:getSuiPianID())
end

function var_0_3.getSuiPianID(arg_29_0)
	return var_0_8:stoneID(arg_29_0:getTableID())
end

function var_0_3.canSummon(arg_30_0)
	if arg_30_0.isCollected_ or arg_30_0:getSuiPian() < var_0_2.TotalStarSuipian[arg_30_0:getStar()] then
		return false
	end

	return true
end

function var_0_3.isCollected(arg_31_0)
	return arg_31_0.isCollected_ or false
end

function var_0_3.getExp(arg_32_0)
	return arg_32_0.exp_
end

function var_0_3.getColor(arg_33_0)
	return arg_33_0.color_
end

function var_0_3.getName(arg_34_0)
	return var_0_8:name(arg_34_0:getTableID())
end

function var_0_3.getSearchName(arg_35_0)
	return var_0_8:searchName(arg_35_0:getTableID())
end

function var_0_3.getHeroType(arg_36_0)
	return var_0_8:heroType(arg_36_0:getTableID())
end

function var_0_3.getAvatar(arg_37_0, arg_37_1)
	if not arg_37_1 or arg_37_1 == 1 then
		return var_0_10:avatar(arg_37_0:getModelID())
	end

	return var_0_10:avatar2(arg_37_0:getModelID())
end

function var_0_3.getModelID(arg_38_0)
	if not arg_38_0.illusionSkinId_ or arg_38_0.illusionSkinId_ == -1 then
		return arg_38_0:getOldModelID()
	elseif arg_38_0.illusionSkinId_ == 0 then
		return var_0_8:modelID(arg_38_0:getFirstTableID())
	elseif arg_38_0.illusionSkinId_ == 1 then
		return var_0_8:modelID(arg_38_0:getTableID())
	else
		return arg_38_0.illusionSkinId_
	end
end

function var_0_3.getOldModelID(arg_39_0)
	if arg_39_0.isSkinOn_ == 1 then
		return arg_39_0.skinId_
	else
		return var_0_8:modelID(arg_39_0:getTableID())
	end
end

function var_0_3.getModelIDs(arg_40_0)
	return var_0_8:modelIDs(arg_40_0:getTableID())
end

function var_0_3.getDistanceType(arg_41_0)
	return var_0_8:distanceType(arg_41_0:getTableID())
end

function var_0_3.getDistance(arg_42_0)
	return var_0_8:distance(arg_42_0:getTableID())
end

function var_0_3.getFromType(arg_43_0)
	return var_0_8:from(arg_43_0:getTableID())
end

function var_0_3.getAddExp(arg_44_0)
	return var_0_12:addExp(arg_44_0:getLevel())
end

function var_0_3.isShow(arg_45_0)
	return var_0_8:isShow(arg_45_0:getTableID())
end

function var_0_3.enterDuration(arg_46_0)
	return var_0_9:enterDuration(arg_46_0:enterSkill())
end

function var_0_3.enterSpeed(arg_47_0)
	return var_0_9:enterSpeed(arg_47_0:enterSkill())
end

function var_0_3.enterDelayDuration(arg_48_0)
	return var_0_9:enterDelayDuration(arg_48_0:enterSkill())
end

function var_0_3.enterSkill(arg_49_0)
	return var_0_8:enterSkill(arg_49_0:getTableID())
end

function var_0_3.className(arg_50_0)
	return var_0_8:className(arg_50_0:getTableID())
end

function var_0_3.awakenID(arg_51_0)
	return var_0_8:awakenID(arg_51_0:getTableID())
end

function var_0_3.beforeAwakenID(arg_52_0)
	return var_0_8:beforeAwaken(arg_52_0:getTableID())
end

function var_0_3.afterAwakenID(arg_53_0)
	return var_0_8:afterAwaken(arg_53_0:getTableID())
end

function var_0_3.getZhandouli(arg_54_0)
	return (math.ceil(arg_54_0:getBasicForce() + arg_54_0:getEquipForce() + arg_54_0:getSkillForce() + arg_54_0:getBookSkillForce() + arg_54_0:getInscriptionForce() + arg_54_0:getConquerSchoolForce() + arg_54_0:getFeedForce() + arg_54_0:getCoursesForce() + arg_54_0:getStoneEvolutionForce() + arg_54_0:getWhiteAlbumForce()))
end

function var_0_3.getStoneEvolutionForce(arg_55_0)
	local var_55_0 = 0

	for iter_55_0 = 1, var_0_2.AttributeType.TOTAL_ATTR_NUM do
		var_55_0 = var_55_0 + arg_55_0:getStoneEvolutionAttr(iter_55_0) * var_0_2.tables.attr:attrScore(iter_55_0)
	end

	return var_55_0
end

function var_0_3.getBasicForce(arg_56_0)
	local var_56_0 = 0

	for iter_56_0 = 1, 3 do
		local var_56_1 = arg_56_0:getGrowAttr(arg_56_0:getTableID(), iter_56_0, arg_56_0:getStar(), arg_56_0:getLevel())
		local var_56_2 = var_0_2.JINJIE_ATTR_RATE * (arg_56_0:getColor() - 1) / 2 * arg_56_0:getColor()
		local var_56_3 = var_0_8:getInitialAttr(arg_56_0:getTableID(), iter_56_0)

		var_56_0 = var_56_0 + (var_56_1 + var_56_2 + var_56_3) * var_0_2.tables.attr:attrScore(iter_56_0)
	end

	for iter_56_1 = 4, var_0_2.AttributeType.TOTAL_ATTR_NUM do
		var_56_0 = var_56_0 + var_0_8:getInitialAttr(arg_56_0:getTableID(), iter_56_1) * var_0_2.tables.attr:attrScore(iter_56_1)
	end

	return var_56_0
end

function var_0_3.getEquipForce(arg_57_0)
	local var_57_0 = 0

	for iter_57_0 = 1, var_0_2.AttributeType.TOTAL_ATTR_NUM do
		var_57_0 = var_57_0 + (arg_57_0:getJinjieEquipAttr(iter_57_0) + arg_57_0:getEquipAttr(iter_57_0) + arg_57_0:getEquipFumoAttr(iter_57_0) + arg_57_0:getTotalPracticeAttr(iter_57_0) + arg_57_0:getElementAttrJustForShow(iter_57_0) + arg_57_0:getSpiritEquipsAttr(iter_57_0)) * var_0_2.tables.attr:attrScore(iter_57_0)
	end

	return var_57_0
end

function var_0_3.getBookSkillForce(arg_58_0)
	local var_58_0 = 0

	for iter_58_0 = 1, var_0_2.AttributeType.TOTAL_ATTR_NUM do
		var_58_0 = var_58_0 + arg_58_0:getSkillBookAttr(iter_58_0) * var_0_2.tables.attr:attrScore(iter_58_0)
	end

	return var_58_0
end

function var_0_3.getConquerSchoolForce(arg_59_0)
	local var_59_0 = 0

	for iter_59_0 = 1, var_0_2.AttributeType.TOTAL_ATTR_NUM do
		var_59_0 = var_59_0 + arg_59_0:getConquerSchoolAttr(iter_59_0) * var_0_2.tables.attr:attrScore(iter_59_0)
	end

	return var_59_0
end

function var_0_3.getSkillForce(arg_60_0)
	local var_60_0 = 0
	local var_60_1 = var_0_8:initPower(arg_60_0:getTableID())

	for iter_60_0 = 1, var_0_2.SKILL_INDEX.AwakeTwice do
		if iter_60_0 ~= var_0_2.SKILL_INDEX.Awake and iter_60_0 ~= var_0_2.SKILL_INDEX.AwakeTwice or iter_60_0 == var_0_2.SKILL_INDEX.Awake and arg_60_0:isAwaken() or iter_60_0 == var_0_2.SKILL_INDEX.AwakeTwice and arg_60_0:isAwakeTwice() then
			local var_60_2 = arg_60_0.skillLev_[iter_60_0] or 0

			if var_60_2 > 0 and (tonumber(var_0_8:getSkill(arg_60_0:getTableID(), iter_60_0)) or 0) > 0 then
				var_60_0 = var_60_0 + (iter_60_0 < var_0_2.SKILL_INDEX.Awake and 4 or 4.5) * var_60_2
			end
		end
	end

	return var_60_0 + var_60_1
end

function var_0_3.getInscriptionForce(arg_61_0)
	if not arg_61_0.inscriptItems_ then
		return 0
	end

	local var_61_0 = 0

	if not arg_61_0.inscriptItems_ then
		return var_61_0
	end

	for iter_61_0, iter_61_1 in pairs(arg_61_0.inscriptItems_) do
		local var_61_1 = var_0_2.tables.item:inscriptId(iter_61_1)

		var_61_0 = var_61_0 + var_0_2.tables.inscription:fightingCapacity(var_61_1)
	end

	local var_61_2 = arg_61_0:getSuitInfo()

	for iter_61_2, iter_61_3 in pairs(var_61_2) do
		if iter_61_3 then
			var_61_0 = var_61_0 + var_0_2.tables.inscriptionSuit:fightingCapacity(iter_61_2)
		end
	end

	return var_61_0
end

function var_0_3.getSuitInfo(arg_62_0)
	local var_62_0 = var_0_2.tables.inscriptionSuit
	local var_62_1 = arg_62_0:getInscriptItems()
	local var_62_2 = var_62_0:ids()
	local var_62_3 = {}

	for iter_62_0, iter_62_1 in ipairs(var_62_1) do
		for iter_62_2, iter_62_3 in ipairs(var_62_2) do
			if var_0_2.tableHaveElement(var_62_0:itemID(iter_62_3), iter_62_1) then
				local var_62_4 = true

				for iter_62_4, iter_62_5 in ipairs(var_62_0:itemID(iter_62_3)) do
					if not var_0_2.tableHaveElement(var_62_1, iter_62_5) then
						var_62_4 = false
					end
				end

				var_62_3[iter_62_3] = var_62_4
			end
		end
	end

	return var_62_3
end

function var_0_3.getCoursesForce(arg_63_0)
	local var_63_0 = 0

	if not arg_63_0.coursesInfo then
		return var_63_0
	end

	for iter_63_0, iter_63_1 in pairs(arg_63_0.coursesInfo) do
		if iter_63_1.add_skill and iter_63_1.add_skill > 0 then
			local var_63_1 = var_0_2.tables.objectBook:power(tonumber(iter_63_0))
			local var_63_2 = var_0_2.tables.objectBook:stepPower(tonumber(iter_63_0))

			var_63_0 = var_63_0 + var_63_1 + iter_63_1.quality * var_63_2
		end
	end

	return var_63_0
end

function var_0_3.getFeedForce(arg_64_0)
	local var_64_0 = 0

	for iter_64_0, iter_64_1 in pairs(arg_64_0.feedAttrs or {}) do
		var_64_0 = var_64_0 + iter_64_1 * var_0_2.tables.attr:attrScore(var_0_2.tables.libraryFeedAttr:attrType(iter_64_0))
	end

	return var_64_0
end

function var_0_3.getZhugeBookSkillNum(arg_65_0)
	local var_65_0 = {
		50000001,
		50000002,
		50000003,
		50000004,
		50000005,
		50000006,
		50000007,
		50000008,
		50000009,
		50000010,
		50000011,
		50000012,
		50000013,
		50000014,
		50000015,
		50000016,
		50000017,
		50000018,
		50000019,
		50000020,
		50000021,
		50000022,
		50000023,
		50000024,
		50000025
	}

	arg_65_0.zhugeBookSkillNum = 0

	if isClient then
		local var_65_1 = var_0_1.ctx.battle.reportData and var_0_1.ctx.battle.reportData.zhuge_book_skill_num and var_0_1.ctx.battle.reportData.zhuge_book_skill_num[tostring(arg_65_0.playerID_)]

		if var_65_1 then
			arg_65_0.zhugeBookSkillNum = var_65_1
		else
			local var_65_2 = arg_65_0.selfPlayer:getBackpack()

			for iter_65_0, iter_65_1 in pairs(var_65_0) do
				if var_65_2:getItemNumByID(iter_65_1) > 0 then
					arg_65_0.zhugeBookSkillNum = arg_65_0.zhugeBookSkillNum + 1
				end
			end
		end
	else
		local var_65_3 = require("lib.player.backpack"):new(arg_65_0.playerID_)

		for iter_65_2, iter_65_3 in pairs(var_65_0) do
			if var_65_3:get_item_num(iter_65_3) > 0 then
				arg_65_0.zhugeBookSkillNum = arg_65_0.zhugeBookSkillNum + 1
			end
		end
	end

	return arg_65_0.zhugeBookSkillNum
end

function var_0_3.getWhiteAlbumForce(arg_66_0)
	if arg_66_0.playerID_ == 0 then
		return 0
	end

	local var_66_0 = var_0_1.ctx.battle.reportData and var_0_1.ctx.battle.reportData.hero_collect_attr and var_0_1.ctx.battle.reportData.hero_collect_attr[tostring(arg_66_0.playerID_)]
	local var_66_1 = 0

	if var_66_0 and next(var_66_0) then
		for iter_66_0, iter_66_1 in pairs(var_66_0) do
			var_66_1 = var_66_1 + iter_66_1 * var_0_2.tables.attr:attrScore(tonumber(iter_66_0))
		end
	elseif arg_66_0.playerID_ == arg_66_0.selfPlayer.playerID then
		if not arg_66_0.selfPlayer.albumAttr then
			return var_66_1
		end

		for iter_66_2 = 1, #arg_66_0.selfPlayer.albumAttr do
			var_66_1 = var_66_1 + arg_66_0.selfPlayer.albumAttr[iter_66_2] * var_0_2.tables.attr:attrScore(iter_66_2)
		end
	end

	return var_66_1
end

function var_0_3.getCard(arg_67_0)
	return var_0_10:card(arg_67_0:getModelID())
end

function var_0_3.getSmallCard(arg_68_0)
	return var_0_10:smallCard(arg_68_0:getModelID())
end

function var_0_3.getScale(arg_69_0)
	return var_0_10:scale(arg_69_0:getModelID())
end

function var_0_3.getMainAttr(arg_70_0, arg_70_1)
	local var_70_0 = arg_70_0:getGrowAttr(arg_70_0:getTableID(), arg_70_1, arg_70_0:getStar(), arg_70_0:getLevel())
	local var_70_1 = var_0_2.JINJIE_ATTR_RATE * (arg_70_0:getColor() - 1) / 2 * arg_70_0:getColor()
	local var_70_2 = var_0_8:getInitialAttr(arg_70_0:getTableID(), arg_70_1)
	local var_70_3 = arg_70_0:getJinjieEquipAttr(arg_70_1) + arg_70_0:getEquipAttr(arg_70_1) + arg_70_0:getEquipFumoAttr(arg_70_1) + arg_70_0:getElementAttr(arg_70_1) + arg_70_0:getSpiritEquipsAttr(arg_70_1)
	local var_70_4 = arg_70_0:getTotalPracticeAttr(arg_70_1)
	local var_70_5 = arg_70_0:getSkillBookAttr(arg_70_1)
	local var_70_6 = arg_70_0:getInscriptionAttr(arg_70_1)
	local var_70_7 = arg_70_0:getConquerSchoolAttr(arg_70_1)
	local var_70_8 = arg_70_0:getCoursesAttr(arg_70_1)
	local var_70_9 = arg_70_0:getStoneEvolutionAttr(arg_70_1)

	return var_70_0 + var_70_1 + var_70_2 + var_70_3 + var_70_4 + var_70_5 + var_70_6 + var_70_7 + var_70_8 + var_70_9
end

function var_0_3.getGrowAttr(arg_71_0, arg_71_1, arg_71_2, arg_71_3, arg_71_4)
	local var_71_0 = var_0_8:getHeroMainAttr(arg_71_1, arg_71_2, arg_71_3, arg_71_4)
	local var_71_1 = arg_71_0:getBookShelfAttr(arg_71_2)

	return var_71_0 * (1 + arg_71_0:getFavorAttrGrowth() + arg_71_0:getHouseAttrGrowthByType(arg_71_2)) + var_71_1
end

function var_0_3.getBattleInscriptionAttr(arg_72_0, arg_72_1)
	local var_72_0 = 0

	if not arg_72_0.inscriptItems_ then
		return var_72_0
	end

	for iter_72_0, iter_72_1 in pairs(arg_72_0.inscriptItems_) do
		var_72_0 = var_72_0 + arg_72_0:getBattleInscriptionAttrByType(arg_72_1, iter_72_1)
	end

	return var_72_0 + arg_72_0:getInscriptionSuitAttr(arg_72_1)
end

function var_0_3.getBattleInscriptionAttrByType(arg_73_0, arg_73_1, arg_73_2)
	return var_0_2.tables.item:attrsBattle(arg_73_2)[arg_73_1] or 0
end

function var_0_3.getInscriptionAttr(arg_74_0, arg_74_1)
	local var_74_0 = 0

	if not arg_74_0.inscriptItems_ then
		return var_74_0
	end

	for iter_74_0, iter_74_1 in pairs(arg_74_0.inscriptItems_) do
		var_74_0 = var_74_0 + arg_74_0:getInscriptionAttrByType(arg_74_1, iter_74_1)
	end

	return var_74_0 + arg_74_0:getInscriptionSuitAttr(arg_74_1)
end

function var_0_3.getInscriptionAttrByType(arg_75_0, arg_75_1, arg_75_2)
	return var_0_2.tables.item:attrs(arg_75_2)[arg_75_1] or 0
end

function var_0_3.getStoneEvolutionAttr(arg_76_0, arg_76_1)
	local var_76_0 = arg_76_0:getEvoAttrPoints()[tostring(arg_76_1)] or 0
	local var_76_1 = arg_76_0:getEvoStage()
	local var_76_2, var_76_3 = var_0_2.tables.stoneEvolution:getCumAttrByType(var_76_1, var_76_0, arg_76_1)

	return var_76_2
end

function var_0_3.getInscriptionSuitAttr(arg_77_0, arg_77_1)
	local var_77_0 = {}
	local var_77_1 = arg_77_0:getSuitInfo()

	for iter_77_0, iter_77_1 in pairs(var_77_1) do
		if iter_77_1 then
			var_77_0 = var_0_2.tables.inscriptionSuit:attrs(iter_77_0)
		end
	end

	return var_77_0[arg_77_1] or 0
end

function var_0_3.getCoursesAttr(arg_78_0, arg_78_1)
	local var_78_0 = 0

	if not arg_78_0.coursesInfo then
		return var_78_0
	end

	for iter_78_0, iter_78_1 in pairs(arg_78_0.coursesInfo) do
		iter_78_0 = tonumber(iter_78_0)

		if iter_78_1.add_skill and iter_78_1.add_skill > 0 and var_0_2.tables.objectBook:bookType(iter_78_0) == 0 then
			local var_78_1 = var_0_2.tables.objectBook:attr(iter_78_0)
			local var_78_2 = var_0_2.tables.objectBook:number(iter_78_0)
			local var_78_3 = var_0_2.tables.objectBook:stepUp(iter_78_0)

			for iter_78_2 = 1, #var_78_1 do
				if var_78_1[iter_78_2] and var_78_1[iter_78_2] == arg_78_1 then
					local var_78_4 = var_78_2[iter_78_2] or 0
					local var_78_5 = var_78_3[iter_78_2] or 0

					var_78_0 = var_78_0 + var_78_4 + iter_78_1.quality * var_78_5
				end
			end
		end
	end

	return var_78_0
end

function var_0_3.getCourseIDByColor(arg_79_0, arg_79_1)
	if not arg_79_0.coursesInfo or arg_79_1 == 0 then
		return 0
	end

	for iter_79_0, iter_79_1 in pairs(arg_79_0.coursesInfo) do
		if iter_79_1.add_skill == arg_79_1 then
			return tonumber(iter_79_0)
		end
	end

	return 0
end

function var_0_3.getCourseLevelByID(arg_80_0, arg_80_1)
	if not arg_80_0.coursesInfo or arg_80_1 == 0 then
		return 0
	end

	for iter_80_0, iter_80_1 in pairs(arg_80_0.coursesInfo) do
		if tonumber(iter_80_0) == arg_80_1 then
			return tonumber(iter_80_1.quality)
		end
	end

	return 0
end

function var_0_3.getCourseTypeByID(arg_81_0, arg_81_1)
	return var_0_2.tables.objectBook:bookType(arg_81_1)
end

function var_0_3.getFavorAttrGrowth(arg_82_0)
	return var_0_2.tables.libraryAmour:attr(arg_82_0:getFavorLev())
end

function var_0_3.getFavorLev(arg_83_0)
	local var_83_0 = var_0_2.tables.libraryAmour:getCurrentId(arg_83_0:getFavorDegree())

	if arg_83_0:getFavorState() == var_0_2.FavorState.MARRIED then
		var_83_0 = var_83_0 + 1
	end

	return var_83_0
end

function var_0_3.getAttrGlow(arg_84_0, arg_84_1)
	return var_0_8:getHeroAttrGrow(arg_84_0:getTableID(), arg_84_1, arg_84_0:getStar())
end

function var_0_3.getFavorAttrGrowByType(arg_85_0, arg_85_1)
	return arg_85_0:getAttrGlow(arg_85_1) * arg_85_0:getFavorAttrGrowth()
end

function var_0_3.getHouseAttrGrowByType(arg_86_0, arg_86_1)
	return arg_86_0:getAttrGlow(arg_86_1) * arg_86_0:getHouseAttrGrowthByType(arg_86_1)
end

function var_0_3.getHouseAttrGrowthByType(arg_87_0, arg_87_1)
	local var_87_0 = var_0_13:getHouseLevByComfort(arg_87_0.houseTableId, arg_87_0.houseComfort)
	local var_87_1 = var_0_13:getAttrsGrowByLev(arg_87_0.houseTableId, var_87_0)
	local var_87_2 = var_0_13:type(arg_87_0.houseTableId)

	if arg_87_0.houseExpandLev and arg_87_0.houseExpandLev > 0 then
		local var_87_3 = var_0_2.tables.dormExpand:getAttrsGrowByLev(var_87_2, arg_87_0.houseComfort, arg_87_0.houseExpandLev)

		if var_87_3 then
			var_87_1 = var_87_3
		end
	end

	if not arg_87_0.houseTableId or arg_87_0.houseTableId <= 0 or not var_87_1 or not next(var_87_1) then
		return 0
	end

	return (var_87_1[arg_87_1] or 0) / 100
end

function var_0_3.getSkillAttr(arg_88_0, arg_88_1)
	local var_88_0 = var_0_1.ctx.battle.getRequire("Buff")

	local function var_88_1(arg_89_0, arg_89_1, arg_89_2)
		local var_89_0 = {}

		for iter_89_0, iter_89_1 in ipairs(arg_89_0) do
			local var_89_1 = var_88_0.new({
				start = 0,
				tableID = iter_89_1,
				level = arg_89_1,
				skillID = arg_89_2
			})

			var_89_1:setYongJiu()
			table.insert(var_89_0, var_89_1)
		end

		return var_89_0
	end

	local var_88_2 = var_0_8:buffSkill(arg_88_0:getTableID())

	if not next(var_88_2) then
		return 0
	end

	local var_88_3 = 0

	for iter_88_0, iter_88_1 in ipairs(var_88_2) do
		if var_0_9:skillType(iter_88_1) == var_0_2.SkillType.BUFF_SELF then
			local var_88_4 = arg_88_0:getSkillLevelByID(iter_88_1)

			if var_88_4 and var_88_4 > 0 then
				local var_88_5 = var_0_9:buffs(iter_88_1)
				local var_88_6 = var_88_1(var_88_5, var_88_4, iter_88_1)

				for iter_88_2, iter_88_3 in ipairs(var_88_6) do
					if iter_88_3:getAttrType() == arg_88_1 then
						local var_88_7, var_88_8 = iter_88_3:getAttr()

						if not var_88_8 then
							var_88_3 = var_88_3 + var_88_7
						else
							print("error : buff skill attribute type use percent increase " .. iter_88_3:getTableID())
						end
					end
				end
			end
		end
	end

	return var_88_3
end

function var_0_3.getMaxHP(arg_90_0)
	local var_90_0 = var_0_8:getInitialAttr(arg_90_0:getTableID(), var_0_2.AttributeType.HP)
	local var_90_1 = arg_90_0:getMainAttr(var_0_2.AttributeType.STRENGTH)

	return math.floor(var_90_0 + var_0_2.STRENGTH_HP_RATE * var_90_1)
end

function var_0_3.skillAttr2HP(arg_91_0)
	local var_91_0 = arg_91_0:getSkillAttr(var_0_2.AttributeType.STRENGTH)

	return var_0_2.STRENGTH_HP_RATE * var_91_0
end

function var_0_3.getAD(arg_92_0)
	local var_92_0 = var_0_8:getInitialAttr(arg_92_0:getTableID(), var_0_2.AttributeType.AD)
	local var_92_1 = arg_92_0:getMainAttr(var_0_2.AttributeType.AGILE) * var_0_2.AGILE_AD_RATE + arg_92_0:getMainAttr(arg_92_0:getHeroType())

	return math.floor(var_92_1 + var_92_0)
end

function var_0_3.skillAttr2AD(arg_93_0)
	local var_93_0 = arg_93_0:getSkillAttr(var_0_2.AttributeType.AGILE)

	return arg_93_0:getSkillAttr(arg_93_0:getHeroType()) + var_93_0 * var_0_2.AGILE_AD_RATE
end

function var_0_3.getAP(arg_94_0)
	local var_94_0 = var_0_8:getInitialAttr(arg_94_0:getTableID(), var_0_2.AttributeType.AP)
	local var_94_1 = arg_94_0:getMainAttr(var_0_2.AttributeType.WISE) * var_0_2.WISE_AP_RATE

	return math.floor(var_94_0 + var_94_1)
end

function var_0_3.skillAttr2AP(arg_95_0)
	return arg_95_0:getSkillAttr(var_0_2.AttributeType.WISE) * var_0_2.WISE_AP_RATE
end

function var_0_3.getHujia(arg_96_0)
	local var_96_0 = var_0_8:getInitialAttr(arg_96_0:getTableID(), var_0_2.AttributeType.HUJIA)
	local var_96_1 = var_0_2.AGILE_HUJIA_RATE * arg_96_0:getMainAttr(var_0_2.AttributeType.AGILE) + var_0_2.STRENGTH_HUJIA_RATE * arg_96_0:getMainAttr(var_0_2.AttributeType.STRENGTH)

	return math.floor(var_96_1 + var_96_0)
end

function var_0_3.skillAttr2Hujia(arg_97_0)
	local var_97_0 = arg_97_0:getSkillAttr(var_0_2.AttributeType.AGILE)
	local var_97_1 = arg_97_0:getSkillAttr(var_0_2.AttributeType.STRENGTH)

	return var_0_2.AGILE_HUJIA_RATE * var_97_0 + var_0_2.STRENGTH_HUJIA_RATE * var_97_1
end

function var_0_3.getMokang(arg_98_0)
	local var_98_0 = var_0_8:getInitialAttr(arg_98_0:getTableID(), var_0_2.AttributeType.MOKANG)
	local var_98_1 = var_0_2.WISE_MOKANG_RATE * arg_98_0:getMainAttr(var_0_2.AttributeType.WISE)

	return math.floor(var_98_0 + var_98_1)
end

function var_0_3.skillAttr2Mokang(arg_99_0)
	return var_0_2.WISE_MOKANG_RATE * arg_99_0:getSkillAttr(var_0_2.AttributeType.WISE)
end

function var_0_3.getADBaoji(arg_100_0)
	local var_100_0 = var_0_8:getInitialAttr(arg_100_0:getTableID(), var_0_2.AttributeType.AD_BAOJI)
	local var_100_1 = var_0_2.AGILE_AD_BAOJI_RATE * arg_100_0:getMainAttr(var_0_2.AttributeType.AGILE)

	return math.floor(var_100_0 + var_100_1)
end

function var_0_3.skillAttr2Baoji(arg_101_0)
	return var_0_2.AGILE_AD_BAOJI_RATE * arg_101_0:getSkillAttr(var_0_2.AttributeType.AGILE)
end

function var_0_3.getSkill2Attr(arg_102_0, arg_102_1)
	if arg_102_1 == var_0_2.AttributeType.HP then
		return arg_102_0:skillAttr2HP()
	elseif arg_102_1 == var_0_2.AttributeType.AD then
		return arg_102_0:skillAttr2AD()
	elseif arg_102_1 == var_0_2.AttributeType.AP then
		return arg_102_0:skillAttr2AP()
	elseif arg_102_1 == var_0_2.AttributeType.HUJIA then
		return arg_102_0:skillAttr2Hujia()
	elseif arg_102_1 == var_0_2.AttributeType.MOKANG then
		return arg_102_0:skillAttr2Mokang()
	elseif arg_102_1 == var_0_2.AttributeType.AD_BAOJI then
		return arg_102_0:skillAttr2Baoji()
	end

	return 0
end

function var_0_3.getTotalAttr(arg_103_0, arg_103_1)
	if arg_103_1 < 4 then
		return arg_103_0:getMainAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1)
	elseif arg_103_1 == var_0_2.AttributeType.HP then
		return arg_103_0:getMaxHP() + arg_103_0:getJinjieEquipAttr(arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getSkill2Attr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getSkillBookAttr(arg_103_1) + arg_103_0:getBattleInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getFeedAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	elseif arg_103_1 == var_0_2.AttributeType.AD then
		return arg_103_0:getAD() + arg_103_0:getJinjieEquipAttr(arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getSkill2Attr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getSkillBookAttr(arg_103_1) + arg_103_0:getBattleInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getFeedAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	elseif arg_103_1 == var_0_2.AttributeType.AP then
		return arg_103_0:getAP() + arg_103_0:getJinjieEquipAttr(arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getSkill2Attr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getSkillBookAttr(arg_103_1) + arg_103_0:getBattleInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getFeedAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	elseif arg_103_1 == var_0_2.AttributeType.HUJIA then
		return arg_103_0:getHujia() + arg_103_0:getJinjieEquipAttr(arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getSkill2Attr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getSkillBookAttr(arg_103_1) + arg_103_0:getBattleInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getFeedAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	elseif arg_103_1 == var_0_2.AttributeType.MOKANG then
		return arg_103_0:getMokang() + arg_103_0:getJinjieEquipAttr(arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getSkill2Attr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getSkillBookAttr(arg_103_1) + arg_103_0:getBattleInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getFeedAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	elseif arg_103_1 == var_0_2.AttributeType.AD_BAOJI then
		return arg_103_0:getADBaoji() + arg_103_0:getJinjieEquipAttr(arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getSkill2Attr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getSkillBookAttr(arg_103_1) + arg_103_0:getBattleInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getFeedAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	elseif arg_103_1 == var_0_2.AttributeType.ENERGY_RATE then
		return 1
	elseif arg_103_1 <= var_0_2.AttributeType.TOTAL_ATTR_NUM then
		return arg_103_0:getJinjieEquipAttr(arg_103_1) + var_0_8:getInitialAttr(arg_103_0:getTableID(), arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getSkillBookAttr(arg_103_1) + arg_103_0:getBattleInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	else
		return var_0_8:getInitialAttr(arg_103_0:getTableID(), arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getSkillBookAttr(arg_103_1) + arg_103_0:getBattleInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1)
	end
end

function var_0_3.getTotalAttrWithOutBook(arg_104_0, arg_104_1)
	if arg_104_1 < 4 then
		return arg_104_0:getMainAttr(arg_104_1) + arg_104_0:getSkillAttr(arg_104_1)
	elseif arg_104_1 == var_0_2.AttributeType.HP then
		return arg_104_0:getMaxHP() + arg_104_0:getJinjieEquipAttr(arg_104_1) + arg_104_0:getEquipAttr(arg_104_1) + arg_104_0:getEquipFumoAttr(arg_104_1) + arg_104_0:getSkillAttr(arg_104_1) + arg_104_0:getSkill2Attr(arg_104_1) + arg_104_0:getTotalPracticeAttr(arg_104_1) + arg_104_0:getInscriptionAttr(arg_104_1) + arg_104_0:getConquerSchoolAttr(arg_104_1) + arg_104_0:getFeedAttr(arg_104_1) + arg_104_0:getCoursesAttr(arg_104_1) + arg_104_0:getStoneEvolutionAttr(arg_104_1) + arg_104_0:getWhiteAlbumAttr(arg_104_1) + arg_104_0:getElementAttr(arg_104_1) + arg_104_0:getSpiritEquipsAttr(arg_104_1)
	elseif arg_104_1 == var_0_2.AttributeType.AD then
		return arg_104_0:getAD() + arg_104_0:getJinjieEquipAttr(arg_104_1) + arg_104_0:getEquipAttr(arg_104_1) + arg_104_0:getEquipFumoAttr(arg_104_1) + arg_104_0:getSkillAttr(arg_104_1) + arg_104_0:getSkill2Attr(arg_104_1) + arg_104_0:getTotalPracticeAttr(arg_104_1) + arg_104_0:getInscriptionAttr(arg_104_1) + arg_104_0:getConquerSchoolAttr(arg_104_1) + arg_104_0:getFeedAttr(arg_104_1) + arg_104_0:getCoursesAttr(arg_104_1) + arg_104_0:getStoneEvolutionAttr(arg_104_1) + arg_104_0:getWhiteAlbumAttr(arg_104_1) + arg_104_0:getElementAttr(arg_104_1) + arg_104_0:getSpiritEquipsAttr(arg_104_1)
	elseif arg_104_1 == var_0_2.AttributeType.AP then
		return arg_104_0:getAP() + arg_104_0:getJinjieEquipAttr(arg_104_1) + arg_104_0:getEquipAttr(arg_104_1) + arg_104_0:getEquipFumoAttr(arg_104_1) + arg_104_0:getSkillAttr(arg_104_1) + arg_104_0:getSkill2Attr(arg_104_1) + arg_104_0:getTotalPracticeAttr(arg_104_1) + arg_104_0:getInscriptionAttr(arg_104_1) + arg_104_0:getConquerSchoolAttr(arg_104_1) + arg_104_0:getFeedAttr(arg_104_1) + arg_104_0:getCoursesAttr(arg_104_1) + arg_104_0:getStoneEvolutionAttr(arg_104_1) + arg_104_0:getWhiteAlbumAttr(arg_104_1) + arg_104_0:getElementAttr(arg_104_1) + arg_104_0:getSpiritEquipsAttr(arg_104_1)
	elseif arg_104_1 == var_0_2.AttributeType.HUJIA then
		return arg_104_0:getHujia() + arg_104_0:getJinjieEquipAttr(arg_104_1) + arg_104_0:getEquipAttr(arg_104_1) + arg_104_0:getEquipFumoAttr(arg_104_1) + arg_104_0:getSkillAttr(arg_104_1) + arg_104_0:getSkill2Attr(arg_104_1) + arg_104_0:getTotalPracticeAttr(arg_104_1) + arg_104_0:getInscriptionAttr(arg_104_1) + arg_104_0:getConquerSchoolAttr(arg_104_1) + arg_104_0:getFeedAttr(arg_104_1) + arg_104_0:getCoursesAttr(arg_104_1) + arg_104_0:getStoneEvolutionAttr(arg_104_1) + arg_104_0:getWhiteAlbumAttr(arg_104_1) + arg_104_0:getElementAttr(arg_104_1) + arg_104_0:getSpiritEquipsAttr(arg_104_1)
	elseif arg_104_1 == var_0_2.AttributeType.MOKANG then
		return arg_104_0:getMokang() + arg_104_0:getJinjieEquipAttr(arg_104_1) + arg_104_0:getEquipAttr(arg_104_1) + arg_104_0:getEquipFumoAttr(arg_104_1) + arg_104_0:getSkillAttr(arg_104_1) + arg_104_0:getSkill2Attr(arg_104_1) + arg_104_0:getTotalPracticeAttr(arg_104_1) + arg_104_0:getInscriptionAttr(arg_104_1) + arg_104_0:getConquerSchoolAttr(arg_104_1) + arg_104_0:getFeedAttr(arg_104_1) + arg_104_0:getCoursesAttr(arg_104_1) + arg_104_0:getStoneEvolutionAttr(arg_104_1) + arg_104_0:getWhiteAlbumAttr(arg_104_1) + arg_104_0:getElementAttr(arg_104_1) + arg_104_0:getSpiritEquipsAttr(arg_104_1)
	elseif arg_104_1 == var_0_2.AttributeType.AD_BAOJI then
		return arg_104_0:getADBaoji() + arg_104_0:getJinjieEquipAttr(arg_104_1) + arg_104_0:getEquipAttr(arg_104_1) + arg_104_0:getEquipFumoAttr(arg_104_1) + arg_104_0:getSkillAttr(arg_104_1) + arg_104_0:getSkill2Attr(arg_104_1) + arg_104_0:getTotalPracticeAttr(arg_104_1) + arg_104_0:getInscriptionAttr(arg_104_1) + arg_104_0:getConquerSchoolAttr(arg_104_1) + arg_104_0:getFeedAttr(arg_104_1) + arg_104_0:getCoursesAttr(arg_104_1) + arg_104_0:getStoneEvolutionAttr(arg_104_1) + arg_104_0:getWhiteAlbumAttr(arg_104_1) + arg_104_0:getElementAttr(arg_104_1) + arg_104_0:getSpiritEquipsAttr(arg_104_1)
	elseif arg_104_1 <= var_0_2.AttributeType.TOTAL_ATTR_NUM then
		return arg_104_0:getJinjieEquipAttr(arg_104_1) + var_0_8:getInitialAttr(arg_104_0:getTableID(), arg_104_1) + arg_104_0:getEquipAttr(arg_104_1) + arg_104_0:getEquipFumoAttr(arg_104_1) + arg_104_0:getSkillAttr(arg_104_1) + arg_104_0:getTotalPracticeAttr(arg_104_1) + arg_104_0:getInscriptionAttr(arg_104_1) + arg_104_0:getConquerSchoolAttr(arg_104_1) + arg_104_0:getCoursesAttr(arg_104_1) + arg_104_0:getStoneEvolutionAttr(arg_104_1) + arg_104_0:getWhiteAlbumAttr(arg_104_1) + arg_104_0:getElementAttr(arg_104_1) + arg_104_0:getSpiritEquipsAttr(arg_104_1)
	else
		return var_0_8:getInitialAttr(arg_104_0:getTableID(), arg_104_1) + arg_104_0:getSkillAttr(arg_104_1) + arg_104_0:getTotalPracticeAttr(arg_104_1) + arg_104_0:getConquerSchoolAttr(arg_104_1)
	end
end

function var_0_3.setupBattleAttrInfo(arg_105_0)
	if not arg_105_0.isPet_ then
		arg_105_0.totalAttrs_ = {}
		arg_105_0.attrMD5_ = {}
		arg_105_0.errorData_ = arg_105_0.errorData_ or {}

		for iter_105_0 = 1, var_0_2.AttributeType.TOTAL_ATTR_NUM do
			arg_105_0.totalAttrs_[iter_105_0] = var_0_0.clone(arg_105_0:getTotalAttr(iter_105_0))

			if isClient then
				arg_105_0.attrMD5_[iter_105_0] = crypto.md5(arg_105_0.totalAttrs_[iter_105_0] .. var_0_2.tables.misc.encryptoKey)
			end
		end
	end
end

function var_0_3.getInscriptionKuangLevel(arg_106_0)
	local var_106_0 = arg_106_0:getInscriptItems()
	local var_106_1 = var_0_2.tables.inscriptionSuit

	if #var_106_0 < 3 then
		return false
	else
		local var_106_2 = arg_106_0:getSuitInfo()
		local var_106_3 = {}

		for iter_106_0, iter_106_1 in pairs(var_106_2) do
			if iter_106_1 then
				var_106_3 = var_106_1:itemID(iter_106_0)
			end
		end

		if #var_106_3 >= 3 then
			return 3
		elseif #var_106_3 >= 2 then
			return 2
		else
			return 1
		end
	end
end

function var_0_3.getBattleAttr(arg_107_0, arg_107_1)
	if not arg_107_0.totalAttrs_ then
		arg_107_0:setupBattleAttrInfo()
	end

	if isClient and crypto.md5(arg_107_0.totalAttrs_[arg_107_1] .. var_0_2.tables.misc.encryptoKey) ~= arg_107_0.attrMD5_[arg_107_1] then
		arg_107_0:recordErrorData(arg_107_1, arg_107_0.totalAttrs_[arg_107_1])
	end

	return arg_107_0.totalAttrs_[arg_107_1]
end

function var_0_3.recordErrorData(arg_108_0, arg_108_1, arg_108_2)
	arg_108_0.errorData_ = arg_108_0.errorData_ or {}
	arg_108_0.errorData_[tostring(arg_108_1)] = arg_108_2
end

function var_0_3.getEquipAttr(arg_109_0, arg_109_1)
	local var_109_0 = 0
	local var_109_1 = arg_109_0:getEquipList(arg_109_0:getColor())

	for iter_109_0, iter_109_1 in pairs(var_109_1) do
		if arg_109_0.equips_[iter_109_0] and arg_109_0.equips_[iter_109_0] > 0 then
			var_109_0 = var_109_0 + arg_109_0:getEquipAttrByType(arg_109_1, iter_109_1)
		end
	end

	return var_109_0 + arg_109_0:getHouseEquipAttr(arg_109_1)
end

function var_0_3.getHouseEquipAttr(arg_110_0, arg_110_1)
	if not arg_110_0.houseTableId or arg_110_0.houseTableId <= 0 or var_0_13:maintype(arg_110_0.houseTableId) == var_0_2.DormType.LOUNGE then
		return 0
	end

	local var_110_0 = 0
	local var_110_1 = arg_110_0:getHouseEquipsList(arg_110_0:getStar())

	for iter_110_0, iter_110_1 in pairs(var_110_1) do
		if arg_110_0.houseEquips and arg_110_0.houseEquips[iter_110_0] and arg_110_0.houseEquips[iter_110_0] > 0 then
			var_110_0 = var_110_0 + arg_110_0:getEquipAttrByType(arg_110_1, iter_110_1)
		end
	end

	return var_110_0
end

function var_0_3.getWhiteAlbumAttr(arg_111_0, arg_111_1)
	if arg_111_0.playerID_ == 0 then
		return 0
	end

	local var_111_0 = var_0_1.ctx.battle.reportData and var_0_1.ctx.battle.reportData.hero_collect_attr and var_0_1.ctx.battle.reportData.hero_collect_attr[tostring(arg_111_0.playerID_)]

	if var_111_0 and next(var_111_0) and var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		return var_111_0[tostring(arg_111_1)] or 0
	elseif arg_111_0.playerID_ == arg_111_0.selfPlayer.playerID then
		return arg_111_0.selfPlayer.albumAttr[arg_111_1] or 0
	end

	return 0
end

function var_0_3.updatePractice(arg_112_0, arg_112_1)
	arg_112_0.practice_attr_ = arg_112_1

	arg_112_0:updatePracticeAwardAttr()
end

function var_0_3.updateBookSkill(arg_113_0, arg_113_1, arg_113_2)
	arg_113_0.skill_book_[tostring(arg_113_1)] = arg_113_2
end

function var_0_3.getInscriptItem(arg_114_0, arg_114_1)
	if not arg_114_0.inscriptItems_ then
		return nil
	end

	for iter_114_0 = 1, #arg_114_0.inscriptItems_ do
		if var_0_2.tables.inscription:getItemPos(var_0_2.tables.item:inscriptId(arg_114_0.inscriptItems_[iter_114_0]), arg_114_0.inscriptItems_[iter_114_0]) == arg_114_1 then
			return arg_114_0.inscriptItems_[iter_114_0]
		end
	end
end

function var_0_3.getInscriptItems(arg_115_0)
	return arg_115_0.inscriptItems_ or {}
end

function var_0_3.setInscriptItem(arg_116_0, arg_116_1)
	if not arg_116_0.inscriptItems_ then
		arg_116_0.inscriptItems_ = {}
	end

	for iter_116_0 = 1, #arg_116_0.inscriptItems_ do
		if var_0_2.tables.inscription:itemType(var_0_2.tables.item:inscriptId(arg_116_0.inscriptItems_[iter_116_0])) == var_0_2.tables.inscription:itemType(arg_116_1) then
			arg_116_0.inscriptItems_[iter_116_0] = arg_116_1

			return
		end
	end

	table.insert(arg_116_0.inscriptItems_, arg_116_1)
end

function var_0_3.setInscriptItems(arg_117_0, arg_117_1)
	arg_117_0.inscriptItems_ = arg_117_1
end

function var_0_3.updatePracticeAwardAttr(arg_118_0)
	local var_118_0 = var_0_8:getPracticeNeeds(arg_118_0:getTableID())
	local var_118_1 = var_0_8:getPracticeAttrType(arg_118_0:getTableID())
	local var_118_2 = var_0_8:getPracticeAttrValue(arg_118_0:getTableID())

	if #var_118_0 ~= 3 or #var_118_1 ~= 3 or #var_118_2 ~= 3 then
		return
	end

	arg_118_0.practiceAwardAttrs = {}

	for iter_118_0 = 1, #var_118_0 do
		if arg_118_0.practice_attr_[iter_118_0] >= var_118_0[iter_118_0] then
			arg_118_0.practiceAwardAttrs[var_118_1[iter_118_0]] = (arg_118_0.practiceAwardAttrs[var_118_1[iter_118_0]] or 0) + var_118_2[iter_118_0]
		end
	end
end

function var_0_3.getTotalPracticeAttr(arg_119_0, arg_119_1)
	return arg_119_0:getPracticeAwardAttr(arg_119_1) + arg_119_0:getPracticeAttr(arg_119_1)
end

function var_0_3.getPracticeAwardAttr(arg_120_0, arg_120_1)
	if not arg_120_0.practiceAwardAttrs then
		return 0
	end

	return arg_120_0.practiceAwardAttrs[arg_120_1] or 0
end

function var_0_3.getJinjieEquipAttr(arg_121_0, arg_121_1)
	local var_121_0 = 0

	for iter_121_0 = 1, arg_121_0:getColor() - 1 do
		local var_121_1 = arg_121_0:getEquipList(iter_121_0)

		for iter_121_1, iter_121_2 in pairs(var_121_1) do
			if var_0_11:isAwakenItem(iter_121_2:getTableID()) == 0 then
				var_121_0 = var_121_0 + arg_121_0:getEquipAttrByType(arg_121_1, iter_121_2)
			end
		end
	end

	return var_121_0
end

function var_0_3.getEquipFumoAttr(arg_122_0, arg_122_1)
	local var_122_0 = arg_122_0:getEquipList(arg_122_0:getColor())
	local var_122_1 = 0

	for iter_122_0, iter_122_1 in ipairs(arg_122_0.equips_) do
		if iter_122_1 > 0 then
			if arg_122_0.fumoLev_ and next(arg_122_0.fumoLev_) then
				var_122_1 = var_122_1 + (var_122_0[iter_122_0]:getFumoByLevel(arg_122_0.fumoLev_[iter_122_0])[arg_122_1] or 0)
			else
				var_122_1 = var_122_1 + arg_122_0:getEquipFumoAttrByType(arg_122_1, var_122_0[iter_122_0])
			end
		end
	end

	return var_122_1
end

function var_0_3.getEquipList(arg_123_0, arg_123_1)
	if not arg_123_0.totalEquipList_ then
		local var_123_0 = var_0_8:equipList(arg_123_0:getTableID())

		arg_123_0.totalEquipList_ = {}

		for iter_123_0, iter_123_1 in ipairs(var_123_0) do
			local var_123_1 = {}

			for iter_123_2, iter_123_3 in ipairs(iter_123_1) do
				local var_123_2

				if var_0_11:isAwakenItem(iter_123_3) == 1 then
					if arg_123_0:awakeTwiceStage() > var_0_2.AwakeTwiceStage.STAGE_ONE then
						if not arg_123_0.awakeTwiceItem then
							var_123_2 = var_0_4.new()

							local var_123_3 = arg_123_0.fumo_[iter_123_2] or 0

							var_123_2:populate({
								item_id = iter_123_0 * 10 + iter_123_2,
								table_id = var_0_8:awakeTwiceItem(arg_123_0.tableID_),
								moneng = var_123_3
							})

							arg_123_0.awakeTwiceItem = var_123_2

							var_123_2:setStateCollected()
						else
							var_123_2 = arg_123_0.awakeTwiceItem
						end
					elseif not arg_123_0.awakeItem then
						var_123_2 = var_0_4.new()

						local var_123_4 = arg_123_0.fumo_[iter_123_2] or 0

						var_123_2:populate({
							item_id = iter_123_0 * 10 + iter_123_2,
							table_id = iter_123_3,
							moneng = var_123_4
						})

						arg_123_0.awakeItem = var_123_2

						if arg_123_0.equips_[iter_123_2] and arg_123_0.equips_[iter_123_2] > 0 and iter_123_0 <= arg_123_0:getColor() then
							var_123_2:setStateCollected()
						end
					else
						var_123_2 = arg_123_0.awakeItem
					end
				else
					var_123_2 = var_0_4.new()

					local var_123_5 = iter_123_0 == arg_123_0:getColor() and arg_123_0.fumo_[iter_123_2] or 0

					var_123_2:populate({
						item_id = iter_123_0 * 10 + iter_123_2,
						table_id = iter_123_3,
						moneng = var_123_5
					})

					if iter_123_0 == arg_123_0:getColor() and arg_123_0.equips_[iter_123_2] and arg_123_0.equips_[iter_123_2] > 0 then
						var_123_2:setStateCollected()
					end
				end

				table.insert(var_123_1, var_123_2)
			end

			table.insert(arg_123_0.totalEquipList_, var_123_1)
		end
	end

	return arg_123_0.totalEquipList_[arg_123_1]
end

function var_0_3.isAwakeTwice(arg_124_0)
	return arg_124_0.awakeTwiceStage_ == var_0_2.AwakeTwiceStage.COMPLETE
end

function var_0_3.awakeTwiceStage(arg_125_0)
	return arg_125_0.awakeTwiceStage_ or 0
end

function var_0_3.updateFumo(arg_126_0, arg_126_1, arg_126_2)
	arg_126_0:getEquipList(arg_126_0:getColor())[arg_126_2].moneng_ = arg_126_1
	arg_126_0.fumo_[arg_126_2] = arg_126_1
end

function var_0_3.getEquipByIndex(arg_127_0, arg_127_1, arg_127_2)
	return arg_127_0:getEquipList(arg_127_2 or arg_127_0:getColor())[arg_127_1]
end

function var_0_3.getEquipByIndexShow(arg_128_0, arg_128_1, arg_128_2)
	arg_128_2 = arg_128_2 or arg_128_0:getColor()

	local var_128_0 = arg_128_0:getEquipList(arg_128_2)[arg_128_1]

	if var_128_0:getTableID() > 0 and var_0_11:isAwakenItem(var_128_0:getTableID()) > 0 and arg_128_0.awakeTwiceStage_ > var_0_2.AwakeTwiceStage.UNSTART then
		var_128_0 = var_0_4.new()

		var_128_0:populate({
			item_id = arg_128_2 * 10 + arg_128_1,
			table_id = var_0_8:awakeTwiceItem(arg_128_0.tableID_)
		})
	end

	return var_128_0
end

function var_0_3.getItemHeroHasNotEquip(arg_129_0, arg_129_1)
	local var_129_0 = arg_129_0:getEquipList(arg_129_0:getColor())

	for iter_129_0, iter_129_1 in pairs(var_129_0) do
		if iter_129_1:getTableID() == arg_129_1 and not iter_129_1:isCollected() then
			return true
		end
	end

	return false
end

function var_0_3.getEquipAttrByType(arg_130_0, arg_130_1, arg_130_2)
	return arg_130_2:getAttr()[arg_130_1] or 0
end

function var_0_3.getEquipFumoAttrByType(arg_131_0, arg_131_1, arg_131_2)
	return arg_131_2:getFumoAttr()[arg_131_1] or 0
end

function var_0_3.getEquipFumoAttrByLevel(arg_132_0, arg_132_1, arg_132_2, arg_132_3)
	return arg_132_2:getFumoByLevel(arg_132_3)[arg_132_1] or 0
end

function var_0_3.getDes(arg_133_0)
	return var_0_8:getDes(arg_133_0:getTableID())
end

function var_0_3.getTalkText(arg_134_0)
	return var_0_8:getTalkText(arg_134_0:getTableID())
end

function var_0_3.getSkillId(arg_135_0, arg_135_1)
	if arg_135_1 then
		if next(arg_135_0.selfSkillIDs_) then
			return clone(arg_135_0.selfSkillIDs_[arg_135_1])
		else
			return var_0_8:getSkill(arg_135_0:getTableID(), arg_135_1)
		end
	elseif next(arg_135_0.selfSkillIDs_) then
		return clone(arg_135_0.selfSkillIDs_)
	else
		return var_0_8:getSkill(arg_135_0:getTableID())
	end
end

function var_0_3.getCircle(arg_136_0)
	local var_136_0 = var_0_0.clone(var_0_8:circle(arg_136_0:getTableID()))

	if #var_0_8:getSkillTable(arg_136_0:getTableID(), 1) > 1 then
		return arg_136_0:changeQueueSkill(var_136_0)
	else
		return var_136_0
	end
end

function var_0_3.getStartCircle(arg_137_0)
	local var_137_0 = var_0_0.clone(var_0_8:startCircle(arg_137_0:getTableID()))

	if #var_0_8:getSkillTable(arg_137_0:getTableID(), 1) > 1 then
		return arg_137_0:changeQueueSkill(var_137_0)
	else
		return var_137_0
	end
end

function var_0_3.changeQueueSkill(arg_138_0, arg_138_1)
	local var_138_0 = {}
	local var_138_1 = var_0_8:pugong(arg_138_0:getTableID())

	for iter_138_0, iter_138_1 in ipairs(arg_138_1) do
		local var_138_2

		if iter_138_1 == 0 then
			local var_138_3 = var_138_1

			table.insert(var_138_0, var_138_3)
		elseif arg_138_0:getSkillLevel(iter_138_1) and arg_138_0:getSkillLevel(iter_138_1) > 1 then
			local var_138_4 = arg_138_0:getSkillId(iter_138_1)

			if var_0_9:type(var_138_4) == var_0_2.AttackType.None then
				table.insert(var_138_0, var_138_1)
			else
				table.insert(var_138_0, var_138_4)
			end
		end
	end

	return var_138_0
end

function var_0_3.getExtraSkillLevel(arg_139_0)
	return arg_139_0:getEquipAttr(var_0_2.AttributeType.ADD_SKILL) + arg_139_0:getJinjieEquipAttr(var_0_2.AttributeType.ADD_SKILL) + arg_139_0:getSkillBookAttr(var_0_2.AttributeType.ADD_SKILL) + arg_139_0:getPracticeAwardAttr(var_0_2.AttributeType.ADD_SKILL) + arg_139_0:getInscriptionAttr(var_0_2.AttributeType.ADD_SKILL) + arg_139_0:getConquerSchoolAttr(var_0_2.AttributeType.ADD_SKILL) + arg_139_0:getCoursesAttr(var_0_2.AttributeType.ADD_SKILL) + arg_139_0:getWhiteAlbumAttr(var_0_2.AttributeType.ADD_SKILL)
end

function var_0_3.getBookShelfSkillLevel(arg_140_0)
	local var_140_0 = 0
	local var_140_1 = arg_140_0.bookshelfLev or 0

	if var_140_1 > 0 then
		var_140_0 = var_0_2.tables.bookShelfTable:upperLimit(var_140_1)
	end

	return var_140_0
end

function var_0_3.getBookShelfAttr(arg_141_0, arg_141_1)
	local var_141_0 = 0
	local var_141_1

	if not arg_141_0.bookshelfLev or arg_141_0.bookshelfLev == 0 then
		return 0
	else
		var_141_1 = arg_141_0.bookshelfLev
	end

	local var_141_2 = var_0_2.tables.bookShelfTable:attribute(var_141_1)

	if var_141_2[arg_141_1] then
		local var_141_3 = var_0_8:getHeroMainAttr(arg_141_0:getTableID(), arg_141_1, arg_141_0:getStar(), arg_141_0:getLevel())

		var_141_0 = var_141_2[arg_141_1] * 0.01 * var_141_3
	end

	return var_141_0
end

function var_0_3.getBookShelfForce(arg_142_0)
	local var_142_0 = 0

	for iter_142_0 = 1, 3 do
		var_142_0 = var_142_0 + arg_142_0:getBookShelfAttr(iter_142_0) * var_0_2.tables.attr:attrScore(iter_142_0)
	end

	return var_142_0
end

function var_0_3.getSkillLevel(arg_143_0, arg_143_1)
	if arg_143_1 then
		local var_143_0 = arg_143_0.skillLev_[arg_143_1]

		if isClient and type(var_143_0) == "number" and var_143_0 > var_0_2.MAX_SKILL_LEV then
			var_0_2.exitProgram()
		end

		return var_143_0
	else
		return arg_143_0.skillLev_
	end
end

function var_0_3.getSkillLevelByID(arg_144_0, arg_144_1)
	local var_144_0 = 0

	if arg_144_1 == var_0_8:pugong(arg_144_0:getTableID()) then
		var_144_0 = arg_144_0.level_
	else
		local var_144_1 = arg_144_0:getSkillId()

		for iter_144_0, iter_144_1 in ipairs(var_144_1) do
			if iter_144_1 == arg_144_1 then
				var_144_0 = arg_144_0:getSkillLevel(iter_144_0)

				break
			end
		end
	end

	if type(var_144_0) == "boolean" then
		return var_144_0
	end

	local var_144_2 = arg_144_0:getBookShelfSkillLevel()

	if var_144_0 > arg_144_0.level_ + var_144_2 then
		var_144_0 = arg_144_0.level_ + var_144_2
	end

	local var_144_3 = var_144_0 + arg_144_0:getExtraSkillLevel()

	if isClient and var_144_3 > var_0_2.MAX_SKILL_LEV then
		var_0_2.exitProgram()
	end

	return var_144_3
end

function var_0_3.skilllevelUp(arg_145_0, arg_145_1, arg_145_2)
	local var_145_0 = {
		partner_id = arg_145_0:getHeroID(),
		skill_index = arg_145_1
	}

	arg_145_0.selfPlayer:setSkillLevel(var_145_0, function(arg_146_0, arg_146_1)
		if arg_146_0 == var_0_2.error.OK then
			arg_145_0.skillLev_[arg_145_1] = math.min(arg_145_0.skillLev_[arg_145_1] + 1, arg_145_0.level_)

			if arg_145_2 then
				arg_145_2(arg_146_0, arg_146_1)
			end
		end
	end)
end

function var_0_3.evolution(arg_147_0, arg_147_1)
	local var_147_0 = {
		partner_id = arg_147_0:getHeroID(),
		hero = arg_147_0
	}

	arg_147_0.selfPlayer:evolveHero(var_147_0, function(arg_148_0, arg_148_1)
		if arg_148_0 == var_0_2.error.OK then
			arg_147_0.star_ = arg_147_0.star_ + 1

			if arg_147_0.star_ == var_0_2.HERO_TOTAL_STARS then
				var_0_2.EventDispatcher.get():dispatchEvent({
					name = var_0_2.event.CHECK_MIDDLE_RED_MARK,
					params = var_0_2.CheckMiddleRed.SUPER_PARTNER
				})
			end
		end

		arg_147_0.selfPlayer:checkSingleHeroAlbumNormal(arg_147_0)
		arg_147_0.selfPlayer:albumRedPointEvent()

		if arg_147_1 then
			arg_147_1(arg_148_0, arg_148_1)
		end
	end)
end

function var_0_3.powerUp(arg_149_0, arg_149_1)
	local var_149_0 = {
		partner_id = arg_149_0:getHeroID()
	}

	arg_149_0.selfPlayer:powerupHero(var_149_0, function(arg_150_0, arg_150_1)
		if arg_150_0 == var_0_2.error.OK then
			if arg_149_0:isInAwakingPeriod() or arg_149_0:isAwaken() then
				for iter_150_0 = 1, 6 do
					if arg_149_0:getEquipByIndex(iter_150_0):getTableID() > 0 and var_0_11:isAwakenItem(arg_149_0:getEquipByIndex(iter_150_0):getTableID()) == 0 and var_0_11:isAwakeTwiceItem(arg_149_0:getEquipByIndex(iter_150_0):getTableID()) == 0 then
						arg_149_0.equips_[iter_150_0] = 0
						arg_149_0.fumo_[iter_150_0] = 0
						arg_149_0.fumoLev_[iter_150_0] = 0
					end
				end
			else
				arg_149_0.equips_ = {
					0,
					0,
					0,
					0,
					0,
					0
				}
				arg_149_0.fumo_ = {
					0,
					0,
					0,
					0,
					0,
					0
				}
				arg_149_0.fumoLev_ = {
					0,
					0,
					0,
					0,
					0,
					0
				}
			end

			arg_149_0.color_ = arg_149_0.color_ + 1

			for iter_150_1 = 1, 6 do
				if arg_149_0.equips_[iter_150_1] == 1 then
					arg_149_0:getEquipByIndex(iter_150_1):setCollected()
				end
			end

			if arg_149_0.skillLev_[var_0_2.Color2Quality[arg_149_0.color_]] == false then
				if var_0_2.Color2Quality[arg_149_0.color_] == var_0_2.SKILL_INDEX.Green then
					arg_149_0.skillLev_[var_0_2.Color2Quality[arg_149_0.color_]] = 1 + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Green]
				elseif var_0_2.Color2Quality[arg_149_0.color_] == var_0_2.SKILL_INDEX.Blue then
					arg_149_0.skillLev_[var_0_2.Color2Quality[arg_149_0.color_]] = 1 + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Blue]
				elseif var_0_2.Color2Quality[arg_149_0.color_] == var_0_2.SKILL_INDEX.Purple then
					arg_149_0.skillLev_[var_0_2.Color2Quality[arg_149_0.color_]] = 1 + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Purple]
				end
			end

			arg_149_0.selfPlayer:checkSingleHeroAlbumNormal(arg_149_0)
			arg_149_0.selfPlayer:albumRedPointEvent()
		end

		if arg_149_1 then
			arg_149_1(arg_150_0, arg_150_1)
		end
	end)
end

function var_0_3.oneKeyPowerUp(arg_151_0, arg_151_1)
	local var_151_0 = {
		partner_id = arg_151_0:getHeroID()
	}

	arg_151_0.selfPlayer:oneKeyPowerUp(var_151_0, function(arg_152_0, arg_152_1)
		if arg_152_0 == var_0_2.error.OK then
			if arg_151_0.color_ < var_0_2.selfPlayer.maxHeroColor then
				if arg_151_0:isInAwakingPeriod() or arg_151_0:isAwaken() then
					for iter_152_0 = 1, 6 do
						if arg_151_0:getEquipByIndex(iter_152_0):getTableID() > 0 and var_0_11:isAwakenItem(arg_151_0:getEquipByIndex(iter_152_0):getTableID()) == 0 and var_0_11:isAwakeTwiceItem(arg_151_0:getEquipByIndex(iter_152_0):getTableID()) == 0 then
							arg_151_0.equips_[iter_152_0] = 0
							arg_151_0.fumo_[iter_152_0] = 0
							arg_151_0.fumoLev_[iter_152_0] = 0
						end
					end
				else
					arg_151_0.equips_ = {
						0,
						0,
						0,
						0,
						0,
						0
					}
					arg_151_0.fumo_ = {
						0,
						0,
						0,
						0,
						0,
						0
					}
					arg_151_0.fumoLev_ = {
						0,
						0,
						0,
						0,
						0,
						0
					}
				end

				arg_151_0.color_ = arg_151_0.color_ + 1

				for iter_152_1 = 1, 6 do
					if arg_151_0.equips_[iter_152_1] == 1 then
						arg_151_0:getEquipByIndex(iter_152_1):setCollected()
					end
				end

				if arg_151_0.skillLev_[var_0_2.Color2Quality[arg_151_0.color_]] == false then
					if var_0_2.Color2Quality[arg_151_0.color_] == var_0_2.SKILL_INDEX.Green then
						arg_151_0.skillLev_[var_0_2.Color2Quality[arg_151_0.color_]] = 1 + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Green]
					elseif var_0_2.Color2Quality[arg_151_0.color_] == var_0_2.SKILL_INDEX.Blue then
						arg_151_0.skillLev_[var_0_2.Color2Quality[arg_151_0.color_]] = 1 + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Blue]
					elseif var_0_2.Color2Quality[arg_151_0.color_] == var_0_2.SKILL_INDEX.Purple then
						arg_151_0.skillLev_[var_0_2.Color2Quality[arg_151_0.color_]] = 1 + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Purple]
					end
				end
			else
				local var_152_0 = var_0_8:equipList(arg_151_0:getTableID())[arg_151_0.color_]

				for iter_152_2 = 1, #var_152_0 do
					if var_152_0[iter_152_2] > 0 and var_0_11:isAwakenItem(var_152_0[iter_152_2]) == 0 then
						arg_151_0.equips_[iter_152_2] = 1

						arg_151_0:getEquipByIndex(iter_152_2):setCollected()
					end
				end
			end

			arg_151_0.selfPlayer:checkSingleHeroAlbumNormal(arg_151_0)
			arg_151_0.selfPlayer:albumRedPointEvent()
		end

		if arg_151_1 then
			arg_151_1(arg_152_0, arg_152_1)
		end
	end)
end

function var_0_3.oneKeyEquip(arg_153_0, arg_153_1, arg_153_2)
	local var_153_0 = {
		partner_id = arg_153_0:getHeroID()
	}

	arg_153_0.selfPlayer:oneKeyEquip(var_153_0, function(arg_154_0, arg_154_1)
		if arg_154_0 == var_0_2.error.OK and arg_154_1 and arg_154_1.equips then
			local var_154_0 = arg_154_1.equips

			for iter_154_0, iter_154_1 in ipairs(var_154_0) do
				arg_153_0.equips_[iter_154_0] = iter_154_1

				if iter_154_1 == 1 then
					arg_153_0:getEquipByIndex(iter_154_0):setCollected()
				end
			end
		end

		if arg_153_2 then
			arg_153_2(arg_154_0, arg_154_1)
		end
	end)
end

function var_0_3.getSpeed(arg_155_0)
	return var_0_8:speed(arg_155_0:getTableID())
end

function var_0_3.getHeroModel(arg_156_0)
	local var_156_0 = var_0_2.HeroAnimation.new(arg_156_0:getTableID(), arg_156_0:getModelID(), var_0_10:uiScale(arg_156_0:getModelID()), {})

	if var_156_0 then
		var_156_0:idle()
	end

	return var_156_0
end

function var_0_3.equipItems(arg_157_0, arg_157_1, arg_157_2)
	if not arg_157_0:isHasItem(arg_157_1) then
		if arg_157_2 then
			arg_157_2()
		end

		return
	end

	local var_157_0 = {
		partner_id = arg_157_0:getHeroID(),
		equip_index = arg_157_1
	}

	if not var_157_0.partner_id or not var_157_0.equip_index then
		if arg_157_2 then
			arg_157_2()
		end

		return
	end

	var_0_2.Backend.get():request(var_0_2.mid.SET_HERO_EQUIP, var_157_0, function(arg_158_0, arg_158_1, arg_158_2)
		if arg_158_0 == var_0_2.error.OK or tonumber(arg_158_1.error_code or 0) == 30001 then
			arg_157_0.equips_[arg_157_1] = 1

			arg_157_0:getEquipByIndex(arg_157_1):setCollected()
			var_0_2.EventDispatcher.get():dispatchEvent({
				name = var_0_2.event.HERO_EQUIP_CHANGED,
				index = arg_157_1
			})

			local var_158_0 = arg_157_0.selfPlayer:getBackpack()
			local var_158_1 = arg_157_0:getEquipByIndex(arg_157_1)
			local var_158_2 = {
				itemID = var_158_1:getTableID()
			}

			var_158_2.itemNum = 1

			var_158_0:removeItem(var_158_2)
		end

		if arg_158_1.error_code == 30001 then
			local var_158_3 = var_0_2.tables.message:getContent(30001)

			var_0_2.WindowManager.get():openWindow("toast", {
				message = var_158_3
			})
		end

		if arg_157_2 then
			arg_157_2(arg_158_0, arg_158_1)
		end
	end)
end

function var_0_3.isHasItem(arg_159_0, arg_159_1)
	return arg_159_0:getEquipByIndexShow(arg_159_1):isInBackpack()
end

function var_0_3.canComposeItem(arg_160_0, arg_160_1)
	return arg_160_0:getEquipByIndexShow(arg_160_1):isHasMaterial()
end

function var_0_3.canEquipItem(arg_161_0, arg_161_1)
	local var_161_0 = arg_161_0:getEquipByIndex(arg_161_1)

	if not var_161_0:isCollected() and var_161_0:isInBackpack() and arg_161_0:getLevel() >= var_161_0:getLevel() then
		return true
	elseif not var_161_0:isCollected() and var_161_0:isInBackpack() and arg_161_0:getLevel() < var_161_0:getLevel() then
		return false
	elseif not var_161_0:isCollected() and not var_161_0:isInBackpack() and var_161_0:isHasMaterial() and arg_161_0:getLevel() >= var_161_0:getLevel() then
		return true
	elseif not var_161_0:isCollected() and not var_161_0:isInBackpack() and var_161_0:isHasMaterial() and arg_161_0:getLevel() < var_161_0:getLevel() then
		return false
	end

	return false
end

function var_0_3.setExp(arg_162_0, arg_162_1, arg_162_2)
	local var_162_0 = arg_162_0:getLevel()
	local var_162_1 = var_0_2.tables.partnerExp:totalExp(var_162_0)
	local var_162_2 = var_0_2.tables.partnerExp:totalExp(arg_162_2)

	arg_162_0.exp_ = math.min(arg_162_1, var_162_2)

	if var_162_1 <= arg_162_0.exp_ then
		arg_162_0:setLevel(arg_162_0.exp_, var_162_0, arg_162_2)
	end
end

function var_0_3.addExp(arg_163_0, arg_163_1, arg_163_2)
	local var_163_0 = arg_163_0:getLevel()
	local var_163_1 = var_0_2.tables.partnerExp:totalExp(var_163_0)
	local var_163_2 = var_0_2.tables.partnerExp:totalExp(arg_163_2)

	arg_163_0.exp_ = math.min(arg_163_0.exp_ + arg_163_1, var_163_2)

	if var_163_1 <= arg_163_0.exp_ then
		arg_163_0:setLevel(arg_163_0.exp_, var_163_0, arg_163_2)
	end
end

function var_0_3.setLevel(arg_164_0, arg_164_1, arg_164_2, arg_164_3)
	local var_164_0 = arg_164_2

	for iter_164_0 = arg_164_2, arg_164_3 do
		if arg_164_1 >= var_0_2.tables.partnerExp:totalExp(iter_164_0) then
			var_164_0 = math.min(iter_164_0 + 1, arg_164_3)
		else
			break
		end
	end

	arg_164_0.level_ = var_164_0
end

function var_0_3.stoneSummonHero(arg_165_0, arg_165_1)
	local var_165_0 = {
		table_id = arg_165_0:getTableID(),
		stone = arg_165_0:getSuiPianID(),
		stone_num = var_0_2.TotalStarSuipian[arg_165_0:getStar()]
	}

	arg_165_0.selfPlayer:stoneSummonHero(var_165_0, arg_165_1)
end

function var_0_3.getAttrRates(arg_166_0)
	return var_0_8:attrRates(arg_166_0:getTableID())
end

function var_0_3.getFumoCount(arg_167_0)
	local var_167_0 = arg_167_0.fumo_
	local var_167_1 = 0

	for iter_167_0 = 1, #var_167_0 do
		var_167_1 = var_167_1 + tonumber(var_167_0[iter_167_0])
	end

	return var_167_1
end

function var_0_3.getWithoutAwakeFumoCount(arg_168_0)
	local var_168_0 = arg_168_0.fumo_
	local var_168_1 = 0

	for iter_168_0 = 1, #var_168_0 do
		if arg_168_0:getEquipByIndex(iter_168_0):getTableID() > 0 and var_0_11:isAwakenItem(arg_168_0:getEquipByIndex(iter_168_0):getTableID()) == 0 then
			var_168_1 = var_168_1 + tonumber(var_168_0[iter_168_0])
		end
	end

	return var_168_1
end

function var_0_3.setReportData(arg_169_0, arg_169_1)
	arg_169_0.fighterReport_ = arg_169_1
end

function var_0_3.getReportData(arg_170_0)
	return arg_170_0.fighterReport_
end

function var_0_3.isAwaken(arg_171_0)
	return var_0_8:beforeAwaken(arg_171_0:getTableID()) > 0
end

function var_0_3.isCanAwaken(arg_172_0)
	return var_0_8:isCanAwaken(arg_172_0:getTableID()) > 0
end

function var_0_3.canOpenAwakeTwiceMission(arg_173_0)
	return arg_173_0:awakeTwiceStage() == var_0_2.AwakeTwiceStage.UNSTART and var_0_8:isCanAwakeTwice(arg_173_0:getTableID()) > 0 and arg_173_0:isAwaken() and arg_173_0.level_ >= var_0_2.tables.misc.awakeTwiceOpenLev and arg_173_0.color_ >= var_0_2.tables.misc.awakeTwiceOpenQua
end

function var_0_3.isCanAwakeTwice(arg_174_0)
	return var_0_8:isCanAwakeTwice(arg_174_0:getTableID()) > 0
end

function var_0_3.isCanBloodAwake(arg_175_0)
	if arg_175_0:afterAwakenID() ~= 0 then
		return var_0_8:isCanAwakeTwice(arg_175_0:afterAwakenID()) > 0
	else
		return var_0_8:isCanAwakeTwice(arg_175_0:getTableID()) > 0
	end
end

function var_0_3.getAwakenType(arg_176_0)
	if arg_176_0:isCanBloodAwake() then
		return 2
	elseif arg_176_0:isCanAwaken() and not arg_176_0:isCanBloodAwake() then
		return 1
	else
		return 3
	end
end

function var_0_3.isInAwakingPeriod(arg_177_0)
	if arg_177_0:getEquipList(arg_177_0:getColor()) and next(arg_177_0:getEquipList(arg_177_0:getColor())) then
		for iter_177_0, iter_177_1 in pairs(arg_177_0:getEquipList(arg_177_0:getColor())) do
			if (var_0_11:isAwakenItem(iter_177_1:getTableID()) == 1 or iter_177_1:getTableID() == 0) and not arg_177_0:isAwaken() then
				return true
			end
		end
	end

	return false
end

function var_0_3.isHaveAwakenItem(arg_178_0)
	if arg_178_0:getEquipList(arg_178_0:getColor()) and next(arg_178_0:getEquipList(arg_178_0:getColor())) then
		for iter_178_0, iter_178_1 in pairs(arg_178_0:getEquipList(arg_178_0:getColor())) do
			if iter_178_1 and (var_0_11:isAwakenItem(iter_178_1:getTableID()) == 1 or iter_178_1 == 0) then
				return true
			end
		end
	end

	return false
end

function var_0_3.updateSkinInfo(arg_179_0)
	if arg_179_0.skinId_ and arg_179_0.skinId_ ~= 0 then
		arg_179_0.isSkinOn_ = 1
	else
		arg_179_0.isSkinOn_ = 0
	end

	if arg_179_0.skinIds_ and next(arg_179_0.skinIds_) then
		arg_179_0.hasSkin_ = 1
	else
		arg_179_0.hasSkin_ = 0
	end
end

function var_0_3.setSkinInfo(arg_180_0, arg_180_1, arg_180_2, arg_180_3)
	arg_180_0.skinId_ = arg_180_1
	arg_180_0.illusionSkinId_ = arg_180_3 or arg_180_0.illusionSkinId_

	if arg_180_2 and next(arg_180_2) then
		arg_180_0:apartSkinIds(arg_180_2)
	end

	arg_180_0:updateSkinInfo()
end

function var_0_3.setTableID(arg_181_0, arg_181_1)
	arg_181_0.tableID_ = arg_181_1
end

function var_0_3.isLastColorHasAwakeItem(arg_182_0)
	local var_182_0 = arg_182_0:getColor() - 1

	if var_182_0 <= 0 then
		return false
	end

	local var_182_1 = var_0_8:equipList(arg_182_0:getTableID())

	for iter_182_0, iter_182_1 in pairs(var_182_1[var_182_0]) do
		if iter_182_1 == 0 or var_0_11:isAwakenItem(iter_182_1) == 1 then
			return true
		end
	end

	return false
end

function var_0_3.isBoardHero(arg_183_0)
	if arg_183_0.isBoard and arg_183_0.isBoard > 0 then
		return true
	end

	return false
end

function var_0_3.skillBook(arg_184_0)
	return arg_184_0.skill_book_ or {}
end

function var_0_3.setIsBoardHero(arg_185_0, arg_185_1)
	arg_185_0.isBoard = arg_185_1
end

function var_0_3.getBoardCard(arg_186_0)
	if arg_186_0.boardCard < 1 then
		arg_186_0.boardCard = 1
	end

	return arg_186_0.boardCard or 1, arg_186_0.boardModelID
end

function var_0_3.setBoardCard(arg_187_0, arg_187_1)
	arg_187_0.boardCard = arg_187_1 or 1
end

function var_0_3.getBoardModelID(arg_188_0)
	return arg_188_0.boardModelID or 0
end

function var_0_3.setBoardModelID(arg_189_0, arg_189_1)
	arg_189_0.boardModelID = arg_189_1
end

function var_0_3.isHeroMarried(arg_190_0)
	if arg_190_0.isMarried and arg_190_0.isMarried > 0 then
		return true
	end

	return false
end

function var_0_3.setMarried(arg_191_0)
	arg_191_0.isMarried = 1

	var_0_2.EventDispatcher.get():dispatchEvent({
		name = var_0_2.event.HERO_CELL_REFRESH,
		tableID = arg_191_0:getTableID()
	})
end

function var_0_3.getFavorDegree(arg_192_0)
	return arg_192_0.favorDegree or 0
end

function var_0_3.setFavorDegree(arg_193_0, arg_193_1)
	local var_193_0 = var_0_2.ModelManager.get():loadModel(var_0_2.ModelType.SELF_PLAYER):getHeroByID(arg_193_0:getHeroID())

	if var_193_0 then
		var_193_0.favorDegree = arg_193_1 or 0
	end

	arg_193_0.favorDegree = arg_193_1 or 0

	var_0_2.EventDispatcher.get():dispatchEvent({
		name = var_0_2.event.HERO_CELL_REFRESH,
		tableID = arg_193_0:getTableID()
	})
end

function var_0_3.getFavorState(arg_194_0)
	local var_194_0

	if not var_0_8:isOpenDialog(arg_194_0:getTableID()) then
		var_194_0 = var_0_2.FavorState.NOT_OPEN
	elseif arg_194_0:isHeroMarried() then
		var_194_0 = var_0_2.FavorState.MARRIED
	elseif arg_194_0:getFavorDegree() >= var_0_2.tables.misc.libraryFavorLimit then
		var_194_0 = var_0_2.FavorState.FULL
	else
		var_194_0 = var_0_2.FavorState.NOT_FULL
	end

	return var_194_0
end

function var_0_3.getFeedAttrs(arg_195_0)
	return arg_195_0.feedAttrs or {}
end

function var_0_3.setFeedAttrs(arg_196_0, arg_196_1)
	local var_196_0 = var_0_2.ModelManager.get():loadModel(var_0_2.ModelType.SELF_PLAYER):getHeroByID(arg_196_0:getHeroID())

	if var_196_0 then
		var_196_0.feedAttrs = arg_196_1
	end

	arg_196_0.feedAttrs = arg_196_1
end

function var_0_3.isInscriptionOpen(arg_197_0)
	if arg_197_0:isAwakeTwice() and arg_197_0.level_ >= var_0_2.tables.functionOpen:level(var_0_2.FunctionID.ID_INSCRIPTION) then
		return true
	end

	return false
end

function var_0_3.getCoursesInfo(arg_198_0)
	return arg_198_0.coursesInfo or {}
end

function var_0_3.getEqupedCoursesInfo(arg_199_0)
	local var_199_0 = {}

	for iter_199_0, iter_199_1 in pairs(arg_199_0.coursesInfo) do
		if iter_199_1.add_skill and iter_199_1.add_skill > 0 then
			var_199_0[iter_199_0] = iter_199_1
		end
	end

	return var_199_0
end

function var_0_3.setCourseInfo(arg_200_0, arg_200_1, arg_200_2)
	arg_200_0.coursesInfo[tonumber(arg_200_2)] = arg_200_1
end

function var_0_3.getCourseInfo(arg_201_0, arg_201_1)
	return arg_201_0.coursesInfo[tonumber(arg_201_1)]
end

function var_0_3.setCoursesInfo(arg_202_0, arg_202_1)
	arg_202_0.coursesInfo = {}

	for iter_202_0, iter_202_1 in pairs(arg_202_1) do
		arg_202_0.coursesInfo[tonumber(iter_202_0)] = iter_202_1
	end
end

function var_0_3.getCourseSkills(arg_203_0)
	local var_203_0 = arg_203_0:getSkillId()
	local var_203_1 = {}

	for iter_203_0, iter_203_1 in pairs(arg_203_0.skillLev_) do
		local var_203_2 = var_203_0[iter_203_0]

		if iter_203_1 and var_203_2 > 0 and var_0_2.tables.skillLevel:bookOpen(iter_203_0) == 1 then
			var_203_1[iter_203_0] = var_203_2
		end
	end

	return var_203_1
end

function var_0_3.canApplyCourse(arg_204_0)
	local var_204_0 = arg_204_0:getCourseSkills()

	if #table.keys(arg_204_0.coursesInfo or {}) >= #var_204_0 then
		return false
	else
		return true
	end
end

function var_0_3.getSkillCourseId(arg_205_0, arg_205_1)
	local var_205_0 = arg_205_0:getSkillId()

	for iter_205_0, iter_205_1 in pairs(arg_205_0.coursesInfo or {}) do
		local var_205_1 = iter_205_1.add_skill

		if var_205_1 and var_205_1 > 0 and var_205_0[var_205_1] == arg_205_1 then
			return tonumber(iter_205_0)
		end
	end
end

function var_0_3.getSkillIDByIndex(arg_206_0, arg_206_1)
	return arg_206_0.skillIDs_[arg_206_1]
end

function var_0_3.setSkillIDByIndex(arg_207_0, arg_207_1, arg_207_2)
	arg_207_0.selfSkillIDs_[arg_207_1] = arg_207_2
	arg_207_0.skillIDs_[arg_207_1] = arg_207_2
end

function var_0_3.setHouseInfo(arg_208_0, arg_208_1)
	arg_208_0.houseId = arg_208_1.house_id
	arg_208_0.houseTableId = arg_208_1.house_table_id
	arg_208_0.houseComfort = arg_208_1.house_comfort

	if arg_208_1.house_expand_lev then
		arg_208_0.houseExpandLev = arg_208_1.house_expand_lev
	end

	if arg_208_1.house_equips then
		arg_208_0:setHouseEquips(arg_208_1.house_equips)
	end
end

function var_0_3.getHouseInfo(arg_209_0)
	return {
		house_id = arg_209_0.houseId,
		house_table_id = arg_209_0.houseTableId,
		houseComfort = arg_209_0.houseComfort
	}
end

function var_0_3.getHouseEquipsList(arg_210_0, arg_210_1)
	local var_210_0 = {}

	for iter_210_0 = 1, arg_210_1 do
		table.insert(var_210_0, arg_210_0:getDormEquipItemByIndex(iter_210_0))
	end

	return var_210_0
end

function var_0_3.getHouseEquips(arg_211_0)
	return arg_211_0.houseEquips or {}
end

function var_0_3.setHouseEquips(arg_212_0, arg_212_1)
	arg_212_0.houseEquips = arg_212_1
end

function var_0_3.setHouseEquip(arg_213_0, arg_213_1, arg_213_2)
	arg_213_0.houseEquips[arg_213_1] = arg_213_2
end

function var_0_3.getDormItemList(arg_214_0)
	if not arg_214_0.dormItems then
		arg_214_0.dormItems = var_0_8:dormItem(arg_214_0:getFirstTableID())
	end

	return arg_214_0.dormItems
end

function var_0_3.getDormEquipItemByIndex(arg_215_0, arg_215_1)
	arg_215_0.houseEquipList = {}

	if not arg_215_0.houseEquipList[arg_215_1] then
		local var_215_0 = arg_215_0:getDormItemList()[arg_215_1]
		local var_215_1 = var_0_4.new()

		var_215_1:populate({
			table_id = var_215_0
		})

		if arg_215_0.houseEquips and arg_215_0.houseEquips[arg_215_1] and arg_215_0.houseEquips[arg_215_1] > 0 then
			var_215_1:setStateCollected()
		end

		arg_215_0.houseEquipList[arg_215_1] = var_215_1
	end

	return arg_215_0.houseEquipList[arg_215_1]
end

function var_0_3.getSkinDatas(arg_216_0)
	local var_216_0 = {}
	local var_216_1 = arg_216_0:getFirstTableID()
	local var_216_2 = var_0_2.tables.hero:afterAwaken(var_216_1)
	local var_216_3 = var_0_2.tables.hero:skinItem(var_216_1)
	local var_216_4 = arg_216_0.skinIds_
	local var_216_5 = var_0_2.tables.hero:skinHide(arg_216_0:getTableID())

	if var_216_1 > 0 then
		local var_216_6 = {
			modelID = var_0_2.tables.hero:modelID(var_216_1),
			isHave = arg_216_0:isCollected(),
			cardState = var_0_2.CardStatus.NORMAL_CARD
		}

		table.insert(var_216_0, var_216_6)
	end

	if var_216_2 > 0 and var_0_2.tables.hero:isCanAwaken(var_216_1) == 1 then
		local var_216_7 = {
			modelID = var_0_2.tables.hero:modelID(var_216_2)
		}

		var_216_7.isAwaken = true
		var_216_7.isHave = arg_216_0:isAwaken()
		var_216_7.cardState = var_0_2.CardStatus.AWAKE_CARD
		var_216_7.skinSkillID = var_0_2.tables.hero:getSkill(var_216_2, var_0_2.SKILL_INDEX.Awake)

		table.insert(var_216_0, var_216_7)
	end

	for iter_216_0 = 1, #var_216_3 do
		if var_216_3[iter_216_0] > 0 then
			local var_216_8 = {
				modelID = var_0_2.tables.skinSkill:getModelID(var_216_3[iter_216_0]),
				skinItem = var_216_3[iter_216_0]
			}

			var_216_8.skinSkillID = var_0_2.tables.skinSkill:getSkillID(var_216_8.skinItem)

			if var_0_2.isInTable(var_216_4, var_216_8.modelID) then
				var_216_8.isHave = true
			end

			var_216_8.cardState = var_0_2.CardStatus.SKIN_CARD

			table.insert(var_216_0, var_216_8)
		end
	end

	for iter_216_1 = #var_216_0, 1, -1 do
		local var_216_9 = var_216_0[iter_216_1]

		if not var_0_2.isInTable(var_216_4, var_216_9.modelID) and var_0_2.isInTable(var_216_5, var_216_9.skinItem) or var_0_11:skinLastTime(var_216_9.skinItem) > 0 then
			table.remove(var_216_0, iter_216_1)
		end
	end

	return var_216_0
end

function var_0_3.getEvoAttrPoints(arg_217_0)
	return arg_217_0.evoAttrPoints or {}
end

function var_0_3.getEvoStage(arg_218_0)
	return arg_218_0.evoStage or 1
end

function var_0_3.setEvoInfo(arg_219_0, arg_219_1)
	if arg_219_1.evo_attr_points then
		arg_219_0.evoAttrPoints = arg_219_1.evo_attr_points
	end

	if arg_219_1.evo_stage then
		arg_219_0.evoStage = arg_219_1.evo_stage
	end
end

function var_0_3.setEvoStage(arg_220_0, arg_220_1)
	arg_220_0.evoStage = arg_220_1 or 1
end

function var_0_3.getHeroVoiceState(arg_221_0)
	local var_221_0
	local var_221_1

	if arg_221_0.isCollected_ then
		var_221_0 = {
			7,
			8,
			9,
			6,
			1,
			2,
			3,
			4,
			5
		}
		var_221_1 = {
			true,
			true,
			true,
			true,
			true
		}

		if arg_221_0.level_ >= 10 then
			var_221_1[6] = true
		end

		if arg_221_0:getFavorLev() >= 2 then
			var_221_1[7] = true
		end

		if var_0_2.Color2Quality[arg_221_0.color_] >= 4 then
			var_221_1[8] = true
		end

		if arg_221_0.star_ >= 3 then
			var_221_1[9] = true
		end
	else
		var_221_0 = {
			1,
			7,
			8,
			9,
			6,
			2,
			3,
			4,
			5
		}
		var_221_1 = {
			true
		}
	end

	return var_221_0, var_221_1
end

function var_0_3.isSuper(arg_222_0)
	return false
end

function var_0_3.getUnlockedDynamicCards(arg_223_0)
	return arg_223_0.unlockedDynamicCards or {}
end

function var_0_3.unlockDynamicCard(arg_224_0, arg_224_1, arg_224_2)
	local var_224_0 = {
		model_id = arg_224_1,
		partner_id = arg_224_0:getHeroID()
	}

	var_0_2.Backend.get():request(var_0_2.mid.UNLOCK_DYNAMIC_CARD, var_224_0, function(arg_225_0, arg_225_1)
		if arg_225_0 == var_0_2.error.OK then
			arg_224_0.unlockedDynamicCards = var_0_2.splitToNumber(arg_225_1.unlocked_dynamic_card or "", "|")
			arg_224_0.dynamicCardState = var_0_2.splitToNumber(arg_225_1.dynamic_card_state or "", "|")

			if arg_224_2 then
				arg_224_2()
			end
		end
	end)
end

function var_0_3.isUnlockDynamicCard(arg_226_0, arg_226_1)
	local var_226_0 = arg_226_0:getUnlockedDynamicCards()

	for iter_226_0 = 1, #var_226_0 do
		if var_226_0[iter_226_0] == arg_226_1 then
			return true
		end
	end

	return false
end

function var_0_3.getDynamicCardState(arg_227_0, arg_227_1)
	local var_227_0 = arg_227_0:getUnlockedDynamicCards()

	for iter_227_0 = 1, #var_227_0 do
		if var_227_0[iter_227_0] == arg_227_1 then
			return arg_227_0.dynamicCardState[iter_227_0]
		end
	end
end

function var_0_3.changeDynamicCardState(arg_228_0, arg_228_1, arg_228_2)
	local var_228_0 = arg_228_0:getUnlockedDynamicCards()
	local var_228_1
	local var_228_2

	for iter_228_0 = 1, #var_228_0 do
		if var_228_0[iter_228_0] == arg_228_1 then
			var_228_1 = iter_228_0
			var_228_2 = 1 - arg_228_0.dynamicCardState[iter_228_0]

			break
		end
	end

	if not var_228_1 then
		return
	end

	local var_228_3 = {
		model_id = arg_228_1,
		partner_id = arg_228_0:getHeroID(),
		is_show = var_228_2
	}

	var_0_2.Backend.get():request(var_0_2.mid.SHOW_DYNAMIC_CARD, var_228_3, function(arg_229_0, arg_229_1)
		if arg_229_0 == var_0_2.error.OK then
			arg_228_0.dynamicCardState[var_228_1] = var_228_2

			if arg_228_2 then
				arg_228_2()
			end
		end
	end)
end

function var_0_3.getEquipEnhanceAttr(arg_230_0, arg_230_1)
	local var_230_0 = 0
	local var_230_1 = arg_230_0:getEquipList(arg_230_0:getColor())

	for iter_230_0, iter_230_1 in pairs(var_230_1) do
		if arg_230_0.equips_[iter_230_0] and arg_230_0.equips_[iter_230_0] > 0 then
			var_230_0 = var_230_0 + arg_230_0:getEquipEnhanceAttrByType(arg_230_1, iter_230_1, arg_230_0.equips_[iter_230_0] - 1)
		end
	end

	return var_230_0
end

function var_0_3.getEquipEnhanceAttrByType(arg_231_0, arg_231_1, arg_231_2, arg_231_3)
	return arg_231_2:getEnhanceEquipAttrByLevel(arg_231_1, arg_231_3) or 0
end

function var_0_3.isSuper(arg_232_0)
	if arg_232_0.partnerType == var_0_2.PartnerType.SUPER then
		return true
	end

	return false
end

function var_0_3.getEquipLevel(arg_233_0, arg_233_1)
	return 0
end

function var_0_3.setAwakeTwiceStage(arg_234_0, arg_234_1)
	if not arg_234_1 or arg_234_1 < 0 then
		return
	end

	arg_234_0.awakeTwiceStage_ = arg_234_1

	if arg_234_0.awakeTwiceStage_ == var_0_2.AwakeTwiceStage.COMPLETE then
		arg_234_0.skillLev_[var_0_2.SKILL_INDEX.AwakeTwice] = var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.AwakeTwice]
	end
end

function var_0_3.canEnvolve(arg_235_0)
	if var_0_2.isSuperHero(arg_235_0) then
		if arg_235_0:getStar() <= var_0_2.MAX_STAR_LEVEL or arg_235_0:getStar() >= 8 or arg_235_0:getStar() > var_0_2.MAX_STAR_LEVEL and arg_235_0:getStar() < 8 and arg_235_0:getSuiPian() < var_0_2.StarLevelSuipian[arg_235_0:getStar() + 1] then
			return false
		end
	elseif arg_235_0:getStar() >= var_0_2.MAX_STAR_LEVEL or arg_235_0:getSuiPian() < var_0_2.StarLevelSuipian[arg_235_0:getStar() + 1] then
		return false
	end

	return true
end

function var_0_3.apartSkinIds(arg_236_0, arg_236_1)
	arg_236_0.skinIds_ = {}
	arg_236_0.timeLimitSkins = {}

	if arg_236_1 and next(arg_236_1) then
		local var_236_0 = false

		for iter_236_0, iter_236_1 in pairs(arg_236_1) do
			if type(iter_236_0) == "number" then
				var_236_0 = true

				break
			end

			if iter_236_1 == -1 then
				table.insert(arg_236_0.skinIds_, tonumber(iter_236_0))
			else
				arg_236_0.timeLimitSkins[iter_236_0] = iter_236_1
			end
		end

		if var_236_0 then
			arg_236_0.skinIds_ = arg_236_1
		end
	end

	if isClient and next(arg_236_0.timeLimitSkins) then
		if arg_236_0.timeLimitSkinsHandle then
			var_0_6.unscheduleGlobal(arg_236_0.timeLimitSkinsHandle)

			arg_236_0.timeLimitSkinsHandle = nil
		end

		arg_236_0.timeLimitSkinsHandle = var_0_6.scheduleGlobal(function()
			if display.getRunningScene().__cname == "MainScene" then
				if not next(arg_236_0.timeLimitSkins) then
					var_0_6.unscheduleGlobal(arg_236_0.timeLimitSkinsHandle)

					arg_236_0.timeLimitSkinsHandle = nil
				end

				local var_237_0 = var_0_2.ServerTime.get():getServerTime()

				for iter_237_0, iter_237_1 in pairs(arg_236_0.timeLimitSkins) do
					if iter_237_1 > 0 and iter_237_1 < var_237_0 then
						arg_236_0.timeLimitSkins[iter_237_0] = 0

						if tonumber(iter_237_0) == tonumber(arg_236_0.skinId_) then
							arg_236_0:setSkinInfo(0)

							local var_237_1 = {
								partner_id = arg_236_0:getHeroID()
							}

							var_0_2.Backend.get():request(var_0_2.mid.SKIN_CANCEL, var_237_1, function(arg_238_0, arg_238_1)
								if arg_238_0 == var_0_2.error.OK then
									-- block empty
								end
							end)

							local var_237_2 = {
								partner_id = arg_236_0:getHeroID()
							}

							var_237_2.item_id = 0

							var_0_2.Backend.get():request(var_0_2.mid.USE_ILLUSION_SKIN_ITEM, var_237_2, function(arg_239_0, arg_239_1)
								if arg_239_0 == var_0_2.error.OK then
									arg_236_0.illusionSkinId_ = 0
								end
							end)
						end
					end
				end
			end
		end, 5)
	end
end

function var_0_3.mergeSkinIds(arg_240_0)
	local var_240_0 = {}

	if arg_240_0.skinIds_ and next(arg_240_0.skinIds_) then
		for iter_240_0, iter_240_1 in ipairs(arg_240_0.skinIds_) do
			var_240_0[tostring(iter_240_1)] = -1
		end
	end

	if arg_240_0.timeLimitSkins and next(arg_240_0.timeLimitSkins) then
		for iter_240_2, iter_240_3 in ipairs(arg_240_0.timeLimitSkins) do
			var_240_0[tostring(iter_240_2)] = iter_240_3
		end
	end

	return var_240_0
end

function var_0_3.getTempSkinItemId(arg_241_0, arg_241_1)
	local var_241_0 = var_0_11:skinModel(arg_241_1)
	local var_241_1 = arg_241_0:getFirstTableID()
	local var_241_2 = var_0_2.tables.hero:skinItem(var_241_1)

	for iter_241_0 = 1, #var_241_2 do
		if var_241_2[iter_241_0] > 0 and var_0_11:skinModel(var_241_2[iter_241_0]) == var_241_0 and var_0_11:skinLastTime(var_241_2[iter_241_0]) > 0 then
			return var_241_2[iter_241_0]
		end
	end

	return 0
end

function var_0_3.getElementEquips(arg_242_0)
	if not arg_242_0.elementEquips_ and not arg_242_0.elementEquipsLevel_ and arg_242_0:getHeroID() == var_0_19 then
		arg_242_0.elementEquips_ = var_0_8:elementEquips(arg_242_0:getTableID())
		arg_242_0.elementEquipsLevel_ = var_0_8:elementEquipsLevel(arg_242_0:getTableID())
	end

	return arg_242_0.elementEquips_, arg_242_0.elementEquipsLevel_
end

function var_0_3.getElementBindingEquips(arg_243_0)
	return arg_243_0.elementBindingEquips_, arg_243_0.elementBindingEquipsLevel_
end

function var_0_3.getElementAttr(arg_244_0, arg_244_1)
	local var_244_0 = 0
	local var_244_1, var_244_2 = arg_244_0:getElementEquips()

	if var_244_1 then
		for iter_244_0 = 1, #var_244_1 do
			local var_244_3 = tonumber(var_244_1[iter_244_0])
			local var_244_4 = var_0_14:itemID(var_244_3)

			if var_244_3 ~= 0 and arg_244_1 == var_0_14:attr(var_244_4) then
				local var_244_5, var_244_6 = var_0_14:battleAttr(var_244_4, var_244_2[iter_244_0])

				var_244_0 = var_244_5 * arg_244_0:getElementEquipActiveRate(var_244_4)

				if var_244_4 == var_0_21 then
					var_244_0 = arg_244_0:getExclusiveElementAttr(arg_244_1, var_244_0)
				end

				return var_244_0
			end
		end
	end

	return var_244_0
end

function var_0_3.getElementAttrJustForShow(arg_245_0, arg_245_1)
	local var_245_0 = 0
	local var_245_1, var_245_2 = arg_245_0:getElementEquips()

	if var_245_1 then
		for iter_245_0 = 1, #var_245_1 do
			local var_245_3 = tonumber(var_245_1[iter_245_0])
			local var_245_4 = var_0_14:itemID(var_245_3)

			if var_245_3 ~= 0 and arg_245_1 == var_0_14:attr(var_245_4) then
				local var_245_5, var_245_6 = var_0_14:battleAttr(var_245_4, var_245_2[iter_245_0])

				var_245_0 = var_245_5 * arg_245_0:getElementEquipActiveRate(var_245_4)

				return var_245_0
			end
		end
	end

	return var_245_0
end

function var_0_3.getExclusiveElementAttr(arg_246_0, arg_246_1, arg_246_2)
	if arg_246_0:checkIsZhuge() then
		arg_246_0.zhugeBookSkillNum = arg_246_0:getZhugeBookSkillNum()
		arg_246_2 = arg_246_2 * arg_246_0.zhugeBookSkillNum
	end

	return arg_246_2
end

function var_0_3.getElementType(arg_247_0)
	local var_247_0 = arg_247_0:getElementEquips()

	if var_247_0 and var_247_0[var_0_2.ElementCoreIndex] then
		local var_247_1 = var_0_14:itemID(var_247_0[var_0_2.ElementCoreIndex])

		return (var_0_14:element(var_247_1))
	else
		return var_0_8:elementType(arg_247_0:getTableID())
	end
end

function var_0_3.getElementEquipActiveRate(arg_248_0, arg_248_1)
	local var_248_0 = var_0_14:element(arg_248_1)

	if var_0_14:equipType(arg_248_1) == var_0_2.ElementEquipType.NORMAL and var_248_0 == arg_248_0:getElementType() then
		if var_0_14:partnerID(arg_248_1) == arg_248_0:getFirstTableID() then
			return 1 + var_0_14:activeSP(arg_248_1)
		else
			return 1 + var_0_14:active(arg_248_1)
		end
	end

	return 1
end

function var_0_3.isActiveSP(arg_249_0)
	local var_249_0 = arg_249_0:getElementEquips()

	if var_249_0 and var_249_0[var_0_2.ElementCoreIndex] ~= 0 then
		local var_249_1 = var_0_14:itemID(var_249_0[var_0_2.ElementCoreIndex])

		return var_0_14:partnerID(var_249_1) == arg_249_0:getFirstTableID()
	end

	return false
end

function var_0_3.setSpiritEquips(arg_250_0, arg_250_1)
	arg_250_0.spiritEquip_ = arg_250_1

	if arg_250_0.spiritItems_ and isClient then
		for iter_250_0, iter_250_1 in ipairs(arg_250_0.spiritEquip_) do
			if iter_250_1 ~= 0 then
				local var_250_0 = arg_250_0.selfPlayer:getBackpack():getSpiritItemBySpiritID(iter_250_1)

				arg_250_0.spiritItems_[iter_250_0] = var_250_0
			else
				arg_250_0.spiritItems_[iter_250_0] = {}
			end
		end
	end
end

function var_0_3.getSpiritEquips(arg_251_0)
	return arg_251_0.spiritEquip_ or {}
end

function var_0_3.getSpiritSuitID(arg_252_0)
	local var_252_0 = arg_252_0:getSpiritEquips()

	arg_252_0.spiritSuit2_ = {}
	arg_252_0.spiritSuit4_ = 0

	local var_252_1 = {}

	for iter_252_0, iter_252_1 in ipairs(var_252_0) do
		if iter_252_1 ~= 0 then
			local var_252_2

			if isClient then
				if arg_252_0.spiritItems_ then
					var_252_2 = arg_252_0.spiritItems_[iter_252_0]
				else
					var_252_2 = arg_252_0.selfPlayer:getBackpack():getSpiritItemBySpiritID(iter_252_1)
				end
			elseif not arg_252_0.spiritItems_[iter_252_0] then
				var_252_2 = var_0_5:new(arg_252_0.playerID_, iter_252_1):get_info()
				arg_252_0.spiritItems_[iter_252_0] = var_252_2
			else
				var_252_2 = arg_252_0.spiritItems_[iter_252_0]
			end

			local var_252_3 = var_0_2.tables.spiritEquip:from(var_252_2.table_id)

			if not var_252_1[var_252_3] then
				var_252_1[var_252_3] = 1
			else
				var_252_1[var_252_3] = var_252_1[var_252_3] + 1
			end
		end
	end

	for iter_252_2, iter_252_3 in pairs(var_252_1) do
		if iter_252_3 >= 2 then
			table.insert(arg_252_0.spiritSuit2_, iter_252_2)
		end

		if iter_252_3 >= 4 then
			arg_252_0.spiritSuit4_ = iter_252_2
		end
	end

	return arg_252_0.spiritSuit2_, arg_252_0.spiritSuit4_
end

function var_0_3.getSpiritEquipsAttr(arg_253_0, arg_253_1)
	local var_253_0 = arg_253_0:getSpiritEquips()
	local var_253_1 = 0

	for iter_253_0, iter_253_1 in ipairs(var_253_0) do
		if iter_253_1 ~= 0 then
			local var_253_2

			if isClient then
				if arg_253_0.spiritItems_ then
					var_253_2 = arg_253_0.spiritItems_[iter_253_0]
				else
					var_253_2 = arg_253_0.selfPlayer:getBackpack():getSpiritItemBySpiritID(iter_253_1)
				end
			elseif not arg_253_0.spiritItems_[iter_253_0] then
				var_253_2 = var_0_5:new(arg_253_0.playerID_, iter_253_1):get_info()
				arg_253_0.spiritItems_[iter_253_0] = var_253_2
			else
				var_253_2 = arg_253_0.spiritItems_[iter_253_0]
			end

			local var_253_3 = var_253_2.table_id
			local var_253_4 = var_0_17:from(var_253_3)
			local var_253_5 = var_0_17:modelId(var_253_3)

			if var_0_16:main(var_253_5, var_253_2.main) == arg_253_1 then
				var_253_1 = var_253_1 + var_253_2.main_attr_value
			end

			if var_253_2.sub then
				for iter_253_2 = 1, #var_253_2.sub do
					local var_253_6 = var_253_2.sub[iter_253_2]

					if var_0_16:sub(var_253_5, var_253_6) == arg_253_1 then
						var_253_1 = var_253_1 + var_253_2.sub_attr_value[iter_253_2]
					end
				end
			end
		end
	end

	local var_253_7 = arg_253_0:getSpiritSuitID()

	for iter_253_3, iter_253_4 in ipairs(var_253_7) do
		local var_253_8 = var_0_18:attr2(iter_253_4)
		local var_253_9 = var_0_18:attr2Value(iter_253_4)

		if var_253_8 == arg_253_1 then
			var_253_1 = var_253_1 + var_253_9
		end
	end

	if arg_253_1 == var_0_2.AttributeType.HP then
		var_253_1 = var_253_1 * (1 + arg_253_0:getSpiritEquipsAttr(var_0_2.AttributeType.HUNQI_HP_BONUS) / var_0_2.DECIMAL_BASE)
	elseif arg_253_1 == var_0_2.AttributeType.AD or arg_253_1 == var_0_2.AttributeType.AP then
		var_253_1 = var_253_1 * (1 + arg_253_0:getSpiritEquipsAttr(var_0_2.AttributeType.HUNQI_AD_AP_BONUS) / var_0_2.DECIMAL_BASE)
	elseif arg_253_1 == var_0_2.AttributeType.HUJIA or arg_253_1 == var_0_2.AttributeType.MOKANG then
		var_253_1 = var_253_1 * (1 + arg_253_0:getSpiritEquipsAttr(var_0_2.AttributeType.HUNQI_JIAKANG_BONUS) / var_0_2.DECIMAL_BASE)
	end

	return var_253_1
end

function var_0_3.setCollocation(arg_254_0, arg_254_1, arg_254_2)
	local var_254_0 = {
		is_like = arg_254_1 or 1 - arg_254_0.isLike,
		partner_id = arg_254_0:getHeroID()
	}

	var_0_2.Backend.get():request(var_0_2.mid.HERO_COLLOCATION, var_254_0, function(arg_255_0, arg_255_1)
		if arg_255_0 == var_0_2.error.OK then
			arg_254_0.isLike = var_254_0.is_like
		end

		if arg_254_2 then
			arg_254_2(arg_255_0, arg_255_1)
		end
	end)
end

function var_0_3.isCollocation(arg_256_0)
	return arg_256_0.isLike and arg_256_0.isLike == 1
end

return var_0_3
