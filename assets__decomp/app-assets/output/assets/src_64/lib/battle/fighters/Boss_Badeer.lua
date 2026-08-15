local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Badeer", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 40011696
local var_0_8 = 40011697
local var_0_9 = 40011698
local var_0_10 = 40011699
local var_0_11 = 40011700
local var_0_12 = 40011701
local var_0_13 = {
	[var_0_7] = {},
	[var_0_8] = {},
	[var_0_9] = {}
}

var_0_13[var_0_7][var_0_8] = var_0_10
var_0_13[var_0_8][var_0_7] = var_0_10
var_0_13[var_0_8][var_0_9] = var_0_11
var_0_13[var_0_9][var_0_8] = var_0_11
var_0_13[var_0_9][var_0_7] = var_0_12
var_0_13[var_0_7][var_0_9] = var_0_12

local var_0_14 = 30
local var_0_15 = 60
local var_0_16 = 60
local var_0_17 = 20
local var_0_18 = 0
local var_0_19 = 0.006
local var_0_20 = 10001590
local var_0_21 = 10001591
local var_0_22 = 10001592
local var_0_23 = 10001593
local var_0_24 = 40011695
local var_0_25 = -110
local var_0_26 = 10001595
local var_0_27 = 10001596
local var_0_28 = 10002443
local var_0_29 = 10002444
local var_0_30 = 0.2
local var_0_31 = 10002431
local var_0_32 = 40012640
local var_0_33 = 10002447
local var_0_34 = 450

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
end

function var_0_3.isSuper(arg_2_0)
	return true
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.hasApplyBossSkill = false
	arg_3_0.lightBuffCount = {}
	arg_3_0.darkBuffCount = {}
	arg_3_0.chaosBuffCount = {}
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1.target

	if arg_4_1.skillID == arg_4_0:getPugongID() and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_1 = arg_4_0:createAttackUnits({
			var_4_0
		}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		for iter_4_0, iter_4_1 in ipairs(var_4_1) do
			local var_4_2 = (var_0_18 + arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) * var_0_19) * arg_4_0:getAP()

			iter_4_1:setExtraHarm(var_4_2)
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end

	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == var_0_26 then
		local var_4_3 = var_4_0:getBuffByID(var_0_24)

		if var_4_3 and arg_4_0.purpleCenterX then
			var_4_3.resetXchange_ = (arg_4_0.purpleCenterX - var_4_0:getX()) * (arg_4_0:getFlipX() and -1 or 1)
			var_4_3.resetYchange_ = arg_4_0.purpleCenterY - var_4_0:getY()
			var_4_0.buffMovePath_ = var_4_3:getPath()
		end
	end

	if arg_4_1.skillID == arg_4_0:getEnergySkillID() then
		arg_4_0:createSkillByID(var_0_28, arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), var_0_6:attackIndex(var_0_28))

		arg_4_0.energyCount = 0
	end

	if arg_4_1.skillID == var_0_28 and arg_4_0.energyCount and arg_4_0.energyCount > 90 then
		arg_4_0.energyCount = nil

		local var_4_4 = var_0_5.B2(arg_4_0)
		local var_4_5 = {
			0,
			0,
			0
		}

		for iter_4_2, iter_4_3 in ipairs(var_4_4) do
			for iter_4_4, iter_4_5 in ipairs(iter_4_3:getBuffs()) do
				local var_4_6 = true

				if iter_4_5:getTableID() == var_0_7 then
					var_4_5[1] = var_4_5[1] + 1
				elseif iter_4_5:getTableID() == var_0_8 then
					var_4_5[2] = var_4_5[2] + 1
				elseif iter_4_5:getTableID() == var_0_9 then
					var_4_5[3] = var_4_5[3] + 1
				elseif iter_4_5:getTableID() == var_0_10 then
					var_4_5[1] = var_4_5[1] + 1
					var_4_5[2] = var_4_5[2] + 1
				elseif iter_4_5:getTableID() == var_0_11 then
					var_4_5[2] = var_4_5[2] + 1
					var_4_5[3] = var_4_5[3] + 1
				elseif iter_4_5:getTableID() == var_0_12 then
					var_4_5[3] = var_4_5[3] + 1
					var_4_5[1] = var_4_5[1] + 1
				else
					var_4_6 = false
				end

				if var_4_6 then
					iter_4_3:removeBuffs(iter_4_5)
				end
			end
		end

		for iter_4_6 = 1, math.min(var_4_5[1], var_4_5[2], var_4_5[3]) do
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_4_7 = arg_4_0:createAttackUnits(var_4_4, var_0_29)

				for iter_4_7, iter_4_8 in ipairs(var_4_7) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_8)
					table.insert(arg_4_0.records_.special_units, iter_4_8)
				end
			end
		end
	end
end

function var_0_3.forceDie(arg_5_0)
	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		for iter_5_2, iter_5_3 in ipairs(iter_5_1:getBuffs()) do
			if iter_5_3:getTableID() == var_0_7 or iter_5_3:getTableID() == var_0_8 or iter_5_3:getTableID() == var_0_9 or iter_5_3:getTableID() == var_0_10 or iter_5_3:getTableID() == var_0_11 or iter_5_3:getTableID() == var_0_12 then
				iter_5_1:removeBuffs(iter_5_3)
			end
		end
	end

	var_0_3.super.forceDie(arg_5_0)
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0.energyCount then
		arg_6_0.energyCount = arg_6_0.energyCount + 1

		if arg_6_0.energyCount == 4 or arg_6_0.energyCount == 10 or arg_6_0.energyCount == 18 or arg_6_0.energyCount == 24 or arg_6_0.energyCount == 34 or arg_6_0.energyCount == 45 or arg_6_0.energyCount == 52 or arg_6_0.energyCount == 61 or arg_6_0.energyCount == 73 or arg_6_0.energyCount == 84 then
			local var_6_0 = var_0_5.B2(arg_6_0, var_0_28)

			if var_0_1.ctx.battle.unitBottomLayer.getContentSize then
				local var_6_1 = var_0_1.ctx.battle.unitBottomLayer:getContentSize()

				if type(var_6_1) == "table" and var_6_1.width and var_6_1.height then
					arg_6_0.energyEffect = var_0_1.ctx.battle.getSpine(var_0_28, "area", 1)

					arg_6_0.energyEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
					arg_6_0.energyEffect:pos(var_6_1.width / 2, var_6_1.height / 2)
					arg_6_0.energyEffect:setScale(0.6 / var_0_1.ctx.battle.unitBottomLayer:getScale())
					arg_6_0.energyEffect:playOnce()
				end
			end

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_6_2 = arg_6_0:createAttackUnits(var_6_0, var_0_28)

				for iter_6_0, iter_6_1 in ipairs(var_6_2) do
					table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
					table.insert(arg_6_0.records_.special_units, iter_6_1)
				end
			end
		end
	end
end

function var_0_3.updateUnitInfoBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0 = var_0_1.ctx.battle.count
	local var_7_1 = arg_7_1.target:getBuffByID(var_0_7) or arg_7_1.target:getBuffByID(var_0_10) or arg_7_1.target:getBuffByID(var_0_12)
	local var_7_2 = arg_7_1.target:getBuffByID(var_0_8) or arg_7_1.target:getBuffByID(var_0_11) or arg_7_1.target:getBuffByID(var_0_10)
	local var_7_3 = arg_7_1.target:getBuffByID(var_0_9) or arg_7_1.target:getBuffByID(var_0_12) or arg_7_1.target:getBuffByID(var_0_11)

	if var_7_1 and var_7_1.fighter == arg_7_0 and arg_7_4 > 0 and var_7_0 > (arg_7_0.lightBuffCount[arg_7_1.fighter] or 0) + var_0_14 then
		arg_7_1.fighter:updateEnergyBy(var_0_17)

		arg_7_0.lightBuffCount[arg_7_1.fighter] = var_7_0
	end

	if var_7_2 and var_7_2.fighter == arg_7_0 and arg_7_4 > 0 and var_7_0 > (arg_7_0.darkBuffCount[arg_7_1.target] or 0) + var_0_15 then
		arg_7_0.darkBuffCount[arg_7_1.target] = var_7_0

		local var_7_4 = math.random(tonumber(os.time()))

		math.randomseed(var_7_4)

		local var_7_5 = {}

		for iter_7_0, iter_7_1 in ipairs(arg_7_1.target.selfTeam_) do
			if not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1 ~= arg_7_1.target then
				table.insert(var_7_5, iter_7_1)
			end
		end

		if next(var_7_5) then
			local var_7_6 = var_7_5[math.random(#var_7_5)]
			local var_7_7 = {
				{
					var_0_21,
					{
						var_0_8,
						var_0_11,
						var_0_10
					}
				},
				var_7_1 and {
					var_0_20,
					{
						var_0_7,
						var_0_10,
						var_0_12
					}
				} or var_7_3 and {
					var_0_22,
					{
						var_0_9,
						var_0_12,
						var_0_11
					}
				}
			}
			local var_7_8 = var_7_7[math.random(#var_7_7)]
			local var_7_9 = var_7_8[1]
			local var_7_10 = var_7_8[2]

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_7_11 = arg_7_0:createAttackUnits({
					var_7_6
				}, var_7_9)

				for iter_7_2, iter_7_3 in ipairs(var_7_11) do
					table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
					table.insert(arg_7_0.records_.special_units, iter_7_3)
				end

				for iter_7_4, iter_7_5 in ipairs(var_7_6:getBuffs()) do
					if iter_7_5:getTableID() == var_7_10[1] or iter_7_5:getTableID() == var_7_10[2] or iter_7_5:getTableID() == var_7_10[3] then
						local var_7_12 = arg_7_0:createAttackUnits({
							var_7_6
						}, var_0_23)

						for iter_7_6, iter_7_7 in ipairs(var_7_12) do
							table.insert(arg_7_0.moveAttackUnits_, iter_7_7)
							table.insert(arg_7_0.records_.special_units, iter_7_7)
						end
					end
				end
			end
		end
	end

	if var_7_3 and var_7_3.fighter == arg_7_0 and arg_7_4 > 0 and var_7_0 > (arg_7_0.chaosBuffCount[arg_7_1.target] or 0) + var_0_16 then
		arg_7_0.chaosBuffCount[arg_7_1.target] = var_7_0

		arg_7_1.target:updateEnergyBy(var_0_25)

		local var_7_13 = {}
		local var_7_14 = var_0_6:scope(var_0_27) / 2

		for iter_7_8, iter_7_9 in ipairs(arg_7_1.target.selfTeam_) do
			if not iter_7_9:isDeath() and not iter_7_9:isAffected() and var_7_14 > math.abs(iter_7_9:getX() - arg_7_1.target:getX()) then
				table.insert(var_7_13, iter_7_9)
			end
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_15 = arg_7_0:createAttackUnits(var_7_13, var_0_27)

			for iter_7_10, iter_7_11 in ipairs(var_7_15) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_11)
				table.insert(arg_7_0.records_.special_units, iter_7_11)
			end
		end
	end

	return var_0_3.super.updateUnitInfoBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	if arg_8_1.target.BadeerLastMarkBuffID and var_0_13[arg_8_1.target.BadeerLastMarkBuffID] then
		local var_8_0 = var_0_13[arg_8_1.target.BadeerLastMarkBuffID][arg_8_1:getTableID()]

		if var_8_0 then
			arg_8_1.leftCount_ = 1

			for iter_8_0, iter_8_1 in ipairs(arg_8_1.target:getBuffs()) do
				if iter_8_1:getTableID() == var_0_7 or iter_8_1:getTableID() == var_0_8 or iter_8_1:getTableID() == var_0_9 or iter_8_1:getTableID() == var_0_10 or iter_8_1:getTableID() == var_0_11 or iter_8_1:getTableID() == var_0_12 then
					iter_8_1.leftCount_ = 1
				end
			end

			arg_8_1.target:addBuffs({
				var_0_4.new({
					tableID = var_8_0,
					start = var_0_1.ctx.battle.count,
					level = arg_8_0:getLevel(),
					skillID = arg_8_0:getLevel(),
					fighter = arg_8_0,
					target = arg_8_1.target
				})
			})
		end
	end

	if var_0_13[arg_8_1:getTableID()] then
		arg_8_1.target.BadeerLastMarkBuffID = arg_8_1:getTableID()
	end
end

function var_0_3.selectTargetByTypeC29(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.targetTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and (arg_9_0:getFlipX() and iter_9_1:getX() < arg_9_0:getX() or iter_9_1:getX() > arg_9_0:getX()) then
			table.insert(var_9_0, iter_9_1)
		end
	end

	return var_9_0
end

function var_0_3.selectTargetByTypeC30(arg_10_0, arg_10_1, arg_10_2)
	local function var_10_0(arg_11_0, arg_11_1)
		local var_11_0, var_11_1 = var_0_5.getTeam(arg_11_0)
		local var_11_2 = {}

		table.insert(var_11_2, arg_11_0)

		for iter_11_0, iter_11_1 in ipairs(var_11_0) do
			if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1 ~= arg_11_0 and arg_11_1 >= math.abs(iter_11_1:getX() - arg_11_0:getX()) then
				table.insert(var_11_2, iter_11_1)
			end
		end

		return var_11_2
	end

	local var_10_1 = {}
	local var_10_2 = 0
	local var_10_3 = var_0_6:scope(arg_10_1) * 0.5
	local var_10_4, var_10_5 = var_0_5.getTeam(arg_10_0)

	arg_10_0.purpleCenterX = nil
	arg_10_0.purpleCenterY = nil

	for iter_10_0, iter_10_1 in ipairs(var_10_5) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() then
			local var_10_6 = var_10_0(iter_10_1, var_10_3)

			if var_10_2 < #var_10_6 then
				arg_10_0.purpleCenterX = iter_10_1:getX()
				arg_10_0.purpleCenterY = iter_10_1:getY()
				var_10_1 = var_10_6
				var_10_2 = #var_10_6
			end
		end
	end

	return var_10_1
end

function var_0_3.getHuJia(arg_12_0)
	local var_12_0 = math.floor(var_0_1.ctx.battle.count / var_0_34)
	local var_12_1 = 1

	if var_12_0 > 0 then
		for iter_12_0 = 1, var_12_0 do
			var_12_1 = var_12_1 * 0.7
		end
	end

	return arg_12_0:getAttrByType(var_0_2.AttributeType.HUJIA) * var_12_1
end

function var_0_3.getMoKang(arg_13_0)
	local var_13_0 = math.floor(var_0_1.ctx.battle.count / var_0_34)
	local var_13_1 = 1

	if var_13_0 > 0 then
		for iter_13_0 = 1, var_13_0 do
			var_13_1 = var_13_1 * 0.7
		end
	end

	return arg_13_0:getAttrByType(var_0_2.AttributeType.MOKANG) * var_13_1
end

function var_0_3.updateUnitDataByTarget(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)
	arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7 = var_0_3.super.updateUnitDataByTarget(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)

	if arg_14_0:isHasBuffByID(var_0_32) and arg_14_4 > 0 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_14_0 = arg_14_0:createAttackUnits({
				arg_14_0
			}, var_0_33)

			for iter_14_0, iter_14_1 in ipairs(var_14_0) do
				iter_14_1.extraCure = arg_14_4

				table.insert(arg_14_0.moveAttackUnits_, iter_14_1)
				table.insert(arg_14_0.records_.special_units, iter_14_1)
			end
		end

		arg_14_4 = 0
	end

	return arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7
end

function var_0_3.updateUnitDataByFighter(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7)
	arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7 = var_0_3.super.updateUnitDataByFighter(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7)

	if arg_15_1.skillID == var_0_33 and arg_15_1.extraCure then
		arg_15_5 = arg_15_5 + arg_15_1.extraCure
	end

	return arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7
end

function var_0_3.applyHurtFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5)
	if arg_16_2 > 0 and not arg_16_0.hasApplyBossSkill then
		local var_16_0 = math.max(0, arg_16_0:getHp() - arg_16_2)
		local var_16_1 = arg_16_0:getHpLimit() * var_0_30

		if var_16_0 < var_16_1 then
			arg_16_2 = arg_16_0:getHp() - var_16_1

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_16_2 = arg_16_0:createAttackUnits({
					arg_16_0
				}, var_0_31)

				for iter_16_0, iter_16_1 in ipairs(var_16_2) do
					table.insert(arg_16_0.moveAttackUnits_, iter_16_1)
					table.insert(arg_16_0.records_.special_units, iter_16_1)
				end
			end

			arg_16_0.hasApplyBossSkill = true
		end
	end

	return var_0_3.super.applyHurtFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5)
end

function var_0_3.updateBuffHarm(arg_17_0, arg_17_1, arg_17_2, arg_17_3, arg_17_4)
	if arg_17_0:isHasBuffByID(var_0_32) and arg_17_2 > 0 then
		arg_17_3 = arg_17_3 + arg_17_2
		arg_17_2 = 0
	elseif arg_17_2 > 0 and not arg_17_0.hasApplyBossSkill then
		local var_17_0 = math.max(0, arg_17_0:getHp() - arg_17_2)
		local var_17_1 = arg_17_0:getHpLimit() * var_0_30

		if var_17_0 < var_17_1 then
			arg_17_2 = arg_17_0:getHp() - var_17_1

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_17_2 = arg_17_0:createAttackUnits({
					arg_17_0
				}, var_0_31)

				for iter_17_0, iter_17_1 in ipairs(var_17_2) do
					table.insert(arg_17_0.moveAttackUnits_, iter_17_1)
					table.insert(arg_17_0.records_.special_units, iter_17_1)
				end
			end

			arg_17_0.hasApplyBossSkill = true
		end
	end

	return arg_17_2, arg_17_3, arg_17_4
end

return var_0_3
