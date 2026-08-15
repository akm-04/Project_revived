local var_0_0 = class("DialogueTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.title_ = {}
	arg_1_0.amour_ = {}
	arg_1_0.expression_ = {}
	arg_1_0.dialog_ = {}
	arg_1_0.idPrefixToIdList_ = {}
	arg_1_0.typeToIdList_ = {}
	arg_1_0.type_ = {}
	arg_1_0.typeId_ = {}
	arg_1_0.people_ = {}
	arg_1_0.turnId_ = {}
	arg_1_0.isReward_ = {}
	arg_1_0.buttonChoose_ = {}

	import("app.common.tables.TableParser").parse(tostring(arg_1_1), function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.title_[var_2_0] = arg_2_0.title
		arg_1_0.amour_[var_2_0] = arg_2_0.amour
		arg_1_0.expression_[var_2_0] = tonumber(arg_2_0.expression)
		arg_1_0.dialog_[var_2_0] = arg_2_0.dialog
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.typeId_[var_2_0] = tonumber(arg_2_0.type_id)
		arg_1_0.people_[var_2_0] = tonumber(arg_2_0.people)
		arg_1_0.turnId_[var_2_0] = xyd.splitToNumber(arg_2_0.turn_id, "|")
		arg_1_0.isReward_[var_2_0] = tonumber(arg_2_0.is_reward)
		arg_1_0.buttonChoose_[var_2_0] = arg_2_0.button_choose

		local var_2_1 = math.floor(var_2_0 / 1000)

		if not arg_1_0.idPrefixToIdList_[var_2_1] then
			arg_1_0.idPrefixToIdList_[var_2_1] = {}
		end

		table.insert(arg_1_0.idPrefixToIdList_[var_2_1], var_2_0)

		if not arg_1_0.typeToIdList_[arg_1_0.type_[var_2_0]] then
			arg_1_0.typeToIdList_[arg_1_0.type_[var_2_0]] = {}
		end

		table.insert(arg_1_0.typeToIdList_[arg_1_0.type_[var_2_0]], var_2_0)
	end)
end

function var_0_0.getTitle(arg_3_0, arg_3_1)
	return arg_3_0.title_[arg_3_1]
end

function var_0_0.getAmour(arg_4_0, arg_4_1)
	return arg_4_0.amour_[arg_4_1]
end

function var_0_0.getExpression(arg_5_0, arg_5_1)
	return arg_5_0.expression_[arg_5_1]
end

function var_0_0.getDialog(arg_6_0, arg_6_1)
	return arg_6_0.dialog_[arg_6_1]
end

function var_0_0.getDialogTotalNum(arg_7_0)
	return #arg_7_0.typeToIdList_
end

function var_0_0.type(arg_8_0, arg_8_1)
	return arg_8_0.type_[arg_8_1]
end

function var_0_0.typeId(arg_9_0, arg_9_1)
	return arg_9_0.typeId_[arg_9_1]
end

function var_0_0.people(arg_10_0, arg_10_1)
	return arg_10_0.people_[arg_10_1]
end

function var_0_0.turnId(arg_11_0, arg_11_1)
	return arg_11_0.turnId_[arg_11_1]
end

function var_0_0.isReward(arg_12_0, arg_12_1)
	return arg_12_0.isReward_[arg_12_1]
end

function var_0_0.buttonChoose(arg_13_0, arg_13_1)
	return arg_13_0.buttonChoose_[arg_13_1]
end

function var_0_0.getFirstIdByType(arg_14_0, arg_14_1)
	return arg_14_0.typeToIdList_[arg_14_1][1]
end

function var_0_0.getIdListByIdType(arg_15_0, arg_15_1)
	return arg_15_0.typeToIdList_[arg_15_1]
end

function var_0_0.getTitleByIdType(arg_16_0, arg_16_1)
	return arg_16_0:getTitle(arg_16_0.typeToIdList_[arg_16_1][1])
end

return var_0_0
