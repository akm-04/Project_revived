local var_0_0 = class("FourthAnniPaintingTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.datas = {}

	for iter_1_0 = 1, 6 do
		arg_1_0.datas[iter_1_0] = {}
		arg_1_0.datas[iter_1_0].ids_ = {}
		arg_1_0.datas[iter_1_0].content_ = {}

		import("app.common.tables.TableParser").parse("activity_anni_4th_painting" .. iter_1_0 .. ".lua", function(arg_2_0)
			local var_2_0 = tonumber(arg_2_0.id)

			arg_1_0.datas[iter_1_0].content_[var_2_0] = xyd.splitToNumber(arg_2_0.content, "|")

			table.insert(arg_1_0.datas[iter_1_0].ids_, var_2_0)
		end)
	end
end

function var_0_0.getIdsByMapId(arg_3_0, arg_3_1)
	return arg_3_0.datas[arg_3_1].ids_ or {}
end

function var_0_0.getData(arg_4_0, arg_4_1, arg_4_2)
	return arg_4_0.datas[arg_4_1].content_[arg_4_2] or {}
end

return var_0_0
