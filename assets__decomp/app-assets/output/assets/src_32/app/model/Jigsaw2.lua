local var_0_0 = class("Jigsaw2", import(".BaseModel"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = 20

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.BROCAST_FINISH_JIGSAW, handler(arg_2_0, arg_2_0.onBrocastFinishJigsaw2_))
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.LOAD_JIGSAW2_INFO, {}, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			if arg_4_1 then
				arg_3_0.activity = arg_4_1
				arg_3_0.details = arg_3_0.activity.details
			end

			arg_3_0:updateRedMark()

			if arg_3_1 then
				arg_3_1(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.put(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.PUT_JIGSAW2, var_5_0, function(arg_6_0, arg_6_1)
		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.updateRedMark(arg_7_0)
	local var_7_0 = false

	for iter_7_0 = 1, #arg_7_0.details.can_award do
		if arg_7_0.details.can_award[iter_7_0] == 1 and arg_7_0.details.is_awards[iter_7_0] == 0 then
			var_7_0 = true
		end
	end

	for iter_7_1 = 1, var_0_2 do
		if arg_7_0.details.jig_infos[iter_7_1].is_put == 0 and arg_7_0.details.jig_infos[iter_7_1].count and xyd.tables.ActivityJigsaw2:amount(arg_7_0.details.jig_infos[iter_7_1].jigsaw_id) and arg_7_0.details.jig_infos[iter_7_1].count >= xyd.tables.ActivityJigsaw2:amount(arg_7_0.details.jig_infos[iter_7_1].jigsaw_id) then
			var_7_0 = true
		end
	end

	local var_7_1 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_7_1 then
		var_7_1:showJigsaw2RedMark(var_7_0)
	end
end

function var_0_0.onBrocastFinishJigsaw2_(arg_8_0, arg_8_1)
	local var_8_0 = xyd.WindowManager.get():getWindow("jigsaw2")
	local var_8_1 = xyd.WindowManager.get():getWindow("main_scene_top")

	dump(arg_8_1)

	if var_8_1 and var_8_0 then
		local var_8_2 = {
			msg = arg_8_1.params.msg.content
		}

		var_8_2.time = 7

		dump(var_8_2)
		var_8_1:showBroadcast(var_8_2)
	end
end

return var_0_0
