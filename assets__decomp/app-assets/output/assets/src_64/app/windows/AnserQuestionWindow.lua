local var_0_0 = class("AnserQuestionWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.activityKiteQuestion

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.packetIdx = arg_1_2.idx
	arg_1_0.packetNum = arg_1_2.num
	arg_1_0.message = arg_1_2.content
	arg_1_0.kiteMsg = arg_1_2.kite
	arg_1_0.kite = xyd.ModelManager.get():loadModel(xyd.ModelType.KITE)

	if arg_1_0.kiteMsg then
		arg_1_0.locPos = math.random(1, 3)
		arg_1_0.locId = arg_1_0.kiteMsg.ans_id
	else
		arg_1_0.locPos = 0
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	if arg_2_0.kiteMsg then
		arg_2_0:nodeByName("title_txt"):setString(var_0_1:translation("ACTIVITY_KITE_FLY_WHRER2"))
	else
		arg_2_0:nodeByName("title_txt"):setString(var_0_1:translation("ACTIVITY_KITE_FLY_WHRER1"))
	end

	arg_2_0:nodeByName("tip_txt"):setString(var_0_1:translation("ACTIVITY_KITE_FLY_TIP"))

	local var_2_0 = var_0_3:allcount()
	local var_2_1 = arg_2_0:nodeByName("location1"):getContentSize()

	arg_2_0.locIds = {}

	for iter_2_0 = 1, 3 do
		if iter_2_0 == arg_2_0.locPos then
			arg_2_0.locIds[iter_2_0] = arg_2_0.locId
		else
			local var_2_2 = true

			while var_2_2 do
				var_2_2 = false
				arg_2_0.locIds[iter_2_0] = math.random(1, var_2_0)

				if arg_2_0.locIds[iter_2_0] == arg_2_0.locId then
					var_2_2 = true
				end

				for iter_2_1 = 1, iter_2_0 - 1 do
					if arg_2_0.locIds[iter_2_0] == arg_2_0.locIds[iter_2_1] then
						var_2_2 = true
					end
				end
			end
		end

		local var_2_3 = arg_2_0:nodeByName("location" .. iter_2_0)

		var_2_3:getChildByName("name"):setString(var_0_3:name(arg_2_0.locIds[iter_2_0]))

		local var_2_4 = xyd.AssetLoader:get():loadSprite(var_0_3:image(arg_2_0.locIds[iter_2_0]))

		var_2_4:setScale(var_0_3:scale(arg_2_0.locIds[iter_2_0]))
		var_2_4:addTo(var_2_3)
		var_2_4:setPosition(var_2_1.width / 2, var_2_1.height / 2)
		var_2_3:setTouchEnabled(true)
		var_2_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
			if arg_3_0.name == "began" then
				return true
			elseif arg_3_0.name == "ended" then
				if arg_2_0.kiteMsg then
					arg_2_0:anserQuestion(arg_2_0.locIds[iter_2_0])
				else
					arg_2_0:sendKite(arg_2_0.locIds[iter_2_0])
				end
			end
		end)
	end
end

function var_0_0.sendKite(arg_4_0, arg_4_1)
	local var_4_0 = {
		id = arg_4_0.packetIdx,
		num = arg_4_0.packetNum,
		content = arg_4_0.message,
		ans_id = arg_4_1
	}

	var_4_0.problem_id = 0

	arg_4_0.kite:sendKite(var_4_0, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			wnd = xyd.WindowManager.get():getWindow("kite")

			if wnd then
				wnd:updateRightListItem(var_4_0.id)
			end

			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.anserQuestion(arg_6_0, arg_6_1)
	local var_6_0 = {
		packet_id = arg_6_0.kiteMsg.packet_id,
		ans_id = arg_6_1
	}
	local var_6_1 = arg_6_0.kiteMsg

	arg_6_0.kite:anserQuestion(var_6_0, function(arg_7_0, arg_7_1)
		if arg_7_1.award then
			if var_6_0.ans_id == var_6_1.ans_id then
				local var_7_0 = {
					crystal = arg_7_1.award,
					kite = arg_6_0.kiteMsg
				}

				xyd.WindowManager.get():openWindow("grab_kite_result", var_7_0)
			else
				local var_7_1 = {
					kite = var_6_1,
					ans_id = var_6_0.ans_id
				}

				var_7_1.result = false
				var_7_1.crystal = arg_7_1.award

				xyd.WindowManager.get():openWindow("anser_result", var_7_1)
			end

			xyd.WindowManager.get():closeWindow(arg_6_0)
		end
	end)
end

function var_0_0.playWithAnserId(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1

	if arg_8_0.isSetQuestion then
		arg_8_0:sendKite(var_8_0)
	else
		arg_8_0:anserQuestion(var_8_0)
	end

	xyd.WindowManager.get():closeWindow(arg_8_0)
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	arg_9_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
end

return var_0_0
