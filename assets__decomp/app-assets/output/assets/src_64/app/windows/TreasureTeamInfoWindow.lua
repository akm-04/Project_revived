local var_0_0 = class("TreasureTeamInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Treasure")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = import("app.model.Hero")
local var_0_5 = {
	adjust = {
		x_1 = 141,
		x_2 = 252
	},
	change = {
		x_1 = 622,
		x_2 = 520
	}
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.Effects = {}
	arg_1_0.Effects.gold = "skeletons/ui_effect/common_effect_gain_mana/common_effect_gain_mana"
	arg_1_0.Effects.drink = "skeletons/ui_effect/common_effect_gain_exp/common_effect_gain_exp"
	arg_1_0.Effects.stone = "skeletons/ui_effect/common_effect_gain_soulstone/common_effect_gain_soulstone"
	arg_1_0.Effects.dust = "skeletons/ui_effect/common_effect_powde/common_effect_powde"
	arg_1_0.Effects.liquid = "skeletons/ui_effect/common_effect_drugs/common_effect_drugs"
	arg_1_0.team_id = arg_1_2.team_id or 0
	arg_1_0.enemyName = arg_1_2.enemyName or ""
	arg_1_0.type = arg_1_2.type or 0
	arg_1_0.award = arg_1_2.award or 0
	arg_1_0.force = math.ceil(arg_1_2.force) or 0
	arg_1_0.partners = arg_1_2.partners or {}
	arg_1_0.isSelf = arg_1_2.isSelf
	arg_1_0.enemyTeam = arg_1_2.enemyTeam or {}
	arg_1_0.enemyStatus = arg_1_2.enemyStatus or {}
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.treasureModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE)
	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.heroesContainer = arg_1_0:nodeByName("heroes_container")

	arg_1_0:nodeByName("desc_1_txt"):setString(var_0_3:translation("TREASURE_TOTAL_INCOME"))
	arg_1_0:nodeByName("cost_num_txt"):setVisible(false)

	arg_1_0.awardNode = arg_1_0:nodeByName("award")
	arg_1_0.goldIcon = arg_1_0:nodeByName("gold")
	arg_1_0.drinkIcon = arg_1_0:nodeByName("drink")
	arg_1_0.stoneIcon = arg_1_0:nodeByName("stone")
	arg_1_0.dustIcon = arg_1_0:nodeByName("dust")
	arg_1_0.liquidIcon = arg_1_0:nodeByName("liquid")
	arg_1_0.robCostNode = arg_1_0:nodeByName("rob_cost")
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	if arg_1_0.isSelf then
		arg_1_0:nodeByName("team_info_title"):setString(string.format(var_0_3:translation("TREASURE_MY_TEAM_DESC"), xyd.tables.treasureName:name(arg_1_0.team_id)))
	else
		local var_1_0 = ""

		if arg_1_0.enemyName == "" then
			var_1_0 = var_0_3:translation("TREASURE_SHENMIREN")
		else
			var_1_0 = arg_1_0.enemyName
		end

		arg_1_0:nodeByName("team_info_title"):setString(string.format(var_0_3:translation("TREASURE_THEIR_TEAM_DESC"), var_1_0, xyd.tables.treasureName:name(arg_1_0.team_id)))
	end

	arg_1_0:nodeByName("team_info_title"):enableShadow(cc.c4b(5, 5, 5, 80), cc.size(1, -1), 1)
	arg_1_0:initEnemy()
	arg_1_0:initButton()
	arg_1_0:layout()
end

function var_0_0.didOpen(arg_2_0)
	var_0_0.super.didOpen()
	arg_2_0:addBlockLayer()
end

function var_0_0.addBlockLayer(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4)
	if arg_3_1 == nil then
		arg_3_1 = cc.c4b(0, 0, 0, 200)
	end

	arg_3_0.blockLayer_ = display.newColorLayer(arg_3_1)

	local var_3_0 = arg_3_0:convertToWorldSpace(cc.p(0, 0))

	arg_3_0.blockLayer_:pos(-var_3_0.x, -var_3_0.y):addTo(arg_3_0, -1)
	arg_3_0.blockLayer_:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)

	local function var_3_1(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended and not arg_3_3 and not arg_3_0.canNotClose then
			local var_4_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_4_0, false)
			xyd.WindowManager.get():closeWindow(arg_3_0.name)
		end

		return true
	end

	local function var_3_2(arg_5_0, arg_5_1)
		if not arg_3_3 and not arg_3_0.canNotClose then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			xyd.WindowManager.get():closeWindow(arg_3_0.name)
		end

		if arg_3_4 then
			arg_3_4()
		end
	end

	if not arg_3_2 then
		arg_3_0.layerListener = cc.EventListenerTouchOneByOne:create()

		arg_3_0.layerListener:setSwallowTouches(true)
		arg_3_0.layerListener:registerScriptHandler(var_3_1, cc.Handler.EVENT_TOUCH_BEGAN)
		arg_3_0.layerListener:registerScriptHandler(var_3_2, cc.Handler.EVENT_TOUCH_ENDED)
		arg_3_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_3_0.layerListener, arg_3_0.contentView_)
	end
end

function var_0_0.initEnemy(arg_6_0)
	arg_6_0.enemyHeroes = {}

	for iter_6_0, iter_6_1 in pairs(arg_6_0.enemyTeam) do
		local var_6_0 = clone(iter_6_1)

		var_6_0.partner_id = tonumber(var_6_0.partner_id) or iter_6_0

		if type(var_6_0.equips) == "string" then
			var_6_0.equips = xyd.splitToNumber(var_6_0.equips, "|")
		end

		if type(var_6_0.fumo_levels) == "string" then
			var_6_0.fumo_levels = xyd.splitToNumber(var_6_0.fumo_levels, "|")
		end

		if type(var_6_0.fumos) == "string" then
			var_6_0.fumos = xyd.splitToNumber(var_6_0.fumos, "|")
		end

		if type(var_6_0.skills) == "string" then
			var_6_0.skills = xyd.splitToNumber(var_6_0.skills, "|")
		end

		local var_6_1 = import("app.model.Hero").new()

		var_6_1:populate(var_6_0)

		var_6_1.healthStatus = arg_6_0.enemyStatus[tostring(var_6_0.partner_id)]

		table.insert(arg_6_0.enemyHeroes, var_6_1)
	end
end

function var_0_0.setParams(arg_7_0, arg_7_1)
	arg_7_0.team_id = arg_7_1.team_id or 0
	arg_7_0.type = arg_7_1.type or 0
	arg_7_0.award = arg_7_1.award or 0
	arg_7_0.force = math.ceil(arg_7_1.force) or 0
	arg_7_0.partners = arg_7_1.partners or {}
	arg_7_0.enemyTeam = arg_7_1.enemyTeam or {}
	arg_7_0.enemyStatus = arg_7_1.enemyStatus or {}
end

function var_0_0.layout(arg_8_0)
	arg_8_0:updateAward()

	local var_8_0 = {}

	if arg_8_0.isSelf then
		arg_8_0.robCostNode:setVisible(false)

		var_8_0 = arg_8_0.selfPlayer:getHerosByHeroIDs(arg_8_0.partners)
	else
		arg_8_0.robCostNode:setVisible(false)

		var_8_0 = arg_8_0.enemyHeroes
	end

	local var_8_1 = 0

	for iter_8_0, iter_8_1 in pairs(var_8_0) do
		var_8_1 = var_8_1 + iter_8_1:getZhandouli()
	end

	arg_8_0:nodeByName("force_txt"):setString(var_0_3:translation("TREASURE_TEAM_FORCE") .. var_8_1)

	for iter_8_2 = 1, 5 do
		local var_8_2 = arg_8_0.heroesContainer:getChildByName("icon_" .. iter_8_2)

		var_8_2:removeAllChildren()

		if var_8_0[iter_8_2] then
			local var_8_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")

			var_8_3:setPositionY(-23)
			xyd.setAvatarBorder(var_8_0[iter_8_2], var_8_3:getChildByName("avatar"))
			var_8_3:getChildByName("lv_txt"):setString(var_8_0[iter_8_2]:getLevel())

			for iter_8_3 = 1, 3 do
				var_8_3:getChildByName("team" .. iter_8_3):setVisible(false)
			end

			local var_8_4 = var_8_3:getChildByName("hp_bar")
			local var_8_5 = var_8_3:getChildByName("hp_di")
			local var_8_6 = var_8_3:getChildByName("mp_bar")
			local var_8_7 = var_8_3:getChildByName("mp_di")
			local var_8_8 = var_8_3:getChildByName("dead_text")

			var_8_8:setString(var_0_3:translation("ALREADY_DEAD"))

			local var_8_9 = var_8_3:getChildByName("avatar_mask")
			local var_8_10 = var_8_3:getChildByName("chosen")
			local var_8_11 = var_8_3:getChildByName("name_label_bg")
			local var_8_12 = var_8_3:getChildByName("name_text")

			var_8_4:setVisible(false)
			var_8_5:setVisible(false)
			var_8_6:setVisible(false)
			var_8_7:setVisible(false)
			var_8_8:setVisible(false)
			var_8_9:setVisible(false)
			var_8_10:setVisible(false)
			var_8_11:setVisible(false)
			var_8_12:setVisible(false)
			var_8_2:addChild(var_8_3)
		end
	end

	arg_8_0:updateBtn()
end

function var_0_0.initButton(arg_9_0)
	arg_9_0.btn_adjust = arg_9_0:nodeByName("node_adjust")
	arg_9_0.btn_getAward = arg_9_0:nodeByName("node_get")
	arg_9_0.btn_change = arg_9_0:nodeByName("node_change")
	arg_9_0.btn_rob = arg_9_0:nodeByName("node_rob")

	arg_9_0:nodeByName("Button_1_adjust"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_9_0.treasureModel.isDisabelAll then
			return
		end

		if arg_10_1 == ccui.TouchEventType.ended then
			if arg_9_0.award > 0 then
				xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
					string.format(var_0_3:translation("TREASURE_ADJUST_TEAM_TIPS"), xyd.tables.treasureName:name(arg_9_0.team_id), arg_9_0.award, xyd.tables.treasure:product(arg_9_0.type))
				}, function(arg_11_0)
					if arg_11_0 then
						arg_9_0:getCurrentAward()
					end
				end)
			else
				arg_9_0.guild:loadSentHeros(function(arg_12_0)
					if arg_12_0 == xyd.error.OK then
						arg_9_0.selfPlayer:loadUsedPartners(function(arg_13_0)
							if arg_12_0 == xyd.error.OK then
								local var_13_0 = {
									type = xyd.SelectTeamType.TREASURE_DEFENSE,
									campaignType = xyd.CampaignType.TREASURE,
									campaignID = xyd.MapBattleID.TREASURE[1],
									busyHeroList = arg_13_0,
									busyHeros = arg_9_0.treasureModel:getOtherTeamHeros(arg_9_0.team_id),
									selected = arg_9_0.treasureModel:getTeamHeros(arg_9_0.team_id),
									treasureType = arg_9_0.type,
									treasureTeamID = arg_9_0.team_id,
									preHeros = arg_9_0.selfPlayer:getHerosByHeroIDs(arg_9_0.partners)
								}

								xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_13_0)
							end
						end)
					end
				end)
			end
		end
	end)
	arg_9_0:nodeByName("Button_1_get"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_9_0.treasureModel.isDisabelAll then
			return
		end

		if arg_14_1 == ccui.TouchEventType.ended then
			arg_9_0:getCurrentAward()
		end
	end)
	arg_9_0:nodeByName("Button_1_change"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_9_0.treasureModel.isDisabelAll then
			return
		end

		if arg_15_1 == ccui.TouchEventType.ended then
			if xyd.tables.treasure:openTypeNum(arg_9_0.selfPlayer.lev) <= 1 then
				if xyd.WindowManager.get():getWindow("toast") ~= nil then
					xyd.WindowManager.get():closeWindow("toast")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("TREASURE_NO_OTHER_WORK")
				})
			elseif arg_9_0.award > 0 then
				xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
					string.format(var_0_3:translation("TREASURE_CHANGE_WORK_TIPS"), xyd.tables.treasureName:name(arg_9_0.team_id), xyd.tables.treasure:name(arg_9_0.type), arg_9_0.award, xyd.tables.treasure:product(arg_9_0.type))
				}, function(arg_16_0)
					if arg_16_0 then
						arg_9_0:getCurrentAward()
					end
				end)
			else
				xyd.WindowManager.get():getWindow("treasure_window"):updateAllBuildings(true, {
					currentType = arg_9_0.type,
					currentTeamID = arg_9_0.team_id
				})
				xyd.WindowManager.get():closeWindow(arg_9_0)
			end
		end
	end)
	arg_9_0:nodeByName("Button_2_rob"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_9_0.treasureModel.isDisabelAll then
			return
		end

		if arg_17_1 == ccui.TouchEventType.ended then
			if arg_9_0.selfPlayer.treasureSP >= xyd.tables.misc.treasureRootCost then
				local var_17_0 = {}

				arg_9_0.guild:loadAllTeamHeros(var_17_0, function(arg_18_0)
					if not arg_9_0 or tolua.isnull(arg_9_0) or not arg_9_0.guild then
						return
					end

					local var_18_0 = false
					local var_18_1 = {}

					if arg_18_0 == xyd.error.OK then
						var_18_0 = true

						for iter_18_0, iter_18_1 in ipairs(arg_9_0.guild:getAllTeamHeros()) do
							local var_18_2 = var_0_4.new()

							var_18_2:populate(iter_18_1)

							var_18_2.player_name = iter_18_1.player_name
							var_18_2.rent_need_mana = iter_18_1.rent_need_mana
							var_18_2.can_rent = iter_18_1.can_rent
							var_18_2.player_id = iter_18_1.player_id

							table.insert(var_18_1, var_18_2)
						end
					end

					local var_18_3 = {
						type = xyd.SelectTeamType.TREASURE,
						campaignType = xyd.CampaignType.TREASURE,
						campaignID = xyd.MapBattleID.TREASURE[arg_9_0.type],
						treasureType = arg_9_0.type,
						enemyHeroes = arg_9_0.enemyHeroes,
						isMercenary = var_18_0,
						allTeamHeros = var_18_1
					}

					xyd.WindowManager.get():closeWindow(arg_9_0)
					xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_18_3)
				end)
			elseif arg_9_0.selfPlayer.buyTreasureSPTimes < xyd.tables.vip:treasureNumSP(arg_9_0.selfPlayer.vip) then
				xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
					string.format(var_0_3:translation("TREASURE_LACK_SP_TIPS1"), xyd.tables.refreshCost:treasureBuySP(arg_9_0.selfPlayer.buyTreasureSPTimes + 1), xyd.tables.misc.treasureBuySPNum, arg_9_0.selfPlayer.buyTreasureSPTimes)
				}, function(arg_19_0)
					if arg_19_0 then
						if arg_9_0.selfPlayer.crystal >= xyd.tables.refreshCost:treasureBuySP(arg_9_0.selfPlayer.buyTreasureSPTimes + 1) then
							xyd.Backend.get():request(xyd.mid.TREASURE_BUY_SP, {}, function(arg_20_0)
								return
							end)
						else
							xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
								var_0_3:translation("ZUANSHI_ABSENCE")
							}, function(arg_21_0)
								if arg_21_0 then
									local var_21_0 = {}

									var_21_0.windowState = true

									xyd.WindowManager.get():openWindow("vip_recharge", var_21_0)
								end
							end)
						end
					end
				end)
			elseif arg_9_0.selfPlayer.vip < 15 then
				xyd.AlertWindow.open(xyd.AlertType.CONFIRM, {
					string.format(var_0_3:translation("TREASURE_LACK_SP_TIPS2"), arg_9_0.selfPlayer.buyTreasureSPTimes)
				})
			else
				xyd.AlertWindow.open(xyd.AlertType.CONFIRM, {
					string.format(var_0_3:translation("TREASURE_LACK_SP_TIPS3"), arg_9_0.selfPlayer.buyTreasureSPTimes)
				})
			end
		end
	end)
end

function var_0_0.updateBtn(arg_22_0)
	if not arg_22_0.isSelf then
		arg_22_0.btn_adjust:setVisible(false)
		arg_22_0.btn_getAward:setVisible(false)
		arg_22_0.btn_change:setVisible(false)
		arg_22_0.btn_rob:setVisible(true)
	elseif arg_22_0.award <= 0 then
		arg_22_0.btn_adjust:setVisible(true)
		arg_22_0.btn_getAward:setVisible(false)
		arg_22_0.btn_change:setVisible(true)
		arg_22_0.btn_rob:setVisible(false)
		arg_22_0.btn_adjust:setPositionX(var_0_5.adjust.x_2)
		arg_22_0.btn_change:setPositionX(var_0_5.change.x_2)
	else
		arg_22_0.btn_adjust:setVisible(true)
		arg_22_0.btn_getAward:setVisible(true)
		arg_22_0.btn_change:setVisible(true)
		arg_22_0.btn_rob:setVisible(false)
		arg_22_0.btn_adjust:setPositionX(var_0_5.adjust.x_1)
		arg_22_0.btn_change:setPositionX(var_0_5.change.x_1)
	end
end

function var_0_0.updateAward(arg_23_0)
	if arg_23_0.award < 0 then
		arg_23_0.awardNode:setVisible(false)
	else
		arg_23_0.awardNode:setVisible(true)
		arg_23_0.goldIcon:setVisible(false)
		arg_23_0.drinkIcon:setVisible(false)
		arg_23_0.stoneIcon:setVisible(false)
		arg_23_0.dustIcon:setVisible(false)
		arg_23_0.liquidIcon:setVisible(false)

		if arg_23_0.type == xyd.TreasureAwardType.Gold then
			arg_23_0.goldIcon:setVisible(true)
		elseif arg_23_0.type == xyd.TreasureAwardType.Drink then
			arg_23_0.drinkIcon:setVisible(true)
		elseif arg_23_0.type == xyd.TreasureAwardType.Stone then
			arg_23_0.stoneIcon:setVisible(true)
		elseif arg_23_0.type == xyd.TreasureAwardType.Dust then
			arg_23_0.dustIcon:setVisible(true)
		elseif arg_23_0.type == xyd.TreasureAwardType.Liquid then
			arg_23_0.liquidIcon:setVisible(true)
		end

		arg_23_0:nodeByName("award_num_txt"):setString("X " .. arg_23_0.award)
	end
end

function var_0_0.getCurrentAward(arg_24_0)
	xyd.Backend.get():request(xyd.mid.TREASURE_FINISH_ONE_TEAM, {
		team_id = arg_24_0.team_id
	}, function(arg_25_0)
		if arg_25_0 == xyd.error.OK then
			arg_24_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

			arg_24_0.selfPlayer:getMessagePush():registerNotification()

			arg_24_0.canNotClose = true

			local var_25_0 = ""

			if arg_24_0.type == xyd.TreasureAwardType.Gold then
				var_25_0 = arg_24_0.Effects.gold
			elseif arg_24_0.type == xyd.TreasureAwardType.Drink then
				var_25_0 = arg_24_0.Effects.drink
			elseif arg_24_0.type == xyd.TreasureAwardType.Stone then
				var_25_0 = arg_24_0.Effects.stone
			elseif arg_24_0.type == xyd.TreasureAwardType.Dust then
				var_25_0 = arg_24_0.Effects.dust
			elseif arg_24_0.type == xyd.TreasureAwardType.Liquid then
				var_25_0 = arg_24_0.Effects.liquid
			end

			local var_25_1 = var_25_0 .. ".json"
			local var_25_2 = var_25_0 .. ".atlas"
			local var_25_3 = var_0_2.new(var_25_1, var_25_2, 1)

			arg_24_0:nodeByName("btn_word_get"):setVisible(false)
			arg_24_0:nodeByName("Button_1_get"):setVisible(false)
			audio.playSound(xyd.tables.treasure:sound(arg_24_0.type), false)
			arg_24_0.btn_getAward:addChild(var_25_3)
			var_25_3:setVisible(true)
			var_25_3:setPosition(87, 32)
			var_25_3:play(function()
				var_25_3:setVisible(false)
				xyd.WindowManager.get():openWindow("alert_award", {
					awards = arg_24_0.treasureModel:getCurrentAwards()
				})

				local var_26_0 = xyd.WindowManager.get():getWindow("treasure_team_info")

				if var_26_0 ~= nil then
					var_26_0:updateInfoAfterFinish()
				end

				arg_24_0.canNotClose = false
			end, false)
		end
	end)
end

function var_0_0.updateInfoAfterFinish(arg_27_0)
	arg_27_0.award = 0

	arg_27_0:updateAward()
	arg_27_0:updateBtn()
end

return var_0_0
