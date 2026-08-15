local var_0_0 = class("SuperPartnerSelectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.hero
local var_0_4 = import("app.model.Hero")
local var_0_5 = xyd.tables.item
local var_0_6 = {
	COLLECTED = 2,
	ALL = 1,
	NOT_COLLECTED = 3
}
local var_0_7 = {
	{
		btn_name = "btn_all",
		flag = var_0_6.ALL
	},
	{
		btn_name = "btn_collected",
		flag = var_0_6.COLLECTED
	},
	{
		btn_name = "btn_not_collected",
		flag = var_0_6.NOT_COLLECTED
	}
}
local var_0_8 = {
	btn_all = var_0_2:translation("TAITAN_TEXT_ALL"),
	btn_collected = var_0_2:translation("TAITAN_TEXT_COLLECTED"),
	btn_not_collected = var_0_2:translation("TAITAN_TEXT_NOT_COLLECTED")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.superHeros = var_0_3:getSuperHeros()
	arg_1_0.leftBtnType = arg_1_2.selectType or var_0_6.ALL
	arg_1_0.leftBtn = var_0_7
	arg_1_0.isSummon = false

	for iter_1_0, iter_1_1 in ipairs(arg_1_0.superHeros) do
		if not var_0_3:isLibraryShow(arg_1_0.superHeros[iter_1_0]) then
			table.remove(arg_1_0.superHeros, iter_1_0)
		end
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:setButtonClick()
	arg_2_0:layout()
end

function var_0_0.setButtonClick(arg_3_0, arg_3_1)
	arg_3_0:nodeByName("btn_close"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("btn_close"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:nodeByName("btn_all"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended and arg_3_0.leftBtnType ~= var_0_6.ALL then
			xyd.playButtonSound()

			arg_3_0.leftBtnType = var_0_6.ALL

			arg_3_0:updateLeftBtn()
			arg_3_0:updateRightPanel()
		end
	end)
	arg_3_0:nodeByName("btn_collected"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended and arg_3_0.leftBtnType ~= var_0_6.COLLECTED then
			xyd.playButtonSound()

			arg_3_0.leftBtnType = var_0_6.COLLECTED

			arg_3_0:updateLeftBtn()
			arg_3_0:updateRightPanel()
		end
	end)
	arg_3_0:nodeByName("btn_not_collected"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended and arg_3_0.leftBtnType ~= var_0_6.NOT_COLLECTED then
			xyd.playButtonSound()

			arg_3_0.leftBtnType = var_0_6.NOT_COLLECTED

			arg_3_0:updateLeftBtn()
			arg_3_0:updateRightPanel()
		end
	end)
end

function var_0_0.layout(arg_8_0, arg_8_1)
	arg_8_0:changeBtnPos()

	for iter_8_0, iter_8_1 in pairs(arg_8_0.leftBtn) do
		arg_8_0:nodeByName("txt_" .. iter_8_1.btn_name):setString(var_0_8[iter_8_1.btn_name])
	end

	arg_8_0:updateLeftBtn()
	arg_8_0:updateRightPanel()
end

function var_0_0.updateLeftBtn(arg_9_0)
	for iter_9_0, iter_9_1 in pairs(arg_9_0.leftBtn) do
		if arg_9_0.leftBtnType == iter_9_1.flag then
			arg_9_0:nodeByName(iter_9_1.btn_name):setBright(false)
		else
			arg_9_0:nodeByName(iter_9_1.btn_name):setBright(true)
		end
	end
end

function var_0_0.changeBtnPos(arg_10_0)
	local var_10_0 = arg_10_0:nodeByName("btn_all"):getPositionY()

	for iter_10_0 = 1, #arg_10_0.leftBtn do
		local var_10_1 = arg_10_0.leftBtn[iter_10_0].btn_name

		if arg_10_0:nodeByName(var_10_1):isVisible() then
			arg_10_0:nodeByName(var_10_1):setPositionY(var_10_0)

			var_10_0 = var_10_0 - 75
		end
	end
end

function var_0_0.updateRightPanel(arg_11_0)
	local var_11_0 = {}
	local var_11_1 = false

	for iter_11_0, iter_11_1 in pairs(arg_11_0.superHeros) do
		local var_11_2 = arg_11_0.selfPlayer:getHeroByTableID(iter_11_1) and true or false

		table.insert(var_11_0, {
			superHeroId = iter_11_1,
			isCollected_ = var_11_2
		})
	end

	arg_11_0.superHeroTable = var_11_0

	if arg_11_0.leftBtnType == var_0_6.ALL then
		table.sort(var_11_0, function(arg_12_0, arg_12_1)
			if arg_12_0.isCollected_ ~= arg_12_1.isCollected_ then
				return arg_12_0.isCollected_
			end
		end)
	elseif arg_11_0.leftBtnType == var_0_6.COLLECTED then
		for iter_11_2 = #var_11_0, 1, -1 do
			if not var_11_0[iter_11_2].isCollected_ then
				table.remove(var_11_0, iter_11_2)
			end
		end
	elseif arg_11_0.leftBtnType == var_0_6.NOT_COLLECTED then
		for iter_11_3 = #var_11_0, 1, -1 do
			if var_11_0[iter_11_3].isCollected_ then
				table.remove(var_11_0, iter_11_3)
			end
		end
	end

	local var_11_3 = arg_11_0:nodeByName("card_list")

	if not arg_11_0.list then
		arg_11_0.list = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_11_3:getWidth(), var_11_3:getHeight()),
			direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(var_11_3):onScroll(handler(arg_11_0, arg_11_0.scrollListener))

		arg_11_0.list:setTouchSwallowEnabled(false)
		arg_11_0.list:setDelegate(handler(arg_11_0, arg_11_0.delegate))
		arg_11_0.list:reload()
	else
		arg_11_0.list:removeAllItems()
		arg_11_0.list:reload()
		collectgarbage("collect")
	end
end

function var_0_0.delegate(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	if cc.ui.UIListView.COUNT_TAG == arg_13_2 then
		return #arg_13_0.superHeroTable
	elseif cc.ui.UIListView.CELL_TAG == arg_13_2 then
		if arg_13_3 > #arg_13_0.superHeroTable then
			return
		end

		local var_13_0
		local var_13_1
		local var_13_2
		local var_13_3 = arg_13_0.list:dequeueItem()

		if not var_13_3 then
			var_13_3 = arg_13_0.list:newItem()
		else
			var_13_3:removeAllChildren()
		end

		local var_13_4 = display.newNode()

		var_13_4:setTouchSwallowEnabled(false)

		local var_13_5 = display.newNode()

		arg_13_0:initListCell(var_13_5, arg_13_3)
		var_13_4:addChild(var_13_5)
		var_13_4:setContentSize(cc.size(var_13_5:getContentSize().width, arg_13_0.list.viewRect_.height))
		var_13_3:setItemSize(var_13_5:getContentSize().width, arg_13_0.list.viewRect_.height)
		var_13_3:addContent(var_13_4)

		return var_13_3
	end
end

function var_0_0.initListCell(arg_14_0, arg_14_1, arg_14_2)
	if arg_14_2 > #arg_14_0.superHeroTable then
		return
	end

	local var_14_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/super_partner/select/select_card.csb")
	local var_14_1 = var_14_0:getChildByName("container")
	local var_14_2 = var_14_1:getContentSize()
	local var_14_3 = arg_14_0.superHeroTable[arg_14_2].superHeroId
	local var_14_4 = arg_14_0.selfPlayer:getHeroByTableID(var_14_3)
	local var_14_5

	if var_14_4 then
		var_14_5 = var_14_4
	else
		var_14_5 = var_0_4.new()

		var_14_5:populateWithTableID(var_14_3)
	end

	local var_14_6 = xyd.getNormalCard(var_14_5, xyd.SkinDynamicPosType.HERO_MAIN)

	var_14_6:setAnchorPoint(0.5, 0.5)
	var_14_6:setPosition(var_14_1:getChildByName("bg_card"):getWidth() / 2, var_14_1:getChildByName("bg_card"):getHeight() / 2)

	local var_14_7 = var_14_1:getChildByName("bg_card"):getHeight() / var_14_6:getHeight()

	var_14_6:setScale(var_14_7)
	var_14_6:addTo(var_14_1:getChildByName("bg_card"))
	arg_14_1:setContentSize(var_14_2.width, var_14_2.height)
	var_14_0:addTo(arg_14_1)

	local var_14_8 = var_0_3:name(arg_14_0.superHeroTable[arg_14_2].superHeroId)
	local var_14_9 = arg_14_0.superHeroTable[arg_14_2].isCollected_

	if not var_14_9 then
		var_14_8 = var_14_8 .. "(" .. var_0_2:translation("TAITAN_TEXT_NOT_COLLECTED") .. ")"
	end

	var_14_1:getChildByName("txt_name"):setString(var_14_8)
	var_14_1:getChildByName("gray_mask"):setVisible(not var_14_9)
	var_14_0:setTouchEnabled(true)
	var_14_0:setTouchSwallowEnabled(false)
	var_14_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			return true
		elseif arg_15_0.name == "ended" and arg_14_0.scrollViewMoved_ == false then
			local var_15_0 = xyd.WindowManager.get():getWindow("super_partner")

			if var_15_0 and not tolua.isnull(var_15_0) then
				for iter_15_0, iter_15_1 in ipairs(var_15_0.superHeros) do
					if var_15_0.superHeros[iter_15_0] == var_14_3 then
						var_15_0.current_ = iter_15_0
					end
				end

				var_15_0.selectType = arg_14_0.leftBtnType

				var_15_0:updateViews()
			end

			xyd.WindowManager.get():closeWindow(arg_14_0)
		end
	end)
end

function var_0_0.scrollListener(arg_16_0, arg_16_1)
	if arg_16_1.name == "began" then
		arg_16_0.scrollViewMoved_ = false
		arg_16_0.prevX_ = arg_16_1.x
	elseif arg_16_1.name == "moved" then
		if 20 <= math.abs(arg_16_1.x - arg_16_0.prevX_) then
			arg_16_0.scrollViewMoved_ = true
		end

		arg_16_0.scrollX = arg_16_0.list:getScrollNode():getPositionX()
	elseif arg_16_1.name == "scrollEnd" then
		arg_16_0.scrollX = arg_16_0.list:getScrollNode():getPositionX()
	end
end

return var_0_0
