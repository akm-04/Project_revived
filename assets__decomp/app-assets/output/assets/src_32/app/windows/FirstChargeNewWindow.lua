local var_0_0 = class("FirstChargeNewWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.firstChargeNewGiftTable
local var_0_3 = import("app.model.Hero")
local var_0_4 = require("framework.scheduler")
local var_0_5 = 90001001
local var_0_6 = 1
local var_0_7 = 980
local var_0_8 = 10001180
local var_0_9 = {
	show = var_0_1:translation("FIRST_CHARGE_TIP_1"),
	charge = var_0_1:translation("ACTIVITY_1130_TIP4"),
	get = var_0_1:translation("FIRST_STORE_AWARD_TEXT7"),
	haveget = var_0_1:translation("FIRST_STORE_AWARD_TEXT8")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.params = arg_1_2
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayer()

	local var_2_0 = arg_2_0:nodeByName("list")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.list = cc.ui.UIListView.new({
		async = true,
		framing = true,
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_2_0)

	arg_2_0.list:setBounceable(false)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.REFRESH_CHARGE_ACTIVITY, function(arg_3_0)
		arg_2_0.activities:loadSingleActivity({
			activity_id = xyd.Activities.FirstRechargeNew
		}, function(arg_4_0, arg_4_1)
			arg_2_0.params = arg_4_1

			arg_2_0:updateBtnState()
		end)
	end)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super.willOpen(arg_5_0, arg_5_1)
	arg_5_0:layout()
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("btn_show"):getChildByName("txt_show"):setString(var_0_9.show)

	local var_6_0 = var_0_2:getGiftID(1)

	arg_6_0.giftItems = xyd.tables.gift:items(var_6_0)
	arg_6_0.itemNums = xyd.tables.gift:itemNum(var_6_0)

	arg_6_0.list:setDelegate(handler(arg_6_0, arg_6_0.delegate))
	arg_6_0:updateBtnState()
	arg_6_0:setButtonClick()
	arg_6_0:playWindowAction()
end

function var_0_0.delegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #arg_7_0.giftItems or 0
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0
		local var_7_1 = arg_7_0.list:dequeueItem()

		if not var_7_1 then
			var_7_1 = arg_7_0.list:newItem()
		else
			var_7_1:removeAllChildren(true)
		end

		local var_7_2 = arg_7_0:createListContent(arg_7_3)

		var_7_1:setItemSize(553, 97)
		var_7_1:addContent(var_7_2)

		return var_7_1
	end
end

function var_0_0.createListContent(arg_8_0, arg_8_1)
	local var_8_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/first_store_award_version2/award_item.csb")
	local var_8_1 = var_8_0:getChildByName("container")
	local var_8_2 = var_8_1:getChildByName("icon")

	xyd.setItemAndAddTips(var_8_2, arg_8_0.giftItems[arg_8_1], arg_8_0.itemNums[arg_8_1])

	local var_8_3 = xyd.tables.item:name(arg_8_0.giftItems[arg_8_1])
	local var_8_4 = xyd.tables.item:desc1(arg_8_0.giftItems[arg_8_1])

	var_8_1:getChildByName("txt_name"):setString(var_8_3)
	var_8_1:getChildByName("txt_message"):setString(var_8_4)

	return var_8_0
end

function var_0_0.playWindowAction(arg_9_0)
	local var_9_0, var_9_1 = arg_9_0:nodeByName("container"):getPosition()

	arg_9_0:nodeByName("container"):setPosition(cc.p(1280, var_9_1))
	arg_9_0:nodeByName("container"):setScale(0)

	local var_9_2 = cc.Sequence:create({
		cc.ScaleTo:create(0, 1, 0.01),
		cc.MoveTo:create(0.1, cc.p(var_9_0, var_9_1)),
		cc.ScaleTo:create(0.1, 1, 1),
		cc.ScaleTo:create(0.05, 1, 1.3),
		cc.ScaleTo:create(0.05, 1, 1),
		cc.CallFunc:create(function()
			arg_9_0.list:reload()
		end)
	})

	arg_9_0:nodeByName("container"):runActionOnce(var_9_2)
end

function var_0_0.updatePageShow(arg_11_0)
	if arg_11_0.page == 1 then
		arg_11_0:nodeByName("page_left"):setVisible(false)
		arg_11_0:nodeByName("page_right"):setVisible(true)
		arg_11_0:nodeByName("three_select"):setVisible(true)
		arg_11_0:nodeByName("zhilong_container"):setVisible(false)
		arg_11_0:nodeByName("charge_btn"):setPosition(-358, -130)
	else
		arg_11_0:nodeByName("page_left"):setVisible(true)
		arg_11_0:nodeByName("page_right"):setVisible(false)
		arg_11_0:nodeByName("three_select"):setVisible(false)
		arg_11_0:nodeByName("zhilong_container"):setVisible(true)
		arg_11_0:nodeByName("charge_btn"):setPosition(-295, -30)
	end

	arg_11_0:updateBtnState()
end

function var_0_0.updateBtnState(arg_12_0)
	arg_12_0.hasAwardGift = arg_12_0.params.details.is_awarded
	arg_12_0.canAwardGift = arg_12_0.params.details.can_award

	arg_12_0:nodeByName("btn_charge"):getChildByName("txt_charge"):setString(var_0_9.charge)

	if arg_12_0.hasAwardGift == 0 and arg_12_0.canAwardGift == 0 then
		arg_12_0:nodeByName("btn_charge"):getChildByName("txt_charge"):setString(var_0_9.charge)
		arg_12_0:nodeByName("btn_charge"):setBright(true)
	elseif arg_12_0.hasAwardGift == 1 then
		arg_12_0:nodeByName("btn_charge"):getChildByName("txt_charge"):setString(var_0_9.haveget)
		arg_12_0:nodeByName("btn_charge"):setBright(false)
	elseif arg_12_0.canAwardGift == 1 then
		arg_12_0:nodeByName("btn_charge"):getChildByName("txt_charge"):setString(var_0_9.get)
		arg_12_0:nodeByName("btn_charge"):setBright(true)
	end
end

function var_0_0.setButtonClick(arg_13_0)
	arg_13_0:nodeByName("btn_charge"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.began then
			arg_13_0:nodeByName("btn_charge"):setScale(0.9)
		elseif arg_14_1 == ccui.TouchEventType.moved then
			arg_13_0:nodeByName("btn_charge"):setScale(1)
		elseif arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_13_0:nodeByName("btn_charge"):setScale(1)

			if arg_13_0.canAwardGift == 1 and arg_13_0.hasAwardGift == 0 then
				arg_13_0.activitiesModel:getActivityReward(xyd.Activities.FirstRechargeNew, var_0_6, function(arg_15_0, arg_15_1)
					if arg_15_0 == xyd.error.OK then
						arg_13_0.selfPlayer:handleRewards(arg_15_1.awards)
						arg_13_0.activitiesModel:clearRedMarkState(xyd.Activities.FirstRechargeNew, 2)

						if arg_13_0.activitiesModel.activities and next(arg_13_0.activitiesModel.activities) then
							for iter_15_0, iter_15_1 in ipairs(arg_13_0.activitiesModel.activities) do
								if iter_15_1.table_id == xyd.Activities.FirstRechargeNew and iter_15_1.is_open == 1 and iter_15_1.details and iter_15_1.details.is_awarded == 0 then
									arg_13_0.activitiesModel.activities[iter_15_0].details.is_awards = 1
								end
							end
						end

						arg_13_0:refreshActivityMain()
						xyd.WindowManager.get():closeWindow(arg_13_0)
					end
				end)
			else
				local var_14_0 = {
					chargeState = xyd.ChargeState.diamond
				}

				xyd.WindowManager.get():openWindow("vip_recharge", var_14_0)
			end
		end
	end)

	local var_13_0 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.selfPlayer.heros_) do
		local var_13_1 = iter_13_1:getTableID()

		if xyd.getOriginHeroId(var_13_1) == var_0_8 then
			table.insert(var_13_0, iter_13_1)
		end
	end

	if not var_13_0 or not next(var_13_0) then
		local var_13_2 = var_0_3.new()

		var_13_2:initUnCollected(var_0_8)
		table.insert(var_13_0, var_13_2)
	end

	arg_13_0:nodeByName("btn_show"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.began then
			arg_13_0:nodeByName("btn_show"):setScale(0.9)
		elseif arg_16_1 == ccui.TouchEventType.moved then
			arg_13_0:nodeByName("btn_show"):setScale(1)
		elseif arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_13_0:nodeByName("btn_show"):setScale(1)

			local var_16_0 = {
				heros = var_13_0
			}

			var_16_0.current = 1
			var_16_0.showType = 2

			xyd.WindowManager.get():openWindow("tujian_herodetail", var_16_0)
		end
	end)
	arg_13_0:nodeByName("close"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.began then
			arg_13_0:nodeByName("close"):setScale(0.9)
		elseif arg_17_1 == ccui.TouchEventType.moved then
			arg_13_0:nodeByName("close"):setScale(1)
		elseif arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_13_0:nodeByName("close"):setScale(1)
			xyd.WindowManager.get():closeWindow(arg_13_0)
		end
	end)
end

function var_0_0.refreshActivityMain(arg_18_0)
	local var_18_0 = false
	local var_18_1 = false

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_CHARGE_ACTIVITY_MAIN,
		params = {
			isShow = var_18_0,
			hasPoint = var_18_1
		}
	})
end

return var_0_0
