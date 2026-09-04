local var_0_0 = class("HunqiCampaignWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.spiritSuit
local var_0_3 = xyd.tables.spiritCampaign
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.common.ui.SpriteNodeButton")
local var_0_6 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.giftPush = xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.campaignType = xyd.CampaignType.HUNQI
	arg_1_0.response = arg_1_2
	arg_1_0.baseInfo = arg_1_0.response.base_info
	arg_1_0.campaignInfos = arg_1_0.response.campaign_infos
	arg_1_0.selfPlayer.spiritCampaignInfo = arg_1_0.baseInfo
	arg_1_0.day = arg_1_0.response.day
	arg_1_0.dayInfo = arg_1_0.response.day_info
	arg_1_0.layer = 1
	arg_1_0.btns = {}
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
	arg_2_0:setText()
	arg_2_0:setBtns()
	xyd.EventDispatcher.get():addEventListener(xyd.event.ECONOMY_AFTER, handler(arg_2_0, arg_2_0.updateTili))
	xyd.EventDispatcher.get():addEventListener(xyd.event.TICK_UPDATE, handler(arg_2_0, arg_2_0.updateTili))
end

function var_0_0.setText(arg_3_0)
	arg_3_0:nodeByName("text_tili"):setString(arg_3_0.selfPlayer:getSpiritEnergy() .. "/" .. xyd.tables.misc:getValue("spirit_energy_up_limit"))
	arg_3_0:nodeByName("text_title"):setString(var_0_1:translation("HUNQI_TEXT_19"))
	arg_3_0:nodeByName("text_skill"):setString(var_0_1:translation("HUNQI_TEXT_13"))
	arg_3_0:nodeByName("text_auto"):setString(var_0_1:translation("HUNQI_TEXT_14"))
	arg_3_0:nodeByName("text_start"):setString(var_0_1:translation("HUNQI_TEXT_15"))
	arg_3_0:nodeByName("text_skill"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_3_0:nodeByName("text_drop"):enableOutline(cc.c4b(71, 64, 97, 255), 2)
	arg_3_0:nodeByName("text_drop_item"):enableOutline(cc.c4b(125, 66, 66, 255), 2)
	arg_3_0:nodeByName("text_open_day"):enableOutline(cc.c4b(125, 66, 66, 255), 0)
end

function var_0_0.setBtns(arg_4_0)
	local var_4_0 = var_0_5.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_4_0:addTo(arg_4_0)
	var_4_0:setAnchorPoint(0.5, 0.5)
	var_4_0:setPosition(46, 694)
	var_4_0:setName("return_btn")

	arg_4_0.returnBtn = var_4_0

	arg_4_0.returnBtn:addTouchEvent(function(arg_5_0)
		if arg_5_0.name == "ended" then
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_6_0 = {}

			var_6_0.title_name = "SPIRIT_CAMPAIN_RULE_TITLE"
			var_6_0.rule = "SPIRIT_CAMPAIN_RULE_TEXT"

			xyd.WindowManager.get():openWindow("hunqi_campaign_rule", var_6_0)
		end
	end)
	arg_4_0:nodeByName("btn_start"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.backpack:getSpiritNum() >= xyd.tables.misc:getValue("spirit_num_limit") then
				local var_7_0 = var_0_1:translation("HUNQI_TEXT_36")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_0
				})

				return
			end

			if arg_4_0.selfPlayer:getSpiritEnergy() >= var_0_3:winCostNum(arg_4_0.campaignID) then
				local var_7_1 = {
					campaign_type = arg_4_0.campaignType
				}

				arg_4_0.guild:loadAllTeamHeros(var_7_1, function(arg_8_0)
					local var_8_0 = false
					local var_8_1 = {}

					if arg_8_0 == xyd.error.OK then
						var_8_0 = true

						local var_8_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

						for iter_8_0, iter_8_1 in ipairs(var_8_2:getAllTeamHeros()) do
							local var_8_3 = var_0_4.new()

							var_8_3:populate(iter_8_1)

							var_8_3.player_name = iter_8_1.player_name
							var_8_3.rent_need_mana = iter_8_1.rent_need_mana
							var_8_3.can_rent = iter_8_1.can_rent
							var_8_3.player_id = iter_8_1.player_id

							table.insert(var_8_1, var_8_3)
						end
					end

					local var_8_4 = xyd.SelectTeamType.HUNQI
					local var_8_5 = {
						type = var_8_4,
						campaignID = arg_4_0.campaignID,
						battleID = var_0_3:battle(arg_4_0.campaignID),
						campaignType = arg_4_0.campaignType,
						isMercenary = var_8_0,
						allTeamHeros = var_8_1
					}

					xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_8_5)
				end)
			else
				local var_7_2 = var_0_1:translation("HUNQI_TEXT_27")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_2
				})
			end
		end
	end)
	arg_4_0:nodeByName("btn_auto"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.baseInfo.auto_campaign ~= 0 then
				local var_9_0 = var_0_1:translation("HUNQI_TEXT_31")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_0
				})

				return
			end

			if arg_4_0.backpack:getSpiritNum() >= xyd.tables.misc:getValue("spirit_num_limit") then
				local var_9_1 = var_0_1:translation("HUNQI_TEXT_36")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_1
				})

				return
			end

			local var_9_2 = arg_4_0.selfPlayer:getSpiritEnergy()

			if arg_4_0.campaignInfos[tostring(arg_4_0.campaignID)].win_count == 0 then
				local var_9_3 = var_0_1:translation("HUNQI_TEXT_28")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_3
				})
			elseif var_9_2 < var_0_3:winCostNum(arg_4_0.campaignID) then
				local var_9_4 = var_0_1:translation("HUNQI_TEXT_27")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_4
				})
			else
				xyd.WindowManager.get():openWindow("hunqi_auto_fight", {
					campaignID = arg_4_0.campaignID
				})
			end
		end
	end)

	local var_4_1 = display.newNode()

	var_4_1:setTouchEnabled(true)
	var_4_1:setTouchSwallowEnabled(false)
	var_4_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			xyd.WindowManager.get():openWindow("hunqi_energy_tips"):setPosition(625, 435)

			return true
		elseif arg_10_0.name == "ended" then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow("hunqi_energy_tips")
		end
	end)
	var_4_1:setContentSize(arg_4_0:nodeByName("bg_tili"):getContentSize())
	var_4_1:addTo(arg_4_0:nodeByName("bg_tili"))
end

function var_0_0.layout(arg_11_0)
	local var_11_0 = var_0_3:dayNum(arg_11_0.day)

	for iter_11_0 = 1, var_11_0 do
		local var_11_1 = arg_11_0.day * 1000 + iter_11_0
		local var_11_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi_campaign/btn_layer.csb")

		var_11_2:getChildByName("text"):setString("No." .. iter_11_0 .. "F")
		var_11_2:getChildByName("btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
			if arg_12_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if arg_11_0.campaignInfos[tostring(var_11_1)].is_open ~= 0 then
					arg_11_0.btns[arg_11_0.layer]:setEnabled(true)
					arg_11_0.btns[arg_11_0.layer]:setBrightStyle(ccui.BrightStyle.normal)

					arg_11_0.layer = iter_11_0

					arg_11_0.btns[arg_11_0.layer]:setEnabled(false)
					arg_11_0.btns[arg_11_0.layer]:setBrightStyle(ccui.BrightStyle.highlight)
					arg_11_0:updateLayout()
				else
					local var_12_0 = var_0_3:level(var_11_1)

					if var_12_0 > arg_11_0.selfPlayer.lev then
						local var_12_1 = string.format(var_0_1:translation("HUNQI_TEXT_29"), var_12_0)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_12_1
						})
					else
						local var_12_2 = var_0_1:translation("HUNQI_TEXT_30")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_12_2
						})
					end
				end
			end
		end)
		table.insert(arg_11_0.btns, var_11_2:getChildByName("btn"))
		var_11_2:addTo(arg_11_0:nodeByName("list_btn"))
		var_11_2:setPosition(0, arg_11_0:nodeByName("list_btn"):getHeight() - iter_11_0 * 89 + 12)

		if arg_11_0.campaignInfos[tostring(var_11_1)].is_open ~= 0 then
			arg_11_0.layer = iter_11_0
		end
	end

	xyd.AssetLoader.get():loadSprite(var_0_3:title(arg_11_0.day * 1000 + 1)):addTo(arg_11_0:nodeByName("node_name"))
	arg_11_0.btns[arg_11_0.layer]:setEnabled(false)
	arg_11_0.btns[arg_11_0.layer]:setBrightStyle(ccui.BrightStyle.highlight)
	arg_11_0:initBoss()
	arg_11_0:updateLayout()
	arg_11_0:updateAutoFight()
end

function var_0_0.initBoss(arg_13_0)
	local var_13_0 = arg_13_0.day * 1000 + 1
	local var_13_1 = var_0_3:battle(var_13_0)
	local var_13_2 = var_0_3:scale(var_13_0)
	local var_13_3 = xyd.tables.battle:fight1(var_13_1)[1]
	local var_13_4 = xyd.tables.hero:modelID(var_13_3)
	local var_13_5 = xyd.HeroAnimation.new(var_13_3, var_13_4, var_13_2, {})

	if var_13_5 then
		var_13_5:idle()
	end

	var_13_5:addTo(arg_13_0:nodeByName("node_boss"))

	local var_13_6 = arg_13_0:nodeByName("container_skill"):getHeight()

	for iter_13_0 = 1, 4 do
		local var_13_7 = display.newNode()

		var_13_7:setContentSize(var_13_6, var_13_6)

		local var_13_8 = xyd.tables.hero:getSkill(var_13_3, iter_13_0)

		xyd.setSkillBorder(var_13_7, var_13_8, true)
		var_13_7:setTouchEnabled(true)
		var_13_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
			if arg_14_0.name == "began" then
				local var_14_0 = {
					has_jiantou = false,
					id = var_13_8
				}

				if not xyd.WindowManager.get():getWindow("skill_tips") then
					local var_14_1 = xyd.WindowManager.get():openWindow("skill_tips", var_14_0)

					xyd.adaptToWorldPosition(var_13_7, var_14_1)
				end

				return true
			elseif arg_14_0.name == "ended" then
				xyd.WindowManager.get():closeWindow("skill_tips")
			end
		end)
		var_13_7:addTo(arg_13_0:nodeByName("container_skill"))
		var_13_7:setPositionX((var_13_6 + 18) * (iter_13_0 - 1))
	end
end

function var_0_0.updateLayout(arg_15_0)
	arg_15_0.campaignID = arg_15_0.day * 1000 + arg_15_0.layer

	arg_15_0:nodeByName("text_open_day"):setString(var_0_3:desc(arg_15_0.campaignID))
	arg_15_0:nodeByName("text_cost"):setString(var_0_1:translation("MANA_COST") .. "         " .. var_0_3:winCostNum(arg_15_0.campaignID))

	local var_15_0 = arg_15_0:nodeByName("item_container")

	if not arg_15_0.list then
		arg_15_0.list = cc.ui.UIListView.new({
			touchOnContent = true,
			viewRect = cc.rect(0, 0, var_15_0:getContentSize().width + 20, var_15_0:getContentSize().height),
			direction = cc.ui.UIListView.DIRECTION_HORIZONTAL
		}):addTo(var_15_0)
	end

	if arg_15_0.campaignInfos[tostring(arg_15_0.campaignID)].win_count == 0 then
		arg_15_0:nodeByName("text_drop"):setString(var_0_1:translation("HUNQI_TEXT_12"))
		arg_15_0:nodeByName("item_container"):setVisible(true)
		arg_15_0:nodeByName("text_drop_item"):setVisible(false)

		local var_15_1 = var_0_3:initDisplay(arg_15_0.campaignID)

		arg_15_0:refreshList(var_15_1)
	else
		arg_15_0:nodeByName("text_drop"):setString(var_0_1:translation("HUNQI_TEXT_11"))

		if var_0_3:displayType(arg_15_0.campaignID) == 1 then
			arg_15_0:nodeByName("item_container"):setVisible(true)
			arg_15_0:nodeByName("text_drop_item"):setVisible(false)

			local var_15_2 = var_0_3:display(arg_15_0.campaignID)

			arg_15_0:refreshList(var_15_2)
		else
			arg_15_0:nodeByName("item_container"):setVisible(false)
			arg_15_0:nodeByName("text_drop_item"):setVisible(true)
			arg_15_0:nodeByName("text_drop_item"):setString(var_0_3:display(arg_15_0.campaignID))
		end
	end
end

function var_0_0.updateAutoFight(arg_16_0, arg_16_1)
	if arg_16_1 then
		arg_16_0.baseInfo = arg_16_1
		arg_16_0.selfPlayer.spiritCampaignInfo = arg_16_1
	end

	arg_16_0:nodeByName("text_auto_left"):setVisible(false)

	if arg_16_0.baseInfo.auto_campaign ~= 0 then
		if arg_16_0.handler then
			var_0_6.unscheduleGlobal(arg_16_0.handler)

			arg_16_0.handler = nil
		end

		arg_16_0.autoRewardLeftTime = arg_16_0.baseInfo.auto_times * xyd.tables.misc:getValue("spirit_auto_time") * 60 - (xyd.ServerTime.get():getServerTime() - arg_16_0.baseInfo.auto_start_time)

		if arg_16_0.autoRewardLeftTime > 0 then
			arg_16_0:nodeByName("text_auto_left"):setVisible(true)
			arg_16_0:nodeByName("text_auto_left"):setString(xyd.timeFormatAsHMS(arg_16_0.autoRewardLeftTime) .. var_0_1:translation("HUNQI_TEXT_32"))
		end

		arg_16_0.handler = var_0_6.scheduleGlobal(function()
			arg_16_0.autoRewardLeftTime = arg_16_0.autoRewardLeftTime - 1

			if arg_16_0.autoRewardLeftTime <= 0 then
				var_0_6.unscheduleGlobal(arg_16_0.handler)

				arg_16_0.handler = nil

				xyd.Backend.get():request(xyd.mid.HUNQI_GET_AUTO_AWRAD, {}, function(arg_18_0, arg_18_1)
					if arg_18_0 == xyd.error.OK then
						arg_16_0.selfPlayer:handleRewards(arg_18_1.awards, nil, arg_18_1.spirit_awards)

						arg_16_0.baseInfo = arg_18_1.base_info

						arg_16_0:nodeByName("text_auto_left"):setVisible(false)
					end
				end)
			else
				local var_17_0 = xyd.timeFormatAsHMS(arg_16_0.autoRewardLeftTime)

				arg_16_0:nodeByName("text_auto_left"):setString(var_17_0 .. var_0_1:translation("HUNQI_TEXT_32"))
			end
		end, 1)
	end
end

function var_0_0.updateTili(arg_19_0)
	if not arg_19_0 or tolua.isnull(arg_19_0) then
		return
	end

	local var_19_0 = arg_19_0:nodeByName("text_tili"):getString()
	local var_19_1 = arg_19_0.selfPlayer:getSpiritEnergy() .. "/" .. arg_19_0.selfPlayer:getSpiritEnergyLimit()

	if var_19_0 == var_19_1 then
		return
	end

	arg_19_0:nodeByName("text_tili"):setString(var_19_1)

	local var_19_2 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.5),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_19_3 = cc.Spawn:create(var_19_2)

	arg_19_0:nodeByName("text_tili"):runAction(var_19_3)
end

function var_0_0.willClose(arg_20_0)
	if arg_20_0.handler then
		var_0_6.unscheduleGlobal(arg_20_0.handler)

		arg_20_0.handler = nil
	end
end

function var_0_0.refreshList(arg_21_0, arg_21_1)
	arg_21_0.list:removeAllItems()

	for iter_21_0 = 1, #arg_21_1 do
		local var_21_0 = arg_21_0.list:newItem()
		local var_21_1 = display.newNode()
		local var_21_2 = 78

		var_21_1:setContentSize(var_21_2, var_21_2)

		if xyd.tables.item:type(arg_21_1[iter_21_0]) == xyd.ItemType.HUNQI then
			xyd.setItemBorder(var_21_1, arg_21_1[iter_21_0])
			var_21_1:setTouchEnabled(true)
			var_21_1:setTouchSwallowEnabled(false)

			local var_21_3

			var_21_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
				if arg_22_0.name == "began" then
					var_21_3 = arg_22_0.y

					if not xyd.WindowManager.get():getWindow("hunqi_detail") then
						local var_22_0 = {
							itemParams1 = {
								isSuit = true,
								suitID = xyd.tables.spiritEquip:from(arg_21_1[iter_21_0])
							}
						}
						local var_22_1 = xyd.WindowManager.get():openWindow("hunqi_detail", var_22_0)

						xyd.adaptToWorldPosition(var_21_1, var_22_1)
					end

					return true
				elseif arg_22_0.name == "moved" then
					local var_22_2 = arg_22_0.y

					if math.abs(var_22_2 - var_21_3) > 30 then
						xyd.WindowManager.get():closeWindow("hunqi_detail")
					end
				elseif arg_22_0.name == "ended" then
					xyd.WindowManager.get():closeWindow("hunqi_detail")
				end
			end)
		else
			xyd.setItemAndAddTips(var_21_1, arg_21_1[iter_21_0])
		end

		var_21_0:addContent(var_21_1)
		var_21_0:setItemSize(var_21_2 + 13, var_21_2)
		arg_21_0.list:addItem(var_21_0)
	end

	arg_21_0.list:reload()
end

return var_0_0
