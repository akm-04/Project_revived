local var_0_0 = class("AdventureIllusionWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("app.model.Hero")
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.adventureEvent
local var_0_6 = xyd.tables.illusionCampaign

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.eventId = arg_1_2.event_info.table_id
	arg_1_0.eventInfo = arg_1_2.event_info
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.monsterId = arg_1_0.eventInfo.special_data
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
	arg_3_0:startTimeCount(arg_3_0.eventId)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:nodeByName("btn_single"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("btn_single"):setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.moved then
			arg_4_0:nodeByName("btn_single"):setScale(1)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0:nodeByName("btn_single"):setScale(1)

			local var_5_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
			local var_5_1 = {
				campaign_type = xyd.CampaignType.ADVENTURE_ILLUSION_SINGLE
			}

			var_5_0:loadAllTeamHeros(var_5_1, function(arg_6_0)
				local var_6_0 = false
				local var_6_1 = {}
				local var_6_2 = false
				local var_6_3 = false

				if arg_6_0 == xyd.error.OK then
					var_6_0 = true

					for iter_6_0, iter_6_1 in ipairs(var_5_0:getAllTeamHeros()) do
						local var_6_4 = var_0_3.new()

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

				for iter_6_2, iter_6_3 in pairs(arg_4_0.selfPlayer.heros_) do
					if iter_6_3.color_ >= xyd.EquipQuality.PURPLE then
						local var_6_6 = true

						break
					end
				end

				local var_6_7 = {
					type = xyd.SelectTeamType.ADVENTURE_ILLUSION_SINGLE,
					campaignType = xyd.CampaignType.ADVENTURE_ILLUSION_SINGLE,
					campaignID = arg_4_0.monsterId,
					isMercenary = var_6_0,
					allTeamHeros = var_6_1
				}

				xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_6_7)
			end)
		end
	end)
	arg_4_0:nodeByName("btn_coop"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("btn_coop"):setScale(0.9)
		elseif arg_7_1 == ccui.TouchEventType.moved then
			arg_4_0:nodeByName("btn_coop"):setScale(1)
		elseif arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0:nodeByName("btn_coop"):setScale(1)

			local var_7_0 = {
				table_id = arg_4_0.eventId
			}

			arg_4_0.adventureEvent:createTeamRoom(var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					local var_8_0 = {
						table_id = arg_4_0.eventId
					}

					xyd.WindowManager.get():openWindow("adventure_illusion_prepare", var_8_0)
				end
			end)
		end
	end)
end

function var_0_0.didClose(arg_9_0, arg_9_1)
	var_0_0.super:didClose(arg_9_1)

	if arg_9_0.handle_ then
		var_0_1.unscheduleGlobal(arg_9_0.handle_)
	end
end

function var_0_0.layout(arg_10_0)
	local var_10_0 = var_0_6:modelId(arg_10_0.monsterId)
	local var_10_1 = xyd.HeroAnimation.new(nil, var_10_0, 1, {})

	var_10_1:addTo(arg_10_0:nodeByName("model_container"))
	var_10_1:setScale(0.8)
	var_10_1:idle(true)
	arg_10_0:nodeByName("monster_desc"):setString(var_0_6:campaignDes(arg_10_0.monsterId))

	local var_10_2 = arg_10_0:nodeByName("skill_container")
	local var_10_3 = var_0_6:skillId(arg_10_0.monsterId)
	local var_10_4 = var_10_2:getHeight()

	for iter_10_0, iter_10_1 in pairs(var_10_3) do
		local var_10_5 = display.newNode()

		var_10_5:setContentSize(var_10_4, var_10_4)

		local var_10_6 = xyd.tables.skill:icon(iter_10_1)
		local var_10_7 = xyd.SpriteLoader.new(var_10_6, nil, extra_params, xyd.DefaultImageType.SKILL_ICON)
		local var_10_8 = xyd.AssetLoader.get():loadSprite("windows/hero/skill_icon.png")

		var_10_8:setPosition(var_10_5:getWidth() / 2, var_10_5:getHeight() / 2)
		var_10_8:setAnchorPoint(cc.p(0.5, 0.5))
		var_10_8:scale(var_10_5:getWidth() / var_10_8:getWidth() / 20 * 19)

		stencil = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

		stencil:setPosition(var_10_5:getWidth() / 2, var_10_5:getHeight() / 2)
		stencil:setAnchorPoint(cc.p(0.5, 0.5))
		stencil:scale(var_10_5:getWidth() / stencil:getWidth())

		local var_10_9 = cc.ClippingNode:create()

		var_10_9:setStencil(stencil)
		var_10_9:setInverted(true)
		var_10_9:setAlphaThreshold(0)
		var_10_5:addChild(var_10_9)
		var_10_9:addChild(var_10_7)
		var_10_7:align(display.LEFT_BOTTOM, 0, 0)
		var_10_7:scale((var_10_5:getWidth() - 3) / var_10_7:getWidth())
		var_10_5:addTo(var_10_2)
		var_10_8:addTo(var_10_5)
		var_10_5:setPosition((iter_10_0 - 1) * (var_10_4 + 10) + 20, 0)

		local var_10_10 = {
			has_jiantou = false,
			id = iter_10_1
		}

		var_10_5:setTouchEnabled(true)
		var_10_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
			if arg_11_0.name == "began" then
				if not xyd.WindowManager.get():getWindow("skill_tips") then
					local var_11_0 = xyd.WindowManager.get():openWindow("skill_tips", var_10_10)

					xyd.adaptToWorldPosition(var_10_5, var_11_0)
				end

				return true
			elseif arg_11_0.name == "ended" then
				xyd.WindowManager.get():closeWindow("skill_tips")
			end
		end)
	end

	arg_10_0:rewardLayer(arg_10_0:nodeByName("single_award_container"), xyd.tables.misc.adventureIllusionSingleGift)
	arg_10_0:rewardLayer(arg_10_0:nodeByName("coop_award_container"), xyd.tables.misc.adventureIllusionCoopGift)
end

function var_0_0.rewardLayer(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_1:getContentSize().height
	local var_12_1 = var_12_0 / 4
	local var_12_2 = xyd.tables.gift:items(arg_12_2)

	if #var_12_2 == 1 and var_12_2[1] == 0 then
		var_12_2 = {}
	end

	local var_12_3 = #var_12_2

	for iter_12_0 = 1, #var_12_2 do
		if xyd.tables.item:type(var_12_2[iter_12_0]) ~= -1 then
			local var_12_4 = display.newNode()

			var_12_4:setContentSize(var_12_0, var_12_0)

			local var_12_5 = xyd.tables.item:type(var_12_2[iter_12_0])

			xyd.setItemBorder(var_12_4, var_12_2[iter_12_0], false, false)
			var_12_4:addTo(arg_12_1)
			var_12_4:setAnchorPoint(cc.p(0, 0))
			var_12_4:setPosition((iter_12_0 - 1) * (var_12_0 + var_12_1), 0)

			local var_12_6 = {
				id = var_12_2[iter_12_0],
				lev = xyd.tables.item:level(var_12_2[iter_12_0])
			}

			if xyd.tables.item:type(var_12_2[iter_12_0]) == -1 then
				var_12_6.tipsType = 0
				var_12_6.desc1 = xyd.tables.hero:getDes(var_12_2[iter_12_0])
			elseif specialItem then
				var_12_6.tipsType = 1
				var_12_6.id = -3
			else
				var_12_6.tipsType = 1
				var_12_6.desc1 = xyd.tables.item:desc1(var_12_2[iter_12_0])
				var_12_6.desc2 = xyd.tables.item:desc2(var_12_2[iter_12_0])
			end

			var_12_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_12_2[iter_12_0])
			var_12_6.name = xyd.tables.item:name(var_12_2[iter_12_0])

			arg_12_0:addTips(var_12_4, var_12_6)
		end
	end

	return arg_12_1
end

function var_0_0.startTimeCount(arg_13_0, arg_13_1)
	if arg_13_0.handle_ then
		var_0_1.unscheduleGlobal(arg_13_0.handle_)
	end

	local var_13_0 = arg_13_0.adventureEvent:getEndTime(arg_13_1) - xyd.ServerTime.get():getServerTime()

	if var_13_0 <= 0 then
		return
	end

	arg_13_0.handle_ = var_0_1.scheduleGlobal(function()
		var_13_0 = var_13_0 - 1

		if var_13_0 == 0 then
			if arg_13_0.handle_ then
				var_0_1.unscheduleGlobal(arg_13_0.handle_)

				arg_13_0.handle_ = nil
			end

			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_4:translation("ADVENTURE_END")
			})

			local var_14_0 = xyd.WindowManager.get():getWindow("adventure_illusion_prepare")

			if var_14_0 and not tolua.isnull(var_14_0) then
				local var_14_1 = {
					table_id = arg_13_1
				}

				arg_13_0.adventureEvent:exitRoom(var_14_1, function(arg_15_0, arg_15_1)
					if arg_15_0 == xyd.error.OK then
						xyd.WindowManager.get():closeWindow("adventure_illusion_prepare")
					end
				end)
			end

			local var_14_2 = xyd.WindowManager.get():getWindow("adventure_illusion_invite")

			if var_14_2 and not tolua.isnull(var_14_2) then
				xyd.WindowManager.get():closeWindow("adventure_illusion_invite")
			end

			local var_14_3 = xyd.WindowManager.get():getWindow("adventure_illusion_show_team")

			if var_14_3 and not tolua.isnull(var_14_3) then
				local var_14_4 = {
					table_id = arg_13_1
				}

				arg_13_0.adventureEvent:exitRoom(var_14_4, function(arg_16_0, arg_16_1)
					if arg_16_0 == xyd.error.OK then
						xyd.WindowManager.get():closeWindow("adventure_illusion_show_team")
					end
				end)
			end

			local var_14_5 = xyd.WindowManager.get():getWindow("adventure_illusion")

			if var_14_5 and not tolua.isnull(var_14_5) then
				xyd.WindowManager.get():closeWindow("adventure_illusion")
			end

			local var_14_6 = xyd.WindowManager.get():getWindow("alert")

			if var_14_6 and not tolua.isnull(var_14_6) then
				xyd.WindowManager.get():closeWindow("alert")
			end
		end
	end, 1)
end

return var_0_0
