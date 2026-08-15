local var_0_0 = class("AdventureDefenseMonsterDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Pet")
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.adventureEvent
local var_0_5 = xyd.tables.adventureDefense

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.pos = arg_1_2.pos
	arg_1_0.battleID = var_0_5:battleId(arg_1_0.adventureEvent.teamDefenseInfo.room_info.campaign_id)[arg_1_0.pos]
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.bgpos = arg_2_0:nodeByName("bg"):getPositionX()

	local var_2_0 = xyd.tables.battle:monsters(arg_2_0.battleID)

	arg_2_0.enemyHeroes = {}
	arg_2_0.herosB = {}

	for iter_2_0 = 1, #var_2_0 do
		local var_2_1 = {}

		for iter_2_1, iter_2_2 in ipairs(var_2_0[iter_2_0]) do
			local var_2_2 = var_0_2.new()

			var_2_2:populateWithTableID(iter_2_2)
			table.insert(var_2_1, var_2_2)
		end

		if #var_2_1 ~= 0 then
			table.insert(arg_2_0.herosB, var_2_1)
		end
	end

	arg_2_0.enemyHeroes = arg_2_0.herosB[1]

	arg_2_0:addBlockLayer()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:nodeByName("btn_chose"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			if arg_3_0.adventureEvent.teamDefenseInfo.pos_statuses[arg_3_0.pos].busy_type > 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("ADVENTURE_CHALLENGE_TIP")
				})
			elseif arg_3_0.adventureEvent.teamDefenseInfo.challenge_times[arg_3_0.pos] >= xyd.tables.misc.adventureDefenseChallengeTimesLimit then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("ADVENTURE_CHALLENGE_LIMIT")
				})
			elseif arg_3_0.adventureEvent.teamDefenseInfo.monster_statuses[arg_3_0.pos] ~= "" then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("ADVENTURE_MONSTER_DEFEATED")
				})
			else
				arg_3_0.adventureEvent:addChallengeTimes(arg_3_0.pos)
				arg_3_0.adventureEvent:prepareRoomFight({
					monster_pos = arg_3_0.pos,
					table_id = xyd.AdventureEventType.DEFENSE
				}, function(arg_5_0, arg_5_1)
					if arg_5_0 == xyd.error.OK then
						local var_5_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
						local var_5_1 = {
							campaign_type = xyd.CampaignType.ADVENTURE_DEFENSE
						}

						var_5_0:loadAllTeamHeros(var_5_1, function(arg_6_0)
							local var_6_0 = false
							local var_6_1 = {}
							local var_6_2 = false
							local var_6_3 = false

							if arg_6_0 == xyd.error.OK then
								var_6_0 = true

								for iter_6_0, iter_6_1 in ipairs(var_5_0:getAllTeamHeros()) do
									local var_6_4 = var_0_2.new()

									var_6_4:populate(iter_6_1)

									var_6_4.player_name = iter_6_1.player_name
									var_6_4.rent_need_mana = iter_6_1.rent_need_mana
									var_6_4.can_rent = iter_6_1.can_rent
									var_6_4.player_id = iter_6_1.player_id

									table.insert(var_6_1, var_6_4)

									if iter_6_1.color >= xyd.EquipQuality.PURPLE then
										local var_6_5 = true
									end
								end
							end

							for iter_6_2, iter_6_3 in pairs(arg_3_0.selfPlayer.heros_) do
								if iter_6_3.color_ >= xyd.EquipQuality.PURPLE then
									local var_6_6 = true

									break
								end
							end

							local var_6_7 = {
								type = xyd.SelectTeamType.ADVENTURE_DEFENSE,
								campaignType = xyd.CampaignType.ADVENTURE_DEFENSE,
								campaignID = arg_3_0.battleID,
								battleID = arg_3_0.battleID,
								isMercenary = var_6_0,
								allTeamHeros = var_6_1,
								monster_pos = arg_3_0.pos
							}

							xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_6_7)
							xyd.WindowManager.get():closeWindow(arg_3_0.name)
						end)
					end
				end)
			end
		end
	end)
	arg_3_0:nodeByName("btn_check"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_3_0.name)
		end
	end)
end

function var_0_0.didClose(arg_8_0, arg_8_1)
	var_0_0.super:didClose(arg_8_1)
end

function var_0_0.layout(arg_9_0)
	arg_9_0:nodeByName("challenge_bg"):setVisible(false)

	if arg_9_0.adventureEvent.teamDefenseInfo.pos_statuses[arg_9_0.pos].busy_type ~= 0 then
		arg_9_0:nodeByName("challenge_bg"):setVisible(true)
		arg_9_0:nodeByName("bg"):setPositionX(arg_9_0.bgpos - 117)

		local var_9_0 = arg_9_0.adventureEvent:getDefensePlayerInfoByID(arg_9_0.adventureEvent.teamDefenseInfo.pos_statuses[arg_9_0.pos].player_id)

		arg_9_0:nodeByName("text_name"):setString(var_9_0.player_name)

		var_9_0.playerInfo = var_9_0

		xyd.setPlayerAvatar(arg_9_0:nodeByName("avatar"), var_9_0)
	else
		arg_9_0:nodeByName("bg"):setPositionX(arg_9_0.bgpos)
	end

	arg_9_0:addHeroCells()
end

function var_0_0.addHeroCells(arg_10_0)
	arg_10_0:nodeByName("monster_container"):removeAllChildren()

	for iter_10_0, iter_10_1 in pairs(arg_10_0.enemyHeroes) do
		local var_10_0 = display.newNode()
		local var_10_1 = cc.p(90, 90)

		var_10_0:setContentSize(var_10_1)
		var_10_0:setPosition(cc.p(95 * (iter_10_0 - 1), 0))

		local var_10_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar3.csb")

		xyd.setAvatarBorder(iter_10_1, var_10_2:getChildByName("avatar"))

		local var_10_3 = xyd.getAvatarBorder(iter_10_1:getColor())

		xyd.displaySpriteOnContainer(var_10_3, var_10_2:getChildByName("border"), true)
		var_10_2:getChildByName("lv_txt"):setString(iter_10_1:getLevel())

		local var_10_4 = var_10_2:getChildByName("avatar_mask")

		var_10_4:setLocalZOrder(2)
		var_10_4:setVisible(false)

		local var_10_5 = var_10_2:getChildByName("dead_text")

		var_10_5:setString(var_0_3:translation("ALREADY_DEAD"))

		if var_10_5 then
			var_10_5:setVisible(false)
		end

		local var_10_6 = var_10_2:getChildByName("hp_bar")
		local var_10_7 = var_10_2:getChildByName("hp_di")

		var_10_6:setVisible(false)
		var_10_7:setVisible(false)
		var_10_0:addChild(var_10_2)
		arg_10_0:nodeByName("monster_container"):addChild(var_10_0)
	end
end

return var_0_0
