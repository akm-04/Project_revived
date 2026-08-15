local var_0_0 = class("ChatBubble", import(".BaseModel"))
local var_0_1 = xyd.tables.chatBubble
local var_0_2 = xyd.tables.misc:getValue("default_bubble")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.loadBubble(arg_2_0, arg_2_1)
	xyd.Backend.get():request(xyd.mid.GET_BUBBLE_INFO, nil, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0:apartBubbleList(arg_3_1.bubble_list)
		end

		if arg_2_1 then
			arg_2_1(arg_3_0, arg_3_1)
		end
	end)
end

function var_0_0.apartBubbleList(arg_4_0, arg_4_1)
	arg_4_0.bubbles = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		arg_4_0.bubbles[iter_4_1.bubble_id] = iter_4_1.end_time
	end

	if not arg_4_0.bubbles[arg_4_0.selfPlayer.bubbleInfo.bubble_id] then
		arg_4_0.selfPlayer.bubbleInfo.bubble_id = var_0_2
	end
end

function var_0_0.setBubble(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_1 == arg_5_0.selfPlayer.bubbleInfo.bubble_id then
		return
	end

	local var_5_0 = arg_5_0.bubbles[arg_5_1]
	local var_5_1 = xyd.ServerTime.get():getServerTime()

	if not var_5_0 then
		return
	end

	if var_5_0 <= 0 or var_5_1 < var_5_0 then
		xyd.Backend.get():request(xyd.mid.CHANGE_BUBBLE, {
			bubble_id = arg_5_1
		}, function(arg_6_0, arg_6_1)
			if arg_6_0 == xyd.error.OK then
				arg_5_0.selfPlayer.bubbleInfo = arg_6_1.bubble_info

				arg_5_2()
			end
		end)
	else
		arg_5_0:loadBubble(function(arg_7_0)
			if arg_7_0 == xyd.error.OK then
				local var_7_0 = xyd.tables.translation:translation("CHAT_BUBBLE_TEXT_8")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_0
				})
				arg_5_2()
			end
		end)
	end
end

function var_0_0.getBubbleID(arg_8_0)
	if not arg_8_0.selfPlayer.bubbleInfo then
		return var_0_2
	end

	local var_8_0 = arg_8_0.selfPlayer.bubbleInfo.end_time
	local var_8_1 = xyd.ServerTime.get():getServerTime()

	if var_8_0 <= 0 or var_8_1 < var_8_0 then
		return arg_8_0.selfPlayer.bubbleInfo.bubble_id
	else
		return var_0_2
	end
end

function var_0_0.getBubbles(arg_9_0)
	local var_9_0 = {}
	local var_9_1 = xyd.ServerTime.get():getServerTime()

	for iter_9_0, iter_9_1 in pairs(arg_9_0.bubbles) do
		table.insert(var_9_0, {
			id = iter_9_0,
			time = iter_9_1 - var_9_1
		})
	end

	table.sort(var_9_0, function(arg_10_0, arg_10_1)
		return arg_10_0.id < arg_10_1.id
	end)

	return var_9_0
end

function var_0_0.getLockBubbles(arg_11_0)
	local var_11_0 = var_0_1:all()
	local var_11_1 = {}

	for iter_11_0, iter_11_1 in pairs(var_11_0) do
		if not arg_11_0.bubbles[iter_11_0] and var_0_1:isShow(iter_11_0) == 1 then
			table.insert(var_11_1, iter_11_0)
		end
	end

	table.sort(var_11_1, function(arg_12_0, arg_12_1)
		return arg_12_0 < arg_12_1
	end)

	return var_11_1
end

return var_0_0
