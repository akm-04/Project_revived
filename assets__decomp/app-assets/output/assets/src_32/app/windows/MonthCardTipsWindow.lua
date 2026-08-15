local var_0_0 = class("MonthCardTipsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.tili = arg_1_2.tili
	arg_1_0.both = arg_1_2.both
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen()
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("text_container")
	local var_4_1 = var_4_0:getContentSize()
	local var_4_2 = 0
	local var_4_3 = var_4_1.height
	local var_4_4 = var_0_1:translation("MONTH_CARD_ALREADY_BUY_TEXT_1_EXTRA")

	for iter_4_0 = 1, 2 do
		local var_4_5 = var_0_1:translation("MONTH_CARD_ALREADY_BUY_TIYLE_" .. iter_4_0)
		local var_4_6 = arg_4_0:createTextLabel(var_4_5, var_4_1.width, cc.ui.TEXT_ALIGN_LEFT, 24, cc.c3b(255, 255, 255))

		var_4_6:addTo(var_4_0)
		var_4_6:setAnchorPoint(cc.p(0, 1))
		var_4_6:setPosition(var_4_2, var_4_3)

		var_4_3 = var_4_3 - var_4_6:getContentSize().height - 10

		local var_4_7 = xyd.split(var_0_1:translation("MONTH_CARD_ALREADY_BUY_TEXT_" .. iter_4_0), "\n")

		if iter_4_0 == 1 and arg_4_0.both then
			table.insert(var_4_7, 3, var_4_4)
			arg_4_0:nodeByName("text_container"):setContentSize(arg_4_0:nodeByName("text_container"):getContentSize().width, arg_4_0:nodeByName("text_container"):getContentSize().height + 30)
			arg_4_0:nodeByName("bg"):setContentSize(arg_4_0:nodeByName("bg"):getContentSize().width, arg_4_0:nodeByName("bg"):getContentSize().height + 30)
			arg_4_0:nodeByName("container"):setContentSize(arg_4_0:nodeByName("container"):getContentSize().width, arg_4_0:nodeByName("container"):getContentSize().height + 30)
			arg_4_0:nodeByName("text_container"):setPositionY(arg_4_0:nodeByName("text_container"):getPositionY() + 30)
		elseif iter_4_0 == 1 and arg_4_0.tili then
			var_4_7[2] = var_4_4
		end

		local var_4_8 = 30

		for iter_4_1 = 1, #var_4_7 do
			local var_4_9 = arg_4_0:createTextLabel(var_4_7[iter_4_1], var_4_1.width - 30, cc.ui.TEXT_ALIGN_LEFT, 20, cc.c3b(255, 255, 255))

			var_4_9:addTo(var_4_0)
			var_4_9:setPosition(cc.p(var_4_8, var_4_3))
			var_4_9:setAnchorPoint(cc.p(0, 1))

			var_4_3 = var_4_3 - var_4_9:getContentSize().height - 5
		end
	end
end

function var_0_0.createTextLabel(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	local var_5_0 = {
		text = arg_5_1,
		align = arg_5_3,
		color = arg_5_5,
		size = arg_5_4,
		dimensions = cc.size(arg_5_2, 0)
	}

	return (xyd.AssetLoader.get():loadLabel(var_5_0))
end

function var_0_0.getWndSize(arg_6_0)
	return arg_6_0:nodeByName("container"):getContentSize()
end

return var_0_0
