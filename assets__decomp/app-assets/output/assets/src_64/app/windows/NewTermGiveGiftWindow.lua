local var_0_0 = class("NewTermGiveGiftFriendItem", function()
	return cc.Node:create()
end)
local var_0_1 = false
local var_0_2 = xyd.tables.translation
local var_0_3 = 1000
local var_0_4 = 80
local var_0_5 = xyd.tables.hero
local var_0_6 = 1
local var_0_7 = 2
local var_0_8 = 3
local var_0_9 = 4
local var_0_10 = 1
local var_0_11 = 2

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/new_term/friend_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
		arg_3_0:setContentSize(arg_3_0.contentView_:getContentSize().width, arg_3_0.contentView_:getContentSize().height)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_2 == var_0_8 then
		arg_4_0.contentView_:nodeByName("region"):setVisible(false)
	else
		arg_4_0.contentView_:nodeByName("region"):setVisible(true)
		arg_4_0.contentView_:nodeByName("region"):setString(string.format(var_0_2:translation("LIANYI_TEXT7"), xyd.getPlayerRegion(arg_4_1.player_id)))
	end

	arg_4_0.contentView_:nodeByName("player_avatar"):setContentSize(var_0_4, var_0_4)
	arg_4_0.contentView_:nodeByName("player_avatar"):setAnchorPoint(0.5, 0.5)
	xyd.setPlayerAvatar(arg_4_0.contentView_:nodeByName("player_avatar"), arg_4_1)

	if arg_4_1.conquer_lev and arg_4_1.conquer_lev ~= 0 then
		xyd.setConquerLev(arg_4_1.conquer_lev, arg_4_0.contentView_:nodeByName("lev"), arg_4_0.contentView_:nodeByName("level_bg"), nil, nil, 0.68, nil, arg_4_1.conquer_loop_id)
	else
		arg_4_0.contentView_:nodeByName("lev"):setString(arg_4_1.lev)
	end

	arg_4_0.contentView_:nodeByName("name"):setString(arg_4_1.name or arg_4_1.player_name)
	arg_4_0.contentView_:setTouchEnabled(true)
	arg_4_0.contentView_:setTouchSwallowEnabled(false)
	arg_4_0.contentView_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "ended" and not var_0_1 then
			xyd.WindowManager.get():openWindow("new_term_give_gift_alert", arg_4_1)
		end

		return true
	end)
end

local var_0_12 = class("NewTermGiveGiftWindow", import("app.common.ui.BaseWindow"))
local var_0_13 = import("app.common.ui.SpineEffect")
local var_0_14 = xyd.tables.translation
local var_0_15 = import("framework.scheduler")
local var_0_16 = xyd.AssetLoader.get()
local var_0_17 = import("app.model.Hero")
local var_0_18 = 3
local var_0_19 = 20

function var_0_12.ctor(arg_6_0, arg_6_1, arg_6_2)
	var_0_12.super.ctor(arg_6_0, arg_6_1, arg_6_2)

	arg_6_0.newTermModel = xyd.ModelManager.get():loadModel(xyd.ModelType.NEW_TERMS)
	arg_6_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_6_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_6_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_6_0.showMode = var_0_6
end

function var_0_12.willOpen(arg_7_0, arg_7_1)
	var_0_12.super.willOpen(arg_7_0, arg_7_1)
end

function var_0_12.didOpen(arg_8_0, arg_8_1)
	var_0_12.super.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
	arg_8_0:nodeByName("do_search_btn"):setVisible(false)
	arg_8_0:nodeByName("search_box"):setVisible(false)
	arg_8_0:nodeByName("search_txt"):setVisible(false)
	arg_8_0:layout()
end

function var_0_12.initPageButtons(arg_9_0)
	arg_9_0.pages = {
		arg_9_0:nodeByName("all_region_btn"),
		arg_9_0:nodeByName("friends_btn"),
		arg_9_0:nodeByName("guild_btn"),
		arg_9_0:nodeByName("search_btn")
	}

	for iter_9_0 = 1, var_0_9 do
		arg_9_0.pages[iter_9_0]:addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				arg_9_0.showMode = iter_9_0

				arg_9_0:showContainerByMode(iter_9_0)
			end
		end)
	end
end

function var_0_12.showContainerByMode(arg_11_0, arg_11_1)
	if arg_11_1 == var_0_6 then
		arg_11_0.newTermModel:getRecommendList({}, function(arg_12_0, arg_12_1)
			arg_11_0.showList = arg_12_1

			arg_11_0:updateList(arg_11_1, arg_12_1)
		end)
	elseif arg_11_1 == var_0_8 then
		arg_11_0.guild:loadTeam(function(arg_13_0, arg_13_1)
			if arg_13_0 == xyd.error.OK then
				local var_13_0 = arg_11_0.guild.members or {}

				for iter_13_0, iter_13_1 in ipairs(var_13_0) do
					if iter_13_1.player_id == arg_11_0.selfPlayer.playerID then
						table.remove(var_13_0, iter_13_0)

						break
					end
				end

				arg_11_0.showList = var_13_0

				arg_11_0:updateList(arg_11_1, arg_11_0.member_list)
			end
		end)
	elseif arg_11_1 == var_0_7 then
		arg_11_0.socialSystem:loadFriends({}, function(arg_14_0, arg_14_1)
			if arg_14_0 == xyd.error.OK then
				local var_14_0 = arg_11_0.socialSystem.friendlist

				arg_11_0.showList = var_14_0

				arg_11_0:updateList(arg_11_1, var_14_0)
			end
		end)
	else
		arg_11_0:initSearchPanel()
	end

	arg_11_0:updateButtonStatus()
end

function var_0_12.scrollListener(arg_15_0, arg_15_1)
	if arg_15_1.name == "began" then
		if arg_15_0.refreshTip and not tolua.isnull(arg_15_0.refreshTip) then
			arg_15_0.refreshTip:setVisible(false)

			arg_15_0.prepareToRefresh = false
		end

		arg_15_0.nodeY = arg_15_0.listView_:getScrollNode():getPositionY()
		var_0_1 = false
		arg_15_0.prevY_ = arg_15_1.y
	elseif arg_15_1.name == "moved" then
		if 10 <= math.abs(arg_15_1.y - arg_15_0.prevY_) then
			var_0_1 = true
		end

		if 0 - arg_15_0.listView_:getScrollNode():getPositionY() > -190 then
			if arg_15_0.refreshTip and not tolua.isnull(arg_15_0.refreshTip) and arg_15_0.showMode == var_0_6 then
				arg_15_0.refreshTip:setVisible(true)

				arg_15_0.prepareToRefresh = true
			end
		elseif arg_15_0.refreshTip and not tolua.isnull(arg_15_0.refreshTip) then
			arg_15_0.refreshTip:setVisible(false)
		end
	elseif arg_15_1.name == "ended" then
		if arg_15_0.refreshTip and not tolua.isnull(arg_15_0.refreshTip) then
			arg_15_0.refreshTip:setVisible(false)
		end
	elseif arg_15_1.name == "scrollEnd" then
		arg_15_0:refreshAllRegion()
	end
end

function var_0_12.refreshAllRegion(arg_16_0)
	if arg_16_0.prepareToRefresh then
		arg_16_0:showContainerByMode(arg_16_0.showMode)

		arg_16_0.prepareToRefresh = false
	end
end

function var_0_12.updateList(arg_17_0, arg_17_1, arg_17_2)
	arg_17_0.listView_:removeAllItems()
	arg_17_0:nodeByName("do_search_btn"):setVisible(false)
	arg_17_0:nodeByName("search_box"):setVisible(false)
	arg_17_0:nodeByName("search_txt"):setVisible(false)
	arg_17_0:nodeByName("friends_list"):setVisible(true)
	arg_17_0.listView_:setDelegate(handler(arg_17_0, arg_17_0.delegate))
	arg_17_0.listView_:reload()
end

function var_0_12.delegate(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	local var_18_0 = math.ceil(#arg_18_0.showList / var_0_18)

	if cc.ui.UIListView.COUNT_TAG == arg_18_2 then
		return var_18_0
	elseif cc.ui.UIListView.CELL_TAG == arg_18_2 then
		local var_18_1 = arg_18_1:dequeueItem()

		if not var_18_1 then
			var_18_1 = arg_18_1:newItem()
		else
			var_18_1:removeAllChildren()
		end

		local var_18_2 = display.newNode()

		var_18_2:setContentSize(820, 216)

		for iter_18_0 = 1, var_0_18 do
			local var_18_3 = (arg_18_3 - 1) * var_0_18 + iter_18_0

			if var_18_3 > #arg_18_0.showList then
				break
			end

			local var_18_4 = var_0_0.new()
			local var_18_5 = arg_18_0.showList[var_18_3]

			var_18_4:setParams(var_18_5, arg_18_0.showMode)
			var_18_4:addTo(var_18_2)
			var_18_4:setAnchorPoint(0, 0)
			var_18_4:setPosition(10 + 270 * (iter_18_0 - 1), 0)
		end

		var_18_1:addContent(var_18_2)
		var_18_1:setItemSize(820, 216)

		return var_18_1
	end
end

function var_0_12.initSearchPanel(arg_19_0)
	arg_19_0:nodeByName("do_search_btn"):setVisible(true)
	arg_19_0:nodeByName("search_box"):setVisible(true)
	arg_19_0:nodeByName("search_txt"):setVisible(true)
	arg_19_0:nodeByName("friends_list"):setVisible(false)
	arg_19_0:nodeByName("do_search_btn"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended then
			local var_20_0 = {}

			if arg_20_1 == ccui.TouchEventType.ended then
				local var_20_1 = {
					msg = arg_19_0.searchTxt or ""
				}

				if var_20_1.msg == "" then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_14:translation("INPUT_PLAYERID_OR_NAME")
					})

					return
				end

				arg_19_0.socialSystem:searchPlayer(var_20_1, function(arg_21_0, arg_21_1)
					if arg_21_0 == xyd.error.OK then
						if #arg_21_1 <= 0 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_14:translation("SEARCH_NONE_TEXT")
							})

							return
						end

						arg_19_0.showList = arg_21_1

						arg_19_0:updateList(var_0_9, arg_19_0.showList)
					end
				end)
			end
		end
	end)
	arg_19_0:initSearchBox()
end

function var_0_12.initSearchBox(arg_22_0)
	local var_22_0 = arg_22_0:nodeByName("search_container")
	local var_22_1 = "windows/login/transparent.png"

	arg_22_0:nodeByName("search_txt"):setString(var_0_14:translation("LIANYI_TEXT14"))
	arg_22_0:nodeByName("search_txt"):setLocalZOrder(10)

	arg_22_0.search_box = ccui.EditBox:create(var_22_0:getContentSize(), var_22_1)

	arg_22_0.search_box:setAnchorPoint(0, 0)
	arg_22_0.search_box:pos(0, 0)
	var_22_0:addChild(arg_22_0.search_box, 1)
	arg_22_0.search_box:setFont(var_0_16.FONT_NAME, var_0_19)
	arg_22_0.search_box:setPlaceholderFont(var_0_16.FONT_NAME, var_0_19)
	arg_22_0.search_box:setPlaceHolder(var_0_14:translation("CHAT_INPUT_MESSAGE"))
	arg_22_0.search_box:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_22_0.search_box:setFontColor(cc.c3b(0, 0, 0))
	arg_22_0.search_box:setMaxLength(14)
	arg_22_0.search_box:registerScriptEditBoxHandler(handler(arg_22_0, arg_22_0.channelboxEventHandler))
	arg_22_0.search_box:setInputFlag(3)

	arg_22_0.inputFlag = true
end

function var_0_12.registerListeners(arg_23_0)
	arg_23_0:nodeByName("my_present_btn"):addTouchEventListener(function(arg_24_0, arg_24_1)
		if arg_24_1 == ccui.TouchEventType.ended then
			arg_23_0.newTermModel:getReceiveLogs({}, function(arg_25_0, arg_25_1)
				xyd.WindowManager.get():openWindow("new_term_my_presents", arg_25_1)
			end)
		end
	end)
	arg_23_0:nodeByName("connection_rank_btn"):addTouchEventListener(function(arg_26_0, arg_26_1)
		if arg_26_1 == ccui.TouchEventType.ended then
			arg_23_0.newTermModel:getConnectionRankList({}, function(arg_27_0, arg_27_1)
				arg_27_1.mode = var_0_11

				xyd.WindowManager.get():openWindow("new_term_rank", arg_27_1)
			end)
		end
	end)
	arg_23_0:nodeByName("charm_rank_btn"):addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.ended then
			arg_23_0.newTermModel:getCharmRankList({}, function(arg_29_0, arg_29_1)
				arg_29_1.mode = var_0_10

				xyd.WindowManager.get():openWindow("new_term_rank", arg_29_1)
			end)
		end
	end)
	arg_23_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.ended then
			local var_30_0 = {}

			var_30_0.title_name = "LIANYI_GIVE_RULE_TITLE"
			var_30_0.rule = "LIANYI_GIVE_RULE_TEXT"

			xyd.WindowManager.get():openWindow("new_text_rule", var_30_0)
		end
	end)
end

function var_0_12.channelboxEventHandler(arg_31_0, arg_31_1)
	if arg_31_1 == "return" then
		local var_31_0 = arg_31_0.search_box:getText()

		arg_31_0:nodeByName("search_txt"):setString(var_31_0)
		arg_31_0.search_box:setText("")

		arg_31_0.searchTxt = var_31_0
		arg_31_0.inputFlag = false
	end
end

function var_0_12.initListView(arg_32_0)
	if not arg_32_0.listView_ then
		arg_32_0.listView_ = cc.ui.UIListView.new({
			touchOnContent = true,
			async = true,
			viewRect = cc.rect(0, 0, 820, 320),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_32_0:nodeByName("friends_list")):onScroll(handler(arg_32_0, arg_32_0.scrollListener))
	else
		arg_32_0.listView_:removeAllItems()
	end
end

function var_0_12.updateButtonStatus(arg_33_0)
	for iter_33_0 = 1, var_0_9 do
		if iter_33_0 == arg_33_0.showMode then
			arg_33_0.pages[iter_33_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_33_0.pages[iter_33_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_12.layout(arg_34_0)
	arg_34_0:nodeByName("do_search_btn"):setVisible(false)
	arg_34_0:nodeByName("search_box"):setVisible(false)
	arg_34_0:nodeByName("search_txt"):setVisible(false)

	arg_34_0.refreshTip = arg_34_0:nodeByName("refresh_tips")

	arg_34_0.refreshTip:setString(var_0_14:translation("LIANYI_TEXT20"))
	arg_34_0:initListView()
	arg_34_0:initPageButtons()
	arg_34_0:registerListeners()
	arg_34_0:showContainerByMode(arg_34_0.showMode)
end

function var_0_12.createHeroAnimations(arg_35_0)
	local var_35_0 = xyd.tables.misc.newTermAnime

	for iter_35_0, iter_35_1 in ipairs(var_35_0) do
		local var_35_1 = var_0_17.new()

		var_35_1:populateWithTableID(iter_35_1)

		local var_35_2 = var_35_1:getHeroModel()

		var_35_2:setScale(0.6)
		var_35_2:addTo(arg_35_0:nodeByName("hero_node" .. iter_35_0))
		var_35_2:win(true)

		if iter_35_0 > 3 then
			var_35_2:setScaleX(-0.6)
		end
	end
end

function var_0_12.willClose(arg_36_0)
	if arg_36_0.handle then
		var_0_15.unscheduleGlobal(arg_36_0.handle)

		arg_36_0.handle = nil
	end
end

return var_0_12
