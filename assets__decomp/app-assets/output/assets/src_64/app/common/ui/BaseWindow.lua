local var_0_0 = class("BaseWindow", function()
	return display.newNode()
end)
local var_0_1 = import("app.common.ui.WndTopSidebar")
local var_0_2 = import("app.common.ui.WndLeftSidebar")
local var_0_3 = import("app.common.ui.SpineEffect")

var_0_0.NAME_SEPARATOR_PATTERN = "%$"
var_0_0.TEXT_TYPE_NAME = "Text"
var_0_0.BACKGROUND_NAME = "background"
var_0_0.CLOSE_BUTTON_NAME = "close"
var_0_0.SOUND_BUTTON_TYPE_NAME = "sound_button"
var_0_0.BG_ZORDER = -100

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	cc(arg_2_0):addComponent("components.behavior.EventProtocol"):exportMethods()

	if xyd.tables.window:canTouch(arg_2_1) then
		arg_2_0:setTouchEnabled(true)
		arg_2_0:setTouchSwallowEnabled(true)
	end

	if arg_2_2 and type(arg_2_2) == "table" and arg_2_2.window_layer then
		arg_2_0.windowLayer = arg_2_2.window_layer
	end

	arg_2_0.buttonName2Sound_ = {}
	arg_2_0.name = arg_2_1

	if not xyd.tables.window:hasWindow(arg_2_1) then
		return
	end

	arg_2_0.colorMode = xyd.tables.window:colorMode(arg_2_1)
	arg_2_0.isLoaded = true
end

function var_0_0.loadRes(arg_3_0)
	local var_3_0 = xyd.tables.window:resource(arg_3_0.name)

	if #var_3_0 == 0 then
		return
	end

	if not xyd.assetDownloadErrorLog(var_3_0) then
		arg_3_0.isLoaded = false

		return
	end

	arg_3_0.hasLoadRes = true

	arg_3_0:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson(var_3_0))

	if xyd.tables.window:isAddTheme(arg_3_0.name) == 1 and arg_3_0.colorMode and arg_3_0.colorMode > 0 then
		arg_3_0:addThemeBG()
	end

	if var_3_0 == xyd.Template.CommonWithSidebar then
		arg_3_0:addLeftSidebar()
		arg_3_0:addTopSidebar()
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	return
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	return
end

function var_0_0.afterCompleteOpenWindow(arg_6_0)
	return
end

function var_0_0.willClose(arg_7_0, arg_7_1)
	return
end

function var_0_0.didClose(arg_8_0, arg_8_1)
	return
end

function var_0_0.nodeByName(arg_9_0, arg_9_1)
	if not arg_9_0.children_ then
		return nil
	end

	return arg_9_0.children_[arg_9_1]
end

function var_0_0.background(arg_10_0)
	return arg_10_0:nodeByName(var_0_0.BACKGROUND_NAME)
end

function var_0_0.closeButton(arg_11_0)
	return arg_11_0:nodeByName(var_0_0.CLOSE_BUTTON_NAME)
end

function var_0_0.windowType(arg_12_0)
	return arg_12_0.windowLayer or xyd.tables.window:windowType(arg_12_0.name)
end

function var_0_0.layoutType(arg_13_0)
	return xyd.tables.window:layoutType(arg_13_0.name)
end

function var_0_0.offset(arg_14_0)
	return xyd.tables.window:offset(arg_14_0.name)
end

function var_0_0.priority(arg_15_0)
	return xyd.tables.window:priority(arg_15_0.name)
end

function var_0_0.showBackground(arg_16_0)
	return xyd.tables.window:showBackground(arg_16_0.name)
end

function var_0_0.childWindowNames(arg_17_0)
	return xyd.tables.window:childWindowNames(arg_17_0.name) or {}
end

function var_0_0.exceptNames(arg_18_0)
	return xyd.tables.window:exceptNames(arg_18_0.name) or {}
end

function var_0_0.hideNames(arg_19_0)
	return xyd.tables.window:hideNames(arg_19_0.name) or {}
end

function var_0_0.showNames(arg_20_0)
	return xyd.tables.window:showNames(arg_20_0.name) or {}
end

function var_0_0.sideBysideNames(arg_21_0)
	return xyd.tables.window:sideBySideNames(arg_21_0.name) or {}
end

function var_0_0.isBySided(arg_22_0, arg_22_1)
	local var_22_0 = arg_22_0:sideBysideNames()

	if var_22_0 == nil then
		return false
	end

	for iter_22_0, iter_22_1 in pairs(var_22_0) do
		if iter_22_1 == arg_22_1 then
			return true
		end
	end

	return false
end

function var_0_0.isExcept(arg_23_0, arg_23_1)
	local var_23_0 = arg_23_0:exceptNames()

	if var_23_0 == nil then
		return false
	end

	for iter_23_0, iter_23_1 in pairs(var_23_0) do
		if iter_23_1 == arg_23_1 then
			return true
		end
	end

	return false
end

function var_0_0.isHide(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_0:hideNames()

	if var_24_0 == nil then
		return false
	end

	for iter_24_0, iter_24_1 in pairs(var_24_0) do
		if iter_24_1 == arg_24_1 then
			return true
		end
	end

	return false
end

function var_0_0.isShowWnd(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_0:showNames()

	if var_25_0 == nil then
		return false
	end

	for iter_25_0, iter_25_1 in pairs(var_25_0) do
		if iter_25_1 == arg_25_1 then
			return true
		end
	end

	return false
end

function var_0_0.setupContentView_(arg_26_0, arg_26_1)
	if arg_26_0.contentView_ and not tolua.isnull(arg_26_0.contentView_) then
		arg_26_0.contentView_:removeAllChildrenWithCleanup()
	end

	arg_26_0.contentView_ = arg_26_1:addTo(arg_26_0)

	arg_26_0:parseChildren_()

	if arg_26_0:background() ~= nil then
		arg_26_0:size(arg_26_0:background():getContentSize())
	end

	if arg_26_0:closeButton() ~= nil then
		arg_26_0:closeButton():addTouchEventListener(function(arg_27_0, arg_27_1)
			if arg_27_1 == ccui.TouchEventType.ended then
				local var_27_0 = xyd.tables.sound:getSound("ui_close_window")

				audio.playSound(var_27_0, false)
				xyd.WindowManager.get():closeWindow(arg_26_0)
			end
		end)
	end

	xyd.setCascadeOpacityEnabled(arg_26_0, true)
end

function var_0_0.parseChildren_(arg_28_0, arg_28_1)
	if arg_28_1 == nil then
		arg_28_0.children_ = {}

		if arg_28_0.contentView_ == nil then
			return
		else
			arg_28_1 = arg_28_0.contentView_
		end
	else
		local var_28_0 = arg_28_0:splitName_(arg_28_1:getName())

		if #var_28_0 >= 2 then
			arg_28_1:setName(var_28_0[1])
			arg_28_0:processNodeType_(arg_28_1, var_28_0)
		end

		arg_28_0.children_[arg_28_1:getName()] = arg_28_1
	end

	for iter_28_0, iter_28_1 in ipairs(arg_28_1:getChildren()) do
		if iter_28_1 ~= nil then
			arg_28_0:parseChildren_(iter_28_1)
		end
	end
end

function var_0_0.splitName_(arg_29_0, arg_29_1)
	local var_29_0 = {}

	if arg_29_1 == nil then
		return var_29_0
	end

	while true do
		local var_29_1, var_29_2 = arg_29_1:find(var_0_0.NAME_SEPARATOR_PATTERN)

		if var_29_1 == nil then
			table.insert(var_29_0, arg_29_1)

			break
		else
			table.insert(var_29_0, arg_29_1:sub(1, var_29_1 - 1))

			arg_29_1 = arg_29_1:sub(var_29_2 + 1)
		end
	end

	return var_29_0
end

function var_0_0.processNodeType_(arg_30_0, arg_30_1, arg_30_2)
	if arg_30_2[2] == var_0_0.TEXT_TYPE_NAME then
		arg_30_0:processText_(arg_30_1, arg_30_2)
	elseif arg_30_2[2] == var_0_0.SOUND_BUTTON_TYPE_NAME then
		-- block empty
	end
end

function var_0_0.processText_(arg_31_0, arg_31_1, arg_31_2)
	local function var_31_0(arg_32_0)
		xyd.formatUIText(arg_32_0, function(arg_33_0)
			arg_33_0:enableShadow()
		end)
	end

	if arg_31_2[3] == nil then
		return
	end

	local var_31_1, var_31_2 = arg_31_2[3]:find(",")

	if var_31_1 == nil then
		if arg_31_2[3]:find("shadow") then
			var_31_0(arg_31_1)
		end

		return
	end

	local var_31_3 = xyd.hex2color4b(arg_31_2[3]:sub(1, var_31_1 - 1), true)
	local var_31_4 = tonumber(arg_31_2[3]:sub(var_31_2 + 1))

	if var_31_4 == nil or var_31_4 <= 0 then
		return
	end

	arg_31_1:enableOutline(var_31_3, var_31_4)

	if arg_31_2[4] and arg_31_2[4]:find("shadow") then
		var_31_0(arg_31_1)
	end
end

function var_0_0.processSoundButton(arg_34_0, arg_34_1, arg_34_2)
	arg_34_1:addTouchEventListener(handler(arg_34_0, arg_34_0.soundButtonClick))
end

function var_0_0.soundButtonClick(arg_35_0, arg_35_1, arg_35_2)
	if arg_35_2 == ccui.TouchEventType.ended then
		local var_35_0 = arg_35_0:getSoundByIndex()

		audio.playSound(var_35_0, false)
	end
end

function var_0_0.getSoundByIndex(arg_36_0)
	return xyd.tables.sound:getSound("ui_button_click")
end

function var_0_0.addBlockLayer(arg_37_0, arg_37_1, arg_37_2, arg_37_3, arg_37_4)
	if arg_37_1 == nil then
		arg_37_1 = cc.c4b(0, 0, 0, 150)
	end

	arg_37_0.blockLayer_ = display.newColorLayer(arg_37_1)

	local var_37_0 = arg_37_0:convertToWorldSpace(cc.p(0, 0))

	arg_37_0.blockLayer_:pos(-var_37_0.x, -var_37_0.y):addTo(arg_37_0, -1)

	local function var_37_1(arg_38_0, arg_38_1)
		if arg_38_1 == ccui.TouchEventType.ended and not arg_37_3 then
			local var_38_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_38_0, false)
			xyd.WindowManager.get():closeWindow(arg_37_0.name)
		end

		return true
	end

	local function var_37_2(arg_39_0, arg_39_1)
		if arg_37_4 then
			arg_37_4()
		end

		if not arg_37_3 then
			local var_39_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_39_0, false)
			xyd.WindowManager.get():closeWindow(arg_37_0.name)
		end
	end

	if not arg_37_2 then
		arg_37_0.layerListener = cc.EventListenerTouchOneByOne:create()

		arg_37_0.layerListener:setSwallowTouches(true)
		arg_37_0.layerListener:registerScriptHandler(var_37_1, cc.Handler.EVENT_TOUCH_BEGAN)
		arg_37_0.layerListener:registerScriptHandler(var_37_2, cc.Handler.EVENT_TOUCH_ENDED)
		arg_37_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_37_0.layerListener, arg_37_0.contentView_)
	end
end

function var_0_0.addBlockLayerClickClose(arg_40_0, arg_40_1, arg_40_2, arg_40_3, arg_40_4)
	if arg_40_1 == nil then
		arg_40_1 = cc.c4b(0, 0, 0, 150)
	end

	arg_40_4 = arg_40_4 or -1
	arg_40_0.blockLayer_ = display.newColorLayer(arg_40_1)

	local var_40_0 = arg_40_0:convertToWorldSpace(cc.p(0, 0))

	arg_40_0.blockLayer_:pos(-var_40_0.x, -var_40_0.y):addTo(arg_40_0, arg_40_4)

	if not arg_40_2 then
		arg_40_0.blockLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_41_0)
			if arg_41_0.name == "began" then
				return true
			elseif arg_41_0.name == "ended" and not arg_40_3 then
				local var_41_0 = xyd.tables.sound:getSound("ui_close_window")

				audio.playSound(var_41_0, false)
				xyd.WindowManager.get():closeWindow(arg_40_0.name)
			end
		end)
	end
end

function var_0_0.addBlockLayerWithNoTouchEvent(arg_42_0, arg_42_1)
	if arg_42_1 == nil then
		arg_42_1 = cc.c4b(0, 0, 0, 200)
	end

	arg_42_0.blockLayer_ = display.newColorLayer(arg_42_1)

	local var_42_0 = arg_42_0:convertToWorldSpace(cc.p(0, 0))

	arg_42_0.blockLayer_:pos(-var_42_0.x, -var_42_0.y):addTo(arg_42_0, -1)

	local function var_42_1(arg_43_0, arg_43_1)
		return true
	end

	local function var_42_2(arg_44_0, arg_44_1)
		return
	end

	arg_42_0.layerListener = cc.EventListenerTouchOneByOne:create()

	arg_42_0.layerListener:setSwallowTouches(true)
	arg_42_0.layerListener:registerScriptHandler(var_42_1, cc.Handler.EVENT_TOUCH_BEGAN)
	arg_42_0.layerListener:registerScriptHandler(var_42_2, cc.Handler.EVENT_TOUCH_ENDED)
	arg_42_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_42_0.layerListener, arg_42_0.contentView_)
end

function var_0_0.resetBlockLayer(arg_45_0)
	if not arg_45_0.blockLayer_ then
		return
	end

	local var_45_0 = arg_45_0:convertToWorldSpace(cc.p(0, 0))

	arg_45_0.blockLayer_:pos(-var_45_0.x, -var_45_0.y)
end

function var_0_0.close(arg_46_0, arg_46_1)
	xyd.WindowManager.get():closeWindow(arg_46_0, arg_46_1)
end

function var_0_0.addTopSidebar(arg_47_0, arg_47_1)
	if not arg_47_0:background() then
		return
	end

	arg_47_0:setTouchEnabled(true)
	arg_47_0:setTouchSwallowEnabled(true)

	if arg_47_0:nodeByName("top_sidebar") then
		return
	end

	local var_47_0 = {
		colorMode = arg_47_0.colorMode,
		parent = arg_47_0,
		title = xyd.tables.window:title(arg_47_0.name),
		show_rule = arg_47_1 and arg_47_1.show_rule
	}

	if arg_47_1 then
		var_47_0.isEcoBar = arg_47_1.isEcoBar
		var_47_0.ecoBarType = arg_47_1.ecoBarType or xyd.EcoSidebarType.MAIN
		var_47_0.ecoCount = arg_47_1.ecoCount or 3
		var_47_0.ecoTypes = arg_47_1.ecoTypes or {}
		var_47_0.ecoIcons = arg_47_1.ecoIcons or {}
		var_47_0.ecoIsAdd = arg_47_1.ecoIsAdd or {}
		var_47_0.ecoScale = arg_47_1.ecoScale or {}
		var_47_0.ecoAddCallback = arg_47_1.ecoAddCallback or {}
		var_47_0.callback = arg_47_1.callback
	end

	local var_47_1 = var_0_1.new(xyd.WidgetName.wndTopSidebar, var_47_0)

	var_47_1:setAnchorPoint(0, 1)
	var_47_1:addTo(arg_47_0:background())
	var_47_1:setPosition(arg_47_0:nodeByName("pos_top_sidebar"):getPosition())

	arg_47_0.children_.top_sidebar = var_47_1
	arg_47_0.children_.eco_sidebar = var_47_1:nodeByName("eco_sidebar")
end

function var_0_0.addLeftSidebar(arg_48_0)
	local var_48_0 = 200
	local var_48_1 = var_0_2.new(xyd.WidgetName.wndLeftSidebar, {})

	var_48_1:setAnchorPoint(0, 0)
	var_48_1:addTo(arg_48_0:background())
	var_48_1:setPosition(arg_48_0:nodeByName("pos_left_sidebar"):getPosition())

	if arg_48_0.changeBG and not tolua.isnull(arg_48_0.changeBG) then
		arg_48_0.changeBG:setPositionX(var_48_0)

		local var_48_2, var_48_3 = arg_48_0.bgEffect:getPosition()

		arg_48_0.bgEffect:setPosition(var_48_2 + var_48_0, var_48_3)
	end

	arg_48_0.children_.left_sidebar = var_48_1
end

function var_0_0.addThemeBG(arg_49_0)
	if not arg_49_0:background() then
		return
	end

	local var_49_0 = arg_49_0:background():getWidth()
	local var_49_1 = arg_49_0:background():getHeight()
	local var_49_2 = xyd.tables.systemColor:bgSources(arg_49_0.colorMode)

	for iter_49_0, iter_49_1 in ipairs(var_49_2) do
		if iter_49_0 == 3 then
			local var_49_3 = display.newClippingRegionNode(cc.rect(0, 0, var_49_0, var_49_1))

			arg_49_0.changeBG = xyd.AssetLoader.get():loadSprite(iter_49_1)

			arg_49_0.changeBG:setAnchorPoint(0, 0)
			arg_49_0.changeBG:setPosition(0, 0)
			arg_49_0.changeBG:addTo(var_49_3)
			var_49_3:addTo(arg_49_0:background(), var_0_0.BG_ZORDER + iter_49_0)
			var_49_3:setAnchorPoint(0, 0)
			var_49_3:setPosition(0, 0)
		else
			local var_49_4 = xyd.AssetLoader.get():loadSprite(iter_49_1)

			var_49_4:setAnchorPoint(0, 0)
			var_49_4:setPosition(0, 0)
			var_49_4:addTo(arg_49_0:background(), var_0_0.BG_ZORDER + iter_49_0)
		end
	end

	arg_49_0:addBgEffect(var_0_0.BG_ZORDER + #var_49_2)
end

function var_0_0.addBgEffect(arg_50_0, arg_50_1, arg_50_2, arg_50_3)
	arg_50_1 = arg_50_1 or 1
	arg_50_2 = arg_50_2 or arg_50_0:background()
	arg_50_3 = arg_50_3 or 0

	local var_50_0 = arg_50_2:getWidth()
	local var_50_1 = arg_50_2:getHeight()
	local var_50_2 = "skeletons/ui_effect/sys_bg_effect/bg_effect"
	local var_50_3 = var_50_2 .. ".json"
	local var_50_4 = var_50_2 .. ".atlas"

	arg_50_0.bgEffect = var_0_3.new(var_50_3, var_50_4, 1)

	arg_50_0.bgEffect:addTo(arg_50_2, arg_50_1)
	arg_50_0.bgEffect:setAnchorPoint(0, 0)
	arg_50_0.bgEffect:setPosition(var_50_0 / 2 - 155 + arg_50_3, var_50_1 / 2 + 35)
	arg_50_0.bgEffect:play(nil, true)
end

function var_0_0.onAppear(arg_51_0)
	return
end

function var_0_0.onHide(arg_52_0)
	return
end

function var_0_0.setGuideBtns(arg_53_0, arg_53_1, arg_53_2)
	if not arg_53_0.guideBtns then
		arg_53_0.guideBtns = {}
	end

	arg_53_0.guideBtns[arg_53_2] = arg_53_1
end

function var_0_0.getButtonByName(arg_54_0, arg_54_1)
	if arg_54_0.guideBtns and arg_54_0.guideBtns[arg_54_1] and not tolua.isnull(arg_54_0.guideBtns[arg_54_1]) then
		return arg_54_0.guideBtns[arg_54_1]
	end
end

function var_0_0.checkIfSatisfyGuide(arg_55_0, arg_55_1)
	return false
end

function var_0_0.addTips(arg_56_0, arg_56_1, arg_56_2)
	xyd.addTips(arg_56_1, arg_56_2)
end

return var_0_0
