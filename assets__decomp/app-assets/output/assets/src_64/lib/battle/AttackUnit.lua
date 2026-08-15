local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("AttackUnit")
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("SkillEffect")
local var_0_7 = var_0_2.tables.battleConfig

function var_0_3.ctor(arg_1_0, arg_1_1)
	arg_1_0.buffs = {}
	arg_1_0.records_ = {}

	if arg_1_1.reportdata then
		arg_1_0:readReport(arg_1_1.reportdata)
	end

	arg_1_0.fighter = arg_1_1.fighter
	arg_1_0.target = arg_1_1.target
	arg_1_0.count = arg_1_1.count or var_0_1.ctx.battle.count
	arg_1_0.extraHarm = 0
	arg_1_0.isEnergySkill = var_0_0.clone(var_0_1.ctx.battle.isEnergySkill)

	arg_1_0:setupUnitBasicInfo(arg_1_1.skillID)
	arg_1_0:init()
	arg_1_0:getPathQueue()

	arg_1_0.targets_ = {
		arg_1_0.target
	}
	arg_1_0.recordTargets_ = {}
	arg_1_0.recordTargets_[arg_1_0.target.fighterIndex] = arg_1_0.target
	arg_1_0.manualPosition_ = nil
	arg_1_0.recordIndex_ = nil
	arg_1_0.records_.resetTarget = {}
	arg_1_0.records_.collisionNum = {}
	arg_1_0.records_.collisionNum[tostring(arg_1_0.count)] = arg_1_0.collisionNum
	arg_1_0.records_.calculate = {}
	arg_1_0.records_.buffs = {}
	arg_1_0.records_.initTarget = arg_1_0.target.fighterIndex
	arg_1_0.records_.target_after = {}
	arg_1_0.records_.target_before = {}
	arg_1_0.records_.doge = false
end

function var_0_3.init(arg_2_0, arg_2_1)
	local var_2_0 = var_0_4:ad(arg_2_0.skillID) + var_0_4:adStep(arg_2_0.skillID) * arg_2_0.skillLv
	local var_2_1 = var_0_4:ap(arg_2_0.skillID) + var_0_4:apStep(arg_2_0.skillID) * arg_2_0.skillLv
	local var_2_2 = var_0_4:init(arg_2_0.skillID)
	local var_2_3 = var_0_4:step(arg_2_0.skillID)

	arg_2_0.basicHarm = arg_2_0.fighter:updateUnitBaseByFighter(arg_2_0, var_2_0, var_2_1) + var_2_2 + var_2_3 * arg_2_0.skillLv + arg_2_0.extraHarm

	if arg_2_0.basicHarm > 0 then
		local var_2_4 = arg_2_0.fighter:elementADExtraHarm(arg_2_0)

		arg_2_0.basicHarm = arg_2_0.basicHarm + var_2_4
	end

	arg_2_0.mustBaoji = false

	if arg_2_0:isHasAttachAttr() then
		local var_2_5 = 0
		local var_2_6 = string.find(arg_2_0:isHasAttachAttr(), "B")
		local var_2_7 = tonumber(string.sub(arg_2_0:isHasAttachAttr(), 2, 2))
		local var_2_8 = arg_2_0.skillLv * var_0_4:attachStep(arg_2_0.skillID) + var_0_4:attrToHarm(arg_2_0.skillID)

		if var_2_6 and var_2_7 then
			var_2_5 = arg_2_0.target:getAttachAttr(var_2_7) * var_2_8
		elseif var_2_7 then
			var_2_5 = arg_2_0.fighter:getAttachAttr(var_2_7) * var_2_8
		end

		local var_2_9, var_2_10 = var_0_4:attachLimit(arg_2_0.skillID)

		if var_2_7 <= 2 or var_2_7 == 5 then
			var_2_5 = math.min(var_2_5, var_2_10 * arg_2_0.skillLv)
			var_2_5 = math.max(var_2_5, var_2_9 * arg_2_0.skillLv)
		else
			var_2_5 = math.max(var_2_9 * arg_2_0.skillLv, var_2_10 * arg_2_0.skillLv * var_2_5)
		end

		arg_2_0.basicHarm = arg_2_0.basicHarm + var_2_5
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_2_0.desX_, arg_2_0.desY_ = arg_2_0:getDesPos()

		arg_2_0:recordPosition("des")
	else
		arg_2_0.desX_, arg_2_0.desY_ = unpack(arg_2_0.reportData_.des)
	end

	if arg_2_1 then
		arg_2_0.iniX_, arg_2_0.iniY_ = arg_2_0:getCurrentPos()
	elseif var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_2_0.iniX_, arg_2_0.iniY_ = arg_2_0:getIniPos()

		arg_2_0:recordPosition("init")
	else
		arg_2_0.iniX_, arg_2_0.iniY_ = unpack(arg_2_0.reportData_.init)
	end

	arg_2_0.xDis_ = arg_2_0.desX_ - arg_2_0.iniX_
	arg_2_0.yDis_ = arg_2_0.desY_ - arg_2_0.iniY_
	arg_2_0.applyCount = arg_2_0.count + arg_2_0.timeout
	arg_2_0.arrived = false

	if arg_2_0.yx == var_0_2.YXType.Paowuxian_Duration then
		arg_2_0.speed = math.abs(arg_2_0.xDis_ * var_0_2.tables.battleConfig.interval / var_0_2.tables.battleConfig.attackunitPaowuxianDuration)
	end

	arg_2_0.moveStack_ = {}
end

function var_0_3.setupUnitBasicInfo(arg_3_0, arg_3_1)
	arg_3_0.skillID = arg_3_1
	arg_3_0.selectType = var_0_4:selectType(arg_3_1)
	arg_3_0.attackType = var_0_4:type(arg_3_1)
	arg_3_0.buffIDs = var_0_0.clone(var_0_4:buffs(arg_3_1))
	arg_3_0.speed = var_0_4:speed(arg_3_1)
	arg_3_0.unitEffectType = var_0_4:unitEffectType(arg_3_1)

	if arg_3_0.unitEffectType ~= var_0_2.UnitEffectType.ShanDianLian then
		arg_3_0.resource = arg_3_0:createResource()
	end

	arg_3_0.timeout = var_0_4:timeout(arg_3_1)
	arg_3_0.collisionNum = var_0_4:collisionNum(arg_3_1)
	arg_3_0.isRotate = var_0_4:isRotate(arg_3_1)
	arg_3_0.isResetToXY = var_0_4:isResetToXY(arg_3_1)
	arg_3_0.isResetTarget = var_0_4:isResetTarget(arg_3_1)
	arg_3_0.collisionTimeout = var_0_4:collisionTimeout(arg_3_1)
	arg_3_0.yx = var_0_4:yx(arg_3_1)
	arg_3_0.skillType = var_0_4:skillType(arg_3_1)
	arg_3_0.rootSkill = var_0_4:father(arg_3_1)
	arg_3_0.skillLv = arg_3_0.fighter:getSkillLevelByID(arg_3_0.rootSkill)

	if not arg_3_0.skillLv or arg_3_0.skillLv <= 0 then
		arg_3_0.skillLv = arg_3_0.fighter:getLevel()
	end

	arg_3_0.aTime_ = var_0_0.clone(var_0_4:aTime(arg_3_0.skillID))
	arg_3_0.accelerate_ = var_0_0.clone(var_0_4:accelerate(arg_3_0.skillID))

	arg_3_0:setCollisionCount()
end

function var_0_3.createResource(arg_4_0)
	if not var_0_4:unitResource(arg_4_0.skillID) or var_0_4:unitResource(arg_4_0.skillID) == "" then
		return
	end

	return (var_0_1.ctx.battle.getSpine(arg_4_0.skillID, "unit", arg_4_0.fighter:getScale()))
end

function var_0_3.hasBuff(arg_5_0)
	return arg_5_0.buffIDs and arg_5_0.buffIDs[1] and arg_5_0.buffIDs[1] > 0
end

function var_0_3.getBuffs(arg_6_0, arg_6_1)
	if arg_6_1 or not arg_6_0:hasBuff() then
		return {}, {}, false, false, false
	end

	local var_6_0 = false
	local var_6_1 = false
	local var_6_2 = false
	local var_6_3 = {}
	local var_6_4 = {}
	local var_6_5 = math.max(arg_6_0.skillLv, 20)
	local var_6_6 = math.min(1 / (var_0_2.tables.battleConfig.buffHitParam1 * math.max(arg_6_0.target:getLevel() - var_6_5, 0) + var_0_2.tables.battleConfig.buffHitParam2), 1)
	local var_6_7 = math.max(math.min(var_6_6 - arg_6_0.target:getZhuangtaiDIkang() + arg_6_0.fighter:getZhuangtaiMingzhong(), 1), 0)
	local var_6_8

	var_6_8 = var_0_2.weightedChoise({
		var_6_6,
		1 - var_6_6
	}) == 1

	for iter_6_0, iter_6_1 in pairs(arg_6_0.buffIDs) do
		local var_6_9 = var_0_5.new({
			tableID = iter_6_1,
			start = var_0_1.ctx.battle.count,
			level = arg_6_0.skillLv,
			skillID = arg_6_0.skillID,
			fighter = arg_6_0.fighter,
			target = arg_6_0.target
		})
		local var_6_10 = true

		if var_6_9:dBuffType() > 0 and var_6_9:dBuffType() ~= var_0_2.DBuffType.ATTR_CHANGE and arg_6_0.fighter:getTeamType() ~= arg_6_0.target:getTeamType() then
			var_6_10 = var_0_2.weightedChoise({
				var_6_7,
				1 - var_6_7
			}) == 1
		else
			var_6_10 = var_0_2.weightedChoise({
				var_6_6,
				1 - var_6_6
			}) == 1
		end

		var_6_9:setIsHit(var_6_10)
		var_6_9:setDirection(arg_6_0.fighter:getFlipX())

		if var_6_9:isHit() then
			table.insert(var_6_3, var_6_9)

			var_6_0 = var_6_0 or var_6_9:canBreakSkill("ad")
			var_6_1 = var_6_1 or var_6_9:canBreakSkill("ap")
			var_6_2 = var_6_2 or var_6_9:isAttackFriend()
		else
			table.insert(var_6_4, var_6_9)
		end
	end

	return var_6_3, var_6_4, var_6_0, var_6_1, var_6_2
end

function var_0_3.calculate(arg_7_0)
	arg_7_0.isShanBi = false
	arg_7_0.isBaoJi = false
	arg_7_0.harm = 0

	local var_7_0 = arg_7_0.target
	local var_7_1 = arg_7_0.fighter
	local var_7_2 = math.max(0, var_7_0:getShanBi() - var_7_1:getMingZhong())
	local var_7_3 = (1 - var_7_2 / (100 + var_7_2)) * var_7_1:getADHitRate()

	if var_0_2.weightedChoise({
		1 - var_7_3,
		var_7_3
	}) == 1 and var_0_4:beMiss(arg_7_0.skillID) == 1 and arg_7_0.attackType == var_0_2.AttackType.AD then
		arg_7_0.isShanBi = true
	end

	arg_7_0.mp = var_0_4:mp(arg_7_0.skillID) + var_0_4:mpStep(arg_7_0.skillID) * arg_7_0.skillLv

	if arg_7_0.basicHarm == 0 then
		arg_7_0.isBaoJi, arg_7_0.harm, arg_7_0.cure, arg_7_0.xixue = arg_7_0.mustBaoji, 0, 0, 0

		return arg_7_0.isShanBi, arg_7_0.isBaoJi, arg_7_0.harm, arg_7_0.cure, arg_7_0.xixue, arg_7_0.mp
	end

	if arg_7_0.attackType == var_0_2.AttackType.AD then
		local var_7_4 = var_7_1:getDHuJia()

		if var_7_1:getHunQiSuitID() == var_0_2.HunqiSuitID.CHUANTOU and var_7_0:getHpLimit() > var_7_1:getHpLimit() then
			var_7_4 = var_7_4 + 10 + 0.2 * var_7_1:getHuJia()
		end

		arg_7_0.harm = arg_7_0.basicHarm * arg_7_0.basicHarm / (arg_7_0.basicHarm + 8 * math.max(var_7_0:getHuJia() - var_7_4, 0))

		if var_0_4:ignoreDefence(arg_7_0.skillID) then
			arg_7_0.harm = arg_7_0.basicHarm
		end

		local var_7_5 = 0

		if arg_7_0.fixedBaojiRate then
			var_7_5 = arg_7_0.fixedBaojiRate
		else
			var_7_5 = var_7_1:getADBaoJi() / (var_0_7.hujiaBaojiParam1 * math.max(var_7_0:getHuJia() - var_7_1:getDHuJia(), 0) + var_0_7.hujiaBaojiParam2) + var_7_1:getBothBaoji()
		end

		local var_7_6 = math.min(1, var_7_5)

		if arg_7_0.mustBaoji or var_0_2.weightedChoise({
			var_7_6,
			1 - var_7_6
		}) == 1 then
			arg_7_0.isBaoJi = true
		end

		if not var_7_1:isIgnoreJianshang() then
			arg_7_0.harm = arg_7_0.harm * var_7_0:getADJianShang()
		end
	elseif arg_7_0.attackType == var_0_2.AttackType.AP then
		local var_7_7 = var_7_1:getDMoKang()

		if var_7_1:getHunQiSuitID() == var_0_2.HunqiSuitID.CHUANTOU and var_7_0:getHpLimit() > var_7_1:getHpLimit() then
			var_7_7 = var_7_7 + 10 + 0.2 * var_7_1:getHuJia()
		end

		arg_7_0.harm = arg_7_0.basicHarm * arg_7_0.basicHarm / (arg_7_0.basicHarm + 12 * math.max(var_7_0:getMoKang() - var_7_7, 0))

		if var_0_4:ignoreDefence(arg_7_0.skillID) then
			arg_7_0.harm = arg_7_0.basicHarm
		end

		local var_7_8 = 0

		if arg_7_0.fixedBaojiRate then
			var_7_8 = arg_7_0.fixedBaojiRate
		else
			var_7_8 = var_7_1:getAPBaoJi() / (var_0_7.mokangBaojiParam1 * math.max(var_7_0:getMoKang() - var_7_1:getDMoKang(), 0) + var_0_7.mokangBaojiParam2) + var_7_1:getBothBaoji()
		end

		local var_7_9 = math.min(1, var_7_8)

		if arg_7_0.mustBaoji or var_0_2.weightedChoise({
			var_7_9,
			1 - var_7_9
		}) == 1 then
			arg_7_0.isBaoJi = true
		end

		if not var_7_1:isIgnoreJianshang() then
			arg_7_0.harm = arg_7_0.harm * var_7_0:getAPJianShang()
		end

		local var_7_10 = var_7_0:getAPShanBi()

		if var_7_10 > 0 then
			local var_7_11 = 1 - var_7_10 / (100 + var_7_10)

			if var_0_2.weightedChoise({
				1 - var_7_11,
				var_7_11
			}) == 1 then
				arg_7_0.isShanBi = true
			end
		end
	elseif arg_7_0.attackType == var_0_2.AttackType.CURE then
		arg_7_0.isShanBi = false
		arg_7_0.harm = arg_7_0.basicHarm
	end

	if arg_7_0.isBaoJi and arg_7_0.attackType == var_0_2.AttackType.AD then
		arg_7_0.harm = arg_7_0.harm * (var_7_1:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + var_7_1:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		arg_7_0.harm = arg_7_0.harm * math.max(0.01, var_7_0:getADBaoJiJianShang())
	elseif arg_7_0.isBaoJi and arg_7_0.attackType == var_0_2.AttackType.AP then
		arg_7_0.harm = arg_7_0.harm * (var_7_1:getAPBaoJiHarm() / var_0_2.DECIMAL_BASE + var_7_1:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		arg_7_0.harm = arg_7_0.harm * math.max(0.01, var_7_0:getAPBaoJiJianShang())
	elseif arg_7_0.isBaoJi and arg_7_0.attackType == var_0_2.AttackType.CURE then
		arg_7_0.harm = arg_7_0.harm * (var_7_1:getAPBaoJiHarm() / var_0_2.DECIMAL_BASE + var_7_1:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
	end

	arg_7_0.harm = math.pow(var_0_4:collisionWeaken(arg_7_0.skillID), var_0_4:collisionNum(arg_7_0.skillID) - arg_7_0.collisionNum) * arg_7_0.harm

	if arg_7_0.attackType == var_0_2.AttackType.CURE then
		arg_7_0.cure = arg_7_0.harm * var_7_1:getCureRate() * (1 + var_7_1:getAddCure())
		arg_7_0.harm = 0
	else
		arg_7_0.cure = 0
	end

	local var_7_12 = arg_7_0.fighter:getXixue() / (100 + arg_7_0.target:getLevel() + arg_7_0.fighter:getXixue())

	if arg_7_0.attackType == var_0_2.AttackType.AP then
		var_7_12 = 1 + var_7_1:getAddCure()
	end

	arg_7_0.xixue = var_7_12 * arg_7_0.harm * var_0_4:xixue(arg_7_0.skillID) / var_0_2.DECIMAL_BASE

	if arg_7_0.harm < 5e-08 and arg_7_0.harm > 0 then
		arg_7_0.harm = 0

		print("too small harm! skillID is " .. arg_7_0.skillID)
	end

	if arg_7_0.harm > 0 then
		arg_7_0.harm = math.max(arg_7_0.harm, 1)
	end

	return arg_7_0.isShanBi, arg_7_0.isBaoJi, arg_7_0.harm, arg_7_0.cure, arg_7_0.xixue, arg_7_0.mp
end

function var_0_3.calculateWithSpecialData(arg_8_0, arg_8_1, arg_8_2)
	arg_8_0.isShanBi = false
	arg_8_0.isBaoJi = false
	arg_8_0.harm = 0
	arg_8_0.basicHarm = arg_8_1 or arg_8_0.basicHarm

	local var_8_0 = arg_8_0.target
	local var_8_1 = arg_8_0.fighter
	local var_8_2 = math.max(0, var_8_0:getShanBi() - var_8_1:getMingZhong())
	local var_8_3 = (1 - var_8_2 / (100 + var_8_2)) * var_8_1:getADHitRate()

	if var_0_2.weightedChoise({
		1 - var_8_3,
		var_8_3
	}) == 1 and var_0_4:beMiss(arg_8_0.skillID) == 1 and arg_8_0.attackType == var_0_2.AttackType.AD then
		arg_8_0.isShanBi = true
	end

	arg_8_0.mp = var_0_4:mp(arg_8_0.skillID) + var_0_4:mpStep(arg_8_0.skillID) * arg_8_0.skillLv

	if arg_8_0.basicHarm == 0 then
		arg_8_0.isBaoJi, arg_8_0.harm, arg_8_0.cure, arg_8_0.xixue = false, 0, 0, 0

		return arg_8_0.isShanBi, arg_8_0.isBaoJi, arg_8_0.harm, arg_8_0.cure, arg_8_0.xixue, arg_8_0.mp
	end

	if arg_8_0.attackType == var_0_2.AttackType.AD then
		local var_8_4 = var_8_1:getDHuJia()

		if var_8_1:getHunQiSuitID() == var_0_2.HunqiSuitID.CHUANTOU and var_8_0:getHpLimit() > var_8_1:getHpLimit() then
			var_8_4 = var_8_4 + 10 + 0.2 * var_8_1:getHuJia()
		end

		arg_8_0.harm = arg_8_0.basicHarm * arg_8_0.basicHarm / (arg_8_0.basicHarm + 8 * math.max(var_8_0:getHuJia() - var_8_4, 0))

		local var_8_5 = arg_8_2

		if not arg_8_2 then
			local var_8_6 = var_8_1:getADBaoJi() / (var_0_7.hujiaBaojiParam1 * math.max(var_8_0:getHuJia() - var_8_1:getDHuJia(), 0) + var_0_7.hujiaBaojiParam2) + var_8_1:getBothBaoji()
			local var_8_7 = math.min(1, var_8_6)
		end

		if var_0_2.weightedChoise({
			var_8_5,
			1 - var_8_5
		}) == 1 then
			arg_8_0.isBaoJi = true
		end

		if not var_8_1:isIgnoreJianshang() then
			arg_8_0.harm = arg_8_0.harm * var_8_0:getADJianShang()
		end
	elseif arg_8_0.attackType == var_0_2.AttackType.AP then
		local var_8_8 = var_8_1:getDMoKang()

		if var_8_1:getHunQiSuitID() == var_0_2.HunqiSuitID.CHUANTOU and var_8_0:getHpLimit() > var_8_1:getHpLimit() then
			var_8_8 = var_8_8 + 10 + 0.2 * var_8_1:getHuJia()
		end

		arg_8_0.harm = arg_8_0.basicHarm * arg_8_0.basicHarm / (arg_8_0.basicHarm + 12 * math.max(var_8_0:getMoKang() - var_8_8, 0))

		if var_0_4:ignoreDefence(arg_8_0.skillID) then
			arg_8_0.harm = arg_8_0.basicHarm
		end

		local var_8_9 = arg_8_2

		if not arg_8_2 then
			local var_8_10 = var_8_1:getAPBaoJi() / (var_0_7.mokangBaojiParam1 * math.max(var_8_0:getMoKang() - var_8_1:getDMoKang(), 0) + var_0_7.mokangBaojiParam2) + var_8_1:getBothBaoji()
			local var_8_11 = math.min(1, var_8_10)
		end

		if var_0_2.weightedChoise({
			var_8_9,
			1 - var_8_9
		}) == 1 then
			arg_8_0.isBaoJi = true
		end

		if not var_8_1:isIgnoreJianshang() then
			arg_8_0.harm = arg_8_0.harm * var_8_0:getAPJianShang()
		end
	elseif arg_8_0.attackType == var_0_2.AttackType.CURE then
		arg_8_0.isShanBi = false
		arg_8_0.harm = arg_8_0.basicHarm
	end

	if arg_8_0.isBaoJi and arg_8_0.attackType == var_0_2.AttackType.AD then
		arg_8_0.harm = arg_8_0.harm * (var_8_1:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + var_8_1:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
	elseif arg_8_0.isBaoJi and arg_8_0.attackType == var_0_2.AttackType.AP then
		arg_8_0.harm = arg_8_0.harm * (var_8_1:getAPBaoJiHarm() / var_0_2.DECIMAL_BASE + var_8_1:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
	elseif arg_8_0.isBaoJi and arg_8_0.attackType == var_0_2.AttackType.CURE then
		arg_8_0.harm = arg_8_0.harm * (var_8_1:getAPBaoJiHarm() / var_0_2.DECIMAL_BASE + var_8_1:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
	end

	arg_8_0.harm = math.pow(var_0_4:collisionWeaken(arg_8_0.skillID), var_0_4:collisionNum(arg_8_0.skillID) - arg_8_0.collisionNum) * arg_8_0.harm
	arg_8_0.cure = arg_8_0.harm * var_8_1:getCureRate() * (1 + var_8_1:getAddCure())

	if arg_8_0.attackType == var_0_2.AttackType.CURE then
		arg_8_0.harm = 0
	end

	local var_8_12 = arg_8_0.fighter:getXixue() / (100 + arg_8_0.target:getLevel() + arg_8_0.fighter:getXixue())

	if arg_8_0.attackType == var_0_2.AttackType.AP then
		var_8_12 = 1 + var_8_1:getAddCure()
	end

	arg_8_0.xixue = var_8_12 * arg_8_0.harm * var_0_4:xixue(arg_8_0.skillID) / var_0_2.DECIMAL_BASE

	if arg_8_0.harm < 5e-08 and arg_8_0.harm > 0 then
		arg_8_0.harm = 0

		print("too small harm! skillID is " .. arg_8_0.skillID)
	end

	if arg_8_0.harm > 0 then
		arg_8_0.harm = math.max(arg_8_0.harm, 1)
	end

	return arg_8_0.isShanBi, arg_8_0.isBaoJi, arg_8_0.harm, arg_8_0.cure, arg_8_0.xixue, arg_8_0.mp
end

function var_0_3.speedY(arg_9_0, arg_9_1)
	if arg_9_0.xDis_ == 0 or arg_9_0.arrived then
		return 0
	end

	if arg_9_0.yx == var_0_2.YXType.Yunsu then
		local var_9_0 = arg_9_0:getDesPos("x") - arg_9_0:getX()

		var_9_0 = var_9_0 == 0 and 1 or var_9_0

		return (arg_9_0:getDesPos("y") - arg_9_0:getY()) / math.abs(var_9_0) * arg_9_0:speedX(arg_9_1)
	end
end

function var_0_3.speedX(arg_10_0, arg_10_1)
	if arg_10_0.xDis_ == 0 or arg_10_0.arrived then
		return 0
	end

	if arg_10_0.yx ~= var_0_2.YXType.Yunsu then
		return arg_10_0.speed
	end

	if #arg_10_0.accelerate_ < #arg_10_0.aTime_ then
		error("skill " .. arg_10_0.skillID .. " acceleration is nil")
	elseif #arg_10_0.accelerate_ > #arg_10_0.aTime_ + 1 then
		error("skill " .. arg_10_0.skillID .. " acceleration time is nil")
	end

	local var_10_0 = 0
	local var_10_1 = var_0_0.clone(arg_10_0.accelerate_)

	if #arg_10_0.accelerate_ > #arg_10_0.aTime_ then
		var_10_0 = arg_10_0.accelerate_[#arg_10_0.accelerate_]

		table.remove(var_10_1)
	end

	local var_10_2 = var_0_0.clone(arg_10_0.speed)

	for iter_10_0 = 1, #var_10_1 do
		if arg_10_1 >= arg_10_0.aTime_[iter_10_0] and iter_10_0 == 1 then
			var_10_2 = var_10_2 + arg_10_0.aTime_[1] * arg_10_0.accelerate_[1]
		elseif arg_10_1 >= arg_10_0.aTime_[iter_10_0] and iter_10_0 > 1 then
			var_10_2 = var_10_2 + (arg_10_0.aTime_[iter_10_0] - arg_10_0.aTime_[iter_10_0 - 1]) * arg_10_0.accelerate_[iter_10_0]
		elseif arg_10_1 < arg_10_0.aTime_[iter_10_0] then
			if iter_10_0 > 2 then
				var_10_2 = var_10_2 + (arg_10_1 - arg_10_0.aTime_[iter_10_0 - 1]) * arg_10_0.accelerate_[iter_10_0]

				break
			end

			var_10_2 = var_10_2 + arg_10_1 * arg_10_0.accelerate_[iter_10_0]

			break
		end
	end

	if not next(arg_10_0.aTime_) then
		var_10_2 = var_10_2 + arg_10_1 * var_10_0
	elseif arg_10_1 > arg_10_0.aTime_[#arg_10_0.aTime_] then
		var_10_2 = var_10_2 + (arg_10_1 - arg_10_0.aTime_[#arg_10_0.aTime_]) * var_10_0
	end

	return var_10_2
end

function var_0_3.getPathQueue(arg_11_0)
	local var_11_0 = var_0_2.tables.battleConfig.attackunitPaowuxianDuration
	local var_11_1 = math.min(math.abs(arg_11_0.xDis_), var_0_2.PAOWUXIAN_BASIC_DISTANCE) / var_0_2.PAOWUXIAN_BASIC_DISTANCE * var_11_0
	local var_11_2 = math.ceil(var_11_1)
	local var_11_3 = var_0_4:y(arg_11_0.skillID) * var_11_2 / var_11_0
	local var_11_4 = arg_11_0.yDis_
	local var_11_5 = arg_11_0.xDis_ / var_11_2

	if var_11_3 <= var_11_4 then
		var_11_3 = var_11_4 + 50
	end

	local function var_11_6(arg_12_0, arg_12_1)
		if arg_11_0.yDis_ < 0 then
			local var_12_0 = (4 * math.sqrt(var_11_3 * var_11_3 - var_11_3 * var_11_4) + 4 * var_11_3 - 2 * var_11_4) / (-1 * arg_12_1 * arg_12_1)

			return math.sqrt(-2 * var_12_0 * var_11_3) + var_12_0 * arg_12_0
		else
			local var_12_1 = -2 * (2 * math.sqrt(var_11_3 * var_11_3 - var_11_3 * var_11_4) - var_11_4 + 2 * var_11_3) / (arg_12_1 * arg_12_1)

			return math.sqrt(-2 * var_12_1 * var_11_3) + var_12_1 * arg_12_0
		end
	end

	arg_11_0.pathQueue_ = {}

	if arg_11_0.yx == var_0_2.YXType.Paowuxian_Duration or arg_11_0.yx == var_0_2.YXType.Paowuxian then
		for iter_11_0 = 1, var_11_2 do
			table.insert(arg_11_0.pathQueue_, {
				var_11_5,
				var_11_6(iter_11_0, var_11_2)
			})
		end
	end
end

function var_0_3.movePosition(arg_13_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and arg_13_0.reportData_.calculate and arg_13_0.reportData_.calculate[tostring(var_0_1.ctx.battle.count + 1)] then
		arg_13_0.arrived = true
	end

	if arg_13_0.xDis_ == 0 or arg_13_0.speed == 0 or arg_13_0.arrived or not arg_13_0.resource then
		arg_13_0.arrived = true

		return
	end

	arg_13_0.moveTime_ = (arg_13_0.moveTime_ or 0) + 1

	if arg_13_0.yx == var_0_2.YXType.Paowuxian_Duration or arg_13_0.yx == var_0_2.YXType.Paowuxian then
		if arg_13_0.pathQueue_[1] then
			arg_13_0:moveBy(unpack(arg_13_0.pathQueue_[1]))
			table.remove(arg_13_0.pathQueue_, 1)
		end

		if not next(arg_13_0.pathQueue_) then
			arg_13_0.arrived = true
		end

		return
	end

	if not arg_13_0.isResetToXY then
		if math.abs(arg_13_0:getX() - arg_13_0.desX_) <= arg_13_0:speedX(arg_13_0.moveTime_) then
			arg_13_0.arrived = true

			arg_13_0.resource:pos(arg_13_0.desX_, arg_13_0.desY_)
		else
			if arg_13_0:getX() == arg_13_0.desX_ then
				return
			end

			local var_13_0 = arg_13_0:speedX(arg_13_0.moveTime_) * (arg_13_0.desX_ - arg_13_0:getX()) / math.abs(arg_13_0:getX() - arg_13_0.desX_)
			local var_13_1 = arg_13_0:speedY(arg_13_0.moveTime_)

			arg_13_0:moveBy(var_13_0, var_13_1)
		end

		return
	end

	if math.abs(arg_13_0:getX() - arg_13_0:getDesPos("x")) <= arg_13_0:speedX(arg_13_0.moveTime_) then
		arg_13_0.arrived = true

		arg_13_0.resource:pos(arg_13_0:getDesPos("x"), arg_13_0:getDesPos("y"))
	else
		if arg_13_0:getDesPos("x") == arg_13_0:getX() then
			return
		end

		local var_13_2 = arg_13_0:speedX(arg_13_0.moveTime_) * (arg_13_0:getDesPos("x") - arg_13_0:getX()) / math.abs(arg_13_0:getDesPos("x") - arg_13_0:getX())
		local var_13_3 = arg_13_0:speedY(arg_13_0.moveTime_)

		arg_13_0:moveBy(var_13_2, var_13_3)
	end
end

function var_0_3.rotate(arg_14_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_14_0.isRotate or arg_14_0.arrived or not arg_14_0.resource or var_0_1.ctx.battle.isReleased(arg_14_0.resource) then
		return
	end

	local var_14_0 = arg_14_0.moveTime_ or 1
	local var_14_1 = 0
	local var_14_2 = 0

	if arg_14_0.yx == var_0_2.YXType.Paowuxian_Duration or arg_14_0.yx == var_0_2.YXType.Paowuxian then
		if arg_14_0.pathQueue_[1] then
			var_14_1, var_14_2 = unpack(arg_14_0.pathQueue_[1])
		end
	else
		var_14_1, var_14_2 = arg_14_0:speedX(var_14_0), arg_14_0:speedY(var_14_0)
		var_14_1 = var_14_1 * arg_14_0.xDis_ / math.abs(arg_14_0.xDis_)
	end

	local var_14_3 = arg_14_0.resource:getRotationSkewX()
	local var_14_4 = var_14_1
	local var_14_5 = var_14_2

	if var_14_1 < 0 then
		arg_14_0.resource:flipX(true)

		var_14_5 = -var_14_2
		var_14_4 = -var_14_1
	else
		arg_14_0.resource:flipX(false)
	end

	local var_14_6 = math.atan2(var_14_5, var_14_4) / math.pi * -180

	if var_14_3 ~= var_14_6 then
		arg_14_0.resource:rotation(var_14_6)
	end
end

function var_0_3.getArriveCount(arg_15_0)
	if arg_15_0.speed < 1 then
		return
	end

	return math.ceil(math.abs(arg_15_0.xDis_) / arg_15_0.speed + arg_15_0.count)
end

function var_0_3.resetTarget(arg_16_0, arg_16_1)
	arg_16_0.target = arg_16_1

	table.insert(arg_16_0.targets_, arg_16_1)

	arg_16_0.recordTargets_[arg_16_1.fighterIndex] = arg_16_1

	arg_16_0:init(true)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_16_0.records_.resetTarget[tostring(var_0_1.ctx.battle.count)] = arg_16_1.fighterIndex
end

function var_0_3.getDesPos(arg_17_0, arg_17_1)
	if not arg_17_0.target then
		return
	end

	local var_17_0, var_17_1 = arg_17_0.target:getPos()

	if arg_17_1 == "x" then
		return var_17_0 + arg_17_0.target:getAttackedPoint().x
	elseif arg_17_1 == "y" then
		return var_17_1 + arg_17_0.target:getAttackedPoint().y
	else
		return var_17_0 + arg_17_0.target:getAttackedPoint().x, var_17_1 + arg_17_0.target:getAttackedPoint().y
	end
end

function var_0_3.getCurrentPos(arg_18_0)
	if arg_18_0.resource then
		return arg_18_0:getX(), arg_18_0:getY()
	end

	return arg_18_0:getIniPos()
end

function var_0_3.getIniPos(arg_19_0, arg_19_1)
	local var_19_0, var_19_1 = arg_19_0.fighter:getPos()
	local var_19_2 = var_0_4:attackIndex(arg_19_0.skillID)
	local var_19_3 = arg_19_0.fighter:getAttackPoint(var_19_2) or arg_19_0.fighter:getAttackPoint(1)

	var_19_3 = var_19_3 or {
		x = 0,
		y = 0
	}

	if arg_19_1 == "x" then
		return var_19_0 + var_19_3.x
	elseif arg_19_1 == "y" then
		return var_19_1 + var_19_3.y
	else
		return var_19_0 + var_19_3.x, var_19_1 + var_19_3.y
	end
end

function var_0_3.getX(arg_20_0)
	if not arg_20_0.resource then
		return
	end

	return arg_20_0.resource:getX()
end

function var_0_3.getY(arg_21_0)
	if not arg_21_0.resource then
		return
	end

	return arg_21_0.resource:getY()
end

function var_0_3.moveBy(arg_22_0, arg_22_1, arg_22_2)
	if not arg_22_0.resource or var_0_1.ctx.battle.isReleased(arg_22_0.resource) then
		return
	end

	local var_22_0, var_22_1 = arg_22_0.resource:getPosition()

	arg_22_0.resource:pos(var_22_0 + arg_22_1, var_22_1 + arg_22_2)
end

function var_0_3.setExtraHarm(arg_23_0, arg_23_1)
	arg_23_0.extraHarm = arg_23_1

	arg_23_0:init(true)
end

function var_0_3.isResetTarget(arg_24_0)
	return arg_24_0.isResetTarget
end

function var_0_3.getCollisionCount(arg_25_0)
	return arg_25_0.collisionCount
end

function var_0_3.setCollisionCount(arg_26_0)
	arg_26_0.collisionCount = arg_26_0.collisionTimeout
end

function var_0_3.isHasAttachAttr(arg_27_0)
	return var_0_4:attachAttr(arg_27_0.skillID)
end

function var_0_3.getHitSound(arg_28_0)
	return var_0_4:hitSound(arg_28_0.skillID)
end

function var_0_3.hitMove(arg_29_0)
	return var_0_4:hitMove(arg_29_0.skillID)
end

function var_0_3.hitMoveTime(arg_30_0)
	return var_0_4:hitMoveTime(arg_30_0.skillID)
end

function var_0_3.isForceBreak(arg_31_0)
	return var_0_4:forceBreak(arg_31_0.skillID)
end

function var_0_3.isInvalidAfterDeath(arg_32_0)
	return var_0_4:isInvalidAfterDeath(arg_32_0.skillID)
end

function var_0_3.getStartCount(arg_33_0)
	return arg_33_0.count
end

function var_0_3.addCollisionNum(arg_34_0)
	arg_34_0.collisionNum = arg_34_0.collisionNum + 1

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_34_0.records_.collisionNum[tostring(var_0_1.ctx.battle.count)] = arg_34_0.collisionNum
end

function var_0_3.setCollisionNum(arg_35_0)
	arg_35_0.collisionNum = arg_35_0.collisionNum - 1

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_35_0.records_.collisionNum[tostring(var_0_1.ctx.battle.count)] = arg_35_0.collisionNum
end

function var_0_3.clearCollisionNum(arg_36_0)
	arg_36_0.collisionNum = 0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_36_0.records_.collisionNum[tostring(var_0_1.ctx.battle.count)] = arg_36_0.collisionNum
end

function var_0_3.recordData(arg_37_0, arg_37_1, arg_37_2, arg_37_3, arg_37_4, arg_37_5, arg_37_6)
	arg_37_0.records_.calculate[tostring(var_0_1.ctx.battle.count)] = {
		arg_37_1,
		arg_37_2,
		arg_37_3,
		arg_37_4,
		arg_37_5,
		arg_37_6,
		arg_37_0.target:getHp(),
		arg_37_0.target:getEnergy()
	}
end

function var_0_3.recordBuff(arg_38_0, arg_38_1, arg_38_2, arg_38_3, arg_38_4, arg_38_5)
	local var_38_0 = {}
	local var_38_1 = {}

	for iter_38_0, iter_38_1 in ipairs(arg_38_1) do
		table.insert(var_38_0, iter_38_1:getTableID())
	end

	for iter_38_2, iter_38_3 in ipairs(arg_38_2) do
		table.insert(var_38_1, iter_38_3:getTableID())
	end

	arg_38_0.records_.buffs[tostring(var_0_1.ctx.battle.count)] = {
		var_38_0,
		var_38_1,
		arg_38_3,
		arg_38_4,
		arg_38_5
	}
end

function var_0_3.getReportBuffs(arg_39_0)
	if not arg_39_0.reportData_.buffs[tostring(var_0_1.ctx.battle.count)] then
		return {}, {}, false, false
	end

	local var_39_0, var_39_1, var_39_2, var_39_3, var_39_4 = unpack(arg_39_0.reportData_.buffs[tostring(var_0_1.ctx.battle.count)])
	local var_39_5 = {}
	local var_39_6 = {}

	for iter_39_0, iter_39_1 in pairs(var_39_0) do
		local var_39_7 = var_0_5.new({
			tableID = iter_39_1,
			start = var_0_1.ctx.battle.count,
			level = arg_39_0.skillLv,
			skillID = arg_39_0.skillID,
			fighter = arg_39_0.fighter,
			target = arg_39_0.target
		})

		var_39_7:setIsHit(true)
		var_39_7:setDirection(arg_39_0.fighter:getFighterModel():getFlipX())
		table.insert(var_39_5, var_39_7)
	end

	for iter_39_2, iter_39_3 in pairs(var_39_1) do
		local var_39_8 = var_0_5.new({
			tableID = iter_39_3,
			start = var_0_1.ctx.battle.count,
			level = arg_39_0.skillLv,
			skillID = arg_39_0.skillID,
			fighter = arg_39_0.fighter,
			target = arg_39_0.target
		})

		var_39_8:setIsHit(false)
		var_39_8:setDirection(arg_39_0.fighter:getFighterModel():getFlipX())
		table.insert(var_39_6, var_39_8)
	end

	return var_39_5, var_39_6, var_39_2, var_39_3, var_39_4
end

function var_0_3.recordPosition(arg_40_0, arg_40_1)
	if arg_40_1 == "des" then
		arg_40_0.records_[arg_40_1] = {
			arg_40_0:getDesPos()
		}
	elseif arg_40_1 == "init" then
		arg_40_0.records_[arg_40_1] = {
			arg_40_0:getIniPos()
		}
	end
end

function var_0_3.recordTargetState(arg_41_0, arg_41_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_41_1 == "before" then
		arg_41_0.records_.target_before[tostring(var_0_1.ctx.battle.count)] = {
			arg_41_0.target:getHp(),
			arg_41_0.target:getEnergy()
		}
	elseif arg_41_1 == "after" then
		arg_41_0.records_.target_after[tostring(var_0_1.ctx.battle.count)] = {
			arg_41_0.target:getHp(),
			arg_41_0.target:getEnergy()
		}
	end
end

function var_0_3.writeReport(arg_42_0)
	arg_42_0.records_.fighter = arg_42_0.fighter.fighterIndex
	arg_42_0.records_.start = arg_42_0.count
	arg_42_0.records_.recordIndex = arg_42_0.recordIndex_
	arg_42_0.records_.skillID = arg_42_0.skillID

	return arg_42_0.records_
end

function var_0_3.readReport(arg_43_0, arg_43_1)
	arg_43_0.recordIndex_ = tonumber(arg_43_1.recordIndex)
	arg_43_0.reportData_ = {}
	arg_43_0.reportData_.collisionNum = arg_43_1.collisionNum
	arg_43_0.reportData_.calculate = arg_43_1.calculate
	arg_43_0.reportData_.buffs = arg_43_1.buffs
	arg_43_0.reportData_.resetTarget = {}
	arg_43_0.reportData_.des = arg_43_1.des
	arg_43_0.reportData_.init = arg_43_1.init
	arg_43_0.reportData_.target_before = arg_43_1.target_before
	arg_43_0.reportData_.target_after = arg_43_1.target_after
	arg_43_0.reportData_.doge = arg_43_1.doge

	for iter_43_0, iter_43_1 in pairs(arg_43_1.resetTarget) do
		arg_43_0.reportData_.resetTarget[iter_43_0] = var_0_1.ctx.battle.getFighter(iter_43_1)
	end
end

return var_0_3
