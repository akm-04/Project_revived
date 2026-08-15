local var_0_0 = class("MailDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = 476
local var_0_2 = 32
local var_0_3 = 32
local var_0_4 = 65
local var_0_5 = 20
local var_0_6 = xyd.tables.translation
local var_0_7 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.mail = arg_1_2.mail
	arg_1_0.idx = arg_1_2.idx
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.container = arg_2_0:nodeByName("container")

	arg_2_0:setContentSize(arg_2_0.container:getContentSize())

	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.backpack_ = arg_2_0.player_:getBackpack()
	arg_2_0.mailbox_ = xyd.ModelManager.get():loadModel(xyd.ModelType.MAILBOX)

	if arg_2_0.mail then
		arg_2_0.content = arg_2_0.mail.content
		arg_2_0.content = string.gsub(arg_2_0.content, "</n>", "\n")
		arg_2_0.contents = xyd.split(arg_2_0.content, "\n")
		arg_2_0.contentStrs = {}

		for iter_2_0, iter_2_1 in pairs(arg_2_0.contents) do
			if iter_2_1 and iter_2_1 ~= "" then
				local var_2_0 = xyd.splitStrByPairTag(iter_2_1, "<u>", "</u>")

				for iter_2_2, iter_2_3 in pairs(var_2_0) do
					table.insert(arg_2_0.contentStrs, iter_2_3)
				end
			end
		end
	end

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("title_text"):setString(arg_3_0.mail.title)
	arg_3_0:showMailContent()
end

function var_0_0.showMailContent(arg_4_0)
	if not arg_4_0.contentList then
		arg_4_0.contentList = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, 530, 510),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_4_0:nodeByName("content")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))
	else
		arg_4_0.contentList:removeAllItems()
	end

	if arg_4_0.contentStrs and next(arg_4_0.contentStrs) then
		local var_4_0
		local var_4_1
		local var_4_2
		local var_4_3 = 0

		while next(arg_4_0.contentStrs) or var_4_0 do
			if var_4_3 == 0 then
				var_4_2 = display.newNode()

				local var_4_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/mailbox/mail_line.csb")

				var_4_4:addTo(var_4_2)
				var_4_4:setAnchorPoint(cc.p(0, 0))

				var_4_1 = var_4_4:getChildByName("container")

				var_4_2:setContentSize(var_4_1:getContentSize().width, var_4_1:getContentSize().height)
			end

			if var_4_0 and var_4_0.str ~= "" then
				local var_4_5 = var_0_1 - var_4_3

				if var_4_0.type == xyd.ParseStrType.MARK then
					arg_4_0.str = var_4_0.str

					local var_4_6 = xyd.createLinkLabel(var_4_0.str, 24, cc.c3b(0, 73, 255), cc.c4f(0, 0.28627450980392155, 1, 1), 3, function(arg_5_0)
						cc.Application:getInstance():openURL(arg_5_0)
					end)

					if var_4_5 < var_4_6:getContentSize().width then
						var_4_3 = var_0_1
					else
						var_4_6:addTo(var_4_1)
						var_4_6:setAnchorPoint(cc.p(0, 0))
						var_4_6:setPosition(var_0_2 + var_4_3, 13)

						var_4_3 = var_4_3 + var_4_6:getContentSize().width
						var_4_0 = nil
					end
				else
					local var_4_7 = {
						size = 24,
						color = cc.c3b(176, 64, 43)
					}
					local var_4_8 = xyd.AssetLoader.get():loadLabel(var_4_7)

					var_4_8:setString(var_4_0.str)

					if var_4_5 < var_4_8:getContentSize().width then
						local var_4_9 = var_4_0.str
						local var_4_10 = ""
						local var_4_11 = string.len(var_4_0.str)

						for iter_4_0 = 1, math.huge, 3 do
							local var_4_12, var_4_13 = xyd.getSplitUtf8Str(var_4_0.str, 1, iter_4_0)
							local var_4_14 = xyd.AssetLoader.get():loadLabel(var_4_7)

							var_4_14:setString(var_4_12)

							if var_4_5 < var_4_14:getContentSize().width then
								var_4_8:setString(var_4_9)
								var_4_8:setAnchorPoint(cc.p(0, 0))
								var_4_8:addTo(var_4_1)
								var_4_8:setPosition(var_0_2 + var_4_3, 13)

								var_4_0.str = var_4_10
								var_4_3 = var_0_1

								break
							end

							var_4_9 = var_4_12
							var_4_10 = var_4_13
						end
					else
						var_4_8:setAnchorPoint(cc.p(0, 0))
						var_4_8:addTo(var_4_1)
						var_4_8:setPosition(var_0_2 + var_4_3, 13)

						var_4_3 = var_4_8:getContentSize().width + var_4_3
						var_4_0 = nil

						if arg_4_0.contentStrs[1] and arg_4_0.contentStrs[1].type == xyd.ParseStrType.TEXT then
							var_4_3 = var_0_1
						end
					end
				end
			else
				var_4_0 = arg_4_0.contentStrs[1]

				table.remove(arg_4_0.contentStrs, 1)
			end

			if var_4_3 == var_0_1 or not var_4_0 and not next(arg_4_0.contentStrs) then
				local var_4_15 = arg_4_0.contentList:newItem()

				var_4_15:addContent(var_4_2)
				var_4_15:setItemSize(var_4_1:getContentSize().width, var_4_1:getContentSize().height)
				arg_4_0.contentList:addItem(var_4_15)

				var_4_3 = 0
			end
		end
	end

	local var_4_16 = display.newNode()
	local var_4_17 = xyd.AssetLoader.get():loadNodeFromJson("windows/mailbox/mail_line.csb")

	var_4_17:addTo(var_4_16)

	local var_4_18 = var_4_17:getChildByName("container")

	var_4_16:setContentSize(var_4_18:getContentSize().width, var_4_18:getContentSize().height)

	local var_4_19 = {
		size = 24,
		color = cc.c3b(176, 64, 43)
	}
	local var_4_20 = xyd.AssetLoader.get():loadLabel(var_4_19)

	var_4_20:setString(arg_4_0.mail.from)
	var_4_20:setAnchorPoint(cc.p(0, 0))

	local var_4_21 = var_4_20:getContentSize().width

	var_4_20:setPosition(var_4_18:getContentSize().width - var_0_3 - var_4_21, 13)
	var_4_20:addTo(var_4_18)

	local var_4_22 = arg_4_0.contentList:newItem()

	var_4_22:addContent(var_4_16)
	var_4_22:setItemSize(var_4_18:getContentSize().width, var_4_18:getContentSize().height)
	arg_4_0.contentList:addItem(var_4_22)
	arg_4_0:addMailAttachement()

	local var_4_23 = display.newNode()
	local var_4_24 = xyd.AssetLoader.get():loadNodeFromJson("windows/mailbox/confirm_item.csb")

	var_4_24:addTo(var_4_23)

	local var_4_25 = var_4_24:getChildByName("container")
	local var_4_26 = var_4_25:getChildByName("ok_btn")

	if arg_4_0.mail.attach and next(arg_4_0.mail.attach) then
		if arg_4_0.mail.is_new == 1 then
			var_4_25:getChildByName("obtain"):setVisible(true)
			var_4_25:getChildByName("already_get_gray"):setVisible(false)
		else
			var_4_26:setTouchEnabled(false)
			var_4_26:setBright(false)
			var_4_25:getChildByName("already_get_gray"):setVisible(true)
			var_4_25:getChildByName("obtain"):setVisible(false)
		end

		var_4_25:getChildByName("ok"):setVisible(false)
	else
		var_4_25:getChildByName("obtain"):setVisible(false)
		var_4_25:getChildByName("ok"):setVisible(true)
		var_4_25:getChildByName("already_get_gray"):setVisible(false)
	end

	arg_4_0:awardBtnHandle(var_4_26)
	var_4_23:setContentSize(var_4_25:getContentSize().width, var_4_25:getContentSize().height)

	local var_4_27 = arg_4_0.contentList:newItem()

	var_4_27:setItemSize(var_4_25:getContentSize().width, var_4_25:getContentSize().height)
	var_4_27:addContent(var_4_23)
	arg_4_0.contentList:addItem(var_4_27)
	arg_4_0.contentList:reload()
	collectgarbage("collect")
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" and 10 <= math.abs(arg_6_1.y - arg_6_0.prevY_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

function var_0_0.addMailAttachement(arg_7_0)
	if not arg_7_0.mail.attach or not next(arg_7_0.mail.attach) then
		return
	end

	local var_7_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/mailbox/attach_mail.csb")
	local var_7_1 = var_7_0:getChildByName("container")
	local var_7_2 = display.newNode()

	var_7_2:setContentSize(var_7_1:getContentSize().width, var_7_1:getHeight())
	var_7_0:addTo(var_7_2)

	local var_7_3 = #arg_7_0.mail.attach
	local var_7_4 = {}
	local var_7_5 = {}

	for iter_7_0 = 1, var_7_3 do
		local var_7_6 = var_7_3 - iter_7_0 + 1
		local var_7_7 = arg_7_0.mail.attach[var_7_6]
		local var_7_8 = tonumber(var_7_7.item) or 0

		if var_7_8 > 0 then
			table.insert(var_7_5, {
				item = var_7_8,
				num = var_7_7.num or 0
			})
		else
			local var_7_9
			local var_7_10 = var_7_7.item == "mana" and "images/icon/eco/jinbi.png" or var_7_7.item == "crystal" and "images/icon/eco/yuanbao.png" or var_7_7.item == "arena_coin" and "images/icon/eco/shell.png" or var_7_7.item == "top_coin" and "images/icon/eco/top_coin.png" or var_7_7.item == "guild_coin" and "images/icon/eco/guild_coin.png" or var_7_7.item == "region_coin" and "images/icon/eco/region_coin.png" or var_7_7.item == "honor_coin" and "images/icon/eco/war_coin.png" or var_7_7.item == "paradise_coin" and "images/icon/eco/illusion_coin.png" or var_7_7.item == "god_war_coin" and "images/icon/eco/academy_coin.png" or var_7_7.item == "spirit_stone" and "images/icon/eco/spirit_stone.png" or var_7_7.item == "magic_liquid" and "images/icon/eco/magic_liquid.png" or var_7_7.item == "magic_dust" and "images/icon/eco/magic_dust.png" or var_7_7.item == "magic_energy" and "images/icon/eco/magic_energy.png" or var_7_7.item == "friend_medal" and "images/icon/eco/gay_coin.png" or var_7_7.item == "team_dungeon_coin" and "images/icon/eco/team_dungeon_coin.png" or var_7_7.item == "summon_coin" and "images/icon/eco/summon_coin.png" or "images/icon/eco/jinbi.png"

			table.insert(var_7_4, {
				icon = var_7_10,
				num = var_7_7.num or 0
			})
		end
	end

	local var_7_11 = 15
	local var_7_12 = 22
	local var_7_13 = 80
	local var_7_14 = 1

	for iter_7_1 = 1, math.ceil(#var_7_5 / 4) do
		local var_7_15 = 4

		if iter_7_1 == 1 and #var_7_5 % 4 ~= 0 then
			var_7_15 = #var_7_5 % 4
		end

		local var_7_16 = var_7_14 + var_7_15 - 1
		local var_7_17 = 0

		for iter_7_2 = var_7_16, var_7_14, -1 do
			local var_7_18 = var_7_5[iter_7_2]
			local var_7_19 = cc.Node:create()

			var_7_19:setContentSize(var_7_13, var_7_13)
			xyd.setItemBorder(var_7_19, var_7_18.item, nil, nil, tonumber(var_7_18.num))
			var_7_19:addTo(var_7_1)
			var_7_19:setPosition(var_7_17 + var_0_4, var_7_11)

			var_7_17 = var_7_17 + var_7_13 + 5
		end

		var_7_11 = var_7_11 + var_7_13 + 5
		var_7_14 = var_7_16 + 1
	end

	local var_7_20 = 36

	for iter_7_3 = 1, #var_7_4 do
		local var_7_21 = var_7_4[iter_7_3]
		local var_7_22 = var_7_21.icon
		local var_7_23 = xyd.AssetLoader:get():loadSprite(var_7_22)

		var_7_1:addChild(var_7_23)
		var_7_23:setPosition(var_0_4, var_7_11)

		local var_7_24 = var_7_23:getContentSize()

		var_7_23:setScale(var_7_20 / var_7_24.width, var_7_20 / var_7_24.height)
		var_7_23:setAnchorPoint(0, 0)

		local var_7_25 = {
			text = "x" .. var_7_21.num,
			size = var_7_12,
			color = cc.c3b(176, 64, 43),
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			dimensions = cc.size(360, 0),
			x = var_0_4 + var_7_20 + 5,
			y = var_7_11
		}
		local var_7_26 = xyd.AssetLoader.get():loadLabel(var_7_25)

		var_7_26:addTo(var_7_1)
		var_7_26:setAnchorPoint(0, 0)

		var_7_11 = var_7_11 + var_7_20 + 5
	end

	local var_7_27 = {
		size = 24,
		color = cc.c3b(176, 64, 43)
	}
	local var_7_28 = xyd.AssetLoader.get():loadLabel(var_7_27)

	var_7_28:setString(var_0_6:translation("ENCLOSURE"))
	var_7_28:addTo(var_7_1)
	var_7_28:setAnchorPoint(cc.p(0, 0))

	local var_7_29 = var_7_11 + 5

	var_7_28:setPosition(var_0_5, var_7_29)

	local var_7_30 = var_7_29 + var_7_12 + 15

	var_7_1:height(var_7_30)
	var_7_2:setContentSize(var_7_1:getContentSize().width, var_7_30)

	local var_7_31 = arg_7_0.contentList:newItem()

	var_7_31:addContent(var_7_2)
	var_7_31:setItemSize(var_7_1:getContentSize().width, var_7_30)
	arg_7_0.contentList:addItem(var_7_31)
end

function var_0_0.awardBtnHandle(arg_8_0, arg_8_1)
	local var_8_0 = {}
	local var_8_1 = {}
	local var_8_2 = arg_8_0.idx
	local var_8_3 = arg_8_0.mail
	local var_8_4 = {
		idx = var_8_2,
		attach = var_8_3.attach,
		mail = var_8_3
	}
	local var_8_5

	if arg_8_0.idx ~= nil and arg_8_0.mail ~= nil and arg_8_0.mail.attach ~= nil then
		for iter_8_0 = 1, #var_8_3.attach do
			if var_8_3.attach[iter_8_0].item == "mana" or var_8_3.attach[iter_8_0].item == "crystal" or var_8_3.attach[iter_8_0].item == "arena_coin" or var_8_3.attach[iter_8_0].item == "top_coin" or var_8_3.attach[iter_8_0].item == "guild_coin" or var_8_3.attach[iter_8_0].item == nil or var_8_3.attach[iter_8_0].item == "region_coin" or var_8_3.attach[iter_8_0].item == "honor_coin" or var_8_3.attach[iter_8_0].item == "paradise_coin" or var_8_3.attach[iter_8_0].item == "magic_liquid" or var_8_3.attach[iter_8_0].item == "magic_dust" or var_8_3.attach[iter_8_0].item == "magic_energy" or var_8_3.attach[iter_8_0].item == "spirit_stone" then
				-- block empty
			else
				table.insert(var_8_0, {
					item = tonumber(arg_8_0.mail.attach[iter_8_0].item),
					num = arg_8_0.mail.attach[iter_8_0].num
				})
			end
		end

		for iter_8_1 = 1, #var_8_0 do
			local var_8_6 = arg_8_0.backpack_:getItemNumByID(tonumber(var_8_0[iter_8_1].item))

			if var_8_0[iter_8_1].num + var_8_6 > var_0_7:stack(var_8_0[iter_8_1].item) then
				table.insert(var_8_1, {
					var_8_0[iter_8_1].item,
					var_8_6 + tonumber(var_8_0[iter_8_1].num) - var_0_7:stack(var_8_0[iter_8_1].item)
				})
			end
		end
	end

	arg_8_1:addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended and not arg_8_0.scrollViewMoved_ then
			xyd.playButtonSound()

			if #var_8_1 ~= 0 then
				xyd.WindowManager.get():openWindow("excessnotice", var_8_4)
				xyd.WindowManager.get():closeWindow(arg_8_0.name)
			elseif arg_9_1 == ccui.TouchEventType.ended then
				arg_8_0.mailbox_:readMail(arg_8_0.mail)
				xyd.WindowManager.get():closeWindow(arg_8_0.name)
			end
		end
	end)
end

function var_0_0.didOpen(arg_10_0)
	arg_10_0:addBlockLayer()
end

return var_0_0
