local var_0_0 = class("BeachFighterModel", import("app.modules.battle.FighterModel"))

function var_0_0.playHPDeltas(arg_1_0, arg_1_1, arg_1_2, arg_1_3)
	local var_1_0 = {}

	for iter_1_0, iter_1_1 in ipairs(arg_1_1) do
		local var_1_1 = iter_1_1[1]
		local var_1_2 = iter_1_1[2]
		local var_1_3 = arg_1_0:getHeroAnimation().headPoint
		local var_1_4 = var_1_3.x
		local var_1_5 = var_1_3.y

		if arg_1_3 then
			var_1_4 = var_1_4 + arg_1_3.x
			var_1_5 = var_1_5 + arg_1_3.y
		end

		local var_1_6 = xyd.AssetLoader.get():loadLabel({
			text = string.format("%s%d", var_1_1 >= 0 and "+" or "", var_1_1)
		}, var_1_1 >= 0 and "battle_float_green" or "battle_float_red"):align(display.CENTER, var_1_4, var_1_5)

		if var_1_2 then
			var_1_6:setScale(1.5)
		end

		table.insert(var_1_0, var_1_6)
	end

	arg_1_0:playNumberFloat_(var_1_0, arg_1_2)
end

return var_0_0
