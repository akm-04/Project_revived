local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yangxi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = 210
local var_0_8 = 80010233

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleCount = 0
	arg_1_0.records_.skin_buff_target = {}
	arg_1_0.energyTag = false
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.PurpleBuff = 40012694
		arg_2_0.EnergySkillID = 10002514
	else
		arg_2_0.PurpleBuff = 40011802
		arg_2_0.EnergySkillID = 50010233
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if arg_3_0.purpleCount <= 0 then
			arg_3_0.purpleCount = var_0_7

			local var_3_0 = 500 * var_0_1.ctx.battle.count / 30 / 8
			local var_3_1 = arg_3_0:newBuff(arg_3_0.PurpleBuff, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple), var_3_0)

			arg_3_0:addBuffs({
				var_3_1
			})

			if arg_3_0.skinSkillIndex_ == 1 then
				if arg_3_0.energyTag then
					arg_3_0.energyTag = false

					for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
						if iter_3_1 ~= arg_3_0 and not iter_3_1:isDeath() and not iter_3_1:isAffected() then
							local var_3_2 = arg_3_0:newBuff(arg_3_0.PurpleBuff, iter_3_1, var_0_8, var_3_0)

							iter_3_1:addBuffs({
								var_3_2
							})
						end
					end
				elseif var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
					local var_3_3 = arg_3_0.skinBuffTargetIndex[tostring(var_0_1.ctx.battle.count)]

					if var_3_3 then
						local var_3_4 = var_0_1.ctx.battle.getFighter(var_3_3)
						local var_3_5 = arg_3_0:newBuff(arg_3_0.PurpleBuff, var_3_4, var_0_8, var_3_0)

						var_3_4:addBuffs({
							var_3_5
						})
					end
				else
					local var_3_6
					local var_3_7 = {}

					for iter_3_2, iter_3_3 in ipairs(arg_3_0.selfTeam_) do
						if iter_3_3 ~= arg_3_0 and not iter_3_3:isDeath() and not iter_3_3:isAffected() then
							table.insert(var_3_7, iter_3_3)
						end
					end

					if #var_3_7 > 0 then
						local var_3_8 = var_3_7[math.random(#var_3_7)]

						arg_3_0.records_.skin_buff_target[tostring(var_0_1.ctx.battle.count)] = var_3_8.fighterIndex

						local var_3_9 = arg_3_0:newBuff(arg_3_0.PurpleBuff, var_3_8, var_0_8, var_3_0)

						var_3_8:addBuffs({
							var_3_9
						})
					end
				end
			end
		else
			arg_3_0.purpleCount = arg_3_0.purpleCount - 1
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if var_0_5:father(arg_4_1.skillID) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0:getBuffs()) do
			if iter_4_1:getBuffForm() == var_0_2.BuffForm.GAIN then
				if arg_4_1.target == arg_4_0 then
					iter_4_1:setLeftCount(iter_4_1:getLeftCount() * 2)
				else
					local var_4_0 = iter_4_1:totalDHarm() - iter_4_1:getDHarm()
					local var_4_1 = iter_4_1:getManualDharm()
					local var_4_2 = arg_4_0:newBuff(iter_4_1:getTableID(), arg_4_1.target, arg_4_1.skillID, var_4_1)

					arg_4_1.target:addBuffs({
						var_4_2
					})
					var_4_2:setDHarm(var_4_0)
					var_4_2:setLeftCount(iter_4_1:getLeftCount())
				end
			end
		end
	elseif var_0_5:father(arg_4_1.skillID) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) and var_0_1.ctx.battle.unitBottomLayer.getContentSize then
		local var_4_3 = var_0_1.ctx.battle.unitBottomLayer:getContentSize()

		if type(var_4_3) == "table" and var_4_3.width and var_4_3.height then
			local var_4_4 = var_0_1.ctx.battle.getSpine(arg_4_0.EnergySkillID, "area", 1)

			var_4_4:addTo(var_0_1.ctx.battle.unitBottomLayer)
			var_4_4:pos(var_4_3.width / 2, var_4_3.height * 3 / 4)
			var_4_4:setScale(0.6 / var_0_1.ctx.battle.unitBottomLayer:getScale())
			var_4_4:playOnce()
		end
	end
end

function var_0_3.newBuff(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4)
	arg_5_4 = arg_5_4 or 0

	local var_5_0 = var_0_4.new({
		tableID = arg_5_1,
		start = var_0_1.ctx.battle.count,
		level = arg_5_0:getSkillLevelByID(arg_5_3),
		skillID = arg_5_3,
		fighter = arg_5_0,
		target = arg_5_2,
		manualDharm = arg_5_4
	})

	var_5_0:setIsHit(true)
	var_5_0:setDirection(arg_5_0:getFighterModel():getFlipX())

	return var_5_0
end

function var_0_3.setupReport(arg_6_0, arg_6_1)
	var_0_3.super.setupReport(arg_6_0, arg_6_1)

	arg_6_0.skinBuffTargetIndex = arg_6_1.skin_buff_target
end

function var_0_3.writeReport(arg_7_0)
	local var_7_0 = var_0_3.super.writeReport(arg_7_0)

	var_7_0.skin_buff_target = arg_7_0.records_.skin_buff_target

	return var_7_0
end

function var_0_3.energyAction(arg_8_0, arg_8_1)
	var_0_3.super.energyAction(arg_8_0, arg_8_1)

	if var_0_5:father(arg_8_1) == arg_8_0:getEnergySkillID() then
		arg_8_0.energyTag = true
	end
end

return var_0_3
