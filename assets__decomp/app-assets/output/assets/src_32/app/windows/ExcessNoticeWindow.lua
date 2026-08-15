local var_0_0 = class("ExcessNoticeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.selfplayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfplayer:getBackpack()
	arg_1_0.mailbox = xyd.ModelManager.get():loadModel(xyd.ModelType.MAILBOX)
end

function var_0_0.getAwardItem(arg_2_0)
	local var_2_0 = arg_2_0.attach

	if var_2_0 == nil then
		return
	end

	for iter_2_0 = 1, #var_2_0 do
		if var_2_0[iter_2_0].item == "mana" or var_2_0[iter_2_0].item == "crystal" or var_2_0[iter_2_0].item == "arena_coin" or var_2_0[iter_2_0].item == "top_coin" or var_2_0[iter_2_0].item == "guild_coin" or var_2_0[iter_2_0].item == "region_coin" or var_2_0[iter_2_0].item == "honor_coin" or var_2_0[iter_2_0].item == "paradise_coin" or var_2_0[iter_2_0].item == "paradise_coin" or var_2_0[iter_2_0].item == "magic_liquid" or var_2_0[iter_2_0].item == "spirit_stone" or var_2_0[iter_2_0].item == "magic_dust" or var_2_0[iter_2_0].item == "magic_energy" or var_2_0[iter_2_0].item == "god_war_coin" then
			table.insert(arg_2_0.noLimitItem, {
				item = var_2_0[iter_2_0].item,
				num = var_2_0[iter_2_0].num
			})
		else
			table.insert(arg_2_0.awardsItem, {
				item = tonumber(var_2_0[iter_2_0].item),
				num = var_2_0[iter_2_0].num
			})
		end
	end
end

function var_0_0.getOverItem(arg_3_0)
	local var_3_0
	local var_3_1

	for iter_3_0 = 1, #arg_3_0.awardsItem do
		local var_3_2 = arg_3_0.backpack:getItemNumByID(arg_3_0.awardsItem[iter_3_0].item)

		if tonumber(arg_3_0.awardsItem[iter_3_0].num) + var_3_2 > var_0_1:stack(arg_3_0.awardsItem[iter_3_0].item) then
			table.insert(arg_3_0.overItem, {
				item = arg_3_0.awardsItem[iter_3_0].item,
				num = var_3_2 + tonumber(arg_3_0.awardsItem[iter_3_0].num) - var_0_1:stack(arg_3_0.awardsItem[iter_3_0].item)
			})
		else
			table.insert(arg_3_0.noLimitItem, {
				item = arg_3_0.awardsItem[iter_3_0].item,
				num = arg_3_0.awardsItem[iter_3_0].num
			})
		end
	end
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevX_ = arg_4_1.x
	elseif arg_4_1.name == "moved" and 1 <= math.abs(arg_4_1.x - arg_4_0.prevX_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = #arg_5_0.overItem

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return var_5_0
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_1
		local var_5_2 = arg_5_0.listView_:dequeueItem()

		if not var_5_2 then
			var_5_2 = arg_5_0.listView_:newItem()
		else
			var_5_2:removeAllChildren()
		end

		local var_5_3 = display.newNode()

		var_5_3:setContentSize(100, 100)

		local var_5_4 = arg_5_0.overItem[arg_5_3].item
		local var_5_5 = arg_5_0.overItem[arg_5_3].num

		xyd.setItemBorder(var_5_3, var_5_4, nil, nil, var_5_5)
		var_5_3:setTouchSwallowEnabled(false)
		var_5_2:setItemSize(var_5_3:getWidth() + 20, var_5_3:getHeight())
		var_5_3:align(display.CENTER, var_5_2:getWidth(), var_5_2:getHeight())
		var_5_2:addContent(var_5_3)

		return var_5_2
	end
end

function var_0_0.didOpen(arg_6_0)
	arg_6_0:addBlockLayer()
end

function var_0_0.willOpen(arg_7_0, arg_7_1)
	arg_7_0:nodeByName("tip1"):setString(xyd.tables.translation:translation("EXCESS_NOTICE_DES"))
	arg_7_0:nodeByName("tip2"):setString(xyd.tables.translation:translation("CONTINUE_TO_RECEIVE"))
	arg_7_0:nodeByName("title"):setString(xyd.tables.translation:translation("EXCESS_TITLE"))

	arg_7_0.awardsItem = {}
	arg_7_0.overItem = {}
	arg_7_0.noLimitItem = {}
	arg_7_0.idx = arg_7_1.idx
	arg_7_0.attach = arg_7_1.attach
	arg_7_0.mail = arg_7_1.mail
	arg_7_0.onekey = arg_7_1.onekey

	arg_7_0:getAwardItem()

	if arg_7_1.overItem then
		arg_7_0.overItem = arg_7_1.overItem
	else
		arg_7_0:getOverItem()
	end

	arg_7_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_7_0:nodeByName("item_scroll"):getWidth(), arg_7_0:nodeByName("item_scroll"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_7_0:nodeByName("item_scroll")):onScroll(handler(arg_7_0, arg_7_0.scrollListener))

	arg_7_0.listView_:setBounceable(true)
	arg_7_0.listView_:setDelegate(handler(arg_7_0, arg_7_0.delegate))
	arg_7_0.listView_:reload()
	arg_7_0:nodeByName("btn_get"):setTouchEnabled(true)
	arg_7_0:nodeByName("btn_later"):setTouchEnabled(true)
	xyd.addTouchEvent(arg_7_0:nodeByName("btn_get"), function()
		if arg_7_0.onekey then
			arg_7_0.onekey()
		else
			arg_7_0.mailbox:readMail(arg_7_0.mail, function(arg_9_0)
				if xyd.WindowManager.get():getWindow("mail_new_detail") then
					xyd.WindowManager.get():closeWindow("mail_new_detail")
				end
			end)
		end

		xyd.WindowManager.get():closeWindow(arg_7_0.name)
	end)
	xyd.addTouchEvent(arg_7_0:nodeByName("btn_later"), function()
		xyd.WindowManager.get():closeWindow(arg_7_0.name)
	end)
end

return var_0_0
