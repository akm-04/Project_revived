local var_0_0 = class("TeamReadGuildWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.misc.guildIdLengthLimit
local var_0_4 = xyd.tables.misc.teamIcons[1]

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:init()
end

function var_0_0.init(arg_3_0)
	arg_3_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_3_0.container = arg_3_0:nodeByName("join_list")

	arg_3_0:nodeByName("fresh_words"):setString(var_0_2:translation("LIST_REFRESH"))
	arg_3_0:nodeByName("id_words"):setString(var_0_2:translation("GUILD_ID_DESC"))
	arg_3_0:nodeByName("join_words"):setString(var_0_2:translation("SHE_TUAN_TEXT_23"))
	arg_3_0:nodeByName("title"):setString(var_0_2:translation("SHE_TUAN_TEXT_22"))
	arg_3_0:nodeByName("find_words"):setString(var_0_2:translation("SHE_TUAN_TEXT_24"))
	arg_3_0:nodeByName("find_words_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_25"))
	arg_3_0:nodeByName("hero_words"):setString(var_0_2:translation("SHE_TUAN_TEXT_26"))

	local var_3_0 = arg_3_0.container:getContentSize()

	arg_3_0.ApplyList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.container):onScroll(handler(arg_3_0, arg_3_0.scrollListener)):setTouchType(true):pos(0, 0)

	local var_3_1 = arg_3_0:nodeByName("find_list"):getContentSize()

	arg_3_0.searchList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("find_container")):setTouchType(true):pos(0, 0)

	local var_3_2 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_3_2, cc.rect(28, 28, 1, 1))

	arg_3_0.sidEditbox_ = ccui.EditBox:create(cc.size(arg_3_0:nodeByName("kuang"):getWidth(), arg_3_0:nodeByName("kuang"):getHeight()), var_3_2):align(display.CENTER, arg_3_0:nodeByName("kuang"):getX(), arg_3_0:nodeByName("kuang"):getY()):addTo(arg_3_0:nodeByName("find_container"))

	arg_3_0:nodeByName("id_text"):setString("")
	arg_3_0.sidEditbox_:registerScriptEditBoxHandler(handler(arg_3_0, arg_3_0.inputboxEventHandler))
	arg_3_0.sidEditbox_:setInputFlag(3)
	arg_3_0:nodeByName("join_btn"):setLocalZOrder(10)
	arg_3_0:nodeByName("join_words"):setLocalZOrder(11)
	arg_3_0:nodeByName("find_btn"):setLocalZOrder(10)
	arg_3_0:nodeByName("find_words"):setLocalZOrder(11)
	arg_3_0:updateList()

	arg_3_0.index = 1

	arg_3_0:updateHighlight(1)
end

function var_0_0.inputboxEventHandler(arg_4_0, arg_4_1)
	if arg_4_1 == "began" then
		local var_4_0 = arg_4_0:nodeByName("id_text"):getString()

		arg_4_0:nodeByName("id_text"):setString("")
		arg_4_0.sidEditbox_:setText(var_4_0)
	end

	if arg_4_1 == "return" then
		local var_4_1 = arg_4_0.sidEditbox_:getText()

		if string.find(var_4_1, "%D") == nil and string.len(var_4_1) <= var_0_3 then
			arg_4_0:nodeByName("id_text"):setString(var_4_1)

			arg_4_0.team_id = var_4_1
		else
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, xyd.tables.translation:translation("TEAM_INPUT_RIGHT_ID_ALERT"), nil, nil, nil, arg_4_0.colorMode)
		end

		arg_4_0.sidEditbox_:setText("")
		arg_4_0.sidEditbox_:setVisible(true)
	end
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:nodeByName("join_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_5_0.index = 1

			arg_5_0:updateHighlight(1)
		end
	end)
	arg_5_0:nodeByName("find_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_5_0.index = 2

			arg_5_0:updateHighlight(2)
		end
	end)
	arg_5_0:nodeByName("close_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_5_0:nodeByName("close_btn"), arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_8_0, false)
			xyd.WindowManager.get():closeWindow(arg_5_0.name)
		end
	end)
end

function var_0_0.updateHighlight(arg_9_0, arg_9_1)
	if arg_9_1 == 1 then
		arg_9_0:nodeByName("fresh_words"):setVisible(false)
		arg_9_0:nodeByName("join_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_9_0:nodeByName("find_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_9_0:nodeByName("find_container"):setVisible(false)
		arg_9_0.ApplyList_:setLocalZOrder(11)
		arg_9_0.searchList_:setLocalZOrder(10)

		arg_9_0.team_id = nil
	elseif arg_9_1 == 2 then
		arg_9_0:nodeByName("join_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_9_0:nodeByName("find_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_9_0:nodeByName("find_container"):setVisible(true)
		arg_9_0.ApplyList_:setLocalZOrder(10)
		arg_9_0.searchList_:setLocalZOrder(11)
	end

	arg_9_0:updateList()
end

function var_0_0.updateList(arg_10_0)
	if arg_10_0.index == 1 then
		arg_10_0.guild:loadAllTeam(function()
			arg_10_0.teams = arg_10_0.guild.allTeams

			arg_10_0:updateApplyList()
		end)
	else
		arg_10_0.ApplyList_:removeAllItems()
		arg_10_0.searchList_:removeAllItems()

		arg_10_0.team_id = arg_10_0:nodeByName("id_text"):getString()

		arg_10_0:searchFunction()
	end
end

function var_0_0.searchFunction(arg_12_0)
	arg_12_0:nodeByName("fresh_words"):setVisible(false)
	arg_12_0:nodeByName("search_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_12_0:nodeByName("search_btn"), arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_12_0.team_id ~= nil and arg_12_0.team_id ~= "" then
				arg_12_0.guild:loadOtherGuild(function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						if arg_12_0.guild.other_guild_id and arg_12_0.guild.other_guild_id ~= 0 then
							local var_14_0 = {
								icon = arg_12_0.guild.other_guild_icon,
								des = arg_12_0.guild.other_guild_des,
								min_allow_level = arg_12_0.guild.other_min_lev,
								name = arg_12_0.guild.other_guild_name,
								member_num = arg_12_0.guild.other_member_nums,
								apply_type = arg_12_0.guild.other_apply_type,
								guild_id = arg_12_0.guild.other_guild_id,
								huoyue = arg_12_0.guild.other_huoyue,
								guild_leader = arg_12_0.guild.other_guild_leader,
								guild_leader_name = arg_12_0.guild.other_guild_leader_name
							}

							arg_12_0:nodeByName("bg_hero"):setVisible(false)
							arg_12_0:updateApplyList(var_14_0)
						else
							arg_12_0:nodeByName("bg_hero"):setVisible(true)
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_2:translation("TEAM_NOT_FIND"), nil, nil, nil, arg_12_0.colorMode)
							arg_12_0.searchList_:removeAllItems()
						end

						return true
					end
				end, {
					guild_id = tonumber(arg_12_0.team_id)
				})
			else
				arg_12_0.ApplyList_:removeAllItems()
				arg_12_0.searchList_:removeAllItems()
			end
		end
	end)
end

function var_0_0.updateApplyList(arg_15_0, arg_15_1)
	arg_15_0.ApplyList_:removeAllItems()
	arg_15_0.searchList_:removeAllItems()

	local var_15_0

	if arg_15_1 then
		arg_15_0.teams = {}

		table.insert(arg_15_0.teams, arg_15_1)

		var_15_0 = arg_15_0.searchList_
	else
		var_15_0 = arg_15_0.ApplyList_
	end

	for iter_15_0, iter_15_1 in pairs(arg_15_0.teams) do
		local var_15_1 = display.newNode()
		local var_15_2 = var_15_0:newItem()
		local var_15_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/team_read_guild_window/read_guild_item.csb")
		local var_15_4 = var_15_3:getChildByName("container")
		local var_15_5 = var_15_4:getChildByName("name_text"):getWidth()

		arg_15_0:setAvatar(var_15_4:getChildByName("icon_container"), iter_15_1.icon)
		var_15_4:getChildByName("need_level_text"):setString(string.format(var_0_2:translation("TEAM_JOIN_ITEM_NEED_LEV"), iter_15_1.min_allow_level))
		var_15_4:getChildByName("name_text"):setString(iter_15_1.name)

		local var_15_6 = var_15_4:getChildByName("name_text"):getWidth() - var_15_5

		var_15_4:getChildByName("huoyue_text"):setString(string.format(var_0_2:translation("GUILD_ACTIVE_NUM"), iter_15_1.huoyue))

		local var_15_7 = var_15_4:getContentSize()

		var_15_3:setPosition(cc.p(0, 0))
		var_15_3:setContentSize(var_15_7.width + 5, var_15_7.height)
		var_15_1:addChild(var_15_3)
		var_15_1:setContentSize(cc.size(var_15_0.viewRect_.width, var_15_3:getContentSize().height + 5))
		var_15_2:addContent(var_15_1)
		var_15_2:setItemSize(var_15_0.viewRect_.width, var_15_1:getContentSize().height)

		local var_15_8 = var_15_4:getChildByName("tel_btn")

		var_15_8:addTouchEventListener(function(arg_16_0, arg_16_1)
			xyd.buttonScaleAnim(var_15_8, arg_16_1)

			if arg_16_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("FUNCTION_NOT_OPEN")
				})
			end
		end)
		var_15_0:addItem(var_15_2)

		if iter_15_1.des == "" then
			var_15_4:getChildByName("team_ads_text"):setString(DEFAULT_DES)
		else
			local var_15_9 = ""

			if xyd.getTextLen(iter_15_1.des) >= 19 then
				var_15_9 = xyd.getTextstr(iter_15_1.des, 0, 18) .. "…"
			else
				var_15_9 = iter_15_1.des
			end

			var_15_4:getChildByName("team_ads_text"):setString(var_15_9)
		end
	end

	var_15_0:reload()
end

function var_0_0.setAvatar(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = "images/icon/skill_icon/" .. arg_17_2 .. "_icon.png" or "images/icon/skill_icon/" .. var_0_4 .. "_icon.png"
	local var_17_1 = xyd.AssetLoader:get():loadSprite(var_17_0)
	local var_17_2 = arg_17_1:getContentSize()
	local var_17_3 = arg_17_1:getContentSize().width
	local var_17_4 = arg_17_1:getContentSize().height
	local var_17_5 = xyd.AssetLoader:get():loadSprite("images/avatars/mask1.png")

	var_17_5:setPosition(var_17_3 / 2, var_17_4 / 2)
	var_17_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_17_5:setScale(var_17_4 / var_17_5:getHeight())

	local var_17_6 = cc.ClippingNode:create()

	var_17_6:setStencil(var_17_5)
	var_17_6:setInverted(true)
	var_17_6:setAlphaThreshold(0)
	var_17_6:addChild(var_17_1)
	var_17_1:align(display.CENTER, var_17_2.width / 2, var_17_2.height / 2)
	var_17_1:scale(var_17_2.width / var_17_1:getWidth())
	arg_17_1:addChild(var_17_6)

	local var_17_7 = xyd.AssetLoader:get():loadSprite("windows/corporation_window/team_icon_window/icon_bg2.png")
	local var_17_8 = clone(var_17_7:getContentSize())

	xyd.displaySpriteOnContainer(var_17_7, arg_17_1, true)

	local var_17_9 = display.newNode()

	var_17_9:setName("view")
	var_17_9:setContentSize(var_17_8)
	var_17_9:setAnchorPoint(cc.p(0, 0))
	var_17_9:setPosition(cc.p(0, 0))
	var_17_9:setScale(var_17_2.width / var_17_8.width, var_17_2.height / var_17_8.height)
	arg_17_1:addChild(var_17_9)
end

function var_0_0.scrollListener(arg_18_0, arg_18_1)
	if arg_18_1.name == "began" then
		arg_18_0:nodeByName("fresh_words"):setVisible(false)

		arg_18_0.is_scroll = false
		arg_18_0.scrollViewMoved_ = false
		arg_18_0.prevY_ = arg_18_1.y
	elseif arg_18_1.name == "moved" then
		if 1 <= math.abs(arg_18_1.y - arg_18_0.prevY_) then
			arg_18_0.scrollViewMoved_ = true
		end

		local var_18_0 = arg_18_0.ApplyList_:getScrollNode()
		local var_18_1 = arg_18_0.ApplyList_:getScrollNodeRect()
		local var_18_2 = arg_18_0.ApplyList_:getViewRectInWorldSpace()
		local var_18_3 = var_18_1.height - var_18_2.height

		if var_18_0:getPositionY() + var_18_3 < -100 then
			arg_18_0:nodeByName("fresh_words"):setVisible(true)

			arg_18_0.is_scroll = true
		end
	end

	if arg_18_1.name == "scrollEnd" then
		arg_18_0:nodeByName("fresh_words"):setVisible(false)

		if arg_18_0.is_scroll == true then
			arg_18_0:updateList()

			arg_18_0.is_scroll = false
		end
	end
end

return var_0_0
