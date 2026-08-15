local var_0_0 = class("LevelUpWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.player
local var_0_5 = xyd.tables.hero
local var_0_6 = xyd.tables.skill
local var_0_7 = "main_scene_bottom"
local var_0_8 = "main_scene_left"
local var_0_9 = "main_scene_middle"
local var_0_10 = "main_scene_top"

var_0_0.TEXT_LEVEL = "text_level"
var_0_0.TEXT_ENERGY = "text_energy"
var_0_0.TEXT_ENERGY_LIMIT = "text_energy_limit"
var_0_0.TEXT_HERO_LEVEL_LIMIT = "text_hero_level_limit"
var_0_0.LEVEL_1 = "level_v1"
var_0_0.LEVEL_2 = "level_v2"
var_0_0.ENERGY_1 = "energy_v1"
var_0_0.ENERGY_2 = "energy_v2"
var_0_0.ENERGY_LIMIT1 = "energy_limit1"
var_0_0.ENERGY_LIMIT2 = "energy_limit2"
var_0_0.HERO_LIMIT1 = "hero_limit1"
var_0_0.HERO_LIMIT2 = "hero_limit2"

local var_0_11 = {}

var_0_11.spin = "skeletons/ui_effect/common_effect_spin3/common_effect_spin3"
var_0_11.levelup = "skeletons/ui_effect/lvlup/lv_up"
var_0_11.evolve = "skeletons/ui_effect/lvlup/evolve_up"
var_0_11.advance = "skeletons/ui_effect/lvlup/color_break_1"
var_0_11.icon = "skeletons/ui_effect/lvlup/color_break_2"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.type_ = arg_1_2.type_
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_1_2.hero then
		arg_1_0.hero = arg_1_2.hero
		arg_1_0.heroID = arg_1_2.hero:getTableID()
	else
		arg_1_0.heroID = arg_1_2.heroID
	end

	arg_1_0.old_hero = arg_1_2.old_hero
	arg_1_0.vals = arg_1_2.vals
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.funcCount = 0
	arg_1_0.actionQueue = {}
end

function var_0_0.loadRes(arg_2_0)
	local var_2_0
	local var_2_1 = arg_2_0.type_ == xyd.LevelUpType.LEVELUP and "windows/levelup/levelup_2.csb" or "windows/levelup/levelup_1.csb"

	if #var_2_1 == 0 then
		return
	end

	arg_2_0.hasLoadRes = true

	arg_2_0:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson(var_2_1))

	if xyd.tables.window:isAddTheme(arg_2_0.name) == 1 and arg_2_0.colorMode and arg_2_0.colorMode > 0 then
		arg_2_0:addThemeBG()
	end

	if var_2_1 == xyd.Template.CommonWithSidebar then
		arg_2_0:addLeftSidebar()
		arg_2_0:addTopSidebar()
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()

	arg_3_0.container = arg_3_0:nodeByName("container")
	arg_3_0.bgContainer = arg_3_0:nodeByName("bg")
	arg_3_0.header = arg_3_0:nodeByName("header")
	arg_3_0.content = arg_3_0:nodeByName("content")
	arg_3_0.footer = arg_3_0:nodeByName("footer")

	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0.container:getContentSize()

	arg_4_0:playGuide()
end

function var_0_0.didClose(arg_5_0)
	if arg_5_0.callback then
		arg_5_0.callback()
	end

	if arg_5_0.player.isComment == 0 and arg_5_0:checkCommendLevel(arg_5_0.vals.newLev) and device.platform == "ios" and arg_5_0.player.commentOpen == 1 then
		xyd.WindowManager.get():openWindow("comment")
	end

	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_EIGHT then
		local var_5_0 = xyd.WindowManager.get():getWindow("hero_main")

		if var_5_0 then
			var_5_0:playGuide()
		end
	end

	if xyd.WindowManager.get():isWindowOpen("battle_win") then
		local var_5_1 = xyd.WindowManager.get():getWindow("battle_win")

		if var_5_1 then
			var_5_1:playGuide()
		end
	elseif xyd.WindowManager.get():isWindowOpen("battle_lose") then
		local var_5_2 = xyd.WindowManager.get():getWindow("battle_lose")

		if var_5_2 then
			var_5_2:playGuide()
		end
	end
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = 0
	local var_6_1 = 0
	local var_6_2 = 0
	local var_6_3 = 10
	local var_6_4 = arg_6_0.footer:getPositionX()
	local var_6_5, var_6_6 = arg_6_0.footer:getPositionY(), arg_6_0.footer:getContentSize()
	local var_6_7 = 10
	local var_6_8 = 10
	local var_6_9 = 0

	arg_6_0:nodeByName("close"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("close"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_6_0)
		end
	end)

	if arg_6_0.type_ == xyd.LevelUpType.LEVELUP then
		arg_6_0.header:setVisible(false)
		arg_6_0.footer:setVisible(false)

		local var_6_10 = arg_6_0:genLevelupItemData()

		var_6_1 = arg_6_0:fillContent(var_6_10)
		var_6_5 = 100
		var_6_9 = 126
	elseif arg_6_0.type_ == xyd.LevelUpType.EVOLVE then
		if arg_6_0.vals.isShowSkillDesc4 then
			var_6_2 = arg_6_0:fillFooter2()

			local var_6_11 = display.newScale9Sprite("windows/levelup/bg_line.png", 0, 0, cc.size(796, 2), cc.rect(5, 5, 5, 5))

			var_6_11:setPosition(390, 155)
			var_6_11:addTo(arg_6_0.footer)

			var_6_2 = var_6_2 + 50

			arg_6_0.footer:setVisible(true)

			arg_6_0.actionLine = var_6_11
		else
			arg_6_0.footer:setVisible(false)
		end

		arg_6_0.header:setVisible(true)

		var_6_0 = arg_6_0:fillHeader()

		local var_6_12 = arg_6_0:genEvolveItemData()

		var_6_1 = arg_6_0:fillContent(var_6_12)

		if arg_6_0.vals.isShowSkillDesc4 then
			var_6_5 = 60
			var_6_8 = -14
			var_6_9 = 70
		else
			var_6_5 = 116
			var_6_8 = -14
			var_6_9 = 70
		end
	elseif arg_6_0.type_ == xyd.LevelUpType.ADVANCE then
		local var_6_13 = xyd.Color2Quality[arg_6_0.vals.oldColor]
		local var_6_14 = xyd.Color2Quality[arg_6_0.vals.newColor]

		if var_6_13 == var_6_14 or var_6_14 >= 5 then
			arg_6_0.footer:setVisible(false)
		else
			arg_6_0.footer:setVisible(true)

			var_6_2 = arg_6_0:fillFooter(var_6_14)

			local var_6_15 = display.newScale9Sprite("windows/levelup/bg_line.png", 0, 0, cc.size(796, 2), cc.rect(5, 5, 5, 5))

			var_6_15:setPosition(390, 175)
			var_6_15:addTo(arg_6_0.footer)

			var_6_2 = var_6_2 + 50
			arg_6_0.actionLine = var_6_15
		end

		arg_6_0.header:setVisible(true)

		var_6_0 = arg_6_0:fillHeader(var_6_14)

		local var_6_16 = arg_6_0:genAdvanceItemData()

		var_6_1 = arg_6_0:fillContent(var_6_16)
		var_6_5 = 60
		var_6_7 = 50
		var_6_8 = 16
		var_6_9 = 70
	else
		return
	end

	arg_6_0.footer:setContentSize(var_6_6.width, var_6_2)
	arg_6_0.footer:setPositionY(var_6_5)

	local var_6_17 = var_6_5 + var_6_2 + var_6_7

	arg_6_0.content:setPositionY(var_6_17)
	arg_6_0.content:setContentSize(var_6_6.width, var_6_1)

	local var_6_18 = var_6_17 + var_6_1 + var_6_8

	arg_6_0.header:setPositionY(var_6_18)
	arg_6_0.content:setContentSize(var_6_6.width, var_6_0)

	local var_6_19 = var_6_18 + var_6_0 + var_6_3 + var_6_9
	local var_6_20 = arg_6_0.container:getContentSize()

	arg_6_0.container:setContentSize(var_6_20.width, var_6_19)
	arg_6_0.bgContainer:setContentSize(var_6_20.width, var_6_19)

	if arg_6_0.type_ ~= xyd.LevelUpType.LEVELUP then
		arg_6_0:nodeByName("close"):setPositionY(var_6_19 - 40)
	else
		arg_6_0:nodeByName("close"):setPositionY(var_6_19 - 32)
	end

	arg_6_0:setAnchorPoint(cc.p(0.5, 0.5))
	arg_6_0:setContentSize(var_6_20.width, var_6_19)
	arg_6_0:playEffect()
end

function var_0_0.playEffect(arg_8_0)
	if arg_8_0.type_ == xyd.LevelUpType.ADVANCE or arg_8_0.type_ == xyd.LevelUpType.EVOLVE then
		local var_8_0 = arg_8_0.container:getContentSize().height
		local var_8_1 = arg_8_0.container:getContentSize().width

		arg_8_0.header:setVisible(false)

		if arg_8_0.actionQueue and next(arg_8_0.actionQueue) then
			for iter_8_0, iter_8_1 in ipairs(arg_8_0.actionQueue) do
				iter_8_1:setVisible(false)
			end
		end

		if arg_8_0.actionLine then
			arg_8_0.actionLine:setVisible(false)
			arg_8_0.footerNode:getChildByName("container"):getChildByName("bg"):setVisible(false)
			arg_8_0.footerNode:getChildByName("container"):getChildByName("skill"):setVisible(false)
			arg_8_0.footerNode:getChildByName("container"):getChildByName("skill_title"):setVisible(false)
			arg_8_0.footerNode:getChildByName("container"):getChildByName("node_pos"):setVisible(false)
		end

		arg_8_0.footer:setVisible(false)
		arg_8_0.bgContainer:setAnchorPoint(cc.p(0.5, 1))
		arg_8_0.bgContainer:setPositionY(var_8_0)
		arg_8_0.bgContainer:setScaleY(250 / var_8_0)
		arg_8_0.bgContainer:setVisible(false)

		local var_8_2

		if arg_8_0.type_ == xyd.LevelUpType.ADVANCE then
			var_8_2 = var_0_11.advance
		else
			var_8_2 = var_0_11.evolve
		end

		local var_8_3 = var_8_2 .. ".json"
		local var_8_4 = var_8_2 .. ".atlas"
		local var_8_5 = var_0_1.new(var_8_3, var_8_4, 1)

		var_8_5:addTo(arg_8_0.container)
		var_8_5:setPosition(var_8_1 / 2, var_8_0 - 40)
		var_8_5:play(function()
			var_8_5:play(nil, true, nil, "texiao02")
		end, false, nil, "texiao01")
		var_0_2.performWithDelayGlobal(function()
			if arg_8_0 and not tolua.isnull(arg_8_0) then
				arg_8_0.bgContainer:setVisible(true)

				local var_10_0 = cc.Spawn:create({
					cc.ScaleTo:create(0.26, 1, 1.1)
				})
				local var_10_1 = cc.Spawn:create({
					cc.ScaleTo:create(0.13, 1, 1)
				})

				arg_8_0.bgContainer:runAction(cc.Sequence:create({
					var_10_0,
					var_10_1
				}))
			end
		end, 0.33)
		var_0_2.performWithDelayGlobal(function()
			if arg_8_0 and not tolua.isnull(arg_8_0) then
				arg_8_0.header:setVisible(true)

				local var_11_0 = arg_8_0.headerNode:getChildByName("container")

				var_11_0:getChildByName("arrow"):setVisible(false)
				var_11_0:getChildByName("avatar2"):setVisible(false)
				var_11_0:getChildByName("avatar1"):scale(0.36)

				local var_11_1 = cc.Spawn:create({
					cc.ScaleTo:create(0.13, 1.2, 1.2)
				})
				local var_11_2 = cc.Spawn:create({
					cc.ScaleTo:create(0.16, 0.9, 0.9)
				})
				local var_11_3 = cc.Spawn:create({
					cc.ScaleTo:create(0.16, 1, 1)
				})
				local var_11_4 = cc.CallFunc:create(function()
					local var_12_0 = var_11_0:getChildByName("avatar2"):getPositionX()
					local var_12_1 = var_11_0:getChildByName("avatar2"):getPositionY()

					var_11_0:getChildByName("avatar2"):setPositionX(var_12_0 - 120)
					var_11_0:getChildByName("avatar2"):setVisible(true)

					local var_12_2 = cc.Spawn:create({
						cc.MoveTo:create(0.3, cc.p(var_12_0, var_12_1))
					})

					var_11_0:getChildByName("avatar2"):runAction(cc.Sequence:create({
						var_12_2
					}))
				end)

				var_11_0:getChildByName("avatar1"):runAction(cc.Sequence:create({
					var_11_1,
					var_11_2,
					var_11_3,
					var_11_4
				}))
			end
		end, 0.33)

		local var_8_6 = var_0_11.icon
		local var_8_7 = var_8_6 .. ".json"
		local var_8_8 = var_8_6 .. ".atlas"
		local var_8_9 = var_0_1.new(var_8_7, var_8_8, 1)

		var_8_9:addTo(arg_8_0.headerNode:getChildByName("container"))
		var_8_9:setPosition(arg_8_0.headerNode:getChildByName("container"):getChildByName("arrow"):getPosition())
		var_8_9:play(function()
			return
		end, false)
		var_0_2.performWithDelayGlobal(function()
			if arg_8_0 and not tolua.isnull(arg_8_0) then
				arg_8_0.headerNode:getChildByName("container"):getChildByName("arrow"):setVisible(true)
			end
		end, 1.2)

		local var_8_10 = 0.5

		for iter_8_2 = 1, #arg_8_0.actionQueue do
			var_0_2.performWithDelayGlobal(function()
				if arg_8_0 and not tolua.isnull(arg_8_0) and arg_8_0.actionQueue and next(arg_8_0.actionQueue) then
					local var_15_0 = arg_8_0.actionQueue[iter_8_2]

					var_15_0:setVisible(true)
					var_15_0:setAnchorPoint(0.5, 1)
					var_15_0:setPositionX(var_15_0:getPositionX() + var_15_0:getContentSize().width / 2)
					var_15_0:setPositionY(var_15_0:getPositionY() + var_15_0:getContentSize().height)

					local var_15_1 = var_15_0:getPositionX()
					local var_15_2 = var_15_0:getPositionY()

					var_15_0:setPositionY(var_15_2 + 10)

					local var_15_3 = cc.Spawn:create({
						cc.MoveTo:create(0.1, cc.p(var_15_1, var_15_2)),
						cc.ScaleTo:create(0.1, 1.2, 1.2)
					})
					local var_15_4 = cc.Spawn:create({
						cc.ScaleTo:create(0.13, 0.9, 0.9)
					})
					local var_15_5 = cc.Spawn:create({
						cc.ScaleTo:create(0.13, 1, 1)
					})

					var_15_0:runAction(cc.Sequence:create({
						var_15_3,
						var_15_5,
						act3
					}))
				end
			end, var_8_10 + (iter_8_2 - 1) * 0.1)
		end

		if arg_8_0.actionLine then
			local var_8_11 = arg_8_0.footerNode:getChildByName("container")

			var_0_2.performWithDelayGlobal(function()
				if arg_8_0 and not tolua.isnull(arg_8_0) then
					arg_8_0.footer:setVisible(true)
					arg_8_0.actionLine:setVisible(true)
					arg_8_0.actionLine:setOpacity(0)
					arg_8_0.actionLine:runAction(cc.FadeIn:create(0.1))
					var_8_11:getChildByName("bg"):setVisible(true)
					var_8_11:getChildByName("bg"):setOpacity(0)
					var_8_11:getChildByName("bg"):runAction(cc.FadeIn:create(0.1))
				end
			end, 0.7)
			var_0_2.performWithDelayGlobal(function()
				if arg_8_0 and not tolua.isnull(arg_8_0) then
					var_8_11:getChildByName("skill"):setVisible(true)
					var_8_11:getChildByName("skill"):scale(0.36)

					local var_17_0 = cc.Spawn:create({
						cc.ScaleTo:create(0.13, 1.2, 1.2)
					})
					local var_17_1 = cc.Spawn:create({
						cc.ScaleTo:create(0.16, 0.9, 0.9)
					})
					local var_17_2 = cc.Spawn:create({
						cc.ScaleTo:create(0.16, 1, 1)
					})

					var_8_11:getChildByName("skill"):runAction(cc.Sequence:create({
						var_17_0,
						var_17_1,
						var_17_2
					}))
				end
			end, 0.8)
			var_0_2.performWithDelayGlobal(function()
				if arg_8_0 and not tolua.isnull(arg_8_0) then
					var_8_11:getChildByName("skill_title"):setVisible(true)
					var_8_11:getChildByName("skill_title"):setAnchorPoint(0.5, 0.5)
					var_8_11:getChildByName("skill_title"):setPositionX(var_8_11:getChildByName("skill_title"):getPositionX() + var_8_11:getChildByName("skill_title"):getContentSize().width / 2)
					var_8_11:getChildByName("skill_title"):scale(0.1)

					local var_18_0 = cc.Spawn:create({
						cc.ScaleTo:create(0.2, 1, 1)
					})

					var_8_11:getChildByName("skill_title"):runAction(cc.Sequence:create({
						var_18_0
					}))
				end
			end, 0.9)
			var_0_2.performWithDelayGlobal(function()
				if arg_8_0 and not tolua.isnull(arg_8_0) then
					var_8_11:getChildByName("node_pos"):setVisible(true)
					var_8_11:getChildByName("node_pos"):setOpacity(0)
					var_8_11:getChildByName("node_pos"):runAction(cc.FadeIn:create(0.3))
				end
			end, 1)
		end
	elseif arg_8_0.type_ == xyd.LevelUpType.LEVELUP then
		local var_8_12 = arg_8_0.container:getContentSize().height
		local var_8_13 = arg_8_0.container:getContentSize().width

		if arg_8_0.actionQueue and next(arg_8_0.actionQueue) then
			for iter_8_3, iter_8_4 in ipairs(arg_8_0.actionQueue) do
				iter_8_4:setVisible(false)
			end
		end

		arg_8_0.bgContainer:setAnchorPoint(cc.p(0.5, 1))
		arg_8_0.bgContainer:setPositionY(var_8_12)
		arg_8_0.bgContainer:setScaleY(250 / var_8_12)
		arg_8_0.bgContainer:setVisible(false)

		local var_8_14 = var_0_11.levelup
		local var_8_15 = var_8_14 .. ".json"
		local var_8_16 = var_8_14 .. ".atlas"
		local var_8_17 = var_0_1.new(var_8_15, var_8_16, 1)

		var_8_17:addTo(arg_8_0.container)
		var_8_17:setPosition(var_8_13 / 2, var_8_12 - 66)
		var_8_17:play(function()
			var_8_17:play(nil, true, nil, "texiao02")
		end, false, nil, "texiao01")
		var_0_2.performWithDelayGlobal(function()
			if arg_8_0 and not tolua.isnull(arg_8_0) then
				arg_8_0.bgContainer:setVisible(true)

				local var_21_0 = cc.Spawn:create({
					cc.ScaleTo:create(0.26, 1, 1.1)
				})
				local var_21_1 = cc.Spawn:create({
					cc.ScaleTo:create(0.13, 1, 1)
				})

				arg_8_0.bgContainer:runAction(cc.Sequence:create({
					var_21_0,
					var_21_1
				}))
			end
		end, 0.33)

		local var_8_18 = 0.5

		for iter_8_5 = 1, #arg_8_0.actionQueue do
			var_0_2.performWithDelayGlobal(function()
				if arg_8_0 and not tolua.isnull(arg_8_0) and arg_8_0.actionQueue and next(arg_8_0.actionQueue) then
					local var_22_0 = arg_8_0.actionQueue[iter_8_5]

					var_22_0:setVisible(true)
					var_22_0:setAnchorPoint(0.5, 1)
					var_22_0:setPositionX(var_22_0:getPositionX() + var_22_0:getContentSize().width / 2)
					var_22_0:setPositionY(var_22_0:getPositionY() + var_22_0:getContentSize().height)

					local var_22_1 = var_22_0:getPositionX()
					local var_22_2 = var_22_0:getPositionY()

					var_22_0:setPositionY(var_22_2 + 10)

					local var_22_3 = cc.Spawn:create({
						cc.MoveTo:create(0.1, cc.p(var_22_1, var_22_2)),
						cc.ScaleTo:create(0.1, 1.2, 1.2)
					})
					local var_22_4 = cc.Spawn:create({
						cc.ScaleTo:create(0.13, 0.9, 0.9)
					})
					local var_22_5 = cc.Spawn:create({
						cc.ScaleTo:create(0.13, 1, 1)
					})

					var_22_0:runAction(cc.Sequence:create({
						var_22_3,
						var_22_5,
						act3
					}))
				end
			end, var_8_18 + (iter_8_5 - 1) * 0.1)
		end
	end
end

function var_0_0.fillFooter(arg_23_0, arg_23_1)
	local var_23_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/levelup/levelup_footer.csb")
	local var_23_1 = var_23_0:getChildByName("container")
	local var_23_2 = var_23_1:getChildByName("skill")
	local var_23_3 = var_23_1:getChildByName("skill_title")
	local var_23_4 = var_0_5:getSkill(arg_23_0.heroID, arg_23_1)

	if var_23_4 and var_23_4 > 0 then
		xyd.setSkillBorder(var_23_2, var_23_4, 1, true)
		var_23_3:setString(var_0_3:translation("NEW_SKILL") .. var_0_6:name(var_23_4))
		var_23_3:enableOutline(cc.c4b(65, 74, 84, 255), 2)
	end

	local var_23_5 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 420, 65),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_23_1:getChildByName("node_pos")):pos(0, -60)
	local var_23_6 = {
		size = 20,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		dimensions = cc.size(420, 0),
		color = cc.c3b(57, 64, 70),
		text = var_0_6:desc(var_23_4)
	}
	local var_23_7 = xyd.AssetLoader.get():loadLabel(var_23_6)
	local var_23_8 = var_23_5:newItem()
	local var_23_9 = display.newNode()

	var_23_7:addTo(var_23_9)
	var_23_9:setContentSize(420, 0)
	var_23_8:addContent(var_23_9)
	var_23_8:setItemSize(420, 0)
	var_23_5:addItem(var_23_8)
	var_23_5:scrollAuto()
	var_23_0:addTo(arg_23_0.footer)

	arg_23_0.footerNode = var_23_0

	return var_23_1:getHeight()
end

function var_0_0.fillFooter2(arg_24_0)
	local var_24_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/levelup/levelup_footer.csb")
	local var_24_1 = var_24_0:getChildByName("container")
	local var_24_2 = var_24_1:getChildByName("skill")
	local var_24_3 = var_24_1:getChildByName("skill_title")
	local var_24_4 = var_0_5:getSkill(arg_24_0.heroID, arg_24_0.vals.oldStar)
	local var_24_5 = var_24_2:getContentSize()

	if var_24_4 and var_24_4 > 0 then
		local var_24_6 = xyd.tables.skill:icon(var_24_4)
		local var_24_7 = xyd.AssetLoader.get():loadSprite(var_24_6)

		var_24_7:addTo(var_24_2)
		var_24_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_24_7:setPosition(cc.p(var_24_5.width / 2, var_24_5.height / 2))
		var_24_7:setScale((var_24_5.height - 10) / var_24_7:getHeight())

		local var_24_8 = xyd.tables.skill:icon(var_24_4)

		xyd.setSpriteBorder(var_24_2, var_24_8, 1, nil, true)
		var_24_3:setString(var_0_3:translation("SKILL_POWER_UP") .. var_0_6:name(var_24_4))
		var_24_3:enableOutline(cc.c4b(65, 74, 84, 255), 2)
	end

	local var_24_9 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 420, 65),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_24_1:getChildByName("node_pos")):pos(0, -60)
	local var_24_10 = {
		size = 20,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		dimensions = cc.size(420, 0),
		color = cc.c3b(57, 64, 70),
		text = var_0_6:desc4(var_24_4)[1]
	}
	local var_24_11 = xyd.AssetLoader.get():loadLabel(var_24_10)
	local var_24_12 = var_24_9:newItem()
	local var_24_13 = display.newNode()

	var_24_11:addTo(var_24_13)
	var_24_13:setContentSize(420, 0)
	var_24_12:addContent(var_24_13)
	var_24_12:setItemSize(420, 0)
	var_24_9:addItem(var_24_12)
	var_24_9:scrollAuto()
	var_24_0:addTo(arg_24_0.footer)

	arg_24_0.footerNode = var_24_0

	return var_24_1:getHeight()
end

function var_0_0.fillHeader(arg_25_0)
	local var_25_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/levelup/levelup_header.csb")
	local var_25_1 = var_25_0:getChildByName("container"):getChildByName("avatar1")
	local var_25_2 = var_25_0:getChildByName("container"):getChildByName("avatar2")

	if arg_25_0.type_ == xyd.LevelUpType.EVOLVE then
		if arg_25_0.old_hero then
			xyd.setAvatarBorderNewUI(arg_25_0.old_hero, var_25_1, arg_25_0.vals.oldColor, arg_25_0.vals.oldStar)
		else
			xyd.setAvatarBorderNewUI(arg_25_0.hero, var_25_1, arg_25_0.vals.oldColor, arg_25_0.vals.oldStar)
		end

		xyd.setAvatarBorderNewUI(arg_25_0.hero, var_25_2, arg_25_0.vals.oldColor, arg_25_0.vals.newStar)
	elseif arg_25_0.type_ == xyd.LevelUpType.ADVANCE then
		if arg_25_0.old_hero then
			xyd.setAvatarBorderNewUI(arg_25_0.old_hero, var_25_1, arg_25_0.vals.oldColor, arg_25_0.vals.oldStar)
		else
			xyd.setAvatarBorderNewUI(arg_25_0.hero, var_25_1, arg_25_0.vals.oldColor, arg_25_0.vals.oldStar)
		end

		xyd.setAvatarBorderNewUI(arg_25_0.hero, var_25_2, arg_25_0.vals.newColor, arg_25_0.vals.oldStar)
	end

	var_25_0:addTo(arg_25_0.header)

	arg_25_0.headerNode = var_25_0

	return var_25_0:getChildByName("container"):getHeight()
end

function var_0_0.fillContent(arg_26_0, arg_26_1)
	if not arg_26_1 or not next(arg_26_1) then
		return 0
	end

	local var_26_0 = 0
	local var_26_1 = 0
	local var_26_2 = {}
	local var_26_3 = false
	local var_26_4 = {}

	for iter_26_0 = #arg_26_1, 1, -1 do
		local var_26_5 = arg_26_1[iter_26_0]
		local var_26_6
		local var_26_7

		if var_26_5.val then
			var_26_0 = var_26_0 + 1
			var_26_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/levelup/levelup_item2.csb")
			var_26_7 = var_26_6:getChildByName("container")

			var_26_7:getChildByName("val"):setString(var_26_5.val)
		elseif var_26_5.val1 then
			var_26_0 = var_26_0 + 1
			var_26_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/levelup/levelup_item.csb")
			var_26_7 = var_26_6:getChildByName("container")

			var_26_7:getChildByName("val1"):setString(var_26_5.val1)
			var_26_7:getChildByName("val2"):setString(var_26_5.val2)
		end

		if var_26_6 and var_26_7 then
			table.insert(var_26_2, var_26_7:getChildByName("bg"))
			var_26_7:getChildByName("name"):setString(var_26_5.name)

			if var_26_5.desc then
				var_26_7:getChildByName("desc"):setString(var_26_5.desc)
			end

			var_26_6:setPositionY(var_26_1)
			var_26_6:addTo(arg_26_0.content)

			if arg_26_0.type_ == xyd.LevelUpType.LEVELUP then
				if var_26_5.val then
					var_26_1 = var_26_1 + var_26_7:getHeight() + 14
				else
					var_26_1 = var_26_1 + var_26_7:getHeight() + 24
				end

				if iter_26_0 == 1 then
					var_26_7:getChildByName("name"):setColor(cc.c4b(255, 234, 91, 255))
				end
			elseif arg_26_0.type_ == xyd.LevelUpType.ADVANCE then
				var_26_1 = var_26_1 + var_26_7:getHeight() + 14
			elseif arg_26_0.type_ == xyd.LevelUpType.EVOLVE then
				if arg_26_0.vals.isShowSkillDesc4 then
					var_26_1 = var_26_1 + var_26_7:getHeight() + 24
				else
					var_26_1 = var_26_1 + var_26_7:getHeight() + 44
				end
			end

			if arg_26_0.funcCount > 0 and iter_26_0 == #arg_26_1 - arg_26_0.funcCount + 1 and var_26_5.val and not var_26_3 then
				var_26_3 = true

				local var_26_8 = display.newScale9Sprite("windows/levelup/bg_line.png", 0, 0, cc.size(796, 2), cc.rect(5, 5, 5, 5))

				var_26_8:setPositionY(var_26_1 + 10)
				var_26_8:setPositionX(arg_26_0.content:getContentSize().width / 2)
				var_26_8:setAnchorPoint(0, 0)
				var_26_8:setPositionX(var_26_8:getPositionX() - var_26_8:getContentSize().width / 2)
				var_26_8:addTo(arg_26_0.content)
				table.insert(var_26_4, var_26_8)

				var_26_1 = var_26_1 + 34
			end
		end

		var_26_6:setContentSize(var_26_6:getChildByName("container"):getContentSize())
		table.insert(var_26_4, var_26_6)
	end

	for iter_26_1 = #var_26_4, 1, -1 do
		table.insert(arg_26_0.actionQueue, var_26_4[iter_26_1])
	end

	return var_26_1
end

function var_0_0.genLevelupItemData(arg_27_0)
	local var_27_0 = {}
	local var_27_1 = {
		name = var_0_3:translation("LEVELUP_TEXT1"),
		val1 = arg_27_0.vals.oldLev,
		val2 = arg_27_0.vals.newLev
	}

	table.insert(var_27_0, var_27_1)

	local var_27_2 = {
		name = var_0_3:translation("LEVELUP_TEXT2"),
		val1 = arg_27_0.vals.oldEnergy,
		val2 = arg_27_0.vals.newEnergy
	}

	table.insert(var_27_0, var_27_2)

	local var_27_3 = {
		name = var_0_3:translation("LEVELUP_TEXT3"),
		val1 = var_0_4:maxEnergy(arg_27_0.vals.oldLev),
		val2 = var_0_4:maxEnergy(arg_27_0.vals.newLev)
	}

	table.insert(var_27_0, var_27_3)

	local var_27_4 = var_0_4:heroMaxLev(arg_27_0.vals.oldLev)
	local var_27_5 = var_0_4:heroMaxLev(arg_27_0.vals.newLev)

	if var_27_5 ~= var_27_4 then
		local var_27_6 = {
			name = var_0_3:translation("LEVELUP_TEXT4"),
			val1 = var_27_4,
			val2 = var_27_5
		}

		table.insert(var_27_0, var_27_6)
	end

	if arg_27_0.vals.newFuncIDs and next(arg_27_0.vals.newFuncIDs) then
		for iter_27_0, iter_27_1 in pairs(arg_27_0.vals.newFuncIDs) do
			if xyd.tables.functionOpen:isOnLevelupWnd(iter_27_1) ~= 0 then
				local var_27_7 = {
					name = var_0_3:translation("LEVELUP_TEXT5"),
					val = xyd.tables.functionOpen:name(iter_27_1)
				}

				table.insert(var_27_0, var_27_7)

				arg_27_0.funcCount = arg_27_0.funcCount + 1
			end
		end
	end

	return var_27_0
end

function var_0_0.genEvolveItemData(arg_28_0)
	local var_28_0 = {}
	local var_28_1 = {
		name = var_0_3:translation("LEVELUP_TEXT8"),
		val1 = var_0_5:getHeroAttrGrow(arg_28_0.heroID, xyd.HeroType.STRENGTH, arg_28_0.vals.oldStar),
		val2 = var_0_5:getHeroAttrGrow(arg_28_0.heroID, xyd.HeroType.STRENGTH, arg_28_0.vals.newStar)
	}

	table.insert(var_28_0, var_28_1)

	local var_28_2 = {
		name = var_0_3:translation("LEVELUP_TEXT9"),
		val1 = var_0_5:getHeroAttrGrow(arg_28_0.heroID, xyd.HeroType.WISE, arg_28_0.vals.oldStar),
		val2 = var_0_5:getHeroAttrGrow(arg_28_0.heroID, xyd.HeroType.WISE, arg_28_0.vals.newStar)
	}

	table.insert(var_28_0, var_28_2)

	local var_28_3 = {
		name = var_0_3:translation("LEVELUP_TEXT10"),
		val1 = var_0_5:getHeroAttrGrow(arg_28_0.heroID, xyd.HeroType.AGILE, arg_28_0.vals.oldStar),
		val2 = var_0_5:getHeroAttrGrow(arg_28_0.heroID, xyd.HeroType.AGILE, arg_28_0.vals.newStar)
	}

	table.insert(var_28_0, var_28_3)

	if xyd.isSuperHero(arg_28_0.heroID) and arg_28_0.vals.newStar > xyd.HERO_TOTAL_STARS then
		local var_28_4 = {
			name = var_0_3:translation("LEVELUP_TEXT11"),
			val1 = xyd.tables.superPartnerStar:equipLimit(arg_28_0.vals.oldStar),
			val2 = xyd.tables.superPartnerStar:equipLimit(arg_28_0.vals.newStar)
		}

		table.insert(var_28_0, var_28_4)
	end

	return var_28_0
end

function var_0_0.genAdvanceItemData(arg_29_0)
	local var_29_0 = {}
	local var_29_1 = {
		name = var_0_3:translation("LEVELUP_TEXT6"),
		val1 = arg_29_0.vals.oldHP,
		val2 = arg_29_0.vals.newHP
	}

	table.insert(var_29_0, var_29_1)

	local var_29_2 = {
		name = var_0_3:translation("LEVELUP_TEXT12"),
		val1 = arg_29_0.vals.oldForce,
		val2 = arg_29_0.vals.newForce
	}

	table.insert(var_29_0, var_29_2)

	return var_29_0
end

function var_0_0.checkCommendLevel(arg_30_0, arg_30_1)
	local var_30_0 = xyd.tables.misc.commendRewardLevs

	for iter_30_0, iter_30_1 in ipairs(var_30_0) do
		if arg_30_1 == iter_30_1 then
			return true
		end
	end

	return false
end

function var_0_0.playGuide(arg_31_0)
	local var_31_0 = xyd.StoryData.get():getGuideID()

	if var_31_0 == xyd.GuideStoryType.GUIDE_SUPER_BATTLE_START then
		arg_31_0:closeAllWithoutFourMainWindow()

		local var_31_1 = xyd.WindowManager.get():getWindow("main_scene_middle")

		if var_31_1 then
			var_31_1:playGuide()
		end
	elseif var_31_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_SIX then
		if xyd.WindowManager.get():isWindowOpen("guide_only_dialog") then
			xyd.WindowManager.get():closeWindow("guide")
		end

		local var_31_2 = false
		local var_31_3
		local var_31_4 = cc.p(0, 0)
		local var_31_5 = xyd.StoryData.get():getGuideID()
		local var_31_6 = {
			callback = function()
				arg_31_0:playGuide()
			end
		}
		local var_31_7 = xyd.WindowManager.get():openWindow("guide_only_dialog", var_31_6)

		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_SEVEN)
		arg_31_0.player:sendOperationLog(xyd.StatID.ID_JINJIE_7)
	elseif var_31_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_SEVEN then
		local var_31_8 = arg_31_0:nodeByName("close")
		local var_31_9 = var_31_8:getPositionX()
		local var_31_10 = var_31_8:getPositionY()

		xyd.WindowManager.get():closeWindow("guide")
		xyd.WindowManager.get():openWindow("guide")

		local var_31_11 = xyd.WindowManager.get():getWindow("guide")
		local var_31_12 = var_31_11:convertToNodeSpace(var_31_8:getParent():convertToWorldSpace(cc.p(var_31_9, var_31_10)))

		var_31_11:addNode()
		var_31_11:setStencil(var_31_8:getContentSize().width, var_31_8:getContentSize().height, var_31_12.x, var_31_12.y, 2, {
			position = {
				1000,
				300
			}
		})
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_EIGHT)
		arg_31_0.player:sendOperationLog(xyd.StatID.ID_JINJIE_8)
	elseif var_31_0 < xyd.GuideStoryType.LEVELUP_WINDOW_GUIDE_END and arg_31_0.player.lev < 10 then
		local var_31_13 = arg_31_0:nodeByName("close")
		local var_31_14 = var_31_13:getPositionX()
		local var_31_15 = var_31_13:getPositionY()

		xyd.WindowManager.get():closeWindow("guide")
		xyd.WindowManager.get():openWindow("guide")

		local var_31_16 = xyd.WindowManager.get():getWindow("guide")
		local var_31_17 = var_31_16:convertToNodeSpace(var_31_13:getParent():convertToWorldSpace(cc.p(var_31_14, var_31_15)))

		var_31_16:addNode()
		var_31_16:setStencil(var_31_13:getContentSize().width, var_31_13:getContentSize().height, var_31_17.x, var_31_17.y, 2, {
			position = {
				1000,
				550
			}
		})
	end
end

function var_0_0.closeAllWithoutFourMainWindow(arg_33_0)
	local var_33_0 = {}
	local var_33_1 = xyd.WindowManager.get():getWindowHistory()

	for iter_33_0 = 1, #var_33_1 do
		local var_33_2 = var_33_1[iter_33_0]

		if var_33_2.name ~= var_0_7 and var_33_2.name ~= var_0_8 and var_33_2.name ~= var_0_9 and var_33_2.name ~= var_0_10 then
			table.insert(var_33_0, var_33_2.name)
		end
	end

	for iter_33_1 = 1, #var_33_0 do
		xyd.WindowManager.get():closeWindow(var_33_0[iter_33_1])
	end
end

function var_0_0.addFuncID(arg_34_0, arg_34_1)
	if not arg_34_0.funcID then
		arg_34_0.funcID = arg_34_1.funcID
	end
end

function var_0_0.willClose(arg_35_0, arg_35_1)
	if arg_35_0.funcID and arg_35_0.funcID ~= 0 then
		local var_35_0 = {
			funcID = arg_35_0.funcID
		}

		xyd.WindowManager.get():openWindow("function_show", var_35_0)
	end
end

return var_0_0
