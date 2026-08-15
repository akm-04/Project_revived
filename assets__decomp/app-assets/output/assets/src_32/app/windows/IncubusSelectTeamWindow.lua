local var_0_0 = class("IncubusSelectTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.incubusTable
local var_0_3 = xyd.tables.hero
local var_0_4 = 30

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.id = arg_1_2.id
	arg_1_0.firstHeros = arg_1_2.firstHeros
	arg_1_0.nowType = xyd.DistanceType.ALL
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.bannedHeros = var_0_2:banList(arg_1_0.id)
	arg_1_0.select_ = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initHeros(arg_2_0.selfPlayer.heros_)
	arg_2_0:layOut()
end

function var_0_0.layOut(arg_3_0)
	arg_3_0:nodeByName("title_txt"):setString(var_0_1:translation("INCUBUS_DESCRIBE1"))
	arg_3_0:updateNum()

	local var_3_0 = arg_3_0:nodeByName("hero_container")

	arg_3_0.ListView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, 680, 500),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_3_0)

	arg_3_0.ListView_:setDelegate(handler(arg_3_0, arg_3_0.delegate))

	arg_3_0.heroCells_ = {}

	arg_3_0:nodeByName("close_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			audio.playSound(xyd.tables.sound:getSound("ui_close_window"), false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:nodeByName("battle_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.Backend.get():request(xyd.mid.UNLIMIT_START_FIGHT, {
				incubus_id = arg_3_0.id
			}, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					arg_3_0:recordFormation()

					local var_6_0 = clone(arg_3_0.select_)
					local var_6_1 = {}

					for iter_6_0, iter_6_1 in ipairs(var_6_0) do
						var_6_1[iter_6_1:getHeroID()] = math.random(1000000)
					end

					table.sort(var_6_0, function(arg_7_0, arg_7_1)
						return var_6_1[arg_7_0:getHeroID()] > var_6_1[arg_7_1:getHeroID()]
					end)

					local var_6_2 = {
						id = arg_3_0.id,
						herosA = arg_3_0.firstHeros,
						supportHeros = var_6_0,
						partner = var_0_2:partner(arg_3_0.id),
						guard = var_0_2:guard(arg_3_0.id),
						drops = arg_6_1.drops
					}
					local var_6_3 = import("app.scenes.BattleUnlimit")

					cc.Director:getInstance():pushScene(var_6_3.new(var_6_2))
				end
			end, nil, nil, true)
		end
	end)
	arg_3_0:initRightMenu()
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	arg_8_0:updateView()
	arg_8_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
end

function var_0_0.initHeros(arg_9_0, arg_9_1)
	arg_9_0.herosList = {}
	arg_9_0.herosList[xyd.DistanceType.ALL] = {}
	arg_9_0.herosList[xyd.DistanceType.QIANPAI] = {}
	arg_9_0.herosList[xyd.DistanceType.ZHONGPAI] = {}
	arg_9_0.herosList[xyd.DistanceType.HOUPAI] = {}

	local var_9_0 = 0

	for iter_9_0, iter_9_1 in pairs(arg_9_1) do
		if iter_9_1:getDistanceType() == xyd.DistanceType.QIANPAI then
			table.insert(arg_9_0.herosList[xyd.DistanceType.QIANPAI], iter_9_1)
		elseif iter_9_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
			table.insert(arg_9_0.herosList[xyd.DistanceType.ZHONGPAI], iter_9_1)
		elseif iter_9_1:getDistanceType() == xyd.DistanceType.HOUPAI then
			table.insert(arg_9_0.herosList[xyd.DistanceType.HOUPAI], iter_9_1)
		end

		table.insert(arg_9_0.herosList[xyd.DistanceType.ALL], iter_9_1)

		if not arg_9_0:isFirst(iter_9_1) and not arg_9_0:isBanned(iter_9_1) then
			var_9_0 = var_9_0 + 1
		end
	end

	for iter_9_2 = 1, #arg_9_0.herosList do
		table.sort(arg_9_0.herosList[iter_9_2], function(arg_10_0, arg_10_1)
			local var_10_0 = arg_9_0:isFirst(arg_10_0)
			local var_10_1 = arg_9_0:isFirst(arg_10_1)

			if (var_10_0 or var_10_1) and (not var_10_0 or not var_10_1) then
				return var_10_0
			end

			local var_10_2, var_10_3 = arg_9_0:isBanned(arg_10_0), arg_9_0:isBanned(arg_10_1)

			if (var_10_2 or var_10_3) and (not var_10_2 or not var_10_3) then
				return var_10_3
			end

			return xyd.heroNormalSort(arg_10_0, arg_10_1) or false
		end)
	end

	local var_9_1 = (xyd.db.formation:getFormationData(xyd.CampaignType.INCUBUS) or {})[1] or {}

	if #var_9_1 > 0 then
		for iter_9_3, iter_9_4 in ipairs(var_9_1) do
			local var_9_2 = arg_9_0.selfPlayer:getHeroByID(iter_9_4)

			if not arg_9_0:isFirst(var_9_2) and not arg_9_0:isBanned(var_9_2) then
				table.insert(arg_9_0.select_, var_9_2)
			end
		end
	else
		local var_9_3 = (var_9_0 - var_9_0 % 2) / 2

		for iter_9_5 = 1, #arg_9_0.herosList[1] do
			if var_9_3 < 1 then
				break
			end

			if not arg_9_0:isFirst(arg_9_0.herosList[1][iter_9_5]) and not arg_9_0:isBanned(arg_9_0.herosList[1][iter_9_5]) then
				var_9_3 = var_9_3 - 1

				table.insert(arg_9_0.select_, arg_9_0.herosList[1][iter_9_5])
			end
		end
	end
end

function var_0_0.initRightMenu(arg_11_0)
	arg_11_0.rightMenuButtons_ = {}

	table.insert(arg_11_0.rightMenuButtons_, arg_11_0:nodeByName("all_btn"))
	table.insert(arg_11_0.rightMenuButtons_, arg_11_0:nodeByName("qian_btn"))
	table.insert(arg_11_0.rightMenuButtons_, arg_11_0:nodeByName("zhong_btn"))
	table.insert(arg_11_0.rightMenuButtons_, arg_11_0:nodeByName("hou_btn"))

	for iter_11_0 = 1, #arg_11_0.rightMenuButtons_ do
		arg_11_0.rightMenuButtons_[iter_11_0]:addTouchEventListener(function(arg_12_0, arg_12_1)
			if arg_12_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				arg_11_0.nowType = iter_11_0

				arg_11_0:updateView()
			end
		end)
	end
end

function var_0_0.updateView(arg_13_0)
	for iter_13_0 = 1, #arg_13_0.rightMenuButtons_ do
		if iter_13_0 == arg_13_0.nowType then
			arg_13_0.rightMenuButtons_[iter_13_0]:setTouchEnabled(false)
			arg_13_0.rightMenuButtons_[iter_13_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_13_0.rightMenuButtons_[iter_13_0]:setTouchEnabled(true)
			arg_13_0.rightMenuButtons_[iter_13_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_13_0.ListView_:removeAllItems()
	arg_13_0.ListView_:reload()
end

function var_0_0.delegate(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = 5

	if cc.ui.UIListView.COUNT_TAG == arg_14_2 then
		return math.ceil(#arg_14_0.herosList[arg_14_0.nowType] / var_14_0)
	elseif cc.ui.UIListView.CELL_TAG == arg_14_2 then
		local var_14_1
		local var_14_2 = arg_14_0.ListView_:dequeueItem()

		if not var_14_2 then
			var_14_2 = arg_14_0.ListView_:newItem()
		else
			var_14_2:removeAllChildren()
		end

		local var_14_3 = display.newNode()

		var_14_3:setTouchSwallowEnabled(false)

		for iter_14_0 = 1, var_14_0 do
			local var_14_4 = (arg_14_3 - 1) * var_14_0 + iter_14_0

			if var_14_4 > #arg_14_0.herosList[arg_14_0.nowType] then
				break
			end

			var_14_1 = display.newNode()

			arg_14_0:initHeroCell(var_14_1, var_14_4)

			local var_14_5 = var_14_1:getContentSize().width
			local var_14_6 = var_14_1:getContentSize().height
			local var_14_7 = (arg_14_0.ListView_.viewRect_.width - var_14_5 * var_14_0) / (var_14_0 + 1)

			var_14_1:pos(var_14_7 * iter_14_0 + (iter_14_0 - 1) * var_14_5 + var_14_5 / 2, var_0_4 + var_14_6 / 2 - 2)
			var_14_3:addChild(var_14_1)

			arg_14_0.heroCells_[var_14_4] = var_14_1
		end

		var_14_3:setContentSize(cc.size(arg_14_0.ListView_.viewRect_.width, var_14_1:getContentSize().height + var_0_4))
		var_14_2:setItemSize(arg_14_0.ListView_.viewRect_.width, var_14_1:getContentSize().height + var_0_4)
		var_14_2:addContent(var_14_3)

		return var_14_2
	end
end

function var_0_0.initHeroCell(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_0.herosList[arg_15_0.nowType][arg_15_2]
	local var_15_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")

	var_15_1:getChildByName("yongbing_tubiao"):setVisible(false)

	local var_15_2 = var_15_1:getChildByName("background"):getContentSize()

	var_15_1:setContentSize(var_15_2)
	arg_15_1:setContentSize(var_15_2)
	xyd.setAvatarBorder(var_15_0, var_15_1:getChildByName("avatar"))

	local var_15_3 = var_15_1:getChildByName("chosen")

	var_15_3:setLocalZOrder(100)
	var_15_3:setVisible(false)

	local var_15_4 = var_15_1:getChildByName("avatar_mask")

	var_15_4:setLocalZOrder(2)
	var_15_4:setVisible(false)
	var_15_1:getChildByName("is_can_rent"):setVisible(false)

	for iter_15_0 = 1, 3 do
		var_15_1:getChildByName("team" .. iter_15_0):setVisible(false)
	end

	var_15_1:getChildByName("lv_txt"):setString(var_15_0:getLevel())

	local var_15_5 = var_15_1:getChildByName("name_text")

	var_15_5:setString(var_15_0:getName())
	var_15_5:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[var_15_0:getColor()] ~= "" then
		local var_15_6 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_15_5:getX() + var_15_5:getWidth() / 2 - 10,
			y = var_15_5:getY(),
			color = xyd.color.HERO_QUALITY[var_15_0:getColor()],
			text = xyd.Color2Level[var_15_0:getColor()]
		}
		local var_15_7 = xyd.AssetLoader.get():loadLabel(var_15_6)

		var_15_7:addTo(var_15_1)
		var_15_7:align(display.CENTER_LEFT)
		var_15_7:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_15_5:x(var_15_5:getX() - 15)
	end

	var_15_1:getChildByName("dead_text"):setVisible(false)
	var_15_1:getChildByName("hp_bar"):hide()
	var_15_1:getChildByName("mp_bar"):hide()
	var_15_1:getChildByName("hp_di"):hide()
	var_15_1:getChildByName("mp_di"):hide()
	var_15_1:setName("layout")
	var_15_1:setPosition(cc.p(0, 0))

	arg_15_1.data = var_15_0

	for iter_15_1, iter_15_2 in ipairs(arg_15_0.select_) do
		if iter_15_2:getTableID() == var_15_0:getTableID() and iter_15_2.player_name == var_15_0.player_name then
			var_15_4:setVisible(true)
			var_15_3:setVisible(true)

			arg_15_1.isChosen = 1

			break
		end
	end

	arg_15_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_15_1:addChild(var_15_1)
	arg_15_1:setTouchSwallowEnabled(false)
	arg_15_1:setTouchEnabled(true)

	if arg_15_0:isBanned(var_15_0) then
		local var_15_8 = xyd.AssetLoader.get():loadSprite("windows/common/text/banned.png")

		var_15_8:setAnchorPoint(cc.p(0.5, 1))
		var_15_8:setPosition(80, 135)
		arg_15_1:addChild(var_15_8)
		var_15_4:setVisible(true)
	elseif arg_15_0:isFirst(var_15_0) then
		local var_15_9 = xyd.AssetLoader.get():loadSprite("windows/common/text/first_heros.png")

		var_15_9:setAnchorPoint(cc.p(0.5, 1))
		var_15_9:setPosition(80, 135)
		arg_15_1:addChild(var_15_9)
		var_15_4:setVisible(true)
	else
		arg_15_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
			arg_15_0:buttonHandler(nil, arg_15_1, arg_16_0)

			if arg_16_0.name == "began" then
				arg_15_0.startClick_ = true
				arg_15_0.prevX_ = arg_16_0.x
				arg_15_0.prevY_ = arg_16_0.y
			elseif arg_16_0.name == "moved" then
				if math.abs(arg_16_0.y - arg_15_0.prevY_) > 5 or math.abs(arg_16_0.x - arg_15_0.prevX_) > 5 then
					arg_15_0.startClick_ = false
				end
			elseif arg_16_0.name == "ended" and arg_15_0.startClick_ then
				arg_15_0:clickAvatar(arg_15_1)
			end

			return true
		end)
	end
end

function var_0_0.clickAvatar(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1:getChildByName("layout")
	local var_17_1 = var_17_0:getChildByName("avatar_mask")
	local var_17_2 = var_17_0:getChildByName("chosen")

	if arg_17_1.isChosen then
		var_17_1:setVisible(false)
		var_17_2:setVisible(false)

		for iter_17_0 = #arg_17_0.select_, 1, -1 do
			if arg_17_0.select_[iter_17_0]:getHeroID() == arg_17_1.data:getHeroID() then
				table.remove(arg_17_0.select_, iter_17_0)

				break
			end
		end

		arg_17_1.isChosen = nil
	else
		var_17_1:setVisible(true)
		var_17_2:setVisible(true)
		table.insert(arg_17_0.select_, arg_17_1.data)

		arg_17_1.isChosen = 1
	end

	arg_17_0:updateNum()
end

function var_0_0.buttonHandler(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	if not arg_18_2 or not arg_18_2:getParent() then
		return
	end

	if arg_18_3.name == "ended" then
		transition.stopTarget(arg_18_2)
		arg_18_2:setScale(1)

		if arg_18_1 then
			arg_18_1(arg_18_2, eventType)
		end
	elseif arg_18_3.name == "began" then
		local var_18_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_18_2:runAction(var_18_0)

		return true
	elseif arg_18_3.name == "cancled" then
		transition.stopTarget(arg_18_2)
		arg_18_2:setScale(1)
	end
end

function var_0_0.updateNum(arg_19_0)
	arg_19_0:nodeByName("support_txt"):setString(string.format(var_0_1:translation("INCUBUS_SUPPORT"), #arg_19_0.select_))
end

function var_0_0.isFirst(arg_20_0, arg_20_1)
	for iter_20_0 = 1, #arg_20_0.firstHeros do
		if arg_20_0.firstHeros[iter_20_0]:getHeroID() == arg_20_1:getHeroID() then
			return true
		end
	end

	return false
end

function var_0_0.isBanned(arg_21_0, arg_21_1)
	local var_21_0 = arg_21_1:getTableID()
	local var_21_1 = xyd.tables.hero

	if var_21_1:beforeAwaken(var_21_0) > 0 then
		var_21_0 = var_21_1:beforeAwaken(var_21_0)
	end

	for iter_21_0 = 1, #arg_21_0.bannedHeros do
		if var_21_0 == arg_21_0.bannedHeros[iter_21_0] then
			return true
		end
	end

	return false
end

function var_0_0.recordFormation(arg_22_0)
	local var_22_0 = xyd.CampaignType.INCUBUS
	local var_22_1 = ""

	for iter_22_0 = 1, #arg_22_0.firstHeros do
		var_22_1 = var_22_1 .. string.format("%d|", arg_22_0.firstHeros[iter_22_0]:getHeroID())
	end

	for iter_22_1 = 1, #arg_22_0.select_ do
		var_22_1 = var_22_1 .. string.format("%d|", arg_22_0.select_[iter_22_1]:getHeroID())
	end

	xyd.db.formation:setFormationData(var_22_0, var_22_1)
end

return var_0_0
