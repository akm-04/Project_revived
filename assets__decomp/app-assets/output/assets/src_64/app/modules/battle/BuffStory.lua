local var_0_0 = xyd.tables.dbuff
local var_0_1 = class("Buff")

function var_0_1.ctor(arg_1_0, arg_1_1)
	arg_1_0.tableID_ = arg_1_1.tableID
	arg_1_0.startCount_ = arg_1_1.start
	arg_1_0.level_ = arg_1_1.level
	arg_1_0.skillID_ = arg_1_1.skillID
	arg_1_0.fighter = arg_1_1.fighter
	arg_1_0.target = arg_1_1.target

	arg_1_0:init()

	arg_1_0.filterColor_ = {}
	arg_1_0.filterColor_[1] = {
		color = cc.c4f(0.8, 0.9, 1.2, 1)
	}
	arg_1_0.filterColor_[2] = {
		color = cc.c4f(0.5, 0.5, 0.5, 1)
	}
	arg_1_0.filterColor_[3] = {
		color = cc.c4f(0.6, 1, 0.6, 1)
	}
	arg_1_0.filterColor_[4] = {
		transparent = 180
	}
	arg_1_0.filterColor_[5] = {
		transparent = 0
	}
end

function var_0_1.init(arg_2_0)
	arg_2_0:setIsHit()
end

function var_0_1.getTableID(arg_3_0)
	return arg_3_0.tableID_
end

function var_0_1.getSkillID(arg_4_0)
	return arg_4_0.skillID_
end

function var_0_1.getLevel(arg_5_0)
	return arg_5_0.level_
end

function var_0_1.getDesc(arg_6_0)
	return var_0_0:desc(arg_6_0:getTableID())
end

function var_0_1.getStartTime(arg_7_0)
	return arg_7_0.startCount_
end

function var_0_1.getType(arg_8_0)
	return var_0_0:type(arg_8_0:getTableID())
end

function var_0_1.getTime(arg_9_0)
	return var_0_0:time(arg_9_0:getTableID()) + arg_9_0.level_ * arg_9_0:getTimeStep()
end

function var_0_1.getTimeStep(arg_10_0)
	return var_0_0:timeStep(arg_10_0:getTableID())
end

function var_0_1.isCover(arg_11_0)
	return var_0_0:isCover(arg_11_0:getTableID())
end

function var_0_1.getFloatText(arg_12_0)
	return var_0_0:floatText(arg_12_0:getTableID())
end

function var_0_1.getRemoveSkill(arg_13_0)
	return var_0_0:removeSkill(arg_13_0:getTableID())
end

function var_0_1.isBack(arg_14_0)
	return var_0_0:isBack(arg_14_0:getTableID())
end

function var_0_1.canCopy(arg_15_0)
	return var_0_0:canCopy(arg_15_0:getTableID())
end

function var_0_1.getDmpRate(arg_16_0)
	return var_0_0:dmpRateInit(arg_16_0:getTableID()) + var_0_0:dmpRateStep(arg_16_0:getTableID()) * arg_16_0:getLevel()
end

function var_0_1.setDirection(arg_17_0, arg_17_1)
	if arg_17_1 then
		arg_17_0.dir_ = -1
	else
		arg_17_0.dir_ = 1
	end
end

function var_0_1.getDirection(arg_18_0)
	return arg_18_0.dir_
end

function var_0_1.getResource(arg_19_0)
	if not arg_19_0.sp_ then
		local var_19_0, var_19_1, var_19_2 = var_0_0:effectResource(arg_19_0:getTableID())

		if var_19_0 and var_19_1 and var_19_0 ~= "" and var_19_1 ~= "" then
			arg_19_0.sp_ = sp.SkeletonAnimation:create(var_19_0, var_19_1, var_19_2)
		end
	end

	return arg_19_0.sp_
end

function var_0_1.position(arg_20_0)
	return var_0_0:position(arg_20_0:getTableID())
end

function var_0_1.resetYXChange(arg_21_0, arg_21_1, arg_21_2)
	if arg_21_1 then
		arg_21_0.resetXchange_ = (arg_21_1 - arg_21_0.target:getX()) * arg_21_0:getDirection()
	end

	if arg_21_2 then
		arg_21_0.resetYChange_ = arg_21_2 - arg_21_0.target:getY()
	end
end

function var_0_1.Xchange(arg_22_0)
	if arg_22_0.resetXchange_ then
		return arg_22_0.resetXchange_
	end

	return var_0_0:x(arg_22_0:getTableID())
end

function var_0_1.Ychange(arg_23_0)
	if arg_23_0.resetYchange_ then
		return arg_23_0.resetYchange_
	end

	return var_0_0:y(arg_23_0:getTableID())
end

function var_0_1.getYx(arg_24_0)
	return var_0_0:yx(arg_24_0:getTableID())
end

function var_0_1.getMoveByX(arg_25_0, arg_25_1, arg_25_2)
	local function var_25_0()
		return arg_25_0:Xchange() / arg_25_0:getTime()
	end

	local function var_25_1()
		return arg_25_0:Xchange() / arg_25_0:getTime()
	end

	local function var_25_2(arg_28_0)
		local var_28_0 = 2 * arg_25_0:Xchange() / (arg_25_0:getTime() * arg_25_0:getTime())

		if arg_28_0 <= arg_25_0:getTime() then
			return var_28_0 * arg_28_0
		else
			return 0
		end
	end

	local function var_25_3()
		return arg_25_0:Xchange() / arg_25_0:getTime()
	end

	local function var_25_4()
		return 2 * arg_25_0:Xchange() / arg_25_0:getTime()
	end

	if arg_25_0:getYx() < 1 or math.abs(arg_25_0:Xchange()) < 1 or arg_25_1 > arg_25_0:getTime() + arg_25_0:getStartTime() then
		return 0
	end

	if arg_25_0:getYx() == xyd.YXType.Yunsu then
		return var_25_0()
	elseif arg_25_0:getYx() == xyd.YXType.Paowuxian then
		return var_25_1()
	elseif arg_25_0:getYx() == xyd.YXType.Yunjiasu then
		return var_25_2(arg_25_1 - arg_25_0.startCount_)
	elseif arg_25_0:getYx() == xyd.YXType.YunsuWangfan then
		return var_25_3()
	elseif arg_25_0:getYx() == xyd.YXType.YunsuXwangfan then
		if arg_25_1 - arg_25_0.startCount_ < arg_25_0:getTime() / 2 then
			return var_25_4()
		else
			return -1 * var_25_4()
		end
	end
end

function var_0_1.getMoveByY(arg_31_0, arg_31_1)
	local function var_31_0()
		return arg_31_0:Ychange() / arg_31_0:getTime()
	end

	local function var_31_1(arg_33_0)
		local var_33_0 = -8 * arg_31_0:Ychange() / (arg_31_0:getTime() * arg_31_0:getTime())
		local var_33_1 = 4 * arg_31_0:Ychange() / arg_31_0:getTime() + var_33_0 * arg_33_0

		if arg_33_0 > arg_31_0:getTime() then
			var_33_1 = 0
		end

		return var_33_1
	end

	local function var_31_2(arg_34_0)
		local var_34_0 = 2 * arg_31_0:Ychange() / (arg_31_0:getTime() * arg_31_0:getTime())

		if arg_34_0 <= arg_31_0:getTime() then
			return var_34_0 * arg_34_0
		else
			return 0
		end
	end

	local function var_31_3()
		return 2 * arg_31_0:Ychange() / arg_31_0:getTime()
	end

	if arg_31_0:getYx() < 1 or arg_31_0:Ychange() < 1 or arg_31_1 > arg_31_0:getTime() + arg_31_0:getStartTime() then
		return 0
	end

	if arg_31_0:getYx() == xyd.YXType.Yunsu then
		return var_31_0()
	elseif arg_31_0:getYx() == xyd.YXType.Paowuxian then
		return var_31_1(arg_31_1 - arg_31_0.startCount_)
	elseif arg_31_0:getYx() == xyd.YXType.Yunjiasu then
		return var_31_2(arg_31_1 - arg_31_0.startCount_)
	elseif arg_31_0:getYx() == xyd.YXType.YunsuWangfan then
		if arg_31_1 - arg_31_0.startCount_ > arg_31_0:getTime() / 2 then
			return var_31_3()
		else
			return -1 * var_31_3()
		end
	elseif arg_31_0:getYx() == xyd.YXType.YunsuXwangfan then
		return 0
	end
end

function var_0_1.canBreakSkill(arg_36_0, arg_36_1)
	if arg_36_1 == "ap" then
		return var_0_0:apUnable(arg_36_0:getTableID())
	elseif arg_36_1 == "ad" then
		return var_0_0:adUnable(arg_36_0:getTableID())
	end

	return false
end

function var_0_1.canMiss(arg_37_0)
	return var_0_0:canMiss(arg_37_0:getTableID())
end

function var_0_1.setIsHit(arg_38_0, arg_38_1)
	if not arg_38_0:canMiss() then
		arg_38_0.isHit_ = true
	else
		arg_38_0.isHit_ = arg_38_1
	end
end

function var_0_1.isHit(arg_39_0)
	return arg_39_0.isHit_
end

function var_0_1.getFilter(arg_40_0)
	local var_40_0 = var_0_0:filterColor(arg_40_0:getTableID())

	if var_40_0 <= 0 then
		return
	end

	return arg_40_0.filterColor_[var_40_0]
end

function var_0_1.isYongJiu(arg_41_0)
	return arg_41_0.isYongJiu_
end

function var_0_1.setYongJiu(arg_42_0)
	arg_42_0.isYongJiu_ = true
end

function var_0_1.showEffect(arg_43_0)
	return arg_43_0.showEffect_
end

function var_0_1.setShowEffect(arg_44_0)
	arg_44_0.showEffect_ = true
end

function var_0_1.getAttrType(arg_45_0)
	return var_0_0:attr(arg_45_0:getTableID())
end

function var_0_1.isAffected(arg_46_0)
	return var_0_0:affected(arg_46_0:getTableID())
end

function var_0_1.isMoveUnable(arg_47_0)
	return var_0_0:moveUnable(arg_47_0:getTableID())
end

function var_0_1.isApUnable(arg_48_0)
	return var_0_0:apUnable(arg_48_0:getTableID())
end

function var_0_1.isAdUnable(arg_49_0)
	return var_0_0:adUnable(arg_49_0:getTableID())
end

function var_0_1.isExcuteAdCircle(arg_50_0)
	return var_0_0:noSkip(arg_50_0:getTableID()) and arg_50_0:isAdUnable()
end

function var_0_1.isExcuteApCircle(arg_51_0)
	return var_0_0:noSkip(arg_51_0:getTableID()) and arg_51_0:isApUnable()
end

function var_0_1.isApImmortal(arg_52_0)
	return var_0_0:isApImmortal(arg_52_0:getTableID())
end

function var_0_1.isAdImmortal(arg_53_0)
	return var_0_0:isAdImmortal(arg_53_0:getTableID())
end

function var_0_1.isAttackFriend(arg_54_0)
	return var_0_0:attackFriend(arg_54_0:getTableID())
end

function var_0_1.isAdBreakImmortal(arg_55_0)
	return var_0_0:isAdBreakImmortal(arg_55_0:getTableID())
end

function var_0_1.pause(arg_56_0)
	return var_0_0:pause(arg_56_0:getTableID())
end

function var_0_1.initAttr(arg_57_0)
	local var_57_0, var_57_1 = var_0_0:init(arg_57_0:getTableID())

	return var_57_0, var_57_1
end

function var_0_1.step(arg_58_0)
	return var_0_0:step(arg_58_0:getTableID())
end

function var_0_1.dHarmType(arg_59_0)
	return var_0_0:dHarmType(arg_59_0:getTableID())
end

function var_0_1.stepHarm(arg_60_0)
	return var_0_0:stepHarm(arg_60_0:getTableID())
end

function var_0_1.harmToHP(arg_61_0)
	return var_0_0:harmToHP(arg_61_0:getTableID())
end

function var_0_1.getAttr(arg_62_0)
	local var_62_0, var_62_1 = arg_62_0:initAttr()

	return var_62_0 + arg_62_0.level_ * arg_62_0:step(), var_62_1
end

function var_0_1.totalDHarm(arg_63_0)
	return math.max(var_0_0:dHarm(arg_63_0:getTableID()) + arg_63_0.level_ * arg_63_0:stepHarm(), 0)
end

function var_0_1.isDHarmLast(arg_64_0)
	return var_0_0:isDHarmLast(arg_64_0:getTableID())
end

function var_0_1.getDHarm(arg_65_0)
	if not arg_65_0.dHarm_ then
		arg_65_0.dHarm_ = arg_65_0:totalDHarm()
	end

	return arg_65_0.dHarm_
end

function var_0_1.setDHarm(arg_66_0, arg_66_1)
	if not arg_66_0.dHarm_ then
		return
	end

	local var_66_0 = arg_66_0.dHarm_

	arg_66_0.dHarm_ = math.max(arg_66_0.dHarm_ - arg_66_1, 0)

	if arg_66_0.dHarm_ > 0 then
		return 0
	else
		return var_66_0
	end
end

function var_0_1.getHarm(arg_67_0)
	if not arg_67_0.target or not arg_67_0.fighter then
		return 0
	end

	local var_67_0 = var_0_0:baseHarm(arg_67_0:getTableID())
	local var_67_1 = var_0_0:stepBase(arg_67_0:getTableID())
	local var_67_2 = var_0_0:ap(arg_67_0:getTableID())

	if var_67_0 == 0 and var_67_1 == 0 and var_67_2 == 0 then
		return 0
	end

	local var_67_3 = var_67_0 + var_67_1 * arg_67_0.level_ + arg_67_0.fighter:getAP() * var_67_2
	local var_67_4 = var_67_3

	if arg_67_0:getType() == xyd.BuffType.CONTINUE_HARM then
		local var_67_5 = math.max(arg_67_0.target:getMoKang() - arg_67_0.fighter:getDMoKang(), 0)

		var_67_4 = var_67_3 * var_67_3 / (var_67_3 + 8 * var_67_5)
	end

	return var_67_4
end

function var_0_1.playRemoveSkill(arg_68_0)
	if arg_68_0:getRemoveSkill() <= 0 then
		return
	end

	local var_68_0 = {
		skillID = arg_68_0:getRemoveSkill(),
		buffTarget = arg_68_0.target
	}

	table.insert(arg_68_0.fighter.specialSkills, var_68_0)
end

function var_0_1.isAct(arg_69_0)
	return var_0_0:isAct(arg_69_0:getTableID())
end

function var_0_1.actNum(arg_70_0)
	return var_0_0:actNum(arg_70_0:getTableID())
end

function var_0_1.ignoreFlip(arg_71_0)
	return var_0_0:ignoreFlip(arg_71_0:getTableID()) == 1
end

return var_0_1
