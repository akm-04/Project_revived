local var_0_0 = class("MailOnekeyTitle", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/mailbox/mailbox_title.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1, arg_4_2)
	arg_4_0.contentView_:nodeByName("title_txt"):setString(arg_4_1)

	local var_4_0 = arg_4_0.contentView_:nodeByName("container")
	local var_4_1 = var_4_0:getContentSize()

	var_4_0:setContentSize(var_4_1.width, var_4_1.height + arg_4_2)

	local var_4_2 = var_4_0:getChildByName("detail"):getPositionY()

	var_4_0:getChildByName("detail"):setPositionY(var_4_2 + arg_4_2)
end

local var_0_1 = class("MailboxOnekeyWindow", import("app.common.ui.BaseWindow"))
local var_0_2 = 4
local var_0_3 = xyd.tables.item
local var_0_4 = require("framework.scheduler")
local var_0_5 = xyd.tables.translation

function var_0_1.ctor(arg_5_0, arg_5_1, arg_5_2)
	var_0_1.super.ctor(arg_5_0, arg_5_1, arg_5_2)

	arg_5_0.mails = arg_5_2.mails
	arg_5_0.backpack_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack()
end

function var_0_1.willOpen(arg_6_0, arg_6_1)
	var_0_1.super:willOpen(arg_6_1)

	arg_6_0.receiveBtn = arg_6_0:nodeByName("receive_btn")

	arg_6_0:layout()
end

function var_0_1.layout(arg_7_0)
	arg_7_0:nodeByName("text_title"):setString(var_0_5:translation("ONE_KEY_TIPS"))

	local var_7_0 = arg_7_0:nodeByName("scroll_container")
	local var_7_1 = var_7_0:getContentSize()

	arg_7_0.listView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_7_1.width, var_7_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_7_0):onScroll(handler(arg_7_0, arg_7_0.scrollListener))
	arg_7_0.action = {}
	arg_7_0.heights = {}
	arg_7_0.delays = {}

	local var_7_2 = 0

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.mails) do
		arg_7_0.action[iter_7_0] = {}
		arg_7_0.action[iter_7_0].items = {}

		local var_7_3 = 0

		if iter_7_1.attach and next(iter_7_1.attach) then
			var_7_3 = (math.ceil(#iter_7_1.attach / var_0_2) - 1) * 50
		end

		local var_7_4 = arg_7_0.listView_:newItem()
		local var_7_5 = var_0_0.new()

		var_7_5:setParams(iter_7_1.title, var_7_3)

		local var_7_6 = var_7_5:contentView():nodeByName("container"):getContentSize()
		local var_7_7 = var_7_5:contentView():nodeByName("detail"):getContentSize().height + 20

		var_7_5:setContentSize(var_7_6.width, var_7_7)
		var_7_4:addContent(var_7_5)
		var_7_4:setItemSize(var_7_6.width, var_7_7)
		arg_7_0.listView_:addItem(var_7_4)

		var_7_2 = var_7_2 + 0.12

		local var_7_8 = 1

		arg_7_0.action[iter_7_0].items[var_7_8] = {}
		arg_7_0.action[iter_7_0].items[var_7_8].view = var_7_4
		arg_7_0.action[iter_7_0].items[var_7_8].delay = var_7_2

		if iter_7_1.attach and next(iter_7_1.attach) then
			local var_7_9 = iter_7_1.attach
			local var_7_10 = math.ceil(#var_7_9 / var_0_2)

			for iter_7_2 = 1, var_7_10 do
				local var_7_11 = arg_7_0.listView_:newItem()
				local var_7_12 = cc.Node:create()

				for iter_7_3 = 1, var_0_2 do
					local var_7_13 = (iter_7_2 - 1) * var_0_2 + iter_7_3

					if var_7_13 > #var_7_9 then
						break
					end

					local var_7_14 = import("app.windows.ListItem").new()

					var_7_14:setParams(var_7_9[var_7_13].item, var_7_9[var_7_13].num or 0)
					var_7_14:setPosition((iter_7_3 - 1) * var_7_14:contentView():nodeByName("container"):getContentSize().width + 50, 0)
					var_7_14:addTo(var_7_12)

					var_7_2 = var_7_2 + 0.08
					var_7_8 = var_7_8 + 1
					arg_7_0.action[iter_7_0].items[var_7_8] = {}
					arg_7_0.action[iter_7_0].items[var_7_8].view = var_7_14
					arg_7_0.action[iter_7_0].items[var_7_8].delay = var_7_2
					arg_7_0.action[iter_7_0].items[var_7_8].effect = true
				end

				var_7_12:setContentSize(var_7_6.width, 50)
				var_7_11:addContent(var_7_12)
				var_7_11:setItemSize(var_7_6.width, 50)
				arg_7_0.listView_:addItem(var_7_11)

				var_7_7 = var_7_7 + var_7_11:getContentSize().height
			end
		else
			local var_7_15 = arg_7_0.listView_:newItem()
			local var_7_16 = cc.Node:create()

			var_7_16:setContentSize(var_7_6.width, 50)
			cc.ui.UILabel.new({
				UILabelType = 2,
				font = "fonts/main_font.ttf",
				size = 30,
				text = var_0_5:translation("MAILBOX_READ")
			}):pos(240, 35):addTo(var_7_16)
			var_7_15:addContent(var_7_16)
			var_7_15:setItemSize(var_7_6.width, 50)
			arg_7_0.listView_:addItem(var_7_15)

			var_7_2 = var_7_2 + 0.08

			local var_7_17 = var_7_8 + 1

			arg_7_0.action[iter_7_0].items[var_7_17] = {}
			arg_7_0.action[iter_7_0].items[var_7_17].view = var_7_15
			arg_7_0.action[iter_7_0].items[var_7_17].delay = var_7_2
			arg_7_0.action[iter_7_0].items[var_7_17].effect = true
			var_7_7 = var_7_7 + var_7_15:getContentSize().height
		end

		arg_7_0.action[iter_7_0].height = var_7_7
	end

	xyd.addTouchEvent(arg_7_0.receiveBtn, function()
		xyd.WindowManager.get():closeWindow(arg_7_0.name)
	end)
	arg_7_0:playAction()
end

function var_0_1.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevX_ = arg_9_1.x
	elseif arg_9_1.name == "moved" and 6 <= math.abs(arg_9_1.x - arg_9_0.prevX_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

function var_0_1.receiveOnekey(arg_10_0)
	arg_10_0.mailbox:onekey(arg_10_0.mailIds, function(arg_11_0, arg_11_1)
		if arg_11_0 == xyd.error.OK then
			arg_10_0:playAction()

			wnd = xyd.WindowManager.get():getWindow("mailbox")

			wnd:updateMailList()
		end
	end)
end

function var_0_1.playAction(arg_12_0)
	arg_12_0.listView_:reload()

	arg_12_0.isend = true

	arg_12_0.receiveBtn:setVisible(false)
	arg_12_0:nodeByName("receive_txt"):setString(var_0_5:translation("OBTAIN"))

	arg_12_0.actionHandles = {}

	local var_12_0 = -arg_12_0:nodeByName("scroll_container"):getContentSize().height

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.action) do
		var_12_0 = var_12_0 + iter_12_1.height

		if var_12_0 > 0 then
			local var_12_1 = var_12_0

			table.insert(arg_12_0.actionHandles, var_0_4.performWithDelayGlobal(handler(arg_12_0, function()
				transition.moveBy(arg_12_0.listView_.container, {
					time = 0.2,
					x = 0,
					y = var_12_1
				})
			end), iter_12_1.items[1].delay))

			var_12_0 = 0
		end

		for iter_12_2, iter_12_3 in ipairs(iter_12_1.items) do
			iter_12_3.view:setVisible(false)
			table.insert(arg_12_0.actionHandles, var_0_4.performWithDelayGlobal(handler(arg_12_0, function()
				iter_12_3.view:setVisible(true)

				if iter_12_3.effect then
					local var_14_0 = transition.sequence({
						cc.ScaleTo:create(0.1, 1.1),
						cc.ScaleTo:create(0.1, 1)
					})

					iter_12_3.view:runAction(var_14_0)
				end
			end), iter_12_3.delay))
		end
	end

	local var_12_2 = #arg_12_0.action
	local var_12_3 = #arg_12_0.action[var_12_2].items

	table.insert(arg_12_0.actionHandles, var_0_4.performWithDelayGlobal(handler(arg_12_0, function()
		arg_12_0.receiveBtn:setVisible(true)
		arg_12_0:nodeByName("text_title"):setVisible(false)
	end), arg_12_0.action[var_12_2].items[var_12_3].delay))
end

function var_0_1.didOpen(arg_16_0, arg_16_1)
	var_0_1.super:didOpen(arg_16_1)

	arg_16_0.blockLayer_ = display.newColorLayer(cc.c4b(0, 0, 0, 200))

	local var_16_0 = arg_16_0:convertToWorldSpace(cc.p(0, 0))

	arg_16_0.blockLayer_:pos(-var_16_0.x, -var_16_0.y):addTo(arg_16_0, -1)

	local function var_16_1(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended and not arg_16_0.isend then
			local var_17_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_17_0, false)
			xyd.WindowManager.get():closeWindow(arg_16_0.name)
		end

		return true
	end

	local function var_16_2(arg_18_0, arg_18_1)
		if not arg_16_0.isend then
			local var_18_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_18_0, false)
			xyd.WindowManager.get():closeWindow(arg_16_0.name)
		end

		if callback then
			callback()
		end
	end

	if not touchFalse then
		arg_16_0.layerListener = cc.EventListenerTouchOneByOne:create()

		arg_16_0.layerListener:setSwallowTouches(true)
		arg_16_0.layerListener:registerScriptHandler(var_16_1, cc.Handler.EVENT_TOUCH_BEGAN)
		arg_16_0.layerListener:registerScriptHandler(var_16_2, cc.Handler.EVENT_TOUCH_ENDED)
		arg_16_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_16_0.layerListener, arg_16_0.contentView_)
	end
end

function var_0_1.willClose(arg_19_0, arg_19_1)
	if arg_19_0.actionHandles then
		for iter_19_0, iter_19_1 in ipairs(arg_19_0.actionHandles) do
			var_0_4.unscheduleGlobal(iter_19_1)
		end
	end
end

return var_0_1
