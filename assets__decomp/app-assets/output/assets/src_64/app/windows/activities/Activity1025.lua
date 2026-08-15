local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.show(arg_1_0, arg_1_1)
	var_0_0.super.show(arg_1_0, arg_1_1)

	if not arg_1_0.res or arg_1_0.res == 0 then
		print("No res available.")

		return
	end

	local var_1_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_1_0.res)

	var_1_0:addTo(arg_1_0.parent)
	var_1_0:setAnchorPoint(cc.p(0, 0))
	var_1_0:setPosition(0, 0)

	arg_1_0.container = var_1_0:getChildByName("bg")

	arg_1_0:layout()
end

function var_0_0.initListView(arg_2_0)
	local var_2_0 = arg_2_0.container:getChildByName("list"):getContentSize()

	arg_2_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0.container:getChildByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.scrollViewMoved_ = false
		arg_3_0.prevX_ = arg_3_1.x
		arg_3_0.prevY_ = arg_3_1.y
	elseif arg_3_1.name == "moved" and 5 <= math.abs(arg_3_1.y - arg_3_0.prevY_) then
		arg_3_0.scrollViewMoved_ = true
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:initListView()
	arg_4_0:initRule()
end

function var_0_0.initRule(arg_5_0)
	local var_5_0

	if not arg_5_0.split then
		var_5_0 = xyd.split(var_0_1:translation("ACTIVITY_1025_TEXT"), "&")
	end

	for iter_5_0 = 1, #var_5_0 do
		local var_5_1 = xyd.split(var_5_0[iter_5_0], "#")

		for iter_5_1 = 2, #var_5_1 do
			local var_5_2 = display.newNode()
			local var_5_3 = arg_5_0.list:newItem()
			local var_5_4 = display.newNode()
			local var_5_5 = {
				size = 22,
				color = cc.c3b(255, 253, 242),
				dimensions = cc.size(490, 0),
				text = var_5_1[iter_5_1]
			}
			local var_5_6 = xyd.AssetLoader.get():loadLabel(var_5_5)

			var_5_6:addTo(var_5_4)
			var_5_6:setAnchorPoint(cc.p(0, 0))
			var_5_6:setPosition(cc.p(0, 0))

			local var_5_7 = var_5_6:getContentSize().height
			local var_5_8 = var_5_7

			var_5_4:setContentSize(490, var_5_7)
			var_5_4:addTo(var_5_2)
			var_5_4:setPositionX(25)
			var_5_4:setPositionY(var_5_4:getPositionY() - 2.5)

			local var_5_9 = 0

			if iter_5_1 == 2 then
				local var_5_10 = display.newNode()
				local var_5_11 = {
					size = 24,
					color = cc.c3b(255, 240, 181),
					dimensions = cc.size(120, 0),
					text = var_5_1[1]
				}
				local var_5_12 = xyd.AssetLoader.get():loadLabel(var_5_11)

				var_5_12:addTo(var_5_10)
				var_5_12:setAnchorPoint(cc.p(0, 0))
				var_5_12:setPosition(cc.p(0, 0))

				local var_5_13 = "windows/activities/1025/bg_point.png"
				local var_5_14 = xyd.AssetLoader.get():loadSprite(var_5_13)

				var_5_14:addTo(var_5_10)
				var_5_14:setAnchorPoint(cc.p(0, 0))
				var_5_14:setPosition(cc.p(-25, 0))

				var_5_9 = var_5_12:getContentSize().height

				var_5_10:setContentSize(120, var_5_9)
				var_5_10:addTo(var_5_2)
				var_5_10:setPositionX(25)
				var_5_10:setPositionY(var_5_8 + 12)
			end

			var_5_2:setContentSize(520, var_5_7 + var_5_9 + 25)
			var_5_3:addContent(var_5_2)
			var_5_3:setItemSize(520, var_5_7 + var_5_9 + 25)
			arg_5_0.list:addItem(var_5_3)
		end
	end

	arg_5_0.list:reload()
end

return var_0_0
