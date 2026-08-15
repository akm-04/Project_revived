local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xinxianying", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("AttackUnit")
local var_0_7 = var_0_2.tables.dbuff
local var_0_8 = var_0_2.tables.skill
local var_0_9 = 10001270
local var_0_10 = 10001265
local var_0_11 = 40011342
local var_0_12 = 10001269
local var_0_13 = {
	10001266,
	10001267,
	10001268
}
local var_0_14 = 10001272
local var_0_15 = 10001271

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenTarget = nil
	arg_1_0.energyEffect = nil
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	if arg_2_1.skillID == var_0_9 then
		if arg_2_0.greenTarget and arg_2_0.greenTarget == arg_2_1.target then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_0 = arg_2_0:createAttackUnits({
					arg_2_0
				}, var_0_10)

				for iter_2_0, iter_2_1 in ipairs(var_2_0) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
					table.insert(arg_2_0.records_.special_units, iter_2_1)
				end
			end
		else
			arg_2_0:removeBuffByID(var_0_11)
		end

		arg_2_0.greenTarget = arg_2_1.target
	end

	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_2_1 = arg_2_1.target:getBuffs()
		local var_2_2 = false

		for iter_2_2, iter_2_3 in ipairs(var_2_1) do
			if var_0_7:dbuffType(iter_2_3:getTableID()) > 0 then
				var_2_2 = true
			end
		end

		if var_2_2 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_3 = arg_2_0:createAttackUnits({
				arg_2_1.target
			}, var_0_12)

			for iter_2_4, iter_2_5 in ipairs(var_2_3) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_5)
				table.insert(arg_2_0.records_.special_units, iter_2_5)
			end
		end
	elseif arg_2_1.skillID == var_0_14 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_4 = arg_2_0:createAttackUnits({
				arg_2_1.target
			}, var_0_13[math.random(#var_0_13)])

			for iter_2_6, iter_2_7 in ipairs(var_2_4) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_7)
				table.insert(arg_2_0.records_.special_units, iter_2_7)
			end
		end
	elseif arg_2_1.skillID == var_0_15 then
		if arg_2_0.energyEffect then
			arg_2_0.energyEffect:removeSelf()

			arg_2_0.energyEffect = nil
		end

		arg_2_0.energyEffect = var_0_1.ctx.battle.getSpine(var_0_15, "area", 1)

		arg_2_0.energyEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
		arg_2_0.energyEffect:setScale(0.4)

		local var_2_5
		local var_2_6

		for iter_2_8, iter_2_9 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_9:isDeath() and not iter_2_9:isAffected() and (not var_2_5 or var_2_5 > iter_2_9:getX()) then
				var_2_5 = iter_2_9:getX()
			end
		end

		for iter_2_10, iter_2_11 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_11:isDeath() and not iter_2_11:isAffected() and (not var_2_6 or var_2_6 < iter_2_11:getX()) then
				var_2_6 = iter_2_11:getX()
			end
		end

		if var_2_5 and var_2_6 then
			arg_2_0.energyEffect:pos((var_2_5 + var_2_6) / 2, 625)
			arg_2_0.energyEffect:playOnce()
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0
	local var_3_1

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and (not var_3_1 or var_3_0 > var_3_1.hero_:getDistance()) then
			var_3_1 = iter_3_1
			var_3_0 = iter_3_1.hero_:getDistance()
		end
	end

	if var_3_1 then
		return {
			var_3_1
		}
	end

	return {}
end

return var_0_3
