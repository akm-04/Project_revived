local var_0_0 = class("RepHero", import(".Hero"))

function var_0_0.ctor(arg_1_0)
	var_0_0.super.ctor(arg_1_0)
end

function var_0_0.populate(arg_2_0, arg_2_1)
	var_0_0.super.populate(arg_2_0, arg_2_1)

	if arg_2_1.player_name then
		arg_2_0.playerName_ = arg_2_1.player_name
	end

	if arg_2_1.point then
		arg_2_0.point_ = tonumber(arg_2_1.point)
	end
end

function var_0_0.getPlayerName(arg_3_0)
	return arg_3_0.playerName_
end

function var_0_0.getPoint(arg_4_0)
	return arg_4_0.point_
end

function var_0_0.toParams(arg_5_0)
	local var_5_0 = {}
	local var_5_1 = var_0_0.super.toParams(arg_5_0)

	if arg_5_0.playerName_ then
		var_5_1.player_name = arg_5_0.playerName_
	end

	if arg_5_0.point_ then
		var_5_1.point = arg_5_0.point_
	end

	return var_5_1
end

return var_0_0
