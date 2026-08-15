local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityZhangheDollShop
local var_0_3 = 4

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
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
	arg_2_0:layout(var_2_0)
end

function var_0_0.layout(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1:getChildByName("bg_content")
	local var_3_1 = var_3_0:getChildByName("item_container")
	local var_3_2 = var_3_1:getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_2.width, var_3_2.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_1):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0:updateListInfo()
	arg_3_0.list:reload()
	arg_3_1:getChildByName("bg_rule"):getChildByName("rule_text"):setString(var_0_1:translation("ACTIVITY_ZHANGHE_DOLL_RULE2"))

	local var_3_3 = var_3_0:getChildByName("btn_exchange")

	var_3_3:getChildByName("txt"):setString(var_0_1:translation("EXCHANGE_AWARD"))
	var_3_3:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			arg_4_0:setScale(0.9)
		elseif arg_4_1 == ccui.TouchEventType.canceled then
			arg_4_0:setScale(1)
		elseif arg_4_1 == ccui.TouchEventType.ended then
			arg_4_0:setScale(1)

			if xyd.ServerTime.get():getServerTime() >= arg_3_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_3_0.activity.end_time then
				local var_4_0 = {
					details = arg_3_0.activity
				}

				xyd.WindowManager.get():openWindow("zhanghe_doll_exchange", var_4_0)
			else
				if xyd.ServerTime.get():getServerTime() < arg_3_0.activity.start_time then
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_3_0.activity.end_time then
					message = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = message
				})
			end
		end
	end)
end

function var_0_0.updateListInfo(arg_5_0)
	arg_5_0.listInfo = var_0_2:ids()
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return (math.ceil(#arg_6_0.listInfo / var_0_3))
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0 = arg_6_0.list:dequeueItem()

		if not var_6_0 then
			var_6_0 = arg_6_0.list:newItem()
		else
			var_6_0:removeAllChildren(true)
		end

		local var_6_1 = 400
		local var_6_2 = 90

		var_6_0:setItemSize(var_6_1, var_6_2)

		local var_6_3 = display.newNode()

		var_6_3:setContentSize(var_6_1, 86)
		arg_6_0:initCell(var_6_3, arg_6_3)
		var_6_0:addContent(var_6_3)

		return var_6_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_6_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_7_0, arg_7_1, arg_7_2)
	for iter_7_0 = 1, var_0_3 do
		local var_7_0 = (arg_7_2 - 1) * var_0_3 + iter_7_0

		if var_7_0 > #arg_7_0.listInfo then
			break
		end

		local var_7_1 = display.newNode()

		var_7_1:setContentSize(86, 86)
		var_7_1:setPosition(100 * iter_7_0 - 50, 43)
		var_7_1:setAnchorPoint(0.5, 0.5)
		arg_7_1:addChild(var_7_1)
		var_7_1:setTouchEnabled(true)
		var_7_1:setTouchSwallowEnabled(false)

		local var_7_2 = var_0_2:itemID(arg_7_0.listInfo[var_7_0])

		xyd.setItemBorder(var_7_1, var_7_2)

		local var_7_3 = {
			id = var_7_2,
			lev = xyd.tables.item:level(var_7_2)
		}

		if xyd.tables.item:type(var_7_2) == -1 then
			var_7_3.tipsType = 0
			var_7_3.desc1 = xyd.tables.hero:getDes(var_7_2)
		elseif specialItem then
			var_7_3.tipsType = 1
			var_7_3.id = -3
		else
			var_7_3.tipsType = 1
			var_7_3.desc1 = xyd.tables.item:desc1(var_7_2)
			var_7_3.desc2 = xyd.tables.item:desc2(var_7_2)
		end

		var_7_3.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_7_2)
		var_7_3.name = xyd.tables.item:name(var_7_2)

		arg_7_0:addTips(var_7_1, var_7_3)
	end
end

return var_0_0
