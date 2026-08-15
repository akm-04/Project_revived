local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hansui", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 40010958
local var_0_6 = {
	5,
	10
}
local var_0_7 = 10000883
local var_0_8 = 10000878
local var_0_9 = 10000879
local var_0_10 = 1
local var_0_11 = 10000884
local var_0_12 = 10000885
local var_0_13 = 80010168
local var_0_14 = 10001485
local var_0_15 = 10001486
local var_0_16 = 40011529
local var_0_17 = 10001487
local var_0_18 = 40012582

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.eNianBuffTargets_ = {}
	arg_1_0.purpleInitPos_ = {}
	arg_1_0.isPurpleSkill_ = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_0_1.ctx.battle.count % 30 < 1 then
		for iter_2_0, iter_2_1 in pairs(arg_2_0.eNianBuffTargets_) do
			local var_2_0 = iter_2_1.target
			local var_2_1 = iter_2_1.count
			local var_2_2 = iter_2_1.start

			if not var_2_0:isDeath() and not var_2_0:isAffected() and var_2_1 <= (var_0_1.ctx.battle.count - var_2_2) / 30 then
				local var_2_3 = arg_2_0:createAttackUnits({
					var_2_0
				}, var_0_8)

				for iter_2_2, iter_2_3 in ipairs(var_2_3) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
					table.insert(arg_2_0.records_.special_units, iter_2_3)
				end

				iter_2_1.start = var_0_1.ctx.battle.count
				iter_2_1.count = math.random(var_0_6[1], var_0_6[2])

				if arg_2_0.skinSkillID_ == var_0_13 then
					local var_2_4 = arg_2_0:createAttackUnits({
						var_2_0
					}, var_0_14)

					for iter_2_4, iter_2_5 in ipairs(var_2_4) do
						table.insert(arg_2_0.moveAttackUnits_, iter_2_5)
						table.insert(arg_2_0.records_.special_units, iter_2_5)
					end

					if #arg_2_0:getBuffsByID(var_0_16) < 5 then
						local var_2_5 = arg_2_0:createAttackUnits({
							arg_2_0
						}, var_0_15)

						for iter_2_6, iter_2_7 in ipairs(var_2_5) do
							table.insert(arg_2_0.moveAttackUnits_, iter_2_7)
							table.insert(arg_2_0.records_.special_units, iter_2_7)
						end
					else
						local var_2_6 = arg_2_0:createAttackUnits({
							arg_2_0
						}, var_0_17)

						for iter_2_8, iter_2_9 in ipairs(var_2_6) do
							table.insert(arg_2_0.moveAttackUnits_, iter_2_9)
							table.insert(arg_2_0.records_.special_units, iter_2_9)
						end
					end
				end
			end
		end
	end
end

function var_0_3.clearENianBuff(arg_3_0, arg_3_1)
	arg_3_1:removeBuffByID(var_0_5)
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	arg_4_0.isPurpleSkill_ = false
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == var_0_7 then
		arg_5_0:clearENianBuff(arg_5_1.target)
	elseif arg_5_1.skillID == var_0_11 then
		local var_5_0, var_5_1 = arg_5_0:getPos()

		arg_5_0.purpleInitPos_ = {
			x = var_5_0,
			y = var_5_1
		}

		local var_5_2, var_5_3 = arg_5_1.target:getPos()
		local var_5_4 = arg_5_0:getFlipX() == true and 1 or -1

		arg_5_0:pos(var_5_2 + var_5_4 * 100, var_5_1)

		arg_5_0.isPurpleSkill_ = true
	elseif arg_5_1.skillID == var_0_12 then
		if arg_5_0.purpleInitPos_ and next(arg_5_0.purpleInitPos_) then
			arg_5_0:pos(arg_5_0.purpleInitPos_.x, arg_5_0.purpleInitPos_.y)

			arg_5_0.purpleInitPos_ = {}
		end

		arg_5_0.isPurpleSkill_ = false
	elseif arg_5_1.skillID == arg_5_0:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_5_1.target:isHasBuffByID(var_0_5) then
		local var_5_5 = arg_5_0:createAttackUnits({
			arg_5_1.target
		}, var_0_7)

		for iter_5_0, iter_5_1 in ipairs(var_5_5) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end
end

function var_0_3.skillIsBreakAction(arg_6_0, arg_6_1)
	var_0_3.super.skillIsBreakAction(arg_6_0, arg_6_1)

	arg_6_0.isPurpleSkill_ = false
end

function var_0_3.checkInENian(arg_7_0, arg_7_1)
	for iter_7_0, iter_7_1 in ipairs(arg_7_0.eNianBuffTargets_) do
		if iter_7_1.target == arg_7_1 then
			return iter_7_0
		end
	end
end

function var_0_3.newBuffs(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		local var_8_1 = Buff.new({
			tableID = iter_8_1,
			start = var_0_1.ctx.battle.count,
			level = arg_8_3,
			skillID = arg_8_2,
			fighter = arg_8_0,
			target = arg_8_4
		})

		table.insert(var_8_0, var_8_1)
	end

	return var_8_0
end

function var_0_3.buffAddAction(arg_9_0, arg_9_1)
	var_0_3.super.buffAddAction(arg_9_0, arg_9_1)

	local var_9_0 = arg_9_1.target

	if arg_9_1:getTableID() == var_0_5 and not arg_9_0:checkInENian(arg_9_1.target) then
		table.insert(arg_9_0.eNianBuffTargets_, {
			target = arg_9_1.target,
			start = var_0_1.ctx.battle.count,
			count = math.random(var_0_6[1], var_0_6[2])
		})

		if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
			local var_9_1 = arg_9_0:createNewBuffs({
				var_0_18
			}, arg_9_0, arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			arg_9_0:addBuffs(var_9_1)
		end
	end
end

function var_0_3.buffRemoveAction(arg_10_0, arg_10_1)
	var_0_3.super.buffRemoveAction(arg_10_0, arg_10_1)

	if arg_10_1:getTableID() == var_0_5 then
		local var_10_0 = arg_10_0:checkInENian(arg_10_1.target)

		if var_10_0 then
			table.remove(arg_10_0.eNianBuffTargets_, var_10_0)

			if arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
				local var_10_1 = arg_10_0:getBuffsByID(var_0_18)

				for iter_10_0 = #var_10_1, 1, -1 do
					local var_10_2 = var_10_1[iter_10_0]

					if var_10_0 == iter_10_0 then
						arg_10_0:removeBuffs(var_10_2)
					end
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	local var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = var_0_3.super.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)

	if var_11_2 > 0 and arg_11_1.skillID == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		if arg_11_1.target:isHasBuffByID(var_0_5) then
			var_11_2 = var_11_2 * (1 + var_0_10)
		end
	elseif arg_11_1.skillID == var_0_8 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_11_6 = arg_11_0:createAttackUnits({
			arg_11_0
		}, var_0_9)

		for iter_11_0, iter_11_1 in ipairs(var_11_6) do
			iter_11_1.change_mp = -var_11_5

			table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
			table.insert(arg_11_0.records_.special_units, iter_11_1)
		end
	elseif arg_11_1.skillID == var_0_9 and arg_11_1.change_mp then
		var_11_5 = var_11_5 + arg_11_1.change_mp
	end

	return var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5
end

function var_0_3.selectTargetByTypeD1(arg_12_0)
	local var_12_0
	local var_12_1
	local var_12_2 = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.sideTeam_) do
		if not iter_12_1:isDeath() and not iter_12_1:isAffected() then
			table.insert(var_12_2, iter_12_1)
		end
	end

	if not next(var_12_2) then
		return {}
	end

	local var_12_3 = arg_12_0:getX()

	table.sort(var_12_2, function(arg_13_0, arg_13_1)
		return math.abs(var_12_3 - arg_13_0:getX()) < math.abs(var_12_3 - arg_13_1:getX())
	end)

	for iter_12_2 = 1, #var_12_2 do
		if not var_12_2[iter_12_2]:isHasBuffByID(var_0_5) then
			var_12_0 = var_12_2[iter_12_2]

			break
		end
	end

	var_12_0 = var_12_0 or var_12_2[math.random(1, #var_12_2)]

	return {
		var_12_0
	}
end

function var_0_3.selectTargetByTypeD4(arg_14_0, arg_14_1, arg_14_2)
	local function var_14_0(arg_15_0, arg_15_1)
		local var_15_0 = {}

		table.insert(var_15_0, arg_15_0)

		for iter_15_0, iter_15_1 in ipairs(arg_14_0.sideTeam_) do
			if not iter_15_1:isDeath() and not iter_15_1:isAffected() and iter_15_1 ~= arg_15_0 and arg_15_1 >= math.abs(iter_15_1:getX() - arg_15_0:getX()) then
				table.insert(var_15_0, iter_15_1)
			end
		end

		return var_15_0
	end

	local var_14_1 = {}
	local var_14_2
	local var_14_3 = 0
	local var_14_4 = var_0_4:scope(arg_14_1) * 0.5

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.sideTeam_) do
		if not iter_14_1:isDeath() and not iter_14_1:isAffected() then
			local var_14_5 = var_14_0(iter_14_1, var_14_4)

			if var_14_3 < #var_14_5 then
				local var_14_6 = var_14_5

				var_14_2 = iter_14_1
				var_14_3 = #var_14_5
			end
		end
	end

	return {
		var_14_2
	}
end

function var_0_3.die(arg_16_0)
	if arg_16_0:isDeath() then
		arg_16_0:dieSkill()
	end

	var_0_3.super.die(arg_16_0)
end

function var_0_3.dieSkill(arg_17_0)
	local var_17_0 = false

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.selfTeam_) do
		if not iter_17_1:isDeath() or iter_17_1:canReborn() then
			var_17_0 = true

			break
		end
	end

	if not var_17_0 then
		return
	end

	local var_17_1 = {}

	for iter_17_2, iter_17_3 in ipairs(arg_17_0.sideTeam_) do
		if not iter_17_3:isDeath() and not iter_17_3:isAffected() and iter_17_3:isHasBuffByID(var_0_5) then
			table.insert(var_17_1, iter_17_3)
		elseif iter_17_3:isHasBuffByID(var_0_5) then
			arg_17_0:clearENianBuff(iter_17_3)
		end
	end

	if not next(var_17_1) then
		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_17_2 = arg_17_0:createAttackUnits(var_17_1, var_0_7)

	for iter_17_4, iter_17_5 in ipairs(var_17_2) do
		table.insert(arg_17_0.moveAttackUnits_, iter_17_5)
		table.insert(arg_17_0.records_.special_units, iter_17_5)
	end
end

function var_0_3.checkMove(arg_18_0)
	if arg_18_0.isPurpleSkill_ and not var_0_1.ctx.battle.walk2NextBattle_ then
		return false
	end

	return var_0_3.super.checkMove(arg_18_0)
end

return var_0_3
