local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yuji", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = 50010009
local var_0_8 = 80010009
local var_0_9 = 10001342
local var_0_10 = 40011440
local var_0_11 = 450

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")

	arg_1_0.skinEnemyKongjuTime = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if var_0_1.ctx.battle.walk2NextBattle_ then
		arg_2_0.skinEnemyKongjuTime = {}
	end

	for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("attack_info")) do
		if iter_2_1.fighter_ == arg_2_0 and var_0_4:father(iter_2_1.rootID_) == var_0_7 then
			arg_2_0:onApplySkinSkill()
		end
	end
end

function var_0_3.deathFeedback(arg_3_0, arg_3_1)
	if arg_3_1:getTeamType() ~= arg_3_0:getTeamType() then
		arg_3_0:onApplySkinSkill()
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == var_0_9 and (not arg_4_0.skinEnemyKongjuTime[arg_4_1.target] or arg_4_0.skinEnemyKongjuTime[arg_4_1.target] < var_0_1.ctx.battle.count) then
		local var_4_0 = var_0_5.new({
			tableID = var_0_10,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getLevel(),
			skillID = var_0_9,
			fighter = arg_4_0,
			target = arg_4_1.target
		})

		arg_4_1.target:addBuffs({
			var_4_0
		})

		arg_4_0.skinEnemyKongjuTime[arg_4_1.target] = var_0_1.ctx.battle.count + var_0_11
	end
end

function var_0_3.onApplySkinSkill(arg_5_0)
	if arg_5_0.skinSkillID_ == var_0_8 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_0 = arg_5_0:createAttackUnits(var_0_6.B2(arg_5_0, var_0_8), var_0_9)

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end
end

return var_0_3
