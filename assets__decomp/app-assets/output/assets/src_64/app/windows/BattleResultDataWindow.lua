local var_0_0 = class("BattleResultDataWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 50
local var_0_3 = import("app.model.Pet")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.herosA = arg_1_2.herosA
	arg_1_0.herosB = arg_1_2.herosB
	arg_1_0.petA = arg_1_2.petA or {}
	arg_1_0.petB = arg_1_2.petB or {}
	arg_1_0.campaignID = arg_1_2.campaignID
	arg_1_0.campaignType = arg_1_2.campaignType
	arg_1_0.isBeforeBattle = arg_1_2.isBeforeBattle
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:update()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.willClose(arg_4_0)
	return
end

function var_0_0.didClose(arg_5_0)
	return
end

function var_0_0.layout(arg_6_0)
	if arg_6_0.campaignType == xyd.CampaignType.INCUBUS then
		if next(arg_6_0.herosA) then
			table.sort(arg_6_0.herosA, function(arg_7_0, arg_7_1)
				if arg_7_0 and arg_7_1 then
					if arg_7_0.harms and arg_7_1.harms then
						return arg_7_0.harms > arg_7_1.harms
					end
				elseif arg_7_1 then
					return false
				else
					return true
				end
			end)
		end

		arg_6_0:nodeByName("unlimit_container"):setVisible(true)
		arg_6_0:nodeByName("txt_damage_self"):setVisible(false)
		arg_6_0:nodeByName("txt_damage_enemy"):setVisible(false)
		arg_6_0:nodeByName("txt_unlimit_damage"):setString(xyd.tables.translation:translation("SELFTEAM") .. xyd.tables.translation:translation("DAMAGE_OUTPUT"))
	end

	arg_6_0:nodeByName("txt_damage_self"):setString(xyd.tables.translation:translation("SELFTEAM") .. xyd.tables.translation:translation("DAMAGE_OUTPUT"))
	arg_6_0:nodeByName("txt_damage_enemy"):setString(xyd.tables.translation:translation("ENEMY") .. xyd.tables.translation:translation("DAMAGE_OUTPUT"))

	if arg_6_0.campaignType == xyd.CampaignType.CLOUD_LADDER or arg_6_0.campaignType == xyd.CampaignType.CLOUD_ROAD or arg_6_0.campaignType == xyd.CampaignType.CLOUD_TEMPLE then
		arg_6_0:nodeByName("btn_save_team"):setVisible(false)
	else
		arg_6_0:nodeByName("text_save_team"):setString(xyd.tables.translation:translation("SAVE_TEAM"))
		arg_6_0:nodeByName("btn_save_team"):addTouchEventListener(function(arg_8_0, arg_8_1)
			xyd.buttonScaleAnim(arg_8_0, arg_8_1)

			if arg_8_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_8_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
				local var_8_1 = xyd.tables.vip:presetNum(var_8_0.vip)

				if var_8_1 <= 0 then
					var_8_1 = 10
				end

				if var_8_1 <= #var_8_0:getSaveTeams() then
					xyd.WindowManager.get():openWindow("toast", {
						message = xyd.tables.translation:translation("PRESET_MEMBER_IS_MAX_NUM")
					})

					return
				end

				local var_8_2 = {}

				for iter_8_0, iter_8_1 in ipairs(arg_6_0.herosA) do
					if arg_6_0.isBeforeBattle then
						table.insert(var_8_2, iter_8_1:getFirstTableID())
					else
						table.insert(var_8_2, iter_8_1.hero_:getFirstTableID())
					end
				end

				local var_8_3 = {}

				for iter_8_2, iter_8_3 in ipairs(var_8_2) do
					local var_8_4 = var_8_0:getHeroIgnoreAwaken(iter_8_3)

					if var_8_4 then
						table.insert(var_8_3, var_8_4)
					end
				end

				local var_8_5

				if arg_6_0.petA and arg_6_0.petA[1] then
					if arg_6_0.isBeforeBattle then
						var_8_5 = var_8_0:getPetIgnoreAwaken(arg_6_0.petA[1]:getFirstTableID())
					else
						var_8_5 = var_8_0:getPetIgnoreAwaken(arg_6_0.petA[1].hero_:getFirstTableID())
					end
				end

				local var_8_6 = {
					type = xyd.SelectTeamType.HERO_PRESET,
					presetHeroType = xyd.PresetHeroType.NEW_TEAM,
					presetHeroIndex = #var_8_0:getSaveTeams(),
					selected = var_8_2,
					preHeros = var_8_3,
					prePet = {
						var_8_5
					}
				}

				xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_8_6)
				arg_6_0:close()
			end
		end)
	end

	arg_6_0.itemA = {}
	arg_6_0.itemB = {}

	if arg_6_0.campaignType ~= xyd.CampaignType.INCUBUS then
		local var_6_0 = arg_6_0:nodeByName("node_pos")

		arg_6_0.content = display.newNode()

		local var_6_1 = 20 + 80 * math.max(math.max(5, #arg_6_0.herosA + #arg_6_0.petA), #arg_6_0.herosB + #arg_6_0.petB)

		arg_6_0.content:size(arg_6_0:nodeByName("list"):getWidth(), var_6_1)
		arg_6_0.content:align(display.LEFT_BOTTOM, 0, 0)
		arg_6_0.content:setColor(cc.c4b(255, 255, 255, 155))

		local var_6_2 = var_6_0:getX()
		local var_6_3 = var_6_1

		local function var_6_4(arg_9_0, arg_9_1)
			local var_9_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle/battle_result_data/item.csb")

			var_9_0:setContentSize(var_9_0:getChildByName("background"):getContentSize())
			var_9_0:addTo(arg_6_0.content)
			var_9_0:setAnchorPoint(cc.p(0, 0))
			var_9_0:pos(var_6_2, var_6_3 - arg_9_0 * 80)

			var_9_0.fighter = arg_9_1

			table.insert(arg_6_0.itemA, var_9_0)
		end

		local function var_6_5(arg_10_0, arg_10_1)
			local var_10_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle/battle_result_data/item.csb")

			var_10_0:setContentSize(var_10_0:getChildByName("background"):getContentSize())
			var_10_0:addTo(arg_6_0.content)
			var_10_0:setAnchorPoint(cc.p(0, 0))
			var_10_0:pos(arg_6_0:nodeByName("list"):getWidth() - var_6_2 - var_10_0:getWidth(), var_6_3 - arg_10_0 * 80)
			var_10_0:getChildByName("avatar"):x(var_10_0:getWidth() - var_10_0:getChildByName("avatar"):getX())
			var_10_0:getChildByName("dead_mark"):x(var_10_0:getWidth() - var_10_0:getChildByName("dead_mark"):getX())
			var_10_0:getChildByName("label"):x(var_10_0:getWidth() - var_10_0:getChildByName("label"):getX())
			var_10_0:getChildByName("bar1"):x(var_10_0:getWidth() - var_10_0:getChildByName("bar1"):getX())
			var_10_0:getChildByName("bar2"):x(var_10_0:getWidth() - var_10_0:getChildByName("bar2"):getX())
			var_10_0:getChildByName("bar_back"):x(var_10_0:getWidth() - var_10_0:getChildByName("bar_back"):getX())

			var_10_0.fighter = arg_10_1

			table.insert(arg_6_0.itemB, var_10_0)
		end

		for iter_6_0 = 1, #arg_6_0.herosA do
			var_6_4(iter_6_0, arg_6_0.herosA[iter_6_0])
		end

		for iter_6_1 = 1, #arg_6_0.petA do
			var_6_4(iter_6_1 + #arg_6_0.herosA, arg_6_0.petA[iter_6_1])
		end

		for iter_6_2 = 1, #arg_6_0.herosB do
			var_6_5(iter_6_2, arg_6_0.herosB[iter_6_2])
		end

		for iter_6_3 = 1, #arg_6_0.petB do
			var_6_5(iter_6_3 + #arg_6_0.herosB, arg_6_0.petB[iter_6_3])
		end
	else
		local var_6_6 = arg_6_0:nodeByName("unlimit_node_pos")

		arg_6_0.content = display.newNode()

		local var_6_7 = 20 + 80 * math.max(5, #arg_6_0.herosA)

		arg_6_0.content:size(arg_6_0:nodeByName("unlimit_list"):getWidth(), var_6_7)
		arg_6_0.content:align(display.LEFT_BOTTOM, 0, 0)
		arg_6_0.content:setColor(cc.c4b(255, 255, 255, 155))

		local var_6_8 = var_6_6:getX() - 25
		local var_6_9 = var_6_7

		local function var_6_10(arg_11_0, arg_11_1)
			local var_11_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle/battle_result_data/item.csb")

			var_11_0:setContentSize(var_11_0:getChildByName("unlimit_background"):getContentSize())
			var_11_0:getChildByName("unlimit_background"):show()
			var_11_0:getChildByName("bar1"):hide()
			var_11_0:getChildByName("bar2"):hide()
			var_11_0:getChildByName("label"):hide()
			var_11_0:getChildByName("bar_back"):hide()
			var_11_0:addTo(arg_6_0.content)
			var_11_0:setAnchorPoint(cc.p(0, 0))
			var_11_0:pos(var_6_8, var_6_9 - arg_11_0 * 80)

			var_11_0.fighter = arg_11_1

			table.insert(arg_6_0.itemA, var_11_0)
		end

		for iter_6_4 = 1, #arg_6_0.herosA do
			var_6_10(iter_6_4, arg_6_0.herosA[iter_6_4])
		end
	end
end

function var_0_0.getList(arg_12_0)
	local function var_12_0(arg_13_0)
		if arg_13_0.name == "began" then
			arg_12_0.scrollViewMoved_ = false
			arg_12_0.prevY_ = arg_13_0.y
		elseif arg_13_0.name == "moved" and 10 <= math.abs(arg_13_0.y - arg_12_0.prevY_) then
			arg_12_0.scrollViewMoved_ = true
		end
	end

	if not arg_12_0.list_ then
		local var_12_1

		if arg_12_0.campaignType ~= xyd.CampaignType.INCUBUS then
			var_12_1 = arg_12_0:nodeByName("list")
		else
			var_12_1 = arg_12_0:nodeByName("unlimit_list")
		end

		arg_12_0.list_ = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 0, var_12_1:getWidth(), var_12_1:getHeight()),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(var_12_1):onScroll(var_12_0)

		arg_12_0.list_:align(display.LEFT_BOTTOM, 0, 0)
	end

	return arg_12_0.list_
end

function var_0_0.update(arg_14_0)
	local var_14_0 = 0

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.herosA) do
		if var_14_0 < iter_14_1.harms then
			var_14_0 = iter_14_1.harms
		end
	end

	for iter_14_2, iter_14_3 in ipairs(arg_14_0.herosB) do
		if var_14_0 < iter_14_3.harms then
			var_14_0 = iter_14_3.harms
		end
	end

	if arg_14_0.campaignType ~= xyd.CampaignType.INCUBUS then
		for iter_14_4, iter_14_5 in ipairs(arg_14_0.itemA) do
			iter_14_5:getChildByName("label"):setString(math.ceil(iter_14_5.fighter.harms))
			iter_14_5:getChildByName("bar1"):setPercent(iter_14_5.fighter.harms / var_14_0 * 100)
			iter_14_5:getChildByName("bar2"):setVisible(false)

			if arg_14_0.isBeforeBattle then
				xyd.setAvatarBorderNewUI(iter_14_5.fighter, iter_14_5:getChildByName("avatar"))
			else
				xyd.setAvatarBorderNewUI(iter_14_5.fighter.hero_, iter_14_5:getChildByName("avatar"))
			end

			if iter_14_5.fighter.willDie ~= nil then
				if iter_14_5.fighter.willDie == true then
					iter_14_5:getChildByName("dead_mark"):setVisible(true)
				end
			elseif not iter_14_5.fighter:canReborn() and iter_14_5.fighter:isDeath() then
				iter_14_5:getChildByName("dead_mark"):setVisible(true)
			elseif iter_14_5.fighter.reportDieCount_ and iter_14_5.fighter.reportDieCount_ ~= -1 then
				iter_14_5:getChildByName("dead_mark"):setVisible(true)
			end
		end

		local var_14_1 = xyd.tables.campaign:monsterStar(arg_14_0.campaignID)

		for iter_14_6, iter_14_7 in ipairs(arg_14_0.itemB) do
			iter_14_7:getChildByName("label"):setString(math.ceil(iter_14_7.fighter.harms))
			iter_14_7:getChildByName("bar2"):setPercent(iter_14_7.fighter.harms / var_14_0 * 100)
			iter_14_7:getChildByName("bar1"):setVisible(false)

			if arg_14_0.campaignType == xyd.CampaignType.CHAPTER_BOSS then
				if arg_14_0.isBeforeBattle then
					xyd.setAvatarBorderNewUI(iter_14_7.fighter, iter_14_7:getChildByName("avatar"), 16, var_14_1[iter_14_6])
				else
					xyd.setAvatarBorderNewUI(iter_14_7.fighter.hero_, iter_14_7:getChildByName("avatar"), 16, var_14_1[iter_14_6])
				end
			elseif arg_14_0.isBeforeBattle then
				xyd.setAvatarBorderNewUI(iter_14_7.fighter, iter_14_7:getChildByName("avatar"), nil, var_14_1[iter_14_6])
			else
				xyd.setAvatarBorderNewUI(iter_14_7.fighter.hero_, iter_14_7:getChildByName("avatar"), nil, var_14_1[iter_14_6])
			end

			if iter_14_7.fighter.willDie ~= nil then
				if iter_14_7.fighter.willDie == true then
					iter_14_7:getChildByName("dead_mark"):setVisible(true)
				end
			elseif not iter_14_7.fighter:canReborn() and iter_14_7.fighter:isDeath() then
				iter_14_7:getChildByName("dead_mark"):setVisible(true)
			elseif iter_14_7.fighter.reportDieCount_ and iter_14_7.fighter.reportDieCount_ ~= -1 then
				iter_14_7:getChildByName("dead_mark"):setVisible(true)
			end
		end

		local var_14_2 = arg_14_0:getList():newItem()

		var_14_2:addContent(arg_14_0.content)
		var_14_2:setItemSize(arg_14_0.content:getWidth(), arg_14_0.content:getHeight())
		arg_14_0:getList():addItem(var_14_2)
		arg_14_0:getList():scrollTo(0, arg_14_0:nodeByName("list"):getHeight() - arg_14_0.content:getHeight())
	else
		for iter_14_8, iter_14_9 in ipairs(arg_14_0.itemA) do
			local var_14_3 = iter_14_9:getChildByName("unlimit_background")

			var_14_3:getChildByName("unlimit_label"):setString(math.ceil(iter_14_9.fighter.harms))
			var_14_3:getChildByName("unlimit_bar"):setPercent(iter_14_9.fighter.harms / var_14_0 * 100)
			xyd.setAvatarBorderNewUI(iter_14_9.fighter.hero_, iter_14_9:getChildByName("avatar"))

			if iter_14_9.fighter.willDie ~= nil then
				if iter_14_9.fighter.willDie == true then
					iter_14_9:getChildByName("dead_mark"):setVisible(true)
				end
			elseif not iter_14_9.fighter:canReborn() and iter_14_9.fighter:isDeath() then
				iter_14_9:getChildByName("dead_mark"):setVisible(true)
			elseif iter_14_9.fighter.reportDieCount_ and iter_14_9.fighter.reportDieCount_ ~= -1 then
				iter_14_9:getChildByName("dead_mark"):setVisible(true)
			end
		end

		local var_14_4 = arg_14_0:getList():newItem()

		var_14_4:addContent(arg_14_0.content)
		var_14_4:setItemSize(arg_14_0.content:getWidth(), arg_14_0.content:getHeight())
		arg_14_0:getList():addItem(var_14_4)
		arg_14_0:getList():scrollTo(0, arg_14_0:nodeByName("unlimit_list"):getHeight() - arg_14_0.content:getHeight())
	end
end

return var_0_0
