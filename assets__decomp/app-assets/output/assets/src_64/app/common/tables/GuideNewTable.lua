local var_0_0 = class("GuideNewTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.haveId_ = {}
	arg_1_0.beforeId_ = {}
	arg_1_0.nextId_ = {}
	arg_1_0.name_ = {}
	arg_1_0.type_ = {}
	arg_1_0.returnId_ = {}
	arg_1_0.condition_ = {}
	arg_1_0.pageName_ = {}
	arg_1_0.picType_ = {}
	arg_1_0.picSize_ = {}
	arg_1_0.picScale_ = {}
	arg_1_0.picPosition_ = {}
	arg_1_0.handType_ = {}
	arg_1_0.handPosition_ = {}
	arg_1_0.isLvmeng_ = {}
	arg_1_0.lvmengDirection_ = {}
	arg_1_0.lvmengPosition_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.dialoguePosition_ = {}
	arg_1_0.dialogueType_ = {}
	arg_1_0.dialogueDirection_ = {}
	arg_1_0.complete_ = {}
	arg_1_0.exPara_ = {}
	arg_1_0.btnName_ = {}
	arg_1_0.btnType_ = {}
	arg_1_0.startId = 0
	arg_1_0.endId = 0

	import("app.common.tables.TableParser").parse("guide_new.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.nextId_[var_2_0] = tonumber(arg_2_0.next_id)

		if arg_1_0.nextId_[var_2_0] then
			arg_1_0.beforeId_[arg_1_0.nextId_[var_2_0]] = var_2_0
		end

		arg_1_0.haveId_[var_2_0] = true
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.returnId_[var_2_0] = tonumber(arg_2_0.return_id)
		arg_1_0.condition_[var_2_0] = xyd.splitToNumber(arg_2_0.condition, "|")
		arg_1_0.pageName_[var_2_0] = arg_2_0.page_name
		arg_1_0.btnName_[var_2_0] = arg_2_0.btn_name
		arg_1_0.btnType_[var_2_0] = tonumber(arg_2_0.btn_type)
		arg_1_0.picType_[var_2_0] = tonumber(arg_2_0.pic_type)
		arg_1_0.picSize_[var_2_0] = xyd.splitToNumber(arg_2_0.pic_size, "|")
		arg_1_0.picScale_[var_2_0] = xyd.splitToNumber(arg_2_0.pic_scale, "|")
		arg_1_0.picPosition_[var_2_0] = xyd.splitToNumber(arg_2_0.pic_position, "|")
		arg_1_0.handType_[var_2_0] = tonumber(arg_2_0.hand_type)
		arg_1_0.handPosition_[var_2_0] = xyd.splitToNumber(arg_2_0.hand_position, "|")
		arg_1_0.isLvmeng_[var_2_0] = tonumber(arg_2_0.is_lvmeng)
		arg_1_0.lvmengDirection_[var_2_0] = tonumber(arg_2_0.lvmeng_direction)
		arg_1_0.lvmengPosition_[var_2_0] = xyd.splitToNumber(arg_2_0.lvmeng_position, "|")
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.dialoguePosition_[var_2_0] = xyd.splitToNumber(arg_2_0.dialogue_position, "|")
		arg_1_0.dialogueType_[var_2_0] = tonumber(arg_2_0.dialogue_type)
		arg_1_0.dialogueDirection_[var_2_0] = tonumber(arg_2_0.dialogue_direction)
		arg_1_0.complete_[var_2_0] = arg_2_0.complete
		arg_1_0.exPara_[var_2_0] = tonumber(arg_2_0.ex_para)
	end)
end

function var_0_0.isHaveId(arg_3_0, arg_3_1)
	return arg_3_0.haveId_[arg_3_1] or false
end

function var_0_0.getStartId(arg_4_0)
	return arg_4_0.startId or 0
end

function var_0_0.getEndId(arg_5_0)
	return arg_5_0.endId or 0
end

function var_0_0.beforeId(arg_6_0, arg_6_1)
	return arg_6_0.beforeId_[arg_6_1] or 0
end

function var_0_0.nextId(arg_7_0, arg_7_1)
	return arg_7_0.nextId_[arg_7_1] or 0
end

function var_0_0.name(arg_8_0, arg_8_1)
	return arg_8_0.name_[arg_8_1] or ""
end

function var_0_0.type(arg_9_0, arg_9_1)
	return arg_9_0.type_[arg_9_1] or 0
end

function var_0_0.returnId(arg_10_0, arg_10_1)
	return arg_10_0.returnId_[arg_10_1] or 0
end

function var_0_0.condition(arg_11_0, arg_11_1)
	return arg_11_0.condition_[arg_11_1] or {}
end

function var_0_0.pageName(arg_12_0, arg_12_1)
	return arg_12_0.pageName_[arg_12_1] or ""
end

function var_0_0.btnName(arg_13_0, arg_13_1)
	return arg_13_0.btnName_[arg_13_1] or ""
end

function var_0_0.picType(arg_14_0, arg_14_1)
	return arg_14_0.picType_[arg_14_1] or 0
end

function var_0_0.picScale(arg_15_0, arg_15_1)
	return arg_15_0.picScale_[arg_15_1] or {}
end

function var_0_0.btnType(arg_16_0, arg_16_1)
	return arg_16_0.btnType_[arg_16_1] or 0
end

function var_0_0.picSize(arg_17_0, arg_17_1)
	return arg_17_0.picSize_[arg_17_1] or {}
end

function var_0_0.picPosition(arg_18_0, arg_18_1)
	return arg_18_0.picPosition_[arg_18_1] or {}
end

function var_0_0.handType(arg_19_0, arg_19_1)
	return arg_19_0.handType_[arg_19_1] or 0
end

function var_0_0.handPosition(arg_20_0, arg_20_1)
	return arg_20_0.handPosition_[arg_20_1] or {}
end

function var_0_0.isLvmeng(arg_21_0, arg_21_1)
	return arg_21_0.isLvmeng_[arg_21_1] or 0
end

function var_0_0.lvmengDirection(arg_22_0, arg_22_1)
	return arg_22_0.lvmengDirection_[arg_22_1] or 0
end

function var_0_0.lvmengPosition(arg_23_0, arg_23_1)
	return arg_23_0.lvmengPosition_[arg_23_1] or {}
end

function var_0_0.desc(arg_24_0, arg_24_1)
	return arg_24_0.desc_[arg_24_1] or ""
end

function var_0_0.dialoguePosition(arg_25_0, arg_25_1)
	return arg_25_0.dialoguePosition_[arg_25_1] or {}
end

function var_0_0.dialogueType(arg_26_0, arg_26_1)
	return arg_26_0.dialogueType_[arg_26_1] or 0
end

function var_0_0.dialogueDirection(arg_27_0, arg_27_1)
	return arg_27_0.dialogueDirection_[arg_27_1] or 0
end

function var_0_0.complete(arg_28_0, arg_28_1)
	return arg_28_0.complete_[arg_28_1] or ""
end

function var_0_0.exPara(arg_29_0, arg_29_1)
	return arg_29_0.exPara_[arg_29_1] or 0
end

return var_0_0
