local var_0_0 = class("OccultSelectModelWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_1_0.chapterId = arg_1_2.chapter_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setButtonClick()
end

function var_0_0.setButtonClick(arg_4_0)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_create"), nil, function()
		xyd.playButtonSound()

		local var_5_0 = {
			chapter_id = arg_4_0.chapterId,
			campaign_type = xyd.OccultRoomType.MULTI_PLAYER
		}

		arg_4_0.occult:createRoom(var_5_0, function(arg_6_0, arg_6_1)
			if arg_6_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("occult_prepare")
				xyd.WindowManager.get():closeWindow(arg_4_0)
			end
		end)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_add"), nil, function()
		xyd.playButtonSound()
		xyd.WindowManager.get():openWindow("occult_input_house")
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("close_btn"), nil, function()
		local var_8_0 = xyd.tables.sound:getSound("ui_close_window")

		audio.playSound(var_8_0, false)
		xyd.WindowManager.get():closeWindow(arg_4_0)
	end)
	arg_4_0:nodeByName("text_create"):setString(var_0_1:translation("ILLUSION_MODE_TXT1"))
	arg_4_0:nodeByName("text_add"):setString(var_0_1:translation("ILLUSION_MODE_TXT2"))
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("ILLUSION_MODE_TXT3"))
end

return var_0_0
