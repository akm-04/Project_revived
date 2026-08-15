local var_0_0 = class("TeamActiveIconTipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = xyd.tables.misc.guildVitalitySelfLimit
	local var_3_1 = xyd.tables.misc.guildVitalityGuildLimit

	arg_3_0:nodeByName("des_1_text"):setString(var_0_2:translation("GUILD_ACTIVE_DES_1"))
	arg_3_0:nodeByName("des_2_text"):setString(string.format(var_0_2:translation("GUILD_ACTIVE_DES_2"), var_3_1, var_3_0))
	arg_3_0:nodeByName("des_3_text"):setString(string.format(var_0_2:translation("GUILD_ACTIVE_SELF_NUM"), arg_3_0.guild.today_huoyue, var_3_0))
	arg_3_0:nodeByName("des_4_text"):setString(string.format(var_0_2:translation("GUILD_ACTIVE_NUM"), arg_3_0.guild.huoyue))
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
end

return var_0_0
