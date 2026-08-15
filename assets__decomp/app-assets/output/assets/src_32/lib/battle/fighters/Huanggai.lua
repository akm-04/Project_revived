local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_2.tables.skill
local var_0_4 = var_0_0.class("Huanggai", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_5 = 20010172
local var_0_6 = 10000243
local var_0_7 = 82010068
local var_0_8 = 150
local var_0_9 = 200
local var_0_10 = 81010068
local var_0_11 = 83010068

function var_0_4.init(arg_1_0)
	var_0_4.super.init(arg_1_0)

	arg_1_0.skinSkillEffect = nil
	arg_1_0.lazhuCount = 0
	arg_1_0.isLazhuOnArea = false
	arg_1_0.skinBuffOn = false

	if arg_1_0.hero_ then
		arg_1_0:checkSkinSkillInfo()

		if arg_1_0.isSkinSkillOn_ then
			table.insert(arg_1_0.startSkillQueue_, 1, var_0_7)
		end
	end
end

function var_0_4.populateWithHero(arg_2_0, arg_2_1)
	var_0_4.super.populateWithHero(arg_2_0, arg_2_1)
	arg_2_0:checkSkinSkillInfo()

	if arg_2_0.isSkinSkillOn_ then
		table.insert(arg_2_0.startSkillQueue_, 1, var_0_7)
	end
end

function var_0_4.applySingleUnit(arg_3_0, arg_3_1)
	if arg_3_1.skillID == var_0_7 then
		arg_3_0.skinSkillPosX_ = arg_3_0:getSkinSkillPosX()

		if not arg_3_0.skinSkillEffect then
			local var_3_0, var_3_1 = var_0_3:areaResource(var_0_7)

			if var_3_0 and var_3_0 ~= "" and var_3_1 and var_3_1 ~= "" then
				arg_3_0.skinSkillEffect = var_0_1.ctx.battle.getSpine(var_0_7, "area", arg_3_0:getScale())

				arg_3_0.skinSkillEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
			end
		end

		if arg_3_0.skinSkillEffect then
			arg_3_0.skinSkillEffect:pos(arg_3_0.skinSkillPosX_, 300)
			arg_3_0.skinSkillEffect:playRepeat()
		end

		arg_3_0.isLazhuOnArea = true
	end

	var_0_4.super.applySingleUnit(arg_3_0, arg_3_1)
end

function var_0_4.moveUnitArrive(arg_4_0, arg_4_1)
	if arg_4_1.skillID ~= var_0_7 then
		var_0_4.super.moveUnitArrive(arg_4_0, arg_4_1)
	else
		if arg_4_1.resource then
			arg_4_1.resource:stop()
		end

		arg_4_1:arrive()

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			local var_4_0 = arg_4_1:getReportUnits()

			for iter_4_0, iter_4_1 in ipairs(var_4_0) do
				table.insert(arg_4_0.applyUnits_, iter_4_1)
			end
		else
			local var_4_1 = arg_4_0:getTargets(arg_4_1.skillID, arg_4_1)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and next(var_4_1) then
				local var_4_2 = arg_4_1:createAttacks(var_4_1)

				for iter_4_2, iter_4_3 in ipairs(var_4_2) do
					table.insert(arg_4_0.applyUnits_, iter_4_3)
				end
			end
		end
	end
end

function var_0_4.toDoPerFrames(arg_5_0)
	if arg_5_0.isSkinSkillOn_ and arg_5_0.isLazhuOnArea then
		arg_5_0.lazhuCount = arg_5_0.lazhuCount + 1

		if arg_5_0.lazhuCount > var_0_8 then
			local var_5_0 = {
				arg_5_0:getLazhuTarget()
			}

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_1 = arg_5_0:createAttackUnits(var_5_0, var_0_10)

				for iter_5_0, iter_5_1 in ipairs(var_5_1) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
					arg_5_0:unitAfterCreate(nil, var_5_1)
				end
			end

			arg_5_0.lazhuCount = 0
		end
	end

	if not arg_5_0.skinBuffOn and arg_5_0.isSkinSkillOn_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_2 = arg_5_0:createAttackUnits({
			arg_5_0
		}, var_0_11)

		for iter_5_2, iter_5_3 in ipairs(var_5_2) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
		end

		arg_5_0.skinBuffOn = true
	end
end

function var_0_4.applyHurtFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
	if arg_6_2 > 0 and arg_6_0:isHasBuffByID(var_0_5) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_0 = var_0_6
		local var_6_1 = {
			arg_6_1.fighter
		}

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_2 = arg_6_0:createAttackUnits(var_6_1, var_6_0)

			for iter_6_0, iter_6_1 in ipairs(var_6_2) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end
	end

	return var_0_4.super.applyHurtFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
end

function var_0_4.selectTargetByTypeC32(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {}

	for iter_7_0, iter_7_1 in pairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and math.abs(iter_7_1:getX() - arg_7_0:getSkinSkillPosX()) < var_0_9 then
			table.insert(var_7_0, iter_7_1)
		end
	end

	return var_7_0
end

function var_0_4.getLazhuTarget(arg_8_0)
	local var_8_0 = 1280
	local var_8_1

	for iter_8_0, iter_8_1 in pairs(arg_8_0.sideTeam_) do
		if not iter_8_1:isDeath() and iter_8_1.summonType_ == var_0_2.summonMonsterType.None and (not var_8_1 or var_8_0 > math.abs(iter_8_1:getX() - arg_8_0:getSkinSkillPosX())) then
			var_8_0 = math.abs(iter_8_1:getX() - arg_8_0:getSkinSkillPosX())
			var_8_1 = iter_8_1
		end
	end

	return var_8_1
end

function var_0_4.getSkinSkillPosX(arg_9_0)
	local var_9_0 = 1

	if arg_9_0:getTeamType() == var_0_2.TeamType.B then
		var_9_0 = -1
	end

	return 640 + 280 * var_9_0
end

function var_0_4.getSkillLevelByID(arg_10_0, arg_10_1)
	local var_10_0 = var_0_4.super.getSkillLevelByID(arg_10_0, arg_10_1)

	if arg_10_1 == var_0_7 then
		var_10_0 = arg_10_0:getSkillLevelByID(arg_10_0:getPugongID())
	end

	return var_10_0 or 0
end

function var_0_4.unitAfterCreate(arg_11_0, arg_11_1, arg_11_2)
	var_0_4.super.unitAfterCreate(arg_11_0, arg_11_1, unit)

	if arg_11_1 and arg_11_1.skillID == var_0_7 then
		arg_11_1:setDesition(arg_11_0:getSkinSkillPosX(), arg_11_0:getY())
	end
end

return var_0_4
