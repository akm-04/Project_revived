local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_2.tables.dbuff
local var_0_4 = var_0_0.class("Buff")

function var_0_4.ctor(arg_1_0, arg_1_1)
	arg_1_0.tableID_ = arg_1_1.tableID
	arg_1_0.startCount_ = arg_1_1.start
	arg_1_0.level_ = arg_1_1.level
	arg_1_0.skillID_ = arg_1_1.skillID
	arg_1_0.fighter = arg_1_1.fighter
	arg_1_0.target = arg_1_1.target

	if arg_1_0.fighter and arg_1_0.tableID_ == 0 and var_0_2.db then
		local var_1_0 = "buff id error, fighter: " .. arg_1_0.fighter.__cname

		if arg_1_0.fighter.fighterIndex then
			var_1_0 = var_1_0 .. "," .. arg_1_0.fighter.fighterIndex
		end

		var_0_2.db.errorLog:add(var_1_0)
	end

	arg_1_0.manualRevise = arg_1_1.manualRevise or 0
	arg_1_0.manualHarmRevise = arg_1_1.manualHarmRevise or 0
	arg_1_0.manualDharm = arg_1_1.manualDharm or 0
	arg_1_0.manualSpGiveRate = arg_1_1.manualSpGiveRate or 0
	arg_1_0.manualMp = arg_1_1.manualMp or 0
	arg_1_0.extraTime_ = 0
	arg_1_0.shieldNum_ = 0
	arg_1_0.manulFilter_ = {}

	arg_1_0:init()

	arg_1_0.filterColor_ = {
		{},
		{},
		{},
		{},
		{},
		{}
	}

	if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.CreateReport then
		arg_1_0.filterColor_[1] = {
			color = cc.c4f(0.8, 0.9, 1.2, 1)
		}
		arg_1_0.filterColor_[2] = {
			color = cc.c4f(0.5, 0.5, 0.5, 1)
		}
		arg_1_0.filterColor_[3] = {
			color = cc.c4f(0.6, 1, 0.6, 1)
		}
		arg_1_0.filterColor_[6] = {
			color = cc.c4f(1, 0.88, 0.46, 1)
		}
	end

	arg_1_0.filterColor_[4] = {
		transparent = 180
	}
	arg_1_0.filterColor_[5] = {
		transparent = 0
	}
	arg_1_0.leftCount_ = arg_1_0:getTime()
end

function var_0_4.init(arg_2_0)
	arg_2_0:setIsHit()
	arg_2_0:setDirection()

	if arg_2_0:isShieldBuff() then
		local var_2_0 = math.floor(arg_2_0:initAttr() + arg_2_0:step() * arg_2_0.level_)

		arg_2_0:setShieldNum(var_2_0)
	end
end

function var_0_4.getTableID(arg_3_0)
	return arg_3_0.tableID_
end

function var_0_4.getSkillID(arg_4_0)
	return arg_4_0.skillID_
end

function var_0_4.getLevel(arg_5_0)
	return arg_5_0.level_
end

function var_0_4.getDesc(arg_6_0)
	return var_0_3:desc(arg_6_0:getTableID())
end

function var_0_4.getStartTime(arg_7_0)
	return arg_7_0.startCount_
end

function var_0_4.getType(arg_8_0)
	return var_0_3:type(arg_8_0:getTableID())
end

function var_0_4.getTime(arg_9_0)
	if arg_9_0:isYongJiu() then
		return 10000
	end

	return var_0_3:time(arg_9_0:getTableID()) + arg_9_0.level_ * arg_9_0:getTimeStep() + arg_9_0.extraTime_
end

function var_0_4.setExtraTime(arg_10_0, arg_10_1)
	arg_10_0.extraTime_ = arg_10_1
	arg_10_0.leftCount_ = arg_10_0:getTime()
end

function var_0_4.setLeftCount(arg_11_0, arg_11_1)
	arg_11_0.leftCount_ = arg_11_1
end

function var_0_4.getLeftCount(arg_12_0)
	return arg_12_0.leftCount_
end

function var_0_4.getTimeStep(arg_13_0)
	return var_0_3:timeStep(arg_13_0:getTableID())
end

function var_0_4.isCover(arg_14_0)
	return var_0_3:isCover(arg_14_0:getTableID())
end

function var_0_4.getFloatText(arg_15_0)
	return var_0_3:floatText(arg_15_0:getTableID())
end

function var_0_4.getRemoveSkill(arg_16_0)
	return var_0_3:removeSkill(arg_16_0:getTableID())
end

function var_0_4.isBack(arg_17_0)
	return var_0_3:isBack(arg_17_0:getTableID())
end

function var_0_4.canCopy(arg_18_0)
	return var_0_3:canCopy(arg_18_0:getTableID())
end

function var_0_4.getDmpRate(arg_19_0)
	return var_0_3:dmpRateInit(arg_19_0:getTableID()) + var_0_3:dmpRateStep(arg_19_0:getTableID()) * arg_19_0:getLevel()
end

function var_0_4.setDirection(arg_20_0, arg_20_1)
	if arg_20_1 then
		arg_20_0.dir_ = -1
	else
		arg_20_0.dir_ = 1
	end
end

function var_0_4.getDirection(arg_21_0)
	return arg_21_0.dir_
end

function var_0_4.getResource(arg_22_0)
	if not arg_22_0.sp_ then
		local var_22_0, var_22_1, var_22_2 = var_0_3:effectResource(arg_22_0:getTableID())

		if var_22_0 and var_22_1 and var_22_0 ~= "" and var_22_1 ~= "" then
			arg_22_0.sp_ = sp.SkeletonAnimation:create(var_22_0, var_22_1, var_22_2)
		end
	end

	return arg_22_0.sp_
end

function var_0_4.position(arg_23_0)
	return var_0_3:position(arg_23_0:getTableID())
end

function var_0_4.resetYXChange(arg_24_0, arg_24_1, arg_24_2)
	if arg_24_1 then
		arg_24_0.resetXchange_ = math.abs(arg_24_1 - arg_24_0.target:getX())
	end

	if arg_24_2 then
		arg_24_0.resetYChange_ = arg_24_2 - arg_24_0.target:getY()
	end
end

function var_0_4.Xchange(arg_25_0)
	if arg_25_0.resetXchange_ then
		return arg_25_0.resetXchange_
	end

	return var_0_3:x(arg_25_0:getTableID())
end

function var_0_4.Ychange(arg_26_0)
	if arg_26_0.resetYchange_ then
		return arg_26_0.resetYchange_
	end

	return var_0_3:y(arg_26_0:getTableID())
end

function var_0_4.getYx(arg_27_0)
	return var_0_3:yx(arg_27_0:getTableID())
end

function var_0_4.getMoveByX(arg_28_0, arg_28_1, arg_28_2)
	local function var_28_0()
		return arg_28_0:Xchange() / arg_28_0:getTime()
	end

	local function var_28_1()
		return arg_28_0:Xchange() / arg_28_0:getTime()
	end

	local function var_28_2(arg_31_0)
		local var_31_0 = 2 * arg_28_0:Xchange() / (arg_28_0:getTime() * arg_28_0:getTime())

		if arg_31_0 <= arg_28_0:getTime() then
			return var_31_0 * arg_31_0
		else
			return 0
		end
	end

	local function var_28_3()
		return arg_28_0:Xchange() / arg_28_0:getTime()
	end

	local function var_28_4()
		return 2 * arg_28_0:Xchange() / arg_28_0:getTime()
	end

	local function var_28_5()
		return arg_28_0:Xchange() / arg_28_0:getTime()
	end

	if arg_28_0:getYx() < 1 or math.abs(arg_28_0:Xchange()) < 1 or arg_28_1 > arg_28_0:getTime() then
		return 0
	end

	if arg_28_0:getYx() == var_0_2.YXType.Yunsu then
		return var_28_0()
	elseif arg_28_0:getYx() == var_0_2.YXType.Paowuxian then
		return var_28_1()
	elseif arg_28_0:getYx() == var_0_2.YXType.Yunjiasu then
		return var_28_2(arg_28_1)
	elseif arg_28_0:getYx() == var_0_2.YXType.YunsuWangfan then
		return var_28_3()
	elseif arg_28_0:getYx() == var_0_2.YXType.YunsuXwangfan then
		if arg_28_1 <= arg_28_0:getTime() / 2 then
			return var_28_4()
		else
			return -1 * var_28_4()
		end
	elseif arg_28_0:getYx() == var_0_2.YXType.ShangXiaTingZhi then
		return var_28_5(arg_28_1)
	end
end

function var_0_4.getMoveByY(arg_35_0, arg_35_1)
	local function var_35_0()
		return arg_35_0:Ychange() / arg_35_0:getTime()
	end

	local function var_35_1(arg_37_0)
		local var_37_0 = -8 * arg_35_0:Ychange() / (arg_35_0:getTime() * arg_35_0:getTime())
		local var_37_1 = 4 * arg_35_0:Ychange() / arg_35_0:getTime() + var_37_0 * arg_37_0

		if arg_37_0 > arg_35_0:getTime() then
			var_37_1 = 0
		end

		return var_37_1
	end

	local function var_35_2(arg_38_0)
		local var_38_0 = 2 * arg_35_0:Ychange() / (arg_35_0:getTime() * arg_35_0:getTime())

		if arg_38_0 <= arg_35_0:getTime() then
			return var_38_0 * arg_38_0
		else
			return 0
		end
	end

	local function var_35_3()
		return 2 * arg_35_0:Ychange() / arg_35_0:getTime()
	end

	local function var_35_4(arg_40_0)
		if arg_40_0 <= arg_35_0:getTime() / 6 then
			return arg_35_0:Ychange() * 6 / arg_35_0:getTime()
		elseif arg_40_0 >= 5 * arg_35_0:getTime() / 6 then
			return -arg_35_0:Ychange() * 6 / arg_35_0:getTime()
		end

		return 0
	end

	if arg_35_0:getYx() < 1 or math.abs(arg_35_0:Ychange()) < 1 or arg_35_1 > arg_35_0:getTime() then
		return 0
	end

	if arg_35_0:getYx() == var_0_2.YXType.Yunsu then
		return var_35_0()
	elseif arg_35_0:getYx() == var_0_2.YXType.Paowuxian then
		return var_35_1(arg_35_1)
	elseif arg_35_0:getYx() == var_0_2.YXType.Yunjiasu then
		return var_35_2(arg_35_1)
	elseif arg_35_0:getYx() == var_0_2.YXType.YunsuWangfan then
		if arg_35_1 >= arg_35_0:getTime() / 2 then
			return var_35_3()
		else
			return -1 * var_35_3()
		end
	elseif arg_35_0:getYx() == var_0_2.YXType.YunsuXwangfan then
		return 0
	elseif arg_35_0:getYx() == var_0_2.YXType.ShangXiaTingZhi then
		return var_35_4(arg_35_1)
	end
end

function var_0_4.getPath(arg_41_0)
	if arg_41_0:getYx() < 1 then
		return {}
	end

	arg_41_0.movePath_ = {}

	for iter_41_0 = 1, arg_41_0:getTime() do
		arg_41_0.movePath_[iter_41_0] = {
			arg_41_0:getMoveByX(iter_41_0) * arg_41_0:getDirection(),
			arg_41_0:getMoveByY(iter_41_0)
		}
	end

	if arg_41_0:getTime() % 2 < 1 and arg_41_0:getYx() == var_0_2.YXType.Paowuxian then
		table.insert(arg_41_0.movePath_, 1, {
			arg_41_0:getMoveByX(0) * arg_41_0:getDirection(),
			arg_41_0:getMoveByY(0)
		})
	end

	return arg_41_0.movePath_
end

function var_0_4.canBreakSkill(arg_42_0, arg_42_1)
	if arg_42_1 == "ap" then
		return var_0_3:apUnable(arg_42_0:getTableID())
	elseif arg_42_1 == "ad" then
		return var_0_3:adUnable(arg_42_0:getTableID())
	end

	return false
end

function var_0_4.canMiss(arg_43_0)
	return var_0_3:canMiss(arg_43_0:getTableID())
end

function var_0_4.setIsHit(arg_44_0, arg_44_1)
	if not arg_44_0:canMiss() then
		arg_44_0.isHit_ = true
	else
		arg_44_0.isHit_ = arg_44_1
	end
end

function var_0_4.isHit(arg_45_0)
	return arg_45_0.isHit_
end

function var_0_4.getFilter(arg_46_0)
	if next(arg_46_0.manulFilter_) then
		return arg_46_0.manulFilter_
	end

	local var_46_0 = var_0_3:filterColor(arg_46_0:getTableID())

	if var_46_0 <= 0 then
		return
	end

	return arg_46_0.filterColor_[var_46_0]
end

function var_0_4.setManualFilter(arg_47_0, arg_47_1)
	arg_47_0.manulFilter_ = arg_47_1
end

function var_0_4.isYongJiu(arg_48_0)
	return arg_48_0.isYongJiu_
end

function var_0_4.setYongJiu(arg_49_0)
	arg_49_0.isYongJiu_ = true
	arg_49_0.leftCount_ = arg_49_0:getTime()
end

function var_0_4.getAttrType(arg_50_0)
	return var_0_3:attr(arg_50_0:getTableID())
end

function var_0_4.isAffected(arg_51_0)
	return var_0_3:affected(arg_51_0:getTableID())
end

function var_0_4.isTeamAffected(arg_52_0)
	return var_0_3:teamAffected(arg_52_0:getTableID())
end

function var_0_4.isInvisible(arg_53_0)
	return var_0_3:invisible(arg_53_0:getTableID())
end

function var_0_4.isFear(arg_54_0)
	return var_0_3:fear(arg_54_0:getTableID()) >= 1
end

function var_0_4.fearDir(arg_55_0)
	return var_0_3:fear(arg_55_0:getTableID()) > 1
end

function var_0_4.isSleep(arg_56_0)
	return var_0_3:sleep(arg_56_0:getTableID())
end

function var_0_4.isPossessed(arg_57_0)
	return var_0_3:possessed(arg_57_0:getTableID())
end

function var_0_4.isSpGive(arg_58_0)
	return var_0_3:isSpGive(arg_58_0:getTableID())
end

function var_0_4.isSpReduce(arg_59_0)
	return var_0_3:isSpReduce(arg_59_0:getTableID())
end

function var_0_4.spGiveRate(arg_60_0, arg_60_1)
	return var_0_3:spGiveRate(arg_60_0:getTableID()) + arg_60_0.manualSpGiveRate
end

function var_0_4.isMoveUnable(arg_61_0)
	return var_0_3:moveUnable(arg_61_0:getTableID())
end

function var_0_4.isApUnable(arg_62_0)
	return var_0_3:apUnable(arg_62_0:getTableID())
end

function var_0_4.isAdUnable(arg_63_0)
	return var_0_3:adUnable(arg_63_0:getTableID())
end

function var_0_4.isExcuteAdCircle(arg_64_0)
	return var_0_3:noSkip(arg_64_0:getTableID()) and arg_64_0:isAdUnable()
end

function var_0_4.isExcuteApCircle(arg_65_0)
	return var_0_3:noSkip(arg_65_0:getTableID()) and arg_65_0:isApUnable()
end

function var_0_4.isApImmortal(arg_66_0)
	return var_0_3:isApImmortal(arg_66_0:getTableID())
end

function var_0_4.isAdImmortal(arg_67_0)
	return var_0_3:isAdImmortal(arg_67_0:getTableID())
end

function var_0_4.isAttackFriend(arg_68_0)
	return var_0_3:attackFriend(arg_68_0:getTableID())
end

function var_0_4.isAdBreakImmortal(arg_69_0)
	return var_0_3:isAdBreakImmortal(arg_69_0:getTableID())
end

function var_0_4.pause(arg_70_0)
	return var_0_3:pause(arg_70_0:getTableID())
end

function var_0_4.initAttr(arg_71_0)
	local var_71_0, var_71_1 = var_0_3:init(arg_71_0:getTableID())

	return var_71_0, var_71_1
end

function var_0_4.step(arg_72_0)
	return var_0_3:step(arg_72_0:getTableID())
end

function var_0_4.dHarmType(arg_73_0)
	return var_0_3:dHarmType(arg_73_0:getTableID())
end

function var_0_4.stepHarm(arg_74_0)
	return var_0_3:stepHarm(arg_74_0:getTableID())
end

function var_0_4.harmToHP(arg_75_0)
	return var_0_3:harmToHP(arg_75_0:getTableID())
end

function var_0_4.getAttr(arg_76_0)
	local var_76_0, var_76_1 = arg_76_0:initAttr()

	if arg_76_0.manualRevise then
		var_76_0 = var_76_0 + arg_76_0.manualRevise
	end

	return var_76_0 + arg_76_0.level_ * arg_76_0:step(), var_76_1
end

function var_0_4.totalDHarm(arg_77_0)
	return math.max(var_0_3:dHarm(arg_77_0:getTableID()) + arg_77_0.level_ * arg_77_0:stepHarm() + arg_77_0.manualDharm, 0)
end

function var_0_4.setManualDharm(arg_78_0, arg_78_1)
	arg_78_0.manualDharm = arg_78_1
end

function var_0_4.getManualDharm(arg_79_0)
	return arg_79_0.manualDharm
end

function var_0_4.isDHarmLast(arg_80_0)
	return var_0_3:isDHarmLast(arg_80_0:getTableID())
end

function var_0_4.getDHarm(arg_81_0)
	if not arg_81_0.dHarm_ then
		arg_81_0.dHarm_ = arg_81_0:totalDHarm()
	end

	return arg_81_0.dHarm_
end

function var_0_4.setDHarm(arg_82_0, arg_82_1)
	if not arg_82_0.dHarm_ then
		return arg_82_1
	end

	local var_82_0 = arg_82_0.dHarm_

	if arg_82_1 >= arg_82_0.dHarm_ then
		local var_82_1 = arg_82_1 - arg_82_0.dHarm_

		arg_82_0.dHarm_ = 0

		return math.max(var_82_1, 0)
	else
		arg_82_0.dHarm_ = math.max(arg_82_0.dHarm_ - arg_82_1, 0)

		return 0
	end
end

function var_0_4.getHarm(arg_83_0)
	if not arg_83_0.target or not arg_83_0.fighter then
		return 0
	end

	if arg_83_0:isShieldBuff() then
		return 0
	end

	local var_83_0 = var_0_3:baseHarm(arg_83_0:getTableID())
	local var_83_1 = var_0_3:stepBase(arg_83_0:getTableID())
	local var_83_2 = var_0_3:ap(arg_83_0:getTableID())

	if var_83_0 == 0 and var_83_1 == 0 and var_83_2 == 0 then
		return 0
	end

	local var_83_3 = var_83_0 + var_83_1 * arg_83_0.level_ + arg_83_0.fighter:getAP() * var_83_2
	local var_83_4 = math.max(1, var_83_3)
	local var_83_5 = var_83_4

	if arg_83_0:getType() == var_0_2.BuffType.CONTINUE_HARM then
		local var_83_6 = math.max(arg_83_0.target:getMoKang() - arg_83_0.fighter:getDMoKang(), 0)

		var_83_5 = var_83_4 * var_83_4 / (var_83_4 + 8 * var_83_6)
	end

	if arg_83_0.manualHarmRevise then
		var_83_5 = arg_83_0.manualHarmRevise + var_83_5
	end

	return var_83_5
end

function var_0_4.getMana(arg_84_0)
	if not arg_84_0.target and not arg_84_0.fighter then
		return 0
	end

	local var_84_0 = var_0_3:baseMana(arg_84_0:getTableID())
	local var_84_1 = var_0_3:stepBaseMana(arg_84_0:getTableID())

	if var_84_0 == 0 and var_84_1 == 0 and arg_84_0.manualMp == 0 then
		return 0
	end

	return var_84_0 + var_84_1 * arg_84_0.level_ + arg_84_0.manualMp
end

function var_0_4.playRemoveSkill(arg_85_0)
	if arg_85_0:getRemoveSkill() <= 0 then
		return
	end

	local var_85_0 = {
		skillID = arg_85_0:getRemoveSkill(),
		buffTarget = arg_85_0.target
	}

	table.insert(arg_85_0.fighter.specialSkills, var_85_0)
end

function var_0_4.getBuffForm(arg_86_0)
	return var_0_3:buffForm(arg_86_0:getTableID())
end

function var_0_4.isPugongOnly(arg_87_0)
	return var_0_3:isPugongOnly(arg_87_0:getTableID())
end

function var_0_4.setForceTarget(arg_88_0, arg_88_1)
	arg_88_0.forceT_ = arg_88_1
end

function var_0_4.getForceTarget(arg_89_0)
	return arg_89_0.forceT_
end

function var_0_4.getDGainBuffCount(arg_90_0)
	if arg_90_0:getType() == var_0_2.BuffType.D_Gain_Buff then
		if not arg_90_0.dGainBuff_ then
			arg_90_0.dGainBuff_ = var_0_3:init(arg_90_0:getTableID())
		end
	else
		arg_90_0.dGainBuff_ = 0
	end

	return arg_90_0.dGainBuff_
end

function var_0_4.setDGainBuffCount(arg_91_0, arg_91_1)
	arg_91_0.dGainBuff_ = arg_91_0.dGainBuff_ + arg_91_1
end

function var_0_4.getdDebuffCount(arg_92_0)
	if arg_92_0:getType() == var_0_2.BuffType.D_Negative_Buff then
		if not arg_92_0.dDebuff_ then
			arg_92_0.dDebuff_ = var_0_3:init(arg_92_0:getTableID())
		end
	else
		arg_92_0.dDebuff_ = 0
	end

	return arg_92_0.dDebuff_
end

function var_0_4.setdDebuffCount(arg_93_0, arg_93_1)
	arg_93_0.dDebuff_ = arg_93_0.dDebuff_ + arg_93_1
end

function var_0_4.isInvalidMpIncrease(arg_94_0)
	return var_0_3:isInvalidMpIncrease(arg_94_0:getTableID())
end

function var_0_4.isInvalidEnergySkill(arg_95_0)
	return var_0_3:isInvalidEnergySkill(arg_95_0:getTableID())
end

function var_0_4.isShieldBuff(arg_96_0)
	return arg_96_0:getType() == var_0_2.BuffType.SHIELD_BUFF
end

function var_0_4.isDHarmBuff(arg_97_0)
	return arg_97_0:getType() == var_0_2.BuffType.D_HARM
end

function var_0_4.isSkillDown(arg_98_0)
	return var_0_3:isSkillDown(arg_98_0:getTableID()) > 0
end

function var_0_4.limitAttr(arg_99_0)
	return var_0_3:limitAttr(arg_99_0:getTableID()) > 0
end

function var_0_4.setShieldNum(arg_100_0, arg_100_1)
	arg_100_0.shieldNum_ = arg_100_1
end

function var_0_4.getShieldNum(arg_101_0)
	return arg_101_0.shieldNum_
end

function var_0_4.getShieldMaxHarm(arg_102_0)
	local var_102_0 = arg_102_0:getTableID()
	local var_102_1 = var_0_3:shieldInit(var_102_0)
	local var_102_2 = var_0_3:shieldStep(var_102_0)

	if arg_102_0.manualHarmRevise then
		var_102_1 = var_102_1 + arg_102_0.manualHarmRevise
	end

	return var_102_1 + var_102_2 * arg_102_0.level_
end

function var_0_4.isHeroNeverDieBuff(arg_103_0)
	return arg_103_0:getType() == var_0_2.BuffType.NEVER_DIE_BUFF
end

function var_0_4.isForverNeverDie(arg_104_0)
	return arg_104_0:getType() == var_0_2.BuffType.FOREVER_NEVER_DIE
end

function var_0_4.setActNum(arg_105_0, arg_105_1)
	arg_105_0.actNum_ = arg_105_1 or 1
end

function var_0_4.isAct(arg_106_0)
	return var_0_3:isAct(arg_106_0:getTableID())
end

function var_0_4.actNum(arg_107_0)
	if arg_107_0.actNum_ then
		return arg_107_0.actNum_
	end

	return var_0_3:actNum(arg_107_0:getTableID())
end

function var_0_4.isLeadBuff(arg_108_0)
	return arg_108_0:getTableID() == 40010694 or arg_108_0:getTableID() == 40010695
end

function var_0_4.isUseSkillCount(arg_109_0)
	local var_109_0 = false

	if var_0_3:useSkillCount(arg_109_0:getTableID()) > 0 and arg_109_0:getType() == var_0_2.BuffType.USE_SKILL_COUNT then
		var_109_0 = true
	end

	return var_109_0
end

function var_0_4.isIgnoreJianshang(arg_110_0)
	return arg_110_0:getType() == var_0_2.BuffType.IGNORE_JIANSHANG
end

function var_0_4.isIgnoreShield(arg_111_0)
	return arg_111_0:getType() == var_0_2.BuffType.IGNORE_SHIELD
end

function var_0_4.ignoreFlip(arg_112_0)
	return var_0_3:ignoreFlip(arg_112_0:getTableID()) == 1
end

function var_0_4.isChaos(arg_113_0)
	return var_0_3:isChaos(arg_113_0:getTableID()) == 1
end

function var_0_4.energyLimit(arg_114_0)
	return var_0_3:energyLimit(arg_114_0:getTableID())
end

function var_0_4.CoverLimit(arg_115_0)
	return var_0_3:CoverLimit(arg_115_0:getTableID())
end

function var_0_4.canRemove(arg_116_0)
	return var_0_3:canRemove(arg_116_0:getTableID())
end

function var_0_4.dBuffType(arg_117_0)
	return var_0_3:dbuffType(arg_117_0:getTableID())
end

function var_0_4.isPartnerControl(arg_118_0)
	return var_0_3:isPartnerControl(arg_118_0:getTableID()) == 1
end

function var_0_4.isImmuneControl(arg_119_0)
	return var_0_3:isImmuneControl(arg_119_0:getTableID()) == 1
end

function var_0_4.getIconTypes(arg_120_0)
	if not arg_120_0.iconTypes then
		arg_120_0.iconTypes = {}

		if arg_120_0:getAttrType() > 0 then
			if arg_120_0:getAttrType() == var_0_2.AttributeType.AD then
				if arg_120_0:getAttr() > 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.AD_INCREASE)
				elseif arg_120_0:getAttr() < 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.AD_DECREASE)
				end
			elseif arg_120_0:getAttrType() == var_0_2.AttributeType.AP then
				if arg_120_0:getAttr() > 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.AP_INCREASE)
				elseif arg_120_0:getAttr() < 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.AP_DECREASE)
				end
			elseif arg_120_0:getAttrType() == var_0_2.AttributeType.HUJIA then
				if arg_120_0:getAttr() > 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.HUJIA_INCREASE)
				elseif arg_120_0:getAttr() < 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.MOKANG_INCREASE)
				end
			elseif arg_120_0:getAttrType() == var_0_2.AttributeType.MOKANG then
				if arg_120_0:getAttr() > 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.HUJIA_DECREASE)
				elseif arg_120_0:getAttr() < 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.MOKANG_DECREASE)
				end
			elseif arg_120_0:getAttrType() == var_0_2.AttributeType.AD_BAOJI or arg_120_0:getAttrType() == var_0_2.AttributeType.AP_BAOJI then
				if arg_120_0:getAttr() > 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.BAOJI_INCREASE)
				elseif arg_120_0:getAttr() < 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.BAOJI_DECREASE)
				end
			elseif arg_120_0:getAttrType() == var_0_2.AttributeType.ACK_SPEED then
				if arg_120_0:getAttr() > 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.ACK_SPEED_INCREASE)
				elseif arg_120_0:getAttr() < 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.ACK_SPEED_DECREASE)
				end
			elseif arg_120_0:getAttrType() == var_0_2.AttributeType.D_HUJIA then
				if arg_120_0:getAttr() > 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.D_HUJIA_INCREASE)
				elseif arg_120_0:getAttr() < 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.D_HUJIA_DECREASE)
				end
			elseif arg_120_0:getAttrType() == var_0_2.AttributeType.D_MOKANG then
				if arg_120_0:getAttr() > 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.D_MOKANG_INCREASE)
				elseif arg_120_0:getAttr() < 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.D_MOKANG_DECREASE)
				end
			elseif arg_120_0:getAttrType() == var_0_2.AttributeType.SHANBI then
				if arg_120_0:getAttr() > 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.SHANBI_INCREASE)
				elseif arg_120_0:getAttr() < 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.SHANBI_DECREASE)
				end
			elseif arg_120_0:getAttrType() == var_0_2.AttributeType.D_CURE then
				if arg_120_0:getAttr() > 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.REHP_INCREASE)
				elseif arg_120_0:getAttr() < 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.REHP_DECREASE)
				end
			elseif arg_120_0:getAttrType() == var_0_2.AttributeType.ENERGY_RATE then
				if arg_120_0:getAttr() > 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.REMP_INCREASE)
				elseif arg_120_0:getAttr() < 0 then
					table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.REMP_DECREASE)
				end
			end
		end

		if arg_120_0:isAdImmortal() then
			table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.AD_IMMORTAL)
		end

		if arg_120_0:isApImmortal() then
			table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.AP_IMMORTAL)
		end

		if arg_120_0:isImmuneControl() then
			table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.BREAK_IMMORTAL)
		end

		if arg_120_0:getMana() > 0 then
			table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.CONTINUE_REMP)
		end

		if arg_120_0:getType() == var_0_2.BuffType.CONTINUE_HARM then
			table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.CONTINUE_HARM)
		end

		if arg_120_0:dBuffType() ~= var_0_2.DBuffType.ATTR_CHANGE and arg_120_0:dBuffType() ~= var_0_2.DBuffType.NONE then
			if arg_120_0:dBuffType() == var_0_2.DBuffType.ZU_ZHOU then
				table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.TAUNT)
			elseif arg_120_0:dBuffType() == var_0_2.DBuffType.XUAN_YUN then
				table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.XUAN_YUN)
			elseif arg_120_0:dBuffType() == var_0_2.DBuffType.MEI_HUO then
				table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.MEI_HUO)
			elseif arg_120_0:dBuffType() == var_0_2.DBuffType.JIN_GU then
				table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.JIN_GU)
			elseif arg_120_0:dBuffType() == var_0_2.DBuffType.ZHI_MANG then
				table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.ZHI_MANG)
			elseif arg_120_0:dBuffType() == var_0_2.DBuffType.CHEN_MO then
				table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.CHEN_MO)
			elseif arg_120_0:dBuffType() == var_0_2.DBuffType.BING_DONG then
				table.insert(arg_120_0.iconTypes, var_0_2.BuffIconType.BING_DONG)
			end
		end
	end

	return arg_120_0.iconTypes
end

return var_0_4
