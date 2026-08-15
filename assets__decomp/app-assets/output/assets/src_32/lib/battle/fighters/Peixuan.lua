local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Peixuan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40011708
local var_0_6 = 10001601
local var_0_7 = 10001816
local var_0_8 = 100
local var_0_9 = 40011703
local var_0_10 = 10001600
local var_0_11 = 200
local var_0_12 = var_0_2.STAGE_WIDTH
local var_0_13 = 40
local var_0_14 = 80010226
local var_0_15 = 10001848
local var_0_16 = 10001821

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	local var_2_0 = arg_2_1.target:getBuffByID(var_0_5)

	if var_2_0 and (arg_2_1.skillID == var_0_6 or arg_2_1.skillID == var_0_7) then
		var_2_0.resetXchange_ = (arg_2_0:getX() < arg_2_1.target:getX() and arg_2_0:getFlipX() and -1 or 1) * var_0_8
		arg_2_1.target.buffMovePath_ = var_2_0:getPath()
	end

	if arg_2_1.skillID == arg_2_0:getEnergySkillID() then
		if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_14 then
			arg_2_0.energyEffect = var_0_1.ctx.battle.getSpine(var_0_16, "area", 1)

			arg_2_0.energyEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
			arg_2_0.energyEffect:pos(arg_2_0:getX(), var_0_2.STAGE_HEIGHT / 2)
			arg_2_0.energyEffect:setScale(1)
			arg_2_0.energyEffect:playRepeat()

			arg_2_0.energyDisX = arg_2_0:getX() + (arg_2_0:getFlipX() and -var_0_12 or var_0_12)
		else
			arg_2_0.energyEffect = var_0_1.ctx.battle.getSpine(var_0_15, "area", 1)

			arg_2_0.energyEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
			arg_2_0.energyEffect:pos(arg_2_0:getX(), var_0_2.STAGE_HEIGHT / 2)
			arg_2_0.energyEffect:setScale(1)
			arg_2_0.energyEffect:playRepeat()

			arg_2_0.energyDisX = arg_2_0:getX() + (arg_2_0:getFlipX() and -var_0_12 or var_0_12)
		end
	end
end

function var_0_3.checkEnergySkill(arg_3_0)
	if arg_3_0.energyEffect then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_3_0)
	end
end

function var_0_3.addBuffBySpecialHero(arg_4_0, arg_4_1)
	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		if iter_4_1:getType() == var_0_2.BuffType.MOVE and iter_4_1.fighter:getTeamType() == arg_4_0:getTeamType() and iter_4_1.target:getTeamType() ~= arg_4_0:getTeamType() and iter_4_1.target:isHasBuffByID(var_0_9) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_0 = arg_4_0:createAttackUnits({
				iter_4_1.target
			}, var_0_10)

			for iter_4_2, iter_4_3 in ipairs(var_4_0) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
				table.insert(arg_4_0.records_.special_units, iter_4_3)
			end
		end
	end
end

function var_0_3.selectTargetByTypeD5(arg_5_0, arg_5_1, arg_5_2)
	return {
		arg_5_0
	}
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)
end

function var_0_3.toDoPerFrames(arg_7_0)
	if arg_7_0.energyEffect then
		local var_7_0 = arg_7_0.energyDisX and arg_7_0.energyEffect:getX() < arg_7_0.energyDisX or not arg_7_0.energyDisX and arg_7_0.energyEffect:getX() < arg_7_0:getX()

		arg_7_0.energyEffect:flipX(not var_7_0)

		local var_7_1 = arg_7_0.energyEffect:getX()
		local var_7_2 = arg_7_0.energyEffect:getX() + (var_7_0 and var_0_13 or -var_0_13)

		arg_7_0.energyEffect:x(var_7_2)

		for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
			if not iter_7_1:isDeath() and not iter_7_1:isAffected() and (var_7_0 and var_7_1 <= iter_7_1:getX() and var_7_2 >= iter_7_1:getX() or not var_7_0 and var_7_1 >= iter_7_1:getX() and var_7_2 <= iter_7_1:getX()) then
				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					if arg_7_0.isSkinSkillOn_ and arg_7_0.skinSkillID_ == var_0_14 then
						local var_7_3 = arg_7_0:createAttackUnits({
							iter_7_1
						}, var_0_16)

						for iter_7_2, iter_7_3 in ipairs(var_7_3) do
							table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
							table.insert(arg_7_0.records_.special_units, iter_7_3)
						end
					else
						local var_7_4 = arg_7_0:createAttackUnits({
							iter_7_1
						}, var_0_15)

						for iter_7_4, iter_7_5 in ipairs(var_7_4) do
							table.insert(arg_7_0.moveAttackUnits_, iter_7_5)
							table.insert(arg_7_0.records_.special_units, iter_7_5)
						end
					end
				end

				if arg_7_0.energyDisX and iter_7_1.hero_:getDistanceType() == var_0_2.DistanceType.QIANPAI or not arg_7_0.energyDisX and iter_7_1.hero_:getDistanceType() == var_0_2.DistanceType.HOUPAI then
					local var_7_5 = var_0_4.new({
						tableID = var_0_5,
						start = var_0_1.ctx.battle.count,
						level = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
						skillID = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
						fighter = arg_7_0,
						target = iter_7_1
					})

					var_7_5:setDirection(arg_7_0:getFlipX())

					var_7_5.resetXchange_ = (var_7_0 and var_0_11 or -var_0_11) * (arg_7_0:getFlipX() and -1 or 1)

					iter_7_1:addBuffs({
						var_7_5
					})
				end
			end
		end

		if var_7_0 then
			if arg_7_0.energyDisX then
				if arg_7_0.energyEffect:getX() > arg_7_0.energyDisX then
					arg_7_0.energyDisX = nil
				end
			elseif arg_7_0.energyEffect:getX() > arg_7_0:getX() then
				arg_7_0.energyEffect:stop()

				arg_7_0.energyEffect = nil
			end
		elseif arg_7_0.energyDisX then
			if arg_7_0.energyEffect:getX() < arg_7_0.energyDisX then
				arg_7_0.energyDisX = nil
			end
		elseif arg_7_0.energyEffect:getX() < arg_7_0:getX() then
			arg_7_0.energyEffect:stop()

			arg_7_0.energyEffect = nil
		end
	end

	if arg_7_0.isSkinSkillOn_ and arg_7_0.skinSkillID_ == var_0_14 and not arg_7_0:isDeath() then
		for iter_7_6, iter_7_7 in ipairs(arg_7_0:getInfoByKey("buff_info")) do
			if iter_7_7.target and iter_7_7.target:getTeamType() ~= arg_7_0:getTeamType() and math.abs(iter_7_7:Xchange()) > 1 and not iter_7_7.target:isDeath() and not iter_7_7.target:isAffected() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_7_6 = arg_7_0:createAttackUnits({
					iter_7_7.target
				}, var_0_14)

				for iter_7_8, iter_7_9 in ipairs(var_7_6) do
					table.insert(arg_7_0.moveAttackUnits_, iter_7_9)
					table.insert(arg_7_0.records_.special_units, iter_7_9)
				end
			end
		end
	end
end

return var_0_3
