local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Menghuo", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.elementEquip
local var_0_7 = 10000156
local var_0_8 = 18
local var_0_9 = 80010053
local var_0_10 = 40011031
local var_0_11 = 540
local var_0_12 = 0.5
local var_0_13 = 0.6
local var_0_14 = 20001486
local var_0_15 = 40012544
local var_0_16 = 0.01
local var_0_17 = 30

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.enterSkillCount_ = var_0_5:pretime(var_0_7)
	arg_1_0.skinSkillCD_ = {}
end

function var_0_3.checkMove(arg_2_0)
	if arg_2_0.isEnterSkill_ then
		if var_0_1.ctx.battle.count < arg_2_0.hero_:enterDuration() then
			arg_2_0.isWalking_ = 1

			if not arg_2_0:isWalking() then
				arg_2_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_2_0:isWalking() == 2 then
				local var_2_0 = arg_2_0:getFlipX() and -1 or 1

				arg_2_0:moveByX(arg_2_0.hero_:enterSpeed() * var_2_0)
			end

			if arg_2_0:getCurrentAnimation() ~= "run" then
				arg_2_0:modelWalk()
			end
		elseif not arg_2_0.playedEnterSkill_ then
			if arg_2_0:isWalking() ~= 3 then
				arg_2_0.preWalk_ = false
				arg_2_0.isWalking_ = false
				arg_2_0.behindWalk_ = false
				arg_2_0.playedEnterSkill_ = true
				arg_2_0.walk2Position_ = false

				if arg_2_0:getCurrentAnimation() == "run" then
					arg_2_0:getFighterModel():idle()
				end
			end
		elseif var_0_1.ctx.battle.count > arg_2_0.hero_:enterDelayDuration() then
			arg_2_0.isEnterSkill_ = nil
			arg_2_0.walk2Position_ = false
			arg_2_0.playedEnterSkill_ = false
		end

		return
	end

	var_0_3.super.checkMove(arg_2_0)
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:hasElementEquipByID(var_0_14) then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
			if not iter_3_1:isDeath() then
				local var_3_0 = iter_3_1:getBuffsByID(var_0_15)[1]

				if var_3_0 and (var_3_0:getLeftCount() - 1) % var_0_17 == 0 and (var_3_0:getLeftCount() - 1) % var_0_17 == 0 then
					var_3_0.manualRevise = var_3_0.manualRevise - var_0_16

					local var_3_1 = iter_3_1.hero_:getBattleAttr(var_0_2.AttributeType.AD)
					local var_3_2, var_3_3 = iter_3_1:getBuffAttrChange(var_0_2.AttributeType.AD)
					local var_3_4 = math.max(1 + var_3_3, 0) * var_3_1 + var_3_2

					iter_3_1.___attrCache[var_0_2.AttributeType.AD] = math.max(var_3_4, 0)
				end
			end
		end
	end

	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0.unitSkills_ and arg_3_0.unitSkills_.rootID_ == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_3_5 = arg_3_0:getTeamType() == var_0_2.TeamType.A and 1 or -1

		arg_3_0:x(arg_3_0:getX() + var_3_5 * var_0_8)
	end

	if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_9 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_3_0:skinSkill()
	end
end

function var_0_3.setFormation(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	arg_4_0.isEnterSkill_ = arg_4_0:enterSkill() > 0 and arg_4_0:getSkillLevelByID(arg_4_0:enterSkill()) > 0

	if arg_4_0.isEnterSkill_ then
		arg_4_0.playedEnterSkill_ = false

		local var_4_0 = arg_4_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH

		arg_4_0:x(var_4_0)
		arg_4_0:y(var_0_2.STAGE_HEIGHT / 2 - 50 + arg_4_3 - 90 * (arg_4_2 % 2))

		return arg_4_2 + 1
	end

	return var_0_3.super.setFormation(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
end

function var_0_3.enterSkill(arg_5_0)
	return arg_5_0.hero_:enterSkill()
end

function var_0_3.skinSkill(arg_6_0)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None and iter_6_1:getHp() / iter_6_1:getHpLimit() < var_0_12 and (not arg_6_0.skinSkillCD_[iter_6_1] or var_0_1.ctx.battle.count - arg_6_0.skinSkillCD_[iter_6_1] > var_0_11) then
			arg_6_0.skinSkillCD_[iter_6_1] = var_0_1.ctx.battle.count

			table.insert(var_6_0, iter_6_1)
		end
	end

	if next(var_6_0) then
		local var_6_1 = arg_6_0:createAttackUnits(var_6_0, var_0_9)

		for iter_6_2, iter_6_3 in ipairs(var_6_1) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
			table.insert(arg_6_0.records_.special_units, iter_6_3)
		end
	end
end

function var_0_3.buffAddAction(arg_7_0, arg_7_1)
	if arg_7_1:getTableID() == var_0_10 then
		local var_7_0 = (arg_7_1.target:getHpLimit() - arg_7_1.target:getHp()) * var_0_13
		local var_7_1 = arg_7_1:getDHarm()

		arg_7_1.manualDharm = arg_7_1.manualDharm + var_7_0
		arg_7_1.dHarm_ = var_7_1 + var_7_0

		if arg_7_1.target ~= arg_7_0 then
			local var_7_2 = arg_7_0:newBuff({
				var_0_10
			}, arg_7_0, arg_7_0:getEnergySkillID())

			var_7_2[1].manualDharm = var_7_2[1].manualDharm + var_7_0

			arg_7_0:addBuffs(var_7_2)
		end
	end

	if arg_7_0:hasElementEquipByID(var_0_14) and arg_7_1:isDHarmBuff() then
		local var_7_3 = var_0_14
		local var_7_4 = var_0_6:battleAttr(var_7_3, arg_7_0:getElementEquipLevelByID(var_7_3))
		local var_7_5 = arg_7_0.hero_:getElementEquipActiveRate(var_7_3)
		local var_7_6 = var_0_6:skillIDs(var_7_3)
		local var_7_7 = var_0_6:buffIDs(var_7_3)
		local var_7_8 = arg_7_0:createNewBuffs(var_7_7, arg_7_1.target, var_7_6[1])

		for iter_7_0, iter_7_1 in ipairs(var_7_8) do
			iter_7_1.manualRevise = var_7_4 * var_7_5
			iter_7_1.relatedBuff = arg_7_1
		end

		arg_7_1.target:addBuffs(var_7_8)

		local var_7_9 = arg_7_0:createNewBuffs({
			var_0_15
		}, arg_7_1.target, var_7_6[1])

		arg_7_1.target:addBuffs(var_7_9)
	end

	arg_7_0:updateHpBar(true)
	var_0_3.super.buffAddAction(arg_7_0, arg_7_1)
end

function var_0_3.newBuff(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		local var_8_1 = var_0_4.new({
			tableID = iter_8_1,
			start = var_0_1.ctx.battle.count,
			level = arg_8_0:getSkillLevelByID(arg_8_3),
			skillID = arg_8_3,
			fighter = arg_8_0,
			target = arg_8_2
		})

		var_8_1:setIsHit(true)
		var_8_1:setDirection(arg_8_0:getFighterModel():getFlipX())
		table.insert(var_8_0, var_8_1)
	end

	return var_8_0
end

function var_0_3.buffRemoveAction(arg_9_0, arg_9_1)
	if arg_9_0:hasElementEquipByID(var_0_14) and arg_9_1:isDHarmBuff() then
		local var_9_0 = var_0_14
		local var_9_1 = var_0_6:buffIDs(var_9_0)
		local var_9_2 = var_0_6:skillIDs(var_9_0)
		local var_9_3 = arg_9_1.target:getBuffsByID(var_9_1[1])
		local var_9_4 = arg_9_1.target:getBuffsByID(var_9_1[2])

		for iter_9_0 = #var_9_3, 1, -1 do
			local var_9_5 = var_9_3[iter_9_0]

			if var_9_5.relatedBuff == arg_9_1 then
				arg_9_1.target:removeBuffs(var_9_5)
				arg_9_1.target:removeBuffs(var_9_4[iter_9_0])

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_9_6 = arg_9_0:createAttackUnits({
						arg_9_1.target
					}, var_9_2[1])

					for iter_9_1, iter_9_2 in ipairs(var_9_6) do
						table.insert(arg_9_0.moveAttackUnits_, iter_9_2)
						table.insert(arg_9_0.records_.special_units, iter_9_2)
					end
				end

				return
			end
		end
	end
end

return var_0_3
