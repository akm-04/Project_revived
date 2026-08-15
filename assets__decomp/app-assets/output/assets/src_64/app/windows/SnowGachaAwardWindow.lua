local var_0_0 = class("SnowGachaAwardWindow", import("app.windows.ActivityGachaAwardWindow"))

function var_0_0.star(arg_1_0, arg_1_1)
	return xyd.tables.snowGachaCollection:rarityById(arg_1_1)
end

return var_0_0
