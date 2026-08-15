local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.count = arg_1_1.idx
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	arg_2_0.container = var_2_0:getChildByName("bg")

	arg_2_0:layout()
end

function var_0_0.initListView(arg_3_0)
	local var_3_0 = arg_3_0.container:getChildByName("word_bg"):getChildByName("list"):getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0.container:getChildByName("word_bg"):getChildByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevX_ = arg_4_1.x
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 5 <= math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:initListView()
	arg_5_0:initRule()
end

function var_0_0.initRule(arg_6_0)
	local var_6_0

	if not arg_6_0.split then
		var_6_0 = xyd.split(var_0_1:translation("ACTIVITY_1077_TEXT1"), "&")
	end

	for iter_6_0 = 1, #var_6_0 do
		local var_6_1 = xyd.split(var_6_0[iter_6_0], "#")

		for iter_6_1 = 1, #var_6_1 do
			if iter_6_1 == 1 then
				local var_6_2 = display.newNode()
				local var_6_3 = arg_6_0.list:newItem()
				local var_6_4 = display.newNode()
				local var_6_5 = {
					size = 22,
					color = cc.c3b(255, 235, 157),
					dimensions = cc.size(120, 0),
					text = var_6_1[1]
				}
				local var_6_6 = xyd.AssetLoader.get():loadLabel(var_6_5)

				var_6_6:addTo(var_6_4)
				var_6_6:setAnchorPoint(cc.p(0, 0))
				var_6_6:setPosition(cc.p(0, 0))
				var_6_6:enableShadow(cc.c4b(134, 26, 26, 255), cc.size(2, -2))

				local var_6_7 = var_6_6:getContentSize().height

				var_6_4:setContentSize(120, var_6_7)
				var_6_4:addTo(var_6_2)
				var_6_4:setPositionX(25)
				var_6_4:setPositionY(0)

				local var_6_8 = xyd.AssetLoader.get():loadSprite("windows/activities/1077/icon_decoration.png")

				var_6_8:addTo(var_6_2)
				var_6_8:setAnchorPoint(cc.p(0, 0.5))
				var_6_8:setPositionX(0)
				var_6_8:setPositionY(var_6_7 / 2)
				var_6_2:setContentSize(530, var_6_7)
				var_6_3:addContent(var_6_2)
				var_6_3:setItemSize(530, var_6_7)
				arg_6_0.list:addItem(var_6_3)
			else
				local var_6_9 = display.newNode()
				local var_6_10 = arg_6_0.list:newItem()
				local var_6_11 = display.newNode()
				local var_6_12 = {
					size = 22,
					color = cc.c3b(255, 246, 203),
					dimensions = cc.size(485, 0),
					text = var_6_1[iter_6_1]
				}
				local var_6_13 = xyd.AssetLoader.get():loadLabel(var_6_12)

				var_6_13:addTo(var_6_11)
				var_6_13:setAnchorPoint(cc.p(0, 0))
				var_6_13:setPosition(cc.p(0, 0))
				var_6_13:enableShadow(cc.c4b(134, 26, 26, 255), cc.size(2, -2))

				local var_6_14 = var_6_13:getContentSize().height

				var_6_11:setContentSize(480, var_6_14)
				var_6_11:addTo(var_6_9)
				var_6_11:setPositionX(25)
				var_6_11:setPositionY(var_6_11:getPositionY() - 2.5)
				var_6_9:setContentSize(530, var_6_14)
				var_6_10:addContent(var_6_9)
				var_6_10:setItemSize(530, var_6_14 + 5)
				arg_6_0.list:addItem(var_6_10)
			end
		end

		local var_6_15 = arg_6_0.list:newItem()

		var_6_15:addContent(display.newNode())
		var_6_15:setItemSize(530, 10)
		arg_6_0.list:addItem(var_6_15)
	end

	arg_6_0.list:reload()
end

return var_0_0
