local var_0_0 = class("HeroSearchWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.AssetLoader.get()
local var_0_3 = 1
local var_0_4 = 0
local var_0_5 = 24

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.searchTxt = ""
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:layout()
	arg_2_0:nodeByName("search_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.began then
			-- block empty
		elseif arg_3_1 == ccui.TouchEventType.ended then
			if arg_2_0.searchTxt and arg_2_0.searchTxt == "" then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("HERO_SEARCH_TIPS")
				})
			else
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.UPDATE_SEARCH_HEROS,
					params = arg_2_0.searchTxt
				})
				xyd.WindowManager.get():closeWindow(arg_2_0)
			end
		end
	end)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:initSearchBox()
end

function var_0_0.initSearchBox(arg_5_0)
	local var_5_0 = "windows/hero_list/hero_search/input_box.png"

	arg_5_0.searchBox = ccui.EditBox:create(arg_5_0:nodeByName("input_box"):getContentSize(), var_5_0)

	arg_5_0.searchBox:setAnchorPoint(0, 0)
	arg_5_0.searchBox:pos(0, 0)
	arg_5_0:nodeByName("input_box"):addChild(arg_5_0.searchBox, -100)
	arg_5_0.searchBox:setFont(var_0_2.FONT_NAME, var_0_5)
	arg_5_0:nodeByName("search_txt"):setString(var_0_1:translation("HERO_SEARCH_TIPS"))
	arg_5_0.searchBox:setFontColor(cc.c3b(0, 0, 0))
	arg_5_0.searchBox:setMaxLength(8)
	arg_5_0.searchBox:setInputMode(6)
	arg_5_0.searchBox:registerScriptEditBoxHandler(handler(arg_5_0, arg_5_0.searchBoxHandler))
	arg_5_0.searchBox:setInputFlag(3)

	arg_5_0.inputFlag = true
end

function var_0_0.searchBoxHandler(arg_6_0, arg_6_1)
	if arg_6_1 == "return" then
		arg_6_0.searchTxt = arg_6_0.searchBox:getText()

		arg_6_0:nodeByName("search_txt"):setString(arg_6_0.searchTxt)
		arg_6_0.searchBox:setText("")

		arg_6_0.inputFlag = false
	end
end

return var_0_0
