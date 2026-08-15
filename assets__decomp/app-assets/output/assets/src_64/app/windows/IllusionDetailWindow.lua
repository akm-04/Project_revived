local var_0_0 = class("IllusionDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.illusionCampaign
local var_0_3 = xyd.tables.illusionAward
local var_0_4 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.modelId = arg_1_2.modelId
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.illusion = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)
	arg_1_0.id = arg_1_0.illusion.id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = xyd.HeroAnimation.new(nil, arg_3_0.modelId, 1, {})

	var_3_0:addTo(arg_3_0:nodeByName("model_container"))
	var_3_0:setScale(0.8)
	var_3_0:idle(true)
	xyd.nodeEventSample(arg_3_0:nodeByName("close_btn"), nil, function()
		local var_4_0 = xyd.tables.sound:getSound("ui_close_window")

		audio.playSound(var_4_0, false)
		xyd.WindowManager.get():closeWindow(arg_3_0)
	end)
	arg_3_0:nodeByName("introduce_concent"):setString(var_0_2:campaignDes(arg_3_0.id))
	arg_3_0:nodeByName("title"):setString(var_0_2:name(arg_3_0.id))

	local var_3_1 = arg_3_0:nodeByName("skill_container")
	local var_3_2 = var_0_2:skillId(arg_3_0.id)
	local var_3_3 = var_3_1:getHeight()

	for iter_3_0, iter_3_1 in pairs(var_3_2) do
		local var_3_4 = display.newNode()

		var_3_4:setContentSize(var_3_3, var_3_3)

		local var_3_5 = xyd.tables.skill:icon(iter_3_1)
		local var_3_6 = xyd.SpriteLoader.new(var_3_5, nil, nil, xyd.DefaultImageType.SKILL_ICON)
		local var_3_7 = xyd.AssetLoader.get():loadSprite("windows/hero/skill_icon.png")

		var_3_7:setPosition(var_3_4:getWidth() / 2, var_3_4:getHeight() / 2)
		var_3_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_3_7:scale(var_3_4:getWidth() / var_3_7:getWidth() / 20 * 19)

		local var_3_8 = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

		var_3_8:setPosition(var_3_4:getWidth() / 2, var_3_4:getHeight() / 2)
		var_3_8:setAnchorPoint(cc.p(0.5, 0.5))
		var_3_8:scale(var_3_4:getWidth() / var_3_8:getWidth())

		local var_3_9 = cc.ClippingNode:create()

		var_3_9:setStencil(var_3_8)
		var_3_9:setInverted(true)
		var_3_9:setAlphaThreshold(0)
		var_3_4:addChild(var_3_9)
		var_3_9:addChild(var_3_6)
		var_3_6:align(display.LEFT_BOTTOM, 0, 0)
		var_3_6:scale((var_3_4:getWidth() - 3) / var_3_6:getWidth())
		var_3_4:addTo(var_3_1)
		var_3_7:addTo(var_3_4)
		var_3_4:setPosition((iter_3_0 - 1) * (var_3_3 + 13), 0)

		local var_3_10 = {
			has_jiantou = false,
			id = iter_3_1
		}

		var_3_4:setTouchEnabled(true)
		var_3_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "began" then
				if not xyd.WindowManager.get():getWindow("skill_tips") then
					local var_5_0 = xyd.WindowManager.get():openWindow("skill_tips", var_3_10)

					xyd.adaptToWorldPosition(var_3_4, var_5_0)
				end

				return true
			elseif arg_5_0.name == "ended" then
				xyd.WindowManager.get():closeWindow("skill_tips")
			end
		end)
	end

	local var_3_11 = arg_3_0.illusion.rank

	if var_3_11 == nil or var_3_11 == 0 then
		arg_3_0:nodeByName("first_txt"):setString(var_0_1:translation("FIRST_CHALLENGE_WORLD_BOSS"))
		arg_3_0:nodeByName("fight_container"):setVisible(false)
	else
		arg_3_0:nodeByName("first_txt"):setVisible(false)
		arg_3_0:nodeByName("damage_txt"):setString(var_0_1:translation("PARADISE_THE_MOST_ATTACK"))
		arg_3_0:nodeByName("damage_num"):setString(math.floor(arg_3_0.illusion.damage))
		arg_3_0:nodeByName("rank_txt"):setString(var_0_1:translation("RANKING") .. var_0_1:translation("COLON"))
		arg_3_0:setRank(var_3_11, arg_3_0:nodeByName("rank_container"))
		arg_3_0:nodeByName("award_txt"):setString(var_0_1:translation("PARADISE_ATTACK_LEVEL_REWARD_DESC"))

		local var_3_12 = xyd.AssetLoader.get():loadNodeFromJson("windows/illusion/rule/illusion_rule_award.csb")

		var_3_12:addTo(arg_3_0:nodeByName("award_container"))
		var_3_12:setAnchorPoint(cc.p(0, 0))

		local var_3_13 = var_3_12:getChildByName("container")
		local var_3_14 = var_0_3:getID(var_3_11)

		var_3_13:getChildByName("IllusionCoin_icon"):getChildByName("IllusionCoin_num"):setString("x" .. var_0_3:illusionCoin(var_3_14))

		local var_3_15 = var_0_3:item(var_3_14)
		local var_3_16 = var_0_3:itemNum(var_3_14)

		if #var_3_15 == 0 or var_3_15[1] == 0 then
			var_3_13:getChildByName("item1"):setVisible(false)
			var_3_13:getChildByName("item2"):setVisible(false)
		elseif #var_3_15 == 1 then
			local var_3_17 = var_3_13:getChildByName("item1")

			var_3_17:getChildByName("item1_num"):setString("x" .. var_3_16[1])
			xyd.setItemBorder(var_3_17, var_3_15[1])
			var_3_13:getChildByName("item2"):setVisible(false)
		elseif #var_3_15 == 2 then
			local var_3_18 = var_3_13:getChildByName("item1")

			var_3_18:getChildByName("item1_num"):setString("x" .. var_3_16[1])
			xyd.setItemBorder(var_3_18, var_3_15[1])

			local var_3_19 = var_3_13:getChildByName("item2")

			var_3_19:getChildByName("item2_num"):setString("x" .. var_3_16[2])
			xyd.setItemBorder(var_3_19, var_3_15[2])
		end
	end

	arg_3_0:nodeByName("solo_txt"):setString(var_0_1:translation("PARADISE_TEXT_4"))
	xyd.nodeEventSample(arg_3_0:nodeByName("continue_btn"), nil, function()
		if arg_3_0.illusion.times < 1 then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("TRIAL_NO_TIMES_LEFT")
			})

			return
		end

		local var_6_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
		local var_6_1 = {
			campaign_type = xyd.CampaignType.ILLUSION
		}

		var_6_0:loadAllTeamHeros(var_6_1, function(arg_7_0)
			local var_7_0 = false
			local var_7_1 = {}
			local var_7_2 = false
			local var_7_3 = false

			if arg_7_0 == xyd.error.OK then
				var_7_0 = true

				for iter_7_0, iter_7_1 in ipairs(var_6_0:getAllTeamHeros()) do
					local var_7_4 = var_0_4.new()

					var_7_4:populate(iter_7_1)

					var_7_4.player_name = iter_7_1.player_name
					var_7_4.rent_need_mana = iter_7_1.rent_need_mana
					var_7_4.can_rent = iter_7_1.can_rent
					var_7_4.player_id = iter_7_1.player_id

					table.insert(var_7_1, var_7_4)

					if iter_7_1.color >= xyd.EquipQuality.PURPLE then
						local var_7_5 = true
					end
				end
			end

			for iter_7_2, iter_7_3 in pairs(arg_3_0.player.heros_) do
				if iter_7_3.color_ >= xyd.EquipQuality.PURPLE then
					local var_7_6 = true

					break
				end
			end

			local var_7_7 = {
				type = xyd.SelectTeamType.ILLUSION,
				campaignType = xyd.CampaignType.ILLUSION,
				campaignID = arg_3_0.id,
				isMercenary = var_7_0,
				allTeamHeros = var_7_1
			}

			xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_7_7)
		end)
	end)
	arg_3_0:nodeByName("cooperation_txt"):setString(var_0_1:translation("PARADISE_TEXT_3"))
	xyd.nodeEventSample(arg_3_0:nodeByName("btn_cooperation"), nil, function()
		arg_3_0.illusion:getRoomInfo(function(arg_9_0, arg_9_1)
			if arg_9_0 == xyd.error.OK and arg_9_1 and next(arg_9_1) then
				xyd.WindowManager.get():openWindow("illusion_prepare")

				return
			end

			xyd.WindowManager.get():openWindow("illusion_select_model")
		end)
	end)
end

function var_0_0.setRank(arg_10_0, arg_10_1, arg_10_2)
	arg_10_2:removeAllChildren()

	local var_10_0 = xyd.colorNumLabel(arg_10_1, "yellow1")

	var_10_0:setAnchorPoint(0, 0)
	var_10_0:addTo(arg_10_2)
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super:didOpen(arg_11_1)
	arg_11_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 150))
end

return var_0_0
