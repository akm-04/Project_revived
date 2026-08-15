local var_0_0 = class("TeamJoinWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc.teamIcons[1]
local var_0_5 = var_0_3:translation("TEAM_JOIN_ITEM_DEFAULT_DES")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:nodeByName("back_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("back_btn"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_4_0, false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
			xyd.WindowManager.get():closeWindow("team_main")
			xyd.WindowManager.get():closeWindow("team_create")
			xyd.WindowManager.get():closeWindow("team_find")
		end
	end)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("fresh_words"):setString(var_0_3:translation("LIST_REFRESH"))

	arg_5_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_5_0.container = arg_5_0:nodeByName("container")

	local var_5_0 = arg_5_0.container:getContentSize()

	arg_5_0.ApplyList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_0.width, var_5_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0.container):onScroll(handler(arg_5_0, arg_5_0.scrollListener)):setTouchType(true):pos(0, 0)

	arg_5_0.ApplyList_:setTouchSwallowEnabled(false)
	arg_5_0.ApplyList_:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0:updateList()
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = arg_6_0.teams

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return #var_6_0
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		if arg_6_3 > #var_6_0 then
			return nil
		end

		local var_6_1 = display.newNode()
		local var_6_2 = arg_6_0.ApplyList_:dequeueItem()

		if not var_6_2 then
			var_6_2 = arg_6_0.ApplyList_:newItem()
		else
			var_6_2:removeAllChildren(true)
		end

		local var_6_3 = var_6_0[arg_6_3]
		local var_6_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/team_window/join_team/join_team_item.csb")
		local var_6_5 = var_6_4:getChildByName("container")
		local var_6_6 = var_6_5:getChildByName("name_text"):getWidth()

		arg_6_0:setAvatar(var_6_5:getChildByName("icon_container"), var_6_3.icon)
		var_6_5:getChildByName("need_level_text"):setString(string.format(var_0_3:translation("TEAM_JOIN_ITEM_NEED_LEV"), var_6_3.min_allow_level))
		var_6_5:getChildByName("name_text"):setString(var_6_3.name)
		var_6_5:getChildByName("txt_region"):setString("s" .. xyd.getGuildRegion(var_6_3.guild_id))

		local var_6_7 = var_6_5:getChildByName("person_num_text")

		var_6_7:setString(string.format(var_0_3:translation("TEAM_JOIN_ITEM_PERSONS"), var_6_3.member_num))

		local var_6_8 = var_6_5:getChildByName("name_text"):getWidth() - var_6_6

		var_6_7:setPosition(cc.p(var_6_7:getX() + var_6_8, var_6_7:getY()))

		local var_6_9 = var_6_5:getContentSize()

		var_6_4:setPosition(cc.p(0, 0))
		var_6_4:setContentSize(var_6_9.width, var_6_9.height)
		var_6_1:addChild(var_6_4)
		var_6_1:setContentSize(cc.size(arg_6_0.ApplyList_.viewRect_.width, var_6_4:getContentSize().height + 5))
		var_6_2:addContent(var_6_1)
		var_6_2:setItemSize(arg_6_0.ApplyList_.viewRect_.width, var_6_1:getContentSize().height)

		local var_6_10 = var_6_5:getChildByName("join_btn")
		local var_6_11 = var_0_2.new({
			size = 428
		})

		var_6_11:addTo(var_6_5:getChildByName("line"))
		var_6_11:setAnchorPoint(0, 0.5)
		var_6_10:getChildByName("apply_cancel_words"):setVisible(false)
		var_6_10:getChildByName("apply_words"):setVisible(false)
		var_6_10:getChildByName("liji_words"):setVisible(false)
		var_6_10:getChildByName("refuse_words"):setVisible(false)
		var_6_10:getChildByName("apply_cancel_words"):setString(var_0_3:translation("SHE_TUAN_TEXT_44"))
		var_6_10:getChildByName("apply_words"):setString(var_0_3:translation("SHE_TUAN_TEXT_45"))
		var_6_10:getChildByName("liji_words"):setString(var_0_3:translation("SHE_TUAN_TEXT_42"))
		var_6_10:getChildByName("refuse_words"):setString(var_0_3:translation("SHE_TUAN_TEXT_43"))

		if var_6_3.apply_type == 1 then
			var_6_10:getChildByName("liji_words"):setVisible(true)
			var_6_10:setLocalZOrder(0)
			var_6_10:addTouchEventListener(function(arg_7_0, arg_7_1)
				xyd.buttonScaleAnim(var_6_10, arg_7_1)

				if arg_7_1 == ccui.TouchEventType.ended and arg_6_0.scrollViewMoved_ == false then
					xyd.playButtonSound()

					if arg_6_0.player.lev >= var_6_3.min_allow_level then
						local var_7_0 = {
							guild_id = var_6_3.guild_id
						}

						arg_6_0.guild:applyTeam(var_7_0, function(arg_8_0, arg_8_1)
							if arg_8_1.error_code == xyd.CantJoinGuild then
								xyd.WindowManager.get():openWindow("team_cant_join_alert", {
									time_ = arg_8_1.time
								})
							elseif arg_8_0 == xyd.error.OK then
								arg_6_0.guild:loadSelfGuild(function()
									xyd.WindowManager.get():openWindow("team")
									xyd.EventDispatcher.get():dispatchEvent({
										name = xyd.event.DRINK_NOTIF
									})
									xyd.WindowManager.get():closeWindow(arg_6_0)
									xyd.WindowManager.get():closeWindow("team_main")

									return true
								end)
							end
						end)
					else
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_3:translation("TEAM_LEV_TOO_LOW_ALERT"), nil, nil, nil, arg_6_0.colorMode)
					end
				end
			end)
		elseif var_6_3.apply_type == 0 then
			local var_6_12 = false

			for iter_6_0, iter_6_1 in pairs(arg_6_0.apply_teams) do
				if var_6_3.guild_id == iter_6_1.guild_id then
					var_6_12 = true

					break
				end
			end

			if var_6_12 == false then
				var_6_10:getChildByName("apply_words"):setVisible(true)
				var_6_10:getChildByName("apply_cancel_words"):setVisible(false)
			else
				var_6_10:getChildByName("apply_cancel_words"):setVisible(true)
				var_6_10:getChildByName("apply_words"):setVisible(false)
			end

			var_6_10:setLocalZOrder(0)
			var_6_10:addTouchEventListener(function(arg_10_0, arg_10_1)
				xyd.buttonScaleAnim(var_6_10, arg_10_1)

				if arg_10_1 == ccui.TouchEventType.ended and arg_6_0.scrollViewMoved_ == false then
					if var_6_12 == false then
						xyd.playButtonSound()

						if arg_6_0.player.lev >= var_6_3.min_allow_level then
							local var_10_0 = {
								guild_id = var_6_3.guild_id
							}

							arg_6_0.guild:applyTeam(var_10_0, function(arg_11_0, arg_11_1)
								if arg_11_1.error_code == xyd.CantJoinGuild then
									xyd.WindowManager.get():openWindow("team_cant_join_alert", {
										time_ = arg_11_1.time
									})
								elseif arg_11_0 == xyd.error.OK then
									var_6_10:getChildByName("apply_words"):setVisible(false)
									var_6_10:getChildByName("apply_cancel_words"):setVisible(true)

									var_6_12 = true

									return true
								end
							end)
						else
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_3:translation("TEAM_LEV_TOO_LOW_ALERT"), nil, nil, nil, arg_6_0.colorMode)
						end
					else
						local var_10_1 = xyd.tables.sound:getSound("ui_close_window")

						audio.playSound(var_10_1, false)

						local var_10_2 = {
							guild_id = var_6_3.guild_id
						}

						arg_6_0.guild:cancelApply(var_10_2, function(arg_12_0)
							if arg_12_0 == xyd.error.OK then
								var_6_10:getChildByName("apply_words"):setVisible(true)
								var_6_10:getChildByName("apply_cancel_words"):setVisible(false)

								var_6_12 = false

								return true
							end
						end)
					end
				end
			end)
		elseif var_6_3.apply_type == 2 then
			var_6_10:getChildByName("refuse_words"):setVisible(true)
			var_6_10:setLocalZOrder(0)
			var_6_10:addTouchEventListener(function(arg_13_0, arg_13_1)
				xyd.buttonScaleAnim(var_6_10, arg_13_1)

				if arg_13_1 == ccui.TouchEventType.ended and arg_6_0.scrollViewMoved_ == false then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_3:translation("TEAM_JOIN_ITEM_REFUSE_ALERT"), nil, nil, nil, arg_6_0.colorMode)
				end
			end)
		end

		if var_6_3.des == "" then
			var_6_5:getChildByName("team_ads_text"):setString(var_0_5)
		else
			local var_6_13 = ""

			if xyd.getTextLen(var_6_3.des) >= 19 then
				var_6_13 = xyd.getTextstr(var_6_3.des, 0, 18) .. "…"
			else
				var_6_13 = var_6_3.des
			end

			var_6_5:getChildByName("team_ads_text"):setString(var_6_13)
		end

		return var_6_2
	end
end

function var_0_0.updateList(arg_14_0)
	arg_14_0:nodeByName("fresh_words"):setVisible(false)
	arg_14_0.guild:loadApplyList(function()
		arg_14_0.guild:loadAllTeam(function()
			arg_14_0.apply_teams = arg_14_0.guild.applyTeams
			arg_14_0.teams = arg_14_0.guild.allTeams

			arg_14_0.ApplyList_:reload()
		end)
	end)
end

function var_0_0.setAvatar(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = "images/icon/skill_icon/" .. arg_17_2 .. "_icon.png" or "images/icon/skill_icon/" .. var_0_4 .. "_icon.png"
	local var_17_1 = xyd.SpriteLoader.new(var_17_0, nil, extra_params, xyd.DefaultImageType.SKILL_ICON)
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
		arg_18_0.nodeY = arg_18_0.ApplyList_:getScrollNode():getPositionY()

		arg_18_0:nodeByName("fresh_words"):setVisible(false)

		arg_18_0.is_scroll = false
		arg_18_0.scrollViewMoved_ = false
		arg_18_0.prevY_ = arg_18_1.y
	elseif arg_18_1.name == "moved" then
		if 1 <= math.abs(arg_18_1.y - arg_18_0.prevY_) then
			arg_18_0.scrollViewMoved_ = true
		end

		if arg_18_0.ApplyList_:getScrollNode():getPositionY() - arg_18_0.nodeY < -100 then
			arg_18_0:nodeByName("fresh_words"):setVisible(true)

			arg_18_0.is_scroll = true
		end
	end

	if arg_18_1.name == "scrollEnd" and arg_18_0.is_scroll == true then
		arg_18_0:updateList()

		arg_18_0.is_scroll = false
	end
end

return var_0_0
