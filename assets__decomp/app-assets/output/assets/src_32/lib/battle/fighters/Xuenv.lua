local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = 40010350
local var_0_8 = 60
local var_0_9 = "skeletons/pet/xuenv/xuehua_particle_texture.plist"
local var_0_10 = "skeletons/pet/xuenv/xuehua_yuan_particle_texture.plist"

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.snowEffectTime_ = 0
	arg_1_0.snowEffect1 = nil
	arg_1_0.snowEffect2 = nil
	arg_1_0.snowEffect3 = nil
	arg_1_0.energyEffectReady_ = false
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getEnergySkillID() then
		arg_2_0.energyEffectReady_ = true
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getEnergySkillID() and arg_3_0.energyEffectReady_ then
		arg_3_0.snowEffectTime_ = var_0_8

		if arg_3_0.isStarEnergy_ then
			arg_3_0.snowEffectTime_ = arg_3_0.snowEffectTime_ + 60
		end

		arg_3_0.energyEffectReady_ = false

		if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
			arg_3_0.snowEffect1 = cc.ParticleSystemQuad:create(var_0_9)

			arg_3_0.snowEffect1:addTo(var_0_1.ctx.battle.unitLayer)
			arg_3_0.snowEffect1:setPosition(var_0_2.STAGE_WIDTH / 2, var_0_2.STAGE_HEIGHT / 2)

			arg_3_0.snowEffect2 = cc.ParticleSystemQuad:create(var_0_10)

			arg_3_0.snowEffect2:addTo(var_0_1.ctx.battle.unitLayer)
			arg_3_0.snowEffect2:setPosition(var_0_2.STAGE_WIDTH / 2, var_0_2.STAGE_HEIGHT / 2)

			arg_3_0.snowEffect3 = var_0_1.ctx.battle.getSpine(arg_3_0:getEnergySkillID(), "area", 2)

			arg_3_0.snowEffect3:addTo(var_0_1.ctx.battle.unitLayer)
			arg_3_0.snowEffect3:setPosition(var_0_2.STAGE_WIDTH / 2, var_0_2.STAGE_HEIGHT / 2)
		end
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0.snowEffectTime_ > 0 then
		if arg_4_0.snowEffectTime_ % 10 < 1 then
			for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
				if not iter_4_1:isDeath() and not iter_4_1:isAffected() and not iter_4_1:isHasBuffByID(var_0_7) then
					arg_4_0:addIceFrozenBuff(iter_4_1)
				end
			end
		end

		arg_4_0.snowEffectTime_ = arg_4_0.snowEffectTime_ - 1

		if arg_4_0.snowEffectTime_ <= 0 and not arg_4_0.stopTimeCount_ then
			arg_4_0:removeIceEffect()
		end
	end
end

function var_0_3.removeIceEffect(arg_5_0)
	arg_5_0:removeIceFrozenBuff()

	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_5_0.snowEffect1 and not tolua.isnull(arg_5_0.snowEffect1) then
		arg_5_0.snowEffect1:removeSelf()
	end

	if arg_5_0.snowEffect2 and not tolua.isnull(arg_5_0.snowEffect2) then
		arg_5_0.snowEffect2:removeSelf()
	end

	if arg_5_0.snowEffect3 and not tolua.isnull(arg_5_0.snowEffect3) then
		arg_5_0.snowEffect3:removeSelf()
	end

	arg_5_0.snowEffect1 = nil
	arg_5_0.snowEffect2 = nil
	arg_5_0.snowEffect3 = nil
end

function var_0_3.addIceFrozenBuff(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0:getEnergySkillID()
	local var_6_1 = var_0_4.new({
		tableID = var_0_7,
		start = var_0_1.ctx.battle.count,
		level = arg_6_0:getSkillLevelByID(var_6_0),
		skillID = var_6_0,
		fighter = arg_6_0,
		target = arg_6_1
	})

	var_6_1:setIsHit(true)
	var_6_1:setDirection(arg_6_0:getFighterModel():getFlipX())
	arg_6_1:addBuffs({
		var_6_1
	})
end

function var_0_3.removeIceFrozenBuff(arg_7_0)
	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and iter_7_1:isHasBuffByID(var_0_7) then
			iter_7_1:removeBuffByID(var_0_7)
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}
	local var_8_1 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() then
			local var_8_2 = var_0_6:distanceType(iter_8_1:getTableID())

			if var_8_2 == var_0_2.DistanceType.ZHONGPAI or var_8_2 == var_0_2.DistanceType.HOUPAI then
				table.insert(var_8_0, iter_8_1)
			end
		end
	end

	if #var_8_0 >= 1 then
		local var_8_3 = math.random(#var_8_0)
		local var_8_4 = var_8_0[var_8_3]

		table.insert(var_8_1, var_8_4)
		table.remove(var_8_0, var_8_3)

		if arg_8_0.isStarPurple_ and #var_8_0 >= 1 then
			local var_8_5 = 0.5

			if var_0_2.weightedChoise({
				1 - var_8_5,
				var_8_5
			}) == 1 then
				local var_8_6 = var_8_0[math.random(#var_8_0)]

				table.insert(var_8_1, var_8_6)
			end
		end
	end

	return var_8_1
end

function var_0_3.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	local var_9_0 = var_0_5:desc4NumStep(arg_9_1.skillID)[2]
	local var_9_1 = arg_9_0:getSkillLevelByID(arg_9_1.skillID)

	if arg_9_0.isStarBlue_ and arg_9_1.skillID == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_9_4 = arg_9_4 + var_9_1 * var_9_0 * arg_9_1.target:getAPJianShang()
	end

	return var_0_3.super.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
end

return var_0_3
