local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xunlu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = 40011687
local var_0_7 = 40011685
local var_0_8 = 40011686
local var_0_9 = 0.8
local var_0_10 = 0
local var_0_11 = 6
local var_0_12 = 40011688
local var_0_13 = 40011689
local var_0_14 = 40011690
local var_0_15 = 40011692
local var_0_16 = 30
local var_0_17 = 60
local var_0_18 = 10000
local var_0_19 = 2000

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("harm_info")

	arg_1_0.energyAccHarms = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("harm_info")) do
		if arg_2_0.energyAccHarms[iter_2_1.target] ~= nil then
			arg_2_0.energyAccHarms[iter_2_1.target] = arg_2_0.energyAccHarms[iter_2_1.target] + iter_2_1.harm

			if arg_2_0.energyAccHarms[iter_2_1.target] > var_0_18 + var_0_19 * #arg_2_0:getBuffsByID(var_0_7) then
				iter_2_1.target:removeBuffByID(var_0_15)
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getPugongID() then
		if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and arg_3_1.target:isHasBuffByID(var_0_7) and var_0_2.weightedChoise({
			var_0_9,
			1 - var_0_9
		}) == 1 then
			if not var_0_5.timeSeed_ then
				var_0_5.timeSeed_ = 1
			end

			math.randomseed(tonumber(tostring(os.time() + var_0_5.timeSeed_):reverse():sub(1, 6)))

			local var_3_0 = math.random(tonumber(os.time()))

			var_0_5.timeSeed_ = var_3_0

			local var_3_1 = {}

			for iter_3_0, iter_3_1 in ipairs(arg_3_0.targetTeam_) do
				if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1 ~= arg_3_1.target then
					table.insert(var_3_1, iter_3_1)
				end
			end

			if #var_3_1 > 0 then
				math.randomseed(var_3_0)

				local var_3_2 = var_3_1[math.random(#var_3_1)]

				var_3_2:addBuffs({
					var_0_4.new({
						tableID = var_0_7,
						start = var_0_1.ctx.battle.count,
						level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green),
						skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
						fighter = arg_3_0,
						target = var_3_2
					}),
					var_0_4.new({
						tableID = var_0_8,
						start = var_0_1.ctx.battle.count,
						level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green),
						skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
						fighter = arg_3_0,
						target = var_3_2
					})
				})
			end
		end

		arg_3_1.target:addBuffs({
			var_0_4.new({
				tableID = var_0_7,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
				fighter = arg_3_0,
				target = arg_3_1.target
			}),
			var_0_4.new({
				tableID = var_0_8,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
				fighter = arg_3_0,
				target = arg_3_1.target
			})
		})
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local function var_3_3(arg_4_0)
			local var_4_0 = var_0_4.new({
				tableID = arg_4_0,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
				fighter = arg_3_0,
				target = arg_3_1.target
			})

			var_4_0.leftCount_ = var_0_10 + var_0_11 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
			var_4_0.extraTime_ = math.max(0, var_4_0.leftCount_ - var_4_0:getTime())

			return var_4_0
		end

		if arg_3_1.target:getTeamType() == arg_3_0:getTeamType() then
			arg_3_1.target:addBuffs({
				var_3_3(var_0_6)
			})
		else
			arg_3_1.target:addBuffs({
				var_3_3(var_0_7),
				var_3_3(var_0_8)
			})
		end
	elseif arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		local var_3_4 = #arg_3_1.target:getBuffsByID(var_0_7)

		if var_3_4 > 1 then
			local var_3_5 = var_0_4.new({
				tableID = var_0_15,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
				fighter = arg_3_0,
				target = arg_3_1.target
			})

			var_3_5.leftCount_ = var_0_16 + var_0_17 * var_3_4
			var_3_5.extraTime_ = math.max(0, var_3_5.leftCount_ - var_3_5:getTime())

			arg_3_1.target:addBuffs({
				var_3_5
			})

			arg_3_0.energyAccHarms[arg_3_1.target] = 0
		end
	end
end

function var_0_3.buffRemoveAction(arg_5_0, arg_5_1)
	if arg_5_1:getTableID() == var_0_12 then
		arg_5_1.target:addBuffs({
			var_0_4.new({
				tableID = var_0_14,
				start = var_0_1.ctx.battle.count,
				level = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
				skillID = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
				fighter = arg_5_0,
				target = arg_5_1.target
			}),
			var_0_4.new({
				tableID = var_0_13,
				start = var_0_1.ctx.battle.count,
				level = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
				skillID = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
				fighter = arg_5_0,
				target = arg_5_1.target
			})
		})
	elseif arg_5_1:getTableID() == var_0_15 then
		arg_5_0.energyAccHarms[arg_5_1.target] = nil
	end
end

function var_0_3.selectTargetByTypeD4(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = {}
	local var_6_1 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() then
			table.insert(var_6_1, iter_6_1)

			if not iter_6_1:isHasBuffByID(var_0_6) then
				table.insert(var_6_0, iter_6_1)
			end
		end
	end

	for iter_6_2, iter_6_3 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_3:isDeath() and not iter_6_3:isAffected() then
			table.insert(var_6_1, iter_6_3)

			if not iter_6_3:isHasBuffByID(var_0_7) then
				table.insert(var_6_0, iter_6_3)
			end
		end
	end

	local var_6_2 = 0

	if #var_6_0 <= 5 then
		var_6_2 = 5
	elseif #var_6_0 < 10 then
		var_6_2 = 10 - #var_6_0
	end

	while var_6_2 > 0 do
		var_6_2 = var_6_2 - 1

		table.insert(var_6_0, var_6_1[math.random(#var_6_1)])
	end

	return var_6_0
end

function var_0_3.selectTargetByTypeD3(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.targetTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and (not var_7_0 or var_7_0:getAD() < iter_7_1:getAD()) then
			var_7_0 = iter_7_1
		end
	end

	return {
		var_7_0
	}
end

return var_0_3
