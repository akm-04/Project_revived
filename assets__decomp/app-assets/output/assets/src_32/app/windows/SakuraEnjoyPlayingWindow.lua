local var_0_0 = class("SakuraEnjoyPlayingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "skeletons/ui_effect/activity_sakura2/yinghuaparticle_texture"
local var_0_2 = "skeletons/ui_effect/activity_sakura2/yinghua2particle_texture"
local var_0_3 = "skeletons/ui_effect/activity_sakura2/yinghua3"
local var_0_4 = "skeletons/ui_effect/activity_sakura2/yinghua4"
local var_0_5 = import("app.common.ui.SpineEffect")
local var_0_6 = import("framework.scheduler")
local var_0_7 = xyd.tables.translation
local var_0_8 = 40

SAKURA_EVENT_TYPE = {
	Companion = 1,
	Competitor = 2,
	GIRL = 3,
	None = 0
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.sakura = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.eventType = arg_1_2.event_type
	arg_1_0.isOver = arg_1_2.isOver or false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)

	if not arg_3_0.isOver then
		arg_3_0:handleEvent()
	elseif arg_3_0.sakura.awards then
		local function var_3_0()
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end

		arg_3_0.selfPlayer:handleRewards(arg_3_0.sakura.awards, var_3_0)

		arg_3_0.sakura.awards = nil

		arg_3_0:nodeByName("event_desc_txt"):setVisible(false)
	else
		arg_3_0:playFailed()
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("escape_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0.activitiesModel:getActivityReward2(xyd.Activities.Sakura, arg_5_0.eventType, 0, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					arg_5_0.sakura.details.event_type = arg_7_1.event_type

					arg_5_0:updateBthShow()
					arg_5_0:playFailed()
				end
			end)
		end
	end)
	arg_5_0:nodeByName("battle_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0:startBattle()
		end
	end)
	arg_5_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
	arg_5_0:nodeByName("close"):setVisible(false)

	arg_5_0.clippingNode = display.newClippingRegionNode()

	arg_5_0.clippingNode:setClippingRegion(cc.rect(0, 0, 1038, 358))
	arg_5_0.clippingNode:setAnchorPoint(cc.p(0, 0))
	arg_5_0.clippingNode:addTo(arg_5_0:nodeByName("material_container"))
	arg_5_0:addPartice(var_0_1, 300)
	arg_5_0:updateBthShow()
	arg_5_0:addCentreModels()
	arg_5_0:nodeByName("event_desc_txt"):setString(var_0_7:translation("SAKURA_EVENT_DES1"))
	arg_5_0:nodeByName("event_desc_txt"):enableOutline(arg_5_0.sakura.outlineColor, arg_5_0.sakura.outlineSize)
end

function var_0_0.updateBthShow(arg_10_0)
	arg_10_0:nodeByName("sure_btn"):setVisible(false)
	arg_10_0:nodeByName("escape_btn"):setVisible(false)
	arg_10_0:nodeByName("battle_btn"):setVisible(false)
end

function var_0_0.handleEvent(arg_11_0)
	if arg_11_0.eventType == SAKURA_EVENT_TYPE.Companion then
		arg_11_0:playCompanionEvent()
	elseif arg_11_0.eventType == SAKURA_EVENT_TYPE.Competitor then
		arg_11_0:playCompetitorEvent()
	elseif arg_11_0.eventType == SAKURA_EVENT_TYPE.GIRL then
		arg_11_0:playGetGirlEvent()
	end
end

function var_0_0.playCompanionEvent(arg_12_0)
	local var_12_0 = var_0_8
	local var_12_1 = xyd.tables.activitySakura2Case:getRandomModel(arg_12_0.eventType)
	local var_12_2 = xyd.HeroAnimation.new(nil, var_12_1, 0.5, {})

	var_12_2:addTo(arg_12_0.clippingNode)
	var_12_2:setPosition(cc.p(0, var_12_0))
	var_12_2:walk(true)

	local var_12_3 = cc.p(arg_12_0:nodeByName("material_container"):getContentSize().width / 3 + 20, var_12_0)

	var_12_2:runActionOnce(cc.Sequence:create({
		cc.MoveTo:create(3, var_12_3),
		cc.CallFunc:create(function()
			var_12_2:idle()
			arg_12_0:nodeByName("event_desc_txt"):setString(string.format(var_0_7:translation("SAKURA_EVENT_DES2"), xyd.tables.model:name(var_12_1)))
			arg_12_0.activitiesModel:getActivityReward(xyd.Activities.Sakura, arg_12_0.eventType, function(arg_14_0, arg_14_1)
				if arg_14_0 == xyd.error.OK then
					arg_12_0.sakura.details.event_type = arg_14_1.event_type

					local function var_14_0()
						xyd.WindowManager.get():closeWindow(arg_12_0)
					end

					var_0_6.performWithDelayGlobal(function()
						arg_12_0.isOver = true

						arg_12_0.selfPlayer:handleRewards(arg_14_1.awards, var_14_0)
					end, 1)
				end
			end)
		end)
	}))
end

function var_0_0.playCompetitorEvent(arg_17_0)
	local var_17_0 = var_0_8
	local var_17_1 = arg_17_0:nodeByName("material_container"):getContentSize().width
	local var_17_2 = xyd.tables.activitySakura2Case:getRandomModel(arg_17_0.eventType)

	arg_17_0.heroModel = xyd.HeroAnimation.new(nil, var_17_2, 0.5, {})

	arg_17_0.heroModel:addTo(arg_17_0.clippingNode)
	arg_17_0.heroModel:setPosition(cc.p(var_17_1, var_17_0))
	arg_17_0.heroModel:setFlipX(true)
	arg_17_0.heroModel:walk(true)

	local var_17_3 = cc.p(var_17_1 * 2 / 3 + 40, var_17_0)

	arg_17_0.heroModel:runActionOnce(cc.Sequence:create({
		cc.MoveTo:create(3, var_17_3),
		cc.CallFunc:create(function()
			arg_17_0.heroModel:idle()

			local var_18_0 = arg_17_0.sakura.details.competitor_info

			arg_17_0:nodeByName("event_desc_txt"):setString(string.format(var_0_7:translation("SAKURA_EVENT_DES3"), var_18_0.player_name))
			arg_17_0:nodeByName("escape_btn"):setVisible(true)
			arg_17_0:nodeByName("battle_btn"):setVisible(true)
		end)
	}))
end

function var_0_0.playGetGirl(arg_19_0)
	local var_19_0 = var_0_8
	local var_19_1 = arg_19_0:nodeByName("material_container"):getContentSize().width
	local var_19_2 = xyd.tables.activitySakura2Case:getRandomModel(arg_19_0.eventType)
	local var_19_3 = xyd.HeroAnimation.new(nil, var_19_2, 0.5, {})

	var_19_3:addTo(arg_19_0.clippingNode)
	var_19_3:setPosition(cc.p(var_19_1 / 2, var_19_0))
	var_19_3:setFlipX(true)
	var_19_3:idle()
	arg_19_0:nodeByName("event_desc_txt"):setString(string.format(var_0_7:translation("SAKURA_EVENT_DES6"), xyd.tables.model:name(var_19_2)))
	arg_19_0.activitiesModel:getActivityReward(xyd.Activities.Sakura, arg_19_0.eventType, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			local function var_20_0()
				xyd.WindowManager.get():closeWindow(arg_19_0)
			end

			arg_19_0.sakura.details.event_type = arg_20_1.event_type

			var_0_6.performWithDelayGlobal(function()
				arg_19_0.isOver = true

				if not arg_20_1.awards or not next(arg_20_1.awards) then
					var_20_0()

					return
				end

				arg_19_0.selfPlayer:handleRewards(arg_20_1.awards, var_20_0)
			end, 2)
		end
	end)
end

function var_0_0.startBattle(arg_23_0)
	local var_23_0 = arg_23_0.sakura.details.competitor_info
	local var_23_1 = {}

	if not var_23_0.heroes then
		return
	end

	for iter_23_0, iter_23_1 in pairs(var_23_0.heroes) do
		local var_23_2 = iter_23_1

		if type(var_23_2.equips) == "string" then
			var_23_2.equips = xyd.splitToNumber(var_23_2.equips, "|")
		end

		local var_23_3 = import("app.model.Hero").new()

		var_23_3:populate(var_23_2)
		table.insert(var_23_1, var_23_3)
	end

	local var_23_4 = var_23_0.pet
	local var_23_5

	if var_23_4 then
		if type(var_23_4.equips) == "string" then
			var_23_4.equips = xyd.splitToNumber(var_23_4.equips, "|")
		end

		local var_23_6 = import("app.model.Pet").new()

		var_23_6:populate(var_23_4)

		var_23_5 = var_23_6
	end

	local var_23_7 = {
		is_avenge = 0,
		showEnemy = true,
		type = xyd.SelectTeamType.SAKURA2_COMPETITOR,
		campaignType = xyd.CampaignType.SAKURA2_COMPETITOR,
		enemyHeroes = var_23_1,
		withRobot = var_23_0.is_robot,
		enemyPets = var_23_5
	}

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "sakura_enjoy_playing"
		}
	})
	xyd.WindowManager.get():retainHistory()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_23_0):addEventListener(xyd.event.WINDOW_DID_CLOSE, function(arg_24_0)
		if arg_24_0.windowName == "battle_select_team" and arg_23_0 and arg_23_0.sakura then
			arg_23_0.sakura:hideWindows()
		end
	end)
	xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_23_7)
end

function var_0_0.addCentreModels(arg_25_0)
	local var_25_0 = 120
	local var_25_1 = arg_25_0:nodeByName("material_container"):getContentSize().width
	local var_25_2 = xyd.tables.misc.activitySakura2SitModel[1]

	arg_25_0.heroModelLeft = xyd.HeroAnimation.new(nil, var_25_2, 0.5, {})

	arg_25_0.heroModelLeft:addTo(arg_25_0.clippingNode)
	arg_25_0.heroModelLeft:setPosition(cc.p(var_25_1 * 0.38, var_25_0))
	arg_25_0.heroModelLeft:playAnimation_("eat", true)

	local var_25_3 = xyd.tables.misc.activitySakura2SitModel[2]

	arg_25_0.heroModelRight = xyd.HeroAnimation.new(nil, var_25_3, 0.5, {})

	arg_25_0.heroModelRight:addTo(arg_25_0.clippingNode)
	arg_25_0.heroModelRight:setPosition(cc.p(var_25_1 * 0.65, var_25_0 + 20))
	arg_25_0.heroModelRight:playAnimation_("eat", true)
	arg_25_0.heroModelRight:setFlipX(true)
end

function var_0_0.playFailed(arg_26_0)
	arg_26_0:nodeByName("event_desc_txt"):setString(var_0_7:translation("SAKURA_EVENT_DES5"))

	local var_26_0 = 120
	local var_26_1 = cc.p(-100, var_26_0)

	arg_26_0.heroModelLeft:flipX(true)
	arg_26_0.heroModelLeft:walk(true)
	arg_26_0.heroModelLeft:runActionOnce(cc.Sequence:create({
		cc.MoveTo:create(3, var_26_1)
	}))

	local var_26_2 = cc.p(-100, var_26_0)

	arg_26_0.heroModelRight:flipX(true)
	arg_26_0.heroModelRight:walk(true)
	arg_26_0.heroModelRight:runActionOnce(cc.Sequence:create({
		cc.MoveTo:create(3.5, var_26_2),
		cc.CallFunc:create(function()
			arg_26_0.isOver = true

			arg_26_0:nodeByName("sure_btn"):setVisible(true)
		end)
	}))
end

function var_0_0.playGetGirlEvent(arg_28_0)
	var_0_6.performWithDelayGlobal(function()
		arg_28_0:playGetGirl()
	end, 1)
	arg_28_0:createSakuraEffect(var_0_3)
	arg_28_0:addPartice(var_0_2, 200)
end

function var_0_0.createSakuraEffect(arg_30_0, arg_30_1)
	effect = arg_30_0:createEffect(arg_30_1)

	effect:addTo(arg_30_0.clippingNode)

	local var_30_0 = arg_30_0:nodeByName("material_container"):getContentSize().width
	local var_30_1 = var_0_8 + 20

	effect:setPosition(cc.p(var_30_0 / 2, var_30_1))

	if arg_30_1 == var_0_4 then
		effect:play(function()
			return
		end, false)
	elseif arg_30_1 == var_0_3 then
		effect:play(function()
			effect:setVisible(false)
			arg_30_0:createSakuraEffect(var_0_4)
		end, false)
	else
		effect:play(nil, false)
	end
end

function var_0_0.createEffect(arg_33_0, arg_33_1)
	local var_33_0 = arg_33_1 .. ".json"
	local var_33_1 = arg_33_1 .. ".atlas"
	local var_33_2 = var_0_5.new(var_33_0, var_33_1, 1)

	var_33_2:setAnchorPoint(cc.p(0.5, 0.5))

	return var_33_2
end

function var_0_0.addPartice(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0 = cc.ParticleSystemQuad:create(arg_34_1 .. ".plist")

	var_34_0:addTo(arg_34_0.clippingNode)

	local var_34_1 = arg_34_0:nodeByName("material_container"):getContentSize().width
	local var_34_2 = var_0_8

	var_34_0:setPosition(cc.p(var_34_1 / 2, var_34_2 + arg_34_2))
end

return var_0_0
