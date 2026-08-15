local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hero")
local var_0_4 = var_0_2.tables.hero
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.model
local var_0_7 = var_0_2.tables.heroExp
local var_0_8 = -1

function var_0_3.ctor(arg_1_0)
	arg_1_0.heroID_ = var_0_8
	arg_1_0.playerID_ = 0
	arg_1_0.exp_ = 0
	arg_1_0.isPet_ = false
	arg_1_0.selfSkillIDs_ = {}

	if isClient then
		arg_1_0.selfPlayer = var_0_2.ModelManager.get():loadModel(var_0_2.ModelType.SELF_PLAYER)
	end
end

function var_0_3.initUnCollected(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	arg_2_3 = arg_2_3 or {}
	arg_2_0.tableID_ = arg_2_1
	arg_2_0.heroID_ = arg_2_2 or var_0_8
	arg_2_0.star_ = arg_2_3.star or var_0_4:initialStar(arg_2_1)
	arg_2_0.level_ = arg_2_3.lev or 1
	arg_2_0.color_ = arg_2_3.color or 1
	arg_2_0.isCollected_ = arg_2_3.isCollected or false
	arg_2_0.exp_ = arg_2_3.exp or 0
	arg_2_0.promoteAttrs_ = arg_2_3.promote_attrs

	arg_2_0:updateSkillLevel()
end

function var_0_3.populate(arg_3_0, arg_3_1)
	arg_3_0.playerID_ = tonumber(arg_3_1.player_id or 0)
	arg_3_0.heroID_ = tonumber(arg_3_1.partner_id or 0)
	arg_3_0.tableID_ = tonumber(arg_3_1.table_id)
	arg_3_0.star_ = tonumber(arg_3_1.star)
	arg_3_0.level_ = tonumber(arg_3_1.lev or 1)
	arg_3_0.promoteAttrs_ = arg_3_1.promote_attrs

	if isClient then
		arg_3_0.exp_ = tonumber(arg_3_1.exp) or var_0_2.tables.partnerExp:totalExp(arg_3_0.level_)
	else
		arg_3_0.exp_ = tonumber(arg_3_1.exp) or 0
	end

	arg_3_0.color_ = tonumber(arg_3_1.color or 1)
	arg_3_0.selfSkillIDs_ = arg_3_1.skill_ids or {
		0,
		0,
		0,
		0,
		0,
		0
	}

	for iter_3_0 = 1, var_0_2.SKILL_INDEX.TotalNum do
		if not arg_3_0.selfSkillIDs_[iter_3_0] then
			arg_3_0.selfSkillIDs_[iter_3_0] = 0
		end
	end

	arg_3_0.isCollected_ = true

	arg_3_0:updateSkillLevel()
end

function var_0_3.populateWithTableID(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_2 or {}

	arg_4_0.tableID_ = arg_4_1
	arg_4_0.star_ = var_4_0.star or var_0_4:initialStar(arg_4_1)
	arg_4_0.level_ = var_4_0.level or var_0_4:level(arg_4_1)
	arg_4_0.color_ = var_4_0.color or var_0_4:color(arg_4_1)
	arg_4_0.promoteAttrs_ = var_4_0.promote_attrs

	arg_4_0:updateSkillLevel()
end

function var_0_3.updateSkillLevel(arg_5_0)
	arg_5_0.skillLev_ = {}
	arg_5_0.skillLev_[var_0_2.SKILL_INDEX.Energy] = arg_5_0.level_

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
end

function var_0_3.toParams(arg_6_0)
	return {
		player_id = arg_6_0.playerID_,
		partner_id = arg_6_0.heroID_,
		table_id = arg_6_0.tableID_,
		star = arg_6_0.star_,
		lev = arg_6_0.level_,
		exp = arg_6_0.exp_,
		color = arg_6_0.color_,
		skill_ids = arg_6_0.selfSkillIDs_,
		promote_attrs = arg_6_0.promoteAttrs_
	}
end

function var_0_3.toString(arg_7_0)
	return json.encode(arg_7_0:toParams())
end

function var_0_3.getPlayerID(arg_8_0)
	return arg_8_0.playerID_
end

function var_0_3.setPlayerID(arg_9_0, arg_9_1)
	arg_9_0.playerID_ = arg_9_1
end

function var_0_3.getHeroID(arg_10_0)
	return arg_10_0.heroID_
end

function var_0_3.getTableID(arg_11_0)
	return arg_11_0.tableID_
end

function var_0_3.getCourseIDByColor(arg_12_0, arg_12_1)
	return 0
end

function var_0_3.getFirstTableID(arg_13_0)
	local var_13_0 = arg_13_0:getTableID()

	if arg_13_0:isAwaken() then
		var_13_0 = arg_13_0:beforeAwakenID()
	end

	return var_13_0
end

function var_0_3.getStar(arg_14_0)
	return arg_14_0.star_ or 0
end

function var_0_3.setStar(arg_15_0, arg_15_1)
	arg_15_0.star_ = arg_15_1
end

function var_0_3.setIsPet(arg_16_0, arg_16_1)
	arg_16_0.isPet_ = arg_16_1
end

function var_0_3.setAttrMD5(arg_17_0, arg_17_1)
	arg_17_0.attrMD5_ = arg_17_1
end

function var_0_3.setTotalAttrs(arg_18_0, arg_18_1)
	arg_18_0.totalAttrs_ = arg_18_1
end

function var_0_3.setBookshelfLevel(arg_19_0, arg_19_1)
	arg_19_0.bookshelfLev = arg_19_1
end

function var_0_3.getLevel(arg_20_0)
	return arg_20_0.level_
end

function var_0_3.isCollected(arg_21_0)
	return arg_21_0.isCollected_ or false
end

function var_0_3.getExp(arg_22_0)
	return arg_22_0.exp_
end

function var_0_3.getColor(arg_23_0)
	return arg_23_0.color_
end

function var_0_3.getName(arg_24_0)
	return var_0_4:name(arg_24_0:getTableID())
end

function var_0_3.isAwakeTwice(arg_25_0)
	return false
end

function var_0_3.getHeroType(arg_26_0)
	return var_0_4:heroType(arg_26_0:getTableID())
end

function var_0_3.getAvatar(arg_27_0, arg_27_1)
	if not arg_27_1 or arg_27_1 == 1 then
		return var_0_6:avatar(arg_27_0:getModelID())
	end

	return var_0_6:avatar2(arg_27_0:getModelID())
end

function var_0_3.getModelID(arg_28_0)
	if arg_28_0.isSkinOn_ == 1 then
		return arg_28_0.skinId_
	else
		return var_0_4:modelID(arg_28_0:getTableID())
	end
end

function var_0_3.getModelIDs(arg_29_0)
	return var_0_4:modelIDs(arg_29_0:getTableID())
end

function var_0_3.getDistanceType(arg_30_0)
	return var_0_4:distanceType(arg_30_0:getTableID())
end

function var_0_3.getDistance(arg_31_0)
	return var_0_4:distance(arg_31_0:getTableID())
end

function var_0_3.getFromType(arg_32_0)
	return var_0_4:from(arg_32_0:getTableID())
end

function var_0_3.getAddExp(arg_33_0)
	return var_0_7:addExp(arg_33_0:getLevel())
end

function var_0_3.isShow(arg_34_0)
	return var_0_4:isShow(arg_34_0:getTableID())
end

function var_0_3.enterDuration(arg_35_0)
	return var_0_5:enterDuration(arg_35_0:enterSkill())
end

function var_0_3.enterSpeed(arg_36_0)
	return var_0_5:enterSpeed(arg_36_0:enterSkill())
end

function var_0_3.enterDelayDuration(arg_37_0)
	return var_0_5:enterDelayDuration(arg_37_0:enterSkill())
end

function var_0_3.enterSkill(arg_38_0)
	return var_0_4:enterSkill(arg_38_0:getTableID())
end

function var_0_3.className(arg_39_0)
	return var_0_4:className(arg_39_0:getTableID())
end

function var_0_3.promoteAttr(arg_40_0)
	return var_0_4:promoteAttr(arg_40_0:getTableID())
end

function var_0_3.promoteAttrs(arg_41_0)
	return arg_41_0.promoteAttrs_
end

function var_0_3.getPromoteAttrByIndex(arg_42_0, arg_42_1)
	if arg_42_0.promoteAttrs_ and next(arg_42_0.promoteAttrs_) then
		return arg_42_0.promoteAttrs_[arg_42_1] or 0
	end

	return 0
end

function var_0_3.getPromoteAttr(arg_43_0, arg_43_1)
	local var_43_0 = 0
	local var_43_1 = arg_43_0:maxAttrPoint()

	if arg_43_0.promoteAttrs_ and next(arg_43_0.promoteAttrs_) then
		local var_43_2 = arg_43_0:promoteAttr()
		local var_43_3 = arg_43_0:attrStar()

		for iter_43_0 = 1, #var_43_2 do
			if var_43_2[iter_43_0] == arg_43_1 then
				var_43_0 = (arg_43_0.promoteAttrs_[iter_43_0] or 0) / (var_43_1[iter_43_0] or 1) * (var_43_3[iter_43_0] or 0) * arg_43_0:getLevel()

				break
			end
		end
	end

	return var_43_0
end

function var_0_3.maxAttrPoint(arg_44_0)
	return var_0_4:maxAttrPoint(arg_44_0:getTableID())
end

function var_0_3.attrStar(arg_45_0)
	return var_0_4:attrStar(arg_45_0:getTableID())
end

function var_0_3.awakenID(arg_46_0)
	return var_0_4:awakenID(arg_46_0:getTableID())
end

function var_0_3.beforeAwakenID(arg_47_0)
	return var_0_4:beforeAwaken(arg_47_0:getTableID())
end

function var_0_3.afterAwakenID(arg_48_0)
	return var_0_4:afterAwaken(arg_48_0:getTableID())
end

function var_0_3.setEffectBuffID(arg_49_0, arg_49_1)
	if arg_49_1 and arg_49_1 > 0 then
		arg_49_0.effectBuffID_ = arg_49_1
	else
		arg_49_0.effectBuffID_ = 0
	end
end

function var_0_3.getEffectBuffID(arg_50_0)
	return arg_50_0.effectBuffID_ or 0
end

function var_0_3.getZhandouli(arg_51_0)
	return (math.ceil(arg_51_0:getBasicForce() + arg_51_0:getSkillForce() + arg_51_0:getPromoteAttrForce()))
end

function var_0_3.getBasicForce(arg_52_0)
	local var_52_0 = 0

	for iter_52_0 = 1, 3 do
		local var_52_1 = arg_52_0:getGrowAttr(arg_52_0:getTableID(), iter_52_0, arg_52_0:getStar(), arg_52_0:getLevel())
		local var_52_2 = var_0_2.JINJIE_ATTR_RATE * (arg_52_0:getColor() - 1) / 2 * arg_52_0:getColor()
		local var_52_3 = var_0_4:getInitialAttr(arg_52_0:getTableID(), iter_52_0)

		var_52_0 = var_52_0 + (var_52_1 + var_52_2 + var_52_3) * var_0_2.tables.attr:attrScore(iter_52_0)
	end

	for iter_52_1 = 4, var_0_2.AttributeType.TOTAL_ATTR_NUM do
		var_52_0 = var_52_0 + var_0_4:getInitialAttr(arg_52_0:getTableID(), iter_52_1) * var_0_2.tables.attr:attrScore(iter_52_1)
	end

	return var_52_0
end

function var_0_3.getSkillForce(arg_53_0)
	local var_53_0 = 0
	local var_53_1 = var_0_4:initPower(arg_53_0:getTableID())

	for iter_53_0 = 1, var_0_2.SKILL_INDEX.Purple do
		local var_53_2 = arg_53_0.skillLev_[iter_53_0] or 0

		if var_53_2 > 0 then
			local var_53_3 = tonumber(var_0_4:getSkill(arg_53_0:getTableID(), iter_53_0)) or 0

			if var_53_3 > 0 then
				var_53_0 = var_53_0 + var_0_5:stepPower(var_53_3) * var_53_2
			end
		end
	end

	return var_53_0 + var_53_1
end

function var_0_3.getPromoteAttrForce(arg_54_0)
	local var_54_0 = 0

	if arg_54_0.promoteAttrs_ and next(arg_54_0.promoteAttrs_) then
		local var_54_1 = arg_54_0:maxAttrPoint()
		local var_54_2 = arg_54_0:promoteAttr()
		local var_54_3 = arg_54_0:attrStar()

		for iter_54_0 = 1, #var_54_2 do
			local var_54_4 = (arg_54_0.promoteAttrs_[iter_54_0] or 0) / (var_54_1[iter_54_0] or 1)
			local var_54_5 = var_54_2[iter_54_0]

			var_54_0 = var_54_0 + var_54_4 * (var_54_3[iter_54_0] or 0) * arg_54_0:getLevel() * var_0_2.tables.attr:attrScore(var_54_5)
		end
	end

	return var_54_0
end

function var_0_3.getCard(arg_55_0)
	return var_0_6:card(arg_55_0:getModelID())
end

function var_0_3.getSmallCard(arg_56_0)
	return var_0_6:smallCard(arg_56_0:getModelID())
end

function var_0_3.getScale(arg_57_0)
	return var_0_6:scale(arg_57_0:getModelID())
end

function var_0_3.getMainAttr(arg_58_0, arg_58_1)
	local var_58_0 = arg_58_0:getGrowAttr(arg_58_0:getTableID(), arg_58_1, arg_58_0:getStar(), arg_58_0:getLevel())
	local var_58_1 = var_0_2.JINJIE_ATTR_RATE * (arg_58_0:getColor() - 1) / 2 * arg_58_0:getColor()
	local var_58_2 = var_0_4:getInitialAttr(arg_58_0:getTableID(), arg_58_1)

	return var_58_0 + var_58_1 + var_58_2
end

function var_0_3.getGrowAttr(arg_59_0, arg_59_1, arg_59_2, arg_59_3, arg_59_4)
	return (var_0_4:getHeroMainAttr(arg_59_1, arg_59_2, arg_59_3, arg_59_4))
end

function var_0_3.getAttrGlow(arg_60_0, arg_60_1)
	return var_0_4:getHeroAttrGrow(arg_60_0:getTableID(), arg_60_1, arg_60_0:getStar())
end

function var_0_3.getSkillAttr(arg_61_0, arg_61_1)
	local var_61_0 = var_0_1.ctx.battle.getRequire("Buff")

	local function var_61_1(arg_62_0, arg_62_1, arg_62_2)
		local var_62_0 = {}

		for iter_62_0, iter_62_1 in ipairs(arg_62_0) do
			local var_62_1 = var_61_0.new({
				start = 0,
				tableID = iter_62_1,
				level = arg_62_1,
				skillID = arg_62_2
			})

			var_62_1:setYongJiu()
			table.insert(var_62_0, var_62_1)
		end

		return var_62_0
	end

	local var_61_2 = var_0_4:buffSkill(arg_61_0:getTableID())

	if not next(var_61_2) then
		return 0
	end

	local var_61_3 = 0

	for iter_61_0, iter_61_1 in ipairs(var_61_2) do
		if var_0_5:skillType(iter_61_1) == var_0_2.SkillType.BUFF_SELF then
			local var_61_4 = arg_61_0:getSkillLevelByID(iter_61_1)

			if var_61_4 and var_61_4 > 0 then
				local var_61_5 = var_0_5:buffs(iter_61_1)
				local var_61_6 = var_61_1(var_61_5, var_61_4, iter_61_1)

				for iter_61_2, iter_61_3 in ipairs(var_61_6) do
					if iter_61_3:getAttrType() == arg_61_1 then
						local var_61_7, var_61_8 = iter_61_3:getAttr()

						if not var_61_8 then
							var_61_3 = var_61_3 + var_61_7
						else
							print("error : buff skill attribute type use percent increase " .. iter_61_3:getTableID())
						end
					end
				end
			end
		end
	end

	return var_61_3
end

function var_0_3.getMaxHP(arg_63_0)
	local var_63_0 = var_0_4:getInitialAttr(arg_63_0:getTableID(), var_0_2.AttributeType.HP)
	local var_63_1 = arg_63_0:getMainAttr(var_0_2.AttributeType.STRENGTH)

	return math.floor(var_63_0 + var_0_2.STRENGTH_HP_RATE * var_63_1)
end

function var_0_3.skillAttr2HP(arg_64_0)
	local var_64_0 = arg_64_0:getSkillAttr(var_0_2.AttributeType.STRENGTH)

	return var_0_2.STRENGTH_HP_RATE * var_64_0
end

function var_0_3.getAD(arg_65_0)
	local var_65_0 = var_0_4:getInitialAttr(arg_65_0:getTableID(), var_0_2.AttributeType.AD)
	local var_65_1 = arg_65_0:getMainAttr(var_0_2.AttributeType.AGILE) * var_0_2.AGILE_AD_RATE + arg_65_0:getMainAttr(arg_65_0:getHeroType())

	return math.floor(var_65_1 + var_65_0)
end

function var_0_3.skillAttr2AD(arg_66_0)
	local var_66_0 = arg_66_0:getSkillAttr(var_0_2.AttributeType.AGILE)

	return arg_66_0:getSkillAttr(arg_66_0:getHeroType()) + var_66_0 * var_0_2.AGILE_AD_RATE
end

function var_0_3.getAP(arg_67_0)
	local var_67_0 = var_0_4:getInitialAttr(arg_67_0:getTableID(), var_0_2.AttributeType.AP)
	local var_67_1 = arg_67_0:getMainAttr(var_0_2.AttributeType.WISE) * var_0_2.WISE_AP_RATE

	return math.floor(var_67_0 + var_67_1)
end

function var_0_3.skillAttr2AP(arg_68_0)
	return arg_68_0:getSkillAttr(var_0_2.AttributeType.WISE) * var_0_2.WISE_AP_RATE
end

function var_0_3.getHujia(arg_69_0)
	local var_69_0 = var_0_4:getInitialAttr(arg_69_0:getTableID(), var_0_2.AttributeType.HUJIA)
	local var_69_1 = var_0_2.AGILE_HUJIA_RATE * arg_69_0:getMainAttr(var_0_2.AttributeType.AGILE) + var_0_2.STRENGTH_HUJIA_RATE * arg_69_0:getMainAttr(var_0_2.AttributeType.STRENGTH)

	return math.floor(var_69_1 + var_69_0)
end

function var_0_3.skillAttr2Hujia(arg_70_0)
	local var_70_0 = arg_70_0:getSkillAttr(var_0_2.AttributeType.AGILE)
	local var_70_1 = arg_70_0:getSkillAttr(var_0_2.AttributeType.STRENGTH)

	return var_0_2.AGILE_HUJIA_RATE * var_70_0 + var_0_2.STRENGTH_HUJIA_RATE * var_70_1
end

function var_0_3.getMokang(arg_71_0)
	local var_71_0 = var_0_4:getInitialAttr(arg_71_0:getTableID(), var_0_2.AttributeType.MOKANG)
	local var_71_1 = var_0_2.WISE_MOKANG_RATE * arg_71_0:getMainAttr(var_0_2.AttributeType.WISE)

	return math.floor(var_71_0 + var_71_1)
end

function var_0_3.skillAttr2Mokang(arg_72_0)
	return var_0_2.WISE_MOKANG_RATE * arg_72_0:getSkillAttr(var_0_2.AttributeType.WISE)
end

function var_0_3.getADBaoji(arg_73_0)
	local var_73_0 = var_0_4:getInitialAttr(arg_73_0:getTableID(), var_0_2.AttributeType.AD_BAOJI)
	local var_73_1 = var_0_2.AGILE_AD_BAOJI_RATE * arg_73_0:getMainAttr(var_0_2.AttributeType.AGILE)

	return math.floor(var_73_0 + var_73_1)
end

function var_0_3.skillAttr2Baoji(arg_74_0)
	return var_0_2.AGILE_AD_BAOJI_RATE * arg_74_0:getSkillAttr(var_0_2.AttributeType.AGILE)
end

function var_0_3.getSkill2Attr(arg_75_0, arg_75_1)
	if arg_75_1 == var_0_2.AttributeType.HP then
		return arg_75_0:skillAttr2HP()
	elseif arg_75_1 == var_0_2.AttributeType.AD then
		return arg_75_0:skillAttr2AD()
	elseif arg_75_1 == var_0_2.AttributeType.AP then
		return arg_75_0:skillAttr2AP()
	elseif arg_75_1 == var_0_2.AttributeType.HUJIA then
		return arg_75_0:skillAttr2Hujia()
	elseif arg_75_1 == var_0_2.AttributeType.MOKANG then
		return arg_75_0:skillAttr2Mokang()
	elseif arg_75_1 == var_0_2.AttributeType.AD_BAOJI then
		return arg_75_0:skillAttr2Baoji()
	end

	return 0
end

function var_0_3.getTotalAttr(arg_76_0, arg_76_1)
	if arg_76_1 < 4 then
		return arg_76_0:getMainAttr(arg_76_1) + arg_76_0:getSkillAttr(arg_76_1) + arg_76_0:getPromoteAttr(arg_76_1)
	elseif arg_76_1 == var_0_2.AttributeType.HP then
		return arg_76_0:getMaxHP() + arg_76_0:getSkillAttr(arg_76_1) + arg_76_0:getSkill2Attr(arg_76_1) + arg_76_0:getPromoteAttr(arg_76_1)
	elseif arg_76_1 == var_0_2.AttributeType.AD then
		return arg_76_0:getAD() + arg_76_0:getSkillAttr(arg_76_1) + arg_76_0:getSkill2Attr(arg_76_1) + arg_76_0:getPromoteAttr(arg_76_1)
	elseif arg_76_1 == var_0_2.AttributeType.AP then
		return arg_76_0:getAP() + arg_76_0:getSkillAttr(arg_76_1) + arg_76_0:getSkill2Attr(arg_76_1) + arg_76_0:getPromoteAttr(arg_76_1)
	elseif arg_76_1 == var_0_2.AttributeType.HUJIA then
		return arg_76_0:getHujia() + arg_76_0:getSkillAttr(arg_76_1) + arg_76_0:getSkill2Attr(arg_76_1) + arg_76_0:getPromoteAttr(arg_76_1)
	elseif arg_76_1 == var_0_2.AttributeType.MOKANG then
		return arg_76_0:getMokang() + arg_76_0:getSkillAttr(arg_76_1) + arg_76_0:getSkill2Attr(arg_76_1) + arg_76_0:getPromoteAttr(arg_76_1)
	elseif arg_76_1 == var_0_2.AttributeType.AD_BAOJI then
		return arg_76_0:getADBaoji() + arg_76_0:getSkillAttr(arg_76_1) + arg_76_0:getSkill2Attr(arg_76_1) + arg_76_0:getPromoteAttr(arg_76_1)
	elseif arg_76_1 == var_0_2.AttributeType.ENERGY_RATE then
		return 1
	elseif arg_76_1 <= var_0_2.AttributeType.TOTAL_ATTR_NUM then
		return var_0_4:getInitialAttr(arg_76_0:getTableID(), arg_76_1) + arg_76_0:getSkillAttr(arg_76_1) + arg_76_0:getPromoteAttr(arg_76_1)
	else
		return var_0_4:getInitialAttr(arg_76_0:getTableID(), arg_76_1) + arg_76_0:getSkillAttr(arg_76_1) + arg_76_0:getPromoteAttr(arg_76_1)
	end
end

function var_0_3.getTotalAttrWithOutBook(arg_77_0, arg_77_1)
	if arg_77_1 < 4 then
		return arg_77_0:getMainAttr(arg_77_1) + arg_77_0:getSkillAttr(arg_77_1) + arg_77_0:getPromoteAttr(arg_77_1)
	elseif arg_77_1 == var_0_2.AttributeType.HP then
		return arg_77_0:getMaxHP() + arg_77_0:getSkillAttr(arg_77_1) + arg_77_0:getSkill2Attr(arg_77_1) + arg_77_0:getPromoteAttr(arg_77_1)
	elseif arg_77_1 == var_0_2.AttributeType.AD then
		return arg_77_0:getAD() + arg_77_0:getSkillAttr(arg_77_1) + arg_77_0:getSkill2Attr(arg_77_1) + arg_77_0:getPromoteAttr(arg_77_1)
	elseif arg_77_1 == var_0_2.AttributeType.AP then
		return arg_77_0:getAP() + arg_77_0:getSkillAttr(arg_77_1) + arg_77_0:getSkill2Attr(arg_77_1) + arg_77_0:getPromoteAttr(arg_77_1)
	elseif arg_77_1 == var_0_2.AttributeType.HUJIA then
		return arg_77_0:getHujia() + arg_77_0:getSkillAttr(arg_77_1) + arg_77_0:getSkill2Attr(arg_77_1) + arg_77_0:getPromoteAttr(arg_77_1)
	elseif arg_77_1 == var_0_2.AttributeType.MOKANG then
		return arg_77_0:getMokang() + arg_77_0:getSkillAttr(arg_77_1) + arg_77_0:getSkill2Attr(arg_77_1) + arg_77_0:getPromoteAttr(arg_77_1)
	elseif arg_77_1 == var_0_2.AttributeType.AD_BAOJI then
		return arg_77_0:getADBaoji() + arg_77_0:getSkillAttr(arg_77_1) + arg_77_0:getSkill2Attr(arg_77_1) + arg_77_0:getPromoteAttr(arg_77_1)
	elseif arg_77_1 <= var_0_2.AttributeType.TOTAL_ATTR_NUM then
		return var_0_4:getInitialAttr(arg_77_0:getTableID(), arg_77_1) + arg_77_0:getSkillAttr(arg_77_1) + arg_77_0:getPromoteAttr(arg_77_1)
	else
		return var_0_4:getInitialAttr(arg_77_0:getTableID(), arg_77_1) + arg_77_0:getSkillAttr(arg_77_1) + arg_77_0:getPromoteAttr(arg_77_1)
	end
end

function var_0_3.setupBattleAttrInfo(arg_78_0)
	if not arg_78_0.isPet_ then
		arg_78_0.totalAttrs_ = {}
		arg_78_0.attrMD5_ = {}
		arg_78_0.errorData_ = arg_78_0.errorData_ or {}

		for iter_78_0 = 1, var_0_2.AttributeType.TOTAL_ATTR_NUM do
			arg_78_0.totalAttrs_[iter_78_0] = var_0_0.clone(arg_78_0:getTotalAttr(iter_78_0))

			if isClient then
				arg_78_0.attrMD5_[iter_78_0] = crypto.md5(arg_78_0.totalAttrs_[iter_78_0] .. var_0_2.tables.misc.encryptoKey)
			end
		end
	end
end

function var_0_3.getBattleAttr(arg_79_0, arg_79_1)
	if not arg_79_0.totalAttrs_ then
		arg_79_0:setupBattleAttrInfo()
	end

	if isClient and crypto.md5(arg_79_0.totalAttrs_[arg_79_1] .. var_0_2.tables.misc.encryptoKey) ~= arg_79_0.attrMD5_[arg_79_1] then
		arg_79_0:recordErrorData(arg_79_1, arg_79_0.totalAttrs_[arg_79_1])
	end

	return arg_79_0.totalAttrs_[arg_79_1]
end

function var_0_3.recordErrorData(arg_80_0, arg_80_1, arg_80_2)
	arg_80_0.errorData_ = arg_80_0.errorData_ or {}
	arg_80_0.errorData_[tostring(arg_80_1)] = arg_80_2
end

function var_0_3.getDes(arg_81_0)
	return var_0_4:getDes(arg_81_0:getTableID())
end

function var_0_3.getTalkText(arg_82_0)
	return var_0_4:getTalkText(arg_82_0:getTableID())
end

function var_0_3.getSkillId(arg_83_0, arg_83_1)
	if arg_83_1 then
		if next(arg_83_0.selfSkillIDs_) then
			return var_0_0.clone(arg_83_0.selfSkillIDs_[arg_83_1])
		else
			return var_0_4:getSkill(arg_83_0:getTableID(), arg_83_1)
		end
	elseif next(arg_83_0.selfSkillIDs_) then
		return var_0_0.clone(arg_83_0.selfSkillIDs_)
	else
		return var_0_4:getSkill(arg_83_0:getTableID())
	end
end

function var_0_3.getCircle(arg_84_0)
	local var_84_0 = var_0_0.clone(var_0_4:circle(arg_84_0:getTableID()))
	local var_84_1 = var_0_4:getSkillTable(arg_84_0:getTableID(), 1)

	return arg_84_0:changeQueueSkill(var_84_0, true)
end

function var_0_3.getStartCircle(arg_85_0)
	local var_85_0 = var_0_0.clone(var_0_4:startCircle(arg_85_0:getTableID()))
	local var_85_1 = var_0_4:getSkillTable(arg_85_0:getTableID(), 1)

	return arg_85_0:changeQueueSkill(var_85_0)
end

function var_0_3.changeQueueSkill(arg_86_0, arg_86_1, arg_86_2)
	local var_86_0 = {}
	local var_86_1 = var_0_4:pugong(arg_86_0:getTableID())

	for iter_86_0, iter_86_1 in ipairs(arg_86_1) do
		local var_86_2

		if iter_86_1 == 0 then
			local var_86_3 = var_86_1

			table.insert(var_86_0, var_86_3)
		elseif arg_86_0:getSkillLevel(iter_86_1) and arg_86_0:getSkillLevel(iter_86_1) > 1 then
			local var_86_4 = arg_86_0:getSkillId(iter_86_1)

			if arg_86_2 and var_86_4 == arg_86_0:enterSkill() then
				-- block empty
			elseif var_0_5:type(var_86_4) == var_0_2.AttackType.None then
				table.insert(var_86_0, var_86_1)
			else
				table.insert(var_86_0, var_86_4)
			end
		end
	end

	return var_86_0
end

function var_0_3.getExtraSkillLevel(arg_87_0)
	return 0
end

function var_0_3.getSkillLevel(arg_88_0, arg_88_1)
	if arg_88_1 then
		local var_88_0 = arg_88_0.skillLev_[arg_88_1]

		if isClient and type(var_88_0) == "number" and var_88_0 > var_0_2.MAX_SKILL_LEV then
			var_0_2.exitProgram()
		end

		return var_88_0
	else
		return arg_88_0.skillLev_
	end
end

function var_0_3.getSkillLevelByID(arg_89_0, arg_89_1)
	local var_89_0 = 0

	if arg_89_1 == var_0_4:pugong(arg_89_0:getTableID()) then
		var_89_0 = arg_89_0.level_
	else
		local var_89_1 = arg_89_0:getSkillId()

		for iter_89_0, iter_89_1 in ipairs(var_89_1) do
			if iter_89_1 == arg_89_1 then
				var_89_0 = arg_89_0:getSkillLevel(iter_89_0)

				break
			end
		end
	end

	if type(var_89_0) == "boolean" then
		return var_89_0
	end

	local var_89_2 = var_89_0 + arg_89_0:getExtraSkillLevel()

	if isClient and var_89_2 > var_0_2.MAX_SKILL_LEV then
		var_0_2.exitProgram()
	end

	return var_89_2
end

function var_0_3.getSpeed(arg_90_0)
	return var_0_4:speed(arg_90_0:getTableID())
end

function var_0_3.getHeroModel(arg_91_0)
	local var_91_0 = var_0_2.HeroAnimation.new(arg_91_0:getTableID(), arg_91_0:getModelID(), var_0_6:uiScale(arg_91_0:getModelID()), {})

	if var_91_0 then
		var_91_0:idle()
	end

	return var_91_0
end

function var_0_3.setExp(arg_92_0, arg_92_1, arg_92_2)
	local var_92_0 = arg_92_0:getLevel()
	local var_92_1 = var_0_2.tables.partnerExp:totalExp(var_92_0)
	local var_92_2 = var_0_2.tables.partnerExp:totalExp(arg_92_2)

	arg_92_0.exp_ = math.min(arg_92_1, var_92_2)

	if var_92_1 <= arg_92_0.exp_ then
		arg_92_0:setLevel(arg_92_0.exp_, var_92_0, arg_92_2)
	end
end

function var_0_3.addExp(arg_93_0, arg_93_1, arg_93_2)
	local var_93_0 = arg_93_0:getLevel()
	local var_93_1 = var_0_2.tables.partnerExp:totalExp(var_93_0)
	local var_93_2 = var_0_2.tables.partnerExp:totalExp(arg_93_2)

	arg_93_0.exp_ = math.min(arg_93_0.exp_ + arg_93_1, var_93_2)

	if var_93_1 <= arg_93_0.exp_ then
		arg_93_0:setLevel(arg_93_0.exp_, var_93_0, arg_93_2)
	end
end

function var_0_3.setLevel(arg_94_0, arg_94_1, arg_94_2, arg_94_3)
	local var_94_0 = arg_94_2

	for iter_94_0 = arg_94_2, arg_94_3 do
		if arg_94_1 >= var_0_2.tables.partnerExp:totalExp(iter_94_0) then
			var_94_0 = math.min(iter_94_0 + 1, arg_94_3)
		else
			break
		end
	end

	arg_94_0.level_ = var_94_0

	arg_94_0:updateSkillLevel()
end

function var_0_3.setColor(arg_95_0, arg_95_1)
	arg_95_0.color_ = arg_95_1

	arg_95_0:updateSkillLevel()
end

function var_0_3.stoneSummonHero(arg_96_0, arg_96_1)
	local var_96_0 = {
		table_id = arg_96_0:getTableID(),
		stone = arg_96_0:getSuiPianID(),
		stone_num = var_0_2.TotalStarSuipian[arg_96_0:getStar()]
	}

	arg_96_0.selfPlayer:stoneSummonHero(var_96_0, arg_96_1)
end

function var_0_3.getAttrRates(arg_97_0)
	return var_0_4:attrRates(arg_97_0:getTableID())
end

function var_0_3.setReportData(arg_98_0, arg_98_1)
	arg_98_0.fighterReport_ = arg_98_1
end

function var_0_3.getReportData(arg_99_0)
	return arg_99_0.fighterReport_
end

function var_0_3.isAwaken(arg_100_0)
	return var_0_4:beforeAwaken(arg_100_0:getTableID()) > 0
end

function var_0_3.isCanAwaken(arg_101_0)
	return var_0_4:isCanAwaken(arg_101_0:getTableID()) > 0
end

function var_0_3.canOpenAwakeTwiceMission(arg_102_0)
	return arg_102_0:awakeTwiceStage() == var_0_2.AwakeTwiceStage.UNSTART and var_0_4:isCanAwakeTwice(arg_102_0:getTableID()) > 0 and arg_102_0:isAwaken() and arg_102_0.level_ >= var_0_2.tables.misc.awakeTwiceOpenLev and arg_102_0.color_ >= var_0_2.tables.misc.awakeTwiceOpenQua
end

function var_0_3.isCanAwakeTwice(arg_103_0)
	return var_0_4:isCanAwakeTwice(arg_103_0:getTableID()) > 0
end

function var_0_3.setTableID(arg_104_0, arg_104_1)
	arg_104_0.tableID_ = arg_104_1
end

function var_0_3.isLastColorHasAwakeItem(arg_105_0)
	return false
end

function var_0_3.getSkillIDByIndex(arg_106_0, arg_106_1)
	return arg_106_0.skillIDs_[arg_106_1]
end

function var_0_3.setSkillIDByIndex(arg_107_0, arg_107_1, arg_107_2)
	arg_107_0.selfSkillIDs_[arg_107_1] = arg_107_2
end

function var_0_3.getElementEquips(arg_108_0)
	return
end

function var_0_3.getElementType(arg_109_0)
	return
end

function var_0_3.getSpiritEquips(arg_110_0)
	return {}
end

function var_0_3.getSpiritSuitID(arg_111_0)
	return {}, 0
end

function var_0_3.checkIsZhuge(arg_112_0)
	return false
end

function var_0_3.isSuper(arg_113_0)
	return false
end

return var_0_3
