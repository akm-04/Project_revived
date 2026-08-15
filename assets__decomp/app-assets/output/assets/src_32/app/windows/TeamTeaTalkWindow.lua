local var_0_0 = class("TeamTeaTalkWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.hero
local var_0_4 = 235
local var_0_5 = 550

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.updateListView(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0
	local var_2_1 = arg_2_0.listView_:dequeueItem()

	if not var_2_1 then
		var_2_1 = arg_2_0.listView_:newItem()
	else
		var_2_1:removeAllChildren(true)
	end

	local var_2_2 = arg_2_0:nodeByName("list_container"):getWidth()
	local var_2_3 = var_0_4

	var_2_1:setItemSize(var_2_2, var_2_3)

	local var_2_4 = display.newNode()

	var_2_4:setContentSize(var_2_2, var_2_3)

	local var_2_5 = arg_2_0.guild.teaTalkWishList
	local var_2_6 = arg_2_2
	local var_2_7 = 0

	for iter_2_0 = 1, 0, -1 do
		local var_2_8 = var_2_6 * 2 - iter_2_0

		if var_2_8 <= #var_2_5 and var_2_8 > 0 then
			local var_2_9 = display.newNode()

			arg_2_0:initCell(var_2_9, var_2_8)
			var_2_4:addChild(var_2_9)
			var_2_9:setPosition(var_2_7 * var_0_5, 0)

			var_2_7 = var_2_7 + 1
		end
	end

	var_2_1:addContent(var_2_4)

	return var_2_1
end

function var_0_0.initCell(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_0.guild.teaTalkWishList[arg_3_2]
	local var_3_1 = var_3_0.wish_info
	local var_3_2 = var_3_0.player_info

	if var_3_1.item_id == 0 then
		return
	end

	local var_3_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/team_tea_talk/tea_talk_item.csb")
	local var_3_4 = var_3_3:getChildByName("container")
	local var_3_5 = var_3_4:getChildByName("shadow")
	local var_3_6 = var_3_4:getContentSize()
	local var_3_7 = var_3_4:getChildByName("avatar_container")
	local var_3_8 = var_3_4:getChildByName("over_words")
	local var_3_9 = var_3_4:getChildByName("give_btn")

	var_3_9:getChildByName("give_words"):setString(var_0_2:translation("SHE_TUAN_TEXT_31"))
	var_3_4:getChildByName("own_words"):setString(var_0_2:translation("OWN"))
	var_3_4:getChildByName("bar_text"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
	var_3_5:setVisible(false)

	local var_3_10 = ""

	if var_3_2.guild_job == xyd.GuildJobType.MEMBER then
		var_3_10 = var_0_2:translation("TEAM_MEMBER")
	elseif var_3_2.guild_job == xyd.GuildJobType.LEADER then
		var_3_10 = var_0_2:translation("TEAM_PRESIDENT")
	else
		var_3_10 = var_0_2:translation("TEAM_VICE_PRESIDENT")
	end

	var_3_4:getChildByName("job_text"):setString(var_3_10)
	var_3_4:getChildByName("name_text"):setString(var_3_2.player_name)

	if var_3_2.conquer_lev and var_3_2.conquer_lev > 0 then
		xyd.setConquerLev(var_3_2.conquer_lev, var_3_4:getChildByName("level_text"), var_3_4:getChildByName("level_bg"), nil, nil, nil, nil, var_3_2.conquer_loop_id)
	else
		var_3_4:getChildByName("level_text"):setString(var_3_2.lev)
	end

	var_3_4:getChildByName("own_text"):setString(arg_3_0.selfPlayer:getBackpack():getItemNumByID(var_3_1.item_id))
	var_3_4:getChildByName("region"):setString("S" .. xyd.getPlayerRegion(var_3_2.player_id))
	var_3_4:getChildByName("bar_text"):setString(var_3_1.current_num .. " / " .. var_3_1.need_num)

	if var_3_1.need_num ~= 0 then
		var_3_4:getChildByName("bar"):setPercent(100 * var_3_1.current_num / var_3_1.need_num)
	end

	xyd.setPlayerAvatar(var_3_7, {
		showLevel = false,
		avatar_id = var_3_2.avatar_id,
		avatar_frame_id = var_3_2.avatar_frame_id
	})
	xyd.setItemAndAddTips(var_3_4:getChildByName("icon_container"), var_3_1.item_id, 1)

	if arg_3_0.selfPlayer.playerID == var_3_2.player_id then
		var_3_8:setVisible(false)
		var_3_9:setVisible(false)
	elseif var_3_1.current_num == var_3_1.need_num then
		var_3_9:setVisible(false)
		var_3_5:setVisible(true)
		var_3_8:setString(var_0_2:translation("ALREADY_DONE"))
	elseif var_3_0.can_present_gift then
		if arg_3_0.selfPlayer:getBackpack():getItemNumByID(var_3_1.item_id) == 0 then
			var_3_9:setVisible(false)
			var_3_8:setString(var_0_2:translation("STONE_NOT_ENOUGH"))
		else
			var_3_8:setVisible(false)
		end
	elseif arg_3_0.selfPlayer:getBackpack():getItemNumByID(var_3_1.item_id) == 0 then
		var_3_9:setVisible(false)
		var_3_8:setString(var_0_2:translation("STONE_NOT_ENOUGH"))
	else
		var_3_9:setVisible(false)
		var_3_8:setString(var_0_2:translation("ALREADY_SEND"))
	end

	var_3_9:addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(var_3_9, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.tables.item:name(var_3_1.item_id)
			local var_4_1 = string.format(var_0_2:translation("TEAM_TALK_HELP"), var_4_0)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_4_1, function()
				local var_5_0 = xyd.tables.item:heroID(var_3_1.item_id)

				if not arg_3_0.selfPlayer:getHeroByTableID(var_5_0) and not arg_3_0.selfPlayer:getHeroByTableID(xyd.tables.hero:afterAwaken(var_5_0)) then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("TEA_TALK_NO_HERO")
					})

					return
				end

				if var_0_3:guildRequestCrossService(var_5_0) == 0 and math.floor(arg_3_0.selfPlayer.playerID / 100000) ~= math.floor(var_3_2.player_id / 100000) then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("TEA_TALK_REGION_TIP")
					})

					return
				end

				xyd.playButtonSound()

				local var_5_1 = {
					player_id = var_3_2.player_id
				}

				arg_3_0.guild:teaTalkPresent(var_5_1, function(arg_6_0)
					if arg_6_0 == xyd.error.OK then
						arg_3_0.selfPlayer:getBackpack():removeItem({
							itemNum = 1,
							itemID = var_3_1.item_id
						})
						arg_3_0:freshList()
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation("TEA_TALK_SEND_OK")
						})

						return true
					end
				end)
			end, nil, nil, arg_3_0.colorMode)
		end
	end)
	var_3_4:getChildByName("shadow"):setLocalZOrder(100)
	var_3_3:setContentSize(var_3_6)
	arg_3_1:setContentSize(var_3_6)
	arg_3_1:addChild(var_3_3)
end

function var_0_0.delegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	data = arg_7_0.guild.teaTalkWishList

	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return math.ceil(#data / 2) or 0
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		return arg_7_0:updateListView(arg_7_2, arg_7_3)
	end
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" and 10 <= math.abs(arg_8_1.y - arg_8_0.prevY_) then
		arg_8_0.scrollViewMoved_ = true
	end

	arg_8_0.originY = arg_8_0.listView_.scrollNode:getPositionY()
end

function var_0_0.willOpen(arg_9_0, arg_9_1)
	var_0_0.super:willOpen(arg_9_1)

	arg_9_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_9_0:nodeByName("list_container"):getWidth(), arg_9_0:nodeByName("list_container"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_9_0:nodeByName("list_container")):onScroll(handler(arg_9_0, arg_9_0.scrollListener))

	arg_9_0.listView_:setBounceable(true)
	arg_9_0.listView_:setDelegate(handler(arg_9_0, arg_9_0.delegate))
	arg_9_0.listView_:reload()
	arg_9_0:layout()
end

function var_0_0.layout(arg_10_0)
	if #arg_10_0.guild.teaTalkWishList > 0 then
		arg_10_0:nodeByName("bg_hero"):setVisible(false)
	else
		arg_10_0:nodeByName("bg_hero"):setVisible(true)
	end

	arg_10_0:nodeByName("hero_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_48"))
	arg_10_0:nodeByName("change_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("change_btn"), arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_10_0.guild.teaTalkOnceFlay ~= 1 then
				arg_10_0.guild:getTeaTalkInfo(function(arg_12_0, arg_12_1)
					if arg_12_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("tea_talk_quest")

						if #arg_10_0.guild.teaTalkGiftList ~= 0 and arg_10_0.guild.teaTalkSelfWishInfo.current_num > 0 then
							xyd.WindowManager.get():openWindow("tea_talk_receive")
						end
					end
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("EVERYDAY_QUEST_LIMIT")
				})
			end
		end
	end)
	arg_10_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("rule_btn"), arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_13_0 = {
				title_name = "GUILD_REQUEST_RULE_TITLE",
				rule = "GUILD_REQUEST_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_13_0)
		end
	end)
	arg_10_0:nodeByName("exchange_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("exchange_btn"), arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				arg_10_0:showTop(false)
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = xyd.ShopType.TEATALK,
					top_status = xyd.MainSceneTop.CLOSE
				})
			end)
		end
	end)
	arg_10_0:nodeByName("bar_text"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
	arg_10_0:nodeByName("coin_text"):enableShadow(cc.c4b(1, 1, 1, 200), cc.size(1, -1), 1)

	if #arg_10_0.guild.teaTalkGiftList ~= 0 and arg_10_0.guild.teaTalkSelfWishInfo.current_num == arg_10_0.guild.teaTalkSelfWishInfo.need_num then
		xyd.WindowManager.get():openWindow("tea_talk_receive")
	end

	arg_10_0:updateMyQuest()
	arg_10_0:updateCoin()
	arg_10_0:nodeByName("title"):setString(var_0_2:translation("SHE_TUAN_TEXT_27"))
	arg_10_0:nodeByName("exchange_words"):setString(var_0_2:translation("SHE_TUAN_TEXT_28"))
	arg_10_0:nodeByName("change_words"):setString(var_0_2:translation("SHE_TUAN_TEXT_29"))
	arg_10_0:nodeByName("send_words"):setString(var_0_2:translation("SHE_TUAN_TEXT_30"))
end

function var_0_0.updateCoin(arg_16_0)
	arg_16_0:nodeByName("coin_text"):setString(arg_16_0.selfPlayer.friendMedal)
end

function var_0_0.showTop(arg_17_0, arg_17_1)
	arg_17_0:nodeByName("panel_coin"):setVisible(arg_17_1)
end

function var_0_0.updateMyQuest(arg_18_0)
	local var_18_0 = arg_18_0.guild.teaTalkSelfWishInfo or {}

	if not var_18_0.item_id or var_18_0.item_id == 0 then
		arg_18_0:nodeByName("my_quest_text"):setString(var_0_2:translation("MY_QUEST") .. var_0_2:translation("DONT_HAVE_NOW"))
		arg_18_0:nodeByName("bar_bg"):setVisible(false)
		arg_18_0:nodeByName("bar"):setVisible(false)
		arg_18_0:nodeByName("bar_text"):setVisible(false)
		arg_18_0:nodeByName("change_words"):setVisible(false)
		arg_18_0:nodeByName("send_words"):setVisible(true)
	else
		arg_18_0:nodeByName("my_quest_text"):setString(var_0_2:translation("MY_QUEST") .. xyd.tables.item:name(var_18_0.item_id))
		arg_18_0:nodeByName("bar_bg"):setVisible(true)
		arg_18_0:nodeByName("bar"):setVisible(true)
		arg_18_0:nodeByName("bar_text"):setVisible(true)
		arg_18_0:nodeByName("send_words"):setVisible(false)
		arg_18_0:nodeByName("change_words"):setVisible(true)

		if var_18_0.need_num ~= 0 then
			arg_18_0:nodeByName("bar"):setPercent(100 * var_18_0.current_num / var_18_0.need_num)
		end

		arg_18_0:nodeByName("bar_text"):setString(var_18_0.current_num .. " / " .. var_18_0.need_num)
	end

	arg_18_0:updateCoin()
end

function var_0_0.freshList(arg_19_0)
	arg_19_0:updateMyQuest()
	arg_19_0.listView_:reload()

	if #arg_19_0.guild.teaTalkWishList > 0 then
		arg_19_0:nodeByName("bg_hero"):setVisible(false)
	else
		arg_19_0:nodeByName("bg_hero"):setVisible(true)
	end

	if arg_19_0.originY then
		arg_19_0.listView_:scrollTo(0, arg_19_0.originY)
	end
end

function var_0_0.didOpen(arg_20_0, arg_20_1)
	var_0_0.super:didOpen(arg_20_1)

	local var_20_0 = xyd.WindowManager.get():getWindow("team")

	if var_20_0 then
		var_20_0:showTop(false)
	end

	arg_20_0.dispatcher = xyd.EventDispatcher.get():addEventListener(xyd.event.FRESH_STONE_QUEST, function(arg_21_0)
		arg_20_0:freshList()
	end)

	arg_20_0:addBlockLayer()
end

function var_0_0.didClose(arg_22_0, arg_22_1)
	var_0_0.super:didClose(arg_22_1)

	local var_22_0 = xyd.WindowManager.get():getWindow("team")

	if var_22_0 then
		var_22_0:showTop(true)
	end

	if arg_22_0.dispatcher then
		xyd.EventDispatcher.get():removeEventListener(arg_22_0.dispatcher)
	end
end

return var_0_0
