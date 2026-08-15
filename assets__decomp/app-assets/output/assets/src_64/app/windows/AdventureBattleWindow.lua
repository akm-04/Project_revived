local var_0_0 = class("AdventureBattleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("app.model.Hero")
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.adventureEvent
local var_0_6 = {
	CAN_ADD = 1,
	IN_BLACK = 3,
	IN_FRIEND = 2,
	FULL_FRIEND = 4
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.eventId = arg_1_2.event_info.table_id
	arg_1_0.eventInfo = arg_1_2.event_info
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.enemyInfo = arg_1_0.eventInfo.detail.enemy_infos
	arg_1_0.enemyHeros = {}
end

function var_0_0.setupBackground(arg_2_0)
	if arg_2_0.bg then
		arg_2_0:removeChild(arg_2_0.bg, true)
	end

	arg_2_0.bg = xyd.AssetLoader.get():loadSprite(var_0_5:contentBg(tostring(arg_2_0.eventId)))

	arg_2_0.bg:setAnchorPoint(0, 0)
	arg_2_0.bg:setPosition(0, 0)
	arg_2_0.bg:setScale(cc.Director:getInstance():getOpenGLView():getFrameSize().width / arg_2_0.bg:getContentSize().width)
	arg_2_0.bg:addTo(arg_2_0, -100)
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)

	arg_3_0.heroesContainer = arg_3_0:nodeByName("panel_enemy")

	arg_3_0:startTimeCount(arg_3_0.eventId)

	if arg_3_0.enemyInfo and next(arg_3_0.enemyInfo) then
		arg_3_0:layout()
	end
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:nodeByName("btn_add_friend"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = arg_4_0:checkCanAddFriend(arg_4_0.eventInfo.special_data)

			if var_5_0 == var_0_6.CAN_ADD then
				local var_5_1 = {
					player_id = arg_4_0.eventInfo.special_data
				}

				arg_4_0.socialSystem:requestFriend(var_5_1, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_4:translation("SEND_FRIEND_APPLY_SUCCEED")
						})
						arg_4_0:nodeByName("btn_add_friend"):setTouchEnabled(false)
						arg_4_0:nodeByName("btn_add_friend"):setBright(false)
					elseif arg_4_0.enemyInfo.is_robot == 1 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_4:translation("SEND_FRIEND_APPLY_SUCCEED")
						})
						arg_4_0:nodeByName("btn_add_friend"):setTouchEnabled(false)
						arg_4_0:nodeByName("btn_add_friend"):setBright(false)
					end
				end)
			else
				local var_5_2
				local var_5_3 = arg_4_0.enemyInfo.player_name

				if var_5_0 == var_0_6.IN_FRIEND then
					var_5_2 = string.format(var_0_4:translation("SOMEONE_IN_FRIEND"), var_5_3)
				elseif var_5_0 == var_0_6.IN_BLACK then
					var_5_2 = string.format(var_0_4:translation("SOMEONE_IN_BLACK"), var_5_3)
				elseif var_5_0 == var_0_6.FULL_FRIEND then
					var_5_2 = var_0_4:translation("FRIEND_NUM_LIMIT_TIPS")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_5_2
				})
			end
		end
	end)
	arg_4_0:nodeByName("btn_challenge"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = {
				my_id = arg_4_0.selfPlayer.playerID,
				enemy_id = arg_4_0.enemyInfo.player_id or 0
			}
			local var_7_1 = {
				is_avenge = 0,
				showEnemy = true,
				type = xyd.SelectTeamType.ADVENTURE_BATTLE,
				campaignType = xyd.CampaignType.ARENA,
				fighterInfo = var_7_0,
				enemyHeroes = arg_4_0.enemyHeros,
				withRobot = arg_4_0.enemyInfo.is_robot,
				enemyPets = arg_4_0.enemyPets
			}

			xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_7_1)
		end
	end)
end

function var_0_0.checkCanAddFriend(arg_8_0, arg_8_1)
	if arg_8_0.socialSystem:isInFriendList(arg_8_1) then
		return var_0_6.IN_FRIEND
	elseif arg_8_0.socialSystem:isInBlackList(arg_8_1) then
		return var_0_6.IN_BLACK
	elseif #arg_8_0.socialSystem.friendlist >= xyd.tables.misc.maxFriendNum then
		return var_0_6.FULL_FRIEND
	else
		return var_0_6.CAN_ADD
	end
end

function var_0_0.didClose(arg_9_0, arg_9_1)
	var_0_0.super:didClose(arg_9_1)

	if arg_9_0.handle_ then
		var_0_1.unscheduleGlobal(arg_9_0.handle_)
	end
end

function var_0_0.layout(arg_10_0)
	arg_10_0:nodeByName("text"):setString(var_0_4:translation("ADVENTURE_CHALLENGE_MAIL_TEXT"))
	arg_10_0:nodeByName("text_name"):setString(arg_10_0.enemyInfo.player_name)

	local var_10_0 = arg_10_0.enemyInfo

	var_10_0.playerInfo = {
		player_id = arg_10_0.enemyInfo.player_id
	}

	xyd.setPlayerAvatar(arg_10_0:nodeByName("avatar"), var_10_0)
	arg_10_0:addHeroCells()
end

function var_0_0.addHeroCells(arg_11_0)
	arg_11_0.heroesContainer:removeAllChildren()

	if not arg_11_0.enemyInfo or not arg_11_0.enemyInfo.heroes or not next(arg_11_0.enemyInfo.heroes) then
		return
	end

	local var_11_0 = 1

	if arg_11_0.enemyInfo.pet then
		local var_11_1 = display.newNode()

		var_11_1:setContentSize(65, 65)

		local var_11_2 = var_0_2.new()

		var_11_2:populate(arg_11_0.enemyInfo.pet)

		arg_11_0.enemyPets = var_11_2

		xyd.setPetAvatar(var_11_1, var_11_2, nil, true)
		var_11_1:setScale(0.65, 0.65)
		var_11_1:setPosition(10, 10)
		arg_11_0.heroesContainer:addChild(var_11_1)

		var_11_0 = var_11_0 + 1

		for iter_11_0, iter_11_1 in pairs(arg_11_0.enemyInfo.heroes) do
			local var_11_3 = display.newNode()

			var_11_3:setContentSize(65, 65)
			var_11_3:setPosition(cc.p(70 * (var_11_0 - 1), 0))

			local var_11_4 = var_0_3.new()

			var_11_4:populate(iter_11_1)
			table.insert(arg_11_0.enemyHeros, var_11_4)
			xyd.setAvatarBorder(var_11_4, var_11_3)

			if iter_11_1.isLeader then
				local var_11_5 = xyd.AssetLoader.get():loadSprite("windows/arena/mode/lead_icon.png")

				var_11_5:addTo(var_11_3)
				var_11_5:setPosition(20, 50)
			end

			arg_11_0.heroesContainer:addChild(var_11_3)

			var_11_0 = var_11_0 + 1
		end
	else
		for iter_11_2, iter_11_3 in pairs(arg_11_0.enemyInfo.heroes) do
			local var_11_6 = display.newNode()

			var_11_6:setContentSize(80, 80)
			var_11_6:setPosition(cc.p(85 * (var_11_0 - 1), 0))

			local var_11_7 = var_0_3.new()

			var_11_7:populate(iter_11_3)
			table.insert(arg_11_0.enemyHeros, var_11_7)
			xyd.setAvatarBorder(var_11_7, var_11_6)

			if iter_11_3.isLeader then
				local var_11_8 = xyd.AssetLoader.get():loadSprite("windows/arena/mode/lead_icon.png")

				var_11_8:addTo(var_11_6)
				var_11_8:setPosition(20, 60)
			end

			arg_11_0.heroesContainer:addChild(var_11_6)

			var_11_0 = var_11_0 + 1
		end
	end
end

function var_0_0.startTimeCount(arg_12_0, arg_12_1)
	if arg_12_0.handle_ then
		var_0_1.unscheduleGlobal(arg_12_0.handle_)
	end

	local var_12_0 = arg_12_0.adventureEvent:getEndTime(arg_12_1) - xyd.ServerTime.get():getServerTime()

	if var_12_0 <= 0 then
		return
	end

	arg_12_0.handle_ = var_0_1.scheduleGlobal(function()
		var_12_0 = var_12_0 - 1

		if var_12_0 == 0 then
			if arg_12_0.handle_ then
				var_0_1.unscheduleGlobal(arg_12_0.handle_)

				arg_12_0.handle_ = nil
			end

			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_4:translation("ADVENTURE_END")
			})

			wnd = xyd.WindowManager.get():getWindow("adventure_battle")

			if wnd and not tolua.isnull(wnd) then
				xyd.WindowManager.get():closeWindow("adventure_battle")
			end

			wnd = xyd.WindowManager.get():getWindow(xyd.WindowName.SelectTeamWnd)

			if wnd and not tolua.isnull(wnd) then
				xyd.WindowManager.get():closeWindow(xyd.WindowName.SelectTeamWnd)
			end
		end
	end, 1)
end

return var_0_0
