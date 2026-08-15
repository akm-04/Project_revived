local var_0_0 = class("HeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import(".HeroSingleViewLayer")
local var_0_2 = import(".HeroListViewLayer")
local var_0_3 = import("app.model.Hero")
local var_0_4 = import("app.common.ui.LayerMultiplex")
local var_0_5 = -1
local var_0_6 = import("framework.scheduler")
local var_0_7 = "hero"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.viewConf_ = arg_1_2.viewConf

	local var_1_0 = xyd.HeroDisplayOption.INFO

	if not arg_1_0.viewConf_.displayOption then
		arg_1_0.viewConf_.displayOption = var_1_0
	end

	arg_1_0.player_ = arg_1_2.player
	arg_1_0.selectedHeroID_ = {
		heroID = var_0_5
	}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:refresh()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.HERO_UPDATE_COMPLETE, function(arg_4_0)
		local var_4_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		if (arg_3_0.player_ == nil or arg_3_0.player_.playerID == var_4_0.playerID) and var_4_0:getHeroByID(arg_3_0.selectedHeroID_.heroID) == nil then
			if arg_3_0.viewConf_.viewMode == xyd.HeroViewMode.SINGLE_VIEW then
				arg_3_0.selectedHeroID_.heroID = arg_3_0.singleViewLayer_:getNextHeroID()
			elseif arg_3_0.viewConf_.viewMode == xyd.HeroViewMode.LIST_VIEW then
				arg_3_0.selectedHeroID_.heroID = arg_3_0.listViewLayer_:getNextHeroID()
			end
		end

		arg_3_0:refresh(arg_4_0)
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.GUIDE_HERO_STEP, function(arg_5_0)
		if arg_5_0.params.step == 4 then
			xyd.WindowManager.get():closeWindow("guide")
			xyd.WindowManager.get():openWindow("guide")

			local var_5_0 = xyd.WindowManager.get():getWindow("guide")
			local var_5_1 = arg_3_0:nodeByName("Button_return")
			local var_5_2 = var_5_1:getCascadeBoundingBox().width
			local var_5_3 = var_5_1:getCascadeBoundingBox().height
			local var_5_4 = var_5_0:convertToNodeSpace(var_5_1:getParent():convertToWorldSpace(cc.p(var_5_1:getPositionX(), var_5_1:getPositionY())))

			var_5_0:setStencil(var_5_2, var_5_3, var_5_4.x, var_5_4.y, 1)
		end
	end)
	var_0_6.performWithDelayGlobal(function(arg_6_0)
		if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_ID_QIANGHUA then
			arg_3_0.singleViewLayer_:playGuide()
		elseif xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_ID_SECOND_XIANGQIAN and xyd.StoryData.get():getStageID() == xyd.StoryData.get().SECOND_STAGE then
			arg_3_0.singleViewLayer_:playGuide()
		end
	end, 0.1)
end

function var_0_0.didClose(arg_7_0)
	local var_7_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_7_0.player_ == nil or arg_7_0.player_.playerID == var_7_0.playerID then
		var_7_0.newHeroIDs_ = {}

		if not arg_7_0.viewConf_ then
			return
		end

		if arg_7_0.viewConf_.viewMode then
			xyd.db.viewConf.heroViewMode = arg_7_0.viewConf_.viewMode
		end

		if arg_7_0.viewConf_.sortType then
			xyd.db.viewConf.heroDataSortType = arg_7_0.viewConf_.sortType
		end

		xyd.db.viewConf:persist()
	end
end

function var_0_0.layout(arg_8_0)
	local var_8_0 = arg_8_0:nodeByName("background")

	var_8_0:setContentSize(cc.size(xyd.STAGE_WIDTH, var_8_0:getContentSize().height))

	local var_8_1 = arg_8_0:nodeByName("top_layer")

	var_8_1:setContentSize(cc.size(xyd.STAGE_WIDTH, var_8_1:getContentSize().height))

	local var_8_2 = arg_8_0:nodeByName("view_mode_layer")

	arg_8_0.singleViewButton_ = arg_8_0:nodeByName("Button_single_view")

	arg_8_0.singleViewButton_:addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playTabButtonSound()
			arg_8_0:switchViewMode()
		end
	end)

	arg_8_0.listViewButton_ = arg_8_0:nodeByName("Button_list_view")

	arg_8_0.listViewButton_:addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = xyd.StoryData.get():getGuideID()
			local var_10_1 = xyd.StoryData.get():getStageID()

			if var_10_0 < xyd.GuideStoryType.GUIDE_ID_QIANGHUA or var_10_1 == xyd.StoryData.get().SECOND_STAGE and var_10_0 < xyd.GuideStoryType.GUIDE_ID_SECOND_XIANGQIAN then
				return
			end

			xyd.playTabButtonSound()
			arg_8_0:switchViewMode()
		end
	end)

	if arg_8_0.viewConf_.modeSwitchEnabled then
		var_8_2:setVisible(true)
		arg_8_0:refreshViewButtons()
	else
		var_8_2:setVisible(false)
	end

	arg_8_0.returnButton_ = arg_8_0:nodeByName("Button_return")

	arg_8_0.returnButton_:addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_8_0:dispatchEvent({
				name = xyd.event.EXIT_HERO
			})
		end
	end)

	local var_8_3 = xyd.tables.translation

	arg_8_0:nodeByName("Label_hero"):setString(var_8_3:translation("HERO"))
	arg_8_0:nodeByName("Label_return"):setString(var_8_3:translation("RETURN"))

	if arg_8_0.viewConf_.modeSwitchEnabled or arg_8_0.viewConf_.viewMode == xyd.HeroViewMode.SINGLE_VIEW then
		arg_8_0.singleViewLayer_ = var_0_1.new({
			player = arg_8_0.player_,
			selectedHeroID = arg_8_0.selectedHeroID_,
			viewConf = arg_8_0.viewConf_
		})
	end

	if arg_8_0.viewConf_.modeSwitchEnabled or arg_8_0.viewConf_.viewMode == xyd.HeroViewMode.LIST_VIEW then
		arg_8_0.listViewLayer_ = var_0_2.new({
			player = arg_8_0.player_,
			selectedHeroID = arg_8_0.selectedHeroID_,
			viewConf = arg_8_0.viewConf_
		})
	end

	arg_8_0.heroLayers_ = var_0_4.new({
		arg_8_0.singleViewLayer_,
		arg_8_0.listViewLayer_
	})

	arg_8_0.heroLayers_:setPosition(cc.p(0, 0))
	arg_8_0.heroLayers_:setContentSize(cc.size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT))
	arg_8_0:nodeByName("main_layer"):addChild(arg_8_0.heroLayers_)
	arg_8_0.heroLayers_:switchTo(arg_8_0.viewConf_.viewMode)
end

function var_0_0.refresh(arg_12_0, arg_12_1)
	arg_12_0:loadHeroNums(arg_12_1)
end

function var_0_0.loadHeroNums(arg_13_0, arg_13_1)
	local var_13_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_13_1 = arg_13_0:nodeByName("Label_hero_num")
	local var_13_2 = arg_13_0.player_ == nil or arg_13_0.player_.playerID == var_13_0.playerID
	local var_13_3

	if var_13_2 then
		var_13_3 = {}
	else
		var_13_3 = {
			player_id = arg_13_0.player_.playerID
		}
	end

	if not arg_13_0.player_ then
		arg_13_0.player_ = var_13_0
	end

	local function var_13_4()
		if arg_13_0.singleViewLayer_ then
			arg_13_0.singleViewLayer_:refresh(arg_13_1)
		end
	end

	local function var_13_5()
		if arg_13_0.listViewLayer_ then
			arg_13_0.listViewLayer_:refresh(arg_13_1)
		end
	end

	arg_13_0.player_:loadHeros(var_13_3, xyd.backendCallbackWrapper(var_0_7, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			var_13_1:setString(string.format("%d/%d", #arg_13_0.player_.heros_, arg_13_0.player_.maxHeroNumLimit_))
			var_13_1:setVisible(true)

			if arg_13_0.viewConf_.viewMode == xyd.HeroViewMode.SINGLE_VIEW then
				var_13_4()
				var_13_5()
			elseif arg_13_0.viewConf_.viewMode == xyd.HeroViewMode.LIST_VIEW then
				var_13_5()
				var_13_4()
			end
		else
			xyd.errorAlert(arg_16_1)
		end
	end))
end

function var_0_0.refreshViewButtons(arg_17_0)
	if not arg_17_0.viewConf_.modeSwitchEnabled then
		return
	end

	if arg_17_0.viewConf_.viewMode == xyd.HeroViewMode.SINGLE_VIEW then
		arg_17_0.singleViewButton_:setBrightStyle(ccui.BrightStyle.highlight)
		arg_17_0.listViewButton_:setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_17_0.viewConf_.viewMode == xyd.HeroViewMode.LIST_VIEW then
		arg_17_0.singleViewButton_:setBrightStyle(ccui.BrightStyle.normal)
		arg_17_0.listViewButton_:setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.switchViewMode(arg_18_0)
	if arg_18_0.viewConf_.viewMode == xyd.HeroViewMode.SINGLE_VIEW then
		arg_18_0.viewConf_.viewMode = xyd.HeroViewMode.LIST_VIEW

		local var_18_0 = socket.gettime() * 1000

		arg_18_0.heroLayers_:switchTo(xyd.HeroViewMode.LIST_VIEW)

		local var_18_1 = socket.gettime() * 1000 - var_18_0

		print("switchTo list view: ", var_18_1)
		arg_18_0:refreshViewButtons()

		local var_18_2 = socket.gettime() * 1000

		arg_18_0.listViewLayer_:refresh()

		local var_18_3 = socket.gettime() * 1000 - var_18_2

		print("refresh list view: ", var_18_3)
	else
		arg_18_0.viewConf_.viewMode = xyd.HeroViewMode.SINGLE_VIEW

		local var_18_4 = socket.gettime() * 1000

		arg_18_0.heroLayers_:switchTo(xyd.HeroViewMode.SINGLE_VIEW)

		local var_18_5 = socket.gettime() * 1000 - var_18_4

		print("switchTo single view: ", var_18_5)
		arg_18_0:refreshViewButtons()

		local var_18_6 = socket.gettime() * 1000

		arg_18_0.singleViewLayer_:refresh()

		local var_18_7 = socket.gettime() * 1000 - var_18_6

		print("refresh single view: ", var_18_7)
	end
end

return var_0_0
