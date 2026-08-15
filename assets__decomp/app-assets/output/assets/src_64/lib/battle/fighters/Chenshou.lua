local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chenshou", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 40011632
local var_0_9 = 40011625
local var_0_10 = 12
local var_0_11 = 25
local var_0_12 = 40011626
local var_0_13 = 0.4
local var_0_14 = 80010221
local var_0_15 = 10002263
local var_0_16 = 40012426
local var_0_17 = 40012427
local var_0_18 = var_0_2.tables.elementEquip
local var_0_19 = 20001480
local var_0_20 = {
	40012496,
	40012497
}
local var_0_21 = 0.05

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenLeftCount = 0
	arg_1_0.greenDeltaMove = {
		dx = 0,
		dy = 0
	}
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.EnergySkillID = 10002265
		arg_2_0.EnergyADBuff = 40012430
	else
		arg_2_0.EnergySkillID = 50010221
		arg_2_0.EnergyADBuff = 40011631
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_3_0:updateNearestTarget()

		local var_3_0

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.targetTeam_) do
			if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1 ~= arg_3_0:getNearestTarget() and (not var_3_0 or math.abs(iter_3_1:getX() - arg_3_0:getX()) < math.abs(var_3_0:getX() - arg_3_0:getX())) then
				var_3_0 = iter_3_1
			end
		end

		var_3_0 = var_3_0 or arg_3_0:getNearestTarget()

		if var_3_0 then
			arg_3_0.greenLeftCount = var_0_7:pretime(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))
			arg_3_0.greenDeltaMove = {
				dx = (var_3_0:getX() - arg_3_0:getX() + (var_3_0:getFlipX() and -50 or 50)) / (var_0_11 - var_0_10),
				dy = (var_3_0:getY() - arg_3_0:getY()) / (var_0_11 - var_0_10)
			}

			arg_3_0:flipX(arg_3_0.greenDeltaMove.dx < 0)
		end
	elseif arg_3_1.rootID_ == arg_3_0.EnergySkillID and arg_3_0.skinSkillIndex_ == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_1 = arg_3_0:createAttackUnits({
			arg_3_0
		}, var_0_14)

		for iter_3_2, iter_3_3 in ipairs(var_3_1) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
			table.insert(arg_3_0.records_.special_units, iter_3_3)
		end
	end

	if arg_3_0:hasElementEquipByID(var_0_19) then
		if #arg_3_0:getBuffsByID(var_0_20[1]) < 10 then
			local var_3_2 = var_0_19
			local var_3_3 = var_0_18:battleAttr(var_3_2, arg_3_0:getElementEquipLevelByID(var_3_2))
			local var_3_4 = arg_3_0.hero_:getElementEquipActiveRate(var_3_2)
			local var_3_5 = arg_3_0:createNewBuffs(var_0_20, arg_3_0, arg_3_0:getEnergySkillID())

			for iter_3_4, iter_3_5 in ipairs(var_3_5) do
				iter_3_5.manualRevise = var_3_3 * var_3_4
			end

			arg_3_0:addBuffs(var_3_5)
		else
			cure = (arg_3_0:getHpLimit() - arg_3_0:getHp()) * var_0_21

			arg_3_0:updateHp(arg_3_0:getHp() + cure)
		end
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0.greenLeftCount > 0 then
		if arg_4_0.greenLeftCount > var_0_10 and arg_4_0.greenLeftCount < var_0_11 then
			arg_4_0:x(arg_4_0:getX() + arg_4_0.greenDeltaMove.dx)
			arg_4_0:y(arg_4_0:getY() + arg_4_0.greenDeltaMove.dy)
		end

		arg_4_0.greenLeftCount = arg_4_0.greenLeftCount - 1
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.target

	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0.EnergySkillID then
		local var_5_1 = var_5_0:getBuffByID(arg_5_0.EnergyADBuff)
		local var_5_2 = var_5_0:getBuffByID(var_0_8)
		local var_5_3 = var_5_0:getAP() - var_5_0:getAD()

		if var_5_1 then
			var_5_1.manualRevise = var_5_3
			var_5_0.___attrCache[var_5_1:getAttrType()] = nil
		end

		if var_5_2 then
			var_5_2.manualRevise = -var_5_3
			var_5_0.___attrCache[var_5_2:getAttrType()] = nil
		end
	end

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_5_0.hero_:getHeroType() ~= var_0_2.HeroType.STRENGTH then
		var_5_0:addBuffs({
			var_0_5.new({
				tableID = var_0_9,
				start = var_0_1.ctx.battle.count,
				level = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green),
				skillID = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
				fighter = arg_5_0,
				target = var_5_0
			})
		})
	end

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_5_4 = var_5_0:getBuffByID(var_0_12)

		if var_5_4 then
			var_5_4.resetXchange_ = (arg_5_0:getX() - var_5_0:getX()) * (arg_5_0:getFlipX() and -1 or 1)
			var_5_4.resetYchange_ = arg_5_0:getY() - var_5_0:getY()
			var_5_0.buffMovePath_ = var_5_4:getPath()
		end
	end
end

function var_0_3.getAttackedReEnergy(arg_6_0)
	local var_6_0 = var_0_3.super.getAttackedReEnergy(arg_6_0)

	if arg_6_0.skinSkillIndex_ == 1 then
		var_6_0 = var_6_0 + var_0_13
	end

	return var_6_0
end

function var_0_3.buffRemoveAction(arg_7_0, arg_7_1)
	var_0_3.super.buffRemoveAction(arg_7_0, arg_7_1)

	if arg_7_1:getTableID() == var_0_17 and arg_7_0.skinSkillIndex_ == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_0 = var_0_6.B2(arg_7_0, var_0_15)
		local var_7_1 = arg_7_0:createAttackUnits(var_7_0, var_0_15)

		for iter_7_0, iter_7_1 in ipairs(var_7_1) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end
	end
end

return var_0_3
