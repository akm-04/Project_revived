local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Moshushi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 40010156
local var_0_5 = 40010157
local var_0_6 = var_0_2.tables.skill

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenHalo_ = nil
	arg_1_0.isHiding_ = false
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_2_0 = var_0_6:scope(arg_2_1.skillID)
		local var_2_1 = {
			fighter = arg_2_0,
			effect_area = function(arg_3_0)
				if math.abs(arg_2_0:getX() - arg_3_0:getX()) <= var_2_0 / 2 then
					return true
				end

				return false
			end,
			target_type = var_0_2.HaloEffect.sideTeam,
			buffs = {
				var_0_5
			},
			level = arg_2_0:getSkillLevelByID(arg_2_1.skillID),
			skillID = arg_2_1.skillID
		}

		arg_2_0:addBuffHalo(var_2_1)

		arg_2_0.greenHalo_ = var_2_1
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0.greenHalo_ and not arg_4_0:isHasBuffByID(var_0_4) then
		arg_4_0:removeBuffHalo(arg_4_0.greenHalo_)

		arg_4_0.greenHalo_ = nil
		arg_4_0.isHiding_ = false

		arg_4_0:playAttack(4)
	end

	if arg_4_0:isHasBuffByID(var_0_4) and not arg_4_0.isHiding_ then
		arg_4_0:getFighterModel():playAnimation_("gongji03", true)

		arg_4_0.isHiding_ = true
	end
end

return var_0_3
