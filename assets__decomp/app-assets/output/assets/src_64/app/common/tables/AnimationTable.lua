local var_0_0 = class("AnimationTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.plists_ = {}
	arg_1_0.images_ = {}
	arg_1_0.numFrames_ = {}
	arg_1_0.delays_ = {}
	arg_1_0.begins_ = {}

	import("app.common.tables.TableParser").parse("animation.lua", function(arg_2_0)
		local var_2_0 = arg_2_0.name

		arg_1_0.plists_[var_2_0] = arg_2_0.plist
		arg_1_0.images_[var_2_0] = arg_2_0.image
		arg_1_0.numFrames_[var_2_0] = tonumber(arg_2_0.num_frames)
		arg_1_0.delays_[var_2_0] = tonumber(arg_2_0.delay) / xyd.DECIMAL_BASE
		arg_1_0.begins_[var_2_0] = tonumber(arg_2_0.begin)
	end)
end

function var_0_0.plist(arg_3_0, arg_3_1)
	return arg_3_0.plists_[arg_3_1]
end

function var_0_0.image(arg_4_0, arg_4_1)
	return arg_4_0.images_[arg_4_1]
end

function var_0_0.numberOfFrames(arg_5_0, arg_5_1)
	return arg_5_0.numFrames_[arg_5_1]
end

function var_0_0.delay(arg_6_0, arg_6_1)
	return arg_6_0.delays_[arg_6_1]
end

function var_0_0.begin(arg_7_0, arg_7_1)
	return arg_7_0.begins_[arg_7_1]
end

return var_0_0
