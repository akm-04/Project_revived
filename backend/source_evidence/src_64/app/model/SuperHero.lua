local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("SuperHero", import("app.model.Hero"))
local var_0_4 = isClient and var_0_0.import("app.model.Item") or var_0_0.import("lib.battle.app.model.Item")
local var_0_5

if not isClient then
	var_0_5 = require("lib.spirit.spirit_item")
end

local var_0_6 = var_0_2.tables.cabinetSkillTable
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_2.tables.dbuff
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

function var_0_3.ctor(arg_1_0)
	arg_1_0.heroID_ = var_0_19
	arg_1_0.playerID_ = 0
	arg_1_0.exp_ = 0
	arg_1_0.isPet_ = false
	arg_1_0.selfSkillIDs_ = {}
	arg_1_0.color_ = 1
	arg_1_0.partnerType = var_0_2.PartnerType.SUPER

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
	arg_2_0.star_ = arg_2_3.star or var_0_7:initialStar(arg_2_1)
	arg_2_0.level_ = arg_2_3.lev or 1
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
	arg_2_0.skillLev_[var_0_2.SKILL_INDEX.Green] = tonumber(var_2_0[var_0_2.SKILL_INDEX.Green]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Green]
	arg_2_0.skillLev_[var_0_2.SKILL_INDEX.Blue] = tonumber(var_2_0[var_0_2.SKILL_INDEX.Blue]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Blue]
	arg_2_0.skillLev_[var_0_2.SKILL_INDEX.Purple] = tonumber(var_2_0[var_0_2.SKILL_INDEX.Purple]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Purple]

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
	arg_3_0.partnerType = tonumber(arg_3_1.partner_type or 0)
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
				arg_3_0.selfSkillIDs_[iter_3_1] = var_0_7:getSkillTable(arg_3_0.tableID_, iter_3_1)[1] or 0
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
	arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Green] = tonumber(var_3_1[var_0_2.SKILL_INDEX.Green]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Green]
	arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Blue] = tonumber(var_3_1[var_0_2.SKILL_INDEX.Blue]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Blue]
	arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Purple] = tonumber(var_3_1[var_0_2.SKILL_INDEX.Purple]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Purple]

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
	arg_5_0.star_ = arg_5_2.star or var_0_7:initialStar(arg_5_1)
	arg_5_0.level_ = arg_5_2.level or var_0_7:level(arg_5_1)
	arg_5_0.equips_ = arg_5_2.equips or var_0_7:equip(arg_5_1) or {
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
	arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Green] = arg_5_0.level_
	arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Blue] = arg_5_0.level_
	arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Purple] = arg_5_0.level_

	if var_0_7:getSkill(arg_5_1, var_0_2.SKILL_INDEX.Awake) > 0 then
		arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Awake] = arg_5_0.level_
	else
		arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Awake] = false
	end

	if var_0_7:getSkill(arg_5_1, var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
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
		partner_type = arg_6_0.partnerType,
		unlocked_dynamic_card = var_0_2.catToString(arg_6_0.unlockedDynamicCards, "|"),
		dynamic_card_state = var_0_2.catToString(arg_6_0.dynamicCardState, "|")
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
		if arg_23_1 == var_0_6:attrIds(tonumber(iter_23_0)) then
			var_23_0 = var_23_0 + var_0_6:attrValues(tonumber(iter_23_0)) * iter_23_1
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
	return var_0_7:stoneID(arg_29_0:getTableID())
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
	return var_0_7:name(arg_34_0:getTableID())
end

function var_0_3.getSearchName(arg_35_0)
	return var_0_7:searchName(arg_35_0:getTableID())
end

function var_0_3.getHeroType(arg_36_0)
	return var_0_7:heroType(arg_36_0:getTableID())
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
		return var_0_7:modelID(arg_38_0:getFirstTableID())
	elseif arg_38_0.illusionSkinId_ == 1 then
		return var_0_7:modelID(arg_38_0:getTableID())
	else
		return arg_38_0.illusionSkinId_
	end
end

function var_0_3.getOldModelID(arg_39_0)
	if arg_39_0.isSkinOn_ == 1 then
		return arg_39_0.skinId_
	else
		return var_0_7:modelID(arg_39_0:getTableID())
	end
end

function var_0_3.getModelIDs(arg_40_0)
	return var_0_7:modelIDs(arg_40_0:getTableID())
end

function var_0_3.getDistanceType(arg_41_0)
	return var_0_7:distanceType(arg_41_0:getTableID())
end

function var_0_3.getDistance(arg_42_0)
	return var_0_7:distance(arg_42_0:getTableID())
end

function var_0_3.getFromType(arg_43_0)
	return var_0_7:from(arg_43_0:getTableID())
end

function var_0_3.getAddExp(arg_44_0)
	return var_0_12:addExp(arg_44_0:getLevel())
end

function var_0_3.isShow(arg_45_0)
	return var_0_7:isShow(arg_45_0:getTableID())
end

function var_0_3.enterDuration(arg_46_0)
	return var_0_8:enterDuration(arg_46_0:enterSkill())
end

function var_0_3.enterSpeed(arg_47_0)
	return var_0_8:enterSpeed(arg_47_0:enterSkill())
end

function var_0_3.enterDelayDuration(arg_48_0)
	return var_0_8:enterDelayDuration(arg_48_0:enterSkill())
end

function var_0_3.enterSkill(arg_49_0)
	return var_0_7:enterSkill(arg_49_0:getTableID())
end

function var_0_3.className(arg_50_0)
	return var_0_7:className(arg_50_0:getTableID())
end

function var_0_3.awakenID(arg_51_0)
	return var_0_7:awakenID(arg_51_0:getTableID())
end

function var_0_3.beforeAwakenID(arg_52_0)
	return var_0_7:beforeAwaken(arg_52_0:getTableID())
end

function var_0_3.afterAwakenID(arg_53_0)
	return var_0_7:afterAwaken(arg_53_0:getTableID())
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
		local var_56_3 = var_0_7:getInitialAttr(arg_56_0:getTableID(), iter_56_0)

		var_56_0 = var_56_0 + (var_56_1 + var_56_2 + var_56_3) * var_0_2.tables.attr:attrScore(iter_56_0)
	end

	for iter_56_1 = 4, var_0_2.AttributeType.TOTAL_ATTR_NUM do
		var_56_0 = var_56_0 + var_0_7:getInitialAttr(arg_56_0:getTableID(), iter_56_1) * var_0_2.tables.attr:attrScore(iter_56_1)
	end

	return var_56_0
end

function var_0_3.getEquipForce(arg_57_0)
	local var_57_0 = 0

	for iter_57_0 = 1, var_0_2.AttributeType.TOTAL_ATTR_NUM do
		var_57_0 = var_57_0 + (arg_57_0:getJinjieEquipAttr(iter_57_0) + arg_57_0:getEquipAttr(iter_57_0) + arg_57_0:getEquipFumoAttr(iter_57_0) + arg_57_0:getTotalPracticeAttr(iter_57_0) + arg_57_0:getElementAttr(iter_57_0) + arg_57_0:getSpiritEquipsAttr(iter_57_0)) * var_0_2.tables.attr:attrScore(iter_57_0)
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
	local var_60_1 = var_0_7:initPower(arg_60_0:getTableID())

	for iter_60_0 = 1, var_0_2.SKILL_INDEX.AwakeTwice do
		if iter_60_0 ~= var_0_2.SKILL_INDEX.Awake and iter_60_0 ~= var_0_2.SKILL_INDEX.AwakeTwice or iter_60_0 == var_0_2.SKILL_INDEX.Awake and arg_60_0:isAwaken() or iter_60_0 == var_0_2.SKILL_INDEX.AwakeTwice and arg_60_0:isAwakeTwice() then
			local var_60_2 = arg_60_0.skillLev_[iter_60_0] or 0

			if var_60_2 > 0 and (tonumber(var_0_7:getSkill(arg_60_0:getTableID(), iter_60_0)) or 0) > 0 then
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

function var_0_3.getWhiteAlbumForce(arg_65_0)
	if arg_65_0.playerID_ == 0 then
		return 0
	end

	local var_65_0 = var_0_1.ctx.battle.reportData and var_0_1.ctx.battle.reportData.hero_collect_attr and var_0_1.ctx.battle.reportData.hero_collect_attr[tostring(arg_65_0.playerID_)]
	local var_65_1 = 0

	if var_65_0 and next(var_65_0) then
		for iter_65_0, iter_65_1 in pairs(var_65_0) do
			var_65_1 = var_65_1 + iter_65_1 * var_0_2.tables.attr:attrScore(tonumber(iter_65_0))
		end
	elseif arg_65_0.playerID_ == arg_65_0.selfPlayer.playerID then
		if not arg_65_0.selfPlayer.albumAttr then
			return var_65_1
		end

		for iter_65_2 = 1, #arg_65_0.selfPlayer.albumAttr do
			var_65_1 = var_65_1 + arg_65_0.selfPlayer.albumAttr[iter_65_2] * var_0_2.tables.attr:attrScore(iter_65_2)
		end
	end

	return var_65_1
end

function var_0_3.getCard(arg_66_0)
	return var_0_10:card(arg_66_0:getModelID())
end

function var_0_3.getSmallCard(arg_67_0)
	return var_0_10:smallCard(arg_67_0:getModelID())
end

function var_0_3.getScale(arg_68_0)
	return var_0_10:scale(arg_68_0:getModelID())
end

function var_0_3.getMainAttr(arg_69_0, arg_69_1)
	local var_69_0 = arg_69_0:getGrowAttr(arg_69_0:getTableID(), arg_69_1, arg_69_0:getStar(), arg_69_0:getLevel())
	local var_69_1 = var_0_2.JINJIE_ATTR_RATE * (arg_69_0:getColor() - 1) / 2 * arg_69_0:getColor()
	local var_69_2 = var_0_7:getInitialAttr(arg_69_0:getTableID(), arg_69_1)
	local var_69_3 = arg_69_0:getJinjieEquipAttr(arg_69_1) + arg_69_0:getEquipAttr(arg_69_1) + arg_69_0:getEquipFumoAttr(arg_69_1)
	local var_69_4 = arg_69_0:getTotalPracticeAttr(arg_69_1)
	local var_69_5 = arg_69_0:getSkillBookAttr(arg_69_1)
	local var_69_6 = arg_69_0:getInscriptionAttr(arg_69_1)
	local var_69_7 = arg_69_0:getConquerSchoolAttr(arg_69_1)
	local var_69_8 = arg_69_0:getCoursesAttr(arg_69_1)
	local var_69_9 = arg_69_0:getStoneEvolutionAttr(arg_69_1)

	return var_69_0 + var_69_1 + var_69_2 + var_69_3 + var_69_4 + var_69_5 + var_69_6 + var_69_7 + var_69_8 + var_69_9
end

function var_0_3.getGrowAttr(arg_70_0, arg_70_1, arg_70_2, arg_70_3, arg_70_4)
	local var_70_0 = var_0_7:getHeroMainAttr(arg_70_1, arg_70_2, arg_70_3, arg_70_4)
	local var_70_1 = arg_70_0:getBookShelfAttr(arg_70_2)

	return var_70_0 * (1 + arg_70_0:getFavorAttrGrowth() + arg_70_0:getHouseAttrGrowthByType(arg_70_2)) + var_70_1
end

function var_0_3.getBattleInscriptionAttr(arg_71_0, arg_71_1)
	local var_71_0 = 0

	if not arg_71_0.inscriptItems_ then
		return var_71_0
	end

	for iter_71_0, iter_71_1 in pairs(arg_71_0.inscriptItems_) do
		var_71_0 = var_71_0 + arg_71_0:getBattleInscriptionAttrByType(arg_71_1, iter_71_1)
	end

	return var_71_0 + arg_71_0:getInscriptionSuitAttr(arg_71_1)
end

function var_0_3.getBattleInscriptionAttrByType(arg_72_0, arg_72_1, arg_72_2)
	return var_0_2.tables.item:attrsBattle(arg_72_2)[arg_72_1] or 0
end

function var_0_3.getInscriptionAttr(arg_73_0, arg_73_1)
	local var_73_0 = 0

	if not arg_73_0.inscriptItems_ then
		return var_73_0
	end

	for iter_73_0, iter_73_1 in pairs(arg_73_0.inscriptItems_) do
		var_73_0 = var_73_0 + arg_73_0:getInscriptionAttrByType(arg_73_1, iter_73_1)
	end

	return var_73_0 + arg_73_0:getInscriptionSuitAttr(arg_73_1)
end

function var_0_3.getInscriptionAttrByType(arg_74_0, arg_74_1, arg_74_2)
	return var_0_2.tables.item:attrs(arg_74_2)[arg_74_1] or 0
end

function var_0_3.getStoneEvolutionAttr(arg_75_0, arg_75_1)
	local var_75_0 = arg_75_0:getEvoAttrPoints()[tostring(arg_75_1)] or 0
	local var_75_1 = arg_75_0:getEvoStage()
	local var_75_2, var_75_3 = var_0_2.tables.stoneEvolution:getCumAttrByType(var_75_1, var_75_0, arg_75_1)

	return var_75_2
end

function var_0_3.getInscriptionSuitAttr(arg_76_0, arg_76_1)
	local var_76_0 = {}
	local var_76_1 = arg_76_0:getSuitInfo()
	local var_76_2 = var_0_2.tables.inscriptionSuit

	for iter_76_0, iter_76_1 in pairs(var_76_1) do
		if iter_76_1 then
			var_76_0 = var_0_2.tables.inscriptionSuit:attrs(iter_76_0)
		end
	end

	return var_76_0[arg_76_1] or 0
end

function var_0_3.getCoursesAttr(arg_77_0, arg_77_1)
	local var_77_0 = 0

	if not arg_77_0.coursesInfo then
		return var_77_0
	end

	for iter_77_0, iter_77_1 in pairs(arg_77_0.coursesInfo) do
		iter_77_0 = tonumber(iter_77_0)

		if iter_77_1.add_skill and iter_77_1.add_skill > 0 and var_0_2.tables.objectBook:bookType(iter_77_0) == 0 then
			local var_77_1 = var_0_2.tables.objectBook:attr(iter_77_0)
			local var_77_2 = var_0_2.tables.objectBook:number(iter_77_0)
			local var_77_3 = var_0_2.tables.objectBook:stepUp(iter_77_0)

			for iter_77_2 = 1, #var_77_1 do
				if var_77_1[iter_77_2] and var_77_1[iter_77_2] == arg_77_1 then
					local var_77_4 = var_77_2[iter_77_2] or 0
					local var_77_5 = var_77_3[iter_77_2] or 0

					var_77_0 = var_77_0 + var_77_4 + iter_77_1.quality * var_77_5
				end
			end
		end
	end

	return var_77_0
end

function var_0_3.getCourseIDByColor(arg_78_0, arg_78_1)
	if not arg_78_0.coursesInfo or arg_78_1 == 0 then
		return 0
	end

	for iter_78_0, iter_78_1 in pairs(arg_78_0.coursesInfo) do
		if iter_78_1.add_skill == arg_78_1 then
			return tonumber(iter_78_0)
		end
	end

	return 0
end

function var_0_3.getCourseLevelByID(arg_79_0, arg_79_1)
	if not arg_79_0.coursesInfo or arg_79_1 == 0 then
		return 0
	end

	for iter_79_0, iter_79_1 in pairs(arg_79_0.coursesInfo) do
		if tonumber(iter_79_0) == arg_79_1 then
			return tonumber(iter_79_1.quality)
		end
	end

	return 0
end

function var_0_3.getCourseTypeByID(arg_80_0, arg_80_1)
	return var_0_2.tables.objectBook:bookType(arg_80_1)
end

function var_0_3.getFavorAttrGrowth(arg_81_0)
	return var_0_2.tables.libraryAmour:attr(arg_81_0:getFavorLev())
end

function var_0_3.getFavorLev(arg_82_0)
	local var_82_0 = var_0_2.tables.libraryAmour:getCurrentId(arg_82_0:getFavorDegree())

	if arg_82_0:getFavorState() == var_0_2.FavorState.MARRIED then
		var_82_0 = var_82_0 + 1
	end

	return var_82_0
end

function var_0_3.getAttrGlow(arg_83_0, arg_83_1)
	return var_0_7:getHeroAttrGrow(arg_83_0:getTableID(), arg_83_1, arg_83_0:getStar())
end

function var_0_3.getFavorAttrGrowByType(arg_84_0, arg_84_1)
	return arg_84_0:getAttrGlow(arg_84_1) * arg_84_0:getFavorAttrGrowth()
end

function var_0_3.getHouseAttrGrowByType(arg_85_0, arg_85_1)
	return arg_85_0:getAttrGlow(arg_85_1) * arg_85_0:getHouseAttrGrowthByType(arg_85_1)
end

function var_0_3.getHouseAttrGrowthByType(arg_86_0, arg_86_1)
	local var_86_0 = var_0_13:getHouseLevByComfort(arg_86_0.houseTableId, arg_86_0.houseComfort)
	local var_86_1 = var_0_13:getAttrsGrowByLev(arg_86_0.houseTableId, var_86_0)
	local var_86_2 = var_0_13:type(arg_86_0.houseTableId)

	if arg_86_0.houseExpandLev and arg_86_0.houseExpandLev > 0 then
		local var_86_3 = var_0_2.tables.dormExpand:getAttrsGrowByLev(var_86_2, arg_86_0.houseComfort, arg_86_0.houseExpandLev)

		if var_86_3 then
			var_86_1 = var_86_3
		end
	end

	if not arg_86_0.houseTableId or arg_86_0.houseTableId <= 0 or not var_86_1 or not next(var_86_1) then
		return 0
	end

	return (var_86_1[arg_86_1] or 0) / 100
end

function var_0_3.getSkillAttr(arg_87_0, arg_87_1)
	local var_87_0 = var_0_1.ctx.battle.getRequire("Buff")

	local function var_87_1(arg_88_0, arg_88_1, arg_88_2)
		local var_88_0 = {}

		for iter_88_0, iter_88_1 in ipairs(arg_88_0) do
			local var_88_1 = var_87_0.new({
				start = 0,
				tableID = iter_88_1,
				level = arg_88_1,
				skillID = arg_88_2
			})

			var_88_1:setYongJiu()
			table.insert(var_88_0, var_88_1)
		end

		return var_88_0
	end

	local var_87_2 = var_0_7:buffSkill(arg_87_0:getTableID())

	if not next(var_87_2) then
		return 0
	end

	local var_87_3 = 0

	for iter_87_0, iter_87_1 in ipairs(var_87_2) do
		if var_0_8:skillType(iter_87_1) == var_0_2.SkillType.BUFF_SELF then
			local var_87_4 = arg_87_0:getSkillLevelByID(iter_87_1)

			if var_87_4 and var_87_4 > 0 then
				local var_87_5 = var_0_8:buffs(iter_87_1)
				local var_87_6 = var_87_1(var_87_5, var_87_4, iter_87_1)

				for iter_87_2, iter_87_3 in ipairs(var_87_6) do
					if iter_87_3:getAttrType() == arg_87_1 then
						local var_87_7, var_87_8 = iter_87_3:getAttr()

						if not var_87_8 then
							var_87_3 = var_87_3 + var_87_7
						else
							print("error : buff skill attribute type use percent increase " .. iter_87_3:getTableID())
						end
					end
				end
			end
		end
	end

	return var_87_3
end

function var_0_3.getMaxHP(arg_89_0)
	local var_89_0 = var_0_7:getInitialAttr(arg_89_0:getTableID(), var_0_2.AttributeType.HP)
	local var_89_1 = arg_89_0:getMainAttr(var_0_2.AttributeType.STRENGTH)

	return math.floor(var_89_0 + var_0_2.STRENGTH_HP_RATE * var_89_1)
end

function var_0_3.skillAttr2HP(arg_90_0)
	local var_90_0 = arg_90_0:getSkillAttr(var_0_2.AttributeType.STRENGTH)

	return var_0_2.STRENGTH_HP_RATE * var_90_0
end

function var_0_3.getAD(arg_91_0)
	local var_91_0 = var_0_7:getInitialAttr(arg_91_0:getTableID(), var_0_2.AttributeType.AD)
	local var_91_1 = arg_91_0:getMainAttr(var_0_2.AttributeType.AGILE) * var_0_2.AGILE_AD_RATE + arg_91_0:getMainAttr(arg_91_0:getHeroType())

	return math.floor(var_91_1 + var_91_0)
end

function var_0_3.skillAttr2AD(arg_92_0)
	local var_92_0 = arg_92_0:getSkillAttr(var_0_2.AttributeType.AGILE)

	return arg_92_0:getSkillAttr(arg_92_0:getHeroType()) + var_92_0 * var_0_2.AGILE_AD_RATE
end

function var_0_3.getAP(arg_93_0)
	local var_93_0 = var_0_7:getInitialAttr(arg_93_0:getTableID(), var_0_2.AttributeType.AP)
	local var_93_1 = arg_93_0:getMainAttr(var_0_2.AttributeType.WISE) * var_0_2.WISE_AP_RATE

	return math.floor(var_93_0 + var_93_1)
end

function var_0_3.skillAttr2AP(arg_94_0)
	return arg_94_0:getSkillAttr(var_0_2.AttributeType.WISE) * var_0_2.WISE_AP_RATE
end

function var_0_3.getHujia(arg_95_0)
	local var_95_0 = var_0_7:getInitialAttr(arg_95_0:getTableID(), var_0_2.AttributeType.HUJIA)
	local var_95_1 = var_0_2.AGILE_HUJIA_RATE * arg_95_0:getMainAttr(var_0_2.AttributeType.AGILE) + var_0_2.STRENGTH_HUJIA_RATE * arg_95_0:getMainAttr(var_0_2.AttributeType.STRENGTH)

	return math.floor(var_95_1 + var_95_0)
end

function var_0_3.skillAttr2Hujia(arg_96_0)
	local var_96_0 = arg_96_0:getSkillAttr(var_0_2.AttributeType.AGILE)
	local var_96_1 = arg_96_0:getSkillAttr(var_0_2.AttributeType.STRENGTH)

	return var_0_2.AGILE_HUJIA_RATE * var_96_0 + var_0_2.STRENGTH_HUJIA_RATE * var_96_1
end

function var_0_3.getMokang(arg_97_0)
	local var_97_0 = var_0_7:getInitialAttr(arg_97_0:getTableID(), var_0_2.AttributeType.MOKANG)
	local var_97_1 = var_0_2.WISE_MOKANG_RATE * arg_97_0:getMainAttr(var_0_2.AttributeType.WISE)

	return math.floor(var_97_0 + var_97_1)
end

function var_0_3.skillAttr2Mokang(arg_98_0)
	return var_0_2.WISE_MOKANG_RATE * arg_98_0:getSkillAttr(var_0_2.AttributeType.WISE)
end

function var_0_3.getADBaoji(arg_99_0)
	local var_99_0 = var_0_7:getInitialAttr(arg_99_0:getTableID(), var_0_2.AttributeType.AD_BAOJI)
	local var_99_1 = var_0_2.AGILE_AD_BAOJI_RATE * arg_99_0:getMainAttr(var_0_2.AttributeType.AGILE)

	return math.floor(var_99_0 + var_99_1)
end

function var_0_3.skillAttr2Baoji(arg_100_0)
	return var_0_2.AGILE_AD_BAOJI_RATE * arg_100_0:getSkillAttr(var_0_2.AttributeType.AGILE)
end

function var_0_3.getSkill2Attr(arg_101_0, arg_101_1)
	if arg_101_1 == var_0_2.AttributeType.HP then
		return arg_101_0:skillAttr2HP()
	elseif arg_101_1 == var_0_2.AttributeType.AD then
		return arg_101_0:skillAttr2AD()
	elseif arg_101_1 == var_0_2.AttributeType.AP then
		return arg_101_0:skillAttr2AP()
	elseif arg_101_1 == var_0_2.AttributeType.HUJIA then
		return arg_101_0:skillAttr2Hujia()
	elseif arg_101_1 == var_0_2.AttributeType.MOKANG then
		return arg_101_0:skillAttr2Mokang()
	elseif arg_101_1 == var_0_2.AttributeType.AD_BAOJI then
		return arg_101_0:skillAttr2Baoji()
	end

	return 0
end

function var_0_3.getTotalAttr(arg_102_0, arg_102_1)
	if arg_102_1 < 4 then
		return arg_102_0:getMainAttr(arg_102_1) + arg_102_0:getSkillAttr(arg_102_1)
	elseif arg_102_1 == var_0_2.AttributeType.HP then
		return arg_102_0:getMaxHP() + arg_102_0:getJinjieEquipAttr(arg_102_1) + arg_102_0:getEquipAttr(arg_102_1) + arg_102_0:getEquipFumoAttr(arg_102_1) + arg_102_0:getSkillAttr(arg_102_1) + arg_102_0:getSkill2Attr(arg_102_1) + arg_102_0:getTotalPracticeAttr(arg_102_1) + arg_102_0:getSkillBookAttr(arg_102_1) + arg_102_0:getBattleInscriptionAttr(arg_102_1) + arg_102_0:getConquerSchoolAttr(arg_102_1) + arg_102_0:getFeedAttr(arg_102_1) + arg_102_0:getCoursesAttr(arg_102_1) + arg_102_0:getStoneEvolutionAttr(arg_102_1) + arg_102_0:getWhiteAlbumAttr(arg_102_1) + arg_102_0:getElementAttr(arg_102_1) + arg_102_0:getSpiritEquipsAttr(arg_102_1)
	elseif arg_102_1 == var_0_2.AttributeType.AD then
		return arg_102_0:getAD() + arg_102_0:getJinjieEquipAttr(arg_102_1) + arg_102_0:getEquipAttr(arg_102_1) + arg_102_0:getEquipFumoAttr(arg_102_1) + arg_102_0:getSkillAttr(arg_102_1) + arg_102_0:getSkill2Attr(arg_102_1) + arg_102_0:getTotalPracticeAttr(arg_102_1) + arg_102_0:getSkillBookAttr(arg_102_1) + arg_102_0:getBattleInscriptionAttr(arg_102_1) + arg_102_0:getConquerSchoolAttr(arg_102_1) + arg_102_0:getFeedAttr(arg_102_1) + arg_102_0:getCoursesAttr(arg_102_1) + arg_102_0:getStoneEvolutionAttr(arg_102_1) + arg_102_0:getWhiteAlbumAttr(arg_102_1) + arg_102_0:getElementAttr(arg_102_1) + arg_102_0:getSpiritEquipsAttr(arg_102_1)
	elseif arg_102_1 == var_0_2.AttributeType.AP then
		return arg_102_0:getAP() + arg_102_0:getJinjieEquipAttr(arg_102_1) + arg_102_0:getEquipAttr(arg_102_1) + arg_102_0:getEquipFumoAttr(arg_102_1) + arg_102_0:getSkillAttr(arg_102_1) + arg_102_0:getSkill2Attr(arg_102_1) + arg_102_0:getTotalPracticeAttr(arg_102_1) + arg_102_0:getSkillBookAttr(arg_102_1) + arg_102_0:getBattleInscriptionAttr(arg_102_1) + arg_102_0:getConquerSchoolAttr(arg_102_1) + arg_102_0:getFeedAttr(arg_102_1) + arg_102_0:getCoursesAttr(arg_102_1) + arg_102_0:getStoneEvolutionAttr(arg_102_1) + arg_102_0:getWhiteAlbumAttr(arg_102_1) + arg_102_0:getElementAttr(arg_102_1) + arg_102_0:getSpiritEquipsAttr(arg_102_1)
	elseif arg_102_1 == var_0_2.AttributeType.HUJIA then
		return arg_102_0:getHujia() + arg_102_0:getJinjieEquipAttr(arg_102_1) + arg_102_0:getEquipAttr(arg_102_1) + arg_102_0:getEquipFumoAttr(arg_102_1) + arg_102_0:getSkillAttr(arg_102_1) + arg_102_0:getSkill2Attr(arg_102_1) + arg_102_0:getTotalPracticeAttr(arg_102_1) + arg_102_0:getSkillBookAttr(arg_102_1) + arg_102_0:getBattleInscriptionAttr(arg_102_1) + arg_102_0:getConquerSchoolAttr(arg_102_1) + arg_102_0:getFeedAttr(arg_102_1) + arg_102_0:getCoursesAttr(arg_102_1) + arg_102_0:getStoneEvolutionAttr(arg_102_1) + arg_102_0:getWhiteAlbumAttr(arg_102_1) + arg_102_0:getElementAttr(arg_102_1) + arg_102_0:getSpiritEquipsAttr(arg_102_1)
	elseif arg_102_1 == var_0_2.AttributeType.MOKANG then
		return arg_102_0:getMokang() + arg_102_0:getJinjieEquipAttr(arg_102_1) + arg_102_0:getEquipAttr(arg_102_1) + arg_102_0:getEquipFumoAttr(arg_102_1) + arg_102_0:getSkillAttr(arg_102_1) + arg_102_0:getSkill2Attr(arg_102_1) + arg_102_0:getTotalPracticeAttr(arg_102_1) + arg_102_0:getSkillBookAttr(arg_102_1) + arg_102_0:getBattleInscriptionAttr(arg_102_1) + arg_102_0:getConquerSchoolAttr(arg_102_1) + arg_102_0:getFeedAttr(arg_102_1) + arg_102_0:getCoursesAttr(arg_102_1) + arg_102_0:getStoneEvolutionAttr(arg_102_1) + arg_102_0:getWhiteAlbumAttr(arg_102_1) + arg_102_0:getElementAttr(arg_102_1) + arg_102_0:getSpiritEquipsAttr(arg_102_1)
	elseif arg_102_1 == var_0_2.AttributeType.AD_BAOJI then
		return arg_102_0:getADBaoji() + arg_102_0:getJinjieEquipAttr(arg_102_1) + arg_102_0:getEquipAttr(arg_102_1) + arg_102_0:getEquipFumoAttr(arg_102_1) + arg_102_0:getSkillAttr(arg_102_1) + arg_102_0:getSkill2Attr(arg_102_1) + arg_102_0:getTotalPracticeAttr(arg_102_1) + arg_102_0:getSkillBookAttr(arg_102_1) + arg_102_0:getBattleInscriptionAttr(arg_102_1) + arg_102_0:getConquerSchoolAttr(arg_102_1) + arg_102_0:getFeedAttr(arg_102_1) + arg_102_0:getCoursesAttr(arg_102_1) + arg_102_0:getStoneEvolutionAttr(arg_102_1) + arg_102_0:getWhiteAlbumAttr(arg_102_1) + arg_102_0:getElementAttr(arg_102_1) + arg_102_0:getSpiritEquipsAttr(arg_102_1)
	elseif arg_102_1 == var_0_2.AttributeType.ENERGY_RATE then
		return 1
	elseif arg_102_1 <= var_0_2.AttributeType.TOTAL_ATTR_NUM then
		return arg_102_0:getJinjieEquipAttr(arg_102_1) + var_0_7:getInitialAttr(arg_102_0:getTableID(), arg_102_1) + arg_102_0:getEquipAttr(arg_102_1) + arg_102_0:getEquipFumoAttr(arg_102_1) + arg_102_0:getSkillAttr(arg_102_1) + arg_102_0:getTotalPracticeAttr(arg_102_1) + arg_102_0:getSkillBookAttr(arg_102_1) + arg_102_0:getBattleInscriptionAttr(arg_102_1) + arg_102_0:getConquerSchoolAttr(arg_102_1) + arg_102_0:getCoursesAttr(arg_102_1) + arg_102_0:getStoneEvolutionAttr(arg_102_1) + arg_102_0:getWhiteAlbumAttr(arg_102_1) + arg_102_0:getElementAttr(arg_102_1) + arg_102_0:getSpiritEquipsAttr(arg_102_1)
	else
		return var_0_7:getInitialAttr(arg_102_0:getTableID(), arg_102_1) + arg_102_0:getSkillAttr(arg_102_1) + arg_102_0:getTotalPracticeAttr(arg_102_1) + arg_102_0:getSkillBookAttr(arg_102_1) + arg_102_0:getBattleInscriptionAttr(arg_102_1) + arg_102_0:getConquerSchoolAttr(arg_102_1)
	end
end

function var_0_3.getTotalAttrWithOutBook(arg_103_0, arg_103_1)
	if arg_103_1 < 4 then
		return arg_103_0:getMainAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1)
	elseif arg_103_1 == var_0_2.AttributeType.HP then
		return arg_103_0:getMaxHP() + arg_103_0:getJinjieEquipAttr(arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getSkill2Attr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getFeedAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	elseif arg_103_1 == var_0_2.AttributeType.AD then
		return arg_103_0:getAD() + arg_103_0:getJinjieEquipAttr(arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getSkill2Attr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getFeedAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	elseif arg_103_1 == var_0_2.AttributeType.AP then
		return arg_103_0:getAP() + arg_103_0:getJinjieEquipAttr(arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getSkill2Attr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getFeedAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	elseif arg_103_1 == var_0_2.AttributeType.HUJIA then
		return arg_103_0:getHujia() + arg_103_0:getJinjieEquipAttr(arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getSkill2Attr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getFeedAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	elseif arg_103_1 == var_0_2.AttributeType.MOKANG then
		return arg_103_0:getMokang() + arg_103_0:getJinjieEquipAttr(arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getSkill2Attr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getFeedAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	elseif arg_103_1 == var_0_2.AttributeType.AD_BAOJI then
		return arg_103_0:getADBaoji() + arg_103_0:getJinjieEquipAttr(arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getSkill2Attr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getFeedAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	elseif arg_103_1 <= var_0_2.AttributeType.TOTAL_ATTR_NUM then
		return arg_103_0:getJinjieEquipAttr(arg_103_1) + var_0_7:getInitialAttr(arg_103_0:getTableID(), arg_103_1) + arg_103_0:getEquipAttr(arg_103_1) + arg_103_0:getEquipFumoAttr(arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getInscriptionAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1) + arg_103_0:getCoursesAttr(arg_103_1) + arg_103_0:getStoneEvolutionAttr(arg_103_1) + arg_103_0:getWhiteAlbumAttr(arg_103_1) + arg_103_0:getElementAttr(arg_103_1) + arg_103_0:getSpiritEquipsAttr(arg_103_1)
	else
		return var_0_7:getInitialAttr(arg_103_0:getTableID(), arg_103_1) + arg_103_0:getSkillAttr(arg_103_1) + arg_103_0:getTotalPracticeAttr(arg_103_1) + arg_103_0:getConquerSchoolAttr(arg_103_1)
	end
end

function var_0_3.setupBattleAttrInfo(arg_104_0)
	if not arg_104_0.isPet_ then
		arg_104_0.totalAttrs_ = {}
		arg_104_0.attrMD5_ = {}
		arg_104_0.errorData_ = arg_104_0.errorData_ or {}

		for iter_104_0 = 1, var_0_2.AttributeType.TOTAL_ATTR_NUM do
			arg_104_0.totalAttrs_[iter_104_0] = var_0_0.clone(arg_104_0:getTotalAttr(iter_104_0))

			if isClient then
				arg_104_0.attrMD5_[iter_104_0] = crypto.md5(arg_104_0.totalAttrs_[iter_104_0] .. var_0_2.tables.misc.encryptoKey)
			end
		end
	end
end

function var_0_3.getInscriptionKuangLevel(arg_105_0)
	local var_105_0 = arg_105_0:getInscriptItems()
	local var_105_1 = var_0_2.tables.inscriptionSuit

	if #var_105_0 < 3 then
		return false
	else
		local var_105_2 = arg_105_0:getSuitInfo()
		local var_105_3 = {}

		for iter_105_0, iter_105_1 in pairs(var_105_2) do
			if iter_105_1 then
				var_105_3 = var_105_1:itemID(iter_105_0)
			end
		end

		if #var_105_3 >= 3 then
			return 3
		elseif #var_105_3 >= 2 then
			return 2
		else
			return 1
		end
	end
end

function var_0_3.getBattleAttr(arg_106_0, arg_106_1)
	if not arg_106_0.totalAttrs_ then
		arg_106_0:setupBattleAttrInfo()
	end

	if isClient and crypto.md5(arg_106_0.totalAttrs_[arg_106_1] .. var_0_2.tables.misc.encryptoKey) ~= arg_106_0.attrMD5_[arg_106_1] then
		arg_106_0:recordErrorData(arg_106_1, arg_106_0.totalAttrs_[arg_106_1])
	end

	return arg_106_0.totalAttrs_[arg_106_1]
end

function var_0_3.recordErrorData(arg_107_0, arg_107_1, arg_107_2)
	arg_107_0.errorData_ = arg_107_0.errorData_ or {}
	arg_107_0.errorData_[tostring(arg_107_1)] = arg_107_2
end

function var_0_3.getEquipAttr(arg_108_0, arg_108_1)
	return arg_108_0:getEquipEnhanceAttr(arg_108_1) + arg_108_0:getHouseEquipAttr(arg_108_1)
end

function var_0_3.getHouseEquipAttr(arg_109_0, arg_109_1)
	if not arg_109_0.houseTableId or arg_109_0.houseTableId <= 0 or var_0_13:maintype(arg_109_0.houseTableId) == var_0_2.DormType.LOUNGE then
		return 0
	end

	local var_109_0 = 0
	local var_109_1 = arg_109_0:getHouseEquipsList(arg_109_0:getStar())

	for iter_109_0, iter_109_1 in pairs(var_109_1) do
		if arg_109_0.houseEquips and arg_109_0.houseEquips[iter_109_0] and arg_109_0.houseEquips[iter_109_0] > 0 then
			var_109_0 = var_109_0 + arg_109_0:getEquipAttrByType(arg_109_1, iter_109_1)
		end
	end

	return var_109_0
end

function var_0_3.getWhiteAlbumAttr(arg_110_0, arg_110_1)
	if arg_110_0.playerID_ == 0 then
		return 0
	end

	local var_110_0 = var_0_1.ctx.battle.reportData and var_0_1.ctx.battle.reportData.hero_collect_attr and var_0_1.ctx.battle.reportData.hero_collect_attr[tostring(arg_110_0.playerID_)]

	if var_110_0 and next(var_110_0) and var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		return var_110_0[tostring(arg_110_1)] or 0
	elseif arg_110_0.playerID_ == arg_110_0.selfPlayer.playerID then
		return arg_110_0.selfPlayer.albumAttr[arg_110_1] or 0
	end

	return 0
end

function var_0_3.updatePractice(arg_111_0, arg_111_1)
	arg_111_0.practice_attr_ = arg_111_1

	arg_111_0:updatePracticeAwardAttr()
end

function var_0_3.updateBookSkill(arg_112_0, arg_112_1, arg_112_2)
	arg_112_0.skill_book_[tostring(arg_112_1)] = arg_112_2
end

function var_0_3.getInscriptItem(arg_113_0, arg_113_1)
	if not arg_113_0.inscriptItems_ then
		return nil
	end

	for iter_113_0 = 1, #arg_113_0.inscriptItems_ do
		if var_0_2.tables.inscription:getItemPos(var_0_2.tables.item:inscriptId(arg_113_0.inscriptItems_[iter_113_0]), arg_113_0.inscriptItems_[iter_113_0]) == arg_113_1 then
			return arg_113_0.inscriptItems_[iter_113_0]
		end
	end
end

function var_0_3.getInscriptItems(arg_114_0)
	return arg_114_0.inscriptItems_ or {}
end

function var_0_3.setInscriptItem(arg_115_0, arg_115_1)
	if not arg_115_0.inscriptItems_ then
		arg_115_0.inscriptItems_ = {}
	end

	for iter_115_0 = 1, #arg_115_0.inscriptItems_ do
		if var_0_2.tables.inscription:itemType(var_0_2.tables.item:inscriptId(arg_115_0.inscriptItems_[iter_115_0])) == var_0_2.tables.inscription:itemType(arg_115_1) then
			arg_115_0.inscriptItems_[iter_115_0] = arg_115_1

			return
		end
	end

	table.insert(arg_115_0.inscriptItems_, arg_115_1)
end

function var_0_3.setInscriptItems(arg_116_0, arg_116_1)
	arg_116_0.inscriptItems_ = arg_116_1
end

function var_0_3.updatePracticeAwardAttr(arg_117_0)
	local var_117_0 = var_0_7:getPracticeNeeds(arg_117_0:getTableID())
	local var_117_1 = var_0_7:getPracticeAttrType(arg_117_0:getTableID())
	local var_117_2 = var_0_7:getPracticeAttrValue(arg_117_0:getTableID())

	if #var_117_0 ~= 3 or #var_117_1 ~= 3 or #var_117_2 ~= 3 then
		return
	end

	arg_117_0.practiceAwardAttrs = {}

	for iter_117_0 = 1, #var_117_0 do
		if arg_117_0.practice_attr_[iter_117_0] >= var_117_0[iter_117_0] then
			arg_117_0.practiceAwardAttrs[var_117_1[iter_117_0]] = (arg_117_0.practiceAwardAttrs[var_117_1[iter_117_0]] or 0) + var_117_2[iter_117_0]
		end
	end
end

function var_0_3.getTotalPracticeAttr(arg_118_0, arg_118_1)
	return arg_118_0:getPracticeAwardAttr(arg_118_1) + arg_118_0:getPracticeAttr(arg_118_1)
end

function var_0_3.getPracticeAwardAttr(arg_119_0, arg_119_1)
	if not arg_119_0.practiceAwardAttrs then
		return 0
	end

	return arg_119_0.practiceAwardAttrs[arg_119_1] or 0
end

function var_0_3.getJinjieEquipAttr(arg_120_0, arg_120_1)
	local var_120_0 = 0
	local var_120_1 = false

	for iter_120_0 = 1, arg_120_0:getColor() - 1 do
		local var_120_2 = arg_120_0:getEquipList(iter_120_0)

		if var_120_2 and next(var_120_2) then
			for iter_120_1, iter_120_2 in pairs(var_120_2) do
				if var_0_11:isAwakenItem(iter_120_2:getTableID()) == 0 then
					var_120_0 = var_120_0 + arg_120_0:getEquipAttrByType(arg_120_1, iter_120_2)

					local var_120_3 = true
				end
			end
		end
	end

	return var_120_0
end

function var_0_3.getEquipFumoAttr(arg_121_0, arg_121_1)
	local var_121_0 = arg_121_0:getEquipList(arg_121_0:getColor())

	return 0
end

function var_0_3.getEquipEnhanceAttr(arg_122_0, arg_122_1)
	local var_122_0 = 0
	local var_122_1 = arg_122_0:getEquipList(arg_122_0:getColor())

	if not var_122_1 or not next(var_122_1) then
		return var_122_0
	end

	for iter_122_0, iter_122_1 in pairs(var_122_1) do
		if arg_122_0.equips_[iter_122_0] and arg_122_0.equips_[iter_122_0] > 0 then
			var_122_0 = var_122_0 + arg_122_0:getEquipEnhanceAttrByType(arg_122_1, iter_122_1, arg_122_0.equips_[iter_122_0] - 1)
		end
	end

	return var_122_0
end

function var_0_3.getEquipList(arg_123_0, arg_123_1)
	if not arg_123_0.totalEquipList_ then
		local var_123_0 = var_0_7:equipList(arg_123_0:getTableID())

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
							local var_123_4 = arg_123_0.equips_[iter_123_2] - 1

							var_123_2:populate({
								item_id = iter_123_0 * 10 + iter_123_2,
								table_id = var_0_7:awakeTwiceItem(arg_123_0.tableID_),
								moneng = var_123_3,
								equip_level = var_123_4
							})

							arg_123_0.awakeTwiceItem = var_123_2

							var_123_2:setStateCollected()
						else
							var_123_2 = arg_123_0.awakeTwiceItem
						end
					elseif not arg_123_0.awakeItem then
						var_123_2 = var_0_4.new()

						local var_123_5 = arg_123_0.fumo_[iter_123_2] or 0
						local var_123_6 = arg_123_0.equips_[iter_123_2] - 1

						var_123_2:populate({
							item_id = iter_123_0 * 10 + iter_123_2,
							table_id = iter_123_3,
							moneng = var_123_5,
							equip_level = var_123_6
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

					local var_123_7 = iter_123_0 == arg_123_0:getColor() and arg_123_0.fumo_[iter_123_2] or 0
					local var_123_8 = arg_123_0.equips_[iter_123_2] - 1

					var_123_2:populate({
						item_id = iter_123_0 * 10 + iter_123_2,
						table_id = iter_123_3,
						moneng = var_123_7,
						equip_level = var_123_8
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

	return arg_123_0.totalEquipList_[arg_123_1] or arg_123_0.totalEquipList_[#arg_123_0.totalEquipList_]
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
			table_id = var_0_7:awakeTwiceItem(arg_128_0.tableID_),
			equip_level = arg_128_0:getEquipLevel(arg_128_1)
		})
	end

	return var_128_0
end

function var_0_3.getEquipLevel(arg_129_0, arg_129_1)
	return arg_129_0.equips_[arg_129_1] - 1
end

function var_0_3.getItemHeroHasNotEquip(arg_130_0, arg_130_1)
	local var_130_0 = arg_130_0:getEquipList(arg_130_0:getColor())

	for iter_130_0, iter_130_1 in pairs(var_130_0) do
		if iter_130_1:getTableID() == arg_130_1 and not iter_130_1:isCollected() then
			return true
		end
	end

	return false
end

function var_0_3.getEquipAttrByType(arg_131_0, arg_131_1, arg_131_2)
	return arg_131_2:getAttr()[arg_131_1] or 0
end

function var_0_3.getEquipEnhanceAttrByType(arg_132_0, arg_132_1, arg_132_2, arg_132_3)
	return arg_132_2:getEnhanceEquipAttrByLevel(arg_132_1, arg_132_3) or 0
end

function var_0_3.getEquipFumoAttrByType(arg_133_0, arg_133_1, arg_133_2)
	return arg_133_2:getFumoAttr()[arg_133_1] or 0
end

function var_0_3.getEquipFumoAttrByLevel(arg_134_0, arg_134_1, arg_134_2, arg_134_3)
	return arg_134_2:getFumoByLevel(arg_134_3)[arg_134_1] or 0
end

function var_0_3.getDes(arg_135_0)
	return var_0_7:getDes(arg_135_0:getTableID())
end

function var_0_3.getTalkText(arg_136_0)
	return var_0_7:getTalkText(arg_136_0:getTableID())
end

function var_0_3.getSkillId(arg_137_0, arg_137_1)
	if arg_137_1 then
		if next(arg_137_0.selfSkillIDs_) then
			return clone(arg_137_0.selfSkillIDs_[arg_137_1])
		else
			return var_0_7:getSkill(arg_137_0:getTableID(), arg_137_1)
		end
	elseif next(arg_137_0.selfSkillIDs_) then
		return clone(arg_137_0.selfSkillIDs_)
	else
		return var_0_7:getSkill(arg_137_0:getTableID())
	end
end

function var_0_3.getCircle(arg_138_0)
	local var_138_0 = var_0_0.clone(var_0_7:circle(arg_138_0:getTableID()))

	if #var_0_7:getSkillTable(arg_138_0:getTableID(), 1) > 1 then
		return arg_138_0:changeQueueSkill(var_138_0)
	else
		return var_138_0
	end
end

function var_0_3.getStartCircle(arg_139_0)
	local var_139_0 = var_0_0.clone(var_0_7:startCircle(arg_139_0:getTableID()))

	if #var_0_7:getSkillTable(arg_139_0:getTableID(), 1) > 1 then
		return arg_139_0:changeQueueSkill(var_139_0)
	else
		return var_139_0
	end
end

function var_0_3.changeQueueSkill(arg_140_0, arg_140_1)
	local var_140_0 = {}
	local var_140_1 = var_0_7:pugong(arg_140_0:getTableID())

	for iter_140_0, iter_140_1 in ipairs(arg_140_1) do
		local var_140_2

		if iter_140_1 == 0 then
			local var_140_3 = var_140_1

			table.insert(var_140_0, var_140_3)
		elseif arg_140_0:getSkillLevel(iter_140_1) and arg_140_0:getSkillLevel(iter_140_1) > 1 then
			local var_140_4 = arg_140_0:getSkillId(iter_140_1)

			if var_0_8:type(var_140_4) == var_0_2.AttackType.None then
				table.insert(var_140_0, var_140_1)
			else
				table.insert(var_140_0, var_140_4)
			end
		end
	end

	return var_140_0
end

function var_0_3.getExtraSkillLevel(arg_141_0)
	return arg_141_0:getEquipAttr(var_0_2.AttributeType.ADD_SKILL) + arg_141_0:getJinjieEquipAttr(var_0_2.AttributeType.ADD_SKILL) + arg_141_0:getSkillBookAttr(var_0_2.AttributeType.ADD_SKILL) + arg_141_0:getPracticeAwardAttr(var_0_2.AttributeType.ADD_SKILL) + arg_141_0:getInscriptionAttr(var_0_2.AttributeType.ADD_SKILL) + arg_141_0:getConquerSchoolAttr(var_0_2.AttributeType.ADD_SKILL) + arg_141_0:getCoursesAttr(var_0_2.AttributeType.ADD_SKILL) + arg_141_0:getWhiteAlbumAttr(var_0_2.AttributeType.ADD_SKILL)
end

function var_0_3.getBookShelfSkillLevel(arg_142_0)
	local var_142_0 = 0
	local var_142_1 = arg_142_0.bookshelfLev or 0

	if var_142_1 > 0 then
		var_142_0 = var_0_2.tables.bookShelfTable:upperLimit(var_142_1)
	end

	return var_142_0
end

function var_0_3.getBookShelfAttr(arg_143_0, arg_143_1)
	local var_143_0 = 0
	local var_143_1

	if not arg_143_0.bookshelfLev or arg_143_0.bookshelfLev == 0 then
		return 0
	else
		var_143_1 = arg_143_0.bookshelfLev
	end

	local var_143_2 = var_0_2.tables.bookShelfTable:attribute(var_143_1)

	if var_143_2[arg_143_1] then
		local var_143_3 = var_0_7:getHeroMainAttr(arg_143_0:getTableID(), arg_143_1, arg_143_0:getStar(), arg_143_0:getLevel())

		var_143_0 = var_143_2[arg_143_1] * 0.01 * var_143_3
	end

	return var_143_0
end

function var_0_3.getBookShelfForce(arg_144_0)
	local var_144_0 = 0

	for iter_144_0 = 1, 3 do
		var_144_0 = var_144_0 + arg_144_0:getBookShelfAttr(iter_144_0) * var_0_2.tables.attr:attrScore(iter_144_0)
	end

	return var_144_0
end

function var_0_3.getSkillLevel(arg_145_0, arg_145_1)
	if arg_145_1 then
		local var_145_0 = arg_145_0.skillLev_[arg_145_1]

		if isClient and type(var_145_0) == "number" and var_145_0 > var_0_2.MAX_SKILL_LEV then
			var_0_2.exitProgram()
		end

		return var_145_0
	else
		return arg_145_0.skillLev_
	end
end

function var_0_3.getSkillLevelByID(arg_146_0, arg_146_1)
	local var_146_0 = 0

	if arg_146_1 == var_0_7:pugong(arg_146_0:getTableID()) then
		var_146_0 = arg_146_0.level_
	else
		local var_146_1 = arg_146_0:getSkillId()

		for iter_146_0, iter_146_1 in ipairs(var_146_1) do
			if iter_146_1 == arg_146_1 then
				var_146_0 = arg_146_0:getSkillLevel(iter_146_0)

				break
			end
		end
	end

	if type(var_146_0) == "boolean" then
		return var_146_0
	end

	local var_146_2 = arg_146_0:getBookShelfSkillLevel()

	if var_146_0 > arg_146_0.level_ + var_146_2 then
		var_146_0 = arg_146_0.level_ + var_146_2
	end

	local var_146_3 = var_146_0 + arg_146_0:getExtraSkillLevel()

	if isClient and var_146_3 > var_0_2.MAX_SKILL_LEV then
		var_0_2.exitProgram()
	end

	return var_146_3
end

function var_0_3.skilllevelUp(arg_147_0, arg_147_1, arg_147_2)
	local var_147_0 = {
		partner_id = arg_147_0:getHeroID(),
		skill_index = arg_147_1
	}

	arg_147_0.selfPlayer:setSkillLevel(var_147_0, function(arg_148_0, arg_148_1)
		if arg_148_0 == var_0_2.error.OK then
			arg_147_0.skillLev_[arg_147_1] = math.min(arg_147_0.skillLev_[arg_147_1] + 1, arg_147_0.level_)

			if arg_147_2 then
				arg_147_2(arg_148_0, arg_148_1)
			end
		end
	end)
end

function var_0_3.evolution(arg_149_0, arg_149_1)
	local var_149_0 = {
		partner_id = arg_149_0:getHeroID(),
		hero = arg_149_0
	}

	arg_149_0.selfPlayer:evolveHero(var_149_0, function(arg_150_0, arg_150_1)
		if arg_150_0 == var_0_2.error.OK then
			arg_149_0.star_ = arg_149_0.star_ + 1
		end

		if arg_149_1 then
			arg_149_1(arg_150_0, arg_150_1)
		end
	end)
end

function var_0_3.powerUp(arg_151_0, arg_151_1)
	return
end

function var_0_3.oneKeyPowerUp(arg_152_0, arg_152_1)
	return
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
	return var_0_7:speed(arg_155_0:getTableID())
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

function var_0_3.enhanceSuperEquip(arg_159_0, arg_159_1, arg_159_2)
	var_0_2.Backend.get():request(var_0_2.mid.UPGRADE_SUPER_EQUIP, arg_159_1, function(arg_160_0, arg_160_1)
		if arg_160_0 == var_0_2.error.OK then
			arg_159_0.equips_[arg_159_1.equip_index] = arg_159_0.equips_[arg_159_1.equip_index] + arg_159_1.enhance_times
		end

		if arg_159_2 then
			arg_159_2(arg_160_0, arg_160_1)
		end
	end)
end

function var_0_3.isHasItem(arg_161_0, arg_161_1)
	return arg_161_0:getEquipByIndexShow(arg_161_1):isInBackpack()
end

function var_0_3.canComposeItem(arg_162_0, arg_162_1)
	return arg_162_0:getEquipByIndexShow(arg_162_1):isHasMaterial()
end

function var_0_3.canEquipItem(arg_163_0, arg_163_1)
	local var_163_0 = arg_163_0:getEquipByIndex(arg_163_1)

	if not var_163_0:isCollected() and var_163_0:isInBackpack() and arg_163_0:getLevel() >= var_163_0:getLevel() then
		return true
	elseif not var_163_0:isCollected() and var_163_0:isInBackpack() and arg_163_0:getLevel() < var_163_0:getLevel() then
		return false
	elseif not var_163_0:isCollected() and not var_163_0:isInBackpack() and var_163_0:isHasMaterial() and arg_163_0:getLevel() >= var_163_0:getLevel() then
		return true
	elseif not var_163_0:isCollected() and not var_163_0:isInBackpack() and var_163_0:isHasMaterial() and arg_163_0:getLevel() < var_163_0:getLevel() then
		return false
	end

	return false
end

function var_0_3.setExp(arg_164_0, arg_164_1, arg_164_2)
	local var_164_0 = arg_164_0:getLevel()
	local var_164_1 = var_0_2.tables.partnerExp:totalExp(var_164_0)
	local var_164_2 = var_0_2.tables.partnerExp:totalExp(arg_164_2)

	arg_164_0.exp_ = math.min(arg_164_1, var_164_2)

	if var_164_1 <= arg_164_0.exp_ then
		arg_164_0:setLevel(arg_164_0.exp_, var_164_0, arg_164_2)
	end
end

function var_0_3.addExp(arg_165_0, arg_165_1, arg_165_2)
	local var_165_0 = arg_165_0:getLevel()
	local var_165_1 = var_0_2.tables.partnerExp:totalExp(var_165_0)
	local var_165_2 = var_0_2.tables.partnerExp:totalExp(arg_165_2)

	arg_165_0.exp_ = math.min(arg_165_0.exp_ + arg_165_1, var_165_2)

	if var_165_1 <= arg_165_0.exp_ then
		arg_165_0:setLevel(arg_165_0.exp_, var_165_0, arg_165_2)
	end
end

function var_0_3.setLevel(arg_166_0, arg_166_1, arg_166_2, arg_166_3)
	local var_166_0 = arg_166_2

	for iter_166_0 = arg_166_2, arg_166_3 do
		if arg_166_1 >= var_0_2.tables.partnerExp:totalExp(iter_166_0) then
			var_166_0 = math.min(iter_166_0 + 1, arg_166_3)
		else
			break
		end
	end

	arg_166_0.level_ = var_166_0
end

function var_0_3.stoneSummonHero(arg_167_0, arg_167_1)
	local var_167_0 = {
		table_id = arg_167_0:getTableID(),
		stone = arg_167_0:getSuiPianID(),
		stone_num = var_0_2.TotalStarSuipian[arg_167_0:getStar()]
	}

	arg_167_0.selfPlayer:stoneSummonHero(var_167_0, arg_167_1)
end

function var_0_3.getAttrRates(arg_168_0)
	return var_0_7:attrRates(arg_168_0:getTableID())
end

function var_0_3.getFumoCount(arg_169_0)
	local var_169_0 = arg_169_0.fumo_
	local var_169_1 = 0

	for iter_169_0 = 1, #var_169_0 do
		var_169_1 = var_169_1 + tonumber(var_169_0[iter_169_0])
	end

	return var_169_1
end

function var_0_3.getWithoutAwakeFumoCount(arg_170_0)
	local var_170_0 = arg_170_0.fumo_
	local var_170_1 = 0

	for iter_170_0 = 1, #var_170_0 do
		if arg_170_0:getEquipByIndex(iter_170_0):getTableID() > 0 and var_0_11:isAwakenItem(arg_170_0:getEquipByIndex(iter_170_0):getTableID()) == 0 then
			var_170_1 = var_170_1 + tonumber(var_170_0[iter_170_0])
		end
	end

	return var_170_1
end

function var_0_3.setReportData(arg_171_0, arg_171_1)
	arg_171_0.fighterReport_ = arg_171_1
end

function var_0_3.getReportData(arg_172_0)
	return arg_172_0.fighterReport_
end

function var_0_3.isAwaken(arg_173_0)
	return var_0_7:beforeAwaken(arg_173_0:getTableID()) > 0
end

function var_0_3.isCanAwaken(arg_174_0)
	return var_0_7:isCanAwaken(arg_174_0:getTableID()) > 0
end

function var_0_3.canOpenAwakeTwiceMission(arg_175_0)
	return arg_175_0:awakeTwiceStage() == var_0_2.AwakeTwiceStage.UNSTART and var_0_7:isCanAwakeTwice(arg_175_0:getTableID()) > 0 and arg_175_0:isAwaken() and arg_175_0.level_ >= var_0_2.tables.misc.awakeTwiceOpenLev and arg_175_0.color_ >= var_0_2.tables.misc.awakeTwiceOpenQua
end

function var_0_3.isCanAwakeTwice(arg_176_0)
	return var_0_7:isCanAwakeTwice(arg_176_0:getTableID()) > 0
end

function var_0_3.isCanBloodAwake(arg_177_0)
	if arg_177_0:afterAwakenID() ~= 0 then
		return var_0_7:isCanAwakeTwice(arg_177_0:afterAwakenID()) > 0
	else
		return var_0_7:isCanAwakeTwice(arg_177_0:getTableID()) > 0
	end
end

function var_0_3.getAwakenType(arg_178_0)
	if arg_178_0:isCanBloodAwake() then
		return 2
	elseif arg_178_0:isCanAwaken() and not arg_178_0:isCanBloodAwake() then
		return 1
	else
		return 3
	end
end

function var_0_3.isInAwakingPeriod(arg_179_0)
	if arg_179_0:getEquipList(arg_179_0:getColor()) and next(arg_179_0:getEquipList(arg_179_0:getColor())) then
		for iter_179_0, iter_179_1 in pairs(arg_179_0:getEquipList(arg_179_0:getColor())) do
			if (var_0_11:isAwakenItem(iter_179_1:getTableID()) == 1 or iter_179_1:getTableID() == 0) and not arg_179_0:isAwaken() then
				return true
			end
		end
	end

	return false
end

function var_0_3.isHaveAwakenItem(arg_180_0)
	if arg_180_0:getEquipList(arg_180_0:getColor()) and next(arg_180_0:getEquipList(arg_180_0:getColor())) then
		for iter_180_0, iter_180_1 in pairs(arg_180_0:getEquipList(arg_180_0:getColor())) do
			if iter_180_1 and (var_0_11:isAwakenItem(iter_180_1:getTableID()) == 1 or iter_180_1 == 0) then
				return true
			end
		end
	end

	return false
end

function var_0_3.updateSkinInfo(arg_181_0)
	if arg_181_0.skinId_ and arg_181_0.skinId_ ~= 0 then
		arg_181_0.isSkinOn_ = 1
	else
		arg_181_0.isSkinOn_ = 0
	end

	if arg_181_0.skinIds_ and next(arg_181_0.skinIds_) then
		arg_181_0.hasSkin_ = 1
	else
		arg_181_0.hasSkin_ = 0
	end
end

function var_0_3.setSkinInfo(arg_182_0, arg_182_1, arg_182_2, arg_182_3)
	arg_182_0.skinId_ = arg_182_1
	arg_182_0.illusionSkinId_ = arg_182_3 or arg_182_0.illusionSkinId_

	if arg_182_2 and next(arg_182_2) then
		arg_182_0:apartSkinIds(arg_182_2)
	end

	arg_182_0:updateSkinInfo()
end

function var_0_3.setTableID(arg_183_0, arg_183_1)
	arg_183_0.tableID_ = arg_183_1
end

function var_0_3.isLastColorHasAwakeItem(arg_184_0)
	local var_184_0 = arg_184_0:getColor() - 1

	if var_184_0 <= 0 then
		return false
	end

	local var_184_1 = var_0_7:equipList(arg_184_0:getTableID())

	for iter_184_0, iter_184_1 in pairs(var_184_1[var_184_0]) do
		if iter_184_1 == 0 or var_0_11:isAwakenItem(iter_184_1) == 1 then
			return true
		end
	end

	return false
end

function var_0_3.isBoardHero(arg_185_0)
	if arg_185_0.isBoard and arg_185_0.isBoard > 0 then
		return true
	end

	return false
end

function var_0_3.skillBook(arg_186_0)
	return arg_186_0.skill_book_ or {}
end

function var_0_3.setIsBoardHero(arg_187_0, arg_187_1)
	arg_187_0.isBoard = arg_187_1
end

function var_0_3.getBoardCard(arg_188_0)
	if arg_188_0.boardCard < 1 then
		arg_188_0.boardCard = 1
	end

	return arg_188_0.boardCard or 1, arg_188_0.boardModelID
end

function var_0_3.setBoardCard(arg_189_0, arg_189_1)
	arg_189_0.boardCard = arg_189_1 or 1

	if boardModelID then
		arg_189_0.boardModelID = boardModelID
	end
end

function var_0_3.getBoardModelID(arg_190_0)
	return arg_190_0.boardModelID or 0
end

function var_0_3.setBoardModelID(arg_191_0, arg_191_1)
	arg_191_0.boardModelID = arg_191_1
end

function var_0_3.isHeroMarried(arg_192_0)
	if arg_192_0.isMarried and arg_192_0.isMarried > 0 then
		return true
	end

	return false
end

function var_0_3.setMarried(arg_193_0)
	arg_193_0.isMarried = 1

	var_0_2.EventDispatcher.get():dispatchEvent({
		name = var_0_2.event.HERO_CELL_REFRESH,
		tableID = arg_193_0:getTableID()
	})
end

function var_0_3.getFavorDegree(arg_194_0)
	return arg_194_0.favorDegree or 0
end

function var_0_3.setFavorDegree(arg_195_0, arg_195_1)
	local var_195_0 = var_0_2.ModelManager.get():loadModel(var_0_2.ModelType.SELF_PLAYER):getHeroByID(arg_195_0:getHeroID())

	if var_195_0 then
		var_195_0.favorDegree = arg_195_1 or 0
	end

	arg_195_0.favorDegree = arg_195_1 or 0

	var_0_2.EventDispatcher.get():dispatchEvent({
		name = var_0_2.event.HERO_CELL_REFRESH,
		tableID = arg_195_0:getTableID()
	})
end

function var_0_3.getFavorState(arg_196_0)
	local var_196_0

	if not var_0_7:isOpenDialog(arg_196_0:getTableID()) then
		var_196_0 = var_0_2.FavorState.NOT_OPEN
	elseif arg_196_0:isHeroMarried() then
		var_196_0 = var_0_2.FavorState.MARRIED
	elseif arg_196_0:getFavorDegree() >= var_0_2.tables.misc.libraryFavorLimit then
		var_196_0 = var_0_2.FavorState.FULL
	else
		var_196_0 = var_0_2.FavorState.NOT_FULL
	end

	return var_196_0
end

function var_0_3.getFeedAttrs(arg_197_0)
	return arg_197_0.feedAttrs or {}
end

function var_0_3.setFeedAttrs(arg_198_0, arg_198_1)
	local var_198_0 = var_0_2.ModelManager.get():loadModel(var_0_2.ModelType.SELF_PLAYER):getHeroByID(arg_198_0:getHeroID())

	if var_198_0 then
		var_198_0.feedAttrs = arg_198_1
	end

	arg_198_0.feedAttrs = arg_198_1
end

function var_0_3.isInscriptionOpen(arg_199_0)
	if arg_199_0:isAwakeTwice() and arg_199_0.level_ >= var_0_2.tables.functionOpen:level(var_0_2.FunctionID.ID_INSCRIPTION) then
		return true
	end

	return false
end

function var_0_3.getCoursesInfo(arg_200_0)
	return arg_200_0.coursesInfo or {}
end

function var_0_3.getEqupedCoursesInfo(arg_201_0)
	local var_201_0 = {}

	for iter_201_0, iter_201_1 in pairs(arg_201_0.coursesInfo) do
		if iter_201_1.add_skill and iter_201_1.add_skill > 0 then
			var_201_0[iter_201_0] = iter_201_1
		end
	end

	return var_201_0
end

function var_0_3.setCourseInfo(arg_202_0, arg_202_1, arg_202_2)
	arg_202_0.coursesInfo[tonumber(arg_202_2)] = arg_202_1
end

function var_0_3.getCourseInfo(arg_203_0, arg_203_1)
	return arg_203_0.coursesInfo[tonumber(arg_203_1)]
end

function var_0_3.setCoursesInfo(arg_204_0, arg_204_1)
	arg_204_0.coursesInfo = {}

	for iter_204_0, iter_204_1 in pairs(arg_204_1) do
		arg_204_0.coursesInfo[tonumber(iter_204_0)] = iter_204_1
	end
end

function var_0_3.getCourseSkills(arg_205_0)
	local var_205_0 = arg_205_0:getSkillId()
	local var_205_1 = {}

	for iter_205_0, iter_205_1 in pairs(arg_205_0.skillLev_) do
		local var_205_2 = var_205_0[iter_205_0]

		if iter_205_1 and var_205_2 > 0 and var_0_2.tables.skillLevel:bookOpen(iter_205_0) == 1 then
			var_205_1[iter_205_0] = var_205_2
		end
	end

	return var_205_1
end

function var_0_3.canApplyCourse(arg_206_0)
	local var_206_0 = arg_206_0:getCourseSkills()

	if #table.keys(arg_206_0.coursesInfo or {}) >= #var_206_0 then
		return false
	else
		return true
	end
end

function var_0_3.getSkillCourseId(arg_207_0, arg_207_1)
	local var_207_0 = arg_207_0:getSkillId()

	for iter_207_0, iter_207_1 in pairs(arg_207_0.coursesInfo or {}) do
		local var_207_1 = iter_207_1.add_skill

		if var_207_1 and var_207_1 > 0 and var_207_0[var_207_1] == arg_207_1 then
			return tonumber(iter_207_0)
		end
	end
end

function var_0_3.getSkillIDByIndex(arg_208_0, arg_208_1)
	return arg_208_0.skillIDs_[arg_208_1]
end

function var_0_3.setSkillIDByIndex(arg_209_0, arg_209_1, arg_209_2)
	arg_209_0.selfSkillIDs_[arg_209_1] = arg_209_2
	arg_209_0.skillIDs_[arg_209_1] = arg_209_2
end

function var_0_3.setHouseInfo(arg_210_0, arg_210_1)
	arg_210_0.houseId = arg_210_1.house_id
	arg_210_0.houseTableId = arg_210_1.house_table_id
	arg_210_0.houseComfort = arg_210_1.house_comfort

	if arg_210_1.house_expand_lev then
		arg_210_0.houseExpandLev = arg_210_1.house_expand_lev
	end

	if arg_210_1.house_equips then
		arg_210_0:setHouseEquips(arg_210_1.house_equips)
	end
end

function var_0_3.getHouseInfo(arg_211_0)
	return {
		house_id = arg_211_0.houseId,
		house_table_id = arg_211_0.houseTableId,
		houseComfort = arg_211_0.houseComfort
	}
end

function var_0_3.getHouseEquipsList(arg_212_0, arg_212_1)
	local var_212_0 = {}

	for iter_212_0 = 1, arg_212_1 do
		table.insert(var_212_0, arg_212_0:getDormEquipItemByIndex(iter_212_0))
	end

	return var_212_0
end

function var_0_3.getHouseEquips(arg_213_0)
	return arg_213_0.houseEquips or {}
end

function var_0_3.setHouseEquips(arg_214_0, arg_214_1)
	arg_214_0.houseEquips = arg_214_1
end

function var_0_3.setHouseEquip(arg_215_0, arg_215_1, arg_215_2)
	arg_215_0.houseEquips[arg_215_1] = arg_215_2
end

function var_0_3.getDormItemList(arg_216_0)
	if not arg_216_0.dormItems then
		arg_216_0.dormItems = var_0_7:dormItem(arg_216_0:getFirstTableID())
	end

	return arg_216_0.dormItems
end

function var_0_3.getDormEquipItemByIndex(arg_217_0, arg_217_1)
	arg_217_0.houseEquipList = {}

	if not arg_217_0.houseEquipList[arg_217_1] then
		local var_217_0 = arg_217_0:getDormItemList()[arg_217_1]
		local var_217_1 = var_0_4.new()

		var_217_1:populate({
			table_id = var_217_0
		})

		if arg_217_0.houseEquips and arg_217_0.houseEquips[arg_217_1] and arg_217_0.houseEquips[arg_217_1] > 0 then
			var_217_1:setStateCollected()
		end

		arg_217_0.houseEquipList[arg_217_1] = var_217_1
	end

	return arg_217_0.houseEquipList[arg_217_1]
end

function var_0_3.getSkinDatas(arg_218_0)
	local var_218_0 = {}
	local var_218_1 = arg_218_0:getFirstTableID()
	local var_218_2 = var_0_2.tables.hero:afterAwaken(var_218_1)
	local var_218_3 = var_0_2.tables.hero:skinItem(var_218_1)
	local var_218_4 = arg_218_0.skinIds_
	local var_218_5 = var_0_2.tables.hero:skinHide(arg_218_0:getTableID())
	local var_218_6 = {}

	if var_218_1 > 0 then
		local var_218_7 = {
			modelID = var_0_2.tables.hero:modelID(var_218_1),
			isHave = arg_218_0:isCollected(),
			cardState = var_0_2.CardStatus.NORMAL_CARD
		}

		table.insert(var_218_0, var_218_7)
	end

	if var_218_2 > 0 and var_0_2.tables.hero:isCanAwaken(var_218_1) == 1 then
		local var_218_8 = {
			modelID = var_0_2.tables.hero:modelID(var_218_2)
		}

		var_218_8.isAwaken = true
		var_218_8.isHave = arg_218_0:isAwaken()
		var_218_8.cardState = var_0_2.CardStatus.AWAKE_CARD
		var_218_8.skinSkillID = var_0_2.tables.hero:getSkill(var_218_2, var_0_2.SKILL_INDEX.Awake)

		table.insert(var_218_0, var_218_8)
	end

	for iter_218_0 = 1, #var_218_3 do
		if var_218_3[iter_218_0] > 0 then
			local var_218_9 = {
				modelID = var_0_2.tables.skinSkill:getModelID(var_218_3[iter_218_0]),
				skinItem = var_218_3[iter_218_0]
			}

			var_218_9.skinSkillID = var_0_2.tables.skinSkill:getSkillID(var_218_9.skinItem)

			if var_0_2.isInTable(var_218_4, var_218_9.modelID) then
				var_218_9.isHave = true
			end

			var_218_9.cardState = var_0_2.CardStatus.SKIN_CARD

			table.insert(var_218_0, var_218_9)
		end
	end

	for iter_218_1 = #var_218_0, 1, -1 do
		local var_218_10 = var_218_0[iter_218_1]

		if not var_0_2.isInTable(var_218_4, var_218_10.modelID) and var_0_2.isInTable(var_218_5, var_218_10.skinItem) or var_0_11:skinLastTime(var_218_10.skinItem) > 0 then
			table.remove(var_218_0, iter_218_1)
		end
	end

	return var_218_0
end

function var_0_3.getEvoAttrPoints(arg_219_0)
	return arg_219_0.evoAttrPoints or {}
end

function var_0_3.getEvoStage(arg_220_0)
	return arg_220_0.evoStage or 1
end

function var_0_3.setEvoInfo(arg_221_0, arg_221_1)
	if arg_221_1.evo_attr_points then
		arg_221_0.evoAttrPoints = arg_221_1.evo_attr_points
	end

	if arg_221_1.evo_stage then
		arg_221_0.evoStage = arg_221_1.evo_stage
	end
end

function var_0_3.setEvoStage(arg_222_0, arg_222_1)
	arg_222_0.evoStage = arg_222_1 or 1
end

function var_0_3.getHeroVoiceState(arg_223_0)
	local var_223_0
	local var_223_1
	local var_223_2 = {
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
	local var_223_3 = {
		true,
		true,
		true,
		true,
		true,
		true,
		true,
		true,
		true
	}

	return var_223_2, var_223_3
end

function var_0_3.isSuper(arg_224_0)
	return true
end

function var_0_3.getUnlockedDynamicCards(arg_225_0)
	return arg_225_0.unlockedDynamicCards or {}
end

function var_0_3.unlockDynamicCard(arg_226_0, arg_226_1, arg_226_2)
	local var_226_0 = {
		model_id = arg_226_1,
		partner_id = arg_226_0:getHeroID()
	}

	var_0_2.Backend.get():request(var_0_2.mid.UNLOCK_DYNAMIC_CARD, var_226_0, function(arg_227_0, arg_227_1)
		if arg_227_0 == var_0_2.error.OK then
			arg_226_0.unlockedDynamicCards = var_0_2.splitToNumber(arg_227_1.unlocked_dynamic_card or "", "|")
			arg_226_0.dynamicCardState = var_0_2.splitToNumber(arg_227_1.dynamic_card_state or "", "|")

			if arg_226_2 then
				arg_226_2()
			end
		end
	end)
end

function var_0_3.isUnlockDynamicCard(arg_228_0, arg_228_1)
	local var_228_0 = arg_228_0:getUnlockedDynamicCards()

	for iter_228_0 = 1, #var_228_0 do
		if var_228_0[iter_228_0] == arg_228_1 then
			return true
		end
	end

	return false
end

function var_0_3.getDynamicCardState(arg_229_0, arg_229_1)
	local var_229_0 = arg_229_0:getUnlockedDynamicCards()

	for iter_229_0 = 1, #var_229_0 do
		if var_229_0[iter_229_0] == arg_229_1 then
			return arg_229_0.dynamicCardState[iter_229_0]
		end
	end
end

function var_0_3.changeDynamicCardState(arg_230_0, arg_230_1, arg_230_2)
	local var_230_0 = arg_230_0:getUnlockedDynamicCards()
	local var_230_1
	local var_230_2

	for iter_230_0 = 1, #var_230_0 do
		if var_230_0[iter_230_0] == arg_230_1 then
			var_230_1 = iter_230_0
			var_230_2 = 1 - arg_230_0.dynamicCardState[iter_230_0]

			break
		end
	end

	if not var_230_1 then
		return
	end

	local var_230_3 = {
		model_id = arg_230_1,
		partner_id = arg_230_0:getHeroID(),
		is_show = var_230_2
	}

	var_0_2.Backend.get():request(var_0_2.mid.SHOW_DYNAMIC_CARD, var_230_3, function(arg_231_0, arg_231_1)
		if arg_231_0 == var_0_2.error.OK then
			arg_230_0.dynamicCardState[var_230_1] = var_230_2

			if arg_230_2 then
				arg_230_2()
			end
		end
	end)
end

function var_0_3.isSuper(arg_232_0)
	if arg_232_0.partnerType == var_0_2.PartnerType.SUPER then
		return true
	end

	return false
end

function var_0_3.canEnvolve(arg_233_0)
	if var_0_2.isSuperHero(arg_233_0) then
		if arg_233_0:getStar() <= var_0_2.MAX_STAR_LEVEL or arg_233_0:getStar() >= 8 or arg_233_0:getStar() > var_0_2.MAX_STAR_LEVEL and arg_233_0:getStar() < 8 and arg_233_0:getSuiPian() < var_0_2.StarLevelSuipian[arg_233_0:getStar() + 1] then
			return false
		end
	elseif arg_233_0:getStar() >= var_0_2.MAX_STAR_LEVEL or arg_233_0:getSuiPian() < var_0_2.StarLevelSuipian[arg_233_0:getStar() + 1] then
		return false
	end

	return true
end

function var_0_3.apartSkinIds(arg_234_0, arg_234_1)
	arg_234_0.skinIds_ = {}
	arg_234_0.timeLimitSkins = {}

	if arg_234_1 and next(arg_234_1) then
		local var_234_0 = false

		for iter_234_0, iter_234_1 in pairs(arg_234_1) do
			if type(iter_234_0) == "number" then
				var_234_0 = true

				break
			end

			if iter_234_1 == -1 then
				table.insert(arg_234_0.skinIds_, tonumber(iter_234_0))
			else
				arg_234_0.timeLimitSkins[iter_234_0] = iter_234_1
			end
		end

		if var_234_0 then
			arg_234_0.skinIds_ = arg_234_1
		end
	end

	if next(arg_234_0.timeLimitSkins) then
		if arg_234_0.timeLimitSkinsHandle then
			scheduler.unscheduleGlobal(arg_234_0.timeLimitSkinsHandle)

			arg_234_0.timeLimitSkinsHandle = nil
		end

		arg_234_0.timeLimitSkinsHandle = scheduler.scheduleGlobal(function()
			if display.getRunningScene().__cname == "MainScene" then
				if not next(arg_234_0.timeLimitSkins) then
					scheduler.unscheduleGlobal(arg_234_0.timeLimitSkinsHandle)

					arg_234_0.timeLimitSkinsHandle = nil
				end

				local var_235_0 = var_0_2.ServerTime.get():getServerTime()

				for iter_235_0, iter_235_1 in pairs(arg_234_0.timeLimitSkins) do
					if iter_235_1 > 0 and iter_235_1 < var_235_0 then
						arg_234_0.timeLimitSkins[iter_235_0] = 0

						if tonumber(iter_235_0) == tonumber(arg_234_0.skinId_) then
							arg_234_0:setSkinInfo(0)

							local var_235_1 = {
								partner_id = arg_234_0:getHeroID()
							}

							var_0_2.Backend.get():request(var_0_2.mid.SKIN_CANCEL, var_235_1, function(arg_236_0, arg_236_1)
								if arg_236_0 == var_0_2.error.OK then
									-- block empty
								end
							end)

							local var_235_2 = {
								partner_id = arg_234_0:getHeroID()
							}

							var_235_2.item_id = 0

							var_0_2.Backend.get():request(var_0_2.mid.USE_ILLUSION_SKIN_ITEM, var_235_2, function(arg_237_0, arg_237_1)
								if arg_237_0 == var_0_2.error.OK then
									arg_234_0.illusionSkinId_ = 0
								end
							end)
						end
					end
				end
			end
		end, 5)
	end
end

function var_0_3.mergeSkinIds(arg_238_0)
	local var_238_0 = {}

	if arg_238_0.skinIds_ and next(arg_238_0.skinIds_) then
		for iter_238_0, iter_238_1 in ipairs(arg_238_0.skinIds_) do
			var_238_0[tostring(iter_238_1)] = -1
		end
	end

	if arg_238_0.timeLimitSkins and next(arg_238_0.timeLimitSkins) then
		for iter_238_2, iter_238_3 in ipairs(arg_238_0.timeLimitSkins) do
			var_238_0[tostring(iter_238_2)] = iter_238_3
		end
	end

	return var_238_0
end

function var_0_3.getTempSkinItemId(arg_239_0, arg_239_1)
	local var_239_0 = var_0_11:skinModel(arg_239_1)
	local var_239_1 = arg_239_0:getFirstTableID()
	local var_239_2 = var_0_2.tables.hero:skinItem(var_239_1)

	for iter_239_0 = 1, #var_239_2 do
		if var_239_2[iter_239_0] > 0 and var_0_11:skinModel(var_239_2[iter_239_0]) == var_239_0 and var_0_11:skinLastTime(var_239_2[iter_239_0]) > 0 then
			return var_239_2[iter_239_0]
		end
	end

	return 0
end

function var_0_3.getElementEquips(arg_240_0)
	if not arg_240_0.elementEquips_ and not arg_240_0.elementEquipsLevel_ and arg_240_0:getHeroID() == var_0_19 then
		arg_240_0.elementEquips_ = var_0_7:elementEquips(arg_240_0:getTableID())
		arg_240_0.elementEquipsLevel_ = var_0_7:elementEquipsLevel(arg_240_0:getTableID())
	end

	return arg_240_0.elementEquips_, arg_240_0.elementEquipsLevel_
end

function var_0_3.getElementBindingEquips(arg_241_0)
	return arg_241_0.elementBindingEquips_, arg_241_0.elementBindingEquipsLevel_
end

function var_0_3.getElementAttr(arg_242_0, arg_242_1)
	local var_242_0 = 0
	local var_242_1, var_242_2 = arg_242_0:getElementEquips()

	if var_242_1 then
		for iter_242_0 = 1, #var_242_1 do
			local var_242_3 = tonumber(var_242_1[iter_242_0])
			local var_242_4 = var_0_14:itemID(var_242_3)

			if var_242_3 ~= 0 and arg_242_1 == var_0_14:attr(var_242_4) then
				local var_242_5, var_242_6 = var_0_14:battleAttr(var_242_4, var_242_2[iter_242_0])

				var_242_0 = var_242_5 * arg_242_0:getElementEquipActiveRate(var_242_4)

				return var_242_0
			end
		end
	end

	return var_242_0
end

function var_0_3.getElementType(arg_243_0)
	local var_243_0 = arg_243_0:getElementEquips()

	if var_243_0 and var_243_0[var_0_2.ElementCoreIndex] then
		local var_243_1 = var_0_14:itemID(var_243_0[var_0_2.ElementCoreIndex])

		return (var_0_14:element(var_243_1))
	else
		return var_0_7:elementType(arg_243_0:getTableID())
	end
end

function var_0_3.getElementEquipActiveRate(arg_244_0, arg_244_1)
	local var_244_0 = var_0_14:element(arg_244_1)

	if var_0_14:equipType(arg_244_1) == var_0_2.ElementEquipType.NORMAL and var_244_0 == arg_244_0:getElementType() then
		if var_0_14:partnerID(arg_244_1) == arg_244_0:getFirstTableID() then
			return 1 + var_0_14:activeSP(arg_244_1)
		else
			return 1 + var_0_14:active(arg_244_1)
		end
	end

	return 1
end

function var_0_3.isActiveSP(arg_245_0)
	local var_245_0 = arg_245_0:getElementEquips()

	if var_245_0 and var_245_0[var_0_2.ElementCoreIndex] then
		local var_245_1 = var_0_14:itemID(var_245_0[var_0_2.ElementCoreIndex])

		return var_0_14:partnerID(var_245_1) == arg_245_0:getFirstTableID()
	end

	return false
end

function var_0_3.setSpiritEquips(arg_246_0, arg_246_1)
	arg_246_0.spiritEquip_ = arg_246_1

	if arg_246_0.spiritItems_ and isClient then
		for iter_246_0, iter_246_1 in ipairs(arg_246_0.spiritEquip_) do
			if iter_246_1 ~= 0 then
				local var_246_0 = arg_246_0.selfPlayer:getBackpack():getSpiritItemBySpiritID(iter_246_1)

				arg_246_0.spiritItems_[iter_246_0] = var_246_0
			else
				arg_246_0.spiritItems_[iter_246_0] = {}
			end
		end
	end
end

function var_0_3.getSpiritEquips(arg_247_0)
	return arg_247_0.spiritEquip_ or {}
end

function var_0_3.getSpiritSuitID(arg_248_0)
	local var_248_0 = arg_248_0:getSpiritEquips()

	arg_248_0.spiritSuit2_ = {}
	arg_248_0.spiritSuit4_ = 0

	local var_248_1 = {}

	for iter_248_0, iter_248_1 in ipairs(var_248_0) do
		if iter_248_1 ~= 0 then
			local var_248_2

			if isClient then
				if arg_248_0.spiritItems_ then
					var_248_2 = arg_248_0.spiritItems_[iter_248_0]
				else
					var_248_2 = arg_248_0.selfPlayer:getBackpack():getSpiritItemBySpiritID(iter_248_1)
				end
			elseif not arg_248_0.spiritItems_[iter_248_0] then
				var_248_2 = var_0_5:new(arg_248_0.playerID_, iter_248_1):get_info()
				arg_248_0.spiritItems_[iter_248_0] = var_248_2
			else
				var_248_2 = arg_248_0.spiritItems_[iter_248_0]
			end

			local var_248_3 = var_0_2.tables.spiritEquip:from(var_248_2.table_id)

			if not var_248_1[var_248_3] then
				var_248_1[var_248_3] = 1
			else
				var_248_1[var_248_3] = var_248_1[var_248_3] + 1
			end
		end
	end

	for iter_248_2, iter_248_3 in pairs(var_248_1) do
		if iter_248_3 >= 2 then
			table.insert(arg_248_0.spiritSuit2_, iter_248_2)
		end

		if iter_248_3 >= 4 then
			arg_248_0.spiritSuit4_ = iter_248_2
		end
	end

	return arg_248_0.spiritSuit2_, arg_248_0.spiritSuit4_
end

function var_0_3.getSpiritEquipsAttr(arg_249_0, arg_249_1)
	local var_249_0 = arg_249_0:getSpiritEquips()
	local var_249_1 = 0

	for iter_249_0, iter_249_1 in ipairs(var_249_0) do
		if iter_249_1 ~= 0 then
			local var_249_2

			if isClient then
				if arg_249_0.spiritItems_ then
					var_249_2 = arg_249_0.spiritItems_[iter_249_0]
				else
					var_249_2 = arg_249_0.selfPlayer:getBackpack():getSpiritItemBySpiritID(iter_249_1)
				end
			elseif not arg_249_0.spiritItems_[iter_249_0] then
				var_249_2 = var_0_5:new(arg_249_0.playerID_, iter_249_1):get_info()
				arg_249_0.spiritItems_[iter_249_0] = var_249_2
			else
				var_249_2 = arg_249_0.spiritItems_[iter_249_0]
			end

			local var_249_3 = var_249_2.table_id
			local var_249_4 = var_0_17:from(var_249_3)
			local var_249_5 = var_0_17:modelId(var_249_3)

			if var_0_16:main(var_249_5, var_249_2.main) == arg_249_1 then
				var_249_1 = var_249_1 + var_249_2.main_attr_value
			end

			if var_249_2.sub then
				for iter_249_2 = 1, #var_249_2.sub do
					local var_249_6 = var_249_2.sub[iter_249_2]

					if var_0_16:sub(var_249_5, var_249_6) == arg_249_1 then
						var_249_1 = var_249_1 + var_249_2.sub_attr_value[iter_249_2]
					end
				end
			end
		end
	end

	local var_249_7 = arg_249_0:getSpiritSuitID()

	for iter_249_3, iter_249_4 in ipairs(var_249_7) do
		local var_249_8 = var_0_18:attr2(iter_249_4)
		local var_249_9 = var_0_18:attr2Value(iter_249_4)

		if var_249_8 == arg_249_1 then
			var_249_1 = var_249_1 + var_249_9
		end
	end

	if arg_249_1 == var_0_2.AttributeType.HP then
		var_249_1 = var_249_1 * (1 + arg_249_0:getSpiritEquipsAttr(var_0_2.AttributeType.HUNQI_HP_BONUS) / var_0_2.DECIMAL_BASE)
	elseif arg_249_1 == var_0_2.AttributeType.AD or arg_249_1 == var_0_2.AttributeType.AP then
		var_249_1 = var_249_1 * (1 + arg_249_0:getSpiritEquipsAttr(var_0_2.AttributeType.HUNQI_AD_AP_BONUS) / var_0_2.DECIMAL_BASE)
	elseif arg_249_1 == var_0_2.AttributeType.HUJIA or arg_249_1 == var_0_2.AttributeType.MOKANG then
		var_249_1 = var_249_1 * (1 + arg_249_0:getSpiritEquipsAttr(var_0_2.AttributeType.HUNQI_JIAKANG_BONUS) / var_0_2.DECIMAL_BASE)
	end

	return var_249_1
end

function var_0_3.setCollocation(arg_250_0, arg_250_1, arg_250_2)
	local var_250_0 = {
		is_like = arg_250_1 or 1 - arg_250_0.isLike,
		partner_id = arg_250_0:getHeroID()
	}

	var_0_2.Backend.get():request(var_0_2.mid.HERO_COLLOCATION, var_250_0, function(arg_251_0, arg_251_1)
		if arg_251_0 == var_0_2.error.OK then
			arg_250_0.isLike = var_250_0.is_like
		end

		if arg_250_2 then
			arg_250_2(arg_251_0, arg_251_1)
		end
	end)
end

function var_0_3.isCollocation(arg_252_0)
	return arg_252_0.isLike and arg_252_0.isLike == 1
end

return var_0_3
