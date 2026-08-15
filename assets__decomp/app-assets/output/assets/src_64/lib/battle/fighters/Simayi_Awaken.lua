local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Simayi", var_0_1.ctx.battle.requireFighter("Simayi"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 10000431
local var_0_6 = 80010103
local var_0_7 = 10001614

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.hasReborn_ = false
end

function var_0_3.updateHp(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = arg_2_0:getHp()

	if arg_2_1 < var_2_0 then
		arg_2_0.hurtHp = arg_2_0.hurtHp + var_2_0 - arg_2_1
	end

	if arg_2_0.isParalysis then
		return
	end

	if arg_2_1 <= 0 and not arg_2_0.hasReborn_ then
		arg_2_0.hasReborn_ = true

		arg_2_0:awakeReHp()

		return
	end

	arg_2_0:setHp(arg_2_1)

	if arg_2_2 ~= false then
		arg_2_2 = true
	end

	arg_2_0:updateHpBar(arg_2_2)
end

function var_0_3.awakeReHp(arg_3_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_3_0 = arg_3_0.skinSkillID_ == var_0_6 and var_0_7 or var_0_5
	local var_3_1 = {
		arg_3_0
	}
	local var_3_2 = arg_3_0:createAttackUnits(var_3_1, var_3_0)

	for iter_3_0, iter_3_1 in ipairs(var_3_2) do
		table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
		table.insert(arg_3_0.records_.special_units, iter_3_1)
	end
end

function var_0_3.hurtSkillEffect(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1.skillID
	local var_4_1 = arg_4_1.fighter
	local var_4_2, var_4_3 = var_0_4:hurtResource(var_4_0)

	if not var_4_2 or not var_4_3 or var_4_2 == "" or var_4_3 == "" then
		return
	end

	local var_4_4 = arg_4_0:getFighterModel().attackedPoint.x
	local var_4_5 = arg_4_0:getFighterModel().attackedPoint.y
	local var_4_6 = var_0_1.ctx.battle.getSpine(var_4_0, "hurt", arg_4_0:getScale())

	if var_0_4:hurtEffectType(var_4_0) == var_0_2.hurtEffectType.Back then
		var_4_6:addTo(var_0_1.ctx.battle.unitLayer)
		var_4_6:x(var_4_4 + arg_4_0:getX()):y(var_4_5 + arg_4_0:getY())
	else
		var_4_6:addTo(arg_4_0.fighterModel:getBuffLayer())
		var_4_6:x(var_4_4):y(var_4_5)
	end

	if var_4_0 == var_0_5 or var_4_0 == var_0_7 then
		var_4_6:y(var_4_6:getY() - 100)
	end

	var_4_6:playOnce()
	var_4_6:flipX(var_4_1:getFlipX())
end

return var_0_3
