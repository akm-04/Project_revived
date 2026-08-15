local var_0_0 = class("ZhugeTeamInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.zhugeShop
local var_0_4 = xyd.tables.zhugeEventDialog
local var_0_5 = import("app.model.Hero")
local var_0_6 = import("framework.scheduler")
local var_0_7 = 5
local var_0_8 = 30

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.selectType = arg_1_2.selectType or xyd.ZhugeTeamWndType.NORMAL
	arg_1_0.eventID = arg_1_2.eventID or 0
	arg_1_0.dialogID = arg_1_2.dialogID or 0
	arg_1_0.mapIndex = arg_1_2.mapIndex or 0
	arg_1_0.curX_ = arg_1_2.x_
	arg_1_0.curY_ = arg_1_2.y_
	arg_1_0.isEndDialog = false
	arg_1_0.needUpdateMap_ = false
	arg_1_0.selectHero_ = nil
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayerWithNoTouchEvent()
	arg_2_0:initHeros()
	arg_2_0:initListview()
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0)
	if arg_3_0.touchHandler then
		var_0_6.unscheduleGlobal(arg_3_0.touchHandler)

		arg_3_0.touchHandler = nil
	end

	if arg_3_0.selectType == xyd.ZhugeTeamWndType.BATTLE_LOSE then
		if arg_3_0.zhugeModel:checkTeamHasAlive() then
			local var_3_0, var_3_1 = arg_3_0.zhugeModel:initEnemyInfo(var_0_4:resultNum(arg_3_0.dialogID))
			local var_3_2 = {
				isShowTips = true,
				showEnemy = true,
				teamType = xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM,
				enemyHeroes = var_3_0,
				enemyPets = var_3_1,
				specialParams = {
					eventID = arg_3_0.eventID,
					dialogID = arg_3_0.dialogID,
					mapIndex = arg_3_0.mapIndex,
					x_ = arg_3_0.curX_,
					y_ = arg_3_0.curY_
				}
			}

			xyd.WindowManager.get():openWindow("zhuge_new_select_team", var_3_2)
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("ZHUGE_ADVENTURE_TIPS_36")
			})
		end
	elseif arg_3_0.needUpdateMap_ then
		local var_3_3 = xyd.WindowManager.get():getWindow("zhuge_new_adventure")

		if var_3_3 and not tolua.isnull(var_3_3) then
			local var_3_4 = ""

			if arg_3_0.selectHero_ then
				var_3_4 = arg_3_0.selectHero_:getName()
			end

			var_3_3:updateAll(arg_3_0.curX_, arg_3_0.curY_, var_3_4)
		end
	end
end

function var_0_0.endCurDialog(arg_4_0, arg_4_1)
	local var_4_0 = {}

	if arg_4_1 then
		local var_4_1 = arg_4_0.zhugeModel:getHeroStatus(arg_4_1:getTableID())

		if var_4_1 then
			var_4_0.partner_id = var_4_1.init_id
		end

		arg_4_0.selectHero_ = arg_4_1
	end

	arg_4_0.zhugeModel:endCurDialog(arg_4_0.eventID, arg_4_0.dialogID, arg_4_0.mapIndex, var_4_0, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			arg_4_0.isEndDialog = true
			arg_4_0.needUpdateMap_ = true

			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.initHeros(arg_6_0)
	local var_6_0 = arg_6_0.zhugeModel:getMemberHeros()
	local var_6_1 = {}

	for iter_6_0 = 1, #var_6_0 do
		local var_6_2 = var_6_0[iter_6_0]
		local var_6_3 = arg_6_0.zhugeModel:getHeroStatus(var_6_2:getTableID())

		if arg_6_0.selectType == xyd.ZhugeTeamWndType.REBORN and var_6_3 and var_6_3.health == 2 then
			table.insert(var_6_1, var_6_2)
		elseif (arg_6_0.selectType == xyd.ZhugeTeamWndType.KILL_ONE or arg_6_0.selectType == xyd.ZhugeTeamWndType.ADD_BUFF or arg_6_0.selectType == xyd.ZhugeTeamWndType.BATTLE_LOSE) and var_6_3 and var_6_3.health ~= 2 then
			table.insert(var_6_1, var_6_2)
		elseif arg_6_0.selectType == xyd.ZhugeTeamWndType.NORMAL then
			table.insert(var_6_1, var_6_2)
		end
	end

	arg_6_0.heros = var_6_1
end

function var_0_0.updateHero(arg_7_0, arg_7_1)
	if arg_7_0:checkItemCanAwaken() then
		local var_7_0 = arg_7_1:afterAwakenID()

		arg_7_1:setTableID(var_7_0)
	end
end

function var_0_0.layout(arg_8_0)
	local var_8_0 = ""

	if arg_8_0.selectType == xyd.ZhugeTeamWndType.REBORN then
		var_8_0 = var_0_1:translation("ZHUGE_ADVENTURE_TIPS_6")
	elseif arg_8_0.selectType == xyd.ZhugeTeamWndType.KILL_ONE then
		var_8_0 = var_0_1:translation("ZHUGE_ADVENTURE_TIPS_7")
	elseif arg_8_0.selectType == xyd.ZhugeTeamWndType.ADD_BUFF then
		var_8_0 = var_0_1:translation("ZHUGE_ADVENTURE_TIPS_13")
	elseif arg_8_0.selectType == xyd.ZhugeTeamWndType.BATTLE_LOSE then
		var_8_0 = var_0_1:translation("ZHUGE_ADVENTURE_TIPS_29")
	else
		local var_8_1, var_8_2 = arg_8_0.zhugeModel:getTotalHp()

		var_8_0 = string.format(var_0_1:translation("ZHUGE_ADVENTURE_TIPS_5"), var_8_2, var_8_1)
	end

	arg_8_0:nodeByName("text_tips"):setString(var_8_0)
	arg_8_0:nodeByName("close"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended and arg_8_0:checkCanClose() then
			xyd.WindowManager.get():closeWindow(arg_8_0)
		end
	end)
end

function var_0_0.checkCanClose(arg_10_0)
	if arg_10_0.selectType == xyd.ZhugeTeamWndType.NORMAL then
		return true
	elseif not arg_10_0.isEndDialog then
		if #arg_10_0.heros == 0 then
			arg_10_0:endCurDialog()

			return false
		end

		local var_10_0 = ""

		if arg_10_0.selectType == xyd.ZhugeTeamWndType.REBORN then
			var_10_0 = var_0_1:translation("ZHUGE_ADVENTURE_TIPS_6")
		elseif arg_10_0.selectType == xyd.ZhugeTeamWndType.KILL_ONE then
			var_10_0 = var_0_1:translation("ZHUGE_ADVENTURE_TIPS_7")
		elseif arg_10_0.selectType == xyd.ZhugeTeamWndType.ADD_BUFF then
			var_10_0 = var_0_1:translation("ZHUGE_ADVENTURE_TIPS_13")
		elseif arg_10_0.selectType == xyd.ZhugeTeamWndType.BATTLE_LOSE then
			var_10_0 = var_0_1:translation("ZHUGE_ADVENTURE_TIPS_29")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_10_0
		})

		return false
	end

	return true
end

function var_0_0.initListview(arg_11_0)
	local var_11_0 = arg_11_0:nodeByName("list")
	local var_11_1 = var_11_0:getContentSize().width
	local var_11_2 = var_11_0:getContentSize().height

	arg_11_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_11_1, var_11_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_11_0)

	arg_11_0.list:setDelegate(handler(arg_11_0, arg_11_0.delegate))
end

function var_0_0.delegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = math.ceil(#arg_12_0.heros / var_0_7)

	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return var_12_0
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		local var_12_1
		local var_12_2
		local var_12_3
		local var_12_4 = arg_12_0.list:dequeueItem()

		if not var_12_4 then
			var_12_4 = arg_12_0.list:newItem()
		else
			var_12_4:removeAllChildren()
		end

		local var_12_5 = display.newNode()

		var_12_5:setTouchSwallowEnabled(false)

		for iter_12_0 = 1, var_0_7 do
			local var_12_6 = (arg_12_3 - 1) * var_0_7 + iter_12_0

			if var_12_6 > #arg_12_0.heros then
				break
			end

			var_12_3 = display.newNode()

			arg_12_0:initHeroItem(var_12_3, var_12_6)

			local var_12_7 = var_12_3:getContentSize().width
			local var_12_8 = var_12_3:getContentSize().height
			local var_12_9 = (arg_12_0.list.viewRect_.width - var_12_7 * var_0_7) / (var_0_7 + 1)

			var_12_3:pos(var_12_9 * iter_12_0 + (iter_12_0 - 1) * var_12_7 + var_12_7 / 2, var_0_8 + var_12_8 / 2 - 2)
			var_12_5:addChild(var_12_3)
		end

		var_12_5:setContentSize(cc.size(arg_12_0.list.viewRect_.width, var_12_3:getContentSize().height + var_0_8))
		var_12_4:setItemSize(arg_12_0.list.viewRect_.width, var_12_3:getContentSize().height + var_0_8)
		var_12_4:addContent(var_12_5)

		return var_12_4
	end
end

function var_0_0.initHeroItem(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_0.heros[arg_13_2]
	local var_13_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")

	var_13_1:getChildByName("yongbing_tubiao"):setVisible(false)

	local var_13_2 = var_13_1:getChildByName("background"):getContentSize()

	var_13_1:setContentSize(var_13_2)
	arg_13_1:setContentSize(var_13_2)
	xyd.setAvatarBorder(var_13_0, var_13_1:getChildByName("avatar"))

	local var_13_3 = var_13_1:getChildByName("chosen")

	var_13_3:setLocalZOrder(100)
	var_13_3:setVisible(false)

	local var_13_4 = var_13_1:getChildByName("avatar_mask")

	var_13_4:setLocalZOrder(2)
	var_13_4:setVisible(false)
	var_13_1:getChildByName("is_can_rent"):setVisible(false)

	for iter_13_0 = 1, 3 do
		var_13_1:getChildByName("team" .. iter_13_0):setVisible(false)
	end

	var_13_1:getChildByName("lv_txt"):setString(var_13_0:getLevel())

	local var_13_5 = var_13_1:getChildByName("name_text")

	var_13_5:setString(var_13_0:getName())
	var_13_5:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[var_13_0:getColor()] ~= "" then
		local var_13_6 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_13_5:getX() + var_13_5:getWidth() / 2 - 10,
			y = var_13_5:getY(),
			color = xyd.color.HERO_QUALITY[var_13_0:getColor()],
			text = xyd.Color2Level[var_13_0:getColor()]
		}
		local var_13_7 = xyd.AssetLoader.get():loadLabel(var_13_6)

		var_13_7:addTo(var_13_1)
		var_13_7:align(display.CENTER_LEFT)
		var_13_7:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_13_5:x(var_13_5:getX() - 15)
	end

	local var_13_8 = var_13_1:getChildByName("hp_bar")
	local var_13_9 = var_13_1:getChildByName("mp_bar")
	local var_13_10 = var_13_1:getChildByName("dead_text")

	var_13_10:setString(var_0_1:translation("ALREADY_DEAD"))

	if var_13_10 then
		var_13_10:setVisible(false)
	end

	if xyd.tables.zhugeHero:zhugeSkill(var_13_0:getTableID()) ~= 0 and var_13_0.partner_type ~= 1 and var_13_0.partner_type ~= 5 then
		local var_13_11 = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/skill_icon.png")

		var_13_11:addTo(arg_13_1)
		var_13_11:setAnchorPoint(cc.p(0.5, 0.5))
		var_13_11:setPosition(cc.p(110, 120))
		var_13_11:setLocalZOrder(100)
	end

	local var_13_12 = false
	local var_13_13 = arg_13_0.zhugeModel:getHeroStatus(var_13_0:getTableID())

	if var_13_13 and next(var_13_13) ~= nil then
		arg_13_0:updateHeroAvatar(var_13_1, arg_13_1, var_13_0, var_13_13)
	else
		var_13_8:hide()
		var_13_9:hide()
		var_13_1:getChildByName("hp_di"):hide()
		var_13_1:getChildByName("mp_di"):hide()
	end

	var_13_1:setName("layout")
	var_13_1:setPosition(cc.p(0, 0))

	arg_13_1.data = var_13_0
	var_13_0.isDead = var_13_12

	arg_13_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_13_1:addChild(var_13_1)
	arg_13_1:setTouchSwallowEnabled(false)

	local var_13_14 = false

	arg_13_1:setTouchEnabled(true)
	arg_13_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" then
			arg_13_1:setScale(0.9)

			arg_13_0.startClick_ = true
			arg_13_0.prevX_ = arg_14_0.x
			arg_13_0.prevY_ = arg_14_0.y
			var_13_14 = false

			if xyd.tables.zhugeHero:zhugeSkill(var_13_0:getTableID()) ~= 0 and var_13_0.partner_type ~= 1 and var_13_0.partner_type ~= 5 then
				local var_14_0 = 0

				local function var_14_1()
					var_14_0 = var_14_0 + 0.1

					if var_14_0 > 0.5 then
						var_13_14 = true

						local var_15_0 = arg_13_1:getParent():convertToWorldSpace(cc.p(arg_13_1:getPosition()))

						arg_13_0:showSkillDetail(true, var_15_0, var_13_0)
					else
						var_13_14 = false
					end
				end

				arg_13_0.touchHandler = var_0_6.scheduleGlobal(var_14_1, 0.1)
			end

			return true
		elseif arg_14_0.name == "moved" then
			if math.abs(arg_14_0.y - arg_13_0.prevY_) > 15 or math.abs(arg_14_0.x - arg_13_0.prevX_) > 15 then
				arg_13_0.startClick_ = false

				arg_13_1:setScale(1)

				if arg_13_0.touchHandler then
					var_0_6.unscheduleGlobal(arg_13_0.touchHandler)
				end

				arg_13_0:showSkillDetail(false)

				var_13_14 = false
			end
		elseif arg_14_0.name == "ended" and arg_13_0.startClick_ then
			arg_13_1:setScale(1)

			if arg_13_0.touchHandler then
				var_0_6.unscheduleGlobal(arg_13_0.touchHandler)
			end

			if var_13_14 then
				arg_13_0:showSkillDetail(false)

				return
			end

			arg_13_0:clickAvatar(arg_13_1, var_13_0)
		end

		return true
	end)
end

function var_0_0.clickAvatar(arg_16_0, arg_16_1, arg_16_2)
	if arg_16_0.selectType == xyd.ZhugeTeamWndType.NORMAL then
		return
	end

	local var_16_0 = ""

	if arg_16_0.selectType == xyd.ZhugeTeamWndType.REBORN then
		var_16_0 = string.format(var_0_1:translation("ZHUGE_ADVENTURE_TIPS_3"), arg_16_2:getName())
	elseif arg_16_0.selectType == xyd.ZhugeTeamWndType.KILL_ONE or arg_16_0.selectType == xyd.ZhugeTeamWndType.BATTLE_LOSE then
		var_16_0 = string.format(var_0_1:translation("ZHUGE_ADVENTURE_TIPS_4"), arg_16_2:getName())
	elseif arg_16_0.selectType == xyd.ZhugeTeamWndType.ADD_BUFF then
		var_16_0 = string.format(var_0_1:translation("ZHUGE_ADVENTURE_TIPS_14"), arg_16_2:getName())
	end

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_16_0, function()
		if arg_16_0 and not tolua.isnull(arg_16_0) then
			arg_16_0:endCurDialog(arg_16_2)
		end
	end, nil, nil, arg_16_0.colorMode)
end

function var_0_0.showSkillDetail(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	if not arg_18_1 then
		if arg_18_0.skillDetail and not tolua.isnull(arg_18_0.skillDetail) then
			arg_18_0.skillDetail:setVisible(false)
		end

		return
	end

	if not arg_18_0.skillDetail then
		local var_18_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/select_team/adventure_skill.csb")

		var_18_0:addTo(arg_18_0)

		arg_18_0.skillDetail = var_18_0
	end

	local var_18_1 = arg_18_0.skillDetail:getChildByName("container")
	local var_18_2 = var_18_1:getContentSize()

	arg_18_0.skillDetail:setPosition(cc.p(arg_18_2.x, arg_18_2.y - var_18_2.height / 2))
	var_18_1:getChildByName("text_name"):setString(arg_18_3:getName())
	var_18_1:getChildByName("text_lev"):setString("lv." .. arg_18_3:getLevel())
	var_18_1:getChildByName("text_hero_tips"):setString(arg_18_3:getDes())

	local var_18_3 = arg_18_3:getTableID()
	local var_18_4 = xyd.tables.zhugeHero:zhugeSkill(var_18_3)
	local var_18_5 = xyd.tables.zhugeSkill:name(var_18_4)
	local var_18_6 = arg_18_0:getSkillDesc(var_18_4)

	var_18_1:getChildByName("text_skill"):setString(var_18_5)
	var_18_1:getChildByName("text_skill__desc"):setString(var_18_6)
	xyd.setAvatarBorder(arg_18_3, var_18_1:getChildByName("hero"))
	arg_18_0.skillDetail:setVisible(true)
end

function var_0_0.getSkillDesc(arg_19_0, arg_19_1)
	local var_19_0 = xyd.tables.zhugeSkill:desc(arg_19_1)
	local var_19_1 = xyd.tables.zhugeSkill:type(arg_19_1)
	local var_19_2 = xyd.tables.zhugeSkill:num(arg_19_1)[1]

	return (string.format(var_19_0, var_19_2))
end

function var_0_0.updateHeroAvatar(arg_20_0, arg_20_1, arg_20_2, arg_20_3, arg_20_4)
	if not arg_20_4 then
		return
	end

	local var_20_0 = arg_20_1:getChildByName("hp_bar")
	local var_20_1 = arg_20_1:getChildByName("mp_bar")
	local var_20_2 = arg_20_1:getChildByName("dead_text")

	var_20_2:setVisible(false)

	local var_20_3 = arg_20_1:getChildByName("avatar_mask")

	var_20_3:setVisible(false)

	local var_20_4 = false

	arg_20_3.healthStatus = arg_20_4

	if arg_20_4 and arg_20_4.health then
		local var_20_5 = 0
		local var_20_6 = 0

		if arg_20_4.health == 0 then
			var_20_5 = 100
			var_20_6 = arg_20_4.mp / 10
		elseif arg_20_4.health == 1 and arg_20_4.hp >= 1 then
			var_20_5 = arg_20_4.hp / arg_20_4.max_hp * 100
			var_20_6 = arg_20_4.mp / 10
		else
			var_20_5 = 0
			var_20_6 = 0

			var_20_3:setVisible(true)
			var_20_2:setLocalZOrder(3)
			var_20_2:setVisible(true)
			var_20_2:enableOutline(cc.c4b(0, 0, 0), 2)
			var_20_2:getVirtualRenderer():setAdditionalKerning(-2)

			var_20_4 = true
		end

		var_20_0:setPercent(var_20_5)
		var_20_0:setVisible(true)
		var_20_1:setPercent(var_20_6)
		var_20_1:setVisible(true)
	end

	arg_20_3.isDead = var_20_4
end

function var_0_0.didOpen(arg_21_0, arg_21_1)
	var_0_0.super:didOpen(arg_21_1)
	arg_21_0:addBlockLayerWithNoTouchEvent()
	arg_21_0.list:reload()
end

return var_0_0
