local var_0_0 = class("HeroPresetWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 120
local var_0_3 = 10

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.closeHeroCollectWnd = true
	arg_1_0.teams = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.heroRecommend = xyd.ModelManager.get():loadModel(xyd.ModelType.HERO_RECOMMEND)

	if not arg_2_0.player:isFuncOpen(xyd.FunctionID.ID_RECOMMEND) then
		arg_2_0:nodeByName("button_recommend"):setVisible(false)
		arg_2_0:nodeByName("recommend_text"):setVisible(false)
	end

	arg_2_0:initTeams()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0.list:reload()
end

function var_0_0.initTeams(arg_4_0)
	arg_4_0.teams = arg_4_0.player:getSaveTeams()
	arg_4_0.maxPresetNum_ = xyd.tables.vip:presetNum(arg_4_0.player.vip)

	if arg_4_0.maxPresetNum_ == 0 then
		arg_4_0.maxPresetNum_ = var_0_3
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:initMenu()
	arg_5_0:initList()
	arg_5_0:nodeByName("btn_set"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if #arg_5_0.teams >= arg_5_0.maxPresetNum_ then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PRESET_MEMBER_IS_MAX_NUM")
				})

				return
			end

			local var_6_0 = {
				type = xyd.SelectTeamType.HERO_PRESET,
				presetHeroType = xyd.PresetHeroType.NEW_TEAM,
				presetHeroIndex = #arg_5_0.teams
			}

			xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_6_0)
		end
	end)

	local var_5_0 = string.format(var_0_1:translation("PRESET_MEMBER_NUM"), #arg_5_0.teams, arg_5_0.maxPresetNum_)

	arg_5_0:nodeByName("text_team_num"):setString(var_5_0)
end

function var_0_0.initMenu(arg_7_0)
	arg_7_0.heroClassButtons_ = {}

	table.insert(arg_7_0.heroClassButtons_, arg_7_0:nodeByName("button_all"))
	table.insert(arg_7_0.heroClassButtons_, arg_7_0:nodeByName("button_filter"))
	table.insert(arg_7_0.heroClassButtons_, arg_7_0:nodeByName("button_search"))

	for iter_7_0 = 1, #arg_7_0.heroClassButtons_ do
		arg_7_0.heroClassButtons_[iter_7_0]:setZoomScale(0.3)
		arg_7_0.heroClassButtons_[iter_7_0]:addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				arg_7_0.closeHeroCollectWnd = false

				if iter_7_0 == 2 then
					local var_8_0 = {
						checkAwaken = 1
					}

					xyd.WindowManager.get():openWindow("hero_filter", var_8_0)
				end

				if iter_7_0 == 3 then
					xyd.WindowManager.get():openWindow("hero_search")
				end

				if xyd.WindowManager.get():getWindow(xyd.WindowName.heroCollectWnd) then
					if arg_7_0.callback then
						arg_7_0.callback(iter_7_0)
					end

					xyd.WindowManager.get():closeWindow(arg_7_0)
				end
			end
		end)
	end

	arg_7_0:nodeByName("button_recommend"):setZoomScale(0.3)
	arg_7_0:nodeByName("button_recommend"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			arg_7_0.callback(4)
		end
	end)
	arg_7_0:nodeByName("button_preset"):setZoomScale(0.3)
	arg_7_0:nodeByName("button_preset"):setBrightStyle(ccui.BrightStyle.highlight)
	arg_7_0:nodeByName("button_preset"):setTouchEnabled(false)
end

function var_0_0.initList(arg_10_0)
	local var_10_0 = arg_10_0:nodeByName("list")
	local var_10_1 = var_10_0:getContentSize()

	arg_10_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_10_1.width, var_10_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_10_0)

	arg_10_0.list:setDelegate(handler(arg_10_0, arg_10_0.delegate))
end

function var_0_0.delegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return #arg_11_0.teams
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_0
		local var_11_1
		local var_11_2
		local var_11_3 = arg_11_0.list:dequeueItem()

		if not var_11_3 then
			var_11_3 = arg_11_0.list:newItem()
		else
			var_11_3:removeAllChildren()
		end

		local var_11_4 = display.newNode()

		var_11_4:setTouchSwallowEnabled(false)

		local var_11_5 = display.newNode()

		arg_11_0:initTeamCell(var_11_5, arg_11_3)
		var_11_4:addChild(var_11_5)
		var_11_4:setContentSize(cc.size(arg_11_0.list.viewRect_.width, var_11_5:getContentSize().height))
		var_11_3:setItemSize(arg_11_0.list.viewRect_.width, var_11_5:getContentSize().height)
		var_11_3:addContent(var_11_4)

		return var_11_3
	end
end

function var_0_0.initTeamCell(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_0.teams[arg_12_2].team
	local var_12_1 = arg_12_0.teams[arg_12_2].teamName
	local var_12_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_list/hero_preset/preset_item.csb")
	local var_12_3 = var_12_2:getChildByName("container")
	local var_12_4 = var_12_3:getContentSize()

	arg_12_1:setContentSize(var_12_4.width, var_12_4.height + 10)
	var_12_2:addTo(arg_12_1)
	var_12_3:getChildByName("text_name"):setString(var_12_1)

	local var_12_5 = var_12_3:getChildByName("hero_list")
	local var_12_6 = 0

	for iter_12_0 = 1, #var_12_0 do
		local var_12_7 = var_12_0[iter_12_0]
		local var_12_8 = display.newNode()

		var_12_8:setContentSize(var_0_2, var_0_2)
		xyd.setAvatarBorder(var_12_7, var_12_8)
		var_12_8:addTo(var_12_5)
		var_12_8:setPositionX(var_12_6)

		var_12_6 = var_12_6 + var_0_2 + 20
	end

	var_12_3:getChildByName("btn_delete"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_13_0 = string.format(var_0_1:translation("PRESET_TEAM_DELETE"), var_12_1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_13_0, function()
				local var_14_0, var_14_1 = arg_12_0.player:getSaveTeamStr()
				local var_14_2 = xyd.split(var_14_0, ":")

				table.remove(var_14_2, arg_12_2)

				local var_14_3 = string.split(var_14_1, "|||")

				table.remove(var_14_3, arg_12_2)

				local var_14_4 = arg_12_0:tableToString(var_14_2, ":")
				local var_14_5 = arg_12_0:tableToString(var_14_3, "|||")
				local var_14_6 = {
					team_str = var_14_4,
					team_name_str = var_14_5
				}

				arg_12_0.player:heroPreset(var_14_6, function()
					arg_12_0:updateTeamInfo()
				end)
			end, nil, nil, arg_12_0.colorMode)
		end
	end)
	var_12_3:getChildByName("btn_adjust"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_16_0 = arg_12_0.player:getSaveTeamStr()
			local var_16_1 = arg_12_0.player:getSaveTeamIDs(var_16_0)
			local var_16_2 = {
				type = xyd.SelectTeamType.HERO_PRESET,
				presetHeroType = xyd.PresetHeroType.ADJUST_TEAM,
				presetHeroIndex = arg_12_2,
				selected = var_16_1[arg_12_2],
				preHeros = var_12_0
			}

			xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_16_2)
		end
	end)
end

function var_0_0.tableToString(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1[1] or ""

	for iter_17_0 = 2, #arg_17_1 do
		var_17_0 = var_17_0 .. arg_17_2 .. arg_17_1[iter_17_0]
	end

	return var_17_0
end

function var_0_0.updateTeamInfo(arg_18_0)
	arg_18_0:initTeams()

	local var_18_0 = string.format(var_0_1:translation("PRESET_MEMBER_NUM"), #arg_18_0.teams, arg_18_0.maxPresetNum_)

	arg_18_0:nodeByName("text_team_num"):setString(var_18_0)
	arg_18_0.list:reload()
end

function var_0_0.willClose(arg_19_0, arg_19_1)
	var_0_0.super.willClose(arg_19_1)

	if xyd.WindowManager.get():getWindow(xyd.WindowName.heroCollectWnd) and arg_19_0.closeHeroCollectWnd then
		xyd.WindowManager.get():closeWindow(xyd.WindowName.heroCollectWnd)
	end
end

return var_0_0
