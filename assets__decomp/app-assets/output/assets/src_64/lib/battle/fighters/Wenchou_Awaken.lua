local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wenchou", var_0_1.ctx.battle.requireFighter("Wenchou"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 10000157
local var_0_6 = 10001140
local var_0_7 = 40011243

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.greenSign_ = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_3_0.leftCount_ then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
			if iter_3_1.target == arg_3_0 and iter_3_1:getType() == var_0_2.BuffType.CONTINUE_HARM then
				local var_3_0 = var_0_4.new({
					tableID = var_0_7,
					start = var_0_1.ctx.battle.count,
					level = arg_3_0:getSkillLevelByID(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)),
					skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice),
					fighter = arg_3_0,
					target = arg_3_0,
					manualHarmRevise = iter_3_1:getHarm()
				})

				var_3_0:setExtraTime(iter_3_1:getTime())
				arg_3_0:addBuffs({
					var_3_0
				})
				arg_3_0:removeBuffs(iter_3_1)
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if arg_4_0.greenSign_[arg_4_1.target] then
			arg_4_0.greenSign_[arg_4_1.target] = arg_4_0.greenSign_[arg_4_1.target] + 1
		else
			arg_4_0.greenSign_[arg_4_1.target] = 1
		end

		if arg_4_0.greenSign_[arg_4_1.target] >= 2 then
			arg_4_0.greenSign_[arg_4_1.target] = 0

			local var_4_0 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_4_0, iter_4_1 in ipairs(var_4_0) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end
	elseif arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_4_1 = arg_4_0:getBuffs()
		local var_4_2 = 0

		for iter_4_2 = #var_4_1, 1, -1 do
			local var_4_3 = var_4_1[iter_4_2]

			if var_4_3 and var_4_3:getBuffForm() == var_0_2.BuffForm.DEBUFF then
				arg_4_0:removeBuffs(var_4_3)
			end
		end
	elseif arg_4_1.skillID == var_0_6 then
		local var_4_4 = arg_4_1.target:getBuffs()
		local var_4_5 = 0
		local var_4_6

		for iter_4_3 = #var_4_4, 1, -1 do
			local var_4_7 = var_4_4[iter_4_3]

			if var_4_7 and var_4_7:getBuffForm() == var_0_2.BuffForm.GAIN and (not var_4_6 or var_4_5 < var_4_7.startCount_) then
				var_4_6 = var_4_7
				var_4_5 = var_4_7.startCount_
			end
		end

		if var_4_6 then
			arg_4_1.target:removeBuffs(var_4_6)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_4_8 = arg_4_0:createAttackUnits({
					arg_4_0
				}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

				for iter_4_4, iter_4_5 in ipairs(var_4_8) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
					table.insert(arg_4_0.records_.special_units, iter_4_5)
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if var_5_2 > 0 and arg_5_1.skillID == var_0_5 and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_6 = arg_5_0:createAttackUnits({
			arg_5_1.target
		}, var_0_6)

		for iter_5_0, iter_5_1 in ipairs(var_5_6) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

return var_0_3
