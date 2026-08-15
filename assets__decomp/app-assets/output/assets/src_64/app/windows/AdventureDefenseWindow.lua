local var_0_0 = class("AdventureDefenseWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("app.model.Hero")
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.adventureEvent
local var_0_6 = xyd.tables.adventureDefense

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.detail = arg_1_0.adventureEvent.teamDefenseInfo
	arg_1_0.eventId = xyd.AdventureEventType.DEFENSE
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.models = var_0_6:models(arg_1_0.detail.room_info.campaign_id)
end

function var_0_0.setupBackground(arg_2_0)
	if arg_2_0.bg then
		arg_2_0:removeChild(arg_2_0.bg, true)
	end

	arg_2_0.bg = xyd.AssetLoader.get():loadSprite(var_0_5:contentBg(tostring(arg_2_0.eventId)))

	arg_2_0.bg:setAnchorPoint(0, 0)
	arg_2_0.bg:setPosition(0, 0)
	arg_2_0.bg:setScale(cc.Director:getInstance():getOpenGLView():getFrameSize().width / arg_2_0.bg:getContentSize().width)
	arg_2_0.bg:addTo(arg_2_0, -1)
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
end

function var_0_0.didClose(arg_5_0, arg_5_1)
	var_0_0.super:didClose(arg_5_1)

	if arg_5_0.handle_ then
		var_0_1.unscheduleGlobal(arg_5_0.handle_)
	end
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("txt_notice"):setString(var_0_4:translation("ADVENTURE_MONSTER_NOTICE"))
	arg_6_0:rewardLayer(arg_6_0:nodeByName("award_container"))

	if not arg_6_0:checkIsMaster() then
		arg_6_0:nodeByName("btn_invite"):setVisible(false)
	end

	arg_6_0:setButtonClick()

	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.models) do
		table.insert(var_6_0, tonumber(iter_6_1))
	end

	arg_6_0:setMonster()
	arg_6_0:setMonsterStatus()
	arg_6_0:initRoom()
	arg_6_0:showChatWin()
	arg_6_0:updateRedMark(false)
end

function var_0_0.setMonster(arg_7_0)
	for iter_7_0 = 1, 3 do
		arg_7_0:nodeByName("monster" .. iter_7_0 .. "_defeated"):setVisible(false)

		local var_7_0 = tonumber(arg_7_0.models[iter_7_0])
		local var_7_1 = xyd.HeroAnimation.new(nil, var_7_0, 1, {})
		local var_7_2 = xyd.tables.model:uiScale(var_7_0)

		var_7_1:addTo(arg_7_0:nodeByName("monster" .. iter_7_0 .. "_container"), -1)
		var_7_1:setScale(var_7_2 * 0.8)
		var_7_1:idle(true)
	end
end

function var_0_0.setMonsterStatus(arg_8_0)
	for iter_8_0 = 1, 3 do
		if arg_8_0.adventureEvent.teamDefenseInfo.monster_statuses[iter_8_0] ~= "" then
			arg_8_0:nodeByName("monster" .. iter_8_0 .. "_defeated"):setVisible(true)
			arg_8_0:nodeByName("monster" .. iter_8_0 .. "_click"):setVisible(false)
			arg_8_0:nodeByName("killer_name" .. iter_8_0):setString(arg_8_0.adventureEvent.teamDefenseInfo.monster_statuses[iter_8_0])
		else
			arg_8_0:nodeByName("monster" .. iter_8_0 .. "_click"):setVisible(true)
			arg_8_0:nodeByName("monster" .. iter_8_0 .. "_defeated"):setVisible(false)
			arg_8_0:nodeByName("monster" .. iter_8_0 .. "_click"):setTouchEnabled(true)
			arg_8_0:nodeByName("monster" .. iter_8_0 .. "_click"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
				if arg_9_0.name == "began" then
					return true
				elseif arg_9_0.name == "ended" then
					local var_9_0 = {
						pos = iter_8_0
					}

					xyd.WindowManager.get():openWindow("adventure_defense_monster_detail", var_9_0)
				end
			end)
		end
	end

	if arg_8_0.adventureEvent:checkDefenseisFinish() then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_4:translation("ADVENTURE_MONSTER_TIP_3"), function()
			xyd.WindowManager.get():closeWindow(arg_8_0)
		end, nil, nil, arg_8_0.colorMode)
	end
end

function var_0_0.initRoom(arg_11_0)
	local var_11_0 = arg_11_0.adventureEvent:getDefensePlayerInfo(1)
	local var_11_1 = arg_11_0:nodeByName("room1")

	var_11_0.playerInfo = var_11_0

	xyd.setPlayerAvatar(var_11_1, var_11_0)

	for iter_11_0 = 2, 6 do
		local var_11_2 = arg_11_0.adventureEvent:getDefensePlayerInfo(iter_11_0)

		if not var_11_2 then
			arg_11_0:nodeByName("room_hole" .. iter_11_0):setVisible(true)
			arg_11_0:nodeByName("room_avatar" .. iter_11_0):removeAllChildren()
			arg_11_0:nodeByName("room_avatar" .. iter_11_0):setVisible(false)
		else
			arg_11_0:nodeByName("room_hole" .. iter_11_0):setVisible(false)
			arg_11_0:nodeByName("room_avatar" .. iter_11_0):removeAllChildren()
			arg_11_0:nodeByName("room_avatar" .. iter_11_0):setVisible(true)

			var_11_1 = arg_11_0:nodeByName("room_avatar" .. iter_11_0)

			local function var_11_3(arg_12_0)
				if arg_12_0.name == "began" then
					arg_11_0:nodeByName("room_avatar" .. iter_11_0):setScale(0.9)

					return true
				elseif arg_12_0.name == "ended" then
					arg_11_0:nodeByName("room_avatar" .. iter_11_0):setScale(1)

					local var_12_0 = {
						player_info = arg_11_0.adventureEvent:getDefensePlayerInfo(iter_11_0)
					}

					if var_12_0.player_info then
						local var_12_1 = xyd.WindowManager.get():openWindow("adventure_defense_player_info", var_12_0)
						local var_12_2, var_12_3 = var_11_1:getPosition()

						var_12_1:setPosition(cc.p(var_12_2, var_12_3 + 100))
					end
				end
			end

			if not arg_11_0:checkIsMaster() then
				var_11_2.playerInfo = var_11_2

				xyd.setPlayerAvatar(var_11_1, var_11_2)
			else
				var_11_2.callback = var_11_3

				xyd.setPlayerAvatar(var_11_1, var_11_2)
			end
		end
	end
end

function var_0_0.setButtonClick(arg_13_0)
	arg_13_0:nodeByName("btn_invite"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("adventure_defense_invite", {
				table_id = xyd.AdventureEventType.DEFENSE
			})
		end
	end)
	arg_13_0:nodeByName("img_chat"):setTouchEnabled(true)
	arg_13_0:nodeByName("img_chat"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			arg_13_0:nodeByName("img_chat"):setScale(0.9)

			return true
		elseif arg_15_0.name == "ended" then
			arg_13_0:nodeByName("img_chat"):setScale(1)
			arg_13_0:showChatWin()
			arg_13_0:updateRedMark(false)
		end
	end)
	arg_13_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_16_0 = {
				title_name = "ADVENTURE_MONSTER_RULES_TITLE",
				rule = "ADVENTURE_MONSTER_RULES_TEXT"
			}

			xyd.WindowManager.get():openWindow("text_rule", var_16_0)
		end
	end)
	arg_13_0:nodeByName("close"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_13_0:checkIsMaster() then
				arg_13_0.adventureEvent:clearDefenseTeamInfo()
				xyd.WindowManager.get():closeWindow(arg_13_0)
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("ILLUSION_TEAM_TIPS_8"), function()
					local var_18_0 = {
						table_id = xyd.AdventureEventType.DEFENSE
					}

					xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT):exitRoom(var_18_0, function(arg_19_0, arg_19_1)
						xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT):clearDefenseTeamInfo()

						local var_19_0 = xyd.WindowManager.get():getWindow("adventure_defense")

						if var_19_0 and not tolua.isnull(var_19_0) then
							xyd.WindowManager.get():closeWindow("adventure_defense")
						end
					end)
				end, nil, nil, arg_13_0.colorMode)
			end
		end
	end)
end

function var_0_0.checkIsMaster(arg_20_0)
	return arg_20_0.adventureEvent:checkIsDefenseMaster(arg_20_0.selfPlayer.playerID)
end

function var_0_0.showChatWin(arg_21_0)
	if arg_21_0.chatWinIsShow then
		arg_21_0.chatWinIsShow = false

		arg_21_0:playChatWinMove(arg_21_0.chatWinIsShow)

		return
	elseif arg_21_0.chatIsInit then
		arg_21_0.chatWinIsShow = true

		arg_21_0:playChatWinMove(arg_21_0.chatWinIsShow)

		return
	end

	local var_21_0 = arg_21_0:nodeByName("chat_container")

	var_21_0:setTouchSwallowEnabled(true)
	var_21_0:removeAllChildren()

	arg_21_0.chatWnd = arg_21_0.adventureEvent:getDefenseChatWindow("adventure_defense")

	arg_21_0.chatWnd:addTo(var_21_0)
	arg_21_0.chatWnd:setPosition(cc.p(0, 0))
	arg_21_0.chatWnd:setName("chat_wnd")
	var_21_0:setVisible(false)

	arg_21_0.chatIsInit = true
	arg_21_0.chatWinIsShow = false

	arg_21_0.chatWnd:updateList()
end

function var_0_0.updateRedMark(arg_22_0, arg_22_1)
	if arg_22_0.chatWinIsShow then
		arg_22_0:nodeByName("icon_8"):setVisible(false)
	else
		arg_22_0:nodeByName("icon_8"):setVisible(arg_22_1)
	end
end

function var_0_0.playChatWinMove(arg_23_0, arg_23_1)
	local var_23_0 = arg_23_0:nodeByName("chat_container")
	local var_23_1 = var_23_0:getContentSize()
	local var_23_2 = cc.p(arg_23_0:nodeByName("img_chat"):getPosition())

	if arg_23_1 then
		var_23_0:setPosition(cc.p(-var_23_1.width, 0))
		var_23_0:setVisible(true)
		transition.moveTo(var_23_0, {
			time = 0.3,
			x = 0,
			y = 0
		})
		transition.moveTo(arg_23_0:nodeByName("img_chat"), {
			time = 0.3,
			x = var_23_2.x + var_23_1.width,
			y = var_23_2.y
		})
	else
		transition.moveTo(var_23_0, {
			time = 0.3,
			y = 0,
			x = -var_23_1.width
		})
		transition.moveTo(arg_23_0:nodeByName("img_chat"), {
			time = 0.3,
			x = var_23_2.x - var_23_1.width,
			y = var_23_2.y
		})

		local var_23_3 = cc.Sequence:create({
			cc.DelayTime:create(0.3)
		})

		var_23_0:runActionOnce(var_23_3, false, function()
			var_23_0:setVisible(false)
		end)
	end
end

function var_0_0.rewardLayer(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_1:getContentSize().height
	local var_25_1 = var_25_0 / 8
	local var_25_2 = xyd.tables.gift:items(var_0_6:gift(arg_25_0.detail.room_info.campaign_id))

	if #var_25_2 == 1 and var_25_2[1] == 0 then
		var_25_2 = {}
	end

	local var_25_3 = #var_25_2

	for iter_25_0 = 1, #var_25_2 do
		if xyd.tables.item:type(var_25_2[iter_25_0]) ~= -1 then
			local var_25_4 = display.newNode()

			var_25_4:setContentSize(var_25_0, var_25_0)

			local var_25_5 = xyd.tables.item:type(var_25_2[iter_25_0])

			xyd.setItemBorder(var_25_4, var_25_2[iter_25_0], false, false)
			var_25_4:addTo(arg_25_1)
			var_25_4:setAnchorPoint(cc.p(0, 0))
			var_25_4:setPosition((iter_25_0 - 1) * (var_25_0 + var_25_1), 0)

			local var_25_6 = {
				id = var_25_2[iter_25_0],
				lev = xyd.tables.item:level(var_25_2[iter_25_0])
			}

			if xyd.tables.item:type(var_25_2[iter_25_0]) == -1 then
				var_25_6.tipsType = 0
				var_25_6.desc1 = xyd.tables.hero:getDes(var_25_2[iter_25_0])
			elseif specialItem then
				var_25_6.tipsType = 1
				var_25_6.id = -3
			else
				var_25_6.tipsType = 1
				var_25_6.desc1 = xyd.tables.item:desc1(var_25_2[iter_25_0])
				var_25_6.desc2 = xyd.tables.item:desc2(var_25_2[iter_25_0])
			end

			var_25_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_25_2[iter_25_0])
			var_25_6.name = xyd.tables.item:name(var_25_2[iter_25_0])

			arg_25_0:addTips(var_25_4, var_25_6)
		end
	end

	return arg_25_1
end

return var_0_0
