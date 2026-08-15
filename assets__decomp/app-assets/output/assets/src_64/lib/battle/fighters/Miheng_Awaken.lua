local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Miheng", var_0_1.ctx.battle.requireFighter("Miheng"))
local var_0_4 = 0
local var_0_5 = 2e-05
local var_0_6 = 40010952

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.addHaloBuff_ = false
	arg_1_0.awakeHaloBuff_ = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		if arg_2_0.awakeHaloBuff_ then
			arg_2_0:removeBuffHalo(arg_2_0.awakeHaloBuff_)

			arg_2_0.awakeHaloBuff_ = nil
		end

		return
	end

	if not arg_2_0.addHaloBuff_ then
		arg_2_0.addHaloBuff_ = true

		local var_2_0 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
		local var_2_1 = var_0_4 + var_0_5 * var_2_0
		local var_2_2 = {
			fighter = arg_2_0,
			effect_area = function(arg_3_0)
				return true
			end,
			manualAttr = function()
				return var_2_1 * (var_0_1.ctx.battle.count / 30)
			end,
			target_type = var_0_2.HaloEffect.selfTeam,
			buffs = {
				var_0_6
			},
			level = var_2_0,
			skillID = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
			summonType = var_0_2.summonMonsterType.None
		}

		arg_2_0:addBuffHalo(var_2_2)

		arg_2_0.awakeHaloBuff_ = var_2_2
	end
end

return var_0_3
