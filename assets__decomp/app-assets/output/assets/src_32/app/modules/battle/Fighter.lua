local var_0_0 = class("Fighter")
local var_0_1 = import("app.modules.battle.BuffStory")
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.modules.battle.MoveUnitStory")
local var_0_4 = import("app.modules.battle.AttackUnitStory")
local var_0_5 = import("app.modules.battle.SkillEffect")
local var_0_6 = import("app.modules.battle.FighterModel")
local var_0_7 = xyd.tables.skill
local var_0_8 = xyd.tables.hero
local var_0_9 = xyd.tables.model
local var_0_10 = require("framework.scheduler")
local var_0_11 = true

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_1 = arg_1_1 or {}
	arg_1_0.buffs = {}
	arg_1_0.energy = 0
	arg_1_0.harms = 0

	arg_1_0:init()

	arg_1_0.isInArena_ = arg_1_1.is_arena
end

function var_0_0.populateWithHero(arg_2_0, arg_2_1)
	arg_2_0.partnerID = arg_2_1:getTableID()
	arg_2_0.hero = arg_2_1
	arg_2_0.name = arg_2_1:getName()
	arg_2_0.distance = arg_2_1:getDistance()
	arg_2_0.hp = clone(arg_2_0:getHpLimit())
	arg_2_0.modelID = arg_2_1:getModelID()
	arg_2_0.lv = arg_2_1:getLevel()
	arg_2_0.skillID = arg_2_1:getSkillId(xyd.SKILL_INDEX.Energy)
	arg_2_0.skills = arg_2_1:getCircle()
	arg_2_0.startCircle = arg_2_1:getStartCircle()
	arg_2_0.buffSkills = var_0_8:buffSkill(arg_2_1:getTableID())
	arg_2_0.deathSound = xyd.tables.model:deathSound(arg_2_0.modelID)
	arg_2_0.summonType_ = var_0_8:summonType(arg_2_0.partnerID)
end

function var_0_0.populateWithMonsterID(arg_3_0, arg_3_1)
	arg_3_0.partnerID = arg_3_1

	local var_3_0 = var_0_2.new()

	var_3_0:populateWithTableID(arg_3_1)
	arg_3_0:populateWithHero(var_3_0)

	arg_3_0.energy = var_0_8:initMp(arg_3_0.partnerID)
end

function var_0_0.populateWithSummonInfo(arg_4_0, arg_4_1, arg_4_2)
	arg_4_0.partnerID = arg_4_1
	arg_4_0.summoner = arg_4_2.summoner

	local var_4_0 = var_0_2.new()

	var_4_0:populateWithTableID(arg_4_1)

	var_4_0.level_ = arg_4_2.level or var_4_0.level_
	var_4_0.star_ = arg_4_2.star or var_4_0.star_
	var_4_0.color_ = arg_4_2.color or var_4_0.color_

	for iter_4_0, iter_4_1 in ipairs(var_4_0.skillLev_) do
		local var_4_1 = var_4_0:getSkillId(iter_4_0)
		local var_4_2 = arg_4_0.summoner.hero:getSkillLevelByID(var_4_1)

		if var_4_2 and var_4_2 > 0 then
			var_4_0.skillLev_[iter_4_0] = clone(var_4_2)
		end
	end

	arg_4_0:populateWithHero(var_4_0)

	arg_4_0.energy = var_0_8:initMp(arg_4_0.partnerID)

	table.insert(arg_4_0.summoner.summonMonsters_, arg_4_0)

	if arg_4_0.summonType_ == xyd.summonMonsterType.Monster then
		if arg_4_0.summoner.summonMonster_ then
			arg_4_0.summoner.summonMonster_.hp = 0

			table.removebyvalue(arg_4_0.summoner.summonMonsters_, arg_4_0.summoner.summonMonster_)
		end

		arg_4_0.summoner.summonMonster_ = arg_4_0
	end
end

function var_0_0.init(arg_5_0)
	arg_5_0.isEnergySkill = false
	arg_5_0.lastSkillIndex = 1
	arg_5_0.skillIndex = 1
	arg_5_0.isWalking_ = false
	arg_5_0.isAdjustY_ = false
	arg_5_0.unableMove = false
	arg_5_0.unableEnergySkill_ = false
	arg_5_0.isShowEffect = {}
	arg_5_0.specialSkills = {}
	arg_5_0.moveStack_ = {}
	arg_5_0.showDHarmbuff = nil
	arg_5_0.specialInterval = 0
	arg_5_0.leftInterval = 0
	arg_5_0.walk2Position_ = true
	arg_5_0.startAttackTime = nil
	arg_5_0.preUnits_ = {}
	arg_5_0.unitSkillIDs_ = {}
	arg_5_0.reportMoveStack_ = {}
	arg_5_0.harmSaveSkills_ = {}
	arg_5_0.xixueSaveSkills_ = {}
	arg_5_0.summonMonsters_ = {}
	arg_5_0.summonMonster_ = nil
	arg_5_0.xuliSkill_ = nil
	arg_5_0.noEnergy_ = nil

	if arg_5_0.hero then
		arg_5_0.startCircle = arg_5_0.hero:getStartCircle()
	end

	if next(arg_5_0.buffs) then
		arg_5_0.fighterModel:removeBuffs(arg_5_0.buffs, 0, true)

		arg_5_0.buffs = {}
	end

	arg_5_0.manualTargets = nil
	arg_5_0.manualPosition = nil
	arg_5_0.manualDirection = nil
	arg_5_0.battleBottomWnd = xyd.WindowManager.get():getWindow(xyd.WindowName.battleBottomWnd)
end

function var_0_0.getTableID(arg_6_0)
	return arg_6_0.partnerID
end

function var_0_0.getSkillID(arg_7_0)
	return arg_7_0.skillID
end

function var_0_0.getX(arg_8_0)
	local var_8_0, var_8_1 = arg_8_0.fighterModel:getPosition()

	return var_8_0
end

function var_0_0.getY(arg_9_0)
	local var_9_0, var_9_1 = arg_9_0.fighterModel:getPosition()

	return var_9_1
end

function var_0_0.x(arg_10_0, arg_10_1)
	arg_10_0.fighterModel:x(arg_10_1)
end

function var_0_0.y(arg_11_0, arg_11_1)
	arg_11_0.fighterModel:y(arg_11_1)
end

function var_0_0.moveByX(arg_12_0, arg_12_1)
	local var_12_0, var_12_1 = arg_12_0.fighterModel:getPosition()

	arg_12_0.fighterModel:setPosition(cc.p(var_12_0 + arg_12_1, var_12_1))
end

function var_0_0.moveByY(arg_13_0, arg_13_1)
	local var_13_0, var_13_1 = arg_13_0.fighterModel:getPosition()

	arg_13_0.fighterModel:setPosition(cc.p(var_13_0, var_13_1 + arg_13_1))
end

function var_0_0.getFlipX(arg_14_0)
	return arg_14_0:getFighterModel():getFlipX()
end

function var_0_0.flipX(arg_15_0, arg_15_1)
	arg_15_0:getFighterModel():flipX(arg_15_1)
end

function var_0_0.getModelID(arg_16_0)
	return arg_16_0.modelID
end

function var_0_0.getDistance(arg_17_0)
	if arg_17_0:getNextSkillID() == xyd.JUMO_ORB then
		local var_17_0 = arg_17_0:getTeamType() == xyd.TeamType.A and ngx.ctx.battle.teamA or ngx.ctx.battle.teamB
		local var_17_1

		for iter_17_0, iter_17_1 in ipairs(var_17_0) do
			if not iter_17_1:isDeath() and not iter_17_1:isAffected() and iter_17_1 ~= arg_17_0 then
				if arg_17_0:getFlipX() and iter_17_1:getX() < arg_17_0:getX() then
					var_17_1 = iter_17_1
				elseif not arg_17_0:getFlipX() and iter_17_1:getX() > arg_17_0:getX() then
					var_17_1 = iter_17_1
				end
			end
		end

		if not var_17_1 then
			return var_0_7:distance(xyd.JUMO_JINZHAN)
		end
	end

	return var_0_7:distance(arg_17_0:getNextSkillID())
end

function var_0_0.getHp(arg_18_0)
	return arg_18_0.hp
end

function var_0_0.setHp(arg_19_0, arg_19_1)
	arg_19_0.hp = arg_19_1
end

function var_0_0.getHpLimit(arg_20_0)
	return arg_20_0.isInArena_ and arg_20_0:getHeroHp() * xyd.tables.battleConfig.arenaHpIncrease or arg_20_0:getHeroHp()
end

function var_0_0.updateHp(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	arg_21_0.hp = arg_21_1

	arg_21_0:updateHpBar()

	local var_21_0 = arg_21_0:getHp() / arg_21_0:getHpLimit()

	arg_21_0.fighterModel:setHPProgress(var_21_0, true, nil, arg_21_2)
	arg_21_0.fighterModel:updateHeroHeaderView(arg_21_2, arg_21_0.showDHarmbuff)
end

function var_0_0.getInterval(arg_22_0)
	return var_0_8:interval(arg_22_0.partnerID)
end

function var_0_0.enterSkill(arg_23_0)
	return arg_23_0.hero:enterSkill()
end

function var_0_0.getSummonType(arg_24_0)
	return arg_24_0.summonType_
end

function var_0_0.isDeath(arg_25_0)
	return arg_25_0.hp <= 0
end

function var_0_0.setAvatar(arg_26_0, arg_26_1)
	arg_26_0.avatar = arg_26_1
end

function var_0_0.setEnergyBar(arg_27_0, arg_27_1)
	arg_27_0.energyBar = arg_27_1

	arg_27_0:updateMpBar()
end

function var_0_0.getAvatar(arg_28_0)
	return arg_28_0.avatar
end

function var_0_0.getEnergyBar(arg_29_0)
	return arg_29_0.energyBar
end

function var_0_0.createUnit(arg_30_0, arg_30_1, arg_30_2, arg_30_3)
	local var_30_0 = {
		skillID = arg_30_0.unitSkillIDs_[1],
		fighter = arg_30_0,
		target = arg_30_1,
		count = arg_30_2,
		ackIndex = arg_30_3,
		isEnergySkill = arg_30_0.isEnergySkill,
		attrs = arg_30_0.attributes
	}

	return (var_0_4.new(var_30_0))
end

function var_0_0.createAttacks(arg_31_0, arg_31_1, arg_31_2, arg_31_3)
	if arg_31_1 == nil then
		return
	end

	local var_31_0 = {}
	local var_31_1

	for iter_31_0, iter_31_1 in ipairs(arg_31_1) do
		local var_31_2 = arg_31_0:createUnit(iter_31_1, arg_31_2, arg_31_3)

		table.insert(var_31_0, var_31_2)
	end

	return var_31_0
end

function var_0_0.createToPosUnit(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = {
		skillID = arg_32_0.unitSkillIDs_[1],
		count = arg_32_1,
		fighter = arg_32_0,
		ackIndex = arg_32_2
	}

	return (var_0_3.new(var_32_0))
end

function var_0_0.setSkillIndex(arg_33_0)
	if arg_33_0.isEnergySkill then
		arg_33_0.isEnergySkill = false
	elseif next(arg_33_0.startCircle) ~= nil then
		table.remove(arg_33_0.startCircle, 1)

		local var_33_0 = arg_33_0.startCircle[1]

		if not arg_33_0.hero:getSkillLevelByID(var_33_0) and var_0_11 then
			arg_33_0:setSkillIndex()
		end
	else
		arg_33_0.skillIndex = arg_33_0.skillIndex + 1

		if arg_33_0.skillIndex > #arg_33_0.skills then
			arg_33_0.skillIndex = 1
		end

		if not arg_33_0.hero:getSkillLevelByID(arg_33_0.skills[arg_33_0.skillIndex]) and var_0_11 then
			arg_33_0:setSkillIndex()
		end
	end
end

function var_0_0.skillIsBreak(arg_34_0)
	if next(arg_34_0.startCircle) ~= nil then
		table.remove(arg_34_0.startCircle, 1)
	else
		arg_34_0.skillIndex = arg_34_0.skillIndex + 1

		if arg_34_0.skillIndex > #arg_34_0.skills then
			arg_34_0.skillIndex = 1
		end
	end

	arg_34_0.preUnits_ = {}
	arg_34_0.unitSkillIDs_ = {}
	arg_34_0.isEnergySkill = false
end

function var_0_0.getCurrentSkill(arg_35_0)
	local var_35_0

	if next(arg_35_0.startCircle) then
		local var_35_1 = arg_35_0.startCircle[1]
		local var_35_2 = var_0_7:randomOrb(var_35_1)

		if next(var_35_2) then
			local var_35_3 = {}

			for iter_35_0, iter_35_1 in ipairs(var_35_2) do
				table.insert(var_35_3, 1)
			end

			return var_35_2[xyd.weightedChoise(var_35_3)]
		end

		if var_0_7:orb(var_35_1) > 0 and arg_35_0:canUseSkill(var_0_7:orb(var_35_1)) then
			return var_0_7:orb(var_35_1)
		end

		if var_0_7:buffOrb(var_35_1) > 0 and arg_35_0:canUseBuffSkill(var_0_7:buffOrbSkill(var_35_1), var_0_7:buffOrb(var_35_1)) then
			return var_0_7:buffOrbSkill(var_35_1)
		end

		return var_35_1
	end

	local var_35_4 = arg_35_0.skills[arg_35_0.skillIndex]
	local var_35_5 = var_0_7:randomOrb(var_35_4)

	if next(var_35_5) then
		local var_35_6 = {}

		for iter_35_2, iter_35_3 in ipairs(var_35_5) do
			table.insert(var_35_6, 1)
		end

		return var_35_5[xyd.weightedChoise(var_35_6)]
	end

	if var_0_7:orb(var_35_4) > 0 and arg_35_0:canUseSkill(var_0_7:orb(var_35_4)) then
		return var_0_7:orb(var_35_4)
	end

	if var_0_7:buffOrb(var_35_4) > 0 and arg_35_0:canUseBuffSkill(var_0_7:buffOrbSkill(var_35_4), var_0_7:buffOrb(var_35_4)) then
		return var_0_7:buffOrbSkill(var_35_4)
	end

	return var_35_4
end

function var_0_0.canUseSkill(arg_36_0, arg_36_1)
	local var_36_0 = arg_36_0.hero:getSkillLevelByID(arg_36_1)

	if not var_36_0 or var_36_0 == 0 then
		return false
	end

	local var_36_1 = var_0_7:type(arg_36_1)

	if var_36_1 == xyd.AttackType.AD and arg_36_0:isAdUnable() then
		return false
	end

	if (var_36_1 == xyd.AttackType.AP or var_36_1 == xyd.AttackType.CURE) and arg_36_0:isApUnable() then
		return false
	end

	return true
end

function var_0_0.canUseBuffSkill(arg_37_0, arg_37_1, arg_37_2)
	local var_37_0 = var_0_7:father(arg_37_1)
	local var_37_1 = arg_37_0.hero:getSkillLevelByID(var_37_0)

	if not var_37_1 or var_37_1 == 0 then
		return false
	end

	local var_37_2 = var_0_7:type(arg_37_1)

	if var_37_2 == xyd.AttackType.AD and arg_37_0:isAdUnable() then
		return false
	end

	if (var_37_2 == xyd.AttackType.AP or var_37_2 == xyd.AttackType.CURE) and arg_37_0:isApUnable() then
		return false
	end

	if not arg_37_0:isHasBuffByID(arg_37_2) then
		return false
	end

	return true
end

function var_0_0.getCurrentSkillUnitNum(arg_38_0)
	return tonumber(var_0_7:unitNum(arg_38_0:getNextSkillID()))
end

function var_0_0.getCurrentSkillUnitInterval(arg_39_0)
	return var_0_7:interval(arg_39_0:getNextSkillID())
end

function var_0_0.getCurrentSkillType(arg_40_0)
	return var_0_7:type(arg_40_0:getNextSkillID())
end

function var_0_0.getSelectType(arg_41_0)
	return var_0_7:selectType(arg_41_0:getNextSkillID())
end

function var_0_0.getScope(arg_42_0)
	return var_0_7:scope(arg_42_0:getNextSkillID())
end

function var_0_0.getPrepareTime(arg_43_0)
	return var_0_7:pretime(arg_43_0:getNextSkillID())
end

function var_0_0.getSkillPreTime(arg_44_0)
	return var_0_7:pretime(arg_44_0:getSkillID())
end

function var_0_0.getScale(arg_45_0)
	return arg_45_0.hero:getScale()
end

function var_0_0.getHeroHp(arg_46_0)
	return arg_46_0:getAttrByType(xyd.AttributeType.HP)
end

function var_0_0.getAD(arg_47_0)
	return arg_47_0:getAttrByType(xyd.AttributeType.AD)
end

function var_0_0.getAP(arg_48_0)
	return arg_48_0:getAttrByType(xyd.AttributeType.AP)
end

function var_0_0.getCurrentSpeed(arg_49_0)
	return arg_49_0:getAttrByType(xyd.AttributeType.SPEED)
end

function var_0_0.getShanBi(arg_50_0)
	return arg_50_0:getAttrByType(xyd.AttributeType.SHANBI)
end

function var_0_0.getLevel(arg_51_0)
	return arg_51_0.lv
end

function var_0_0.getADBaoJi(arg_52_0)
	return arg_52_0:getAttrByType(xyd.AttributeType.AD_BAOJI)
end

function var_0_0.getAPBaoJi(arg_53_0)
	return arg_53_0:getAttrByType(xyd.AttributeType.AP_BAOJI)
end

function var_0_0.getADBaoJiHarm(arg_54_0)
	return arg_54_0:getAttrByType(xyd.AttributeType.AD_BAOJIHARM)
end

function var_0_0.getAPBaoJiHarm(arg_55_0)
	return arg_55_0:getAttrByType(xyd.AttributeType.AP_BAOJIHARM)
end

function var_0_0.getHuJia(arg_56_0)
	return arg_56_0:getAttrByType(xyd.AttributeType.HUJIA)
end

function var_0_0.getDHuJia(arg_57_0)
	return arg_57_0:getAttrByType(xyd.AttributeType.D_HUJIA)
end

function var_0_0.getMoKang(arg_58_0)
	return arg_58_0:getAttrByType(xyd.AttributeType.MOKANG)
end

function var_0_0.getDMoKang(arg_59_0)
	return arg_59_0:getAttrByType(xyd.AttributeType.D_MOKANG)
end

function var_0_0.getMingZhong(arg_60_0)
	return arg_60_0:getAttrByType(xyd.AttributeType.MINGZHONG)
end

function var_0_0.getBasicSpeed(arg_61_0)
	return arg_61_0.hero:getSpeed()
end

function var_0_0.getCureRate(arg_62_0)
	return arg_62_0:getAttrByType(xyd.AttributeType.CURE)
end

function var_0_0.getAddCure(arg_63_0)
	return arg_63_0:getAttrByType(xyd.AttributeType.ADD_CURE) / 100
end

function var_0_0.getReMP(arg_64_0)
	return arg_64_0:getAttrByType(xyd.AttributeType.REMP)
end

function var_0_0.getReHP(arg_65_0)
	return arg_65_0:getAttrByType(xyd.AttributeType.REHP)
end

function var_0_0.getDMP(arg_66_0)
	return arg_66_0:getAttrByType(xyd.AttributeType.D_MP)
end

function var_0_0.getHurtMP(arg_67_0)
	return arg_67_0:getAttrByType(xyd.AttributeType.GETMP)
end

function var_0_0.getMP(arg_68_0)
	return arg_68_0.energy
end

function var_0_0.getDelaySkill(arg_69_0)
	return var_0_8:delaySkill(arg_69_0.hero:getTableID()) + (arg_69_0.formationDelay_ or 0)
end

function var_0_0.setFormationDelay(arg_70_0, arg_70_1, arg_70_2)
	arg_70_0.formationDelay_ = arg_70_1 or 0
	arg_70_0.formationWalk2Position_ = arg_70_2 or 100
end

function var_0_0.getXixue(arg_71_0)
	return arg_71_0:getAttrByType(xyd.AttributeType.XIXUE)
end

function var_0_0.getADHitRate(arg_72_0)
	return arg_72_0:getAttrByType(xyd.AttributeType.AD_HIT_RATE)
end

function var_0_0.getADJianShang(arg_73_0)
	return arg_73_0:getAttrByType(xyd.AttributeType.AD_JIANSHANG)
end

function var_0_0.getAPJianShang(arg_74_0)
	return arg_74_0:getAttrByType(xyd.AttributeType.AP_JIANSHANG)
end

function var_0_0.getADBaoJiJianShang(arg_75_0)
	return arg_75_0:getAttrByType(xyd.AttributeType.AD_BAOJI_JIANSHANG)
end

function var_0_0.getAPBaoJiJianShang(arg_76_0)
	return arg_76_0:getAttrByType(xyd.AttributeType.AP_BAOJI_JIANSHANG)
end

function var_0_0.getKillingMp(arg_77_0)
	return arg_77_0:getAttrByType(xyd.AttributeType.KILLING_MP)
end

function var_0_0.getDmpRate(arg_78_0)
	local var_78_0 = arg_78_0:getBuffByID(xyd.MOON_LIGHT_SELF_BUFF)

	if var_78_0 then
		return var_78_0:getDmpRate()
	else
		return 0
	end
end

function var_0_0.getAttackedReEnergy(arg_79_0)
	return arg_79_0:getAttrByType(xyd.AttributeType.ATTACKED_RE_ENERGY)
end

function var_0_0.getBuffHarmRate(arg_80_0)
	return arg_80_0:getAttrByType(xyd.AttackType.BUFF_HARM_RATE)
end

function var_0_0.isHasBuffByType(arg_81_0, arg_81_1, arg_81_2)
	if arg_81_1 == nil or arg_81_0.buffs == nil then
		return false
	end

	for iter_81_0, iter_81_1 in pairs(arg_81_0.buffs) do
		if not iter_81_1:isYongJiu() and arg_81_2 < iter_81_1:getStartTime() + iter_81_1:getTime() and iter_81_1:getType() == arg_81_1 then
			return true
		end
	end

	return false
end

function var_0_0.isHasBuffByID(arg_82_0, arg_82_1)
	for iter_82_0, iter_82_1 in ipairs(arg_82_0.buffs) do
		if iter_82_1:getTableID() == arg_82_1 then
			return true
		end
	end

	return false
end

function var_0_0.getBuffByID(arg_83_0, arg_83_1)
	for iter_83_0, iter_83_1 in ipairs(arg_83_0.buffs) do
		if iter_83_1:getTableID() == arg_83_1 then
			return iter_83_1
		end
	end
end

function var_0_0.getCurrentAckSpeed(arg_84_0)
	local var_84_0 = math.min(arg_84_0:getAttrByType(xyd.AttributeType.ACK_SPEED) / xyd.DECIMAL_BASE, xyd.MAX_ATTACK_SPEED)

	return (math.max(var_84_0, xyd.MIN_ATTACK_SPEED))
end

function var_0_0.getBasicAckSpeed(arg_85_0)
	return var_0_8:getInitialAttr(arg_85_0.partnerID, xyd.AttributeType.ACK_SPEED)
end

function var_0_0.getLeftInterval(arg_86_0)
	return arg_86_0.leftInterval
end

function var_0_0.getSpecialInterval(arg_87_0)
	return arg_87_0.specialInterval
end

function var_0_0.delayLeftInterval(arg_88_0, arg_88_1)
	if arg_88_0.leftInterval ~= nil then
		arg_88_0.leftInterval = math.max(arg_88_0.leftInterval + arg_88_1, arg_88_0:getInterval())
	end
end

function var_0_0.updateLeftInterval(arg_89_0, arg_89_1)
	arg_89_0.specialInterval = math.max(0, arg_89_0.specialInterval - 1)

	if arg_89_0.leftInterval == nil then
		return
	end

	if not arg_89_0:isBattleUnable() then
		arg_89_0.leftInterval = arg_89_0.leftInterval - 1 * arg_89_0:getCurrentAckSpeed()
	end
end

function var_0_0.updateBuffEffect(arg_90_0, arg_90_1)
	if arg_90_0:isDeath() then
		return
	end

	local var_90_0

	for iter_90_0 = #arg_90_0.buffs, 1, -1 do
		local var_90_1 = arg_90_0.buffs[iter_90_0]

		if not var_90_1:isYongJiu() and (arg_90_1 > var_90_1:getStartTime() + var_90_1:getTime() and var_90_1:showEffect() or var_90_1:totalDHarm() > 0 and var_90_1:getDHarm() <= 0) then
			if arg_90_0:getFighterModel() ~= nil then
				arg_90_0.fighterModel:removeBuffs({
					var_90_1
				}, arg_90_1)
			end

			if var_90_1:getYx() > 0 then
				arg_90_0.initPosition = nil
			end

			var_90_1:playRemoveSkill()
			table.remove(arg_90_0.buffs, iter_90_0)
		end
	end

	return false
end

function var_0_0.cleanAllBuffs(arg_91_0, arg_91_1)
	arg_91_0.isEnergySkill = false
	arg_91_0.lastSkillIndex = 1
	arg_91_0.skillIndex = 1
	arg_91_0.isWalking_ = false
	arg_91_0.isAdjustY_ = false
	arg_91_0.unableMove = false
	arg_91_0.isShowEffect = {}
	arg_91_0.showDHarmbuff = nil
	arg_91_0.manualTargets = nil
	arg_91_0.manualPosition = nil
	arg_91_0.manualDirection = nil

	for iter_91_0 = #arg_91_0.buffs, 1, -1 do
		buff = arg_91_0.buffs[iter_91_0]

		if arg_91_0:getFighterModel() ~= nil then
			arg_91_0.fighterModel:removeBuffs({
				buff
			}, arg_91_1, true)
		end

		if buff:getYx() > 0 then
			arg_91_0.initPosition = nil
		end

		buff:playRemoveSkill()
		table.remove(arg_91_0.buffs, iter_91_0)
	end
end

function var_0_0.updateBuffState(arg_92_0, arg_92_1)
	arg_92_0:revive(arg_92_1)

	local var_92_0 = arg_92_0.showDHarmbuff

	if var_92_0 and (var_92_0:getDHarm() <= 0 or arg_92_1 > var_92_0:getStartTime() + var_92_0:getTime()) then
		table.removebyvalue(arg_92_0.buffs, var_92_0)

		if arg_92_0:getFighterModel() ~= nil then
			arg_92_0.fighterModel:removeBuffs({
				var_92_0
			}, arg_92_1, true)
		end

		if var_92_0:getYx() > 0 then
			arg_92_0.initPosition = nil
		end

		var_92_0:playRemoveSkill()

		arg_92_0.showDHarmbuff = nil
	end

	arg_92_0.fighterModel:updateHeroHeaderView(arg_92_1, arg_92_0.showDHarmbuff)
	arg_92_0.fighterModel:updateHeaderViewTime(arg_92_1)
end

function var_0_0.removeBuffByID(arg_93_0, arg_93_1)
	for iter_93_0 = #arg_93_0.buffs, 1, -1 do
		local var_93_0 = arg_93_0.buffs[iter_93_0]

		if var_93_0:getTableID() == arg_93_1 then
			if arg_93_0:getFighterModel() ~= nil then
				arg_93_0.fighterModel:removeBuffs({
					var_93_0
				}, 0, true)
			end

			if var_93_0:getYx() > 0 then
				arg_93_0.initPosition = nil
			end

			var_93_0:playRemoveSkill()

			if var_93_0 == arg_93_0.showDHarmbuff then
				arg_93_0.showDHarmbuff = nil
			end
		end
	end
end

function var_0_0.revive(arg_94_0, arg_94_1)
	if arg_94_0:isDeath() and arg_94_0:isHasReviveBuff() and not arg_94_0.reviveCount then
		-- block empty
	elseif arg_94_0:isDeath() and arg_94_0:isHasReviveBuff() and arg_94_1 > arg_94_0.reviveCount then
		local var_94_0 = arg_94_0:removeReviveBuff()

		arg_94_0.reviveCount = nil

		local var_94_1 = xyd.tables.dbuff:baseHarm(var_94_0:getTableID()) + xyd.tables.dbuff:stepBase(var_94_0:getTableID()) * var_94_0.level_
		local var_94_2 = math.min(var_94_1, arg_94_0:getHpLimit())

		arg_94_0:updateHp(var_94_2, arg_94_1, 1.2)

		local var_94_3 = var_0_7:attackIndex(var_94_0:getSkillID())

		if var_94_3 then
			arg_94_0:playAttack(var_94_3, arg_94_1)
		end

		arg_94_0.fighterModel:hideHeaderView(true)
	end
end

function var_0_0.setHpBar(arg_95_0, arg_95_1)
	arg_95_0.hpBar_ = arg_95_1

	arg_95_0:updateHpBar()
end

function var_0_0.updateHpBar(arg_96_0)
	if arg_96_0.hpBar_ and arg_96_0.battleBottomWnd and arg_96_0.fighterIndex then
		local var_96_0 = xyd.split(arg_96_0.fighterIndex, "|")
		local var_96_1 = tonumber(var_96_0[2])

		arg_96_0.battleBottomWnd:setHPProgress(arg_96_0:getHp() / arg_96_0:getHpLimit(), var_96_1, true)
	end
end

function var_0_0.updateMP(arg_97_0, arg_97_1)
	local var_97_0 = arg_97_1 / arg_97_0:getHpLimit() * arg_97_0:getHurtMP() / xyd.DECIMAL_BASE * xyd.ENERGY_DECIMAL_BASE
	local var_97_1 = arg_97_0.energy

	arg_97_0.energy = math.min(arg_97_0.energy + var_97_0, xyd.ENERGY_DECIMAL_BASE)

	if arg_97_0.energy >= xyd.ENERGY_DECIMAL_BASE and var_97_1 < xyd.ENERGY_DECIMAL_BASE then
		audio.playSound(xyd.tables.sound:getSound("battle_energy_full"))
	end

	return arg_97_0:updateMpBar()
end

function var_0_0.attackReMP(arg_98_0, arg_98_1)
	arg_98_1 = arg_98_1 or arg_98_0:getNextSkillID()

	local var_98_0 = arg_98_0.energy

	arg_98_0.energy = math.min(arg_98_0.energy + var_0_7:reMP(arg_98_1), xyd.ENERGY_DECIMAL_BASE)

	if arg_98_0.energy >= xyd.ENERGY_DECIMAL_BASE and var_98_0 < xyd.ENERGY_DECIMAL_BASE then
		audio.playSound(xyd.tables.sound:getSound("battle_energy_full"))
	end

	return arg_98_0:updateMpBar()
end

function var_0_0.addMp(arg_99_0, arg_99_1)
	local var_99_0 = arg_99_0.energy

	arg_99_0.energy = arg_99_0.energy + arg_99_1
	arg_99_0.energy = math.min(arg_99_0.energy, xyd.ENERGY_DECIMAL_BASE)
	arg_99_0.energy = math.max(arg_99_0.energy, 0)

	if arg_99_0.energy >= xyd.ENERGY_DECIMAL_BASE and var_99_0 < xyd.ENERGY_DECIMAL_BASE then
		audio.playSound(xyd.tables.sound:getSound("battle_energy_full"))
	end

	return arg_99_0:updateMpBar()
end

function var_0_0.updateMpBar(arg_100_0)
	if arg_100_0:getEnergyBar() and arg_100_0.battleBottomWnd and arg_100_0.fighterIndex then
		local var_100_0 = arg_100_0:getEnergyBar():getPercentage()
		local var_100_1 = xyd.split(arg_100_0.fighterIndex, "|")
		local var_100_2 = tonumber(var_100_1[2])

		arg_100_0.battleBottomWnd:setMPProgress(arg_100_0:getMP() / xyd.ENERGY_DECIMAL_BASE, var_100_2, true)

		if var_100_0 < 100 and arg_100_0.energy / 10 >= 100 then
			return true
		end

		return false
	end

	return false
end

function var_0_0.resetLeftInterval(arg_101_0)
	arg_101_0.leftInterval = arg_101_0:getInterval()
end

function var_0_0.setBreakInterval(arg_102_0)
	arg_102_0.leftInterval = math.max(arg_102_0.leftInterval, 0)
	arg_102_0.leftInterval = math.min(arg_102_0.leftInterval + arg_102_0:getHurtPlayDuratuin(), arg_102_0:getInterval())
end

function var_0_0.initEnergySkill(arg_103_0)
	if not arg_103_0.isEnergySkill then
		arg_103_0.isEnergySkill = true
		arg_103_0.leftInterval = 0
		arg_103_0.startAttackTime = nil

		return true
	end

	return false
end

function var_0_0.getNextSkillID(arg_104_0)
	if arg_104_0.isEnergySkill and arg_104_0:getSkillID() > 0 then
		local var_104_0 = var_0_7:randomOrb(arg_104_0:getSkillID())

		if next(var_104_0) then
			local var_104_1 = {}

			for iter_104_0, iter_104_1 in ipairs(var_104_0) do
				table.insert(var_104_1, 1)
			end

			return var_104_0[xyd.weightedChoise(var_104_1)]
		end

		return tonumber(arg_104_0:getSkillID())
	else
		local var_104_2 = arg_104_0:getCurrentSkill()
		local var_104_3 = var_0_7:father(var_104_2)

		if not arg_104_0.hero:getSkillLevelByID(var_104_3) and var_0_11 then
			arg_104_0:setSkillIndex()
		end

		return tonumber(arg_104_0:getCurrentSkill())
	end
end

function var_0_0.canEnergySkill(arg_105_0)
	return not arg_105_0:isDeath() and arg_105_0.energy >= xyd.ENERGY_DECIMAL_BASE
end

function var_0_0.manualType(arg_106_0)
	return var_0_7:manualType(arg_106_0:getSkillID())
end

function var_0_0.checkNextSkillID(arg_107_0, arg_107_1)
	if arg_107_0:isApUnable() or arg_107_0:isAttackFriend() then
		arg_107_0:getADskillIndex()
	elseif arg_107_0:isAdUnable() and not arg_107_0:isExcuteAdCircle() then
		arg_107_0:getAPskillIndex()
	end

	return arg_107_0:getNextSkillID()
end

function var_0_0.getADskillIndex(arg_108_0)
	while next(arg_108_0.startCircle) ~= nil do
		local var_108_0 = arg_108_0.startCircle[1]

		if var_0_7:type(var_108_0) ~= xyd.AttackType.AD then
			table.remove(arg_108_0.startCircle, 1)
		else
			return
		end
	end

	if var_0_7:type(arg_108_0.skills[arg_108_0.skillIndex]) ~= xyd.AttackType.AD then
		local var_108_1 = arg_108_0.skillIndex

		for iter_108_0 = 1, #arg_108_0.skills do
			if arg_108_0.skillIndex + iter_108_0 > #arg_108_0.skills then
				var_108_1 = arg_108_0.skillIndex + iter_108_0 - #arg_108_0.skills
			else
				var_108_1 = arg_108_0.skillIndex + iter_108_0
			end

			if var_0_7:type(arg_108_0.skills[var_108_1]) == xyd.AttackType.AD then
				arg_108_0.skillIndex = var_108_1

				return
			end
		end

		local var_108_2 = var_0_8:name(arg_108_0.partnerID)

		print("-----------------" .. var_108_2 .. "技能序列中没有物理伤害技能-------------------")

		arg_108_0.skillIndex = 1
	end
end

function var_0_0.getAPskillIndex(arg_109_0)
	while next(arg_109_0.startCircle) ~= nil do
		local var_109_0 = arg_109_0.startCircle[1]

		if var_0_7:type(var_109_0) ~= xyd.AttackType.AP and var_0_7:type(var_109_0) ~= xyd.AttackType.CURE then
			table.remove(arg_109_0.startCircle, 1)
		else
			return
		end
	end

	local var_109_1 = var_0_7:type(arg_109_0.skills[arg_109_0.skillIndex])

	if var_109_1 ~= xyd.AttackType.AP and var_109_1 ~= xyd.AttackType.CURE then
		local var_109_2 = arg_109_0.skillIndex

		for iter_109_0 = 1, #arg_109_0.skills do
			if arg_109_0.skillIndex + iter_109_0 > #arg_109_0.skills then
				var_109_2 = arg_109_0.skillIndex + iter_109_0 - #arg_109_0.skills
			else
				var_109_2 = arg_109_0.skillIndex + iter_109_0
			end

			local var_109_3 = var_0_7:type(arg_109_0.skills[var_109_2])

			if var_109_3 == xyd.AttackType.AP or var_109_3 == xyd.AttackType.CURE then
				arg_109_0.skillIndex = var_109_2

				return
			end
		end

		local var_109_4 = var_0_8:name(arg_109_0.partnerID)

		print("-----------------" .. var_109_4 .. "技能序列中没有魔法技能-------------------")

		arg_109_0.skillIndex = 1
	end
end

function var_0_0.addBuffs(arg_110_0, arg_110_1)
	for iter_110_0, iter_110_1 in pairs(arg_110_1) do
		if iter_110_1:getDHarm() > 0 then
			arg_110_0.showDHarmbuff = iter_110_1
		end

		local var_110_0 = 0

		if iter_110_1:getTableID() == xyd.VIP_BUFF1 or iter_110_1:getTableID() == xyd.VIP_BUFF2 then
			for iter_110_2, iter_110_3 in ipairs(arg_110_0.buffs) do
				if iter_110_3:getTableID() == iter_110_1:getTableID() then
					iter_110_3.startCount_ = iter_110_1.startCount_
					var_110_0 = var_110_0 + 1
				end
			end
		end

		if iter_110_1:isCover() then
			local var_110_1

			for iter_110_4, iter_110_5 in ipairs(arg_110_0.buffs) do
				if iter_110_5:getTableID() == iter_110_1:getTableID() then
					iter_110_5.startCount_ = iter_110_1.startCount_

					local var_110_2 = true

					break
				end
			end

			if not var_110_1 then
				table.insert(arg_110_0.buffs, iter_110_1)
				arg_110_0.fighterModel:addBuffs({
					iter_110_1
				})
			end
		else
			if var_110_0 < xyd.VIP_BUFF_MAX_NUM then
				table.insert(arg_110_0.buffs, iter_110_1)
			end

			if var_110_0 < 1 then
				arg_110_0.fighterModel:addBuffs({
					iter_110_1
				})
			end
		end

		if iter_110_1:getYx() > 0 then
			arg_110_0.initPosition = {
				arg_110_0:getX(),
				arg_110_0:getY()
			}
		end
	end
end

function var_0_0.isHasReviveBuff(arg_111_0)
	for iter_111_0, iter_111_1 in ipairs(arg_111_0.buffs) do
		if iter_111_1:getType() == xyd.BuffType.REVIVIE then
			return true
		end
	end

	return false
end

function var_0_0.removeReviveBuff(arg_112_0)
	for iter_112_0, iter_112_1 in ipairs(arg_112_0.buffs) do
		if iter_112_1:getType() == xyd.BuffType.REVIVIE then
			table.remove(arg_112_0.buffs, iter_112_0)

			return iter_112_1
		end
	end
end

function var_0_0.getAttrByType(arg_113_0, arg_113_1)
	local var_113_0 = arg_113_0.hero:getBattleAttr(arg_113_1)
	local var_113_1, var_113_2 = arg_113_0:getBuffAttrChange(arg_113_1)
	local var_113_3 = math.max(1 + var_113_2, 0) * var_113_0 + var_113_1

	return math.max(var_113_3, 0)
end

function var_0_0.buffAttr2HP(arg_114_0, arg_114_1)
	return xyd.STRENGTH_HP_RATE * arg_114_1
end

function var_0_0.buffAttr2AD(arg_115_0, arg_115_1, arg_115_2, arg_115_3)
	if arg_115_0.hero:getHeroType() == xyd.HeroType.STRENGTH then
		return arg_115_1 + arg_115_3 * xyd.AGILE_AD_RATE
	elseif arg_115_0.hero:getHeroType() == xyd.HeroType.WISE then
		return arg_115_2 + arg_115_3 * xyd.AGILE_AD_RATE
	else
		return arg_115_3 + arg_115_3 * xyd.AGILE_AD_RATE
	end
end

function var_0_0.buffAttr2AP(arg_116_0, arg_116_1)
	return arg_116_1 * xyd.WISE_AP_RATE
end

function var_0_0.buffAttr2Hujia(arg_117_0, arg_117_1, arg_117_2)
	return xyd.AGILE_HUJIA_RATE * arg_117_2 + xyd.STRENGTH_HUJIA_RATE * arg_117_1
end

function var_0_0.buffAttr2Mokang(arg_118_0, arg_118_1)
	return xyd.WISE_MOKANG_RATE * arg_118_1
end

function var_0_0.buffAttr2Baoji(arg_119_0, arg_119_1)
	return xyd.AGILE_AD_BAOJI_RATE * arg_119_1
end

function var_0_0.getBuff2Attr(arg_120_0, arg_120_1, arg_120_2, arg_120_3, arg_120_4)
	if arg_120_1 == xyd.AttributeType.HP then
		return arg_120_0:buffAttr2HP(arg_120_2)
	elseif arg_120_1 == xyd.AttributeType.AD then
		return arg_120_0:buffAttr2AD(arg_120_2, arg_120_3, arg_120_4)
	elseif arg_120_1 == xyd.AttributeType.AP then
		return arg_120_0:buffAttr2AP(arg_120_3)
	elseif arg_120_1 == xyd.AttributeType.HUJIA then
		return arg_120_0:buffAttr2Hujia(arg_120_2, arg_120_4)
	elseif arg_120_1 == xyd.AttributeType.MOKANG then
		return arg_120_0:buffAttr2Mokang(arg_120_3)
	elseif arg_120_1 == xyd.AttributeType.AD_BAOJI then
		return arg_120_0:buffAttr2Baoji(arg_120_4)
	end

	return 0
end

function var_0_0.getBuffAttrChange(arg_121_0, arg_121_1)
	local var_121_0 = 0
	local var_121_1 = 0
	local var_121_2 = 0
	local var_121_3 = 0
	local var_121_4 = 0
	local var_121_5 = 0
	local var_121_6 = 0
	local var_121_7 = 0

	for iter_121_0, iter_121_1 in ipairs(arg_121_0.buffs) do
		if iter_121_1:getAttrType() == arg_121_1 then
			local var_121_8, var_121_9 = iter_121_1:getAttr()

			if not var_121_9 then
				var_121_0 = var_121_0 + var_121_8
			else
				var_121_1 = var_121_1 + var_121_8
			end
		end

		if iter_121_1:getAttrType() == xyd.HeroType.STRENGTH then
			local var_121_10, var_121_11 = iter_121_1:getAttr()

			if not var_121_11 then
				var_121_2 = var_121_2 + var_121_10
			else
				var_121_5 = var_121_5 + var_121_10
			end
		elseif iter_121_1:getAttrType() == xyd.HeroType.WISE then
			local var_121_12, var_121_13 = iter_121_1:getAttr()

			if not var_121_13 then
				var_121_3 = var_121_3 + var_121_12
			else
				var_121_6 = var_121_6 + var_121_12
			end
		elseif iter_121_1:getAttrType() == xyd.HeroType.AGILE then
			local var_121_14, var_121_15 = iter_121_1:getAttr()

			if not var_121_15 then
				var_121_4 = var_121_4 + var_121_14
			else
				var_121_7 = var_121_7 + var_121_14
			end
		end
	end

	if arg_121_1 == xyd.AttributeType.HP then
		var_121_0 = var_121_0 + arg_121_0:buffAttr2HP(var_121_2)
	elseif arg_121_1 == xyd.AttributeType.AD then
		var_121_0 = var_121_0 + arg_121_0:buffAttr2AD(var_121_2, var_121_3, var_121_4)
	elseif arg_121_1 == xyd.AttributeType.AP then
		var_121_0 = var_121_0 + arg_121_0:buffAttr2AP(var_121_3)
	elseif arg_121_1 == xyd.AttributeType.HUJIA then
		var_121_0 = var_121_0 + arg_121_0:buffAttr2Hujia(var_121_2, var_121_4)
	elseif arg_121_1 == xyd.AttributeType.MOKANG then
		var_121_0 = var_121_0 + arg_121_0:buffAttr2Mokang(var_121_3)
	elseif arg_121_1 == xyd.AttributeType.AD_BAOJI then
		var_121_0 = var_121_0 + arg_121_0:buffAttr2Baoji(var_121_4)
	end

	return var_121_0, var_121_1
end

function var_0_0.setupBattleAttrInfo(arg_122_0)
	arg_122_0.hero:setupBattleAttrInfo()
end

function var_0_0.isMoveUnable(arg_123_0)
	for iter_123_0, iter_123_1 in ipairs(arg_123_0.buffs) do
		if iter_123_1:isMoveUnable() then
			return true
		end
	end

	return false
end

function var_0_0.isBattleUnable(arg_124_0)
	return arg_124_0:isAdUnable() and arg_124_0:isApUnable()
end

function var_0_0.isAdUnable(arg_125_0)
	for iter_125_0, iter_125_1 in ipairs(arg_125_0.buffs) do
		if iter_125_1:isAdUnable() then
			return true
		end
	end

	return false
end

function var_0_0.isApUnable(arg_126_0)
	for iter_126_0, iter_126_1 in ipairs(arg_126_0.buffs) do
		if iter_126_1:isApUnable() then
			return true
		end
	end

	return false
end

function var_0_0.isExcuteAdCircle(arg_127_0)
	for iter_127_0, iter_127_1 in ipairs(arg_127_0.buffs) do
		if iter_127_1:isExcuteAdCircle() then
			return true
		end
	end

	return false
end

function var_0_0.isExcuteApCircle(arg_128_0)
	for iter_128_0, iter_128_1 in ipairs(arg_128_0.buffs) do
		if iter_128_1:isExcuteApCircle() then
			return true
		end
	end

	return false
end

function var_0_0.isAttackFriend(arg_129_0)
	for iter_129_0, iter_129_1 in ipairs(arg_129_0.buffs) do
		if iter_129_1:isAttackFriend() then
			return true
		end
	end

	return false
end

function var_0_0.isAdBreakImmortal(arg_130_0)
	for iter_130_0, iter_130_1 in ipairs(arg_130_0.buffs) do
		if iter_130_1:isAdBreakImmortal() then
			return true
		end
	end

	return false
end

function var_0_0.isBuffMove(arg_131_0)
	for iter_131_0, iter_131_1 in ipairs(arg_131_0.buffs) do
		if iter_131_1:getYx() > 0 then
			return true
		end
	end

	return false
end

function var_0_0.isImmortal(arg_132_0, arg_132_1)
	if arg_132_1 == xyd.AttackType.AD then
		return arg_132_0:isAdImmortal()
	else
		return arg_132_0:isApImmortal()
	end
end

function var_0_0.isApImmortal(arg_133_0)
	for iter_133_0, iter_133_1 in ipairs(arg_133_0.buffs) do
		if iter_133_1:isApImmortal() then
			return true
		end
	end

	return false
end

function var_0_0.isAdImmortal(arg_134_0)
	for iter_134_0, iter_134_1 in ipairs(arg_134_0.buffs) do
		if iter_134_1:isAdImmortal() then
			return true
		end
	end

	return false
end

function var_0_0.isAffected(arg_135_0)
	if arg_135_0.isUnitResource then
		return true
	end

	for iter_135_0, iter_135_1 in ipairs(arg_135_0.buffs) do
		if iter_135_1:isAffected() then
			return true
		end
	end

	return false
end

function var_0_0.isPause(arg_136_0)
	for iter_136_0, iter_136_1 in ipairs(arg_136_0.buffs) do
		if iter_136_1:pause() then
			return true
		end
	end

	return false
end

function var_0_0.getFighterModelScale(arg_137_0)
	return xyd.tables.model:scale(arg_137_0:getModelID())
end

function var_0_0.setTeamType(arg_138_0, arg_138_1)
	arg_138_0.teamType = arg_138_1
end

function var_0_0.getTeamType(arg_139_0)
	return arg_139_0.teamType
end

function var_0_0.getFighterModel(arg_140_0)
	if not arg_140_0.fighterModel then
		return
	end

	return arg_140_0.fighterModel:getHeroAnimation()
end

function var_0_0.initModels(arg_141_0)
	if not arg_141_0.fighterModel then
		arg_141_0.fighterModel = var_0_6.new(arg_141_0.hero, arg_141_0:getFighterModelScale())
	end
end

function var_0_0.updatePosition(arg_142_0, arg_142_1)
	if arg_142_0:isDeath() then
		return 0, 0
	end

	local var_142_0 = 0
	local var_142_1 = 0

	for iter_142_0, iter_142_1 in pairs(arg_142_0.buffs) do
		if iter_142_1:getYx() > 0 and arg_142_1 <= iter_142_1:getTime() + iter_142_1:getStartTime() then
			var_142_0 = var_142_0 + iter_142_1:getMoveByX(arg_142_1) * iter_142_1:getDirection()
			var_142_1 = var_142_1 + iter_142_1:getMoveByY(arg_142_1)
		end
	end

	return var_142_0, var_142_1
end

function var_0_0.getSkillLvByID(arg_143_0, arg_143_1)
	return arg_143_0.hero:getSkillLevelByID(arg_143_1)
end

function var_0_0.getDHarmBuff(arg_144_0, arg_144_1, arg_144_2)
	local var_144_0 = arg_144_1
	local var_144_1 = 0

	for iter_144_0 = #arg_144_0.buffs, 1, -1 do
		local var_144_2 = arg_144_0.buffs[iter_144_0]
		local var_144_3 = clone(var_144_0)

		if var_144_2:getDHarm() > 0 and (var_144_2:dHarmType() == arg_144_2 or var_144_2:dHarmType() == xyd.HarmType.All) and not var_144_2:isDHarmLast() then
			var_144_0 = var_144_2:setDHarm(var_144_0)

			if var_144_2:harmToHP() > 0 then
				var_144_1 = var_144_1 + var_144_2:harmToHP() * (var_144_3 - var_144_0)
			end

			if var_144_0 == 0 then
				return var_144_0, var_144_1
			end
		end
	end

	return var_144_0, var_144_1
end

function var_0_0.getLastDHarmBuff(arg_145_0, arg_145_1, arg_145_2)
	local var_145_0 = arg_145_1

	for iter_145_0 = #arg_145_0.buffs, 1, -1 do
		local var_145_1 = arg_145_0.buffs[iter_145_0]

		if var_145_1:getDHarm() > 0 and (var_145_1:dHarmType() == arg_145_2 or var_145_1:dHarmType() == xyd.HarmType.All) and var_145_1:isDHarmLast() then
			var_145_0 = var_145_1:setDHarm(var_145_0)

			if var_145_0 == 0 then
				break
			end
		end
	end

	return var_145_0
end

function var_0_0.applyBuffHarm(arg_146_0, arg_146_1)
	local var_146_0 = 0
	local var_146_1 = 0
	local var_146_2

	for iter_146_0 = #arg_146_0.buffs, 1, -1 do
		local var_146_3 = arg_146_0.buffs[iter_146_0]

		if var_146_3:getType() == xyd.BuffType.CONTINUE_HARM then
			var_146_0 = var_146_0 + var_146_3:getHarm()
			var_146_2 = var_146_3.fighter
		elseif var_146_3:getType() == xyd.BuffType.GAIN then
			var_146_1 = var_146_1 + var_146_3:getHarm()
		end
	end

	if var_146_1 == 0 and var_146_0 == 0 then
		return
	end

	local var_146_4 = math.max(0, arg_146_0:getHp() - var_146_0 + var_146_1)

	if var_146_1 - var_146_0 > 0 then
		var_146_4 = math.min(arg_146_0:getHp() - var_146_0 + var_146_1, arg_146_0:getHpLimit())
	end

	percentage = arg_146_0:getHp() / arg_146_0:getHpLimit()

	arg_146_0:updateHp(var_146_4, arg_146_1, 0.3)

	return var_146_2
end

function var_0_0.walk(arg_147_0)
	if arg_147_0.fighterModel:getScale() ~= 1 then
		arg_147_0.fighterModel:scale(1)
	end

	arg_147_0:getFighterModel():walk(true)
end

function var_0_0.playAttack(arg_148_0, arg_148_1, arg_148_2, arg_148_3)
	if not arg_148_1 then
		return
	end

	arg_148_0.unableMove = arg_148_2 + var_0_9:duration(arg_148_0:getModelID(), arg_148_1)

	arg_148_0:getFighterModel():attack(arg_148_1, nil, nil, function()
		if arg_148_0.fighterModel:getScale() ~= 1 then
			arg_148_0.fighterModel:scale(1)
		end

		if arg_148_0:getFighterModel().currentAnimation_ == string.format("gongji%02d", arg_148_1) then
			arg_148_0:resumeIdle()

			if arg_148_3 then
				arg_148_3()
			end
		end
	end)
end

function var_0_0.attacked(arg_150_0, arg_150_1)
	if arg_150_0:getFighterModel().currentAnimation_ and arg_150_0:getFighterModel().currentAnimation_ == "hurt" then
		return
	end

	if arg_150_0.fighterModel:getScale() ~= 1 then
		arg_150_0.fighterModel:scale(1)
	end

	local var_150_0 = var_0_9:hurtDuration(arg_150_0:getModelID())

	arg_150_0.unableMove = arg_150_1 + var_150_0
	arg_150_0.unableEnergySkill_ = arg_150_1 + var_150_0

	arg_150_0:getFighterModel():attacked(function()
		if arg_150_0:getFighterModel().currentAnimation_ == "hurt" then
			arg_150_0:resumeIdle()
		end
	end)
end

function var_0_0.summon(arg_152_0, arg_152_1)
	if not arg_152_0:getFighterModel():hasAnimation("summon") then
		return
	end

	arg_152_0.unableMove = arg_152_1 + var_0_9:summonDuration(arg_152_0:getModelID())

	arg_152_0:getFighterModel():summon(function()
		if arg_152_0:getFighterModel().currentAnimation_ == "summon" then
			arg_152_0:resumeIdle()
		end
	end)
end

function var_0_0.getSkillPlayDuration(arg_154_0)
	local var_154_0 = var_0_7:attackIndex(arg_154_0.skillID)

	duration = math.ceil(var_0_9:duration(arg_154_0:getModelID(), var_154_0) / arg_154_0:getSecondsPerFrame())

	return duration
end

function var_0_0.getIndexPlayDuration(arg_155_0, arg_155_1)
	if not arg_155_1 or arg_155_1 == 0 then
		return 0
	end

	return (math.ceil(var_0_9:duration(arg_155_0:getModelID(), arg_155_1) / arg_155_0:getSecondsPerFrame()))
end

function var_0_0.getHurtPlayDuratuin(arg_156_0)
	return (math.ceil(var_0_9:hurtDuration(arg_156_0:getModelID()) / arg_156_0:getSecondsPerFrame()))
end

function var_0_0.getCurrentAnimation(arg_157_0)
	return arg_157_0:getFighterModel().currentAnimation_
end

function var_0_0.resumeIdleState(arg_158_0)
	arg_158_0.isWalking_ = false
	arg_158_0.isAdjustY_ = false
	arg_158_0.unableMove = false
end

function var_0_0.resumeIdle(arg_159_0)
	if not arg_159_0:isDeath() and arg_159_0:getFighterModel() then
		arg_159_0:getFighterModel():idle()
	end
end

function var_0_0.isWalking(arg_160_0, arg_160_1)
	return arg_160_1 < (arg_160_0.isWalking_ or 0)
end

function var_0_0.isAdjustY(arg_161_0, arg_161_1)
	return arg_161_1 < (arg_161_0.isAdjustY_ or 0)
end

function var_0_0.isSkillMove(arg_162_0)
	return next(arg_162_0.moveStack_)
end

function var_0_0.unableEnergySkill(arg_163_0, arg_163_1)
	return false
end

function var_0_0.getAttachAttr(arg_164_0, arg_164_1)
	if arg_164_1 == 1 then
		return arg_164_0:getHpLimit() - arg_164_0:getHp()
	end

	return 0
end

function var_0_0.energySkillType(arg_165_0)
	return var_0_7:type(arg_165_0:getSkillID())
end

function var_0_0.isWalked2Position(arg_166_0)
	if not arg_166_0.walk2Position_ then
		return true
	end

	if arg_166_0:getTeamType() == xyd.TeamType.A then
		return arg_166_0:getX() > arg_166_0:getFormationWalkPosition()
	else
		return arg_166_0:getX() < xyd.STAGE_WIDTH - arg_166_0:getFormationWalkPosition()
	end
end

function var_0_0.getFormationWalkPosition(arg_167_0)
	return arg_167_0.formationWalk2Position_
end

function var_0_0.playTargetCircle(arg_168_0, arg_168_1)
	if arg_168_0:isDeath() then
		return
	end

	if not arg_168_0.targetCircles_ then
		arg_168_0.targetCircles_ = {}
	end

	for iter_168_0, iter_168_1 in ipairs(arg_168_0.targetCircles_) do
		if iter_168_1 == arg_168_1 then
			arg_168_0.fighterModel:playTargetCircle(true)

			return
		end
	end

	table.insert(arg_168_0.targetCircles_, arg_168_1)
	arg_168_0.fighterModel:playTargetCircle(true)
end

function var_0_0.removeTargetCircle(arg_169_0, arg_169_1, arg_169_2)
	if not arg_169_0.targetCircles_ then
		return
	end

	if arg_169_2 then
		arg_169_0.fighterModel:playTargetCircle(false)
	end

	for iter_169_0 = #arg_169_0.targetCircles_, 1, -1 do
		if arg_169_0.targetCircles_[iter_169_0] == arg_169_1 then
			table.remove(arg_169_0.targetCircles_, iter_169_0)

			break
		end
	end

	if not next(arg_169_0.targetCircles_) and not arg_169_0:isDeath() then
		arg_169_0.fighterModel:playTargetCircle(false)
	end
end

function var_0_0.getSecondsPerFrame(arg_170_0)
	return 0.03333333333333333
end

function var_0_0.getBuffNumByID(arg_171_0, arg_171_1)
	local var_171_0 = 0

	for iter_171_0, iter_171_1 in ipairs(arg_171_0.buffs) do
		if buff:getTableID() == arg_171_1 then
			var_171_0 = var_171_0 + 1
		end
	end

	return var_171_0
end

function var_0_0.pushMoveStack(arg_172_0, arg_172_1, arg_172_2)
	if arg_172_1 < 1 then
		return
	end

	local var_172_0 = arg_172_2 / arg_172_1

	for iter_172_0 = 1, arg_172_1 do
		if arg_172_0.moveStack_[iter_172_0] and math.abs(arg_172_0.moveStack_[iter_172_0]) < math.abs(var_172_0) or not arg_172_0.moveStack_[iter_172_0] then
			arg_172_0.moveStack_[iter_172_0] = var_172_0
		end
	end
end

function var_0_0.popMoveStack(arg_173_0)
	if not arg_173_0.moveStack_[1] then
		return
	end

	table.remove(arg_173_0.moveStack_, 1)
end

function var_0_0.pushReportMoveStack(arg_174_0, arg_174_1, arg_174_2)
	arg_174_1 = arg_174_1 or 0
	arg_174_2 = arg_174_2 or 0
	arg_174_0.reportMoveStack_ = arg_174_0.reportMoveStack_ or {}
	arg_174_0.reportMoveStack_[1] = arg_174_0.reportMoveStack_[1] or 0
	arg_174_0.reportMoveStack_[2] = arg_174_0.reportMoveStack_[2] or 0
	arg_174_0.reportMoveStack_[1] = arg_174_0.reportMoveStack_[1] + arg_174_1
	arg_174_0.reportMoveStack_[2] = arg_174_0.reportMoveStack_[2] + arg_174_2
end

function var_0_0.popReportMoveStack(arg_175_0)
	if not arg_175_0.reportMoveStack_[1] then
		return
	end

	table.remove(arg_175_0.reportMoveStack_, 1)
	table.remove(arg_175_0.reportMoveStack_, 1)

	arg_175_0.adjustYSpeed_ = 0
end

function var_0_0.addHarmSaveSkills(arg_176_0, arg_176_1, arg_176_2)
	arg_176_0.harmSaveSkills_[arg_176_1] = (arg_176_0.harmSaveSkills_[arg_176_1] or 0) + arg_176_2
end

function var_0_0.addXixueSaveSkills(arg_177_0, arg_177_1, arg_177_2)
	arg_177_0.xixueSaveSkills_[arg_177_1] = (arg_177_0.xixueSaveSkills_[arg_177_1] or 0) + arg_177_2
end

return var_0_0
