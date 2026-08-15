local var_0_0 = class("WarCampTimelineTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.des_ = {}
	arg_1_0.isOpenJoin_ = {}
	arg_1_0.isOpenWar_ = {}

	import("app.common.tables.TableParser").parse("camp_war_timeline", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.time_id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.des_[var_2_0] = arg_2_0.des
		arg_1_0.isOpenJoin_[var_2_0] = tonumber(arg_2_0.is_open_join)
		arg_1_0.isOpenWar_[var_2_0] = tonumber(arg_2_0.is_open_war)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.des(arg_5_0, arg_5_1)
	return arg_5_0.des_[arg_5_1] or ""
end

function var_0_0.isOpenJoin(arg_6_0, arg_6_1)
	return arg_6_0.isOpenJoin_[arg_6_1] or 0
end

function var_0_0.isOpenWar(arg_7_0, arg_7_1)
	return arg_7_0.isOpenWar_[arg_7_1] or 0
end

function var_0_0.getOpenWarDay(arg_8_0)
	for iter_8_0 = 1, #arg_8_0.ids_ do
		local var_8_0 = arg_8_0.ids_[iter_8_0]

		if arg_8_0:isOpenWar(var_8_0) == 1 then
			return iter_8_0
		end
	end

	return #arg_8_0.ids_
end

function var_0_0.getEndWarDay(arg_9_0)
	local var_9_0 = false

	for iter_9_0 = 1, #arg_9_0.ids_ do
		local var_9_1 = arg_9_0.ids_[iter_9_0]

		if arg_9_0:isOpenWar(var_9_1) == 0 then
			if var_9_0 then
				return iter_9_0
			else
				var_9_0 = true
			end
		end
	end

	return #arg_9_0.ids_
end

return var_0_0
