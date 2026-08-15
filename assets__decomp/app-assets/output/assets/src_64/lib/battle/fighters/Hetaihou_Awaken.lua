local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hetaihou", var_0_1.ctx.battle.requireFighter("Hetaihou"))
local var_0_4 = var_0_2.tables.hero
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 5
local var_0_7 = 40011479
local var_0_8 = 40011480
local var_0_9 = 40011481

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")

	arg_1_0.twiceAwakenHitInfo = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0.energyEndCount_ == 1 then
		arg_2_0:onApplyTwiceAwakenSkill()
	end

	if arg_2_0:isDeath() or var_0_1.ctx.battle.count % 30 > 1 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or not arg_2_0.isEnergying_ then
		return
	end

	local var_2_0 = {}

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
		if not iter_2_1:isDeath() and not iter_2_1:isAffected() and (var_0_4:speed(iter_2_1:getTableID()) > iter_2_1:getCurrentSpeed() or arg_2_0.energyStoneHeros_[iter_2_1]) then
			table.insert(var_2_0, iter_2_1)
		end
	end

	if next(var_2_0) then
		local var_2_1 = arg_2_0:createAttackUnits(var_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_2_2, iter_2_3 in ipairs(var_2_1) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
			table.insert(arg_2_0.records_.special_units, iter_2_3)
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice) then
		local var_3_0 = arg_3_1.target
		local var_3_1 = var_3_0:getBuffByID(var_0_7)
		local var_3_2 = var_3_0:getBuffByID(var_0_8)
		local var_3_3 = var_3_0:getBuffByID(var_0_9)
		local var_3_4 = arg_3_0.twiceAwakenHitInfo[var_3_0] * 30

		if var_3_1 then
			var_3_1.leftCount_ = var_3_4
		end

		if var_3_2 then
			var_3_2.leftCount_ = var_3_4
		end

		if var_3_3 then
			var_3_3.leftCount_ = var_3_4
		end
	end
end

function var_0_3.applyHurtFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
	local var_4_0 = arg_4_1.fighter

	if arg_4_2 > 0 and var_4_0:getTeamType() ~= arg_4_0:getTeamType() and var_0_5:skillType(arg_4_1.skillID) ~= 1 then
		arg_4_0.twiceAwakenHitInfo[var_4_0] = math.min((arg_4_0.twiceAwakenHitInfo[var_4_0] or 0) + 1, 5)
	end

	return arg_4_0.super.applyHurtFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
end

function var_0_3.forceDie(arg_5_0)
	arg_5_0:onApplyTwiceAwakenSkill()
	var_0_3.super.forceDie(arg_5_0)
end

function var_0_3.onApplyTwiceAwakenSkill(arg_6_0)
	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) <= 0 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	for iter_6_0, iter_6_1 in pairs(arg_6_0.twiceAwakenHitInfo) do
		if not iter_6_0:isDeath() and not iter_6_0:isAffected() then
			local var_6_0 = arg_6_0:createAttackUnits({
				iter_6_0
			}, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			for iter_6_2, iter_6_3 in ipairs(var_6_0) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
				table.insert(arg_6_0.records_.special_units, iter_6_3)
			end
		end
	end
end

return var_0_3
