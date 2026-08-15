local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lvmeng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("AttackUnit")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.elementEquip
local var_0_9 = 10000043
local var_0_10 = 10000044
local var_0_11 = 10000175
local var_0_12 = 10000176
local var_0_13 = 10350001
local var_0_14 = 50
local var_0_15 = 40010268
local var_0_16 = 0.6
local var_0_17 = 0.6
local var_0_18 = 0.02
local var_0_19 = 0.3
local var_0_20 = 0.3
local var_0_21 = 20001432
local var_0_22 = 200

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("unit_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.awakeSecondReady_ = false
	arg_2_0.extraSkillJudge = false
	arg_2_0.extraSkillLevel = 0
	arg_2_0.skinADJianshang = var_0_19
	arg_2_0.skinAPJianshang = var_0_20
end

function var_0_3.selectTargetByTypeB3(arg_3_0, arg_3_1)
	if not var_0_5.timeSeed_ then
		var_0_5.timeSeed_ = 1
	end

	math.randomseed(tonumber(tostring(os.time() + var_0_5.timeSeed_):reverse():sub(1, 6)))

	local var_3_0 = math.random(tonumber(os.time()))

	var_0_5.timeSeed_ = var_3_0

	local var_3_1 = var_0_5.B2(arg_3_0, arg_3_1)

	if not var_3_1 or next(var_3_1) == nil then
		return {}
	end

	math.randomseed(var_3_0)

	local var_3_2 = {}
	local var_3_3 = math.random(#var_3_1)

	var_3_1[var_3_3].type = "normal"

	table.insert(var_3_2, var_3_1[var_3_3])
	table.remove(var_3_1, var_3_3)

	if #var_3_1 > 0 then
		local var_3_4 = math.random(#var_3_1)

		var_3_1[var_3_4].type = "awake"

		table.insert(var_3_2, var_3_1[var_3_4])
	end

	return var_3_2
end

function var_0_3.createAttackUnits(arg_4_0, arg_4_1, arg_4_2)
	local function var_4_0(arg_5_0)
		local var_5_0 = {
			skillID = arg_4_2,
			fighter = arg_4_0,
			target = arg_5_0,
			count = var_0_0.clone(var_0_1.ctx.battle.count)
		}

		return var_0_4.new(var_5_0)
	end

	if arg_4_1 == nil or next(arg_4_1) == nil then
		return {}
	end

	local var_4_1 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		if iter_4_1.type and iter_4_1.type == "awake" then
			if arg_4_2 == var_0_9 then
				arg_4_2 = var_0_11
			elseif arg_4_2 == var_0_10 then
				arg_4_2 = var_0_12
			end
		end

		local var_4_2 = var_4_0(iter_4_1)

		table.insert(arg_4_0.records_.attackunit, var_4_2)
		table.insert(var_4_1, var_4_2)

		var_4_2.recordIndex_ = #arg_4_0.records_.attackunit
	end

	return var_4_1
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_6_1.rootID_ == arg_6_0:getEnergySkillID() then
		arg_6_0.awakeSecondReady_ = true
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_7_0.awakeSecondReady_ and arg_7_1.skillID == arg_7_0:getEnergySkillID() then
		arg_7_0.awakeSecondReady_ = false

		local var_7_0 = {}

		for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
			if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
				table.insert(var_7_0, iter_7_1)
			end
		end

		local var_7_1 = arg_7_0:createAttackUnits(var_7_0, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		for iter_7_2, iter_7_3 in ipairs(var_7_1) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
			table.insert(arg_7_0.records_.special_units, iter_7_3)
		end
	end

	if arg_7_1.skillID == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_7_0.extraSkillLevel > 0 then
		local var_7_2 = var_0_6.new({
			tableID = var_0_15,
			start = var_0_1.ctx.battle.count,
			level = arg_7_0.extraSkillLevel,
			skillID = arg_7_1.skillID,
			fighter = arg_7_0,
			target = arg_7_1.target
		})

		var_7_2:setIsHit(true)
		var_7_2:setDirection(arg_7_0:getFighterModel():getFlipX())
		arg_7_1.target:addBuffs({
			var_7_2
		})
	end

	if arg_7_0.isSkinSkillOn_ and arg_7_1.target == arg_7_0 then
		local var_7_3 = var_0_7:type(arg_7_1.skillID)

		if var_7_3 == var_0_2.AttackType.AP and arg_7_0.skinAPJianshang < var_0_17 then
			arg_7_0.skinAPJianshang = arg_7_0.skinAPJianshang + var_0_18
			arg_7_0.skinADJianshang = arg_7_0.skinADJianshang - var_0_18
		elseif var_7_3 == var_0_2.AttackType.AD and arg_7_0.skinADJianshang < var_0_16 then
			arg_7_0.skinAPJianshang = arg_7_0.skinAPJianshang - var_0_18
			arg_7_0.skinADJianshang = arg_7_0.skinADJianshang + var_0_18
		end
	end
end

function var_0_3.updateUnitDataByTarget(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	if arg_8_0.isSkinSkillOn_ and arg_8_4 > 0 and arg_8_0.skinAPJianshang ~= 0 then
		local var_8_0 = var_0_7:type(arg_8_1.skillID)

		if var_8_0 == var_0_2.AttackType.AP then
			arg_8_4 = arg_8_4 * (1 - arg_8_0.skinAPJianshang)
		elseif var_8_0 == var_0_2.AttackType.AD then
			arg_8_4 = arg_8_4 * (1 - arg_8_0.skinADJianshang)
		end
	end

	return var_0_3.super.updateUnitDataByTarget(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
end

function var_0_3.toDoPerFrames(arg_9_0)
	if arg_9_0:isDeath() then
		return
	end

	if arg_9_0.isSkinSkillOn_ then
		for iter_9_0, iter_9_1 in ipairs(arg_9_0:getInfoByKey("unit_info")) do
			if iter_9_1.target == arg_9_0 then
				local var_9_0 = var_0_7:type(iter_9_1.skillID)

				if var_9_0 == var_0_2.AttackType.AP and arg_9_0.skinAPJianshang < var_0_17 then
					arg_9_0.skinAPJianshang = arg_9_0.skinAPJianshang + var_0_18
					arg_9_0.skinADJianshang = arg_9_0.skinADJianshang - var_0_18
				elseif var_9_0 == var_0_2.AttackType.AD and arg_9_0.skinADJianshang < var_0_16 then
					arg_9_0.skinAPJianshang = arg_9_0.skinAPJianshang - var_0_18
					arg_9_0.skinADJianshang = arg_9_0.skinADJianshang + var_0_18
				end
			end
		end
	end

	if not arg_9_0.playGuide_ and not arg_9_0.extraSkillJudge then
		arg_9_0.extraSkillJudge = true
		arg_9_0.extraSkillLevel = arg_9_0.hero_:skillBook()[tostring(var_0_13)] or 0
	end
end

function var_0_3.getTargets(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {}
	local var_10_1 = var_0_7:selectType(arg_10_1)

	if arg_10_0:getForceTarget() and not arg_10_0:getForceTarget():isDeath() then
		if var_10_1 == "C11" then
			local var_10_2 = arg_10_0:getForceTarget()

			if (arg_10_2.iniX_ < var_10_2:getX() and var_10_2:getX() <= arg_10_2:getX() or arg_10_2.iniX_ > var_10_2:getX() and var_10_2:getX() >= arg_10_2:getX()) and not arg_10_2.targets[var_10_2.fighterIndex] then
				arg_10_2.targets[var_10_2.fighterIndex] = var_10_2

				return {
					var_10_2
				}
			end

			return {}
		end

		return {
			arg_10_0:getForceTarget()
		}
	end

	if arg_10_0["selectTargetByType" .. var_10_1] then
		var_10_0 = arg_10_0["selectTargetByType" .. var_10_1](arg_10_0, arg_10_1, arg_10_2)
	elseif arg_10_1 == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_10_0.extraSkillLevel > 0 then
		var_10_0 = arg_10_0:selectTargetByTypeD1(arg_10_1, arg_10_2)
	else
		var_10_0 = var_0_5[var_10_1](arg_10_0, arg_10_1, arg_10_2)
	end

	return var_10_0
end

function var_0_3.selectTargetByTypeD1(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = {}
	local var_11_1 = var_0_7:scope(arg_11_1) + var_0_14
	local var_11_2, var_11_3 = arg_11_0:getPos()

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.targetTeam_) do
		local var_11_4, var_11_5 = iter_11_1:getPos()

		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and var_11_1 >= math.abs(var_11_4 - var_11_2) then
			table.insert(var_11_0, iter_11_1)
		end
	end

	return var_11_0
end

function var_0_3.addBuffBySpecialHero(arg_12_0, arg_12_1)
	var_0_3.super.addBuffBySpecialHero(arg_12_0, arg_12_1)

	if arg_12_0:hasElementEquipByID(var_0_21) then
		for iter_12_0, iter_12_1 in ipairs(arg_12_1) do
			if iter_12_1:Ychange() > 0 and iter_12_1.target:getTeamType() ~= arg_12_0:getTeamType() then
				local var_12_0 = var_0_21
				local var_12_1 = var_0_8:battleAttr(var_12_0, arg_12_0:getElementEquipLevelByID(var_12_0))
				local var_12_2 = arg_12_0.hero_:getElementEquipActiveRate(var_12_0)

				arg_12_0:resetHpLimit(arg_12_0:getHpLimit() + var_12_1 * var_12_2)
				arg_12_0:updateEnergyBy(var_0_22)
			end
		end
	end
end

return var_0_3
