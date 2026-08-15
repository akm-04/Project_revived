local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("MoveUnit")
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("SkillEffect")
local var_0_6 = var_0_1.ctx.battle.getRequire("SkillNode")
local var_0_7 = var_0_1.ctx.battle.getRequire("AttackUnit")

function var_0_3.ctor(arg_1_0, arg_1_1)
	arg_1_0.fighter = arg_1_1.fighter
	arg_1_0.count = arg_1_1.count
	arg_1_0.skillID = arg_1_1.skillID
	arg_1_0.targets = {}
	arg_1_0.manualTargets_ = nil

	arg_1_0:setupBasic()
	arg_1_0:init()
	arg_1_0:getPathQueue()

	arg_1_0.recordIndex_ = nil
	arg_1_0.recordUnits_ = {}
	arg_1_0.arriveCount_ = nil
	arg_1_0.isReturn_ = false
end

function var_0_3.setupBasic(arg_2_0)
	arg_2_0.unitEffectType = var_0_4:unitEffectType(arg_2_0.skillID)

	local var_2_0, var_2_1 = var_0_4:unitResource(arg_2_0.skillID)

	if arg_2_0.unitEffectType == var_0_2.UnitEffectType.FollowFighter then
		arg_2_0.resource = var_0_6.new(arg_2_0.skillID, "unit", arg_2_0.fighter:getScale())

		arg_2_0.resource:retain()
	end

	if var_2_0 and var_2_0 ~= "" and var_2_1 and var_2_1 ~= "" and arg_2_0.unitEffectType ~= var_0_2.UnitEffectType.FollowFighter then
		arg_2_0.resource = var_0_1.ctx.battle.getSpine(arg_2_0.skillID, "unit", arg_2_0.fighter:getScale())
	end

	arg_2_0.arrived = false
	arg_2_0.xDis_ = var_0_4:distance(arg_2_0.skillID)

	if arg_2_0.fighter:getFlipX() then
		arg_2_0.xDis_ = arg_2_0.xDis_ * -1
	end

	arg_2_0.iniX_, arg_2_0.iniY_ = arg_2_0:getIniPos()
	arg_2_0.desX_ = arg_2_0:getIniPos("x") + arg_2_0.xDis_
	arg_2_0.desY_ = arg_2_0:getIniPos("y")
	arg_2_0.selectType = var_0_4:selectType(arg_2_0.skillID)
	arg_2_0.yx = var_0_4:yx(arg_2_0.skillID)
	arg_2_0.offY = var_0_4:y(arg_2_0.skillID)
	arg_2_0.isRotate = var_0_4:isRotate(arg_2_0.skillID)
	arg_2_0.speed = var_0_4:speed(arg_2_0.skillID)
	arg_2_0.aTime_ = var_0_4:aTime(arg_2_0.skillID)
	arg_2_0.accelerate_ = var_0_4:accelerate(arg_2_0.skillID)

	if arg_2_0.yx == var_0_2.YXType.Yunsuwangfan then
		if arg_2_0.xDis_ > 0 then
			if var_0_1.ctx.battle.isUnlimitBattle then
				arg_2_0.desX_ = var_0_2.UNLIMIT_STAGE_WIDTH
			else
				arg_2_0.desX_ = var_0_2.STAGE_WIDTH
			end
		else
			arg_2_0.desX_ = 0
		end
	end
end

function var_0_3.init(arg_3_0)
	arg_3_0.xDis_ = arg_3_0.desX_ - arg_3_0.iniX_
	arg_3_0.yDis_ = arg_3_0.desY_ - arg_3_0.iniY_

	if arg_3_0.yx == var_0_2.YXType.Paowuxian_Duration then
		arg_3_0.speed = math.abs(arg_3_0.xDis_ / var_0_2.tables.battleConfig.attackunitPaowuxianDuration)
	end
end

function var_0_3.getAreaResource(arg_4_0)
	if not arg_4_0.areaResource then
		local var_4_0, var_4_1 = var_0_4:areaResource(arg_4_0.skillID)

		if var_4_0 and var_4_0 ~= "" and var_4_1 and var_4_1 ~= "" then
			arg_4_0.areaResource = var_0_1.ctx.battle.getSpine(arg_4_0.skillID, "area", arg_4_0.fighter:getScale())
		end
	end

	return arg_4_0.areaResource
end

function var_0_3.speedY(arg_5_0, arg_5_1)
	if arg_5_0.xDis_ == 0 or arg_5_0.arrived then
		return 0
	end

	if arg_5_0.yx == var_0_2.YXType.Yunsu or arg_5_0.yx == var_0_2.YXType.Yunsuwangfan then
		local var_5_0 = arg_5_0:getDesPos("x") - arg_5_0:getX()

		var_5_0 = var_5_0 == 0 and 1 or var_5_0

		return (arg_5_0:getDesPos("y") - arg_5_0:getY()) / math.abs(var_5_0) * arg_5_0:speedX(arg_5_1)
	end
end

function var_0_3.speedX(arg_6_0, arg_6_1)
	if arg_6_0.xDis_ == 0 or arg_6_0.arrived then
		return 0
	end

	if arg_6_0.yx ~= var_0_2.YXType.Yunsu or arg_6_0.yx ~= var_0_2.YXType.Yunsuwangfan then
		return arg_6_0.speed
	end

	if #arg_6_0.accelerate_ < #arg_6_0.aTime_ then
		error("skill " .. arg_6_0.skillID .. " acceleration is nil")
	elseif #arg_6_0.accelerate_ > #arg_6_0.aTime_ + 1 then
		error("skill " .. arg_6_0.skillID .. " acceleration time is nil")
	end

	local var_6_0 = 0
	local var_6_1 = var_0_0.clone(arg_6_0.accelerate_)

	if #arg_6_0.accelerate_ > #arg_6_0.aTime_ then
		var_6_0 = arg_6_0.accelerate_[#arg_6_0.accelerate_]

		table.remove(var_6_1)
	end

	local var_6_2 = var_0_0.clone(arg_6_0.speed)

	for iter_6_0 = 1, #var_6_1 do
		if arg_6_1 >= arg_6_0.aTime_[iter_6_0] and iter_6_0 == 1 then
			var_6_2 = var_6_2 + arg_6_0.aTime_[1] * arg_6_0.accelerate_[1]
		elseif arg_6_1 >= arg_6_0.aTime_[iter_6_0] and iter_6_0 > 1 then
			var_6_2 = var_6_2 + (arg_6_0.aTime_[iter_6_0] - arg_6_0.aTime_[iter_6_0 - 1]) * arg_6_0.accelerate_[iter_6_0]
		elseif arg_6_1 < arg_6_0.aTime_[iter_6_0] then
			if iter_6_0 > 2 then
				var_6_2 = var_6_2 + (arg_6_1 - arg_6_0.aTime_[iter_6_0 - 1]) * arg_6_0.accelerate_[iter_6_0]

				break
			end

			var_6_2 = var_6_2 + arg_6_1 * arg_6_0.accelerate_[iter_6_0]

			break
		end
	end

	if not next(arg_6_0.aTime_) then
		var_6_2 = var_6_2 + arg_6_1 * var_6_0
	elseif arg_6_1 > arg_6_0.aTime_[#arg_6_0.aTime_] then
		var_6_2 = var_6_2 + (arg_6_1 - arg_6_0.aTime_[#arg_6_0.aTime_]) * var_6_0
	end

	return var_6_2
end

function var_0_3.getPathQueue(arg_7_0)
	local var_7_0 = var_0_2.tables.battleConfig.attackunitPaowuxianDuration
	local var_7_1 = math.min(math.abs(arg_7_0.xDis_), var_0_2.PAOWUXIAN_BASIC_DISTANCE) / var_0_2.PAOWUXIAN_BASIC_DISTANCE * var_7_0
	local var_7_2 = math.ceil(var_7_1)
	local var_7_3 = var_0_4:y(arg_7_0.skillID) * var_7_2 / var_7_0
	local var_7_4 = arg_7_0.yDis_
	local var_7_5 = arg_7_0.xDis_ / var_7_2

	local function var_7_6(arg_8_0, arg_8_1)
		if arg_7_0.yDis_ < 0 then
			local var_8_0 = (4 * math.sqrt(var_7_3 * var_7_3 - var_7_3 * var_7_4) + 4 * var_7_3 - 2 * var_7_4) / (-1 * arg_8_1 * arg_8_1)

			return math.sqrt(-2 * var_8_0 * var_7_3) + var_8_0 * arg_8_0
		else
			local var_8_1 = -2 * (2 * math.sqrt(var_7_3 * var_7_3 - var_7_3 * var_7_4) - var_7_4 + 2 * var_7_3) / (arg_8_1 * arg_8_1)

			return math.sqrt(-2 * var_8_1 * var_7_3) + var_8_1 * arg_8_0
		end
	end

	arg_7_0.pathQueue_ = {}

	if arg_7_0.yx == var_0_2.YXType.Paowuxian_Duration then
		for iter_7_0 = 1, var_7_2 do
			table.insert(arg_7_0.pathQueue_, {
				var_7_5,
				var_7_6(iter_7_0, var_7_2)
			})
		end
	elseif arg_7_0.yx == var_0_2.YXType.Paowuxian then
		if arg_7_0.speed <= 0 then
			return
		end

		local var_7_7 = math.ceil(math.abs(arg_7_0.xDis_ / arg_7_0.speed))

		for iter_7_1 = 1, var_7_7 do
			table.insert(arg_7_0.pathQueue_, {
				arg_7_0.speed,
				var_7_6(iter_7_1, var_7_7)
			})
		end
	end
end

function var_0_3.movePosition(arg_9_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and arg_9_0.reportData_.arriveCount and arg_9_0.reportData_.arriveCount <= var_0_1.ctx.battle.count + 1 then
		arg_9_0.arrived = true
	end

	if arg_9_0.unitEffectType == var_0_2.UnitEffectType.FollowFighter and arg_9_0.resource and not var_0_1.ctx.battle.isReleased(arg_9_0.resource) then
		arg_9_0.resource:pos(arg_9_0.fighter:getX(), arg_9_0.fighter:getY())

		return
	end

	if arg_9_0.xDis_ == 0 or arg_9_0.speed == 0 or arg_9_0.arrived or not arg_9_0.resource then
		return
	end

	arg_9_0.moveTime_ = (arg_9_0.moveTime_ or 0) + 1

	if arg_9_0.yx == var_0_2.YXType.Paowuxian_Duration or arg_9_0.yx == var_0_2.YXType.Paowuxian then
		if arg_9_0.pathQueue_[1] then
			arg_9_0:moveBy(unpack(arg_9_0.pathQueue_[1]))
			table.remove(arg_9_0.pathQueue_, 1)
		end

		if not next(arg_9_0.pathQueue_) then
			arg_9_0.arrived = var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType
		end

		return
	end

	if not arg_9_0.isResetToXY then
		if math.abs(arg_9_0:getX() - arg_9_0.desX_) <= arg_9_0:speedX(arg_9_0.moveTime_) then
			if arg_9_0.yx == var_0_2.YXType.Yunsuwangfan and not arg_9_0.isReturn_ then
				arg_9_0.isReturn_ = true

				if arg_9_0.desX_ > 0 then
					arg_9_0:setDesition(0, arg_9_0:getDesPos("y"))
				elseif var_0_1.ctx.battle.isUnlimitBattle then
					arg_9_0:setDesition(var_0_2.UNLIMIT_STAGE_WIDTH, arg_9_0:getDesPos("y"))
				else
					arg_9_0:setDesition(var_0_2.STAGE_WIDTH, arg_9_0:getDesPos("y"))
				end
			else
				arg_9_0.arrived = var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType

				arg_9_0.resource:pos(arg_9_0.desX_, arg_9_0.desY_)
			end
		else
			if arg_9_0:getX() == arg_9_0.desX_ then
				return
			end

			local var_9_0 = arg_9_0:speedX(arg_9_0.moveTime_) * (arg_9_0.desX_ - arg_9_0:getX()) / math.abs(arg_9_0:getX() - arg_9_0.desX_)
			local var_9_1 = arg_9_0:speedY(arg_9_0.moveTime_)

			arg_9_0:moveBy(var_9_0, var_9_1)
		end

		return
	end

	if math.abs(arg_9_0:getX() - arg_9_0:getDesPos("x")) <= arg_9_0:speedX(arg_9_0.moveTime_) then
		if arg_9_0.yx == var_0_2.YXType.Yunsuwangfan and not arg_9_0.isReturn_ then
			arg_9_0.isReturn_ = true

			if arg_9_0.desX_ > 0 then
				arg_9_0:setDesition(0, arg_9_0:getDesPos("y"))
			elseif var_0_1.ctx.battle.isUnlimitBattle then
				arg_9_0:setDesition(var_0_2.UNLIMIT_STAGE_WIDTH, arg_9_0:getDesPos("y"))
			else
				arg_9_0:setDesition(var_0_2.STAGE_WIDTH, arg_9_0:getDesPos("y"))
			end
		else
			arg_9_0.arrived = var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType

			arg_9_0.resource:pos(arg_9_0:getDesPos("x"), arg_9_0:getDesPos("y"))
		end
	else
		if arg_9_0:getDesPos("x") == arg_9_0:getX() then
			return
		end

		local var_9_2 = arg_9_0:speedX(arg_9_0.moveTime_) * (arg_9_0:getDesPos("x") - arg_9_0:getX()) / math.abs(arg_9_0:getDesPos("x") - arg_9_0:getX())
		local var_9_3 = arg_9_0:speedY(arg_9_0.moveTime_)

		arg_9_0:moveBy(var_9_2, var_9_3)
	end
end

function var_0_3.rotate(arg_10_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_10_0.isRotate or arg_10_0.arrived or not arg_10_0.resource or var_0_1.ctx.battle.isReleased(arg_10_0.resource) then
		return
	end

	if arg_10_0.unitEffectType == var_0_2.UnitEffectType.FollowFighter then
		return
	end

	local var_10_0 = arg_10_0.moveTime_ or 1
	local var_10_1 = 0
	local var_10_2 = 0

	if arg_10_0.yx == var_0_2.YXType.Paowuxian_Duration or arg_10_0.yx == var_0_2.YXType.Paowuxian then
		if arg_10_0.pathQueue_[1] then
			var_10_1, var_10_2 = unpack(arg_10_0.pathQueue_[1])
		end
	else
		var_10_1, var_10_2 = arg_10_0:speedX(var_10_0), arg_10_0:speedY(var_10_0)
		var_10_1 = var_10_1 * arg_10_0.xDis_ / math.abs(arg_10_0.xDis_)
	end

	local var_10_3 = arg_10_0.resource:getRotationSkewX()
	local var_10_4 = var_10_1
	local var_10_5 = var_10_2

	if var_10_1 < 0 then
		arg_10_0.resource:flipX(true)

		var_10_5 = -var_10_2
		var_10_4 = -var_10_1
	else
		arg_10_0.resource:flipX(false)
	end

	local var_10_6 = math.atan2(var_10_5, var_10_4) / math.pi * -180

	if var_10_3 ~= var_10_6 then
		arg_10_0.resource:rotation(var_10_6)
	end
end

function var_0_3.moveBy(arg_11_0, arg_11_1, arg_11_2)
	if not arg_11_0.resource or var_0_1.ctx.battle.isReleased(arg_11_0.resource) then
		return
	end

	local var_11_0, var_11_1 = arg_11_0.resource:getPosition()

	arg_11_0.resource:pos(var_11_0 + arg_11_1, var_11_1 + arg_11_2)
end

function var_0_3.getIniPos(arg_12_0, arg_12_1)
	local var_12_0, var_12_1 = arg_12_0.fighter:getPos()
	local var_12_2 = var_0_4:attackIndex(arg_12_0.skillID)
	local var_12_3 = arg_12_0.fighter:getAttackPoint(var_12_2) or arg_12_0.fighter:getAttackPoint(1)

	if arg_12_0.unitEffectType == var_0_2.UnitEffectType.FollowFighter then
		var_12_3.x = 0
	end

	if arg_12_1 == "x" then
		return var_12_0 + var_12_3.x
	elseif arg_12_1 == "y" then
		return var_12_1 + var_12_3.y
	else
		return var_12_0 + var_12_3.x, var_12_1 + var_12_3.y
	end
end

function var_0_3.getDesPos(arg_13_0, arg_13_1)
	if arg_13_1 == "x" then
		return arg_13_0.desX_
	elseif arg_13_1 == "y" then
		return arg_13_0.desY_
	else
		return arg_13_0.desX_, arg_13_0.desY_
	end
end

function var_0_3.getX(arg_14_0)
	if not arg_14_0.resource then
		return arg_14_0.desX_
	end

	return arg_14_0.resource:getX()
end

function var_0_3.getY(arg_15_0)
	if not arg_15_0.resource then
		return arg_15_0.desY_
	end

	return arg_15_0.resource:getY()
end

function var_0_3.createAttacks(arg_16_0, arg_16_1)
	local function var_16_0(arg_17_0)
		local var_17_0 = {
			fighter = arg_16_0.fighter,
			target = arg_17_0,
			attrs = arg_16_0.fighter.attributes,
			skillID = arg_16_0.skillID
		}

		return (var_0_7.new(var_17_0))
	end

	local var_16_1 = {}

	for iter_16_0, iter_16_1 in ipairs(arg_16_1) do
		local var_16_2 = var_16_0(iter_16_1)

		table.insert(var_16_1, var_16_2)
		table.insert(arg_16_0.recordUnits_, var_16_2)
		table.insert(arg_16_0.fighter.records_.attackunit, var_16_2)

		var_16_2.recordIndex_ = #arg_16_0.fighter.records_.attackunit
	end

	return var_16_1
end

function var_0_3.setDesition(arg_18_0, arg_18_1, arg_18_2)
	arg_18_0.desX_ = arg_18_1 or arg_18_0.desX_
	arg_18_0.desY_ = arg_18_2 or arg_18_0.desY_

	arg_18_0:init()
end

function var_0_3.getSkillScope(arg_19_0)
	return var_0_4:scope(arg_19_0.skillID)
end

function var_0_3.arrive(arg_20_0)
	arg_20_0.arriveCount_ = var_0_1.ctx.battle.count
end

function var_0_3.writeReport(arg_21_0)
	arg_21_0.records_ = {}
	arg_21_0.records_.skillID = arg_21_0.skillID
	arg_21_0.records_.start = arg_21_0.count
	arg_21_0.records_.arriveCount = arg_21_0.arriveCount_
	arg_21_0.records_.units = {}

	for iter_21_0, iter_21_1 in ipairs(arg_21_0.recordUnits_) do
		table.insert(arg_21_0.records_.units, iter_21_1:writeReport())
	end

	arg_21_0.records_.recordIndex = arg_21_0.recordIndex_

	return arg_21_0.records_
end

function var_0_3.readReport(arg_22_0, arg_22_1)
	local var_22_0 = arg_22_1.unit

	arg_22_0.recordIndex_ = tonumber(arg_22_1.recordIndex)
	arg_22_0.reportData_ = {}
	arg_22_0.reportData_.arriveCount = tonumber(var_22_0.arriveCount)
	arg_22_0.reportData_.units = {}
	arg_22_0.reportData_.pos = arg_22_1.pos

	for iter_22_0, iter_22_1 in ipairs(var_22_0.units) do
		local var_22_1 = {
			skillID = tonumber(iter_22_1.skillID),
			fighter = arg_22_0.fighter,
			target = var_0_1.ctx.battle.getFighter(iter_22_1.initTarget),
			count = tonumber(iter_22_1.start),
			reportdata = iter_22_1
		}
		local var_22_2 = var_0_7.new(var_22_1)

		table.insert(arg_22_0.reportData_.units, var_22_2)
	end
end

function var_0_3.getReportUnits(arg_23_0)
	if next(arg_23_0.reportData_.units) == nil then
		return {}
	end

	local var_23_0 = {}
	local var_23_1 = arg_23_0.reportData_.units[1]

	while var_23_1 and var_23_1.count <= var_0_1.ctx.battle.count do
		table.insert(var_23_0, var_23_1)
		table.remove(arg_23_0.reportData_.units, 1)

		var_23_1 = arg_23_0.reportData_.units[1]
	end

	return var_23_0
end

return var_0_3
