local var_0_0 = class("MailboxWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.item
local var_0_2 = xyd.tables.translation
local var_0_3 = 10
local var_0_4 = 20
local var_0_5 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack_ = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.mailbox = xyd.ModelManager.get():loadModel(xyd.ModelType.MAILBOX)
	arg_1_0.showDetailFlag = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.UPDATE_MAIL_LIST, handler(arg_2_0, arg_2_0.updateMailList))
	arg_2_0:layout()
	arg_2_0.mailbox:loadMailList({
		load_num = xyd.MailPerLoadNum
	}, function()
		if not arg_2_0 or tolua.isnull(arg_2_0) then
			return
		end

		arg_2_0:updateMailList()
		arg_2_0.listView_.scrollNode:setPositionY(0)
		arg_2_0.listView_.scrollNode:runAction(cc.MoveBy:create(0.3, cc.p(0, 450)))
	end)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("tip"):setString(var_0_2:translation("MAIL_BLANK_SENTENCE"))
	arg_5_0:nodeByName("one_key_txt"):setString(var_0_2:translation("MAILBOX_ONEKEY_GET"))

	arg_5_0.items = arg_5_0:nodeByName("items")

	local var_5_0 = arg_5_0.items:getContentSize()

	arg_5_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_0.width, var_5_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0.items):onScroll(handler(arg_5_0, arg_5_0.scrollListener)):setTouchType(true):pos(0, 0)

	arg_5_0.listView_:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0:setContentSize(arg_5_0.items:getContentSize())

	arg_5_0.onekeyBtn = arg_5_0:nodeByName("one_key_btn")

	arg_5_0.onekeyBtn:setTouchEnabled(true)
	xyd.addTouchEvent(arg_5_0.onekeyBtn, function()
		arg_5_0:onekeyPre()
	end)
	arg_5_0:onekeyBtnShow()
end

function var_0_0.onekeyPre(arg_7_0)
	arg_7_0.onekeyMails = {}
	arg_7_0.onekeyIds = {}

	local var_7_0 = {}
	local var_7_1 = 0
	local var_7_2 = false

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.mailbox.mails_) do
		if iter_7_1.is_new and iter_7_1.is_new > 0 and iter_7_1.category ~= xyd.specialMail.updateOffset and iter_7_1.category ~= xyd.specialMail.onlyAndroid and iter_7_1.category ~= xyd.specialMail.onlyIos then
			table.insert(arg_7_0.onekeyMails, iter_7_1)

			var_7_1 = var_7_1 + 1

			if var_7_1 > var_0_4 then
				var_7_2 = true

				break
			end

			if iter_7_1.is_region then
				if arg_7_0.onekeyIds.region_ids then
					arg_7_0.onekeyIds.region_ids = arg_7_0.onekeyIds.region_ids .. "|" .. iter_7_1.id
				else
					arg_7_0.onekeyIds.region_ids = "" .. iter_7_1.id
				end
			elseif arg_7_0.onekeyIds.normal_ids then
				arg_7_0.onekeyIds.normal_ids = arg_7_0.onekeyIds.normal_ids .. "|" .. iter_7_1.id
			else
				arg_7_0.onekeyIds.normal_ids = "" .. iter_7_1.id
			end
		end

		if iter_7_1.attach and next(iter_7_1.attach) and iter_7_1.category ~= xyd.specialMail.updateOffset and iter_7_1.category ~= xyd.specialMail.onlyAndroid and iter_7_1.category ~= xyd.specialMail.onlyIos then
			for iter_7_2, iter_7_3 in ipairs(iter_7_1.attach) do
				local var_7_3 = iter_7_3.item

				if var_7_3 and var_7_3 ~= "mana" and var_7_3 ~= "crystal" and var_7_3 ~= "arena_coin" and var_7_3 ~= "top_coin" and var_7_3 ~= "guild_coin" and var_7_3 ~= "region_coin" and var_7_3 ~= "honor_coin" and var_7_3 ~= "paradise_coin" and var_7_3 ~= "magic_liquid" and var_7_3 ~= "spirit_stone" and var_7_3 ~= "magic_dust" and var_7_3 ~= "magic_energy" and var_7_3 ~= "team_dungeon_coin" and var_7_3 ~= "god_war_coin" then
					local var_7_4 = tonumber(var_7_3)

					if var_7_0[var_7_4] then
						var_7_0[var_7_4] = var_7_0[var_7_4] + iter_7_3.num
					else
						var_7_0[var_7_4] = iter_7_3.num
					end
				end
			end
		end
	end

	if var_7_2 then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.split(var_0_2:translation("MAILBOX_ONEKEY_TIPS"), "|"), function()
			arg_7_0:onekeyCheck(var_7_0)
		end, nil, nil, arg_7_0.colorMode)
	else
		arg_7_0:onekeyCheck(var_7_0)
	end
end

function var_0_0.onekeyCheck(arg_9_0, arg_9_1)
	local function var_9_0()
		arg_9_0.mailbox:onekey(arg_9_0.onekeyIds, function(arg_11_0, arg_11_1)
			if arg_11_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("mailbox_onekey", {
					mails = arg_9_0.onekeyMails
				})
				arg_9_0:updateMailList()
			end
		end)
	end

	local var_9_1 = {}

	for iter_9_0, iter_9_1 in pairs(arg_9_1) do
		local var_9_2 = arg_9_0.backpack_:getItemNumByID(iter_9_0)

		if iter_9_1 + var_9_2 > var_0_1:stack(iter_9_0) then
			table.insert(var_9_1, {
				item = iter_9_0,
				num = var_9_2 + iter_9_1 - var_0_1:stack(iter_9_0)
			})
		end
	end

	if #var_9_1 > 0 then
		xyd.WindowManager.get():openWindow("excessnotice", {
			overItem = var_9_1,
			onekey = var_9_0
		})
	else
		var_9_0()
	end
end

function var_0_0.delegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = arg_12_0.mailbox:getMails()

	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return #var_12_0
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		if arg_12_3 > #var_12_0 then
			return nil
		end

		local var_12_1 = var_12_0[arg_12_3]
		local var_12_2 = arg_12_0.listView_:dequeueItem()

		if not var_12_2 then
			var_12_2 = arg_12_0.listView_:newItem()
		else
			var_12_2:removeAllChildren(true)
		end

		local var_12_3 = import("app.windows.MailItem").new()

		var_12_3:setParams({
			mail = var_12_1,
			idx = arg_12_3,
			callback = function(arg_13_0)
				xyd.WindowManager.get():openWindow("mail_new_detail", arg_13_0)
			end
		})

		local var_12_4 = var_12_3:contentView():getContentSize()

		var_12_2:addContent(var_12_3)
		var_12_2:setItemSize(var_12_4.width, var_12_4.height)

		return var_12_2
	end
end

function var_0_0.updateMailList(arg_14_0)
	arg_14_0.listView_:reload()
	arg_14_0:onekeyBtnShow()
end

function var_0_0.scrollListener(arg_15_0, arg_15_1)
	if arg_15_1.name == "began" then
		arg_15_0.nodeY = arg_15_0.listView_:getScrollNode():getPositionY()
		arg_15_0.is_scroll = false
		arg_15_0.scrollViewMoved_ = false
		arg_15_0.prevY_ = arg_15_1.y
	elseif arg_15_1.name == "moved" then
		if 1 <= math.abs(arg_15_1.y - arg_15_0.prevY_) then
			arg_15_0.scrollViewMoved_ = true
		end

		if arg_15_0.mailbox:getMailsNum() < arg_15_0.mailbox:getTotal() then
			if arg_15_0.listView_:getScrollNode():getPositionY() > arg_15_0.mailbox:getMailsNum() * 149 + 25 then
				arg_15_0.is_scroll = true
			else
				arg_15_0.is_scroll = false
			end
		end
	elseif arg_15_1.name == "scrollEnd" and arg_15_0.is_scroll == true then
		arg_15_0.mailbox:loadMailList({
			load_num = arg_15_0.mailbox:getMailsNum() + xyd.MailPerLoadNum
		}, function()
			if arg_15_0.listView_ and arg_15_0.listView_.getScrollNode and not tolua.isnull(arg_15_0.listView_) then
				local var_16_0 = arg_15_0.listView_:getScrollNode()
				local var_16_1 = var_16_0:getPositionY()

				var_16_0:setPositionY(var_16_1 + 20)
			end
		end)

		arg_15_0.is_scroll = false
	end
end

function var_0_0.onekeyBtnShow(arg_17_0)
	local var_17_0 = 0

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.mailbox.mails_) do
		if iter_17_1.is_new and iter_17_1.is_new > 0 and iter_17_1.category ~= xyd.specialMail.updateOffset and iter_17_1.category ~= xyd.specialMail.onlyAndroid and iter_17_1.category ~= xyd.specialMail.onlyIos then
			var_17_0 = var_17_0 + 1
		end
	end

	arg_17_0.onekeyBtn:setVisible(var_17_0 >= var_0_5)
	arg_17_0:nodeByName("npc"):setVisible(#arg_17_0.mailbox.mails_ == 0)
end

return var_0_0
