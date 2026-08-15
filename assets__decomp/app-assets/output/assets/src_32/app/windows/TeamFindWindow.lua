local var_0_0 = class("TeamFindWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc.guildIdLengthLimit

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
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("Text_1"):setString(string.format(var_0_3:translation("PLAYER_INFO_TEAM_ID"), ""))
	arg_4_0:nodeByName("find_words"):setString(var_0_3:translation("SHE_TUAN_TEXT_47"))
	arg_4_0:nodeByName("hero_words"):setString(var_0_3:translation("SHE_TUAN_TEXT_26"))

	arg_4_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_4_0.container = arg_4_0:nodeByName("list_container")

	local var_4_0 = arg_4_0.container:getContentSize()

	arg_4_0.ApplyList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.container):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setTouchType(true):pos(0, 0)

	local var_4_1 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_4_1, cc.rect(28, 28, 1, 1))

	arg_4_0.sidEditbox_ = ccui.EditBox:create(cc.size(arg_4_0:nodeByName("bg_input"):getWidth(), arg_4_0:nodeByName("bg_input"):getHeight()), var_4_1):align(display.CENTER, arg_4_0:nodeByName("bg_input"):getX(), arg_4_0:nodeByName("bg_input"):getY()):addTo(arg_4_0:nodeByName("container"))

	arg_4_0:nodeByName("name_text"):setString("")
	arg_4_0.sidEditbox_:registerScriptEditBoxHandler(handler(arg_4_0, arg_4_0.inputboxEventHandler))
	arg_4_0.sidEditbox_:setInputFlag(3)
	arg_4_0.guild:loadApplyList(function()
		arg_4_0.apply_teams = arg_4_0.guild.applyTeams
		arg_4_0.teams = arg_4_0.guild.allTeams

		arg_4_0:nodeByName("find_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
			xyd.buttonScaleAnim(arg_4_0:nodeByName("find_btn"), arg_6_1)

			if arg_6_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_4_0.guild:loadOtherGuild(function(arg_7_0, arg_7_1)
					if arg_7_0 == xyd.error.OK then
						if arg_4_0.guild.other_guild_id and arg_4_0.guild.other_guild_id ~= 0 then
							local var_7_0 = {
								icon = arg_4_0.guild.other_guild_icon,
								des = arg_4_0.guild.other_guild_des,
								min_allow_level = arg_4_0.guild.other_min_lev,
								name = arg_4_0.guild.other_guild_name,
								member_num = arg_4_0.guild.other_member_nums,
								apply_type = arg_4_0.guild.other_apply_type,
								guild_id = arg_4_0.guild.other_guild_id
							}

							arg_4_0:nodeByName("bg_hero"):setVisible(false)
							arg_4_0:updateApplyList(var_7_0)
						else
							arg_4_0:nodeByName("bg_hero"):setVisible(true)
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_3:translation("TEAM_NOT_FIND"), nil, nil, nil, arg_4_0.colorMode)
							arg_4_0.ApplyList_:removeAllItems()
						end

						return true
					end
				end, {
					guild_id = tonumber(arg_4_0.team_id)
				})
			end
		end)
	end)
end

function var_0_0.updateApplyList(arg_8_0, arg_8_1)
	arg_8_0.ApplyList_:removeAllItems()

	local var_8_0 = display.newNode()
	local var_8_1 = arg_8_0.ApplyList_:newItem()
	local var_8_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/team_window/join_team/join_team_item.csb")
	local var_8_3 = var_8_2:getChildByName("container")
	local var_8_4 = var_8_3:getChildByName("name_text"):getWidth()

	arg_8_0:setAvatar(var_8_3:getChildByName("icon_container"), arg_8_1.icon)
	var_8_3:getChildByName("need_level_text"):setString(string.format(var_0_3:translation("TEAM_JOIN_ITEM_NEED_LEV"), arg_8_1.min_allow_level))
	var_8_3:getChildByName("name_text"):setString(arg_8_1.name)

	local var_8_5 = var_8_3:getChildByName("person_num_text")

	var_8_5:setString(string.format(var_0_3:translation("TEAM_JOIN_ITEM_PERSONS"), arg_8_1.member_num))

	local var_8_6 = var_8_3:getChildByName("name_text"):getWidth() - var_8_4

	var_8_5:setPosition(cc.p(var_8_5:getX() + var_8_6, var_8_5:getY()))

	local var_8_7 = var_8_3:getContentSize()

	var_8_2:setPosition(cc.p(0, 0))
	var_8_2:setContentSize(var_8_7.width, var_8_7.height)
	var_8_0:addChild(var_8_2)
	var_8_0:setContentSize(cc.size(arg_8_0.ApplyList_.viewRect_.width, var_8_2:getContentSize().height + 5))
	var_8_1:addContent(var_8_0)
	var_8_1:setItemSize(arg_8_0.ApplyList_.viewRect_.width, var_8_0:getContentSize().height)

	local var_8_8 = var_8_3:getChildByName("join_btn")
	local var_8_9 = var_0_2.new({
		size = 428
	})

	var_8_9:addTo(var_8_3:getChildByName("line"))
	var_8_9:setAnchorPoint(0, 0.5)
	arg_8_0.ApplyList_:addItem(var_8_1)
	var_8_8:getChildByName("apply_cancel_words"):setVisible(false)
	var_8_8:getChildByName("apply_words"):setVisible(false)
	var_8_8:getChildByName("liji_words"):setVisible(false)
	var_8_8:getChildByName("refuse_words"):setVisible(false)
	var_8_8:getChildByName("apply_cancel_words"):setString(var_0_3:translation("SHE_TUAN_TEXT_44"))
	var_8_8:getChildByName("apply_words"):setString(var_0_3:translation("SHE_TUAN_TEXT_45"))
	var_8_8:getChildByName("liji_words"):setString(var_0_3:translation("SHE_TUAN_TEXT_42"))
	var_8_8:getChildByName("refuse_words"):setString(var_0_3:translation("SHE_TUAN_TEXT_43"))

	if arg_8_1.apply_type == 1 then
		var_8_8:getChildByName("liji_words"):setVisible(true)
		var_8_8:setLocalZOrder(0)
		var_8_8:addTouchEventListener(function(arg_9_0, arg_9_1)
			xyd.buttonScaleAnim(var_8_8, arg_9_1)

			if arg_9_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if arg_8_0.player.lev >= arg_8_1.min_allow_level then
					local var_9_0 = {
						guild_id = arg_8_1.guild_id
					}

					arg_8_0.guild:applyTeam(var_9_0, function(arg_10_0, arg_10_1)
						if arg_10_1.error_code == xyd.CantJoinGuild then
							xyd.WindowManager.get():openWindow("team_cant_join_alert", {
								time_ = arg_10_1.time
							})
						elseif arg_10_0 == xyd.error.OK then
							arg_8_0.guild:loadSelfGuild(function()
								xyd.WindowManager.get():openWindow("team")
								xyd.EventDispatcher.get():dispatchEvent({
									name = xyd.event.DRINK_NOTIF
								})
								xyd.WindowManager.get():closeWindow(arg_8_0)
								xyd.WindowManager.get():closeWindow("team_main")

								return true
							end)
						end
					end)
				else
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_3:translation("TEAM_LEV_TOO_LOW_ALERT"), nil, nil, nil, arg_8_0.colorMode)
				end
			end
		end)
	elseif arg_8_1.apply_type == 0 then
		local var_8_10 = false

		for iter_8_0, iter_8_1 in pairs(arg_8_0.apply_teams) do
			if arg_8_1.guild_id == iter_8_1.guild_id then
				var_8_10 = true

				break
			end
		end

		if var_8_10 == false then
			var_8_8:getChildByName("apply_words"):setVisible(true)
			var_8_8:getChildByName("apply_cancel_words"):setVisible(false)
		else
			var_8_8:getChildByName("apply_cancel_words"):setVisible(true)
			var_8_8:getChildByName("apply_words"):setVisible(false)
		end

		var_8_8:setLocalZOrder(0)
		var_8_8:addTouchEventListener(function(arg_12_0, arg_12_1)
			xyd.buttonScaleAnim(var_8_8, arg_12_1)

			if arg_12_1 == ccui.TouchEventType.ended then
				if var_8_10 == false then
					xyd.playButtonSound()

					if arg_8_0.player.lev >= arg_8_1.min_allow_level then
						local var_12_0 = {
							guild_id = arg_8_1.guild_id
						}

						arg_8_0.guild:applyTeam(var_12_0, function(arg_13_0, arg_13_1)
							if arg_13_1.error_code == xyd.CantJoinGuild then
								xyd.WindowManager.get():openWindow("team_cant_join_alert", {
									time_ = arg_13_1.time
								})
							elseif arg_13_0 == xyd.error.OK then
								var_8_8:getChildByName("apply_words"):setVisible(false)
								var_8_8:getChildByName("apply_cancel_words"):setVisible(true)

								var_8_10 = true

								return true
							end
						end)
					else
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_3:translation("TEAM_LEV_TOO_LOW_ALERT"), nil, nil, nil, arg_8_0.colorMode)
					end
				else
					local var_12_1 = xyd.tables.sound:getSound("ui_close_window")

					audio.playSound(var_12_1, false)

					local var_12_2 = {
						guild_id = arg_8_1.guild_id
					}

					arg_8_0.guild:cancelApply(var_12_2, function(arg_14_0)
						if arg_14_0 == xyd.error.OK then
							var_8_8:getChildByName("apply_words"):setVisible(true)
							var_8_8:getChildByName("apply_cancel_words"):setVisible(false)

							var_8_10 = false

							return true
						end
					end)
				end
			end
		end)
	elseif arg_8_1.apply_type == 2 then
		var_8_8:getChildByName("refuse_words"):setVisible(true)
		var_8_8:setLocalZOrder(0)
		var_8_8:addTouchEventListener(function(arg_15_0, arg_15_1)
			xyd.buttonScaleAnim(var_8_8, arg_15_1)

			if arg_15_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_3:translation("TEAM_JOIN_ITEM_REFUSE_ALERT"), nil, nil, nil, arg_8_0.colorMode)
			end
		end)
	end

	if arg_8_1.des == "" then
		var_8_3:getChildByName("team_ads_text"):setString(DEFAULT_DES)
	else
		local var_8_11 = ""

		if xyd.getTextLen(arg_8_1.des) >= 19 then
			var_8_11 = xyd.getTextstr(arg_8_1.des, 0, 18) .. "…"
		else
			var_8_11 = arg_8_1.des
		end

		var_8_3:getChildByName("team_ads_text"):setString(var_8_11)
	end

	arg_8_0.ApplyList_:reload()
end

function var_0_0.setAvatar(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = "images/icon/skill_icon/" .. arg_16_2 .. "_icon.png" or "images/icon/skill_icon/" .. DEFAULT_ICON .. "_icon.png"
	local var_16_1 = xyd.AssetLoader:get():loadSprite(var_16_0)
	local var_16_2 = arg_16_1:getContentSize()
	local var_16_3 = arg_16_1:getContentSize().width
	local var_16_4 = arg_16_1:getContentSize().height
	local var_16_5 = xyd.AssetLoader:get():loadSprite("images/avatars/mask1.png")

	var_16_5:setPosition(var_16_3 / 2, var_16_4 / 2)
	var_16_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_16_5:setScale(var_16_4 / var_16_5:getHeight())

	local var_16_6 = cc.ClippingNode:create()

	var_16_6:setStencil(var_16_5)
	var_16_6:setInverted(true)
	var_16_6:setAlphaThreshold(0)
	var_16_6:addChild(var_16_1)
	var_16_1:align(display.CENTER, var_16_2.width / 2, var_16_2.height / 2)
	var_16_1:scale(var_16_2.width / var_16_1:getWidth())
	arg_16_1:addChild(var_16_6)

	local var_16_7 = xyd.AssetLoader:get():loadSprite("windows/corporation_window/team_icon_window/icon_bg2.png")
	local var_16_8 = clone(var_16_7:getContentSize())

	xyd.displaySpriteOnContainer(var_16_7, arg_16_1, true)

	local var_16_9 = display.newNode()

	var_16_9:setName("view")
	var_16_9:setContentSize(var_16_8)
	var_16_9:setAnchorPoint(cc.p(0, 0))
	var_16_9:setPosition(cc.p(0, 0))
	var_16_9:setScale(var_16_2.width / var_16_8.width, var_16_2.height / var_16_8.height)
	arg_16_1:addChild(var_16_9)
end

function var_0_0.inputboxEventHandler(arg_17_0, arg_17_1)
	if arg_17_1 == "began" then
		local var_17_0 = arg_17_0:nodeByName("name_text"):getString()

		arg_17_0:nodeByName("name_text"):setString("")
		arg_17_0.sidEditbox_:setText(var_17_0)
	end

	if arg_17_1 == "return" then
		local var_17_1 = arg_17_0.sidEditbox_:getText()

		if string.find(var_17_1, "%D") == nil and string.len(var_17_1) <= var_0_4 then
			arg_17_0:nodeByName("name_text"):setString(var_17_1)

			arg_17_0.team_id = var_17_1
		else
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, xyd.tables.translation:translation("TEAM_INPUT_RIGHT_ID_ALERT"), nil, nil, nil, arg_17_0.colorMode)
		end

		arg_17_0.sidEditbox_:setText("")
		arg_17_0.sidEditbox_:setVisible(true)
	end
end

function var_0_0.scrollListener(arg_18_0, arg_18_1)
	if arg_18_1.name == "began" then
		arg_18_0.scrollViewMoved_ = false
		arg_18_0.prevX_ = arg_18_1.x
	elseif arg_18_1.name == "moved" and 1 <= math.abs(arg_18_1.x - arg_18_0.prevX_) then
		arg_18_0.scrollViewMoved_ = true
	end
end

return var_0_0
