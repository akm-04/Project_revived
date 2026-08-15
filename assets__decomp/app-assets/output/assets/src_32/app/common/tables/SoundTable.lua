local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("SoundTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.sounds_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("sound_config.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("sound_config", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_1.key

	arg_2_0.sounds_[var_2_0] = arg_2_1.sound
end

function var_0_2.getSound(arg_3_0, arg_3_1)
	return arg_3_0.sounds_[arg_3_1]
end

return var_0_2
