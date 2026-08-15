local var_0_0 = class("NewTermMyPresentItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = 1000
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.newTermGift
local var_0_5 = 80

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/new_term/my_present_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
		arg_3_0:setContentSize(arg_3_0.contentView_:getContentSize().width, arg_3_0.contentView_:getContentSize().height)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	arg_4_0.contentView_:nodeByName("player_avatar"):setContentSize(var_0_5, var_0_5)
	arg_4_0.contentView_:nodeByName("player_avatar"):setAnchorPoint(0.5, 0.5)
	xyd.setPlayerAvatar(arg_4_0.contentView_:nodeByName("player_avatar"), arg_4_1)

	local var_4_0 = ""
	local var_4_1 = json.decode(arg_4_1.items)
	local var_4_2 = 0

	for iter_4_0, iter_4_1 in pairs(var_4_1) do
		local var_4_3 = xyd.tables.item:quality(iter_4_1.item_id)
		local var_4_4 = xyd.tables.item:name(iter_4_1.item_id)
		local var_4_5 = iter_4_1.item_num

		var_4_2 = var_4_2 + var_0_4:charm(iter_4_1.item_id) * var_4_5

		if iter_4_0 == 3 then
			var_4_0 = var_4_0 .. "..."
		elseif iter_4_0 < 3 then
			var_4_0 = var_4_0 .. var_4_0.format(var_0_1:translation("LIANYI_TEXT1"), xyd.tables.misc.newTermTextColor[var_4_3], var_4_4 .. "x" .. var_4_5)
		end
	end

	arg_4_0.contentView_:nodeByName("charm_txt"):setString(var_4_0.format(var_0_1:translation("LIANYI_TEXT8"), ""))
	arg_4_0.contentView_:nodeByName("charm_txt_num"):setString(var_4_2)
	arg_4_0.contentView_:nodeByName("region"):setString("S" .. xyd.getPlayerRegion(arg_4_1.player_id))

	local var_4_6 = xyd.createMultiColorTxt(var_4_0, xyd.color.BLACK, 22, true)

	var_4_6:setContentSize(300, 40)
	var_4_6:addTo(arg_4_0.contentView_:nodeByName("give_detail"))

	if arg_4_1.conquer_lev and arg_4_1.conquer_lev ~= 0 then
		xyd.setConquerLev(arg_4_1.conquer_lev, arg_4_0.contentView_:nodeByName("lev"), arg_4_0.contentView_:nodeByName("level_bg"), nil, nil, nil, nil, arg_4_1.conquer_loop_id)
	else
		arg_4_0.contentView_:nodeByName("lev"):setString(arg_4_1.lev)
	end

	arg_4_0.contentView_:nodeByName("name"):setString(arg_4_1.name or arg_4_1.player_name)
	arg_4_0.contentView_:nodeByName("give_back_button"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("new_term_give_gift_alert", arg_4_1)
		end
	end)
end

local var_0_6 = class("NewTermMyPresentsWindow", import("app.common.ui.BaseWindow"))
local var_0_7 = import("app.common.ui.SpineEffect")
local var_0_8 = xyd.tables.translation
local var_0_9 = import("framework.scheduler")

function var_0_6.ctor(arg_6_0, arg_6_1, arg_6_2)
	var_0_6.super.ctor(arg_6_0, arg_6_1, arg_6_2)

	arg_6_0.giftList = arg_6_2
end

function var_0_6.willOpen(arg_7_0, arg_7_1)
	var_0_6.super.willOpen(arg_7_0, arg_7_1)
end

function var_0_6.didOpen(arg_8_0, arg_8_1)
	var_0_6.super.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
	arg_8_0:layout()
end

function var_0_6.layout(arg_9_0)
	arg_9_0:initListView()
	arg_9_0:updateListView()
end

function var_0_6.initListView(arg_10_0)
	if not arg_10_0.listView_ then
		arg_10_0.listView_ = cc.ui.UIListView.new({
			touchOnContent = true,
			viewRect = cc.rect(0, 0, 790, 450),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_10_0:nodeByName("my_present_list"))
	else
		arg_10_0.listView_:removeAllItems()
	end
end

function var_0_6.updateListView(arg_11_0)
	for iter_11_0 = 1, #arg_11_0.giftList do
		local var_11_0 = arg_11_0.listView_:newItem()
		local var_11_1 = var_0_0.new()

		var_11_1:setParams(arg_11_0.giftList[iter_11_0])
		var_11_0:addContent(var_11_1)
		var_11_0:setItemSize(759, 137)
		arg_11_0.listView_:addItem(var_11_0)
	end

	arg_11_0.listView_:reload()
end

function var_0_6.willClose(arg_12_0)
	if arg_12_0.handle then
		var_0_9.unscheduleGlobal(arg_12_0.handle)

		arg_12_0.handle = nil
	end
end

return var_0_6
