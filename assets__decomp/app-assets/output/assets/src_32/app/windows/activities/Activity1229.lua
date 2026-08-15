local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityDeExchange
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.container:getChildByName("txt_rule"):getVirtualRenderer():setLineHeight(28)
	arg_3_0.container:getChildByName("txt_rule"):setString(var_0_1:translation("ACTIVITY_1229_TEXT_1"))

	arg_3_0.list = cc.ui.UITableView.new({
		itemGap = 22,
		size = arg_3_0.container:getChildByName("list"):getContentSize(),
		direction = cc.ui.UITableView.DIRECTION_HORIZONTAL
	}):addTo(arg_3_0.container:getChildByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0:loadList()
end

function var_0_0.loadList(arg_4_0)
	arg_4_0.list:removeAllItems()

	local var_4_0 = {}
	local var_4_1 = {}

	for iter_4_0 = 1, var_0_2:max() do
		local var_4_2 = var_0_2:limitTimes(iter_4_0) - arg_4_0.activity.details.buy_times[iter_4_0]

		if var_4_2 > 0 then
			table.insert(var_4_0, {
				id = iter_4_0,
				times = var_4_2
			})
		else
			table.insert(var_4_1, {
				times = 0,
				id = iter_4_0
			})
		end
	end

	for iter_4_1, iter_4_2 in ipairs(var_4_1) do
		table.insert(var_4_0, iter_4_2)
	end

	for iter_4_3, iter_4_4 in ipairs(var_4_0) do
		local var_4_3 = arg_4_0.list:newItem()
		local var_4_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1229/item.csb")
		local var_4_5 = var_4_4:getChildByName("container")
		local var_4_6 = var_0_2:partnerId(iter_4_4.id)
		local var_4_7 = arg_4_0.selfPlayer:getHeroIgnoreAwaken(var_4_6)
		local var_4_8 = var_0_3:stoneID(var_4_6)
		local var_4_9 = arg_4_0.backpack:getItemNumByID(var_4_8)

		if var_4_7 then
			xyd.setAvatarBorderNewUI(var_4_7, var_4_5:getChildByName("avatar"))

			if var_4_7:getStar() >= 5 then
				var_4_5:getChildByName("avatar"):addTouchEventListener(function(arg_5_0, arg_5_1)
					if arg_5_1 == ccui.TouchEventType.ended then
						if arg_4_0.scrollViewMoved_ then
							return
						end

						local var_5_0 = {
							id = iter_4_4.id,
							stone_num = var_4_9,
							times = iter_4_4.times,
							callback = function(arg_6_0, arg_6_1)
								arg_4_0.activity.details.buy_times[arg_6_0] = arg_4_0.activity.details.buy_times[arg_6_0] + arg_6_1

								arg_4_0:loadList()
							end
						}

						xyd.WindowManager.get():openWindow("activity_de_exchange", var_5_0)
					end
				end)
			else
				var_4_5:getChildByName("mask"):setVisible(true)
			end
		else
			xyd.setAvatarBorderNewUI(var_4_6, var_4_5:getChildByName("avatar"), 1, 0)
			var_4_5:getChildByName("mask"):setVisible(true)
		end

		var_4_5:getChildByName("txt_name"):setString(var_0_4:name(var_4_8))

		local var_4_10 = string.format(var_0_1:translation("ACTIVITY_1229_TEXT_2"), var_4_9)
		local var_4_11 = xyd.getColorlabel({
			size = 18
		}, var_4_10)

		var_4_11:setAnchorPoint(0.5, 0.5)
		var_4_5:getChildByName("pos_txt_have"):addChild(var_4_11)

		local var_4_12 = string.format(var_0_1:translation("ACTIVITY_1229_TEXT_3"), iter_4_4.times)
		local var_4_13 = xyd.getColorlabel({
			size = 18
		}, var_4_12)

		var_4_13:setAnchorPoint(0.5, 0.5)
		var_4_5:getChildByName("pos_txt_times"):addChild(var_4_13)
		var_4_3:addContent(var_4_4)
		var_4_3:setItemSize(var_4_5:getContentSize())
		arg_4_0.list:addItem(var_4_3)
	end

	arg_4_0.list:refreshList()
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevX_ = arg_7_1.x
	elseif arg_7_1.name == "moved" and math.abs(arg_7_1.x - arg_7_0.prevX_) >= 10 then
		arg_7_0.scrollViewMoved_ = true
	end
end

return var_0_0
