require("config")
require("cocos.init")
require("framework.init")

local var_0_0 = require("framework.scheduler")
local var_0_1 = "fonts/main_font.ttf"
local var_0_2 = 1
local var_0_3 = 1000
local var_0_4 = 600
local var_0_5 = 1280
local var_0_6 = 720
local var_0_7 = {}

function var_0_7.get(arg_1_0)
	if not var_0_7.INSTANCE then
		var_0_7.INSTANCE = setmetatable({}, {
			__index = var_0_7
		})
	end

	return var_0_7.INSTANCE
end

function var_0_7.init(arg_2_0)
	display.addSpriteFrames("images/loading_games/loading_games.plist", "images/loading_games/loading_games.png")

	arg_2_0.position = cc.p(850, 300)
	arg_2_0.isShowAction = true
	arg_2_0.countAnimation = 0

	arg_2_0:loadHeroTable()

	arg_2_0.tableID = 1
	arg_2_0.children_ = {}

	arg_2_0:parseChildren_()

	arg_2_0.__layer = cc.Node:create()

	arg_2_0:setupScreen()
	arg_2_0.__layer:schedule(function()
		if not arg_2_0.isShowAction then
			arg_2_0:closeAction()
		end
	end, 7)
end

function var_0_7.parseChildren_(arg_4_0, arg_4_1)
	if not arg_4_1 then
		arg_4_0.__root = cc.CSLoader:createNode("windows/hero_show/hero_show_main.csb")
		arg_4_1 = arg_4_0.__root
	end

	arg_4_0.children_[arg_4_1:getName()] = arg_4_1

	for iter_4_0, iter_4_1 in ipairs(arg_4_1:getChildren()) do
		if iter_4_1 ~= nil then
			arg_4_0:parseChildren_(iter_4_1)
		end
	end
end

function var_0_7.nodeByName(arg_5_0, arg_5_1)
	return arg_5_0.children_[arg_5_1]
end

function var_0_7.clear(arg_6_0)
	arg_6_0.__root:removeSelf()

	arg_6_0.__root = nil
	arg_6_0.children_ = {}
	arg_6_0.isShowAction = true
	arg_6_0.countAnimation = 0
	arg_6_0.tableID = arg_6_0.tableID % #heroTable + 1
end

function var_0_7.play(arg_7_0)
	arg_7_0:parseChildren_()
	arg_7_0.__layer:addChild(arg_7_0.__root)
	arg_7_0:layout()
	arg_7_0:addBlockLayer()
	arg_7_0:animations()
	arg_7_0:playMusic()
end

function var_0_7.playMusic(arg_8_0)
	if not audio.isMusicPlaying() then
		audio.playMusic("sound/loading.ogg", true)
	end
end

function var_0_7.layout(arg_9_0)
	arg_9_0:nodeByName("text_tips"):setString(__("HERO_SHOW_SKILL_TIPS"))
	arg_9_0:initName()
	arg_9_0:initHeroDesc()
	arg_9_0:initHeroCard()
	arg_9_0:nodeByName("skill_desc"):setLocalZOrder(11)
end

function var_0_7.animations(arg_10_0)
	arg_10_0:nodeByName("desc_container"):setVisible(false)
	arg_10_0:nodeByName("name_container"):setVisible(false)
	arg_10_0:nodeByName("hero_card"):setVisible(false)
	arg_10_0:showSelectEffect(function()
		arg_10_0:nodeByName("desc_container"):setVisible(true)
		arg_10_0:nodeByName("name_container"):setVisible(true)
		arg_10_0:nodeByName("hero_card"):setVisible(true)
		arg_10_0:nameAnimation()
		arg_10_0:descAnimation()
		arg_10_0:heroAnimation()
	end)
end

function var_0_7.closeAction(arg_12_0, arg_12_1)
	if arg_12_0.isShowAction then
		return
	end

	if arg_12_1 then
		arg_12_0.countAnimation = arg_12_0.countAnimation + 1

		if arg_12_0.countAnimation == 3 then
			arg_12_0:clear()
			arg_12_0:play()

			return
		end
	end

	local var_12_0 = true

	arg_12_0:descAnimation(var_12_0)
	arg_12_0:nameAnimation(var_12_0)
	arg_12_0:heroAnimation(var_12_0)
end

function var_0_7.showSelectEffect(arg_13_0, arg_13_1)
	local var_13_0 = "skeletons/ui_effect/zhunxing/zhunxing"
	local var_13_1 = sp.SkeletonAnimation:create(var_13_0 .. ".json", var_13_0 .. ".atlas", 0.5)
	local var_13_2 = display.newNode()

	var_13_2:size(100, 100)
	var_13_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_13_2:addTo(arg_13_0:nodeByName("container"), 120)
	var_13_1:align(display.CENTER, var_13_2:getWidth() / 2, var_13_2:getHeight() / 2):addTo(var_13_2)
	var_13_1:registerSpineEventHandler(function(arg_14_0)
		var_13_1:unregisterSpineEventHandler(2)
		arg_13_1()
	end, 2)
	var_13_1:setAnimation(0, "texiao", false)
	var_13_1:setTouchSwallowEnabled(false)

	local var_13_3 = cc.p(arg_13_0:nodeByName("container"):convertToNodeSpace(cc.p(arg_13_0.position)))

	var_13_2:pos(var_13_3.x, var_13_3.y + 100)
end

function var_0_7.initName(arg_15_0)
	local var_15_0 = __heroTable("name", arg_15_0.tableID)

	if not var_15_0 then
		return
	end

	local var_15_1 = string.utf8len(var_15_0)

	arg_15_0.nameLabels = {}

	local var_15_2 = 0
	local var_15_3 = 0
	local var_15_4 = 0
	local var_15_5 = display.newNode()

	var_15_5:addTo(arg_15_0:nodeByName("name_container"))

	for iter_15_0 = 1, var_15_1 do
		local var_15_6 = arg_15_0:utf8str(var_15_0, iter_15_0, 1)
		local var_15_7 = arg_15_0:createTextLabel(var_15_6, 56, nil, cc.c3b(251, 168, 198))

		var_15_7:enableOutline(cc.c4b(96, 24, 110, 255), 3)
		var_15_7:setAnchorPoint(cc.p(0.5, 0))
		var_15_7:addTo(var_15_5)
		var_15_7:setPosition(cc.p(var_15_2, 0))
		var_15_7:setVisible(false)
		var_15_7:setScale(3)

		local var_15_8 = var_15_7:getContentSize()

		var_15_4 = var_15_8.width
		var_15_2 = var_15_2 + var_15_4 + 10
		var_15_3 = var_15_8.height

		table.insert(arg_15_0.nameLabels, var_15_7)
	end

	var_15_5:setContentSize(var_15_2 - var_15_4, var_15_3)
	var_15_5:setAnchorPoint(cc.p(0.5, 0.5))

	local var_15_9 = arg_15_0:nodeByName("name_container"):getContentSize()

	var_15_5:setPosition(cc.p(var_15_9.width / 2, var_15_9.height / 2))
end

function var_0_7.createTextLabel(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4)
	local var_16_0 = {
		text = arg_16_1,
		align = cc.ui.TEXT_ALIGN_LEFT,
		color = arg_16_4 or cc.c3b(255, 255, 255),
		size = arg_16_2 or 24,
		UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
		font = var_0_1
	}
	local var_16_1 = cc.ui.UILabel.new(var_16_0)

	if arg_16_3 then
		var_16_1:setDimensions(arg_16_3, 0)
	end

	return var_16_1
end

function var_0_7.nameAnimation(arg_17_0, arg_17_1)
	if not arg_17_1 then
		if #arg_17_0.nameLabels <= 0 then
			return
		end

		local var_17_0 = var_0_2 / #arg_17_0.nameLabels

		for iter_17_0 = 1, #arg_17_0.nameLabels do
			local var_17_1 = cc.Sequence:create({
				cc.DelayTime:create(0.5 + var_17_0 * (iter_17_0 - 1)),
				cc.CallFunc:create(function()
					arg_17_0.nameLabels[iter_17_0]:setVisible(true)
				end),
				cc.ScaleTo:create(0.5, 1),
				cc.CallFunc:create(function()
					if iter_17_0 == #arg_17_0.nameLabels then
						arg_17_0:initNameBgEffect()
					end
				end)
			})

			arg_17_0.nameLabels[iter_17_0]:runAction(var_17_1)
		end
	else
		local var_17_2 = arg_17_0:nodeByName("name_container"):getPositionY()

		arg_17_0:moveFadeOutAction(0, var_17_2, arg_17_0:nodeByName("name_container"), function()
			arg_17_0:closeAction(true)
		end)
	end
end

function var_0_7.initNameBgEffect(arg_21_0)
	local var_21_0 = "skeletons/ui_effect/show_backgroud/show_backgroud"
	local var_21_1 = sp.SkeletonAnimation:create(var_21_0 .. ".json", var_21_0 .. ".atlas", 1)
	local var_21_2 = display.newNode()

	var_21_2:size(100, 100)
	var_21_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_21_2:addTo(arg_21_0:nodeByName("name_container"), 120)
	var_21_1:align(display.CENTER, var_21_2:getWidth() / 2, var_21_2:getHeight() / 2):addTo(var_21_2)
	var_21_1:setAnimation(0, "texiao", false)
	var_21_1:setTouchSwallowEnabled(false)

	local var_21_3 = arg_21_0:nodeByName("name_container"):getContentSize()

	var_21_2:setPosition(cc.p(var_21_3.width / 2, var_21_3.height / 2))
end

function var_0_7.initHeroDesc(arg_22_0)
	local var_22_0 = arg_22_0:nodeByName("desc_container")
	local var_22_1 = __heroTable("des", arg_22_0.tableID)
	local var_22_2 = arg_22_0:createTextLabel(var_22_1, 24, 500)

	var_22_2:addTo(var_22_0)
	var_22_2:setAnchorPoint(cc.p(0, 1))
	var_22_2:setPosition(cc.p(arg_22_0:nodeByName("hero_desc_node"):getPosition()))
	var_22_2:enableOutline(cc.c4b(96, 24, 110, 255), 1)

	local var_22_3 = __heroTable("skill_name", arg_22_0.tableID)

	arg_22_0:nodeByName("skill_name"):setString(var_22_3)

	local var_22_4 = arg_22_0:nodeByName("skill_desc"):getContentSize()

	arg_22_0.skillDeslist = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_22_4.width, var_22_4.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_22_0:nodeByName("skill_desc")):onScroll(handler(arg_22_0, arg_22_0.scrollListener))

	local var_22_5 = __heroTable("skill_des", arg_22_0.tableID)
	local var_22_6 = arg_22_0:createTextLabel(var_22_5, 24, var_22_4.width)

	var_22_6:setAnchorPoint(cc.p(0, 0))
	var_22_6:enableOutline(cc.c4b(96, 24, 110, 255), 1)

	local var_22_7 = display.newNode()
	local var_22_8 = arg_22_0.skillDeslist:newItem()
	local var_22_9 = display.newNode()

	var_22_6:addTo(var_22_9)

	local var_22_10 = var_22_6:getContentSize().height

	var_22_9:setContentSize(var_22_4.width, var_22_10)
	var_22_9:addTo(var_22_7)
	var_22_7:setContentSize(var_22_4.width, var_22_10)
	var_22_8:addContent(var_22_7)
	var_22_8:setItemSize(var_22_4.width, var_22_10)
	arg_22_0.skillDeslist:addItem(var_22_8)
	arg_22_0.skillDeslist:reload()
	arg_22_0:setSpriteBorder(arg_22_0:nodeByName("energy_skill_icon"), __heroTable("skill_icon", arg_22_0.tableID))
end

function var_0_7.setSpriteBorder(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = arg_23_0:newSprite(arg_23_2)
	local var_23_1 = arg_23_1:getContentSize().width
	local var_23_2 = arg_23_1:getContentSize().height
	local var_23_3 = arg_23_0:newSprite("images/icon_mask2.png")

	var_23_3:setPosition(var_23_1 / 2, var_23_2 / 2)
	var_23_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_23_3:setScale(var_23_2 / var_23_3:getHeight())

	local var_23_4 = var_23_2 / var_23_3:getHeight()
	local var_23_5 = cc.ClippingNode:create()

	var_23_5:setStencil(var_23_3)
	var_23_5:setInverted(true)
	var_23_5:setAlphaThreshold(0)
	arg_23_1:addChild(var_23_5)
	var_23_5:addChild(var_23_0)
	var_23_0:setPosition(var_23_1 / 2, var_23_2 / 2)
	var_23_0:setAnchorPoint(cc.p(0.5, 0.5))

	local var_23_6 = var_23_2 / var_23_0:getHeight()

	var_23_0:setScale(var_23_6)
	var_23_5:setLocalZOrder(-1)

	local var_23_7 = arg_23_0:newSprite("images/border-white.png")

	var_23_7:scale((var_23_7:getWidth() - 5) / var_23_1)
	var_23_7:addTo(arg_23_1)
	var_23_7:align(display.CENTER, var_23_1 / 2, var_23_2 / 2)
end

function var_0_7.scrollListener(arg_24_0, arg_24_1)
	if arg_24_1.name == "began" then
		arg_24_0.scrollViewMoved_ = false
		arg_24_0.prevX_ = arg_24_1.x
		arg_24_0.prevY_ = arg_24_1.y
	elseif arg_24_1.name == "moved" and 5 <= math.abs(arg_24_1.y - arg_24_0.prevY_) then
		arg_24_0.scrollViewMoved_ = true
	end
end

function var_0_7.initHeroCard(arg_25_0)
	local var_25_0 = arg_25_0:newSprite(__heroTable("card", arg_25_0.tableID))
	local var_25_1 = var_25_0:getContentSize()

	var_25_0:setAnchorPoint(cc.p(0.5, 0))
	var_25_0:addTo(arg_25_0:nodeByName("hero_card"))

	local var_25_2 = arg_25_0:newSprite(__heroTable("card", arg_25_0.tableID))

	var_25_2:setAnchorPoint(cc.p(0.5, 0))
	var_25_2:addTo(arg_25_0:nodeByName("hero_card"))

	local var_25_3 = arg_25_0:nodeByName("hero_card"):getContentSize()
	local var_25_4 = cc.p(arg_25_0:nodeByName("hero_card"):getPosition())
	local var_25_5 = 0
	local var_25_6 = 0
	local var_25_7 = cc.p(arg_25_0:nodeByName("hero_card"):convertToNodeSpace(cc.p(0, 0)))
	local var_25_8 = cc.p(var_25_3.width / 2 + var_25_5 / 2, var_25_7.y + var_25_6)

	var_25_0:setPosition(cc.p(var_0_5 - var_25_4.x, var_25_8.y))

	arg_25_0.heroSprite = var_25_0

	var_25_2:setPosition(cc.p(var_25_8.x, var_25_8.y))

	arg_25_0.heroSprite1 = var_25_2
end

function var_0_7.heroAnimation(arg_26_0, arg_26_1)
	if not arg_26_0.heroSprite or not arg_26_0.heroSprite1 then
		return
	end

	if not arg_26_1 then
		local var_26_0 = cc.p(arg_26_0.heroSprite1:getPosition())

		arg_26_0.heroSprite:setColor(cc.c4f(0, 0, 0, 1))
		arg_26_0.heroSprite1:setVisible(false)
		arg_26_0.heroSprite:runActionOnce(cc.MoveTo:create(0.5, cc.p(var_26_0.x, var_26_0.y)), false, function()
			arg_26_0.heroSprite:setVisible(false)
			arg_26_0.heroSprite1:setVisible(true)
			arg_26_0:moveFadeInAction(var_26_0.x, var_26_0.y, arg_26_0.heroSprite1, function()
				arg_26_0.isShowAction = false
			end, 1)
		end)
	else
		local var_26_1 = cc.p(arg_26_0.heroSprite1:getPosition())

		arg_26_0:moveFadeOutAction(var_0_5, var_26_1.y, arg_26_0.heroSprite1, function()
			arg_26_0:closeAction(true)
		end)
	end
end

function var_0_7.descAnimation(arg_30_0, arg_30_1)
	local var_30_0 = arg_30_0:nodeByName("desc_container")
	local var_30_1 = var_30_0:getContentSize()
	local var_30_2 = cc.p(var_30_0:getPosition())

	if not arg_30_1 then
		var_30_0:setPosition(cc.p(0, var_30_2.y))
		arg_30_0:moveFadeInAction(var_30_2.x, var_30_2.y, var_30_0, function()
			arg_30_0:nodeByName("desc_bg"):setVisible(false)
			arg_30_0:nodeByName("main_bg"):setVisible(true)
		end)
	else
		arg_30_0:nodeByName("desc_bg"):setVisible(true)
		arg_30_0:nodeByName("main_bg"):setVisible(false)
		arg_30_0:moveFadeOutAction(0, var_30_2.y, var_30_0, function()
			arg_30_0:closeAction(true)
		end)
	end
end

function var_0_7.moveFadeInAction(arg_33_0, arg_33_1, arg_33_2, arg_33_3, arg_33_4, arg_33_5, arg_33_6)
	local var_33_0 = arg_33_5 or 0.4
	local var_33_1 = arg_33_6 or 0.5

	arg_33_0:widgetSet(arg_33_3)
	arg_33_3:setCascadeOpacityEnabled(true)
	arg_33_3:setOpacity(0)

	local var_33_2 = cc.Spawn:create(cc.FadeIn:create(var_33_0), cc.MoveTo:create(var_33_1, cc.p(arg_33_1, arg_33_2)))

	arg_33_3:runActionOnce(var_33_2, false, arg_33_4)
end

function var_0_7.moveFadeOutAction(arg_34_0, arg_34_1, arg_34_2, arg_34_3, arg_34_4)
	arg_34_0:widgetSet(arg_34_3)
	arg_34_3:setCascadeOpacityEnabled(true)

	local var_34_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_34_1, arg_34_2)))

	arg_34_3:runActionOnce(var_34_0, true, arg_34_4)
end

function var_0_7.widgetSet(arg_35_0, arg_35_1)
	for iter_35_0, iter_35_1 in ipairs(arg_35_1:getChildren()) do
		if iter_35_1 ~= nil then
			iter_35_1:setCascadeOpacityEnabled(true)
			arg_35_0:widgetSet(iter_35_1)
		end
	end
end

function var_0_7.newSprite(arg_36_0, arg_36_1)
	local var_36_0 = "#" .. arg_36_1

	if cc.SpriteFrameCache:getInstance():getSpriteFrame(arg_36_1) ~= nil then
		return display.newSprite(var_36_0)
	end

	return display.newSprite(arg_36_1)
end

function var_0_7.utf8str(arg_37_0, arg_37_1, arg_37_2, arg_37_3)
	local function var_37_0(arg_38_0)
		if not arg_38_0 then
			return 0
		elseif arg_38_0 > 240 then
			return 4
		elseif arg_38_0 > 225 then
			return 3
		elseif arg_38_0 > 192 then
			return 2
		else
			return 1
		end
	end

	local var_37_1 = 1

	while arg_37_2 > 1 do
		local var_37_2 = string.byte(arg_37_1, var_37_1)

		var_37_1 = var_37_1 + var_37_0(var_37_2)
		arg_37_2 = arg_37_2 - 1
	end

	local var_37_3 = var_37_1

	while arg_37_3 > 0 do
		if var_37_3 > #arg_37_1 then
			var_37_3 = #arg_37_1

			break
		end

		local var_37_4 = string.byte(arg_37_1, var_37_3)

		var_37_3 = var_37_3 + var_37_0(var_37_4)
		arg_37_3 = arg_37_3 - 1
	end

	return arg_37_1:sub(var_37_1, var_37_3 - 1)
end

function var_0_7.loadHeroTable(arg_39_0)
	if __skill == nil then
		local var_39_0 = {}
		local var_39_1 = require("data.tables.load_hero")

		heroTable = {}

		for iter_39_0, iter_39_1 in pairs(var_39_1.rows) do
			local var_39_2 = {
				name = iter_39_1[2],
				des = iter_39_1[3],
				skill_name = iter_39_1[5],
				skill_des = iter_39_1[6],
				skill_icon = iter_39_1[7],
				card = iter_39_1[8]
			}

			table.insert(heroTable, var_39_2)
		end

		function __heroTable(arg_40_0, arg_40_1)
			return heroTable[arg_40_1][arg_40_0] or arg_40_0
		end
	end
end

function var_0_7.setParent(arg_41_0, arg_41_1)
	if not arg_41_0.__layer then
		return
	end

	arg_41_1:addChild(arg_41_0.__layer)
end

function var_0_7.addBlockLayer(arg_42_0, arg_42_1, arg_42_2, arg_42_3, arg_42_4)
	if arg_42_1 == nil then
		arg_42_1 = cc.c4b(0, 0, 0, 200)
	end

	arg_42_0.blockLayer_ = display.newColorLayer(arg_42_1)

	local var_42_0 = arg_42_0.__root:convertToWorldSpace(cc.p(0, 0))

	arg_42_0.blockLayer_:pos(-var_42_0.x, -var_42_0.y):addTo(arg_42_0.__root, -1)
	arg_42_0.blockLayer_:setContentSize(var_0_5, var_0_6)
end

function var_0_7.setProgress_(arg_43_0, arg_43_1)
	if arg_43_0.__progressBar == nil then
		arg_43_0.__bottomBack = ccui.Scale9Sprite:createWithSpriteFrameName("images/loading_games/bottom_back1.png", {
			width = 60,
			height = 69,
			x = 20,
			y = 0
		})

		arg_43_0.__bottomBack:size(1280, 70)
		arg_43_0.__bottomBack:addTo(arg_43_0.__layer, 2)
		arg_43_0.__bottomBack:align(display.LEFT_BOTTOM, 0, 0)

		local var_43_0 = arg_43_0:newSprite("images/loading_games/loading_bar.png")

		arg_43_0.__progressBar = cc.ProgressTimer:create(var_43_0)

		arg_43_0.__progressBar:setType(1)
		arg_43_0.__progressBar:setMidpoint({
			x = 0,
			y = 0
		})
		arg_43_0.__progressBar:setBarChangeRate({
			x = 1,
			y = 0
		})
		arg_43_0.__progressBar:setPercentage(0)
		arg_43_0.__progressBar:setAnchorPoint({
			x = 0.5,
			y = 0.5
		})

		arg_43_0.__progressBackground = ccui.Scale9Sprite:createWithSpriteFrameName("images/loading_games/loading_bar_back.png", {
			width = 40,
			height = 24,
			x = 15,
			y = 0
		})

		arg_43_0.__progressBackground:size(var_43_0:getWidth(), var_43_0:getHeight())
		arg_43_0.__progressBackground:addTo(arg_43_0.__layer, 3)
		arg_43_0.__progressBackground:align(display.LEFT_CENTER, 50, 30)
		arg_43_0.__progressBar:pos(var_43_0:getWidth() / 2, var_43_0:getHeight() / 2)
		arg_43_0.__progressBackground:addChild(arg_43_0.__progressBar)
	end

	arg_43_0.__progressBar:setPercentage(arg_43_1 * 100)
end

function var_0_7.prepareProgressLabel_(arg_44_0)
	if arg_44_0.progressLabel_ == nil then
		arg_44_0.progressLabel_ = cc.Label:createWithTTF("", var_0_1, 24)

		arg_44_0.progressLabel_:enableShadow()
		arg_44_0.progressLabel_:setAnchorPoint({
			x = 0,
			y = 0.5
		})
		arg_44_0.progressLabel_:setPosition({
			x = 1020,
			y = 30
		})
		arg_44_0.progressLabel_:addTo(arg_44_0.__layer, 3)
	end
end

function var_0_7.setDownloadProgressMessage_(arg_45_0, arg_45_1, arg_45_2)
	local var_45_0 = string.format("%.1fM", arg_45_1 / 1024 / 1024)
	local var_45_1 = string.format("%.1fM", arg_45_2 / 1024 / 1024)

	arg_45_0:prepareProgressLabel_()
	arg_45_0.progressLabel_:setString(string.format(__("DOWNLOAD_PROGRESS_GAME"), var_45_0, var_45_1))
end

function var_0_7.setUnzipProgressMessage_(arg_46_0, arg_46_1)
	arg_46_0:prepareProgressLabel_()
	arg_46_0.progressLabel_:setString(__("UNZIP_PROGRESS_GAME"))
end

function var_0_7.setDownloadSpeedMessage_(arg_47_0, arg_47_1, arg_47_2)
	if arg_47_0.downloadSpeedLabel_ == nil then
		arg_47_0.downloadSpeedLabel_ = cc.Label:createWithTTF("", var_0_1, 24)

		arg_47_0.downloadSpeedLabel_:enableShadow()
		arg_47_0.downloadSpeedLabel_:setAnchorPoint({
			x = 1,
			y = 0.5
		})
		arg_47_0.downloadSpeedLabel_:setPosition({
			x = 1260,
			y = 30
		})
		arg_47_0.downloadSpeedLabel_:addTo(arg_47_0.__layer, 3)
	end

	arg_47_0.downloadSpeedLabel_:setVisible(not arg_47_2)
	arg_47_0.downloadSpeedLabel_:setString(string.format("%.2fKB/S", arg_47_1))
end

function var_0_7.beforeDownLoadCompleted(arg_48_0)
	return
end

function var_0_7.downLoadCompleted(arg_49_0, arg_49_1)
	arg_49_0:cleanUp()

	if arg_49_1 then
		arg_49_1()
	end
end

function var_0_7.cleanUp(arg_50_0)
	__heroTable = nil
	package.loaded["data.tables.load_hero"] = nil

	arg_50_0.__layer:setVisible(false)
	transition.stopTarget(arg_50_0.__layer)
end

function var_0_7.setupScreen(arg_51_0)
	local var_51_0 = cc.Director:getInstance()
	local var_51_1 = var_51_0:getOpenGLView()
	local var_51_2 = var_51_1:getFrameSize()
	local var_51_3 = 0
	local var_51_4 = var_51_2.width / var_51_2.height < 1.5
	local var_51_5 = var_51_4 and 4 or 3

	var_51_0:setContentScaleFactor(1)
	var_51_1:setDesignResolutionSize(var_0_5, var_0_6, var_51_5)

	local var_51_6 = var_51_0:getVisibleSize()

	if var_51_4 then
		var_51_6.height = var_0_6 / var_0_5 * var_51_6.width
	end
end

return var_0_7
