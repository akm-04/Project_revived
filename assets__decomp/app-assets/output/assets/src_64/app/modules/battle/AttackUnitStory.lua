local var_0_0 = class("AttackUnit")
local var_0_1 = xyd.tables.skill
local var_0_2 = import("app.modules.battle.BuffStory")
local var_0_3 = import("app.modules.battle.SkillEffect")
local var_0_4 = 0.05
local var_0_5 = xyd.tables.battleConfig

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.buffs = {}
	arg_1_0.fighter = arg_1_1.fighter
	arg_1_0.target = arg_1_1.target
	arg_1_0.startCount = arg_1_1.count
	arg_1_0.count = arg_1_1.count
	arg_1_0.ackIndex = arg_1_1.ackIndex
	arg_1_0.isEnergySkill = arg_1_1.isEnergySkill

	arg_1_0:setupUnitBasicInfo(arg_1_1.skillID)
	arg_1_0:setupAttrInfo(arg_1_1.attrs)
	arg_1_0:init()

	arg_1_0.targets_ = {
		arg_1_0.target
	}
	arg_1_0.recordTargets_ = {}
	arg_1_0.recordTargets_[arg_1_0.target.fighterIndex] = arg_1_0.target
	arg_1_0.manualPosition_ = nil
end

function var_0_0.init(arg_2_0, arg_2_1)
	local var_2_0 = var_0_1:ad(arg_2_0.skillID) + var_0_1:adStep(arg_2_0.skillID) * arg_2_0.skillLv
	local var_2_1 = var_0_1:ap(arg_2_0.skillID) + var_0_1:apStep(arg_2_0.skillID) * arg_2_0.skillLv
	local var_2_2 = var_0_1:init(arg_2_0.skillID)
	local var_2_3 = var_0_1:step(arg_2_0.skillID)

	arg_2_0.basicHarm = arg_2_0.fighter:getAD() * var_2_0 / xyd.DECIMAL_BASE + arg_2_0.fighter:getAP() * var_2_1 / xyd.DECIMAL_BASE + var_2_2 + var_2_3 * arg_2_0.skillLv

	if arg_2_0:isHasAttachAttr() then
		local var_2_4 = 0
		local var_2_5 = string.find(arg_2_0:isHasAttachAttr(), "B")
		local var_2_6 = tonumber(string.sub(arg_2_0:isHasAttachAttr(), 2, 2))
		local var_2_7 = arg_2_0.skillLv * var_0_1:attachStep(arg_2_0.skillID) + var_0_1:attrToHarm(arg_2_0.skillID)

		if var_2_5 and var_2_6 then
			var_2_4 = arg_2_0.target:getAttachAttr(var_2_6) * var_2_7
		elseif var_2_6 then
			var_2_4 = arg_2_0.fighter:getAttachAttr(var_2_6) * var_2_7
		end

		local var_2_8, var_2_9 = var_0_1:attachLimit(arg_2_0.skillID)
		local var_2_10 = math.min(var_2_4, var_2_9 * arg_2_0.skillLv)
		local var_2_11 = math.max(var_2_10, var_2_8 * arg_2_0.skillLv)

		arg_2_0.basicHarm = arg_2_0.basicHarm + var_2_11
	end

	arg_2_0.desX_, arg_2_0.desY_ = arg_2_0:getDesPos()

	if arg_2_1 then
		arg_2_0.iniX_, arg_2_0.iniY_ = arg_2_0:getCurrentPos()
	else
		arg_2_0.iniX_, arg_2_0.iniY_ = arg_2_0:getIniPos()
	end

	arg_2_0.xDis_ = arg_2_0.desX_ - arg_2_0.iniX_
	arg_2_0.yDis_ = arg_2_0.desY_ - arg_2_0.iniY_
	arg_2_0.applyCount = arg_2_0.startCount + arg_2_0.timeout
	arg_2_0.arrived = false

	if arg_2_0.yx == xyd.YXType.Paowuxian_Duration then
		arg_2_0.speed = math.abs(arg_2_0.xDis_ * xyd.tables.battleConfig.interval / xyd.tables.battleConfig.attackunitPaowuxianDuration)
	end

	arg_2_0.moveStack_ = {}
end

function var_0_0.setupUnitBasicInfo(arg_3_0, arg_3_1)
	arg_3_0.skillID = arg_3_1
	arg_3_0.selectType = var_0_1:selectType(arg_3_1)
	arg_3_0.attackType = var_0_1:type(arg_3_1)
	arg_3_0.buffIDs = var_0_1:buffs(arg_3_1)
	arg_3_0.resource = arg_3_0:createResource()
	arg_3_0.speed = var_0_1:speed(arg_3_1)
	arg_3_0.unitEffectType = var_0_1:unitEffectType(arg_3_1)
	arg_3_0.timeout = var_0_1:timeout(arg_3_1)
	arg_3_0.collisionNum = var_0_1:collisionNum(arg_3_1)
	arg_3_0.isRotate = var_0_1:isRotate(arg_3_1)
	arg_3_0.isResetToXY = var_0_1:isResetToXY(arg_3_1)
	arg_3_0.isResetTarget = var_0_1:isResetTarget(arg_3_1)
	arg_3_0.collisionTimeout = var_0_1:collisionTimeout(arg_3_1)
	arg_3_0.yx = var_0_1:yx(arg_3_1)
	arg_3_0.skillType = var_0_1:skillType(arg_3_1)
	arg_3_0.rootSkill = var_0_1:father(arg_3_1)

	if var_0_1:skillType(arg_3_0.rootSkill) ~= xyd.SkillType.PU_GONG then
		arg_3_0.skillLv = arg_3_0.fighter:getSkillLvByID(arg_3_0.rootSkill) or arg_3_0.fighter:getLevel()
	else
		arg_3_0.skillLv = arg_3_0.fighter:getLevel()
	end

	arg_3_0.aTime_ = clone(var_0_1:aTime(arg_3_0.skillID))
	arg_3_0.accelerate_ = clone(var_0_1:accelerate(arg_3_0.skillID))
end

function var_0_0.createResource(arg_4_0)
	if not var_0_1:unitResource(arg_4_0.skillID) or var_0_1:unitResource(arg_4_0.skillID) == "" then
		return
	end

	return (var_0_3.new(arg_4_0.skillID, "unit", arg_4_0.fighter:getScale()))
end

function var_0_0.hasBuff(arg_5_0)
	return arg_5_0.buffIDs and arg_5_0.buffIDs[1] and arg_5_0.buffIDs[1] > 0
end

function var_0_0.getBuffInfo(arg_6_0, arg_6_1)
	local var_6_0 = {}

	if arg_6_0.recordBuffs_ and next(arg_6_0.recordBuffs_) then
		var_6_0.breakApSkill = arg_6_0.recordBuffs_.breakApSkill
		var_6_0.breakAdSkill = arg_6_0.recordBuffs_.breakAdSkill
		var_6_0.isBuffHit = arg_6_0.recordBuffs_.isBuffHit

		for iter_6_0, iter_6_1 in pairs(arg_6_0.buffIDs) do
			local var_6_1 = var_0_2.new({
				tableID = iter_6_1,
				start = arg_6_1,
				level = arg_6_0.skillLv,
				skillID = arg_6_0.skillID,
				fighter = arg_6_0.fighter,
				target = arg_6_0.target
			})

			var_6_1:setIsHit(arg_6_0.recordBuffs_.hits[iter_6_0])
			var_6_1:setShowEffect()
			var_6_1:setDirection(arg_6_0.fighter:getFighterModel():getFlipX())

			if var_6_1:getRemoveSkill() > 0 and arg_6_0.manualPosition_ and var_6_1:getYx() > 0 then
				var_6_1:resetYXChange(arg_6_0.manualPosition_[1])
			end

			table.insert(arg_6_0.buffs, var_6_1)
		end

		return var_6_0, arg_6_0.buffs
	end

	var_6_0.breakApSkill = false
	var_6_0.breakAdSkill = false

	local var_6_2 = math.max(arg_6_0.skillLv, 20)
	local var_6_3 = math.max(arg_6_0.target.lv, 1)
	local var_6_4 = math.min(var_6_2 / var_6_3, 1)

	var_6_0.isBuffHit = xyd.weightedChoise({
		var_6_4,
		1 - var_6_4
	}) == 1

	local var_6_5 = 0

	for iter_6_2, iter_6_3 in pairs(arg_6_0.buffIDs) do
		local var_6_6 = var_0_2.new({
			tableID = iter_6_3,
			start = arg_6_1,
			level = arg_6_0.skillLv,
			skillID = arg_6_0.skillID,
			fighter = arg_6_0.fighter,
			target = arg_6_0.target
		})

		var_6_0.breakApSkill = var_6_0.breakApSkill or var_6_6:canBreakSkill("ap")
		var_6_0.breakAdSkill = var_6_0.breakAdSkill or var_6_6:canBreakSkill("ad")

		var_6_6:setIsHit(var_6_0.isBuffHit)
		var_6_6:setShowEffect()
		var_6_6:setDirection(arg_6_0.fighter:getFighterModel():getFlipX())

		if var_6_6:isHit() then
			var_6_5 = var_6_5 + 1
		end

		if var_6_6:getRemoveSkill() > 0 and arg_6_0.manualPosition_ and var_6_6:getYx() > 0 then
			var_6_6:resetYXChange(arg_6_0.manualPosition_[1])
		end

		table.insert(arg_6_0.buffs, var_6_6)
	end

	if var_6_5 >= table.nums(arg_6_0.buffIDs) and not var_6_0.isBuffHit then
		var_6_0.isBuffHit = true
	end

	return var_6_0, arg_6_0.buffs
end

function var_0_0.addExtraBuffs(arg_7_0, arg_7_1)
	arg_7_0.extraBuffs_ = arg_7_0.extraBuffs_ or {}
	arg_7_1 = arg_7_1 or {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_1) do
		table.insert(arg_7_0.extraBuffs_, iter_7_1)
	end
end

function var_0_0.getExtraBuffs(arg_8_0, arg_8_1)
	local var_8_0 = {}
	local var_8_1 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.extraBuffs or {}) do
		local var_8_2 = var_0_2.new({
			tableID = iter_8_1.id,
			start = arg_8_1,
			level = iter_8_1.level,
			skillID = arg_8_0.skillID,
			fighter = arg_8_0.fighter,
			target = arg_8_0.target
		})

		var_8_1.breakApSkill = var_8_1.breakApSkill or var_8_2:canBreakSkill("ap")
		var_8_1.breakAdSkill = var_8_1.breakAdSkill or var_8_2:canBreakSkill("ad")

		var_8_2:setIsHit(true)
		var_8_2:setShowEffect()
		var_8_2:setDirection(arg_8_0.fighter:getFighterModel():getFlipX())
		table.insert(arg_8_0.buffs, var_8_2)
		table.insert(var_8_0, var_8_2)
	end

	return var_8_0, var_8_1.breakApSkill, var_8_1.breakAdSkill
end

function var_0_0.setupAttrInfo(arg_9_0, arg_9_1)
	arg_9_0.attributes = arg_9_1 or {}
end

function var_0_0.setupTargetInfo(arg_10_0, arg_10_1)
	arg_10_0.eAttributes = arg_10_1 or {}
end

function var_0_0.recordBuffs(arg_11_0, arg_11_1)
	arg_11_0.recordBuffs_ = arg_11_1
end

function var_0_0.recordCalculateResult(arg_12_0, arg_12_1)
	arg_12_0.recordResult_ = {
		arg_12_1.isShanBi,
		arg_12_1.isBaoJi,
		tonumber(arg_12_1.harm),
		tonumber(arg_12_1.cure),
		tonumber(arg_12_1.xixue),
		tonumber(arg_12_1.mp)
	}
	arg_12_0.applyCount = tonumber(arg_12_1.applyCount)
end

function var_0_0.getRecordResult(arg_13_0)
	return unpack(arg_13_0.recordResult_)
end

function var_0_0.calculate(arg_14_0)
	if arg_14_0.recordResult_ and next(arg_14_0.recordResult_) then
		return arg_14_0:getRecordResult()
	end

	arg_14_0.isShanBi = false
	arg_14_0.isBaoJi = false
	arg_14_0.harm = 0

	local var_14_0 = arg_14_0.target
	local var_14_1 = arg_14_0.fighter
	local var_14_2 = math.max(0, var_14_0:getShanBi() - var_14_1:getMingZhong())
	local var_14_3 = (1 - var_14_2 / (100 + var_14_2)) * var_14_1:getADHitRate()

	if xyd.weightedChoise({
		1 - var_14_3,
		var_14_3
	}) == 1 and var_0_1:beMiss(arg_14_0.skillID) == 1 then
		arg_14_0.isShanBi = true
	end

	arg_14_0.mp = var_0_1:mp(arg_14_0.skillID) + var_0_1:mpStep(arg_14_0.skillID) * arg_14_0.skillLv

	if arg_14_0.basicHarm == 0 then
		arg_14_0.isBaoJi, arg_14_0.harm, arg_14_0.cure, arg_14_0.xixue = false, 0, 0, 0

		if var_14_1.harmSaveSkills_[arg_14_0.skillID] and var_14_1.harmSaveSkills_[arg_14_0.skillID] > 0 then
			arg_14_0.harm = arg_14_0.harm + var_14_1.harmSaveSkills_[arg_14_0.skillID]
			var_14_1.harmSaveSkills_[arg_14_0.skillID] = 0
		end

		if var_14_1.xixueSaveSkills_[arg_14_0.skillID] and var_14_1.xixueSaveSkills_[arg_14_0.skillID] > 0 then
			arg_14_0.xixue = arg_14_0.xixue + var_14_1.xixueSaveSkills_[arg_14_0.skillID]
			var_14_1.xixueSaveSkills_[arg_14_0.skillID] = 0
		end

		return arg_14_0.isShanBi, arg_14_0.isBaoJi, arg_14_0.harm, arg_14_0.cure, arg_14_0.xixue, arg_14_0.mp
	end

	if arg_14_0.attackType == xyd.AttackType.AD then
		arg_14_0.harm = arg_14_0.basicHarm * arg_14_0.basicHarm / (arg_14_0.basicHarm + 8 * math.max(var_14_0:getHuJia() - var_14_1:getDHuJia(), 0))

		local var_14_4 = var_14_1:getADBaoJi() / (var_0_5.adBaojiParam1 + var_14_1:getADBaoJi() + var_0_5.adBaojiLevelParam1 * var_14_0:getLevel()) - var_14_0:getHuJia() / (var_0_5.hujiaBaojiParam1 + var_14_0:getHuJia() + var_0_5.hujiaBaojiParam2 * var_14_0:getLevel()) + var_0_5.hujiaBaojiParam3
		local var_14_5 = math.max(0, var_14_4)

		if xyd.weightedChoise({
			var_14_5,
			1 - var_14_5
		}) == 1 then
			arg_14_0.isBaoJi = true
		end

		arg_14_0.harm = arg_14_0.harm * var_14_0:getADJianShang()
	elseif arg_14_0.attackType == xyd.AttackType.AP then
		arg_14_0.harm = arg_14_0.basicHarm * arg_14_0.basicHarm / (arg_14_0.basicHarm + 12 * math.max(var_14_0:getMoKang() - var_14_1:getDMoKang(), 0))

		if var_0_1:ignoreDefence(arg_14_0.skillID) then
			arg_14_0.harm = arg_14_0.basicHarm
		end

		local var_14_6 = var_14_1:getAPBaoJi() / (var_0_5.apBaojiParam1 + var_14_1:getAPBaoJi() + var_0_5.apBaojiLevelParam1 * var_14_0:getLevel()) - var_14_0:getMoKang() / (var_0_5.mokangBaojiParam1 + var_14_0:getMoKang() + var_0_5.mokangBaojiParam2 * var_14_0:getLevel()) + var_0_5.mokangBaojiParam3
		local var_14_7 = math.max(0, var_14_6)

		if xyd.weightedChoise({
			var_14_7,
			1 - var_14_7
		}) == 1 then
			arg_14_0.isBaoJi = true
		end

		arg_14_0.harm = arg_14_0.harm * var_14_0:getAPJianShang()
	elseif arg_14_0.attackType == xyd.AttackType.CURE then
		arg_14_0.isShanBi = false
		arg_14_0.harm = arg_14_0.basicHarm
	end

	if arg_14_0.isBaoJi and arg_14_0.attackType == xyd.AttackType.AD then
		arg_14_0.harm = arg_14_0.harm * var_14_1:getADBaoJiHarm() / xyd.DECIMAL_BASE
	elseif arg_14_0.isBaoJi and arg_14_0.attackType == xyd.AttackType.AP then
		arg_14_0.harm = arg_14_0.harm * var_14_1:getAPBaoJiHarm() / xyd.DECIMAL_BASE
	elseif arg_14_0.isBaoJi and arg_14_0.attackType == xyd.AttackType.CURE then
		arg_14_0.harm = arg_14_0.harm * var_14_1:getAPBaoJiHarm() / xyd.DECIMAL_BASE
	end

	arg_14_0.cure = arg_14_0.harm * var_14_1:getCureRate() * (1 + var_14_1:getAddCure())

	if arg_14_0.attackType == xyd.AttackType.CURE then
		arg_14_0.harm = 0
	end

	if arg_14_0.skillID == xyd.AXE_SKILL and arg_14_0.target:getHp() / arg_14_0.target:getHpLimit() <= xyd.tables.battleConfig.axeSkillHpLimit then
		arg_14_0.harm = arg_14_0.harm * xyd.tables.battleConfig.axeSkillHarmRate
	end

	arg_14_0.harm = math.pow(var_0_1:collisionWeaken(arg_14_0.skillID), var_0_1:collisionNum(arg_14_0.skillID) - arg_14_0.collisionNum) * arg_14_0.harm

	local var_14_8 = arg_14_0.fighter:getXixue() / (100 + arg_14_0.target.lv + arg_14_0.fighter:getXixue())

	if arg_14_0.attackType == xyd.AttackType.AP then
		var_14_8 = 1 + var_14_1:getAddCure()
	end

	arg_14_0.xixue = var_14_8 * math.min(arg_14_0.target:getHp(), arg_14_0.harm) * var_0_1:xixue(arg_14_0.skillID) / xyd.DECIMAL_BASE

	if arg_14_0.harm > 0 then
		arg_14_0.harm = math.max(arg_14_0.harm, 1)
	end

	if var_0_1:harmSaveSkill(arg_14_0.skillID) > 0 and arg_14_0.harm > 0 then
		var_14_1:addHarmSaveSkills(var_0_1:harmSaveSkill(arg_14_0.skillID), arg_14_0.harm)

		arg_14_0.harm = 0
	end

	if var_0_1:xixueSaveSkill(arg_14_0.skillID) > 0 and arg_14_0.xixue > 0 then
		var_14_1:addXixueSaveSkills(var_0_1:xixueSaveSkill(arg_14_0.skillID), arg_14_0.xixue)

		arg_14_0.xixue = 0
	end

	if var_14_1.harmSaveSkills_[arg_14_0.skillID] and var_14_1.harmSaveSkills_[arg_14_0.skillID] > 0 then
		arg_14_0.harm = arg_14_0.harm + var_14_1.harmSaveSkills_[arg_14_0.skillID]
		var_14_1.harmSaveSkills_[arg_14_0.skillID] = 0
	end

	if var_14_1.xixueSaveSkills_[arg_14_0.skillID] and var_14_1.xixueSaveSkills_[arg_14_0.skillID] > 0 then
		arg_14_0.xixue = arg_14_0.xixue + var_14_1.xixueSaveSkills_[arg_14_0.skillID]
		var_14_1.xixueSaveSkills_[arg_14_0.skillID] = 0
	end

	return arg_14_0.isShanBi, arg_14_0.isBaoJi, arg_14_0.harm, arg_14_0.cure, arg_14_0.xixue, arg_14_0.mp
end

function var_0_0.speedY(arg_15_0, arg_15_1)
	if arg_15_0.xDis_ == 0 or arg_15_0.arrived then
		return 0
	end

	local var_15_0 = arg_15_1 - arg_15_0.startCount

	if arg_15_0.yx == xyd.YXType.Paowuxian_Duration then
		local var_15_1 = xyd.tables.battleConfig.attackunitPaowuxianDuration / xyd.tables.battleConfig.interval

		if arg_15_0.yDis_ < 0 then
			local var_15_2 = var_0_1:y(arg_15_0.skillID)
			local var_15_3 = arg_15_0.yDis_
			local var_15_4 = (4 * math.sqrt(var_15_2 * var_15_2 - var_15_2 * var_15_3) + 4 * var_15_2 - 2 * var_15_3) / (-1 * var_15_1 * var_15_1)

			return math.sqrt(-2 * var_15_4 * var_15_2) + var_15_4 * var_15_0
		else
			local var_15_5 = var_0_1:y(arg_15_0.skillID)
			local var_15_6 = arg_15_0.yDis_
			local var_15_7 = -2 * (2 * math.sqrt(var_15_5 * var_15_5 - var_15_5 * var_15_6) - var_15_6 + 2 * var_15_5) / (var_15_1 * var_15_1)

			return math.sqrt(-2 * var_15_7 * var_15_5) + var_15_7 * var_15_0
		end
	end

	if arg_15_0.speed == 0 then
		return 0
	end

	local var_15_8 = math.abs(arg_15_0.xDis_ / arg_15_0.speed)

	if arg_15_0.yx == xyd.YXType.Yunsu then
		local var_15_9 = arg_15_0:getDesPos("x") - arg_15_0:getX()

		var_15_9 = var_15_9 == 0 and 1 or var_15_9

		return (arg_15_0:getDesPos("y") - arg_15_0:getY()) / math.abs(var_15_9) * arg_15_0:speedX(arg_15_1)
	elseif arg_15_0.yx == xyd.YXType.Paowuxian then
		if arg_15_0.yDis_ < 0 then
			local var_15_10 = var_0_1:y(arg_15_0.skillID)
			local var_15_11 = arg_15_0.yDis_
			local var_15_12 = (4 * math.sqrt(var_15_10 * var_15_10 - var_15_10 * var_15_11) + 4 * var_15_10 - 2 * var_15_11) / (-1 * var_15_8 * var_15_8)

			return math.sqrt(-2 * var_15_12 * var_15_10) + var_15_12 * var_15_0
		else
			local var_15_13 = var_0_1:y(arg_15_0.skillID)
			local var_15_14 = arg_15_0.yDis_
			local var_15_15 = -2 * (2 * math.sqrt(var_15_13 * var_15_13 - var_15_13 * var_15_14) - var_15_14 + 2 * var_15_13) / (var_15_8 * var_15_8)

			return math.sqrt(-2 * var_15_15 * var_15_13) + var_15_15 * var_15_0
		end
	end
end

function var_0_0.speedX(arg_16_0, arg_16_1)
	if arg_16_0.xDis_ == 0 or arg_16_0.arrived then
		return 0
	end

	local var_16_0 = arg_16_1 - arg_16_0.startCount

	if arg_16_0.yx ~= xyd.YXType.Yunsu then
		return arg_16_0.speed
	end

	if #arg_16_0.accelerate_ < #arg_16_0.aTime_ then
		error("skill " .. arg_16_0.skillID .. " acceleration is nil")
	elseif #arg_16_0.accelerate_ > #arg_16_0.aTime_ + 1 then
		error("skill " .. arg_16_0.skillID .. " acceleration time is nil")
	end

	local var_16_1 = 0
	local var_16_2 = clone(arg_16_0.accelerate_)

	if #arg_16_0.accelerate_ > #arg_16_0.aTime_ then
		var_16_1 = arg_16_0.accelerate_[#arg_16_0.accelerate_]

		table.remove(var_16_2)
	end

	local var_16_3 = clone(arg_16_0.speed)

	for iter_16_0 = 1, #var_16_2 do
		if var_16_0 >= arg_16_0.aTime_[iter_16_0] and iter_16_0 == 1 then
			var_16_3 = var_16_3 + arg_16_0.aTime_[1] * arg_16_0.accelerate_[1]
		elseif var_16_0 >= arg_16_0.aTime_[iter_16_0] and iter_16_0 > 1 then
			var_16_3 = var_16_3 + (arg_16_0.aTime_[iter_16_0] - arg_16_0.aTime_[iter_16_0 - 1]) * arg_16_0.accelerate_[iter_16_0]
		elseif var_16_0 < arg_16_0.aTime_[iter_16_0] then
			if iter_16_0 > 2 then
				var_16_3 = var_16_3 + (var_16_0 - arg_16_0.aTime_[iter_16_0 - 1]) * arg_16_0.accelerate_[iter_16_0]

				break
			end

			var_16_3 = var_16_3 + var_16_0 * arg_16_0.accelerate_[iter_16_0]

			break
		end
	end

	if not next(arg_16_0.aTime_) then
		var_16_3 = var_16_3 + var_16_0 * var_16_1
	elseif var_16_0 > arg_16_0.aTime_[#arg_16_0.aTime_] then
		var_16_3 = var_16_3 + (var_16_0 - arg_16_0.aTime_[#arg_16_0.aTime_]) * var_16_1
	end

	return var_16_3
end

function var_0_0.movePosition(arg_17_0, arg_17_1)
	if arg_17_0.xDis_ == 0 or arg_17_0.speed == 0 or arg_17_0.arrived or not arg_17_0.resource then
		return 0
	end

	local var_17_0

	if not arg_17_0.isResetToXY then
		if math.abs(arg_17_0:getX() - arg_17_0.desX_) <= arg_17_0:speedX(arg_17_1) then
			arg_17_0.arrived = true
			var_17_0 = {
				time = var_0_4,
				x = arg_17_0.desX_ - arg_17_0:getX(),
				y = arg_17_0.desY_ - arg_17_0:getY()
			}
		else
			var_17_0 = {
				time = var_0_4,
				x = arg_17_0:speedX(arg_17_1) * arg_17_0.xDis_ / math.abs(arg_17_0.xDis_),
				y = arg_17_0:speedY(arg_17_1)
			}
		end

		transition.moveBy(arg_17_0.resource, var_17_0)

		return
	end

	if math.abs(arg_17_0:getX() - arg_17_0:getDesPos("x")) <= arg_17_0:speedX(arg_17_1) then
		arg_17_0.arrived = true
		var_17_0 = {
			time = var_0_4,
			x = arg_17_0:getDesPos("x") - arg_17_0:getX(),
			y = arg_17_0:getDesPos("y") - arg_17_0:getY()
		}
	else
		var_17_0 = {
			time = var_0_4,
			x = arg_17_0:speedX(arg_17_1) * arg_17_0.xDis_ / math.abs(arg_17_0.xDis_),
			y = arg_17_0:speedY(arg_17_1)
		}
	end

	transition.moveBy(arg_17_0.resource, var_17_0)
end

function var_0_0.movePositionReport(arg_18_0, arg_18_1)
	if arg_18_0.xDis_ == 0 or arg_18_0.speed == 0 or arg_18_0.arrived or not arg_18_0.resource then
		return 0
	end

	if arg_18_0.moveStack_ and next(arg_18_0.moveStack_) then
		arg_18_0.moveStack_[1] = arg_18_0.moveStack_[1] or 0
		arg_18_0.moveStack_[2] = arg_18_0.moveStack_[2] or 0

		arg_18_0.resource:pos(arg_18_0:getX() + arg_18_0.moveStack_[1], arg_18_0:getY() + arg_18_0.moveStack_[2])

		arg_18_0.moveStack_ = {}
	end

	local var_18_0

	if not arg_18_0.isResetToXY then
		if math.abs(arg_18_0:getX() - arg_18_0.desX_) <= arg_18_0:speedX(arg_18_1) then
			arg_18_0.arrived = true
			var_18_0 = {
				time = var_0_4,
				x = arg_18_0.desX_ - arg_18_0:getX(),
				y = arg_18_0.desY_ - arg_18_0:getY()
			}
		else
			var_18_0 = {
				time = var_0_4,
				x = arg_18_0:speedX(arg_18_1) * arg_18_0.xDis_ / math.abs(arg_18_0.xDis_),
				y = arg_18_0:speedY(arg_18_1)
			}
		end

		arg_18_0.moveStack_ = {
			var_18_0.x,
			var_18_0.y
		}

		return
	end

	if math.abs(arg_18_0:getX() - arg_18_0:getDesPos("x")) <= arg_18_0:speedX(arg_18_1) then
		arg_18_0.arrived = true
		var_18_0 = {
			time = var_0_4,
			x = arg_18_0:getDesPos("x") - arg_18_0:getX(),
			y = arg_18_0:getDesPos("y") - arg_18_0:getY()
		}
	else
		var_18_0 = {
			time = var_0_4,
			x = arg_18_0:speedX(arg_18_1) * arg_18_0.xDis_ / math.abs(arg_18_0.xDis_),
			y = arg_18_0:speedY(arg_18_1)
		}
	end

	arg_18_0.moveStack_ = {
		var_18_0.x,
		var_18_0.y
	}
end

function var_0_0.rotate(arg_19_0, arg_19_1)
	if not arg_19_0.isRotate or arg_19_0.arrived or not arg_19_0.resource or tolua.isnull(arg_19_0.resource) then
		return
	end

	local var_19_0 = arg_19_0.resource:getRotationSkewX()
	local var_19_1 = math.atan2(arg_19_0:speedY(arg_19_1), arg_19_0:speedX(arg_19_1) * arg_19_0.xDis_ / math.abs(arg_19_0.xDis_)) / math.pi * -180

	if var_19_0 ~= var_19_1 then
		arg_19_0.resource:rotation(var_19_1)
	end
end

function var_0_0.rotateReport(arg_20_0, arg_20_1)
	if not arg_20_0.isRotate or arg_20_0.arrived or not arg_20_0.resource or tolua.isnull(arg_20_0.resource) then
		return
	end

	local var_20_0 = arg_20_0.resource:getRotationSkewX()
	local var_20_1 = math.atan2(arg_20_0:speedY(arg_20_1), arg_20_0:speedX(arg_20_1) * arg_20_0.xDis_ / math.abs(arg_20_0.xDis_)) / math.pi * -180

	if var_20_0 ~= var_20_1 then
		arg_20_0.resource:rotation(var_20_1)
	end
end

function var_0_0.getArriveCount(arg_21_0)
	if arg_21_0.speed < 1 then
		return
	end

	return math.ceil(math.abs(arg_21_0.xDis_) / arg_21_0.speed + arg_21_0.count)
end

function var_0_0.resetTarget(arg_22_0, arg_22_1)
	arg_22_0.target = arg_22_1

	table.insert(arg_22_0.targets_, arg_22_1)

	arg_22_0.recordTargets_[arg_22_1.fighterIndex] = arg_22_1

	arg_22_0:init(true)
end

function var_0_0.getDesPos(arg_23_0, arg_23_1)
	if not arg_23_0.target then
		return
	end

	local var_23_0, var_23_1 = arg_23_0.target.fighterModel:getPosition()

	if arg_23_1 == "x" then
		return var_23_0 + arg_23_0.target:getFighterModel().attackedPoint.x
	elseif arg_23_1 == "y" then
		return var_23_1 + arg_23_0.target:getFighterModel().attackedPoint.y
	else
		return var_23_0 + arg_23_0.target:getFighterModel().attackedPoint.x, var_23_1 + arg_23_0.target:getFighterModel().attackedPoint.y
	end
end

function var_0_0.getCurrentPos(arg_24_0)
	if arg_24_0.resource then
		return arg_24_0:getX(), arg_24_0:getY()
	end

	return arg_24_0:getIniPos()
end

function var_0_0.getIniPos(arg_25_0, arg_25_1)
	local var_25_0, var_25_1 = arg_25_0.fighter.fighterModel:getPosition()
	local var_25_2 = var_0_1:attackIndex(arg_25_0.skillID)
	local var_25_3 = arg_25_0.fighter:getFighterModel().attackPoints[var_25_2]

	if not var_25_3 then
		var_25_3 = arg_25_0.fighter:getFighterModel().attackPoints[1]

		print(arg_25_0.fighter.hero:getName(), arg_25_0.skillID, "attackPoint is nil " .. var_25_2)
	end

	if arg_25_1 == "x" then
		return var_25_0 + var_25_3.x
	elseif arg_25_1 == "y" then
		return var_25_1 + var_25_3.y
	else
		return var_25_0 + var_25_3.x, var_25_1 + var_25_3.y
	end
end

function var_0_0.getX(arg_26_0)
	if not arg_26_0.resource then
		return
	end

	return cc.p(arg_26_0.resource:getPosition()).x
end

function var_0_0.getY(arg_27_0)
	if not arg_27_0.resource then
		return
	end

	return cc.p(arg_27_0.resource:getPosition()).y
end

function var_0_0.isResetTarget(arg_28_0)
	return arg_28_0.isResetTarget
end

function var_0_0.getCollisionCount(arg_29_0)
	if arg_29_0.collisionNum <= 1 then
		return
	end

	return arg_29_0.startCount + #arg_29_0.targets_ * arg_29_0.collisionTimeout
end

function var_0_0.isHasAttachAttr(arg_30_0)
	return var_0_1:attachAttr(arg_30_0.skillID)
end

function var_0_0.getHitSound(arg_31_0)
	return var_0_1:hitSound(arg_31_0.skillID)
end

function var_0_0.hitMove(arg_32_0)
	return var_0_1:hitMove(arg_32_0.skillID)
end

function var_0_0.hitMoveTime(arg_33_0)
	return var_0_1:hitMoveTime(arg_33_0.skillID)
end

function var_0_0.isForceBreak(arg_34_0)
	return var_0_1:forceBreak(arg_34_0.skillID)
end

function var_0_0.isInvalidAfterDeath(arg_35_0)
	return var_0_1:isInvalidAfterDeath(arg_35_0.skillID)
end

return var_0_0
