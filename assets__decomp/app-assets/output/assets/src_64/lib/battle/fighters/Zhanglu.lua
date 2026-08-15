local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhanglu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.battleConfig
local var_0_9 = var_0_2.tables.skill
local var_0_10 = var_0_2.tables.hero
local var_0_11 = var_0_2.tables.model
local var_0_12 = 0.5
local var_0_13 = 40011194
local var_0_14 = 210
local var_0_15 = 40011195
local var_0_16 = 30
local var_0_17 = 0.2
local var_0_18 = 0.5
local var_0_19 = 40011193
local var_0_20 = 100
local var_0_21 = 40011197
local var_0_22 = 40011196
local var_0_23 = 240
local var_0_24 = 9
local var_0_25 = 90

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("move_info")
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.blueShieldCount = 0
	arg_2_0.purpleSkillCount = {}
	arg_2_0.extraFearTime = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
		if iter_3_1.target:getTeamType() ~= arg_3_0:getTeamType() and iter_3_1:isFear() then
			local var_3_0 = var_0_7.new({
				tableID = var_0_19,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
				fighter = arg_3_0,
				target = iter_3_1.target
			})

			var_3_0:setExtraTime(iter_3_1.leftCount_)
			iter_3_1.target:addBuffs({
				var_3_0
			})
		end
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_3_2, iter_3_3 in pairs(arg_3_0.purpleSkillCount) do
			arg_3_0.purpleSkillCount[iter_3_2] = arg_3_0.purpleSkillCount[iter_3_2] - 1
		end

		for iter_3_4, iter_3_5 in ipairs(arg_3_0:getInfoByKey("move_info")) do
			local var_3_1 = iter_3_5.fighter
			local var_3_2 = math.abs(iter_3_5.x or 0)

			if var_3_1:getTeamType() == arg_3_0:getTeamType() and var_3_2 >= var_0_20 and not iter_3_5.isBuff and var_3_1:getX() >= 0 and var_3_1:getX() <= var_0_2.STAGE_WIDTH then
				local var_3_3 = arg_3_0:selectTargetByTypeD5(var_3_1:getX())

				if var_3_3 and (not arg_3_0.purpleSkillCount[var_3_3] or arg_3_0.purpleSkillCount[var_3_3] < 0) and math.abs(var_3_3:getX() - var_3_1:getX()) <= var_0_20 then
					if var_3_1:getX() > var_3_3:getX() and var_3_3:getTeamType() == var_0_2.TeamType.A or var_3_1:getX() < var_3_3:getX() and var_3_3:getTeamType() == var_0_2.TeamType.B then
						local var_3_4 = var_0_7.new({
							tableID = var_0_22,
							start = var_0_1.ctx.battle.count,
							level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
							skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
							fighter = arg_3_0,
							target = var_3_3
						})

						var_3_3:addBuffs({
							var_3_4
						})
					else
						local var_3_5 = var_0_7.new({
							tableID = var_0_21,
							start = var_0_1.ctx.battle.count,
							level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
							skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
							fighter = arg_3_0,
							target = var_3_3
						})

						var_3_3:addBuffs({
							var_3_5
						})
					end

					arg_3_0.purpleSkillCount[var_3_3] = var_0_23
				end
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_4_1.target:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE > var_0_12 then
		local var_4_0 = var_0_7.new({
			tableID = var_0_13,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)),
			skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
			fighter = arg_4_0,
			target = arg_4_1.target
		})
		local var_4_1 = math.ceil((arg_4_1.target:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE - var_0_12) * var_0_14) + arg_4_0.blueShieldCount * var_0_16

		var_4_0:setExtraTime(var_4_1)
		arg_4_1.target:addBuffs({
			var_4_0
		})

		arg_4_0.blueShieldCount = 0
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if var_5_2 > 0 and var_0_9:father(arg_5_1.skillID) == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		var_5_2 = var_5_2 + var_5_2 * arg_5_0.blueShieldCount * var_0_17
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	var_0_3.super.buffAddAction(arg_6_0, arg_6_1)

	if arg_6_0.isSkinSkillOn_ and arg_6_1.fighter == arg_6_0 and arg_6_1:dBuffType() == var_0_2.DBuffType.KONG_JU then
		arg_6_0.extraFearTime = math.min(arg_6_0.extraFearTime + var_0_24, var_0_25)

		arg_6_1:setExtraTime(arg_6_1.extraTime_ + arg_6_0.extraFearTime)
	end
end

function var_0_3.buffRemoveAction(arg_7_0, arg_7_1)
	var_0_3.super.buffRemoveAction(arg_7_0, arg_7_1)

	if arg_7_1:getTableID() == var_0_15 then
		arg_7_0.blueShieldCount = arg_7_0.blueShieldCount + 1
	end
end

function var_0_3.shieldFeedBack(arg_8_0, arg_8_1, arg_8_2)
	var_0_3.super.shieldFeedBack(arg_8_0, arg_8_1, arg_8_2)

	if arg_8_2 and arg_8_2:getTableID() == var_0_15 then
		arg_8_0.blueShieldCount = arg_8_0.blueShieldCount - 1
	end
end

function var_0_3.selectTargetByTypeD1(arg_9_0)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and iter_9_1.hero_:getDistanceType() == var_0_2.DistanceType.QIANPAI then
			table.insert(var_9_0, iter_9_1)
		end
	end

	return var_9_0
end

function var_0_3.selectTargetByTypeD2(arg_10_0)
	local var_10_0 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1.hero_:getDistanceType() == var_0_2.DistanceType.ZHONGPAI then
			table.insert(var_10_0, iter_10_1)
		end
	end

	return var_10_0
end

function var_0_3.selectTargetByTypeD3(arg_11_0)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.sideTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1.hero_:getDistanceType() == var_0_2.DistanceType.HOUPAI then
			table.insert(var_11_0, iter_11_1)
		end
	end

	return var_11_0
end

function var_0_3.selectTargetByTypeD4(arg_12_0)
	local var_12_0 = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.selfTeam_) do
		if not iter_12_1:isDeath() and not iter_12_1:isAffected() and iter_12_1:getSummonType() == var_0_2.summonMonsterType.None and (iter_12_1:getHp() / iter_12_1:getHpLimit() < var_0_18 or iter_12_1 == arg_12_0) then
			table.insert(var_12_0, iter_12_1)
		end
	end

	return var_12_0
end

function var_0_3.selectTargetByTypeD5(arg_13_0, arg_13_1)
	local var_13_0
	local var_13_1

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() and iter_13_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_13_1 or var_13_1 > math.abs(iter_13_1:getX() - arg_13_1)) then
			var_13_0 = iter_13_1
			var_13_1 = iter_13_1:getX() - arg_13_1
		end
	end

	return var_13_0
end

return var_0_3
