local var_0_0 = class("AssetTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.icon_ = {}
	arg_1_0.transparentIcon_ = {}
	arg_1_0.backendName_ = {}
	arg_1_0.name_ = {}

	import("app.common.tables.TableParser").parse("asset.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.transparentIcon_[var_2_0] = arg_2_0.transparent_icon
		arg_1_0.backendName_[var_2_0] = arg_2_0.backend_name
		arg_1_0.name_[var_2_0] = arg_2_0.name
	end)
end

function var_0_0.icon(arg_3_0, arg_3_1)
	return arg_3_0.icon_[arg_3_1] or ""
end

function var_0_0.transparentIcon(arg_4_0, arg_4_1)
	return arg_4_0.transparentIcon_[arg_4_1] or ""
end

function var_0_0.backendName(arg_5_0, arg_5_1)
	return arg_5_0.backendName_[arg_5_1] or ""
end

function var_0_0.name(arg_6_0, arg_6_1)
	return arg_6_0.name_[arg_6_1] or ""
end

function var_0_0.getIdByBackendName(arg_7_0, arg_7_1)
	for iter_7_0, iter_7_1 in pairs(arg_7_0.backendName_) do
		if iter_7_1 == arg_7_1 then
			return iter_7_0
		end
	end
end

return var_0_0
