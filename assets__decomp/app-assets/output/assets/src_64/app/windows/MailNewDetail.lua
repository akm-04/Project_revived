local var_0_0 = class("MailNewDetail", import("app.common.ui.BaseWindow"))
local var_0_1 = 650
local var_0_2 = 40
local var_0_3 = 16
local var_0_4 = 16
local var_0_5 = 65
local var_0_6 = 20
local var_0_7 = 140
local var_0_8 = xyd.tables.translation
local var_0_9 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.mail = arg_1_2.mail
	arg_1_0.idx = arg_1_2.idx
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.container = arg_2_0:nodeByName("container")
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
	arg_3_0:nodeByName("title"):setString(arg_3_0.mail.title)
	arg_3_0:nodeByName("attach_txt"):setString(var_0_8:translation("ENCLOSURE"))
	arg_3_0:nodeByName("txt_get"):setString(var_0_8:translation("MAILBOX_GET"))
	arg_3_0:showMailContent()
end

function var_0_0.showMailContent(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("word_scroll"):getContentSize()

	if not arg_4_0.mail.attach or not next(arg_4_0.mail.attach) then
		arg_4_0:nodeByName("word_scroll"):setContentSize(var_4_0.width, var_4_0.height + var_0_7)
		arg_4_0:nodeByName("dotted_line"):setVisible(false)
		arg_4_0:nodeByName("attach_scroll"):setVisible(false)
		arg_4_0:nodeByName("attach_txt"):setVisible(false)

		var_4_0 = arg_4_0:nodeByName("word_scroll"):getContentSize()

		arg_4_0:nodeByName("txt_get"):setString(var_0_8:translation("OK"))
	end

	if not arg_4_0.contentList then
		arg_4_0.contentList = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_4_0:nodeByName("word_scroll")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))
	else
		arg_4_0.contentList:removeAllItems()
	end

	if arg_4_0.contentStrs and next(arg_4_0.contentStrs) then
		local var_4_1
		local var_4_2
		local var_4_3
		local var_4_4 = 0

		while next(arg_4_0.contentStrs) or var_4_1 do
			if var_4_4 == 0 then
				var_4_3 = display.newNode()

				var_4_3:setContentSize(var_0_1 + var_0_3 + var_0_4, var_0_2)
			end

			if var_4_1 and var_4_1.str ~= "" then
				local var_4_5 = var_0_1 - var_4_4

				if var_4_1.type == xyd.ParseStrType.MARK then
					arg_4_0.str = var_4_1.str

					local var_4_6 = xyd.createLinkLabel(var_4_1.str, 26, cc.c3b(0, 73, 255), cc.c4f(0, 0.28627450980392155, 1, 1), 3, function(arg_5_0)
						cc.Application:getInstance():openURL(arg_5_0)
					end)

					var_4_6:addTo(var_4_3)
					var_4_6:setAnchorPoint(cc.p(0, 0))
					var_4_6:setPosition(var_0_3 + var_4_4, 3)

					var_4_4 = var_4_4 + var_4_6:getContentSize().width
					var_4_1 = nil
				else
					local var_4_7 = {
						size = 26,
						color = cc.c3b(99, 104, 116)
					}
					local var_4_8 = xyd.AssetLoader.get():loadLabel(var_4_7)

					var_4_8:setString(var_4_1.str)

					if var_4_5 < var_4_8:getContentSize().width then
						local var_4_9 = var_4_1.str
						local var_4_10 = ""
						local var_4_11 = string.len(var_4_1.str)

						for iter_4_0 = 1, math.huge, 3 do
							local var_4_12, var_4_13 = xyd.getSplitUtf8Str(var_4_1.str, 1, iter_4_0)
							local var_4_14 = xyd.AssetLoader.get():loadLabel(var_4_7)

							var_4_14:setString(var_4_12)

							if var_4_5 < var_4_14:getContentSize().width then
								var_4_8:setString(var_4_9)
								var_4_8:setAnchorPoint(cc.p(0, 0))
								var_4_8:addTo(var_4_3)
								var_4_8:setPosition(var_0_3 + var_4_4, 3)

								var_4_1.str = var_4_10
								var_4_4 = var_0_1

								break
							end

							var_4_9 = var_4_12
							var_4_10 = var_4_13
						end
					else
						var_4_8:setAnchorPoint(cc.p(0, 0))
						var_4_8:addTo(var_4_3)
						var_4_8:setPosition(var_0_3 + var_4_4, 3)

						var_4_4 = var_4_8:getContentSize().width + var_4_4
						var_4_1 = nil

						if arg_4_0.contentStrs[1] and arg_4_0.contentStrs[1].type == xyd.ParseStrType.TEXT then
							var_4_4 = var_0_1
						end
					end
				end
			else
				var_4_1 = arg_4_0.contentStrs[1]

				table.remove(arg_4_0.contentStrs, 1)
			end

			if var_4_4 == var_0_1 or not var_4_1 and not next(arg_4_0.contentStrs) then
				local var_4_15 = arg_4_0.contentList:newItem()

				var_4_15:addContent(var_4_3)
				var_4_15:setItemSize(var_4_3:getContentSize().width, var_4_3:getContentSize().height)
				arg_4_0.contentList:addItem(var_4_15)

				var_4_4 = 0
			end
		end
	end

	local var_4_16 = display.newNode()

	var_4_16:setContentSize(var_0_1 + var_0_3 + var_0_4, var_0_2)

	local var_4_17 = {
		size = 26,
		color = cc.c3b(99, 104, 116)
	}
	local var_4_18 = xyd.AssetLoader.get():loadLabel(var_4_17)

	var_4_18:setString(arg_4_0.mail.from)
	var_4_18:setAnchorPoint(cc.p(0, 0))

	local var_4_19 = var_4_18:getContentSize().width

	var_4_18:setPosition(var_4_16:getContentSize().width - var_0_4 - var_4_19, 3)
	var_4_18:addTo(var_4_16)

	local var_4_20 = arg_4_0.contentList:newItem()

	var_4_20:addContent(var_4_16)
	var_4_20:setItemSize(var_4_16:getContentSize().width, var_4_16:getContentSize().height)
	arg_4_0.contentList:addItem(var_4_20)
	arg_4_0.contentList:reload()
	arg_4_0:addMailAttachement()
	arg_4_0:awardBtnHandle(arg_4_0:nodeByName("btn_get"))
	collectgarbage("collect")
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayer()
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 10 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.scrollViewMoved_ = true
	end
end

function var_0_0.addMailAttachement(arg_8_0)
	if not arg_8_0.mail.attach or not next(arg_8_0.mail.attach) then
		return
	end

	local var_8_0 = arg_8_0:nodeByName("attach_scroll"):getContentSize()

	arg_8_0.attachList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_8_0.width, var_8_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_8_0:nodeByName("attach_scroll")):onScroll(handler(arg_8_0, arg_8_0.scrollListener))

	local var_8_1 = #arg_8_0.mail.attach
	local var_8_2 = {}
	local var_8_3 = {}

	for iter_8_0 = 1, var_8_1 do
		local var_8_4 = var_8_1 - iter_8_0 + 1
		local var_8_5 = arg_8_0.mail.attach[var_8_4]
		local var_8_6 = tonumber(var_8_5.item) or 0

		if var_8_6 > 0 then
			table.insert(var_8_3, {
				item = var_8_6,
				num = var_8_5.num or 0
			})
		else
			local var_8_7
			local var_8_8 = var_8_5.item == "mana" and "images/icon/eco/jinbi.png" or var_8_5.item == "crystal" and "images/icon/eco/yuanbao.png" or var_8_5.item == "arena_coin" and "images/icon/eco/shell.png" or var_8_5.item == "top_coin" and "images/icon/eco/top_coin.png" or var_8_5.item == "guild_coin" and "images/icon/eco/guild_coin.png" or var_8_5.item == "region_coin" and "images/icon/eco/region_coin.png" or var_8_5.item == "honor_coin" and "images/icon/eco/war_coin.png" or var_8_5.item == "paradise_coin" and "images/icon/eco/illusion_coin.png" or var_8_5.item == "god_war_coin" and "images/icon/eco/academy_coin.png" or var_8_5.item == "spirit_stone" and "images/icon/eco/spirit_stone.png" or var_8_5.item == "magic_liquid" and "images/icon/eco/magic_liquid.png" or var_8_5.item == "magic_dust" and "images/icon/eco/magic_dust.png" or var_8_5.item == "magic_energy" and "images/icon/eco/magic_energy.png" or var_8_5.item == "friend_medal" and "images/icon/eco/gay_coin.png" or var_8_5.item == "team_dungeon_coin" and "images/icon/eco/team_dungeon_coin.png" or "images/icon/eco/jinbi.png"

			table.insert(var_8_2, {
				icon = var_8_8,
				num = var_8_5.num or 0
			})
		end
	end

	for iter_8_1 = 1, math.ceil(#var_8_2 / 2) do
		local var_8_9 = arg_8_0.attachList:newItem()
		local var_8_10 = xyd.AssetLoader.get():loadNodeFromJson("windows/mailbox/mail_attach_item1.csb")
		local var_8_11 = var_8_10:getChildByName("container")
		local var_8_12 = display.newNode()

		for iter_8_2 = 1, 2 do
			local var_8_13 = iter_8_1 * 2 + iter_8_2 - 2

			if var_8_13 > #var_8_2 then
				var_8_11:getChildByName("num" .. iter_8_2):setVisible(false)
				var_8_11:getChildByName("item" .. iter_8_2):setVisible(false)
			else
				local var_8_14 = var_8_2[var_8_13].icon
				local var_8_15 = var_8_2[var_8_13].num
				local var_8_16 = xyd.AssetLoader:get():loadSprite(var_8_14)

				var_8_16:setAnchorPoint(0, 0)
				var_8_16:setPosition(0, 0)
				var_8_16:addTo(var_8_11:getChildByName("item" .. iter_8_2))

				local var_8_17 = var_8_16:getContentSize()
				local var_8_18 = var_8_11:getChildByName("item" .. iter_8_2):getContentSize()

				var_8_16:setScale(var_8_18.width / var_8_17.width, var_8_18.height / var_8_17.height)
				var_8_11:getChildByName("num" .. iter_8_2):setString("X " .. var_8_15)
			end
		end

		local var_8_19 = var_8_11:getContentSize()

		var_8_10:setAnchorPoint(0, 0)
		var_8_10:setPosition(0, 0)
		var_8_10:addTo(var_8_12)
		var_8_12:setContentSize(var_8_19.width, var_8_19.height)
		var_8_9:addContent(var_8_12)
		var_8_9:setItemSize(var_8_19.width, var_8_19.height)
		arg_8_0.attachList:addItem(var_8_9)
	end

	for iter_8_3 = 1, math.ceil(#var_8_3 / 6) do
		local var_8_20 = arg_8_0.attachList:newItem()
		local var_8_21 = display.newNode()
		local var_8_22 = xyd.AssetLoader.get():loadNodeFromJson("windows/mailbox/mail_attach_item2.csb")
		local var_8_23 = var_8_22:getChildByName("container")

		for iter_8_4 = 1, 6 do
			local var_8_24 = iter_8_3 * 6 + iter_8_4 - 6

			if var_8_24 > #var_8_3 then
				break
			end

			xyd.setItemAndAddTips(var_8_23:getChildByName("item" .. iter_8_4), var_8_3[var_8_24].item, var_8_3[var_8_24].num)
		end

		local var_8_25 = var_8_23:getContentSize()

		var_8_22:setAnchorPoint(0, 0)
		var_8_22:setPosition(0, 0)
		var_8_22:addTo(var_8_21)
		var_8_21:setContentSize(var_8_25.width, var_8_25.height)
		var_8_20:addContent(var_8_21)
		var_8_20:setItemSize(var_8_25.width, var_8_25.height)
		arg_8_0.attachList:addItem(var_8_20)
	end

	arg_8_0.attachList:reload()
end

function var_0_0.awardBtnHandle(arg_9_0, arg_9_1)
	local var_9_0 = {}
	local var_9_1 = {}
	local var_9_2 = arg_9_0.idx
	local var_9_3 = arg_9_0.mail
	local var_9_4 = {
		idx = var_9_2,
		attach = var_9_3.attach,
		mail = var_9_3
	}
	local var_9_5

	if arg_9_0.idx ~= nil and arg_9_0.mail ~= nil and arg_9_0.mail.attach ~= nil then
		for iter_9_0 = 1, #var_9_3.attach do
			if var_9_3.attach[iter_9_0].item == "mana" or var_9_3.attach[iter_9_0].item == "crystal" or var_9_3.attach[iter_9_0].item == "god_war_coin" or var_9_3.attach[iter_9_0].item == "arena_coin" or var_9_3.attach[iter_9_0].item == "top_coin" or var_9_3.attach[iter_9_0].item == "guild_coin" or var_9_3.attach[iter_9_0].item == nil or var_9_3.attach[iter_9_0].item == "region_coin" or var_9_3.attach[iter_9_0].item == "honor_coin" or var_9_3.attach[iter_9_0].item == "paradise_coin" or var_9_3.attach[iter_9_0].item == "magic_liquid" or var_9_3.attach[iter_9_0].item == "magic_dust" or var_9_3.attach[iter_9_0].item == "magic_energy" or var_9_3.attach[iter_9_0].item == "spirit_stone" or var_9_3.attach[iter_9_0].item == "team_dungeon_coin" then
				-- block empty
			else
				table.insert(var_9_0, {
					item = tonumber(arg_9_0.mail.attach[iter_9_0].item),
					num = arg_9_0.mail.attach[iter_9_0].num
				})
			end
		end

		for iter_9_1 = 1, #var_9_0 do
			local var_9_6 = arg_9_0.backpack_:getItemNumByID(tonumber(var_9_0[iter_9_1].item))

			if var_9_0[iter_9_1].num + var_9_6 > var_0_9:stack(var_9_0[iter_9_1].item) then
				table.insert(var_9_1, {
					var_9_0[iter_9_1].item,
					var_9_6 + tonumber(var_9_0[iter_9_1].num) - var_0_9:stack(var_9_0[iter_9_1].item)
				})
			end
		end
	end

	local var_9_7 = arg_9_0:canReadSpecialMail(var_9_3.category)

	xyd.addTouchEvent2(arg_9_1, function(arg_10_0)
		if arg_10_0.name == "began" then
			arg_9_1:setScale(0.9)

			return true
		elseif arg_10_0.name == "canceled" then
			arg_9_1:setScale(1)
		elseif arg_10_0.name == "ended" then
			arg_9_1:setScale(1)
			xyd.playButtonSound()

			if not var_9_7 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_8:translation("SPECIAL_MAIL_TIPS")
				})

				return
			end

			if #var_9_1 ~= 0 then
				xyd.WindowManager.get():openWindow("excessnotice", var_9_4)
			else
				arg_9_0.mailbox_:readMail(arg_9_0.mail, function(arg_11_0)
					if arg_11_0 == xyd.error.OK then
						xyd.WindowManager.get():closeWindow(arg_9_0.name)
					end
				end)
			end
		end
	end)
end

function var_0_0.canReadSpecialMail(arg_12_0, arg_12_1)
	local function var_12_0(arg_13_0, arg_13_1)
		if arg_13_0.main ~= arg_13_1.main then
			return arg_13_0.main - arg_13_1.main
		elseif arg_13_0.mid ~= arg_13_1.mid then
			return arg_13_0.mid - arg_13_1.mid
		else
			return arg_13_0.sub - arg_13_1.sub
		end
	end

	local function var_12_1(arg_14_0)
		local var_14_0, var_14_1, var_14_2 = arg_14_0:match("(%d+)%.(%d+)%.(%d+)")
		local var_14_3 = {
			main = tonumber(var_14_0 or 0),
			mid = tonumber(var_14_1 or 0),
			sub = tonumber(var_14_2 or 0)
		}

		setmetatable(var_14_3, {
			__tostring = function()
				return arg_14_0
			end
		})

		return var_14_3
	end

	local var_12_2 = var_12_1(xyd.getVersionName() or "")

	if arg_12_1 == xyd.specialMail.updateOffset then
		if device.platform == "android" then
			if var_12_0(var_12_2, var_12_1("1.579.0")) >= 0 then
				return true
			else
				return false
			end
		elseif device.platform == "ios" then
			if var_12_0(var_12_2, var_12_1("1.578.0")) >= 0 then
				return true
			else
				return false
			end
		else
			return false
		end
	elseif arg_12_1 == xyd.specialMail.onlyAndroid and (device.platform ~= "android" or true) then
		-- block empty
	elseif arg_12_1 == xyd.specialMail.onlyIos and (device.platform ~= "ios" or true) then
		-- block empty
	else
		return true
	end
end

return var_0_0
