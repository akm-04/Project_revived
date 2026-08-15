local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fulei", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = 40012653
local var_0_8 = 40012654
local var_0_9 = 10002460
local var_0_10 = 40012655
local var_0_11 = 40012656
local var_0_12 = 10002461
local var_0_13 = 10002462
local var_0_14 = 10002463

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.HuoMianBuffCount = 0
end

function var_0_3.buffAddAction(arg_2_0, arg_2_1)
	if arg_2_1:getTableID() == var_0_11 then
		if arg_2_1.fighter:isHasBuffByID(var_0_10) then
			arg_2_1.fighter:removeBuffByID(var_0_10)
		elseif arg_2_1.fighter:isHasBuffByID(var_0_11) then
			arg_2_1.fighter:removeBuffByID(var_0_11)
		end
	end
end

function var_0_3.buffRemoveAction(arg_3_0, arg_3_1)
	if arg_3_1:getTableID() == var_0_8 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_0 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, var_0_9)

			for iter_3_0, iter_3_1 in ipairs(var_3_0) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end
	elseif arg_3_1:getTableID() == var_0_10 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			if arg_3_1.huomian then
				local var_3_1 = arg_3_0:createAttackUnits({
					arg_3_1.target
				}, var_0_12)

				for iter_3_2, iter_3_3 in ipairs(var_3_1) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end
			elseif not arg_3_1.huomian then
				local var_3_2 = arg_3_0:createAttackUnits({
					arg_3_1.target
				}, var_0_13)

				for iter_3_4, iter_3_5 in ipairs(var_3_2) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
					table.insert(arg_3_0.records_.special_units, iter_3_5)
				end
			end
		end
	elseif arg_3_1:getTableID() == var_0_11 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_3_1.huomian then
			local var_3_3 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, var_0_12)

			for iter_3_6, iter_3_7 in ipairs(var_3_3) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_7)
				table.insert(arg_3_0.records_.special_units, iter_3_7)
			end
		elseif not arg_3_1.huomian then
			local var_3_4 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, var_0_14)

			for iter_3_8, iter_3_9 in ipairs(var_3_4) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_9)
				table.insert(arg_3_0.records_.special_units, iter_3_9)
			end
		end
	end
end

function var_0_3.addBuffBySpecialHero(arg_4_0, arg_4_1)
	for iter_4_0 = #arg_4_1, 1, -1 do
		local var_4_0 = arg_4_1[iter_4_0]

		if var_4_0:getTableID() == var_0_7 and var_4_0.fighter == arg_4_0 and var_4_0.target:getTeamType() == arg_4_0:getTeamType() then
			local var_4_1 = var_4_0.target:getBuffs()

			for iter_4_1 = #var_4_1, 1, -1 do
				local var_4_2 = var_4_1[iter_4_1]

				if not arg_4_0:isPartnerControl(var_4_2) and var_4_2:canRemove() and (var_4_2:isFear() or var_4_2:isApUnable() or var_4_2:isAdUnable() or var_4_2:isExcuteAdCircle() or var_4_2:isAttackFriend() or var_4_2:isPugongOnly()) then
					var_4_0.target:removeBuffs(var_4_2)
					arg_4_0:updateHuoMianBuffCount(1)
				end
			end
		elseif var_4_0.target:isHasBuffByID(var_0_7) and var_4_0.target:getTeamType() == arg_4_0:getTeamType() and not arg_4_0:isPartnerControl(var_4_0) then
			if var_4_0:isFear() or var_4_0:isApUnable() or var_4_0:isAdUnable() or var_4_0:isExcuteAdCircle() or var_4_0:isAttackFriend() or var_4_0:isPugongOnly() then
				table.remove(arg_4_1, iter_4_0)
				var_4_0.target:removeBuffs(var_4_0)
				arg_4_0:updateHuoMianBuffCount(1)
			end
		elseif var_4_0.target:isHasBuffByID(var_0_11) and var_4_0.target:getTeamType() == arg_4_0:getTeamType() and var_4_0:getTableID() ~= var_0_11 then
			if var_4_0:dBuffType() > 0 and var_4_0:dBuffType() ~= var_0_2.DBuffType.ATTR_CHANGE and var_4_0:canRemove() then
				table.remove(arg_4_1, iter_4_0)
				arg_4_0:updateHuoMianBuffCount(1)

				var_4_0.target:getBuffByID(var_0_11).huomian = true

				var_4_0.target:removeBuffByID(var_0_11)

				local var_4_3 = arg_4_0:createNewBuffs({
					var_0_10
				}, var_4_0.target, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

				var_4_0.target:addBuffs(var_4_3)
			end
		elseif var_4_0.target:isHasBuffByID(var_0_10) and var_4_0.target:getTeamType() == arg_4_0:getTeamType() and var_4_0:getTableID() ~= var_0_10 and var_4_0:dBuffType() > 0 and var_4_0:dBuffType() ~= var_0_2.DBuffType.ATTR_CHANGE and var_4_0:canRemove() then
			table.remove(arg_4_1, iter_4_0)
			arg_4_0:updateHuoMianBuffCount(1)

			var_4_0.target:getBuffByID(var_0_10).huomian = true

			var_4_0.target:removeBuffByID(var_0_10)

			break
		end
	end

	return arg_4_1
end

function var_0_3.updateHuoMianBuffCount(arg_5_0, arg_5_1)
	arg_5_0.HuoMianBuffCount = arg_5_0.HuoMianBuffCount + arg_5_1

	if arg_5_0.HuoMianBuffCount >= 2 and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_5_0.HuoMianBuffCount = arg_5_0.HuoMianBuffCount - 2

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_5_0 = arg_5_0:getTargets(arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))
			local var_5_1 = arg_5_0:createAttackUnits(var_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			for iter_5_0, iter_5_1 in ipairs(var_5_1) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = {}
	local var_6_1 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() then
			table.insert(var_6_0, iter_6_1)
		end
	end

	local var_6_2 = math.random(tonumber(os.time()))

	math.randomseed(var_6_2)

	while #var_6_1 < 2 and #var_6_0 > 0 do
		local var_6_3 = math.random(#var_6_0)
		local var_6_4 = var_6_0[var_6_3]

		table.insert(var_6_1, var_6_4)
		table.remove(var_6_0, var_6_3)
	end

	return var_6_1
end

return var_0_3
