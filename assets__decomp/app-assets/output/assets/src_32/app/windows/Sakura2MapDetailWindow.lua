local var_0_0 = class("Sakura2MapDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")

var_0_0.START_BUTTON = "start"
var_0_0.TXT_NAME = "txt_name"
var_0_0.TXT_DESC = "txt_desc"
var_0_0.TXT_XIAOHAO = "txt_xiaohao"
var_0_0.TXT_ENERGY = "txt_energy"
var_0_0.TXT_ENEMY = "txt_enemy"
var_0_0.TXT_EQUIP = "txt_equip"
var_0_0.PANEL_EQUIP = "panel_equip"
var_0_0.PANEL_ENEMY = "panel_enemy"
var_0_0.PANEL_SWEEP = "panel_sweep"
var_0_0.PANEL_LEFT = "panel_left"

local var_0_2 = 113
local var_0_3 = import("app.model.Hero")
local var_0_4 = import("app.model.Pet")
local var_0_5 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.campaignID = arg_1_2.campaignID
	arg_1_0.campaignType = arg_1_2.campaignType
	arg_1_0.sakura = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA)
	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_1_0:setTouchSwallowEnabled(true)
end

function var_0_0.layout(arg_2_0)
	arg_2_0:nodeByName("clgStar_container"):setVisible(false)
	arg_2_0:nodeByName("star_container"):setVisible(false)
	arg_2_0:nodeByName("panel_challenge"):setVisible(false)
	arg_2_0:nodeByName(var_0_0.PANEL_SWEEP):setVisible(false)

	local var_2_0 = arg_2_0.campaignID

	arg_2_0:nodeByName("title_pos"):setString(xyd.tables.activitySakura2Campaign:campaignName(var_2_0))

	local var_2_1 = xyd.tables.activitySakura2Campaign:campaignDes(var_2_0)

	arg_2_0:nodeByName(var_0_0.TXT_DESC):setString(var_2_1)

	local var_2_2 = xyd.tables.campaign:energyCost(var_2_0)

	arg_2_0:nodeByName(var_0_0.TXT_ENERGY):setString(0)
	arg_2_0:nodeByName(var_0_0.TXT_XIAOHAO):setString(var_0_5:translation("MAP_TILI_TXT"))
	arg_2_0:nodeByName(var_0_0.TXT_ENEMY):setString(var_0_5:translation("MAP_ENEMY_TXT"))
	arg_2_0:nodeByName(var_0_0.TXT_EQUIP):setString(var_0_5:translation("MAP_GET_TXT"))

	local var_2_3 = xyd.tables.activitySakura2Campaign:monsterDisplay(var_2_0)
	local var_2_4 = arg_2_0.player_.lev
	local var_2_5 = xyd.tables.activitySakura2Monster:getColorByLevel(var_2_4)
	local var_2_6 = xyd.tables.activitySakura2Monster:star(color)

	arg_2_0.monsterTips = {}

	for iter_2_0 = 1, #var_2_3 do
		local var_2_7 = {}
		local var_2_8 = cc.Node:create()

		if iter_2_0 ~= #var_2_3 then
			var_2_7.isBoss = false

			var_2_8:setContentSize(110, 110)
		else
			var_2_7.isBoss = true

			var_2_8:setContentSize(127, 127)
		end

		xyd.setAvatarBorder(var_2_3[iter_2_0], var_2_8, var_2_5, var_2_6)
		arg_2_0:nodeByName(var_0_0.PANEL_ENEMY):addChild(var_2_8)
		var_2_8:setPosition(iter_2_0 * 120 - 120, 0)

		var_2_7.id = var_2_3[iter_2_0]
		var_2_7.lev = level
		var_2_7.quality = var_2_5
		var_2_7.name = xyd.tables.hero:name(var_2_3[iter_2_0])
		var_2_7.desc = xyd.tables.hero:getDes(var_2_3[iter_2_0])
		var_2_7.isHero = true

		local var_2_9, var_2_10 = var_2_8:getPosition()

		var_2_8:setTouchEnabled(true)
		var_2_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
			if arg_3_0.name == "began" then
				local var_3_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_3_1 = arg_2_0:convertToWorldSpace(cc.p(0, 0))

				if not var_3_0 then
					local var_3_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_2_7)

					xyd.adaptToWorldPosition(var_2_8, var_3_2)
				end

				return true
			elseif arg_3_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_3_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end

	arg_2_0:nodeByName("panel_equip"):removeAllChildren()

	local var_2_11 = xyd.tables.activitySakura2Campaign:itemDisplay(var_2_0)

	arg_2_0.itemTips = {}

	local var_2_12 = {
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName(var_0_0.PANEL_EQUIP):getContentSize().width, var_0_2),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}

	arg_2_0.listview = cc.ui.UIListView.new(var_2_12):addTo(arg_2_0:nodeByName(var_0_0.PANEL_EQUIP)):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	for iter_2_1 = 1, #var_2_11 do
		local var_2_13 = cc.Node:create()
		local var_2_14 = display.newNode()
		local var_2_15 = arg_2_0.listview:newItem()

		var_2_13:setContentSize(114, 113)
		xyd.setItemBorder(var_2_13, var_2_11[iter_2_1])

		local var_2_16 = {
			id = var_2_11[iter_2_1]
		}

		arg_2_0:addTips(var_2_13, var_2_16)
		var_2_14:addChild(var_2_13)
		var_2_14:setContentSize(var_0_2, var_0_2)
		var_2_15:addContent(var_2_14)
		var_2_15:setItemSize(var_0_2, var_0_2)
		arg_2_0.listview:addItem(var_2_15)
	end

	arg_2_0.listview:reload()
	arg_2_0:updateLayout()
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevX_ = arg_4_1.x
	elseif arg_4_1.name == "moved" and 20 <= math.abs(arg_4_1.x - arg_4_0.prevX_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateLayout(arg_5_0)
	arg_5_0:nodeByName(var_0_0.PANEL_LEFT):setVisible(false)
end

function var_0_0.willOpen(arg_6_0, arg_6_1)
	var_0_0.super.willOpen(arg_6_0, arg_6_1)
	arg_6_0:layout()
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super.didOpen(arg_7_0, arg_7_1)
	arg_7_0:nodeByName(var_0_0.START_BUTTON):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_8_0 = {
				type = xyd.SelectTeamType.SAKURA2_WAR,
				campaignID = arg_7_0.campaignID,
				campaignType = arg_7_0.campaignType,
				selected = arg_7_0.sakura:getPreHeroIDs(),
				preHeros = arg_7_0.sakura:getPreHeros(),
				prePet = arg_7_0.sakura:getPrePet()
			}

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "sakura_battle"
				}
			})
			xyd.WindowManager.get():retainHistory()
			cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.WINDOW_DID_CLOSE, function(arg_9_0)
				if arg_9_0.windowName == "battle_select_team" and arg_7_0 and arg_7_0.sakura then
					arg_7_0.sakura:hideWindows()
				end
			end)
			xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_8_0)
		end
	end)
end

return var_0_0
