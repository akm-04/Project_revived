local var_0_0 = class("PlayoffsVSRoundWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.round = arg_1_2.params.team_id
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_1_0.selfPlayer.playerID == arg_1_2.A_player_id then
		arg_1_0.firstSelect = 0
	else
		arg_1_0.firstSelect = 1
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	return
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()

	if arg_3_0.round == 1 then
		arg_3_0:nodeByName("first"):setVisible(true)
		arg_3_0:nodeByName("second"):setVisible(false)
		arg_3_0:nodeByName("third"):setVisible(false)
	elseif arg_3_0.round == 2 then
		arg_3_0:nodeByName("first"):setVisible(false)
		arg_3_0:nodeByName("second"):setVisible(true)
		arg_3_0:nodeByName("third"):setVisible(false)
	elseif arg_3_0.round == 3 then
		arg_3_0:nodeByName("first"):setVisible(false)
		arg_3_0:nodeByName("second"):setVisible(false)
		arg_3_0:nodeByName("third"):setVisible(true)
	end

	if arg_3_0.firstSelect == 0 then
		arg_3_0:nodeByName("attack"):setVisible(true)
		arg_3_0:nodeByName("defence"):setVisible(false)
	else
		arg_3_0:nodeByName("attack"):setVisible(false)
		arg_3_0:nodeByName("defence"):setVisible(true)
	end
end

return var_0_0
