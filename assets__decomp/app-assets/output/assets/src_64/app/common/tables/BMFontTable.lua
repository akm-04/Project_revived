local var_0_0 = class("BMFontTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.resources_ = {}

	import("app.common.tables.TableParser").parse("bmfont.lua", function(arg_2_0)
		arg_1_0.resources_[arg_2_0.name] = {
			font = arg_2_0.font_file,
			image = arg_2_0.image
		}
	end)
end

function var_0_0.resource(arg_3_0, arg_3_1)
	return arg_3_0.resources_[arg_3_1] or {}
end

return var_0_0
