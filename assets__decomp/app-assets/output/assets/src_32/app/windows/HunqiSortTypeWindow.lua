local var_0_0 = class("HunqiSortTypeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.attr
local var_0_3 = {
	AD = 5,
	HUJIA = 7,
	HP = 4,
	LEV = 1,
	ZHUANGTAI_KANGXING = 11,
	AP = 6,
	BAOJIHARM = 10,
	BAOJI_RATE = 9,
	HUNQI_HP_BONUS = 13,
	QUALITY = 2,
	MOKANG = 8,
	ZHUANGTAI_MINGZHONG = 12,
	GET_TIME = 3,
	HUNQI_JIAKANG_BONUS = 15,
	HUNQI_AD_AP_BONUS = 14
}
local var_0_4 = {
	var_0_1:translation("HUNQI_TEXT_21"),
	var_0_1:translation("HUNQI_TEXT_22"),
	var_0_1:translation("HUNQI_TEXT_23"),
	var_0_2:name(xyd.AttributeType.HP),
	var_0_2:name(xyd.AttributeType.AD),
	var_0_2:name(xyd.AttributeType.AP),
	var_0_2:name(xyd.AttributeType.HUJIA),
	var_0_2:name(xyd.AttributeType.MOKANG),
	var_0_2:name(xyd.AttributeType.BAOJI_RATE),
	var_0_2:name(xyd.AttributeType.BAOJIHARM),
	var_0_2:name(xyd.AttributeType.ZHUANGTAI_KANGXING),
	var_0_2:name(xyd.AttributeType.ZHUANGTAI_MINGZHONG),
	var_0_2:name(xyd.AttributeType.HUNQI_HP_BONUS),
	var_0_2:name(xyd.AttributeType.HUNQI_AD_AP_BONUS),
	var_0_2:name(xyd.AttributeType.HUNQI_JIAKANG_BONUS)
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.types = arg_1_2.types
	arg_1_0.colNum = arg_1_2.colNum or 2
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addNoTouchLayer()
end

function var_0_0.getTipHeight(arg_4_0)
	return arg_4_0.tipHeight
end

function var_0_0.getTipWidth(arg_5_0)
	return arg_5_0.tipHeight
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = #arg_6_0.types
	local var_6_1
	local var_6_2
	local var_6_3

	if arg_6_0.colNum == 1 then
		var_6_1 = var_6_0
		var_6_3 = 156
	else
		var_6_1 = math.ceil(var_6_0 / 2)
		var_6_3 = 297
	end

	local var_6_4 = 32 + var_6_1 * 49 + 13

	for iter_6_0 = 1, var_6_0 do
		local var_6_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/sort_type_btn.csb")

		var_6_5:getChildByName("btn"):getChildByName("text"):setString(var_0_4[arg_6_0.types[iter_6_0]])
		var_6_5:getChildByName("btn"):setTouchEnabled(true)
		var_6_5:getChildByName("btn"):setTouchSwallowEnabled(true)
		var_6_5:getChildByName("btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
			xyd.buttonScaleAnim(arg_7_0, arg_7_1)

			if arg_7_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if arg_6_0.callback then
					arg_6_0.callback(arg_6_0.types[iter_6_0])
				else
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.HUNQI_SORT,
						type_ = arg_6_0.types[iter_6_0]
					})
				end

				arg_6_0:close()
			end
		end)
		var_6_5:addTo(arg_6_0:nodeByName("bg"))

		local var_6_6
		local var_6_7

		if arg_6_0.colNum == 1 then
			var_6_6, var_6_7 = var_6_5:getChildByName("btn"):getWidth() / 2 + 11, var_6_4 - 13 - 16 - var_6_5:getChildByName("btn"):getHeight() / 2
			var_6_7 = var_6_7 - (iter_6_0 - 1) * (var_6_5:getChildByName("btn"):getHeight() + 11)
		else
			var_6_6, var_6_7 = var_6_5:getChildByName("btn"):getWidth() / 2 + 11, var_6_4 - 13 - 16 - var_6_5:getChildByName("btn"):getHeight() / 2

			if iter_6_0 % 2 == 0 then
				var_6_6 = var_6_5:getChildByName("btn"):getWidth() * 3 / 2 + 22
			end

			var_6_7 = var_6_7 - math.floor((iter_6_0 - 1) / 2) * (var_6_5:getChildByName("btn"):getHeight() + 11)
		end

		var_6_5:setPosition(var_6_6, var_6_7)
	end

	arg_6_0:nodeByName("container"):setContentSize(var_6_3, var_6_4)
	arg_6_0:nodeByName("bg"):setContentSize(var_6_3, var_6_4)

	local var_6_8 = display.newNode()

	var_6_8:setContentSize(var_6_3, var_6_4)
	var_6_8:setTouchEnabled(true)
	var_6_8:setTouchSwallowEnabled(true)
	var_6_8:addTo(arg_6_0)

	arg_6_0.tipWidth = var_6_3
	arg_6_0.tipHeight = var_6_4
end

function var_0_0.addNoTouchLayer(arg_8_0)
	local function var_8_0(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended and not noClose then
			local var_9_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_9_0, false)
			xyd.WindowManager.get():closeWindow(arg_8_0.name)
		end

		return true
	end

	local function var_8_1(arg_10_0, arg_10_1)
		if callback then
			callback()
		end

		if not noClose then
			local var_10_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_10_0, false)
			xyd.WindowManager.get():closeWindow(arg_8_0.name)
		end
	end

	if not touchFalse then
		arg_8_0.layerListener = cc.EventListenerTouchOneByOne:create()

		arg_8_0.layerListener:registerScriptHandler(var_8_0, cc.Handler.EVENT_TOUCH_BEGAN)
		arg_8_0.layerListener:registerScriptHandler(var_8_1, cc.Handler.EVENT_TOUCH_ENDED)
		arg_8_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_8_0.layerListener, arg_8_0.contentView_)
	end
end

return var_0_0
