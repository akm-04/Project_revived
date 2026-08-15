local var_0_0 = ngx
local var_0_1 = require("lib.battle.framework.cocos")
local var_0_2 = var_0_1.getXinyoudi(var_0_0)
local var_0_3 = var_0_1.class("Pet")
local var_0_4 = _G.isClient
local var_0_5 = var_0_4 and require("app.model.Item") or require("lib.battle.app.model.Item")
local var_0_6 = 3
local var_0_7 = -1
local var_0_8 = var_0_2.tables.hero
local var_0_9 = var_0_2.tables.skill
local var_0_10 = var_0_2.tables.dbuff
local var_0_11 = var_0_2.tables.model
local var_0_12 = var_0_2.tables.item
local var_0_13 = var_0_2.tables.petExp
local var_0_14 = math
local var_0_15 = var_0_2.tables.translation

function var_0_3.ctor(arg_1_0)
	arg_1_0.petID_ = var_0_7
	arg_1_0.playerID_ = 0
	arg_1_0.isPet_ = true
	arg_1_0.exp_ = 0
	arg_1_0.selfPlayer = var_0_4 and var_0_2.ModelManager.get():loadModel(var_0_2.ModelType.SELF_PLAYER)
end

function var_0_3.onRegister(arg_2_0)
	return
end

function var_0_3.initUnCollected(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	arg_3_3 = arg_3_3 or {}
	arg_3_0.tableID_ = arg_3_1
	arg_3_0.petID_ = arg_3_2 or var_0_7
	arg_3_0.star_ = arg_3_3.star or var_0_8:initialStar(arg_3_1)
	arg_3_0.level_ = arg_3_3.lev or 1
	arg_3_0.color_ = arg_3_3.color or 1
	arg_3_0.isCollected_ = arg_3_3.isCollected or false
	arg_3_0.exp_ = arg_3_3.exp or 0
	arg_3_0.practice_attr_ = {
		0,
		0,
		0
	}
	arg_3_0.birthday_ = arg_3_3.birthday or 0
	arg_3_0.is_born_ = arg_3_3.is_born or 0
	arg_3_0.is_show_ = arg_3_3.is_show or 0

	local var_3_0 = arg_3_3.skills or {
		1,
		1,
		1,
		1
	}

	arg_3_0.skillLev_ = {}
	arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Energy] = tonumber(var_3_0[var_0_2.SKILL_INDEX.Energy]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Energy]

	if arg_3_0.color_ >= var_0_2.EquipQuality.GREEN then
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Green] = tonumber(var_3_0[var_0_2.SKILL_INDEX.Green]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Green]
	else
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Green] = 0
	end

	if arg_3_0.color_ >= var_0_2.EquipQuality.BLUE then
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Blue] = tonumber(var_3_0[var_0_2.SKILL_INDEX.Blue]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Blue]
	else
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Blue] = 0
	end

	if arg_3_0.color_ >= var_0_2.EquipQuality.PURPLE then
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Purple] = tonumber(var_3_0[var_0_2.SKILL_INDEX.Purple]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Purple]
	else
		arg_3_0.skillLev_[var_0_2.SKILL_INDEX.Purple] = 0
	end

	local var_3_1 = arg_3_3.equip or {
		0,
		0,
		0
	}

	arg_3_0.equips_ = {}

	for iter_3_0 = 1, var_0_6 do
		table.insert(arg_3_0.equips_, tonumber(var_3_1[iter_3_0]))
	end

	local var_3_2 = arg_3_3.fumos or {
		0,
		0,
		0
	}

	arg_3_0.fumo_ = {}

	for iter_3_1 = 1, var_0_6 do
		table.insert(arg_3_0.fumo_, tonumber(var_3_2[iter_3_1]))
	end
end

function var_0_3.populate(arg_4_0, arg_4_1)
	arg_4_0.playerID_ = tonumber(arg_4_1.player_id or 0)
	arg_4_0.petID_ = tonumber(arg_4_1.pet_id)
	arg_4_0.tableID_ = tonumber(arg_4_1.table_id)
	arg_4_0.star_ = tonumber(arg_4_1.star)
	arg_4_0.level_ = tonumber(arg_4_1.lev or 1)
	arg_4_0.exp_ = tonumber(arg_4_1.exp or 0)
	arg_4_0.color_ = tonumber(arg_4_1.color or 1)
	arg_4_0.birthday_ = tonumber(arg_4_1.birthday or 0)
	arg_4_0.is_born_ = tonumber(arg_4_1.is_born or 0)
	arg_4_0.is_show_ = tonumber(arg_4_1.is_show or 0)
	arg_4_0.activeStyle = tonumber(arg_4_1.active_style or 0)
	arg_4_0.petStyles = arg_4_1.pet_styles or {}
	arg_4_0.isCollected_ = true

	local var_4_0 = arg_4_1.skills or {
		1,
		1,
		1,
		1,
		1
	}

	arg_4_0.skillLev_ = {}
	arg_4_0.skillLev_[var_0_2.SKILL_INDEX.Energy] = tonumber(var_4_0[var_0_2.SKILL_INDEX.Energy]) + var_0_2.PET_SKILL_EXTRA[var_0_2.SKILL_INDEX.Energy]

	if arg_4_0.color_ >= var_0_2.EquipQuality.GREEN then
		arg_4_0.skillLev_[var_0_2.SKILL_INDEX.Green] = tonumber(var_4_0[var_0_2.SKILL_INDEX.Green]) + var_0_2.PET_SKILL_EXTRA[var_0_2.SKILL_INDEX.Green]
	else
		arg_4_0.skillLev_[var_0_2.SKILL_INDEX.Green] = 0
	end

	if arg_4_0.color_ >= var_0_2.EquipQuality.BLUE then
		arg_4_0.skillLev_[var_0_2.SKILL_INDEX.Blue] = tonumber(var_4_0[var_0_2.SKILL_INDEX.Blue]) + var_0_2.PET_SKILL_EXTRA[var_0_2.SKILL_INDEX.Blue]
	else
		arg_4_0.skillLev_[var_0_2.SKILL_INDEX.Blue] = 0
	end

	if arg_4_0.color_ >= var_0_2.EquipQuality.PURPLE then
		arg_4_0.skillLev_[var_0_2.SKILL_INDEX.Purple] = tonumber(var_4_0[var_0_2.SKILL_INDEX.Purple]) + var_0_2.PET_SKILL_EXTRA[var_0_2.SKILL_INDEX.Purple]
	else
		arg_4_0.skillLev_[var_0_2.SKILL_INDEX.Purple] = 0
	end

	if arg_4_0:isAwaken() then
		arg_4_0.skillLev_[var_0_2.SKILL_INDEX.Awake] = tonumber(var_4_0[var_0_2.SKILL_INDEX.Awake]) + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Awake]
	else
		arg_4_0.skillLev_[var_0_2.SKILL_INDEX.Awake] = 0
	end

	local var_4_1 = arg_4_1.equips or {
		0,
		0,
		0
	}

	arg_4_0.equips_ = {}

	for iter_4_0 = 1, var_0_6 do
		table.insert(arg_4_0.equips_, tonumber(var_4_1[iter_4_0]))
	end

	local var_4_2 = arg_4_1.practice_attr or {
		0,
		0,
		0
	}

	arg_4_0.practice_attr_ = {}

	for iter_4_1 = 1, 3 do
		table.insert(arg_4_0.practice_attr_, tonumber(var_4_2[iter_4_1]))
	end

	arg_4_0:updatePracticeAwardAttr()

	local var_4_3 = arg_4_1.fumos or {
		0,
		0,
		0
	}

	arg_4_0.fumo_ = {}

	for iter_4_2 = 1, var_0_6 do
		table.insert(arg_4_0.fumo_, tonumber(var_4_3[iter_4_2]))
	end
end

function var_0_3.toParams(arg_5_0)
	local var_5_0 = {
		player_id = arg_5_0.playerID_,
		pet_id = arg_5_0.petID_,
		table_id = arg_5_0.tableID_,
		star = arg_5_0.star_,
		lev = arg_5_0.level_,
		exp = arg_5_0.exp_,
		color = arg_5_0.color_,
		equips = arg_5_0.equips_,
		fumos = arg_5_0.fumo_,
		birthday = arg_5_0.birthday_,
		is_born = arg_5_0.is_born_,
		practice_attr = arg_5_0.practice_attr_,
		is_show = arg_5_0.is_show_
	}
	local var_5_1 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.skillLev_) do
		if iter_5_1 then
			var_5_1[iter_5_0] = iter_5_1 < 1 and var_0_2.PET_SKILL_EXTRA[iter_5_0] + 1 - var_0_2.PET_SKILL_EXTRA[iter_5_0] or iter_5_1 - var_0_2.PET_SKILL_EXTRA[iter_5_0]
		end
	end

	var_5_0.skills = var_5_1

	return var_5_0
end

function var_0_3.toString(arg_6_0)
	return json.encode(arg_6_0:toParams())
end

function var_0_3.getPractice(arg_7_0)
	return arg_7_0.practice_attr_ or {
		0,
		0,
		0
	}
end

function var_0_3.updatePractice(arg_8_0, arg_8_1)
	arg_8_0.practice_attr_ = arg_8_1

	arg_8_0:updatePracticeAwardAttr()
end

function var_0_3.updatePracticeAwardAttr(arg_9_0)
	local var_9_0 = var_0_8:getPracticeNeeds(arg_9_0:getTableID())
	local var_9_1 = var_0_8:getPracticeAttrType(arg_9_0:getTableID())
	local var_9_2 = var_0_8:getPracticeAttrValue(arg_9_0:getTableID())

	if #var_9_0 ~= 3 or #var_9_1 ~= 3 or #var_9_2 ~= 3 then
		return
	end

	arg_9_0.practiceAwardAttrs = {}

	for iter_9_0 = 1, #var_9_0 do
		if arg_9_0.practice_attr_[iter_9_0] >= var_9_0[iter_9_0] then
			arg_9_0.practiceAwardAttrs[var_9_1[iter_9_0]] = var_9_2[iter_9_0]
		end
	end
end

function var_0_3.getPlayerID(arg_10_0)
	return arg_10_0.playerID_
end

function var_0_3.setPlayerID(arg_11_0, arg_11_1)
	arg_11_0.playerID_ = arg_11_1
end

function var_0_3.getPetID(arg_12_0)
	return arg_12_0.petID_
end

function var_0_3.isBorn(arg_13_0)
	return arg_13_0.is_show_
end

function var_0_3.getTableID(arg_14_0)
	return arg_14_0.tableID_
end

function var_0_3.getFirstTableID(arg_15_0)
	local var_15_0 = arg_15_0:getTableID()

	if arg_15_0:isAwaken() then
		var_15_0 = arg_15_0:beforeAwakenID()
	end

	return var_15_0
end

function var_0_3.getStar(arg_16_0)
	return arg_16_0.star_
end

function var_0_3.isShow(arg_17_0)
	return var_0_8:isShow(arg_17_0:getTableID())
end

function var_0_3.getLevel(arg_18_0)
	return arg_18_0.level_
end

function var_0_3.isHomeSkinOn(arg_19_0)
	if arg_19_0.activeStyle and arg_19_0.activeStyle > 0 then
		return true
	end

	return false
end

function var_0_3.getHomeSkinID(arg_20_0)
	return arg_20_0.activeStyle
end

function var_0_3.setHomeSkinID(arg_21_0, arg_21_1)
	arg_21_0.activeStyle = arg_21_1
end

function var_0_3.getHomeStyles(arg_22_0)
	return arg_22_0.petStyles or {}
end

function var_0_3.setHomeStyles(arg_23_0, arg_23_1)
	arg_23_0.petStyles = arg_23_1
end

function var_0_3.checkHomeStyleIsUsed(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_0:getHomeStyles()

	for iter_24_0, iter_24_1 in pairs(var_24_0) do
		if iter_24_1 == arg_24_1 then
			return true
		end
	end

	return false
end

function var_0_3.getSuiPian(arg_25_0)
	if not arg_25_0:getSuiPianID() or arg_25_0:getSuiPianID() == 0 then
		return 0
	end

	local var_25_0 = arg_25_0.selfPlayer:getBackpack()

	if var_25_0 == nil then
		return 0
	end

	return var_25_0:getItemNumByID(arg_25_0:getSuiPianID())
end

function var_0_3.getSuiPianID(arg_26_0)
	return var_0_8:stoneID(arg_26_0:getTableID())
end

function var_0_3.isHasEgg(arg_27_0)
	if arg_27_0:getSuiPian() >= var_0_2.TotalStarSuipian[arg_27_0:getStar()] then
		return true
	end

	if not arg_27_0:getEgg() or arg_27_0:getEgg() == 0 then
		return false
	end

	local var_27_0 = arg_27_0.selfPlayer:getBackpack()

	if var_27_0 == nil then
		return false
	end

	if var_27_0:getItemNumByID(arg_27_0:getEgg()) >= 1 then
		return true
	else
		return false
	end
end

function var_0_3.getEgg(arg_28_0)
	return var_0_8:getEgg(arg_28_0:getTableID())
end

function var_0_3.isCollected(arg_29_0)
	return arg_29_0.isCollected_ or false
end

function var_0_3.getExp(arg_30_0)
	return arg_30_0.exp_
end

function var_0_3.getColor(arg_31_0)
	return arg_31_0.color_
end

function var_0_3.getName(arg_32_0)
	return var_0_8:name(arg_32_0:getTableID())
end

function var_0_3.getModelID(arg_33_0)
	if arg_33_0:getStar() == 1 then
		return var_0_8:modelID(arg_33_0:getTableID())
	else
		return var_0_8:modelIDs(arg_33_0:getTableID())[arg_33_0:getStar() - 1]
	end
end

function var_0_3.getModelIDs(arg_34_0)
	return var_0_8:modelIDs(arg_34_0:getTableID())
end

function var_0_3.className(arg_35_0)
	return var_0_8:className(arg_35_0:getTableID())
end

function var_0_3.getZhandouli(arg_36_0)
	return var_0_14.ceil(arg_36_0:getBasicForce() + arg_36_0:getEquipForce() + arg_36_0:getSkillForce())
end

function var_0_3.getBasicForce(arg_37_0)
	local var_37_0 = 0

	for iter_37_0 = 1, 3 do
		local var_37_1 = var_0_8:getHeroMainAttr(arg_37_0:getTableID(), iter_37_0, arg_37_0:getStar(), arg_37_0:getLevel())
		local var_37_2 = var_0_2.JINJIE_ATTR_RATE * (arg_37_0:getColor() - 1) / 2 * arg_37_0:getColor()
		local var_37_3 = var_0_8:getInitialAttr(arg_37_0:getTableID(), iter_37_0)

		var_37_0 = var_37_0 + (var_37_1 + var_37_2 + var_37_3) * var_0_2.tables.attr:attrScore(iter_37_0)
	end

	for iter_37_1 = 4, var_0_2.AttributeType.TOTAL_NUM do
		var_37_0 = var_37_0 + var_0_8:getInitialAttr(arg_37_0:getTableID(), iter_37_1) * var_0_2.tables.attr:attrScore(iter_37_1)
	end

	return var_37_0
end

function var_0_3.getEquipForce(arg_38_0)
	local var_38_0 = 0

	for iter_38_0 = 1, var_0_2.AttributeType.TOTAL_NUM do
		var_38_0 = var_38_0 + (arg_38_0:getJinjieEquipAttr(iter_38_0) + arg_38_0:getEquipAttr(iter_38_0) + arg_38_0:getTotalPracticeAttr(iter_38_0)) * var_0_2.tables.attr:attrScore(iter_38_0)
	end

	return var_38_0
end

function var_0_3.getSkillForce(arg_39_0)
	local var_39_0 = 0

	for iter_39_0 = 1, var_0_2.SKILL_INDEX.Awake do
		local var_39_1 = arg_39_0.skillLev_[iter_39_0]

		if var_39_1 and var_39_1 > 0 then
			local var_39_2 = tonumber(var_0_8:getSkill(arg_39_0:getTableID(), iter_39_0)) or 0

			if var_39_2 > 0 then
				var_39_0 = var_39_0 + var_0_9:initPower(var_39_2) + var_0_9:stepPower(var_39_2) * var_39_1
			end
		end
	end

	return var_39_0
end

function var_0_3.getScale(arg_40_0)
	return var_0_11:scale(arg_40_0:getModelID())
end

function var_0_3.getSmallCard(arg_41_0)
	return "images/small_card/10001001.png"
end

function var_0_3.getMainAttr(arg_42_0, arg_42_1)
	local var_42_0 = var_0_8:getHeroMainAttr(arg_42_0:getTableID(), arg_42_1, arg_42_0:getStar(), arg_42_0:getLevel())
	local var_42_1 = var_0_2.JINJIE_ATTR_RATE * (arg_42_0:getColor() - 1) / 2 * arg_42_0:getColor()
	local var_42_2 = var_0_8:getInitialAttr(arg_42_0:getTableID(), arg_42_1)
	local var_42_3 = arg_42_0:getJinjieEquipAttr(arg_42_1) + arg_42_0:getEquipAttr(arg_42_1)
	local var_42_4 = arg_42_0:getTotalPracticeAttr(arg_42_1)

	return var_42_0 + var_42_1 + var_42_2 + var_42_3 + var_42_4
end

function var_0_3.getTotalPracticeAttr(arg_43_0, arg_43_1)
	return arg_43_0:getPracticeAwardAttr(arg_43_1) + arg_43_0:getPracticeAttr(arg_43_1)
end

function var_0_3.getPracticeAwardAttr(arg_44_0, arg_44_1)
	if not arg_44_0.practiceAwardAttrs then
		return 0
	end

	return arg_44_0.practiceAwardAttrs[arg_44_1] or 0
end

function var_0_3.getAttrGlow(arg_45_0, arg_45_1)
	return var_0_8:getHeroAttrGrow(arg_45_0:getTableID(), arg_45_1, arg_45_0:getStar())
end

function var_0_3.getSkillAttr(arg_46_0, arg_46_1)
	local var_46_0 = var_0_0.ctx.battle.getRequire("Buff")

	local function var_46_1(arg_47_0, arg_47_1, arg_47_2)
		local var_47_0 = {}

		for iter_47_0, iter_47_1 in ipairs(arg_47_0) do
			local var_47_1 = var_46_0.new({
				start = 0,
				tableID = iter_47_1,
				level = arg_47_1,
				skillID = arg_47_2
			})

			var_47_1:setYongJiu()
			table.insert(var_47_0, var_47_1)
		end

		return var_47_0
	end

	local var_46_2 = var_0_8:buffSkill(arg_46_0:getTableID())

	if not next(var_46_2) then
		return 0
	end

	local var_46_3 = 0

	for iter_46_0, iter_46_1 in ipairs(var_46_2) do
		if var_0_9:skillType(iter_46_1) == var_0_2.SkillType.BUFF_SELF then
			local var_46_4 = arg_46_0:getSkillLevelByID(iter_46_1)

			if var_46_4 and var_46_4 > 0 then
				local var_46_5 = var_0_9:buffs(iter_46_1)
				local var_46_6 = var_46_1(var_46_5, var_46_4, iter_46_1)

				for iter_46_2, iter_46_3 in ipairs(var_46_6) do
					if iter_46_3:getAttrType() == arg_46_1 then
						local var_46_7, var_46_8 = iter_46_3:getAttr()

						if not var_46_8 then
							var_46_3 = var_46_3 + var_46_7
						else
							print("error : buff skill attribute type use percent increase " .. iter_46_3:getTableID())
						end
					end
				end
			end
		end
	end

	return var_46_3
end

function var_0_3.getPracticeAttr(arg_48_0, arg_48_1)
	return arg_48_0.practice_attr_[arg_48_1] or 0
end

function var_0_3.getMaxHP(arg_49_0)
	local var_49_0 = var_0_8:getInitialAttr(arg_49_0:getTableID(), var_0_2.AttributeType.HP)
	local var_49_1 = arg_49_0:getMainAttr(var_0_2.AttributeType.STRENGTH)

	return var_0_14.floor(var_49_0 + var_0_2.STRENGTH_HP_RATE_PET * var_49_1)
end

function var_0_3.skillAttr2HP(arg_50_0)
	local var_50_0 = arg_50_0:getSkillAttr(var_0_2.AttributeType.STRENGTH)

	return var_0_2.STRENGTH_HP_RATE_PET * var_50_0
end

function var_0_3.getAD(arg_51_0)
	local var_51_0 = var_0_8:getInitialAttr(arg_51_0:getTableID(), var_0_2.AttributeType.AD)
	local var_51_1 = arg_51_0:getMainAttr(var_0_2.AttributeType.STRENGTH) * var_0_2.STRENGTH_AD_RATE_PET

	return var_0_14.floor(var_51_1 + var_51_0)
end

function var_0_3.getHeroType(arg_52_0)
	return var_0_8:heroType(arg_52_0:getTableID())
end

function var_0_3.skillAttr2AD(arg_53_0)
	return arg_53_0:getSkillAttr(var_0_2.AttributeType.STRENGTH) * var_0_2.STRENGTH_AD_RATE_PET
end

function var_0_3.getAP(arg_54_0)
	local var_54_0 = var_0_8:getInitialAttr(arg_54_0:getTableID(), var_0_2.AttributeType.AP)
	local var_54_1 = arg_54_0:getMainAttr(var_0_2.AttributeType.WISE) * var_0_2.WISE_AP_RATE_PET

	return var_0_14.floor(var_54_0 + var_54_1)
end

function var_0_3.skillAttr2AP(arg_55_0)
	return arg_55_0:getSkillAttr(var_0_2.AttributeType.WISE) * var_0_2.WISE_AP_RATE_PET
end

function var_0_3.getHujia(arg_56_0)
	local var_56_0 = var_0_8:getInitialAttr(arg_56_0:getTableID(), var_0_2.AttributeType.HUJIA)
	local var_56_1 = var_0_2.AGILE_HUJIA_RATE_PET * arg_56_0:getMainAttr(var_0_2.AttributeType.AGILE) + var_0_2.STRENGTH_HUJIA_RATE_PET * arg_56_0:getMainAttr(var_0_2.AttributeType.STRENGTH)

	return var_0_14.floor(var_56_1 + var_56_0)
end

function var_0_3.skillAttr2Hujia(arg_57_0)
	local var_57_0 = arg_57_0:getSkillAttr(var_0_2.AttributeType.AGILE)
	local var_57_1 = arg_57_0:getSkillAttr(var_0_2.AttributeType.STRENGTH)

	return var_0_2.AGILE_HUJIA_RATE_PET * var_57_0 + var_0_2.STRENGTH_HUJIA_RATE_PET * var_57_1
end

function var_0_3.getMokang(arg_58_0)
	local var_58_0 = var_0_8:getInitialAttr(arg_58_0:getTableID(), var_0_2.AttributeType.MOKANG)
	local var_58_1 = var_0_2.WISE_MOKANG_RATE_PET * arg_58_0:getMainAttr(var_0_2.AttributeType.WISE)

	return var_0_14.floor(var_58_0 + var_58_1)
end

function var_0_3.skillAttr2Mokang(arg_59_0)
	return var_0_2.WISE_MOKANG_RATE_PET * arg_59_0:getSkillAttr(var_0_2.AttributeType.WISE)
end

function var_0_3.getADBaoji(arg_60_0)
	local var_60_0 = var_0_8:getInitialAttr(arg_60_0:getTableID(), var_0_2.AttributeType.AD_BAOJI)
	local var_60_1 = var_0_2.AGILE_AD_BAOJI_RATE_PET * arg_60_0:getMainAttr(var_0_2.AttributeType.AGILE)

	return var_0_14.floor(var_60_0 + var_60_1)
end

function var_0_3.isAwaken(arg_61_0)
	return var_0_8:beforeAwaken(arg_61_0:getTableID()) > 0
end

function var_0_3.awakenID(arg_62_0)
	return var_0_8:awakenID(arg_62_0:getTableID())
end

function var_0_3.isCanAwaken(arg_63_0)
	return var_0_8:isCanAwaken(arg_63_0:getTableID()) > 0
end

function var_0_3.beforeAwakenID(arg_64_0)
	return var_0_8:beforeAwaken(arg_64_0:getTableID())
end

function var_0_3.afterAwakenID(arg_65_0)
	return var_0_8:afterAwaken(arg_65_0:getTableID())
end

function var_0_3.skillAttr2Baoji(arg_66_0)
	return var_0_2.AGILE_AD_BAOJI_RATE_PET * arg_66_0:getSkillAttr(var_0_2.AttributeType.AGILE)
end

function var_0_3.getSkill2Attr(arg_67_0, arg_67_1)
	if arg_67_1 == var_0_2.AttributeType.HP then
		return arg_67_0:skillAttr2HP()
	elseif arg_67_1 == var_0_2.AttributeType.AD then
		return arg_67_0:skillAttr2AD()
	elseif arg_67_1 == var_0_2.AttributeType.AP then
		return arg_67_0:skillAttr2AP()
	elseif arg_67_1 == var_0_2.AttributeType.HUJIA then
		return arg_67_0:skillAttr2Hujia()
	elseif arg_67_1 == var_0_2.AttributeType.MOKANG then
		return arg_67_0:skillAttr2Mokang()
	elseif arg_67_1 == var_0_2.AttributeType.AD_BAOJI then
		return arg_67_0:skillAttr2Baoji()
	end

	return 0
end

function var_0_3.getTotalAttr(arg_68_0, arg_68_1)
	if arg_68_1 < 4 then
		return arg_68_0:getMainAttr(arg_68_1) + arg_68_0:getSkillAttr(arg_68_1)
	elseif arg_68_1 == var_0_2.AttributeType.HP then
		return arg_68_0:getMaxHP() + arg_68_0:getJinjieEquipAttr(arg_68_1) + arg_68_0:getEquipAttr(arg_68_1) + arg_68_0:getSkillAttr(arg_68_1) + arg_68_0:getSkill2Attr(arg_68_1) + arg_68_0:getTotalPracticeAttr(arg_68_1)
	elseif arg_68_1 == var_0_2.AttributeType.AD then
		return arg_68_0:getAD() + arg_68_0:getJinjieEquipAttr(arg_68_1) + arg_68_0:getEquipAttr(arg_68_1) + arg_68_0:getSkillAttr(arg_68_1) + arg_68_0:getSkill2Attr(arg_68_1) + arg_68_0:getTotalPracticeAttr(arg_68_1)
	elseif arg_68_1 == var_0_2.AttributeType.AP then
		return arg_68_0:getAP() + arg_68_0:getJinjieEquipAttr(arg_68_1) + arg_68_0:getEquipAttr(arg_68_1) + arg_68_0:getSkillAttr(arg_68_1) + arg_68_0:getSkill2Attr(arg_68_1) + arg_68_0:getTotalPracticeAttr(arg_68_1)
	elseif arg_68_1 == var_0_2.AttributeType.HUJIA then
		return arg_68_0:getHujia() + arg_68_0:getJinjieEquipAttr(arg_68_1) + arg_68_0:getEquipAttr(arg_68_1) + arg_68_0:getSkillAttr(arg_68_1) + arg_68_0:getSkill2Attr(arg_68_1) + arg_68_0:getTotalPracticeAttr(arg_68_1)
	elseif arg_68_1 == var_0_2.AttributeType.MOKANG then
		return arg_68_0:getMokang() + arg_68_0:getJinjieEquipAttr(arg_68_1) + arg_68_0:getEquipAttr(arg_68_1) + arg_68_0:getSkillAttr(arg_68_1) + arg_68_0:getSkill2Attr(arg_68_1) + arg_68_0:getTotalPracticeAttr(arg_68_1)
	elseif arg_68_1 == var_0_2.AttributeType.AD_BAOJI then
		return arg_68_0:getADBaoji() + arg_68_0:getJinjieEquipAttr(arg_68_1) + arg_68_0:getEquipAttr(arg_68_1) + arg_68_0:getSkillAttr(arg_68_1) + arg_68_0:getSkill2Attr(arg_68_1) + arg_68_0:getTotalPracticeAttr(arg_68_1)
	elseif arg_68_1 == var_0_2.AttributeType.ENERGY_RATE then
		return 1
	elseif arg_68_1 <= var_0_2.AttributeType.TOTAL_NUM then
		return arg_68_0:getJinjieEquipAttr(arg_68_1) + var_0_8:getInitialAttr(arg_68_0:getTableID(), arg_68_1) + arg_68_0:getEquipAttr(arg_68_1) + arg_68_0:getSkillAttr(arg_68_1) + arg_68_0:getTotalPracticeAttr(arg_68_1)
	else
		return var_0_8:getInitialAttr(arg_68_0:getTableID(), arg_68_1) + arg_68_0:getSkillAttr(arg_68_1) + arg_68_0:getTotalPracticeAttr(arg_68_1)
	end
end

function var_0_3.setupBattleAttrInfo(arg_69_0)
	arg_69_0.totalAttrs_ = {}

	for iter_69_0 = 1, var_0_2.AttributeType.TOTAL_ATTR_NUM do
		arg_69_0.totalAttrs_[iter_69_0] = var_0_1.clone(arg_69_0:getTotalAttr(iter_69_0))
	end
end

function var_0_3.getBattleAttr(arg_70_0, arg_70_1)
	if not arg_70_0.totalAttrs_ then
		arg_70_0:setupBattleAttrInfo()
	end

	return arg_70_0.totalAttrs_[arg_70_1]
end

function var_0_3.getEquipAttr(arg_71_0, arg_71_1)
	local var_71_0 = 0
	local var_71_1 = arg_71_0:getEquipList(arg_71_0:getColor())

	for iter_71_0, iter_71_1 in pairs(var_71_1) do
		if arg_71_0.equips_[iter_71_0] > 0 then
			var_71_0 = var_71_0 + arg_71_0:getEquipAttrByType(arg_71_1, iter_71_1)
		end
	end

	return var_71_0
end

function var_0_3.getJinjieEquipAttr(arg_72_0, arg_72_1)
	local var_72_0 = 0

	for iter_72_0 = 1, arg_72_0:getColor() - 1 do
		local var_72_1 = arg_72_0:getEquipList(iter_72_0)

		for iter_72_1, iter_72_2 in pairs(var_72_1) do
			var_72_0 = var_72_0 + arg_72_0:getEquipAttrByType(arg_72_1, iter_72_2)
		end
	end

	return var_72_0
end

function var_0_3.getEquipList(arg_73_0, arg_73_1)
	if not arg_73_0.totalEquipList_ then
		local var_73_0 = var_0_8:equipList(arg_73_0:getTableID())

		arg_73_0.totalEquipList_ = {}

		for iter_73_0, iter_73_1 in ipairs(var_73_0) do
			local var_73_1 = {}

			for iter_73_2, iter_73_3 in ipairs(iter_73_1) do
				local var_73_2

				if var_0_12:isAwakenItem(iter_73_3) == 1 and not arg_73_0.awakeItem then
					var_73_2 = var_0_5.new()

					local var_73_3 = arg_73_0.fumo_[iter_73_2] or 0

					var_73_2:populate({
						item_id = iter_73_0 * 10 + iter_73_2,
						table_id = iter_73_3,
						moneng = var_73_3
					})

					arg_73_0.awakeItem = var_73_2

					if arg_73_0.equips_[iter_73_2] > 0 and iter_73_0 <= arg_73_0:getColor() then
						var_73_2:setStateCollected()
					end
				elseif var_0_12:isAwakenItem(iter_73_3) == 1 and arg_73_0.awakeItem then
					var_73_2 = arg_73_0.awakeItem
				else
					var_73_2 = var_0_5.new()

					local var_73_4 = iter_73_0 == arg_73_0:getColor() and arg_73_0.fumo_[iter_73_2] or 0

					var_73_2:populate({
						item_id = iter_73_0 * 10 + iter_73_2,
						table_id = iter_73_3,
						moneng = var_73_4
					})

					if iter_73_0 == arg_73_0:getColor() and arg_73_0.equips_[iter_73_2] > 0 then
						var_73_2:setStateCollected()
					end
				end

				table.insert(var_73_1, var_73_2)
			end

			table.insert(arg_73_0.totalEquipList_, var_73_1)
		end
	end

	return arg_73_0.totalEquipList_[arg_73_1]
end

function var_0_3.isAwakeTwice(arg_74_0)
	return arg_74_0.awakeTwiceStage_ == var_0_2.AwakeTwiceStage.COMPLETE
end

function var_0_3.awakeTwiceStage(arg_75_0)
	return arg_75_0.awakeTwiceStage_ or 0
end

function var_0_3.updateFumo(arg_76_0, arg_76_1, arg_76_2)
	arg_76_0:getEquipList(arg_76_0:getColor())[arg_76_2].moneng_ = arg_76_1
	arg_76_0.fumo_[arg_76_2] = arg_76_1
end

function var_0_3.clearCD(arg_77_0, arg_77_1)
	local var_77_0 = {
		pet_id = arg_77_0:getPetID()
	}

	var_0_2.Backend.get():request(var_0_2.mid.PET_CLEAN_CD, var_77_0, function(arg_78_0, arg_78_1, arg_78_2)
		if arg_78_0 == var_0_2.error.OK then
			arg_77_0.is_show_ = 1

			arg_77_0:setShow(function(arg_79_0, arg_79_1)
				return
			end, arg_77_0:getPetID())
		end

		arg_77_1(arg_78_0, arg_78_1)
	end)
end

function var_0_3.setShow(arg_80_0, arg_80_1, arg_80_2)
	local var_80_0 = {
		pet_id = arg_80_2
	}

	var_0_2.Backend.get():request(var_0_2.mid.PET_SET_SHOW, var_80_0, function(arg_81_0, arg_81_1, arg_81_2)
		if arg_81_0 == var_0_2.error.OK then
			arg_80_0.time_ = nil
		end

		arg_80_1(arg_81_0, arg_81_1)
	end)
end

function var_0_3.evolution(arg_82_0, arg_82_1)
	local var_82_0 = {
		pet_id = arg_82_0:getPetID()
	}

	var_0_2.Backend.get():request(var_0_2.mid.PET_EVOLVE, var_82_0, function(arg_83_0, arg_83_1, arg_83_2)
		if arg_83_0 == var_0_2.error.OK then
			local var_83_0 = {
				itemID = arg_82_0:getSuiPianID(),
				itemNum = var_0_2.StarLevelSuipian[arg_82_0:getStar() + 1]
			}

			arg_82_0.selfPlayer:getBackpack():removeItem(var_83_0)

			arg_82_0.star_ = arg_82_0.star_ + 1
		end

		arg_82_1(arg_83_0, arg_83_1)
	end)
end

function var_0_3.feed(arg_84_0, arg_84_1, arg_84_2)
	var_0_2.Backend.get():request(var_0_2.mid.PET_FEED, arg_84_1, function(arg_85_0, arg_85_1, arg_85_2)
		if arg_85_0 == var_0_2.error.OK then
			local var_85_0 = {
				itemID = arg_84_1.item_id,
				itemNum = arg_84_1.item_num
			}

			arg_84_0.selfPlayer:getBackpack():removeItem(var_85_0)
		end

		arg_84_2(arg_85_0, arg_84_1, arg_85_1)
	end, {}, false, true)
end

function var_0_3.equipItems(arg_86_0, arg_86_1, arg_86_2)
	if not arg_86_0:isHasItem(arg_86_1) then
		if arg_86_2 then
			arg_86_2()
		end

		return
	end

	local var_86_0 = {
		pet_id = arg_86_0:getPetID(),
		equip_index = arg_86_1
	}

	if not var_86_0.pet_id or not var_86_0.equip_index then
		if arg_86_2 then
			arg_86_2()
		end

		return
	end

	var_0_2.Backend.get():request(var_0_2.mid.PET_EQUIP, var_86_0, function(arg_87_0, arg_87_1, arg_87_2)
		if arg_87_0 == var_0_2.error.OK or tonumber(arg_87_1.error_code or 0) == 30001 then
			arg_86_0.equips_[arg_86_1] = 1

			arg_86_0:getEquipByIndex(arg_86_1):setCollected()
			var_0_2.EventDispatcher.get():dispatchEvent({
				name = var_0_2.event.HERO_EQUIP_CHANGED,
				index = arg_86_1
			})

			local var_87_0 = arg_86_0.selfPlayer:getBackpack()
			local var_87_1 = arg_86_0:getEquipByIndex(arg_86_1)
			local var_87_2 = {
				itemID = var_87_1:getTableID()
			}

			var_87_2.itemNum = 1

			var_87_0:removeItem(var_87_2)
		end

		if arg_87_1.error_code == 30001 then
			local var_87_3 = var_0_2.tables.message:getContent(30001)

			var_0_2.WindowManager.get():openWindow("toast", {
				message = var_87_3
			})
		end

		if arg_86_2 then
			arg_86_2(arg_87_0, arg_87_1)
		end
	end)
end

function var_0_3.getEquipByIndex(arg_88_0, arg_88_1, arg_88_2)
	return arg_88_0:getEquipList(arg_88_2 or arg_88_0:getColor())[arg_88_1]
end

function var_0_3.getEquipByIndexShow(arg_89_0, arg_89_1, arg_89_2)
	return arg_89_0:getEquipList(arg_89_2 or arg_89_0:getColor())[arg_89_1]
end

function var_0_3.getItemHeroHasNotEquip(arg_90_0, arg_90_1)
	local var_90_0 = arg_90_0:getEquipList(arg_90_0:getColor())

	for iter_90_0, iter_90_1 in pairs(var_90_0) do
		if iter_90_1:getTableID() == arg_90_1 and not iter_90_1:isCollected() then
			return true
		end
	end

	return false
end

function var_0_3.getEquipAttrByType(arg_91_0, arg_91_1, arg_91_2)
	return arg_91_2:getAttr()[arg_91_1] or 0
end

function var_0_3.getDes(arg_92_0)
	return var_0_8:getDes(arg_92_0:getTableID())
end

function var_0_3.getTalkText(arg_93_0)
	return var_0_8:getTalkText(arg_93_0:getTableID())
end

function var_0_3.getSkillId(arg_94_0, arg_94_1)
	if arg_94_1 then
		return var_0_8:getSkill(arg_94_0:getTableID(), arg_94_1)
	else
		return var_0_8:getSkill(arg_94_0:getTableID())
	end
end

function var_0_3.getCircle(arg_95_0)
	return var_0_1.clone(var_0_8:circle(arg_95_0:getTableID()))
end

function var_0_3.getStartCircle(arg_96_0)
	return var_0_1.clone(var_0_8:startCircle(arg_96_0:getTableID()))
end

function var_0_3.getExtraSkillLevel(arg_97_0)
	return arg_97_0:getEquipAttr(var_0_2.AttributeType.ADD_SKILL) + arg_97_0:getJinjieEquipAttr(var_0_2.AttributeType.ADD_SKILL)
end

function var_0_3.getSkillLevel(arg_98_0, arg_98_1)
	if arg_98_1 then
		return arg_98_0.skillLev_[arg_98_1]
	else
		return arg_98_0.skillLev_
	end
end

function var_0_3.getSkillLevelByID(arg_99_0, arg_99_1)
	if arg_99_1 == var_0_8:pugong(arg_99_0:getTableID()) then
		return arg_99_0.level_
	end

	local var_99_0 = arg_99_0:getSkillId()
	local var_99_1 = 0
	local var_99_2 = 0

	for iter_99_0, iter_99_1 in ipairs(var_99_0) do
		if iter_99_1 == arg_99_1 then
			var_99_1 = arg_99_0:getSkillLevel(iter_99_0)
			var_99_2 = iter_99_0

			break
		end
	end

	local var_99_3 = arg_99_0:getPetStarSkillLevel(arg_99_1, var_99_2)

	if var_99_1 > arg_99_0.level_ + var_99_3 then
		var_99_1 = arg_99_0.level_ + var_99_3
	end

	return var_99_1
end

function var_0_3.skilllevelUp(arg_100_0, arg_100_1, arg_100_2, arg_100_3)
	if not arg_100_1 or not arg_100_3 then
		if arg_100_2 then
			arg_100_2()
		end

		return
	end

	local var_100_0 = var_0_2.luaStringMerge(arg_100_1, "|")
	local var_100_1 = var_0_2.luaStringMerge(arg_100_3, "|")
	local var_100_2 = {
		pet_id = arg_100_0:getPetID(),
		skill_colors = var_100_0,
		skill_counts = var_100_1
	}

	var_0_2.Backend.get():request(var_0_2.mid.PET_UPGRADE_ALL_SKILL, var_100_2, function(arg_101_0, arg_101_1, arg_101_2)
		if arg_101_0 == var_0_2.error.OK then
			local var_101_0 = 0

			for iter_101_0, iter_101_1 in pairs(arg_100_1) do
				for iter_101_2 = 1, arg_100_3[iter_101_0] do
					var_101_0 = var_0_2.tables.petSkillBook:getBookNum(arg_100_0.skillLev_[iter_101_1] - iter_101_2) + var_101_0
				end
			end

			arg_100_0.selfPlayer:getBackpack():removeItem({
				itemID = var_0_2.tables.misc.skillBookItem,
				itemNum = var_101_0
			})
			var_0_2.EventDispatcher.get():dispatchEvent({
				name = var_0_2.event.PET_UPDATE_SKILL_BOOK
			})
		end

		if arg_100_2 then
			arg_100_2(arg_101_0, arg_101_1)
		end
	end)
end

function var_0_3.getHeroModel(arg_102_0)
	local var_102_0 = var_0_2.HeroAnimation.new(arg_102_0:getTableID(), arg_102_0:getModelID(), var_0_11:uiScale(arg_102_0:getModelID()), {})

	if var_102_0 then
		var_102_0:idle()
	end

	return var_102_0
end

function var_0_3.isHasItem(arg_103_0, arg_103_1)
	return arg_103_0:getEquipByIndex(arg_103_1):isInBackpack()
end

function var_0_3.canComposeItem(arg_104_0, arg_104_1)
	return arg_104_0:getEquipByIndex(arg_104_1):isHasMaterial()
end

function var_0_3.canEquipItem(arg_105_0, arg_105_1)
	local var_105_0 = arg_105_0:getEquipByIndex(arg_105_1)

	if not var_105_0:isCollected() and var_105_0:isInBackpack() and arg_105_0:getLevel() >= var_105_0:getLevel() then
		return true
	elseif not var_105_0:isCollected() and var_105_0:isInBackpack() and arg_105_0:getLevel() < var_105_0:getLevel() then
		return false
	elseif not var_105_0:isCollected() and not var_105_0:isInBackpack() and var_105_0:isHasMaterial() and arg_105_0:getLevel() >= var_105_0:getLevel() then
		return true
	elseif not var_105_0:isCollected() and not var_105_0:isInBackpack() and var_105_0:isHasMaterial() and arg_105_0:getLevel() < var_105_0:getLevel() then
		return false
	end

	return false
end

function var_0_3.setExp(arg_106_0, arg_106_1, arg_106_2)
	local var_106_0 = arg_106_0:getLevel()
	local var_106_1 = var_0_2.tables.petExp:totalExp(var_106_0)
	local var_106_2 = var_0_2.tables.petExp:totalExp(arg_106_2)

	arg_106_0.exp_ = var_0_14.min(arg_106_1, var_106_2)

	if var_106_1 <= arg_106_0.exp_ then
		arg_106_0:setLevel(arg_106_0.exp_, var_106_0, arg_106_2)
	end
end

function var_0_3.addExp(arg_107_0, arg_107_1, arg_107_2)
	local var_107_0 = arg_107_0:getLevel()
	local var_107_1 = var_0_2.tables.petExp:totalExp(var_107_0)
	local var_107_2 = var_0_2.tables.petExp:totalExp(arg_107_2)

	arg_107_0.exp_ = var_0_14.min(arg_107_0.exp_ + arg_107_1, var_107_2)

	if var_107_1 <= arg_107_0.exp_ then
		arg_107_0:setLevel(arg_107_0.exp_, var_107_0, arg_107_2)
	end
end

function var_0_3.setLevel(arg_108_0, arg_108_1, arg_108_2, arg_108_3)
	local var_108_0 = arg_108_2

	for iter_108_0 = arg_108_2, arg_108_3 do
		if arg_108_1 >= var_0_2.tables.petExp:totalExp(iter_108_0) then
			var_108_0 = var_0_14.min(iter_108_0 + 1, arg_108_3)
		else
			break
		end
	end

	arg_108_0.level_ = var_108_0
end

function var_0_3.canSummon(arg_109_0)
	if arg_109_0.isCollected_ or arg_109_0:isHasEgg() == false then
		return false
	end

	return true
end

function var_0_3.stoneSummonHero(arg_110_0, arg_110_1)
	local var_110_0 = {
		table_id = arg_110_0:getTableID()
	}

	var_0_2.Backend.get():request(var_0_2.mid.PET_SUMMON, var_110_0, function(arg_111_0, arg_111_1, arg_111_2)
		if arg_111_0 == var_0_2.error.OK then
			if type(arg_111_1) ~= "table" then
				if arg_110_1 then
					arg_110_1(arg_111_0, arg_111_1)
				end

				return
			end

			arg_110_0:populate(arg_111_1)
			arg_110_0.selfPlayer:addPet(arg_110_0)

			if arg_110_0.selfPlayer:getBackpack():getItemNumByID(arg_110_0:getEgg()) >= 1 then
				arg_110_0.selfPlayer:getBackpack():removeItem({
					itemNum = 1,
					itemID = arg_110_0:getEgg()
				})
			else
				arg_110_0.selfPlayer:getBackpack():removeItem({
					itemID = arg_110_0:getSuiPianID(),
					itemNum = var_0_2.TotalStarSuipian[arg_110_0:getStar()]
				})
			end

			local var_111_0 = tonumber(var_0_2.ServerTime.get():getServerTime())

			arg_110_0.time_ = arg_110_0.birthday_ + var_0_8:getHatchTime(arg_110_0:getTableID()) - var_111_0

			var_0_2.ModelManager.get():loadModel(var_0_2.ModelType.GLOBAL_TIMER):checkIsMakingChild()
		end

		if arg_110_1 then
			arg_110_1(arg_111_0, arg_111_1)
		end
	end)
end

function var_0_3.getAttrRates(arg_112_0)
	return var_0_8:attrRates(arg_112_0:getTableID())
end

function var_0_3.setReportData(arg_113_0, arg_113_1)
	arg_113_0.fighterReport_ = arg_113_1
end

function var_0_3.getReportData(arg_114_0)
	return arg_114_0.fighterReport_
end

function var_0_3.setTableID(arg_115_0, arg_115_1)
	arg_115_0.tableID_ = arg_115_1
end

function var_0_3.getAddExp(arg_116_0)
	return var_0_13:exp(arg_116_0:getLevel())
end

function var_0_3.getEquipFumoAttr(arg_117_0, arg_117_1)
	local var_117_0 = arg_117_0:getEquipList(arg_117_0:getColor())
	local var_117_1 = 0

	for iter_117_0, iter_117_1 in ipairs(arg_117_0.equips_) do
		if iter_117_1 > 0 then
			if arg_117_0.fumoLev_ and next(arg_117_0.fumoLev_) then
				var_117_1 = var_117_1 + (var_117_0[iter_117_0]:getFumoByLevel(arg_117_0.fumoLev_[iter_117_0])[arg_117_1] or 0)
			else
				var_117_1 = var_117_1 + arg_117_0:getEquipFumoAttrByType(arg_117_1, var_117_0[iter_117_0])
			end
		end
	end

	return var_117_1
end

function var_0_3.getEquipFumoAttrByType(arg_118_0, arg_118_1, arg_118_2)
	return arg_118_2:getFumoAttr()[arg_118_1] or 0
end

function var_0_3.oneKeyPowerUp(arg_119_0, arg_119_1)
	local var_119_0 = {
		pet_id = arg_119_0:getPetID()
	}

	var_0_2.Backend.get():request(var_0_2.mid.PET_ONE_KEY_UP, var_119_0, function(arg_120_0, arg_120_1, arg_120_2)
		if arg_120_0 == var_0_2.error.OK then
			if arg_119_0.color_ < var_0_2.tables.misc.maxPetColor then
				if arg_119_0:isInAwakingPeriod() or arg_119_0:isAwaken() then
					for iter_120_0 = 1, 3 do
						if arg_119_0:getEquipByIndex(iter_120_0):getTableID() > 0 and var_0_12:isAwakenItem(arg_119_0:getEquipByIndex(iter_120_0):getTableID()) == 0 then
							arg_119_0.equips_[iter_120_0] = 0
							arg_119_0.fumo_[iter_120_0] = 0
						end
					end
				else
					arg_119_0.equips_ = {
						0,
						0,
						0
					}
					arg_119_0.fumo_ = {
						0,
						0,
						0
					}
				end

				arg_119_0.color_ = arg_119_0.color_ + 1

				for iter_120_1 = 1, 3 do
					if arg_119_0.equips_[iter_120_1] == 1 then
						arg_119_0:getEquipByIndex(iter_120_1):setCollected()
					end
				end

				if arg_119_0.skillLev_[var_0_2.Color2Quality[arg_119_0.color_]] == 0 then
					if var_0_2.Color2Quality[arg_119_0.color_] == var_0_2.SKILL_INDEX.Green then
						arg_119_0.skillLev_[var_0_2.Color2Quality[arg_119_0.color_]] = 1 + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Green]
					elseif var_0_2.Color2Quality[arg_119_0.color_] == var_0_2.SKILL_INDEX.Blue then
						arg_119_0.skillLev_[var_0_2.Color2Quality[arg_119_0.color_]] = 1 + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Blue]
					elseif var_0_2.Color2Quality[arg_119_0.color_] == var_0_2.SKILL_INDEX.Purple then
						arg_119_0.skillLev_[var_0_2.Color2Quality[arg_119_0.color_]] = 1 + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Purple]
					end
				end
			else
				local var_120_0 = var_0_8:equipList(arg_119_0:getTableID())[arg_119_0.color_]

				for iter_120_2 = 1, #var_120_0 do
					if var_120_0[iter_120_2] > 0 and var_0_12:isAwakenItem(var_120_0[iter_120_2]) == 0 then
						arg_119_0.equips_[iter_120_2] = 1

						arg_119_0:getEquipByIndex(iter_120_2):setCollected()
					end
				end
			end
		end

		if arg_119_1 then
			arg_119_1(arg_120_0, arg_120_1)
		end
	end)
end

function var_0_3.oneKeyEquip(arg_121_0, arg_121_1, arg_121_2)
	local var_121_0 = {
		pet_id = arg_121_0:getPetID()
	}

	var_0_2.Backend.get():request(var_0_2.mid.PET_ONE_KEY_EQUIP, var_121_0, function(arg_122_0, arg_122_1, arg_122_2)
		if arg_122_0 == var_0_2.error.OK then
			for iter_122_0, iter_122_1 in pairs(arg_121_1) do
				arg_121_0.equips_[iter_122_1] = 1

				arg_121_0:getEquipByIndex(iter_122_1):setCollected()
				var_0_2.EventDispatcher.get():dispatchEvent({
					name = var_0_2.event.HERO_EQUIP_CHANGED,
					index = iter_122_1
				})
			end
		end

		if arg_121_2 then
			arg_121_2(arg_122_0, arg_122_1)
		end
	end)
end

function var_0_3.selfDrink(arg_123_0, arg_123_1, arg_123_2)
	local var_123_0 = {
		items = arg_123_1,
		pet_id = arg_123_0:getPetID()
	}

	var_0_2.Backend.get():request(var_0_2.mid.PET_USE_EXP_ITEMS, var_123_0, function(arg_124_0, arg_124_1, arg_124_2)
		if arg_124_0 == var_0_2.error.OK then
			for iter_124_0, iter_124_1 in pairs(var_123_0.items) do
				arg_123_0.selfPlayer:getBackpack():removeItem({
					itemID = iter_124_1.item_id,
					itemNum = iter_124_1.item_num
				})
			end
		end

		if arg_123_2 then
			arg_123_2(arg_124_0, arg_124_1)
		end
	end)
end

function var_0_3.powerUp(arg_125_0, arg_125_1)
	local var_125_0 = {
		pet_id = arg_125_0:getPetID()
	}

	if arg_125_0.color_ < var_0_2.MAX_HERO_COLOR then
		var_0_2.Backend.get():request(var_0_2.mid.PET_ADVANCE, var_125_0, function(arg_126_0, arg_126_1, arg_126_2)
			if arg_126_0 == var_0_2.error.OK then
				if arg_125_0:isInAwakingPeriod() or arg_125_0:isAwaken() then
					for iter_126_0 = 1, 3 do
						if arg_125_0:getEquipByIndex(iter_126_0):getTableID() > 0 and var_0_12:isAwakenItem(arg_125_0:getEquipByIndex(iter_126_0):getTableID()) == 0 then
							arg_125_0.equips_[iter_126_0] = 0
							arg_125_0.fumo_[iter_126_0] = 0
						end
					end
				else
					arg_125_0.equips_ = {
						0,
						0,
						0
					}
					arg_125_0.fumo_ = {
						0,
						0,
						0
					}
				end

				arg_125_0.color_ = arg_125_0.color_ + 1

				for iter_126_1 = 1, 3 do
					if arg_125_0.equips_[iter_126_1] == 1 then
						arg_125_0:getEquipByIndex(iter_126_1):setCollected()
					end
				end

				if arg_125_0.skillLev_[var_0_2.Color2Quality[arg_125_0.color_]] == 0 then
					if var_0_2.Color2Quality[arg_125_0.color_] == var_0_2.SKILL_INDEX.Green then
						arg_125_0.skillLev_[var_0_2.Color2Quality[arg_125_0.color_]] = 1 + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Green]
					elseif var_0_2.Color2Quality[arg_125_0.color_] == var_0_2.SKILL_INDEX.Blue then
						arg_125_0.skillLev_[var_0_2.Color2Quality[arg_125_0.color_]] = 1 + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Blue]
					elseif var_0_2.Color2Quality[arg_125_0.color_] == var_0_2.SKILL_INDEX.Purple then
						arg_125_0.skillLev_[var_0_2.Color2Quality[arg_125_0.color_]] = 1 + var_0_2.SKILL_EXTRA[var_0_2.SKILL_INDEX.Purple]
					end
				end
			end

			if arg_125_1 then
				arg_125_1(arg_126_0, arg_126_1)
			end
		end)
	end
end

function var_0_3.getFumoCount(arg_127_0)
	local var_127_0 = arg_127_0.fumo_
	local var_127_1 = 0

	for iter_127_0 = 1, #var_127_0 do
		var_127_1 = var_127_1 + tonumber(var_127_0[iter_127_0])
	end

	return var_127_1
end

function var_0_3.getWithoutAwakeFumoCount(arg_128_0)
	local var_128_0 = arg_128_0.fumo_
	local var_128_1 = 0

	for iter_128_0 = 1, #var_128_0 do
		if arg_128_0:getEquipByIndex(iter_128_0):getTableID() > 0 and var_0_12:isAwakenItem(arg_128_0:getEquipByIndex(iter_128_0):getTableID()) == 0 then
			var_128_1 = var_128_1 + tonumber(var_128_0[iter_128_0])
		end
	end

	return var_128_1
end

function var_0_3.isLastColorHasAwakeItem(arg_129_0)
	local var_129_0 = arg_129_0:getColor() - 1

	if var_129_0 <= 0 then
		return false
	end

	local var_129_1 = var_0_8:equipList(arg_129_0:getTableID())

	for iter_129_0, iter_129_1 in pairs(var_129_1[var_129_0]) do
		if iter_129_1 == 0 or var_0_12:isAwakenItem(iter_129_1) == 1 then
			return true
		end
	end

	return false
end

function var_0_3.isInAwakingPeriod(arg_130_0)
	if arg_130_0:getEquipList(arg_130_0:getColor()) and next(arg_130_0:getEquipList(arg_130_0:getColor())) then
		for iter_130_0, iter_130_1 in pairs(arg_130_0:getEquipList(arg_130_0:getColor())) do
			if (var_0_12:isAwakenItem(iter_130_1:getTableID()) or iter_130_1:getTableID() == 0) and not arg_130_0:isAwaken() then
				return true
			end
		end
	end

	return false
end

function var_0_3.isHaveAwakenItem(arg_131_0)
	if arg_131_0:getEquipList(arg_131_0:getColor()) and next(arg_131_0:getEquipList(arg_131_0:getColor())) then
		for iter_131_0, iter_131_1 in pairs(arg_131_0:getEquipList(arg_131_0:getColor())) do
			if iter_131_1 and (var_0_12:isAwakenItem(iter_131_1:getTableID()) == 1 or iter_131_1 == 0) then
				return true
			end
		end
	end

	return false
end

function var_0_3.getHeroType(arg_132_0)
	return var_0_2.HeroType.NONE
end

function var_0_3.getAvatar(arg_133_0, arg_133_1)
	if not arg_133_1 or arg_133_1 == 1 then
		return var_0_11:avatar(arg_133_0:getModelID())
	end

	return var_0_11:avatar2(arg_133_0:getModelID())
end

function var_0_3.enterDuration(arg_134_0)
	return var_0_9:enterDuration(arg_134_0:enterSkill())
end

function var_0_3.enterSpeed(arg_135_0)
	return var_0_9:enterSpeed(arg_135_0:enterSkill())
end

function var_0_3.enterDelayDuration(arg_136_0)
	return var_0_9:enterDelayDuration(arg_136_0:enterSkill())
end

function var_0_3.enterSkill(arg_137_0)
	return var_0_8:enterSkill(arg_137_0:getTableID())
end

function var_0_3.checkSkillChange(arg_138_0, arg_138_1)
	if arg_138_1 <= arg_138_0.star_ - 1 then
		return true
	end

	return false
end

function var_0_3.getPetStarSkillLevel(arg_139_0, arg_139_1, arg_139_2)
	if not arg_139_1 or not arg_139_2 or arg_139_2 <= 0 then
		return 0
	elseif not arg_139_0:checkSkillChange(arg_139_2) then
		return 0
	end

	if var_0_9:petStarType(arg_139_1) == var_0_2.PetStarType.ADD_SKILL then
		local var_139_0 = var_0_9:desc4NumStep(arg_139_1)[2]

		if var_139_0 and var_139_0 > 0 then
			return var_139_0
		end
	end

	return 0
end

function var_0_3.getSkillLimitLevel(arg_140_0, arg_140_1)
	if not arg_140_1 or arg_140_1 <= 0 then
		return arg_140_0.level_
	end

	local var_140_0 = arg_140_0:getSkillId(arg_140_1)

	return arg_140_0.level_ + arg_140_0:getPetStarSkillLevel(var_140_0, arg_140_1)
end

function var_0_3.getInscriptionKuangLevel(arg_141_0)
	return
end

function var_0_3.getElementEquips(arg_142_0)
	return {}
end

function var_0_3.getElementType(arg_143_0)
	return 0
end

function var_0_3.getSpiritEquips(arg_144_0)
	return {}
end

function var_0_3.getSpiritSuitID(arg_145_0)
	return {}, 0
end

function var_0_3.isActiveSP(arg_146_0)
	return false
end

function var_0_3.checkIsZhuge(arg_147_0)
	return false
end

function var_0_3.isSuper(arg_148_0)
	return false
end

function var_0_3.getSearchName(arg_149_0)
	return var_0_8:searchName(arg_149_0:getTableID())
end

return var_0_3
