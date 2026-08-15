local var_0_0 = class("FightFishBattleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.activityFish

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.fighterATableID = arg_1_2.fighterATableID
	arg_1_0.fighterBTableID = arg_1_2.fighterBTableID
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.messageList = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("list"):getWidth(), arg_3_0:nodeByName("list"):getHeight() - 15),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	local var_3_0 = import("app.common.ui.SpriteNodeButton").new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_3_0:addTo(arg_3_0)
	var_3_0:setAnchorPoint(0.5, 0.5)
	var_3_0:setPosition(46, 694)
	var_3_0:setName("return_btn")

	arg_3_0.returnBtn = var_3_0

	arg_3_0.returnBtn:addTouchEvent(function(arg_4_0)
		if arg_4_0.name == "ended" then
			xyd.playCloseSound()
			xyd.WindowManager.get():closeAllWindows()
			ngx.ctx.battle.releaseCache()
			cc.Director:getInstance():popScene()
		end
	end)
	arg_3_0:updateFighter()
	arg_3_0:addEffect()
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" and 20 <= math.abs(arg_5_1.y - arg_5_0.prevY_) then
		arg_5_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateFighter(arg_6_0)
	arg_6_0:nodeByName("name_1"):setString(var_0_1:name(arg_6_0.fighterATableID))
	arg_6_0:nodeByName("name_2"):setString(var_0_1:name(arg_6_0.fighterBTableID))
	arg_6_0:nodeByName("name_1"):enableOutline(cc.c4b(49, 49, 49, 255))
	arg_6_0:nodeByName("name_2"):enableOutline(cc.c4b(49, 49, 49, 255))
	arg_6_0:setHPProgress(1, 1, false)
	arg_6_0:setHPProgress(1, 2, false)
	display.addSpriteFrames("windows/fight_fish_battle/icon/icon.plist", "windows/fight_fish_battle/icon/icon.png")

	local var_6_0 = xyd.AssetLoader.get():loadSprite("windows/fight_fish_battle/icon/" .. arg_6_0.fighterATableID .. ".png")

	var_6_0:addTo(arg_6_0:nodeByName("bg_red"))
	var_6_0:setPosition(arg_6_0:nodeByName("bg_red"):getWidth() / 2, arg_6_0:nodeByName("bg_red"):getHeight() / 2)

	local var_6_1 = xyd.AssetLoader.get():loadSprite("windows/fight_fish_battle/icon/" .. arg_6_0.fighterBTableID .. ".png")

	var_6_1:addTo(arg_6_0:nodeByName("bg_blue"))
	var_6_1:setPosition(arg_6_0:nodeByName("bg_blue"):getWidth() / 2, arg_6_0:nodeByName("bg_blue"):getHeight() / 2)
	var_6_1:setScaleX(-1)

	local var_6_2 = "windows/activities/1226/skill_icon/border.png"

	xyd.AssetLoader.get():loadSprite("windows/activities/1226/skill_icon/" .. arg_6_0.fighterATableID .. ".png"):addTo(arg_6_0:nodeByName("node_skill_1"))
	xyd.AssetLoader.get():loadSprite(var_6_2):addTo(arg_6_0:nodeByName("node_skill_1"))
	arg_6_0:nodeByName("node_skill_1"):setScale(0.6)
	xyd.AssetLoader.get():loadSprite("windows/activities/1226/skill_icon/" .. arg_6_0.fighterBTableID .. ".png"):addTo(arg_6_0:nodeByName("node_skill_2"))
	xyd.AssetLoader.get():loadSprite(var_6_2):addTo(arg_6_0:nodeByName("node_skill_2"))
	arg_6_0:nodeByName("node_skill_2"):setScale(0.6)
end

function var_0_0.addMessage(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = xyd.split(arg_7_1)
	local var_7_1 = display.newNode()
	local var_7_2 = 28
	local var_7_3 = 18

	for iter_7_0 = 1, #var_7_0 do
		local var_7_4 = var_7_0[iter_7_0]
		local var_7_5 = xyd.createMultiColorTxt(var_7_4, cc.c3b(228, 228, 228), var_7_3)

		var_7_5:addTo(var_7_1)
		var_7_5:setPosition(49, var_7_2 * (#var_7_0 - iter_7_0 + 1) - var_7_3)
	end

	var_7_1:setContentSize(arg_7_0:nodeByName("list"):getWidth(), var_7_2 * #var_7_0)

	if arg_7_2 then
		local var_7_6 = "windows/fight_fish_battle/block_"

		if arg_7_2 == xyd.TeamType.A then
			var_7_6 = var_7_6 .. "red.png"
		else
			var_7_6 = var_7_6 .. "blue.png"
		end

		local var_7_7 = xyd.AssetLoader.get():loadSprite(var_7_6)

		var_7_7:addTo(var_7_1)
		var_7_7:setPosition(29, var_7_2 * (#var_7_0 - 0.5) + 3)
	end

	local var_7_8 = arg_7_0.messageList:newItem()

	var_7_8:addContent(var_7_1)
	var_7_8:setItemSize(var_7_1:getWidth(), var_7_1:getHeight())
	arg_7_0.messageList:addItem(var_7_8)
	arg_7_0.messageList:reload()
	arg_7_0.messageList:scrollTo(0, 0)
end

function var_0_0.setHPProgress(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	if arg_8_0.hpProgress_ == nil then
		arg_8_0.hpProgress_ = {}
	end

	if not arg_8_0.hpProgress_[arg_8_2] then
		arg_8_0.hpProgress_[arg_8_2] = {}

		local var_8_0 = arg_8_0:nodeByName("bg_hp_" .. arg_8_2):getContentSize()

		arg_8_0:newHPProgress("windows/fight_fish_battle/hp_green.png", 1, var_8_0, arg_8_0:nodeByName("bg_hp_" .. arg_8_2), arg_8_2)
		arg_8_0:newHPProgress("windows/fight_fish_battle/hp_yellow.png", 2, var_8_0, arg_8_0:nodeByName("bg_hp_" .. arg_8_2), arg_8_2)
		arg_8_0:newHPProgress("windows/fight_fish_battle/hp_red.png", 3, var_8_0, arg_8_0:nodeByName("bg_hp_" .. arg_8_2), arg_8_2)
	end

	for iter_8_0 = 1, 3 do
		arg_8_0.hpProgress_[arg_8_2][iter_8_0]:setVisible(false)
	end

	if arg_8_1 >= 0.5 then
		arg_8_0.hpProgress_[arg_8_2][1]:setVisible(true)
	elseif arg_8_1 >= 0.25 then
		arg_8_0.hpProgress_[arg_8_2][2]:setVisible(true)
	else
		arg_8_0.hpProgress_[arg_8_2][3]:setVisible(true)
	end

	arg_8_0:setBarProgress_(arg_8_0.hpProgress_[arg_8_2][1], arg_8_1, true)
	arg_8_0:setBarProgress_(arg_8_0.hpProgress_[arg_8_2][2], arg_8_1, true)
	arg_8_0:setBarProgress_(arg_8_0.hpProgress_[arg_8_2][3], arg_8_1, true)
end

function var_0_0.newHPProgress(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)
	local var_9_0 = xyd.AssetLoader.get():loadSprite(arg_9_1)

	arg_9_0.hpProgress_[arg_9_5][arg_9_2] = display.newProgressTimer(var_9_0, display.PROGRESS_TIMER_BAR):align(display.CENTER, arg_9_3.width / 2, arg_9_3.height / 2):addTo(arg_9_4, 1)

	arg_9_0.hpProgress_[arg_9_5][arg_9_2]:setMidpoint(cc.p(0, 0))
	arg_9_0.hpProgress_[arg_9_5][arg_9_2]:setBarChangeRate(cc.p(1, 0))
	arg_9_0.hpProgress_[arg_9_5][arg_9_2]:setPercentage(100)
end

function var_0_0.setBarProgress_(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	arg_10_1:stopAllActions()

	arg_10_2 = arg_10_2 * 100

	local var_10_0 = arg_10_1:getPercentage()

	if tonumber(arg_10_3) then
		arg_10_1:runActionOnce(cc.ProgressTo:create(tonumber(arg_10_3), arg_10_2), false, arg_10_4)
	elseif arg_10_3 or var_10_0 < arg_10_2 then
		local var_10_1 = arg_10_2 - var_10_0
		local var_10_2 = xyd.tables.battleConfig.hpProgressMoveBase + xyd.tables.battleConfig.hpProgressMoveStep * math.abs(var_10_1)
		local var_10_3 = xyd.tables.battleConfig.hpProgressBrakeBase
		local var_10_4 = var_10_0 + var_10_1 * (1 - xyd.tables.battleConfig.hpProgressBrakePercent)
		local var_10_5 = arg_10_2
		local var_10_6 = cc.Sequence:create(cc.ProgressTo:create(var_10_2, var_10_4), cc.ProgressTo:create(var_10_3, var_10_5))

		arg_10_1:runActionOnce(var_10_6, false, arg_10_4)
	else
		arg_10_1:setPercentage(arg_10_2)

		if arg_10_4 ~= nil then
			arg_10_4()
		end
	end
end

function var_0_0.addEffect(arg_11_0)
	local var_11_0 = "skeletons/ui_effect/activity_fish_fight/zhandouchangjing"
	local var_11_1 = xyd.createEffect(var_11_0)

	var_11_1:addTo(arg_11_0:nodeByName("bg"))
	var_11_1:setPosition(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2)
	var_11_1:play(nil, true, nil, "texiao01")
end

function var_0_0.addEndEffect(arg_12_0)
	local var_12_0 = "skeletons/ui_effect/activity_fish_fight/ko"
	local var_12_1 = xyd.createEffect(var_12_0)

	var_12_1:addTo(arg_12_0, 10)
	var_12_1:setPosition(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2 + 150)
	var_12_1:play(function()
		arg_12_0:performWithDelay(function()
			if arg_12_0 and not tolua.isnull(arg_12_0) then
				xyd.WindowManager.get():closeAllWindows()
				ngx.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end
		end, 30)
	end, false, nil, "texiao01")
end

return var_0_0
