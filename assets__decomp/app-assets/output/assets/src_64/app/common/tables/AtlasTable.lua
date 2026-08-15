local var_0_0 = class("AtlasTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.atlases_ = {}

	import("app.common.tables.TableParser").parse("atlas.lua", function(arg_2_0)
		table.insert(arg_1_0.atlases_, {
			arg_2_0.plist,
			arg_2_0.texture
		})
	end)
end

function var_0_0.allAtlas(arg_3_0)
	return arg_3_0.atlases_
end

return var_0_0
