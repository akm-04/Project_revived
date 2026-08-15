local var_0_0 = class("BattleWinWindow", import("app.common.ui.BaseWindow"))
local var_0_1
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("app.model.Hero")
local var_0_4 = xyd.tables.translation
local var_0_5 = require("framework.scheduler")
local var_0_6 = {
	MERCENARY_HEROS = 2,
	SELF_HEROS = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.windowType_ = arg_1_2.type
	arg_1_0.star = arg_1_2.star or 0
	arg_1_0.campaignID = arg_1_2.campaignID or 0
	arg_1_0.campaignType = arg_1_2.campaignType
	arg_1_0.fighterA = arg_1_2.fighterA
	arg_1_0.fighterB = arg_1_2.fighterB
	arg_1_0.petA = arg_1_2.petA
	arg_1_0.petB = arg_1_2.petB
	arg_1_0.mana = arg_1_2.mana or 0
	arg_1_0.items = arg_1_2.items or {}
	arg_1_0.spiritItems = arg_1_2.spiritItems or {}
	arg_1_0.tutorCoin = arg_1_2.tutorCoin
	arg_1_0.heroExp = arg_1_2.heroExp or {}
	arg_1_0.data = arg_1_2.data or {}
	arg_1_0.favorDegreeUp = arg_1_2.favorDegreeUp
	arg_1_0.thisRecordNum = arg_1_2.thisRecordNum or 0
	arg_1_0.historyRecordNum = arg_1_2.historyRecordNum or 0
	arg_1_0.location = arg_1_2.location
	arg_1_0.allParams = arg_1_2.allParams
	arg_1_0.isAwakeSecond_ = arg_1_2.isAwakeSecond
	arg_1_0.starCrystal = arg_1_2.star_crystal
	arg_1_0.teamCells = {}

	if arg_1_0.location and arg_1_0.location == 0 then
		arg_1_0.fighterA = arg_1_2.fighterB
		arg_1_0.fighterB = arg_1_2.fighterA
		arg_1_0.petA = arg_1_2.petB
		arg_1_0.petB = arg_1_2.petA
	end

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.heroMaxLev = xyd.tables.player:heroMaxLev(arg_1_0.player_.lev)

	if arg_1_2.addExp then
		arg_1_0.ExpRes = arg_1_2.addExp
	elseif arg_1_0.campaignType ~= xyd.CampaignType.TUTOR then
		arg_1_0.groupExp_ = xyd.tables.campaign:energyCost(arg_1_0.campaignID)
	end

	if arg_1_0.campaignType == xyd.CampaignType.ALL_NIGHT_MAP then
		arg_1_0.groupExp_ = xyd.tables.allNightCampaign:winCost(arg_1_0.campaignID)
	end

	if arg_1_0.mana > 0 and arg_1_0.campaignType ~= xyd.CampaignType.GUILD and arg_1_0.campaignType ~= xyd.CampaignType.PET and arg_1_0.campaignType ~= xyd.CampaignType.NORMAL then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.ECONOMY,
			params = {
				mana = arg_1_0.player_.mana + arg_1_0.mana
			}
		})
	end

	arg_1_0.guildItems = arg_1_2.guildItems
	arg_1_0.actType = {}
	arg_1_0.actType[xyd.CampaignType.ARENA] = 1
	arg_1_0.actType[xyd.CampaignType.ARENA_MODE] = 1
	arg_1_0.actType[xyd.CampaignType.MARCH] = 1
	arg_1_0.actType[xyd.CampaignType.PET] = 1
	arg_1_0.actType[xyd.CampaignType.TREASURE] = 1
	arg_1_0.actType[xyd.CampaignType.SUPER_ARENA] = 1
	arg_1_0.actType[xyd.CampaignType.REGION_ARENA] = 1
	arg_1_0.actType[xyd.CampaignType.GUILD_ARENA] = 1
	arg_1_0.actType[xyd.CampaignType.PLAYOFFS] = 1
	arg_1_0.actType[xyd.CampaignType.PLAYOFFS_RECORD] = 1
	arg_1_0.actType[xyd.CampaignType.REGION_CASUAL] = 1
	arg_1_0.actType[xyd.CampaignType.FRIEND_FIGHT] = 1
	arg_1_0.actType[xyd.CampaignType.TWO_YEARS] = 1
	arg_1_0.actType[xyd.CampaignType.SNOW] = 1
	arg_1_0.actType[xyd.CampaignType.STUDENT_OVER] = 1
	arg_1_0.actType[xyd.CampaignType.GUILD] = 2
	arg_1_0.actType[xyd.CampaignType.INCUBUS] = 3
	arg_1_0.wndAction = {}
	arg_1_0.wndAction[0] = arg_1_0.starActions
	arg_1_0.wndAction[1] = arg_1_0.winActions
	arg_1_0.wndAction[2] = arg_1_0.battleFinishActions
	arg_1_0.wndAction[3] = arg_1_0.challengeFinishActions
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	arg_2_0.super.didOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer(cc.c4b(0, 0, 0, 150), true)
end

function var_0_0.layout(arg_3_0)
	arg_3_0._type = arg_3_0.actType[arg_3_0.campaignType] or 0

	if xyd.tables.campaign:campaignType(arg_3_0.campaignID) == 1 then
		arg_3_0._type = 1
	end

	arg_3_0.clipper = display.newClippingRectangleNode(cc.rect(0, 583, 1280, 137))

	arg_3_0.clipper:addTo(arg_3_0:nodeByName("effect_layer"))

	arg_3_0.lightEffect = xyd.createEffect("skeletons/ui_effect/battle_end/win_light")

	arg_3_0.lightEffect:addTo(arg_3_0.clipper)

	arg_3_0.smallStarEffect = xyd.createEffect("skeletons/ui_effect/battle_end/win_star")

	arg_3_0.smallStarEffect:addTo(arg_3_0:nodeByName("star_layer"))

	if arg_3_0.campaignType == xyd.CampaignType.RAGNAROK or xyd.CampaignType.FIFTH_ANNIVERSARY_BOSS then
		arg_3_0.lightEffect:setVisible(false)
		arg_3_0.smallStarEffect:setVisible(false)
	end

	arg_3_0.frameAction = {}

	arg_3_0.wndAction[arg_3_0._type](arg_3_0)

	arg_3_0.frame = 0
	arg_3_0.handler = var_0_5.scheduleGlobal(function()
		arg_3_0.frame = arg_3_0.frame + 1

		if arg_3_0.frameAction[arg_3_0.frame] then
			arg_3_0.frameAction[arg_3_0.frame](arg_3_0)
		end
	end, 0.01)

	if arg_3_0.frameAction[0] then
		arg_3_0.frameAction[0](arg_3_0)
	end

	arg_3_0.frameAction[64] = function()
		arg_3_0:nodeByName("btn_return"):setTouchEnabled(true)
		arg_3_0:nodeByName("btn_data"):setTouchEnabled(true)
		arg_3_0:nodeByName("btn_replay"):setTouchEnabled(true)
		var_0_5.unscheduleGlobal(arg_3_0.handler)
		arg_3_0:playGuide()
	end
	arg_3_0.showItems = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.items) do
		arg_3_0.showItems[iter_3_1:getTableID()] = (arg_3_0.showItems[iter_3_1:getTableID()] or 0) + 1
	end

	if table.nums(arg_3_0.showItems) > 0 then
		for iter_3_2, iter_3_3 in pairs(arg_3_0.showItems) do
			arg_3_0.player_:getBackpack():addItemsByID(iter_3_2, iter_3_3)
		end
	end

	arg_3_0.itemRecord_ = table.keys(arg_3_0.showItems)

	if arg_3_0.starCrystal then
		arg_3_0.showItems[-1] = arg_3_0.starCrystal

		table.insert(arg_3_0.itemRecord_, -1)
	end

	if arg_3_0.tutorCoin then
		arg_3_0.showItems[39] = arg_3_0.tutorCoin

		table.insert(arg_3_0.itemRecord_, 39)
	end

	for iter_3_4, iter_3_5 in ipairs(arg_3_0.spiritItems) do
		table.insert(arg_3_0.itemRecord_, iter_3_5)
		arg_3_0.player_:getBackpack():addSpiritItem(iter_3_5)
	end

	local var_3_0 = math.min(#arg_3_0.itemRecord_, 6)

	arg_3_0.actionItems = {}

	for iter_3_6 = var_3_0, 1, -1 do
		local var_3_1 = display.newNode()

		var_3_1:setContentSize(arg_3_0:nodeByName("item_scroll"):getHeight(), arg_3_0:nodeByName("item_scroll"):getHeight())

		if type(arg_3_0.itemRecord_[iter_3_6]) == "table" then
			xyd.setHunqiAndAddTips({
				container = var_3_1,
				item = arg_3_0.itemRecord_[iter_3_6]
			})
		else
			xyd.setItemBorder(var_3_1, arg_3_0.itemRecord_[iter_3_6], nil, nil, arg_3_0.showItems[arg_3_0.itemRecord_[iter_3_6]])

			local var_3_2 = {
				id = arg_3_0.itemRecord_[iter_3_6]
			}

			if xyd.tables.ecoType:getEcoPathByID(arg_3_0.itemRecord_[iter_3_6]) then
				-- block empty
			else
				xyd.addTips(var_3_1, var_3_2)
			end
		end

		var_3_1:setAnchorPoint(0.5, 0.5)
		var_3_1:pos(arg_3_0:nodeByName("item_scroll"):getPositionX(), arg_3_0:nodeByName("item_scroll"):getPositionY())
		var_3_1:setRotation(180)
		var_3_1:addTo(arg_3_0)
		var_3_1:setVisible(false)

		arg_3_0.actionItems[iter_3_6] = var_3_1
	end

	if (next(arg_3_0.items) or next(arg_3_0.spiritItems)) and #arg_3_0.itemRecord_ > 6 then
		local var_3_3

		if arg_3_0.campaignType == xyd.CampaignType.INCUBUS then
			var_3_3 = arg_3_0:nodeByName("unlimit_item_scroll")
		else
			var_3_3 = arg_3_0:nodeByName("item_scroll")
		end

		arg_3_0.touchList_ = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_3_3:getWidth(), var_3_3:getHeight()),
			direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(var_3_3):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

		arg_3_0.touchList_:align(display.LEFT_BOTTOM, 0, 0)
		arg_3_0.touchList_:setDelegate(handler(arg_3_0, arg_3_0.delegate))
		arg_3_0.touchList_:reload()
		arg_3_0.touchList_:setVisible(false)
		arg_3_0.touchList_:setViewCanNotScroll(true)
	end
end

function var_0_0.starActions(arg_6_0)
	arg_6_0.lightEffect:pos(640, 473)
	arg_6_0.lightEffect:play(function()
		arg_6_0.lightEffect:play(nil, true, nil, "texiao02")
	end, nil, nil, "texiao01")
	arg_6_0.smallStarEffect:pos(640, 553)
	arg_6_0.smallStarEffect:play(function()
		arg_6_0:nodeByName("star_title"):setLocalZOrder(10)
		arg_6_0.smallStarEffect:play(nil, true, nil, "texiao05")
	end, nil, nil, "texiao02")
	arg_6_0:initPetAndHeros()

	arg_6_0.frameAction[0] = arg_6_0.backgroundAction
	arg_6_0.frameAction[8] = arg_6_0.heroRun
	arg_6_0.frameAction[12] = arg_6_0.playStarAction
	arg_6_0.frameAction[26] = arg_6_0.wordBackShowUp
	arg_6_0.frameAction[29] = arg_6_0.rewardItemsAction
	arg_6_0.frameAction[55] = arg_6_0.btnShowUp
end

function var_0_0.winActions(arg_9_0)
	arg_9_0.lightEffect:pos(640, 473)
	arg_9_0.lightEffect:play(function()
		arg_9_0.lightEffect:play(nil, true, nil, "texiao02")
	end, nil, nil, "texiao01")
	arg_9_0.smallStarEffect:pos(640, 553)
	arg_9_0.smallStarEffect:play(function()
		arg_9_0:nodeByName("win"):setLocalZOrder(10)
		arg_9_0.smallStarEffect:play(nil, true, nil, "texiao05")
	end, nil, nil, "texiao01")
	arg_9_0:initPetAndHeros()

	arg_9_0.frameAction[0] = arg_9_0.backgroundAction
	arg_9_0.frameAction[8] = arg_9_0.heroRun
	arg_9_0.frameAction[14] = arg_9_0.playWinAction
	arg_9_0.frameAction[26] = arg_9_0.wordBackShowUp
	arg_9_0.frameAction[29] = arg_9_0.rewardItemsAction
	arg_9_0.frameAction[55] = arg_9_0.btnShowUp
end

function var_0_0.battleFinishActions(arg_12_0)
	arg_12_0.lightEffect:pos(640, 473)
	arg_12_0.lightEffect:play(function()
		arg_12_0.lightEffect:play(nil, true, nil, "texiao02")
	end, nil, nil, "texiao01")
	arg_12_0.smallStarEffect:pos(640, 535)
	arg_12_0.smallStarEffect:play(function()
		arg_12_0:nodeByName("win"):setLocalZOrder(10)
		arg_12_0.smallStarEffect:play(nil, true, nil, "texiao06")
	end, nil, nil, "texiao03")
	arg_12_0:nodeByName("back"):setContentSize(arg_12_0:nodeByName("back"):getWidth(), 326)
	arg_12_0:nodeByName("back_up"):runAction(cc.MoveBy:create(0, cc.p(0, -60)))
	arg_12_0:nodeByName("back_down"):runAction(cc.MoveBy:create(0, cc.p(0, 60)))
	arg_12_0:nodeByName("btn_data"):runAction(cc.MoveBy:create(0, cc.p(0, 50)))
	arg_12_0:nodeByName("btn_replay"):runAction(cc.MoveBy:create(0, cc.p(0, 50)))
	arg_12_0:nodeByName("btn_return"):runAction(cc.MoveBy:create(0, cc.p(0, 50)))

	arg_12_0.frameAction[0] = arg_12_0.backgroundAction
	arg_12_0.frameAction[16] = arg_12_0.playBattleFinishAction
	arg_12_0.frameAction[26] = arg_12_0.guildContainerShowUp
	arg_12_0.frameAction[55] = arg_12_0.btnShowUp
end

function var_0_0.challengeFinishActions(arg_15_0)
	arg_15_0.lightEffect:pos(640, 473)
	arg_15_0.lightEffect:play(function()
		arg_15_0.lightEffect:play(nil, true, nil, "texiao02")
	end, nil, nil, "texiao01")
	arg_15_0.smallStarEffect:pos(640, 503)
	arg_15_0.smallStarEffect:play(function()
		arg_15_0:nodeByName("win"):setLocalZOrder(10)
		arg_15_0.smallStarEffect:play(nil, true, nil, "texiao06")
	end, nil, nil, "texiao04")
	arg_15_0:nodeByName("back"):setContentSize(arg_15_0:nodeByName("back"):getWidth(), 326)
	arg_15_0:nodeByName("back_up"):runAction(cc.MoveBy:create(0, cc.p(0, -60)))
	arg_15_0:nodeByName("back_down"):runAction(cc.MoveBy:create(0, cc.p(0, 60)))
	arg_15_0:nodeByName("word_back"):runAction(cc.MoveBy:create(0, cc.p(0, -60)))
	arg_15_0:nodeByName("btn_data"):runAction(cc.MoveBy:create(0, cc.p(0, 50)))
	arg_15_0:nodeByName("btn_replay"):runAction(cc.MoveBy:create(0, cc.p(0, 50)))
	arg_15_0:nodeByName("btn_return"):runAction(cc.MoveBy:create(0, cc.p(0, 50)))

	arg_15_0.frameAction[0] = arg_15_0.backgroundAction
	arg_15_0.frameAction[16] = arg_15_0.playChallengeFinishAction
	arg_15_0.frameAction[26] = arg_15_0.wordBackShowUp
	arg_15_0.frameAction[55] = arg_15_0.btnShowUp
end

function var_0_0.backgroundAction(arg_18_0)
	arg_18_0:nodeByName("back"):setVisible(true)
	arg_18_0:nodeByName("back"):setScaleX(0)
	arg_18_0:nodeByName("back"):runAction(cc.ScaleTo:create(0.16, 1, 1))
	arg_18_0:nodeByName("back_up"):runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(-1080, 0)),
		cc.DelayTime:create(0.06),
		cc.CallFunc:create(function()
			arg_18_0:nodeByName("back_up"):setVisible(true)
		end),
		cc.MoveBy:create(0.26, cc.p(1080, 0))
	}))
	arg_18_0:nodeByName("back_down"):runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(1080, 0)),
		cc.DelayTime:create(0.06),
		cc.CallFunc:create(function()
			arg_18_0:nodeByName("back_down"):setVisible(true)
		end),
		cc.MoveBy:create(0.26, cc.p(-1080, 0))
	}))
end

function var_0_0.playStarAction(arg_21_0)
	for iter_21_0 = 1, arg_21_0.star do
		local var_21_0 = arg_21_0:nodeByName("star_title"):getChildByName(tostring(iter_21_0))

		var_21_0:runAction(cc.Sequence:create({
			cc.DelayTime:create(0.1 * (iter_21_0 - 1)),
			cc.RotateBy:create(0, 180),
			cc.CallFunc:create(function()
				var_21_0:setVisible(true)
				var_21_0:setScale(1.5)
			end),
			cc.Spawn:create({
				cc.ScaleTo:create(0.2, 1),
				cc.RotateBy:create(0.2, -180)
			}),
			cc.ScaleTo:create(0.1, 0.9),
			cc.ScaleTo:create(0.13, 1.1),
			cc.ScaleTo:create(0.2, 1),
			cc.CallFunc:create(function()
				audio.playSound(xyd.tables.sound:getSound("battle_star_" .. iter_21_0))
			end)
		}))
	end
end

function var_0_0.playWinAction(arg_24_0)
	for iter_24_0 = 1, 2 do
		local var_24_0 = arg_24_0:nodeByName("win"):getChildByName(tostring(iter_24_0))

		var_24_0:runAction(cc.Sequence:create({
			cc.DelayTime:create(iter_24_0 * 0.1 - 0.1),
			cc.CallFunc:create(function()
				var_24_0:setVisible(true)
				var_24_0:setOpacity(0)
				var_24_0:setScale(1.25)
			end),
			cc.FadeIn:create(0.06),
			cc.ScaleTo:create(0.1, 0.9),
			cc.ScaleTo:create(0.13, 1.1),
			cc.ScaleTo:create(0.2, 1)
		}))
	end
end

function var_0_0.playBattleFinishAction(arg_26_0)
	local var_26_0 = arg_26_0:nodeByName("battle_end")

	var_26_0:setScale(1.25)
	var_26_0:setVisible(true)
	var_26_0:runAction(cc.Sequence:create({
		cc.ScaleTo:create(0.1, 0.9),
		cc.ScaleTo:create(0.13, 1.1),
		cc.ScaleTo:create(0.2, 1)
	}))
end

function var_0_0.playChallengeFinishAction(arg_27_0)
	local var_27_0 = arg_27_0:nodeByName("challenge_end")

	var_27_0:setScale(1.25)
	var_27_0:setVisible(true)
	var_27_0:runAction(cc.Sequence:create({
		cc.ScaleTo:create(0.1, 0.9),
		cc.ScaleTo:create(0.13, 1.1),
		cc.ScaleTo:create(0.2, 1)
	}))
end

function var_0_0.wordBackShowUp(arg_28_0)
	arg_28_0:checkStudentExp()
	arg_28_0:nodeByName("txt_exp_tab"):setString(var_0_4:translation("BATTLE_WIN_EXP_TAB"))
	arg_28_0:nodeByName("txt_exp"):setString("+" .. (arg_28_0.ExpRes or arg_28_0.groupExp_ or 0))
	arg_28_0:nodeByName("txt_mana"):setString("+" .. arg_28_0.mana)
	arg_28_0:nodeByName("txt_lv"):setString(arg_28_0.player_.lev)
	arg_28_0:nodeByName("word_back"):setVisible(true)
	arg_28_0:nodeByName("word_back"):setOpacity(0)
	arg_28_0:nodeByName("word_back"):runAction(cc.FadeIn:create(0.26))
end

function var_0_0.checkStudentExp(arg_29_0)
	local var_29_0 = 0

	if not arg_29_0.groupExp_ then
		arg_29_0:nodeByName("txt_exp_student"):setString("")

		return
	end

	local var_29_1

	arg_29_0.groupExp_, var_29_1 = xyd.getStudentExp(arg_29_0.groupExp_, arg_29_0.player_:getExpMulti())

	if var_29_1 > 0 then
		arg_29_0:nodeByName("txt_exp_student"):setString(string.format("+%s", var_29_1))
		arg_29_0:nodeByName("txt_exp_student"):setPositionX(arg_29_0:nodeByName("txt_exp"):getPositionX() + arg_29_0:nodeByName("txt_exp"):getContentSize().width + 12)
	else
		arg_29_0:nodeByName("txt_exp_tab"):setPositionX(arg_29_0:nodeByName("txt_exp_tab"):getPositionX() + 16)
		arg_29_0:nodeByName("txt_exp"):setPositionX(arg_29_0:nodeByName("txt_exp"):getPositionX() + 16)
		arg_29_0:nodeByName("txt_exp_student"):setString("")
	end
end

function var_0_0.guildContainerShowUp(arg_30_0)
	arg_30_0:nodeByName("text_jindu"):setString(var_0_4:translation("BATTLE_WIN_JINDU"))
	arg_30_0:nodeByName("text_harm"):setString(var_0_4:translation("BATTLE_WIN_DAMAGE"))
	arg_30_0:nodeByName("label_guanjiajindu"):setString("+" .. string.format("%0.2f", arg_30_0.data.totalHarm / arg_30_0.data.totalHp * 100) .. "%")
	arg_30_0:nodeByName("label_total_harm"):setString(math.floor(arg_30_0.data.totalHarm))
	arg_30_0:nodeByName("bar"):setPercent((1 - arg_30_0.data.currentHp / arg_30_0.data.totalHp) * 100)
	arg_30_0:nodeByName("label_guild_mana"):setString(arg_30_0.mana)
	arg_30_0:nodeByName("bar"):y(arg_30_0:nodeByName("bar"):getY())

	if arg_30_0.guildItems and next(arg_30_0.guildItems) then
		local var_30_0 = var_0_4:translation("GUILD_AWARD_TITLE")
		local var_30_1 = var_0_4:translation("GUILD_AWARD_TOP")
		local var_30_2 = var_0_4:translation("GUILD_AWARD_BOTTOM")
		local var_30_3 = {
			var_30_0,
			var_30_1,
			var_30_2
		}

		xyd.WindowManager.get():openWindow("battle_award_items", {
			items = arg_30_0.guildItems,
			labels = var_30_3
		})
	end

	arg_30_0:nodeByName("guild_container"):setVisible(true)
	arg_30_0:nodeByName("guild_container"):setOpacity(0)
	arg_30_0:nodeByName("guild_container"):runAction(cc.FadeIn:create(0.26))
end

function var_0_0.rewardItemsAction(arg_31_0)
	if not arg_31_0.actionItems or not next(arg_31_0.actionItems) then
		return
	end

	for iter_31_0 = 1, #arg_31_0.actionItems do
		local var_31_0 = arg_31_0.actionItems[iter_31_0]

		var_31_0:setVisible(true)
		var_31_0:setTouchEnabled(false)
		var_31_0:runAction(cc.Sequence:create({
			cc.Spawn:create({
				cc.RotateBy:create(0.2, -180),
				cc.ScaleTo:create(0.2, 0.9)
			}),
			cc.ScaleTo:create(0.13, 1.1),
			cc.ScaleTo:create(0.23, 1),
			cc.MoveBy:create(0.3, cc.p((2 * iter_31_0 - 1 - #arg_31_0.actionItems) / 2 * (var_31_0:getWidth() + 28), 0)),
			cc.CallFunc:create(function()
				var_31_0:setTouchEnabled(true)

				if arg_31_0.touchList_ then
					var_31_0:removeSelf()
				end
			end)
		}))
	end

	if arg_31_0.touchList_ then
		local var_31_1 = arg_31_0.touchList_:getScrollNode()
		local var_31_2 = 0.2 * (#arg_31_0.itemRecord_ - 6)
		local var_31_3 = 118 * (#arg_31_0.itemRecord_ - 6)

		var_31_1:runAction(cc.Sequence:create({
			cc.DelayTime:create(0.87),
			cc.CallFunc:create(function()
				arg_31_0.touchList_:setVisible(true)
			end),
			cc.MoveBy:create(var_31_2, cc.p(-var_31_3, 0)),
			cc.CallFunc:create(function()
				arg_31_0.touchList_:setViewCanNotScroll(false)
			end)
		}))
	end
end

function var_0_0.btnShowUp(arg_35_0)
	arg_35_0:showDataButton()
	arg_35_0:showReplayButton()
	arg_35_0:showReturnButton()
end

function var_0_0.initPetAndHeros(arg_36_0)
	local var_36_0 = (arg_36_0.petA and #arg_36_0.petA or 0) + (arg_36_0.fighterA and #arg_36_0.fighterA or 0)
	local var_36_1 = var_36_0 * 180
	local var_36_2 = var_36_0 * 90 + 700
	local var_36_3 = 0

	arg_36_0:nodeByName("hero_pos"):runAction(cc.MoveBy:create(0, cc.p(-var_36_2, 0)))

	arg_36_0.teamCells = {}
	arg_36_0.teamPartners = {}

	if arg_36_0.petA then
		for iter_36_0, iter_36_1 in ipairs(arg_36_0.petA) do
			local var_36_4 = arg_36_0:createPartnerCell(iter_36_1)

			var_36_3 = var_36_3 + 1

			var_36_4:addTo(arg_36_0:nodeByName("hero_pos"))
			var_36_4:pos(var_36_3 * 180 - 90 - var_36_1 / 2, 0)
			table.insert(arg_36_0.teamCells, var_36_4)

			arg_36_0.teamPartners[var_36_3] = iter_36_1
		end
	end

	if arg_36_0.fighterA then
		for iter_36_2, iter_36_3 in ipairs(arg_36_0.fighterA) do
			local var_36_5 = arg_36_0:createPartnerCell(iter_36_3)

			var_36_3 = var_36_3 + 1

			var_36_5:addTo(arg_36_0:nodeByName("hero_pos"))
			var_36_5:pos(var_36_3 * 180 - 90 - var_36_1 / 2, 0)
			table.insert(arg_36_0.teamCells, var_36_5)

			arg_36_0.teamPartners[var_36_3] = iter_36_3
		end
	end
end

function var_0_0.heroRun(arg_37_0)
	local var_37_0 = (arg_37_0.petA and #arg_37_0.petA or 0) + (arg_37_0.fighterA and #arg_37_0.fighterA or 0)
	local var_37_1 = var_37_0 * 180
	local var_37_2 = var_37_0 * 90 + 700
	local var_37_3 = 0

	arg_37_0:nodeByName("hero_pos"):runAction(cc.Sequence:create({
		cc.CallFunc:create(function()
			arg_37_0:nodeByName("hero_pos"):setVisible(true)
		end),
		cc.MoveBy:create(0.4, cc.p(var_37_2, 0)),
		cc.CallFunc:create(function()
			for iter_39_0 = 1, #arg_37_0.teamCells do
				local var_39_0 = arg_37_0.teamCells[iter_39_0]:getChildByName("container")

				var_39_0:getChildByName("partner_pos"):getChildByName("hero"):win(false, function()
					var_39_0:getChildByName("partner_pos"):getChildByName("hero"):idle()
				end)
				var_39_0:getChildByName("star_pos"):setVisible(true)
				var_39_0:getChildByName("icon_pos"):setVisible(true)
				var_39_0:getChildByName("bar_bg"):setVisible(true)
				var_39_0:getChildByName("exp"):setVisible(true)
				arg_37_0:setProgress(arg_37_0.teamPartners[iter_39_0].hero_, var_39_0)
			end
		end)
	}))
end

function var_0_0.createPartnerCell(arg_41_0, arg_41_1)
	local var_41_0 = arg_41_1.hero_
	local var_41_1 = var_41_0:getHeroModel()

	var_41_1:setScale(0.7)

	local var_41_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle/battle_win/partner_item.csb")
	local var_41_3 = var_41_2:getChildByName("container")

	var_41_1:addTo(var_41_3:getChildByName("partner_pos"))
	var_41_1:setName("hero")
	var_41_1:walk(true)

	local var_41_4 = var_41_0:getStar()
	local var_41_5 = "windows/battle/battle_win/"

	if var_41_4 > 5 then
		var_41_4 = var_41_4 - 5
		var_41_5 = var_41_5 .. "small_super_star.png"
	else
		var_41_5 = var_41_5 .. "small_normal_star.png"
	end

	for iter_41_0 = 1, var_41_4 do
		local var_41_6 = 20
		local var_41_7 = xyd.AssetLoader.get():loadSprite(var_41_5)

		var_41_7:setAnchorPoint(0.5, 0.5)
		var_41_7:setPosition(((var_41_4 + 1) / 2 - iter_41_0) * var_41_6, 0)
		var_41_7:addTo(var_41_3:getChildByName("star_pos"))
	end

	if var_41_0.houseTableId and var_41_0.houseTableId > 0 then
		local var_41_8 = xyd.tables.dormHouse:maintype(houseTableId)
		local var_41_9 = var_41_0.houseExpandLev and var_41_0.houseExpandLev > 0

		if var_41_8 >= 1 then
			local var_41_10 = xyd.tables.dormHouseType:icon(var_41_8)

			if var_41_9 then
				var_41_10 = "images/dorm/choose/orange.png"
			end

			local var_41_11 = xyd.AssetLoader.get():loadSprite(var_41_10)

			var_41_11:setAnchorPoint(0.5, 0.5)
			var_41_11:addTo(var_41_3:getChildByName("icon_pos"))
		end
	end

	return var_41_2
end

function var_0_0.scrollListener(arg_42_0, arg_42_1)
	if arg_42_1.name == "began" then
		arg_42_0.scrollViewMoved_ = false
		arg_42_0.prevX_ = arg_42_1.x
	elseif arg_42_1.name == "moved" and 20 <= math.abs(arg_42_1.x - arg_42_0.prevX_) then
		arg_42_0.scrollViewMoved_ = true
	end
end

function var_0_0.showReturnButton(arg_43_0)
	arg_43_0.returnBtn_ = arg_43_0:nodeByName("btn_return")

	xyd.nodeEventSample(arg_43_0.returnBtn_, nil, function(arg_44_0)
		xyd.playButtonSound()

		if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_CAMPAIGN_RESULT then
			arg_43_0.player_:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_END)
		end

		arg_43_0:dispatchEvent({
			name = xyd.event.BATTLE_END_BACK_TO_MAIN
		})
	end)
	arg_43_0.returnBtn_:setTouchEnabled(false)
	arg_43_0.returnBtn_:setVisible(true)
	arg_43_0.returnBtn_:setOpacity(0)
	arg_43_0.returnBtn_:runAction(cc.FadeIn:create(0.3))
end

function var_0_0.showDataButton(arg_45_0)
	if arg_45_0.campaignType == xyd.CampaignType.SUMMER_FIGHT_BOSS or arg_45_0.campaignType == xyd.CampaignType.SNOW then
		return
	end

	arg_45_0.dataBtn_ = arg_45_0:nodeByName("btn_data")

	xyd.nodeEventSample(arg_45_0.dataBtn_, nil, function(arg_46_0)
		xyd.playButtonSound()
		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, {
			herosA = arg_45_0.fighterA,
			herosB = arg_45_0.fighterB,
			petA = arg_45_0.petA,
			petB = arg_45_0.petB,
			campaignID = arg_45_0.campaignID,
			campaignType = arg_45_0.campaignType
		})
	end)
	arg_45_0.dataBtn_:setTouchEnabled(false)
	arg_45_0.dataBtn_:setVisible(true)
	arg_45_0.dataBtn_:setOpacity(0)
	arg_45_0.dataBtn_:runAction(cc.FadeIn:create(0.3))
end

function var_0_0.showReplayButton(arg_47_0)
	if not arg_47_0.allParams or arg_47_0.allParams.peak_fight_first or arg_47_0.allParams.campaignType == xyd.CampaignType.REGION_CASUAL or arg_47_0.campaignType == xyd.CampaignType.SNOW then
		return
	end

	if not arg_47_0.allParams.battleType or arg_47_0.allParams.battleType ~= xyd.BattleType.ReplayReport then
		return
	end

	arg_47_0.replayBtn_ = arg_47_0:nodeByName("btn_replay")

	xyd.nodeEventSample(arg_47_0.replayBtn_, nil, function(arg_48_0)
		xyd.playButtonSound()

		local var_48_0 = arg_47_0.allParams

		if arg_47_0.allParams.campaignType ~= xyd.CampaignType.FRIEND_FIGHT then
			arg_47_0:dispatchEvent({
				name = xyd.event.BATTLE_END_BACK_TO_MAIN
			})
		else
			arg_47_0:dispatchEvent({
				name = xyd.event.BATTLE_END_WATCH_REGION_REPLAY
			})
		end

		xyd.pushBattleScene(var_48_0)
	end)
	arg_47_0.replayBtn_:setTouchEnabled(false)
	arg_47_0.replayBtn_:setVisible(true)
	arg_47_0.replayBtn_:setOpacity(0)
	arg_47_0.replayBtn_:runAction(cc.FadeIn:create(0.3))
end

function var_0_0.willClose(arg_49_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.HERO_EQUIP_UPDATE
	})
end

function var_0_0.didClose(arg_50_0)
	if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_EQUIP_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_START)
		xyd.StoryData.get():persist()
	end

	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_EQUIP_START then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.GUIDE_EQUIP_START
			}
		})
	elseif xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_TWO then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_TWO
			}
		})
	end
end

function var_0_0.playStarEffect(arg_51_0, arg_51_1)
	arg_51_1 = arg_51_1 or 1

	local var_51_0 = arg_51_0:getStarTitle(arg_51_1)
	local var_51_1 = cc.Spawn:create(cc.ScaleTo:create(0.5, 1), cc.RotateBy:create(0.5, 360))

	transition.newEasing(var_51_1, "ELASTICIN")
	var_51_0:runActionOnce(var_51_1, false, function()
		if arg_51_1 < arg_51_0.star then
			arg_51_0:playStarEffect(arg_51_1 + 1)
		end

		audio.playSound(xyd.tables.sound:getSound("battle_star_" .. arg_51_1))
	end)
end

function var_0_0.buttonHandler(arg_53_0, arg_53_1, arg_53_2, arg_53_3)
	if arg_53_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_53_2)
		arg_53_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound(xyd.tables.sound:getSound("ui_button_click"), false)

		if arg_53_1 then
			arg_53_1(arg_53_2, arg_53_3)
		end
	elseif arg_53_3 == ccui.TouchEventType.began then
		local var_53_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_53_1 = cc.RepeatForever:create(var_53_0)

		arg_53_2:runAction(var_53_1)

		return true
	elseif arg_53_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_53_2)
		arg_53_2:setScale(1)
	end
end

function var_0_0.setIDBeforeGuideWnd(arg_54_0)
	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_ONE)
	end
end

function var_0_0.setIDAfterGuideWnd(arg_55_0)
	local var_55_0 = xyd.StoryData.get():getGuideID()

	if var_55_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_SEVEN then
		arg_55_0.player_:sendOperationLog(xyd.StatID.ID_FIGHT_2_7)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_END)
		xyd.StoryData.get():persist()
	elseif var_55_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_END then
		arg_55_0.player_:sendOperationLog(xyd.StatID.ID_FIGHT_3_6)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_START)
		xyd.StoryData.get():persist()
	elseif var_55_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_ONE then
		arg_55_0.player_:sendOperationLog(xyd.StatID.ID_JINJIE_2)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_TWO)
		xyd.StoryData.get():persist()
	end
end

function var_0_0.checkGuideReturn(arg_56_0)
	local var_56_0 = xyd.StoryData.get():getGuideID()

	if var_56_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_RESULT or var_56_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_SEVEN or var_56_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_END or var_56_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_START then
		return true
	end

	return false
end

function var_0_0.playGuide(arg_57_0)
	if xyd.WindowManager.get():isWindowOpen("levelup") then
		return
	end

	local var_57_0 = xyd.StoryData.get():getGuideID()

	if arg_57_0:checkGuideReturn() then
		arg_57_0:setIDBeforeGuideWnd()

		local var_57_1 = arg_57_0:nodeByName("btn_return")

		xyd.showGuideWnd(var_57_1, nil, nil, 2, {
			850,
			250
		}, false, nil, true)
		arg_57_0:setIDAfterGuideWnd()
	elseif var_57_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_END then
		if xyd.WindowManager.get():isWindowOpen("guide_only_dialog") then
			xyd.WindowManager.get():closeWindow("guide_only_dialog")
		end

		local var_57_2 = {
			tipPosition = cc.p(700, 150),
			callback = function()
				arg_57_0:playGuide()
			end
		}

		arg_57_0.player_:sendOperationLog(xyd.StatID.ID_JINJIE_1)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_START)
		xyd.StoryData.get():persist()

		local var_57_3 = xyd.WindowManager.get():openWindow("guide_only_dialog", var_57_2)
	end
end

function var_0_0.getPlusType(arg_59_0, arg_59_1)
	local var_59_0 = {}

	for iter_59_0, iter_59_1 in pairs(arg_59_0.player_.heros_) do
		if iter_59_1:getItemHeroHasNotEquip(arg_59_1) then
			local var_59_1 = {}

			if xyd.tables.item:level(arg_59_1) > iter_59_1:getLevel() then
				var_59_1 = {
					plusType = 0,
					hero = iter_59_1
				}
			else
				var_59_1 = {
					plusType = 1,
					hero = iter_59_1
				}
			end

			table.insert(var_59_0, var_59_1)
		end
	end

	return var_59_0
end

function var_0_0.setProgress(arg_60_0, arg_60_1, arg_60_2)
	local var_60_0 = 0.6
	local var_60_1 = xyd.AssetLoader.get():loadSprite("windows/battle/battle_win/exp_bar1.png")
	local var_60_2 = display.newProgressTimer(var_60_1, display.PROGRESS_TIMER_BAR):align(display.CENTER, 0, 0):addTo(arg_60_2:getChildByName("bar_pos"))
	local var_60_3 = arg_60_2:getChildByName("red_bar")
	local var_60_4 = arg_60_1.type and arg_60_1.type == var_0_6.MERCENARY_HEROS
	local var_60_5 = xyd.tables.partnerExp:exp(arg_60_1:getLevel())
	local var_60_6 = xyd.tables.partnerExp:totalExp(arg_60_1:getLevel())
	local var_60_7 = arg_60_1:getExp()
	local var_60_8 = arg_60_1:getLevel()
	local var_60_9 = math.min((var_60_7 + var_60_5 - var_60_6) / var_60_5, 1)

	var_60_2:setMidpoint(cc.p(0, 0))
	var_60_2:setBarChangeRate(cc.p(1, 0))
	var_60_2:setPercentage((var_60_9 or 0) * 100)

	if arg_60_1.petID_ then
		var_60_2:setPercentage(0)
		var_60_2:runAction(cc.ProgressTo:create(var_60_9 * var_60_0, var_60_9 * 100))
		arg_60_2:getChildByName("exp"):setString("EXP+" .. (arg_60_1.add_exp or 0))
		arg_60_2:getChildByName("exp"):enableOutline(cc.c4b(51, 31, 31, 255), 3)

		return
	end

	for iter_60_0, iter_60_1 in ipairs(arg_60_0.heroExp) do
		if iter_60_1.partner_id == (arg_60_1.heroID_ or arg_60_1.petID_) then
			if iter_60_1.exp and iter_60_1.exp > 0 then
				arg_60_1:setExp(iter_60_1.exp or 0, arg_60_0.heroMaxLev)
			end

			break
		end
	end

	local var_60_10 = xyd.tables.partnerExp:exp(arg_60_1:getLevel())
	local var_60_11 = xyd.tables.partnerExp:totalExp(arg_60_1:getLevel())
	local var_60_12 = arg_60_1:getExp() + var_60_10 - var_60_11
	local var_60_13 = math.min(var_60_12 / var_60_10, 1)
	local var_60_14 = arg_60_1:getLevel()
	local var_60_15 = arg_60_1:getExp()
	local var_60_16 = var_60_15 - var_60_7

	if var_60_4 or var_60_16 < 0 then
		var_60_16 = 0
	end

	arg_60_2:getChildByName("exp"):setString("EXP+" .. var_60_16)
	arg_60_2:getChildByName("exp"):enableOutline(cc.c4b(51, 31, 31, 255), 3)

	local function var_60_17()
		if var_60_15 >= xyd.tables.partnerExp:totalExp(arg_60_0.heroMaxLev) then
			var_60_3:setVisible(true)
			var_60_2:setVisible(false)
		end
	end

	local function var_60_18(arg_62_0, arg_62_1)
		if arg_62_1 == var_60_14 then
			var_60_2:runAction(cc.Sequence:create({
				cc.ProgressTo:create(var_60_13 * var_60_0, var_60_13 * 100),
				cc.CallFunc:create(function()
					var_60_17()
				end)
			}))

			return
		end

		local var_62_0

		if arg_62_1 == var_60_8 then
			var_62_0 = (1 - var_60_9) / arg_62_0 * var_60_0
		else
			var_62_0 = var_60_0 / arg_62_0
		end

		var_60_2:runAction(cc.Sequence:create({
			cc.ProgressTo:create(var_62_0, 100),
			cc.CallFunc:create(function()
				var_60_2:setPercentage(0)
				var_60_18(arg_62_0, arg_62_1 + 1)
			end)
		}))
	end

	if var_60_7 >= xyd.tables.partnerExp:totalExp(arg_60_0.heroMaxLev) then
		var_60_3:setVisible(true)
		var_60_2:setVisible(false)
	elseif var_60_8 == var_60_14 and var_60_13 ~= var_60_9 then
		var_60_2:runAction(cc.Sequence:create({
			cc.ProgressTo:create(var_60_0 * (var_60_13 - var_60_9), var_60_13 * 100),
			cc.CallFunc:create(function()
				var_60_17()
			end)
		}))
	elseif var_60_8 ~= var_60_14 then
		local var_60_19 = math.max(var_60_14 - var_60_8 - var_60_9)

		var_60_18(var_60_19, var_60_8)
	end

	if arg_60_0.favorDegreeUp and arg_60_1.getHeroID and arg_60_0.favorDegreeUp[arg_60_1:getHeroID()] then
		local var_60_20 = xyd.createEffect("skeletons/ui_effect/battle_end/loveheart_up")

		var_60_20:addTo(arg_60_2)
		var_60_20:pos(90, 240)
		var_60_20:play(function()
			var_60_20:setVisible(false)
		end, nil, 0.3)

		local var_60_21 = xyd.createEffect("skeletons/ui_effect/battle_end/love_up")

		var_60_21:addTo(arg_60_2:getChildByName("favor_pos"))
		var_60_21:play(nil, nil, 0.3)
	end
end

function var_0_0.delegate(arg_67_0, arg_67_1, arg_67_2, arg_67_3)
	if cc.ui.UIListView.COUNT_TAG == arg_67_2 then
		return #arg_67_0.itemRecord_
	elseif cc.ui.UIListView.CELL_TAG == arg_67_2 then
		local var_67_0
		local var_67_1
		local var_67_2 = arg_67_0.touchList_:dequeueItem()

		if not var_67_2 then
			var_67_2 = arg_67_0.touchList_:newItem()
		else
			var_67_2:removeAllChildren()
		end

		local var_67_3

		if arg_67_0.campaignType == xyd.CampaignType.INCUBUS then
			var_67_3 = arg_67_0:nodeByName("unlimit_item_scroll")
		else
			var_67_3 = arg_67_0:nodeByName("item_scroll")
		end

		local var_67_4 = display.newNode()

		var_67_4:setTouchSwallowEnabled(false)
		var_67_4:size(var_67_3:getHeight(), var_67_3:getHeight())

		if type(arg_67_0.itemRecord_[arg_67_3]) == "table" then
			xyd.setHunqiAndAddTips({
				container = var_67_4,
				item = arg_67_0.itemRecord_[arg_67_3]
			})
		else
			xyd.setItemBorder(var_67_4, arg_67_0.itemRecord_[arg_67_3])
		end

		var_67_4:pos(0, 0)
		var_67_4:setAnchorPoint(0, 0)

		local var_67_5 = display.newNode()

		var_67_4:addTo(var_67_5)
		var_67_5:size(var_67_4:getWidth() + (arg_67_3 == #arg_67_0.itemRecord_ and 0 or 28), var_67_4:getHeight())
		var_67_2:setItemSize(var_67_5:getWidth(), var_67_5:getHeight())
		var_67_2:addContent(var_67_5)

		if type(arg_67_0.itemRecord_[arg_67_3]) == "number" then
			local var_67_6 = arg_67_0.showItems[arg_67_0.itemRecord_[arg_67_3]]
			local var_67_7 = {
				size = 22,
				y = 5,
				text = tostring(var_67_6),
				color = cc.c3b(255, 255, 255),
				align = cc.ui.TEXT_ALIGN_CENTER,
				valign = cc.ui.TEXT_VALIGN_TOP,
				x = var_67_4:getWidth() - 10
			}

			if var_67_6 > 1 then
				local var_67_8 = xyd.AssetLoader.get():loadLabel(var_67_7)

				var_67_8:addTo(var_67_4)
				var_67_8:setAnchorPoint(1, 0)
				var_67_8:enableOutline(cc.c4b(0, 0, 0, 255), 2)
			end

			local var_67_9 = arg_67_0:getPlusType(arg_67_0.itemRecord_[arg_67_3])
			local var_67_10 = {
				id = arg_67_0.itemRecord_[arg_67_3],
				itemHeroList = var_67_9,
				hasNum = arg_67_0.player_:getBackpack():getItemNumByID(arg_67_0.itemRecord_[arg_67_3])
			}
			local var_67_11 = var_67_3:convertToWorldSpace(cc.p(var_67_3:getX(), var_67_3:getY()))
			local var_67_12 = var_67_4:convertToWorldSpace(cc.p(var_67_4:getX(), var_67_4:getY()))
			local var_67_13
			local var_67_14

			if arg_67_0.campaignType == xyd.CampaignType.INCUBUS then
				var_67_13, var_67_14 = var_67_11.x + var_67_12.x, var_67_11.y + var_67_12.y + 80
			else
				var_67_13, var_67_14 = var_67_4:getX() + var_67_3:getX(), var_67_4:getY() + var_67_3:getY()
			end

			local var_67_15 = var_67_4:getHeight()

			var_67_4:setTouchEnabled(true)
			var_67_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_68_0)
				if arg_68_0.name == "began" then
					if arg_67_0.scrollViewMoved_ then
						return true
					end

					if not xyd.WindowManager.get():getWindow("new_item_tips") then
						local var_68_0 = xyd.WindowManager.get():openWindow("new_item_tips", var_67_10)

						xyd.adaptToWorldPosition(var_67_4, var_68_0)
					end

					return true
				elseif arg_68_0.name == "ended" then
					if arg_67_0.scrollViewMoved_ then
						return true
					end

					local var_68_1 = arg_67_0:convertToWorldSpace(cc.p(var_67_13, var_67_14))
					local var_68_2 = xyd.WindowManager.get():getWindow("new_item_tips")

					xyd.WindowManager.get():closeWindow("new_item_tips")
				end
			end)
		end

		return var_67_2
	end
end

function var_0_0.showGuildItems(arg_69_0)
	if not arg_69_0.guildItems or next(arg_69_0.guildItems) == nil then
		return
	end
end

return var_0_0
