local var_0_0 = class("MoveUnit")
local var_0_1 = xyd.tables.skill
local var_0_2 = import("app.modules.battle.SkillEffect")
local var_0_3 = import("app.modules.battle.AttackUnitStory")
local var_0_4 = 0.05

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.fighter = arg_1_1.fighter
	arg_1_0.count = arg_1_1.count
	arg_1_0.skillID = arg_1_1.skillID
	arg_1_0.ackIndex = arg_1_1.ackIndex
	arg_1_0.targets = {}
	arg_1_0.manualTargets = nil
	arg_1_0.resourceIsHero = false
	arg_1_0.resourceHero = nil

	arg_1_0:setupBasic()
	arg_1_0:init()
end

function var_0_0.setupBasic(arg_2_0)
	local var_2_0, var_2_1 = var_0_1:unitResource(arg_2_0.skillID)

	if var_2_0 and var_2_0 ~= "" and var_2_1 and var_2_1 ~= "" then
		arg_2_0.resource = var_0_2.new(arg_2_0.skillID, "unit", arg_2_0.fighter:getScale())
	end

	arg_2_0.arrived = false
	arg_2_0.xDis_ = var_0_1:distance(arg_2_0.skillID)

	if arg_2_0.fighter:getFighterModel():getFlipX() then
		arg_2_0.xDis_ = arg_2_0.xDis_ * -1
	end

	arg_2_0.iniX_, arg_2_0.iniY_ = arg_2_0:getIniPos()
	arg_2_0.desX_ = arg_2_0:getIniPos("x") + arg_2_0.xDis_
	arg_2_0.desY_ = arg_2_0:getIniPos("y")
	arg_2_0.selectType = var_0_1:selectType(arg_2_0.skillID)
	arg_2_0.yx = var_0_1:yx(arg_2_0.skillID)
	arg_2_0.offY = var_0_1:y(arg_2_0.skillID)
	arg_2_0.isRotate = var_0_1:isRotate(arg_2_0.skillID)
	arg_2_0.speed = var_0_1:speed(arg_2_0.skillID)
	arg_2_0.unitEffectType = var_0_1:unitEffectType(arg_2_0.skillID)
	arg_2_0.aTime_ = var_0_1:aTime(arg_2_0.skillID)
	arg_2_0.accelerate_ = var_0_1:accelerate(arg_2_0.skillID)
end

function var_0_0.init(arg_3_0)
	arg_3_0.xDis_ = arg_3_0.desX_ - arg_3_0.iniX_
	arg_3_0.yDis_ = arg_3_0.desY_ - arg_3_0.iniY_

	if arg_3_0.yx == xyd.YXType.Paowuxian_Duration then
		arg_3_0.speed = math.abs(arg_3_0.xDis_ * xyd.tables.battleConfig.interval / xyd.tables.battleConfig.attackunitPaowuxianDuration)
	end
end

function var_0_0.getAreaResource(arg_4_0)
	if not arg_4_0.areaResource then
		local var_4_0, var_4_1 = var_0_1:areaResource(arg_4_0.skillID)

		if var_4_0 and var_4_0 ~= "" and var_4_1 and var_4_1 ~= "" then
			arg_4_0.areaResource = var_0_2.new(arg_4_0.skillID, "area", arg_4_0.fighter:getScale())
		end
	end

	return arg_4_0.areaResource
end

function var_0_0.addExtraBuffs(arg_5_0, arg_5_1)
	arg_5_0.extraBuffs_ = arg_5_0.extraBuffs_ or {}
	arg_5_1 = arg_5_1 or {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_1) do
		table.insert(arg_5_0.extraBuffs_, iter_5_1)
	end
end

function var_0_0.getExtraBuffs(arg_6_0)
	return arg_6_0.extraBuffs_ or {}
end

function var_0_0.speedY(arg_7_0, arg_7_1)
	if arg_7_0.yx == xyd.YXType.Yunsu or arg_7_0.arrived then
		return 0
	end

	local var_7_0 = arg_7_1 - arg_7_0.count

	if var_7_0 * arg_7_0.speed > math.abs(arg_7_0.xDis_) then
		return 0
	end

	local var_7_1 = math.abs(arg_7_0.xDis_ / arg_7_0.speed)

	if arg_7_0.yDis_ < 0 then
		local var_7_2 = var_0_1:y(arg_7_0.skillID)
		local var_7_3 = arg_7_0.yDis_
		local var_7_4 = (4 * math.sqrt(var_7_2 * var_7_2 - var_7_2 * var_7_3) + 4 * var_7_2 - 2 * var_7_3) / (-1 * var_7_1 * var_7_1)

		return math.sqrt(-2 * var_7_4 * var_7_2) + var_7_4 * var_7_0
	else
		local var_7_5 = var_0_1:y(arg_7_0.skillID)
		local var_7_6 = arg_7_0.yDis_
		local var_7_7 = -2 * (2 * math.sqrt(var_7_5 * var_7_5 - var_7_5 * var_7_6) - var_7_6 + 2 * var_7_5) / (var_7_1 * var_7_1)

		return math.sqrt(-2 * var_7_7 * var_7_5) + var_7_7 * var_7_0
	end
end

function var_0_0.speedX(arg_8_0, arg_8_1)
	if arg_8_0.xDis_ == 0 or arg_8_0.arrived then
		return 0
	end

	local var_8_0 = arg_8_1 - arg_8_0.count

	if arg_8_0.yx ~= xyd.YXType.Yunsu then
		return arg_8_0.speed
	end

	if #arg_8_0.accelerate_ < #arg_8_0.aTime_ then
		error("skill " .. arg_8_0.skillID .. " acceleration is nil")
	elseif #arg_8_0.accelerate_ > #arg_8_0.aTime_ + 1 then
		error("skill " .. arg_8_0.skillID .. " acceleration time is nil")
	end

	local var_8_1 = 0
	local var_8_2 = clone(arg_8_0.accelerate_)

	if #arg_8_0.accelerate_ > #arg_8_0.aTime_ then
		var_8_1 = arg_8_0.accelerate_[#arg_8_0.accelerate_]

		table.remove(var_8_2)
	end

	local var_8_3 = clone(arg_8_0.speed)

	for iter_8_0 = 1, #var_8_2 do
		if var_8_0 >= arg_8_0.aTime_[iter_8_0] and iter_8_0 == 1 then
			var_8_3 = var_8_3 + arg_8_0.aTime_[1] * arg_8_0.accelerate_[1]
		elseif var_8_0 >= arg_8_0.aTime_[iter_8_0] and iter_8_0 > 1 then
			var_8_3 = var_8_3 + (arg_8_0.aTime_[iter_8_0] - arg_8_0.aTime_[iter_8_0 - 1]) * arg_8_0.accelerate_[iter_8_0]
		elseif var_8_0 < arg_8_0.aTime_[iter_8_0] then
			if iter_8_0 > 2 then
				var_8_3 = var_8_3 + (var_8_0 - arg_8_0.aTime_[iter_8_0 - 1]) * arg_8_0.accelerate_[iter_8_0]

				break
			end

			var_8_3 = var_8_3 + var_8_0 * arg_8_0.accelerate_[iter_8_0]

			break
		end
	end

	if not next(arg_8_0.aTime_) then
		var_8_3 = var_8_3 + var_8_0 * var_8_1
	elseif var_8_0 > arg_8_0.aTime_[#arg_8_0.aTime_] then
		var_8_3 = var_8_3 + (var_8_0 - arg_8_0.aTime_[#arg_8_0.aTime_]) * var_8_1
	end

	return var_8_3
end

function var_0_0.movePosition(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_0.arrived or not arg_9_0.resource then
		return
	end

	local var_9_0

	if math.abs(arg_9_0:getX() - arg_9_0.desX_) <= arg_9_0:speedX(arg_9_1) then
		arg_9_0.arrived = true
		var_9_0 = {
			time = var_0_4,
			x = arg_9_0.desX_ - arg_9_0:getX(),
			y = arg_9_0.desY_ - arg_9_0:getY()
		}
	else
		var_9_0 = {
			time = var_0_4,
			x = arg_9_0:speedX(arg_9_1) * arg_9_0.xDis_ / math.abs(arg_9_0.xDis_),
			y = arg_9_0:speedY(arg_9_1)
		}
	end

	if arg_9_2 then
		var_9_0.onComplete = arg_9_2
	end

	transition.moveBy(arg_9_0.resource, var_9_0)
end

function var_0_0.movePositionReport(arg_10_0, arg_10_1, arg_10_2)
	if arg_10_0.arrived or not arg_10_0.resource then
		return
	end

	local var_10_0

	if math.abs(arg_10_0:getX() - arg_10_0.desX_) <= arg_10_0:speedX(arg_10_1) then
		arg_10_0.arrived = true
		var_10_0 = {
			time = var_0_4,
			x = arg_10_0.desX_ - arg_10_0:getX(),
			y = arg_10_0.desY_ - arg_10_0:getY()
		}
	else
		var_10_0 = {
			time = var_0_4,
			x = arg_10_0:speedX(arg_10_1) * arg_10_0.xDis_ / math.abs(arg_10_0.xDis_),
			y = arg_10_0:speedY(arg_10_1)
		}
	end

	if arg_10_2 then
		arg_10_2()
	end

	arg_10_0.resource:pos(arg_10_0:getX() + var_10_0.x, arg_10_0:getY() + var_10_0.y)
end

function var_0_0.rotate(arg_11_0, arg_11_1)
	if not arg_11_0.isRotate or arg_11_0.arrived or not arg_11_0.resource or tolua.isnull(arg_11_0.resource) then
		return
	end

	local var_11_0 = arg_11_0.resource:getRotationSkewX()
	local var_11_1 = math.atan2(arg_11_0:speedY(arg_11_1), arg_11_0:speedX(arg_11_1) * arg_11_0.xDis_ / math.abs(arg_11_0.xDis_)) / math.pi * -180

	if var_11_0 ~= var_11_1 then
		arg_11_0.resource:rotation(var_11_1)
	end
end

function var_0_0.rotateReport(arg_12_0, arg_12_1)
	if not arg_12_0.isRotate or arg_12_0.arrived or not arg_12_0.resource then
		return
	end

	local var_12_0 = arg_12_0.resource:getRotationSkewX()
	local var_12_1 = {
		time = 0,
		rotate = math.atan2(arg_12_0:speedY(arg_12_1), arg_12_0:speedX(arg_12_1) * arg_12_0.xDis_ / math.abs(arg_12_0.xDis_)) / math.pi * -180
	}

	if var_12_0 ~= var_12_1.rotate then
		arg_12_0.resource:rotation(var_12_1.rotate)
	end
end

function var_0_0.getIniPos(arg_13_0, arg_13_1)
	local var_13_0, var_13_1 = arg_13_0.fighter.fighterModel:getPosition()
	local var_13_2 = var_0_1:attackIndex(arg_13_0.skillID)
	local var_13_3 = arg_13_0.fighter:getFighterModel().attackPoints[var_13_2]

	if not var_13_3 then
		var_13_3 = arg_13_0.fighter:getFighterModel().attackPoints[1]

		print("attackPoint is nil " .. var_13_2)
	end

	if arg_13_1 == "x" then
		return var_13_0 + var_13_3.x
	elseif arg_13_1 == "y" then
		return var_13_1 + var_13_3.y
	else
		return var_13_0 + var_13_3.x, var_13_1 + var_13_3.y
	end
end

function var_0_0.getX(arg_14_0)
	if not arg_14_0.resource then
		return arg_14_0.desX_
	end

	return cc.p(arg_14_0.resource:getPosition()).x
end

function var_0_0.getY(arg_15_0)
	if not arg_15_0.resource then
		return arg_15_0.desY_
	end

	return cc.p(arg_15_0.resource:getPosition()).y
end

function var_0_0.createAttacks(arg_16_0, arg_16_1, arg_16_2)
	local function var_16_0(arg_17_0, arg_17_1)
		local var_17_0 = {
			fighter = arg_16_0.fighter,
			target = arg_17_0,
			count = arg_17_1,
			ackIndex = arg_16_0.ackIndex,
			isEnergySkill = arg_16_0.isEnergySkill,
			attrs = arg_16_0.fighter.attributes,
			skillID = arg_16_0.skillID
		}
		local var_17_1 = var_0_3.new(var_17_0)

		var_17_1:addExtraBuffs(arg_16_0:getExtraBuffs())

		return var_17_1
	end

	local var_16_1 = {}

	for iter_16_0, iter_16_1 in ipairs(arg_16_1) do
		local var_16_2 = var_16_0(iter_16_1, arg_16_2)

		table.insert(var_16_1, var_16_2)
	end

	return var_16_1
end

function var_0_0.setDesition(arg_18_0, arg_18_1, arg_18_2)
	arg_18_0.desX_ = arg_18_1 or arg_18_0.desX_
	arg_18_0.desY_ = arg_18_2 or arg_18_0.desY_

	arg_18_0:init()
end

function var_0_0.getSkillScope(arg_19_0)
	return var_0_1:scope(arg_19_0.skillID)
end

return var_0_0
