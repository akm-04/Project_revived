local var_0_0 = class("HeroShowWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("framework.scheduler")
local var_0_4 = xyd.tables.hero
local var_0_5 = xyd.tables.skill
local var_0_6 = import("app.model.Hero")
local var_0_7 = 1
local var_0_8 = 1000
local var_0_9 = 600

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.position = arg_1_2.position or cc.p(0, 0)
	arg_1_0.tableID = arg_1_2.table_id or 10001002
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.isShowAction = true
	arg_1_0.countAnimation = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 100))
	arg_3_0:animations()
	arg_3_0:playSound()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:initName()
	arg_4_0:initHeroDesc()
	arg_4_0:initHeroCard()

	local var_4_0 = display.newNode()

	var_4_0:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	var_4_0:setAnchorPoint(cc.p(0, 0))
	var_4_0:addTo(arg_4_0:nodeByName("desc_container"))
	var_4_0:setLocalZOrder(10)

	local var_4_1 = arg_4_0:nodeByName("desc_container"):convertToWorldSpace(cc.p(0, 0))

	var_4_0:setPosition(cc.p(-var_4_1.x, -var_4_1.y))
	var_4_0:setTouchEnabled(true)
	var_4_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			return true
		elseif arg_5_0.name == "ended" and not arg_4_0.isShowAction then
			var_4_0:setTouchEnabled(false)
			arg_4_0:closeAction(true)

			return true
		end
	end)
	arg_4_0:nodeByName("skill_desc"):setLocalZOrder(11)
end

function var_0_0.playSound(arg_6_0)
	local var_6_0 = var_0_4:dialogSounds(arg_6_0.tableID)
	local var_6_1 = var_0_4:soundTimes(arg_6_0.tableID)

	if var_6_0[1] ~= "" and var_6_1[1] > 0 then
		local var_6_2 = {
			arg_6_0.tableID
		}

		xyd.AssetDownload.get():preloadCharacterSound(var_6_2, function()
			return
		end, true)
		dump("play right")
		arg_6_0.selfPlayer:playHeroSound(var_6_0[1], var_6_1[1], function()
			return
		end)
	end
end

function var_0_0.animations(arg_9_0)
	arg_9_0:nodeByName("desc_container"):setVisible(false)
	arg_9_0:nodeByName("name_container"):setVisible(false)
	arg_9_0:nodeByName("cv_container"):setVisible(false)
	arg_9_0:nodeByName("hero_card"):setVisible(false)
	arg_9_0.blockLayer_:setVisible(false)
	arg_9_0:showSelectEffect(function()
		arg_9_0.blockLayer_:setVisible(true)
		arg_9_0:nodeByName("desc_container"):setVisible(true)
		arg_9_0:nodeByName("name_container"):setVisible(true)
		arg_9_0:nodeByName("hero_card"):setVisible(true)
		arg_9_0:nameAnimation()
		arg_9_0:descAnimation()
		arg_9_0:heroAnimation()
	end)
end

function var_0_0.showSelectEffect(arg_11_0, arg_11_1)
	local var_11_0 = "skeletons/ui_effect/zhunxing/zhunxing"
	local var_11_1 = var_0_2.new(var_11_0 .. ".json", var_11_0 .. ".atlas", 0.5)
	local var_11_2 = display.newNode()

	var_11_2:size(100, 100)
	var_11_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_11_2:addTo(arg_11_0:nodeByName("container"), 120)
	var_11_1:align(display.CENTER, var_11_2:getWidth() / 2, var_11_2:getHeight() / 2):addTo(var_11_2)
	var_11_1:play(arg_11_1, false)
	var_11_1:setTouchSwallowEnabled(false)

	local var_11_3 = cc.p(arg_11_0:nodeByName("container"):convertToNodeSpace(cc.p(arg_11_0.position)))

	var_11_2:pos(var_11_3.x, var_11_3.y + 100)
end

function var_0_0.initName(arg_12_0)
	local var_12_0 = var_0_4:name(arg_12_0.tableID)

	if not var_12_0 then
		return
	end

	local var_12_1 = xyd.utf8len(var_12_0)

	arg_12_0.nameLabels = {}

	local var_12_2 = 0
	local var_12_3 = 0
	local var_12_4 = 0
	local var_12_5 = display.newNode()

	var_12_5:addTo(arg_12_0:nodeByName("name_container"))

	for iter_12_0 = 1, var_12_1 do
		local var_12_6 = xyd.utf8str(var_12_0, iter_12_0, 1)
		local var_12_7 = arg_12_0:createTextLabel(var_12_6, 26, nil, cc.c3b(255, 255, 255))

		var_12_7:setAnchorPoint(cc.p(0, 0))
		var_12_7:addTo(var_12_5)
		var_12_7:setPosition(cc.p(var_12_2 - 10, 5))
		var_12_7:setVisible(false)
		var_12_7:setScale(1)

		local var_12_8 = var_12_7:getContentSize()

		var_12_4 = var_12_8.width
		var_12_2 = var_12_2 + var_12_4
		var_12_3 = var_12_8.height

		table.insert(arg_12_0.nameLabels, var_12_7)
	end

	var_12_5:setContentSize(var_12_2 - var_12_4, var_12_3)
	var_12_5:setAnchorPoint(cc.p(0, 0.5))

	local var_12_9 = arg_12_0:nodeByName("name_container"):getContentSize()

	var_12_5:setPosition(cc.p(var_12_9.width / 2, var_12_9.height / 2))
end

function var_0_0.initCv(arg_13_0)
	local var_13_0 = "CV:" .. var_0_4:getCV(arg_13_0.tableID)

	if not var_13_0 then
		return
	end

	local var_13_1 = xyd.utf8len(var_13_0)

	arg_13_0.cvLabels = {}

	local var_13_2 = 0
	local var_13_3 = 0
	local var_13_4 = 0
	local var_13_5 = display.newNode()

	var_13_5:addTo(arg_13_0:nodeByName("cv_container"))

	for iter_13_0 = 1, var_13_1 do
		local var_13_6 = xyd.utf8str(var_13_0, iter_13_0, 1)
		local var_13_7 = arg_13_0:createTextLabel(var_13_6, 32, nil, cc.c3b(251, 168, 198))

		var_13_7:enableOutline(cc.c4b(96, 24, 110, 255), 2)
		var_13_7:setAnchorPoint(cc.p(0.5, 0))
		var_13_7:addTo(var_13_5)
		var_13_7:setPosition(cc.p(var_13_2, 0))
		var_13_7:setVisible(false)
		var_13_7:setScale(2)

		local var_13_8 = var_13_7:getContentSize()

		var_13_4 = var_13_8.width
		var_13_2 = var_13_2 + var_13_4 + 10
		var_13_3 = var_13_8.height

		table.insert(arg_13_0.cvLabels, var_13_7)
	end

	var_13_5:setContentSize(var_13_2 - var_13_4, var_13_3)
	var_13_5:setAnchorPoint(cc.p(0.5, 0.5))

	local var_13_9 = arg_13_0:nodeByName("cv_container"):getContentSize()

	var_13_5:setPosition(cc.p(var_13_9.width / 2, var_13_9.height / 2))
end

function var_0_0.createTextLabel(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4)
	local var_14_0 = {
		text = arg_14_1,
		align = cc.ui.TEXT_ALIGN_LEFT,
		color = arg_14_4 or cc.c3b(255, 255, 255),
		size = arg_14_2 or 24
	}
	local var_14_1 = xyd.AssetLoader.get():loadLabel(var_14_0)

	if arg_14_3 then
		var_14_1:setDimensions(arg_14_3, 0)
	end

	return var_14_1
end

function var_0_0.nameAnimation(arg_15_0, arg_15_1)
	if not arg_15_1 then
		if #arg_15_0.nameLabels <= 0 then
			return
		end

		local var_15_0 = var_0_7 / #arg_15_0.nameLabels

		for iter_15_0 = 1, #arg_15_0.nameLabels do
			local var_15_1 = cc.Sequence:create({
				cc.DelayTime:create(var_15_0 * (iter_15_0 - 1)),
				cc.CallFunc:create(function()
					arg_15_0.nameLabels[iter_15_0]:setVisible(true)
				end),
				cc.ScaleTo:create(0.5, 1)
			})
			local var_15_2

			if iter_15_0 == #arg_15_0.nameLabels then
				function var_15_2()
					arg_15_0:initNameBgEffect()
				end
			end

			arg_15_0.nameLabels[iter_15_0]:runActionOnce(var_15_1, false, var_15_2, 0.5)
		end
	else
		local var_15_3 = arg_15_0:nodeByName("name_container"):getPositionY()

		arg_15_0:moveFadeOutAction(0, var_15_3, arg_15_0:nodeByName("name_container"), function()
			arg_15_0:closeAction(true)
		end)
	end
end

function var_0_0.initNameBgEffect(arg_19_0)
	local var_19_0 = "skeletons/ui_effect/show_backgroud/show_backgroud"
	local var_19_1 = var_0_2.new(var_19_0 .. ".json", var_19_0 .. ".atlas", 1)
	local var_19_2 = display.newNode()

	var_19_2:size(100, 100)
	var_19_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_19_2:addTo(arg_19_0:nodeByName("name_container"), 120)
	var_19_1:align(display.CENTER, var_19_2:getWidth() / 2, var_19_2:getHeight() / 2):addTo(var_19_2)
	var_19_1:play(nil, false)
	var_19_1:setTouchSwallowEnabled(false)

	local var_19_3 = arg_19_0:nodeByName("name_container"):getContentSize()

	var_19_2:setPosition(cc.p(var_19_3.width / 2, var_19_3.height / 2))
end

function var_0_0.initCVBgEffect(arg_20_0)
	local var_20_0 = "skeletons/ui_effect/show_backgroud/show_backgroud"
	local var_20_1 = var_0_2.new(var_20_0 .. ".json", var_20_0 .. ".atlas", 1)
	local var_20_2 = display.newNode()

	var_20_2:size(100, 100)
	var_20_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_20_2:addTo(arg_20_0:nodeByName("cv_container"), 120)
	var_20_1:align(display.CENTER, var_20_2:getWidth() / 2, var_20_2:getHeight() / 2):addTo(var_20_2)
	var_20_1:play(nil, false)
	var_20_1:setTouchSwallowEnabled(false)

	local var_20_3 = arg_20_0:nodeByName("cv_container"):getContentSize()

	var_20_2:setPosition(cc.p(var_20_3.width / 2, var_20_3.height / 2))
end

function var_0_0.initHeroDesc(arg_21_0)
	local var_21_0 = arg_21_0:nodeByName("desc_container")
	local var_21_1 = var_0_4:getDes(arg_21_0.tableID)
	local var_21_2 = arg_21_0:createTextLabel(var_21_1, 26, 460)

	var_21_2:addTo(var_21_0)
	var_21_2:setAnchorPoint(cc.p(0, 1))
	var_21_2:setPosition(cc.p(arg_21_0:nodeByName("hero_desc_node"):getPosition()))
	var_21_2:setColor(cc.c4b(58, 29, 7, 255))

	local var_21_3 = var_0_4:getSkill(arg_21_0.tableID, xyd.SKILL_INDEX.Energy)
	local var_21_4 = var_0_5:name(var_21_3)

	arg_21_0:nodeByName("skill_name"):setString(var_21_4)
	arg_21_0:nodeByName("skill_name"):enableOutline(cc.c4b(54, 23, 5, 255), 3)

	local var_21_5 = arg_21_0:nodeByName("skill_desc"):getContentSize()

	arg_21_0.skillDeslist = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_21_5.width, var_21_5.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_21_0:nodeByName("skill_desc")):onScroll(handler(arg_21_0, arg_21_0.scrollListener))

	local var_21_6 = var_0_5:desc(var_21_3)
	local var_21_7 = arg_21_0:createTextLabel(var_21_6, 24, var_21_5.width)

	var_21_7:setAnchorPoint(cc.p(0, 0))
	var_21_7:enableOutline(cc.c4b(78, 22, 9, 255), 2)

	local var_21_8 = display.newNode()
	local var_21_9 = arg_21_0.skillDeslist:newItem()
	local var_21_10 = display.newNode()

	var_21_7:addTo(var_21_10)

	local var_21_11 = var_21_7:getContentSize().height

	var_21_10:setContentSize(var_21_5.width, var_21_11)
	var_21_10:addTo(var_21_8)
	var_21_8:setContentSize(var_21_5.width, var_21_11)
	var_21_9:addContent(var_21_8)
	var_21_9:setItemSize(var_21_5.width, var_21_11)
	arg_21_0.skillDeslist:addItem(var_21_9)
	arg_21_0.skillDeslist:reload()
	xyd.setSkillBorder(arg_21_0:nodeByName("energy_skill_icon"), var_21_3, 0.8)
end

function var_0_0.scrollListener(arg_22_0, arg_22_1)
	if arg_22_1.name == "began" then
		arg_22_0.scrollViewMoved_ = false
		arg_22_0.prevX_ = arg_22_1.x
		arg_22_0.prevY_ = arg_22_1.y
	elseif arg_22_1.name == "moved" and 5 <= math.abs(arg_22_1.y - arg_22_0.prevY_) then
		arg_22_0.scrollViewMoved_ = true
	end
end

function var_0_0.initHeroCard(arg_23_0)
	local var_23_0 = xyd.SpriteLoader.new("images/home_card/" .. arg_23_0.tableID + var_0_8 .. ".png", nil, extra_params, xyd.DefaultImageType.HOME_CARD)
	local var_23_1 = var_23_0:getContentSize()

	var_23_0:setAnchorPoint(cc.p(0.5, 0))
	var_23_0:addTo(arg_23_0:nodeByName("hero_card"))

	local var_23_2 = xyd.SpriteLoader.new("images/home_card/" .. arg_23_0.tableID + var_0_8 .. ".png", nil, extra_params, xyd.DefaultImageType.HOME_CARD)

	var_23_2:setAnchorPoint(cc.p(0.5, 0))
	var_23_2:addTo(arg_23_0:nodeByName("hero_card"))

	local var_23_3 = arg_23_0:nodeByName("hero_card"):getContentSize()
	local var_23_4 = cc.p(arg_23_0:nodeByName("hero_card"):getPosition())
	local var_23_5 = xyd.tables.homeCard:x(arg_23_0.tableID)
	local var_23_6 = xyd.tables.homeCard:y(arg_23_0.tableID)
	local var_23_7 = cc.p(arg_23_0:nodeByName("hero_card"):convertToNodeSpace(cc.p(0, 0)))
	local var_23_8 = cc.p(var_23_3.width / 2 + var_23_5 / 2, var_23_7.y + var_23_6)

	var_23_0:setPosition(cc.p(xyd.STAGE_WIDTH - var_23_4.x, var_23_8.y))

	arg_23_0.heroSprite = var_23_0

	var_23_2:setPosition(cc.p(var_23_8.x, var_23_8.y))

	arg_23_0.heroSprite1 = var_23_2
end

function var_0_0.heroAnimation(arg_24_0, arg_24_1)
	if not arg_24_0.heroSprite or not arg_24_0.heroSprite1 then
		return
	end

	if not arg_24_1 then
		local var_24_0 = cc.p(arg_24_0.heroSprite1:getPosition())

		arg_24_0.heroSprite:setColor(cc.c4f(0, 0, 0, 1))
		arg_24_0.heroSprite1:setVisible(false)
		arg_24_0.heroSprite:runActionOnce(cc.MoveTo:create(0.5, cc.p(var_24_0.x, var_24_0.y)), false, function()
			arg_24_0.heroSprite:setVisible(false)
			arg_24_0.heroSprite1:setVisible(true)
			arg_24_0:moveFadeInAction(var_24_0.x, var_24_0.y, arg_24_0.heroSprite1, function()
				arg_24_0.isShowAction = false
			end, 1)
		end)
	else
		local var_24_1 = cc.p(arg_24_0.heroSprite1:getPosition())

		arg_24_0:moveFadeOutAction(xyd.STAGE_WIDTH, var_24_1.y, arg_24_0.heroSprite1, function()
			arg_24_0:closeAction(true)
		end)
	end
end

function var_0_0.descAnimation(arg_28_0, arg_28_1)
	local var_28_0 = arg_28_0:nodeByName("desc_container")
	local var_28_1 = var_28_0:getContentSize()
	local var_28_2 = cc.p(var_28_0:getPosition())

	if not arg_28_1 then
		var_28_0:setPosition(cc.p(0, var_28_2.y))
		arg_28_0:moveFadeInAction(var_28_2.x, var_28_2.y, var_28_0, function()
			arg_28_0:nodeByName("desc_bg"):setVisible(false)
			arg_28_0:nodeByName("main_bg"):setVisible(true)
		end)
	else
		arg_28_0:nodeByName("desc_bg"):setVisible(true)
		arg_28_0:nodeByName("main_bg"):setVisible(false)
		arg_28_0:moveFadeOutAction(0, var_28_2.y, var_28_0, function()
			arg_28_0:closeAction(true)
		end)
	end
end

function var_0_0.moveFadeInAction(arg_31_0, arg_31_1, arg_31_2, arg_31_3, arg_31_4, arg_31_5, arg_31_6)
	local var_31_0 = arg_31_5 or 0.4
	local var_31_1 = arg_31_6 or 0.5

	arg_31_0:widgetSet(arg_31_3)
	arg_31_3:setCascadeOpacityEnabled(true)
	arg_31_3:setOpacity(0)

	local var_31_2 = cc.Spawn:create(cc.FadeIn:create(var_31_0), cc.MoveTo:create(var_31_1, cc.p(arg_31_1, arg_31_2)))

	arg_31_3:runActionOnce(var_31_2, false, arg_31_4)
end

function var_0_0.moveFadeOutAction(arg_32_0, arg_32_1, arg_32_2, arg_32_3, arg_32_4)
	arg_32_0:widgetSet(arg_32_3)
	arg_32_3:setCascadeOpacityEnabled(true)

	local var_32_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_32_1, arg_32_2)))

	arg_32_3:runActionOnce(var_32_0, true, arg_32_4)
end

function var_0_0.widgetSet(arg_33_0, arg_33_1)
	for iter_33_0, iter_33_1 in ipairs(arg_33_1:getChildren()) do
		if iter_33_1 ~= nil then
			iter_33_1:setCascadeOpacityEnabled(true)
			arg_33_0:widgetSet(iter_33_1)
		end
	end
end

function var_0_0.willClose(arg_34_0, arg_34_1)
	var_0_0.super:willClose(arg_34_1)

	if arg_34_0.handle_ then
		var_0_3.unscheduleGlobal(arg_34_0.handle_)

		arg_34_0.handle_ = nil
	end
end

function var_0_0.didClose(arg_35_0, arg_35_1)
	var_0_0.super:didClose(arg_35_1)

	if arg_35_0.callback then
		arg_35_0.callback()
	end
end

function var_0_0.closeAction(arg_36_0, arg_36_1)
	if arg_36_0.isShowAction then
		return
	end

	if arg_36_1 then
		arg_36_0.countAnimation = arg_36_0.countAnimation + 1

		if arg_36_0.countAnimation == 3 then
			xyd.WindowManager.get():closeWindow(arg_36_0)

			return
		end
	end

	local var_36_0 = true

	arg_36_0:descAnimation(var_36_0)
	arg_36_0:nameAnimation(var_36_0)
	arg_36_0:heroAnimation(var_36_0)
end

return var_0_0
