local var_0_0 = class("FumoWindow", import("app.common.ui.BaseWindow"))

var_0_0.CHOOSE_BUTTON = "choose"
var_0_0.PANEL_EQUIP = "panel_equip"
var_0_0.PANEL_ATTR = "panel_attr"
var_0_0.PANEL_PROCESS = "panel_process"
var_0_0.PANEL_FUMO = "panel_fumo"
var_0_0.ITEM_LIST = "item_list"
var_0_0.ATTR_LIST = "attr_list"
var_0_0.TOUXIANG = "touxiang"
var_0_0.PROCESS_BAR = "process_bar"
var_0_0.PROCESS_BAR2 = "process_bar2"
var_0_0.TXT_PROCESS = "txt_process"
var_0_0.BTN_FUMO = "btn_fumo"
var_0_0.BTN_YIJIAN = "btn_yijian"
var_0_0.TXT_CHOOSE = "txt_choose"
var_0_0.TXT_FUMO = "txt_fumo"
var_0_0.TXT_YIJIAN = "txt_yijian"
var_0_0.TXT_TYPE = "txt_type"
var_0_0.TXT_JINBI = "txt_jinbi"
var_0_0.TXT_NAME = "txt_equip"
var_0_0.FUMO_TYPE = "fumo_type"
var_0_0.HERO_NAME = "txt_hero_name"

local var_0_1 = import("app.windows.FumoItem")
local var_0_2 = import("app.windows.NewEquipItem")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = 7
local var_0_5 = 120
local var_0_6 = import("framework.scheduler")
local var_0_7 = {
	xyd.ItemType.EQUIPMENT,
	xyd.ItemType.REEL,
	xyd.ItemType.EQUIPMENT_FRAGMENT,
	xyd.ItemType.REEL_FRAGMENT
}
local var_0_8 = xyd.tables.translation
local var_0_9 = {
	var_0_8:translation("PUTONG_FUMO"),
	var_0_8:translation("GAOJI_FUMO"),
	var_0_8:translation("ZHUANJIA_FUMO"),
	var_0_8:translation("ZONGSHI_FUMO"),
	var_0_8:translation("CHUANSHUO_FUMO")
}
local var_0_10 = {
	yijian = var_0_8:translation("YIJIAN_FUMO"),
	fumo = var_0_8:translation("FUMO"),
	txt_choose = var_0_8:translation("SELECT_HERO"),
	txt_chat = var_0_8:translation("FUMO_TXT_CHAT")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()

	arg_2_0.panelEquip_ = arg_2_0:nodeByName(var_0_0.PANEL_EQUIP)
	arg_2_0.panelAttr_ = arg_2_0:nodeByName(var_0_0.PANEL_ATTR)
	arg_2_0.panelProcess_ = arg_2_0:nodeByName(var_0_0.PANEL_PROCESS)
	arg_2_0.panelFumo_ = arg_2_0:nodeByName(var_0_0.PANEL_FUMO)
	arg_2_0.touxiang_ = arg_2_0:nodeByName(var_0_0.TOUXIANG)
	arg_2_0.txtChoose_ = arg_2_0:nodeByName(var_0_0.TXT_CHOOSE)
	arg_2_0.processBar = arg_2_0:nodeByName(var_0_0.PROCESS_BAR)
	arg_2_0.processBar2 = arg_2_0:nodeByName(var_0_0.PROCESS_BAR2)
	arg_2_0.txtProcess = arg_2_0:nodeByName(var_0_0.TXT_PROCESS)
	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:listItems()

	arg_2_0.items = {}
	arg_2_0.monengItems = {}
	arg_2_0.equipItems = {}
	arg_2_0.quickTimes = 0
	arg_2_0.maxTime = xyd.tables.dailyConsume:getNum(xyd.DailyConsumeType.Magicka)
	arg_2_0.buyCoinCost = xyd.tables.dailyConsume:getCost(xyd.DailyConsumeType.Magicka)

	arg_2_0:nodeByName("txt_zuanshi"):setString(tostring(arg_2_0.buyCoinCost))
	arg_2_0.txtChoose_:setString(var_0_10.txt_choose)
	arg_2_0:initLayout()
	xyd.Backend.get():request(xyd.mid.DAILY_CONSUNME_LOAD, {}, function(arg_3_0, arg_3_1)
		local var_3_0 = arg_3_1.buy_times

		arg_2_0.quickTimes = tonumber(string.sub(var_3_0, 3, 3))
	end, {}, false, true)

	arg_2_0.attrListContainer = arg_2_0:nodeByName(var_0_0.ATTR_LIST)

	local var_2_0 = arg_2_0.attrListContainer:getContentSize()

	arg_2_0.attrList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_2_0.attrListContainer)
end

function var_0_0.listItems(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("item_list")

	arg_4_0.itemList_ = {}

	var_4_0:removeAllChildren()

	arg_4_0.itemList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, 900, 255),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_4_0):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.itemList_:setDelegate(handler(arg_4_0, arg_4_0.itemDelegate))
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevX_ = arg_5_1.x
		arg_5_0.prevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" then
		local var_5_0 = 20

		if var_5_0 <= math.abs(arg_5_1.x - arg_5_0.prevX_) or var_5_0 <= math.abs(arg_5_1.y - arg_5_0.prevY_) then
			arg_5_0.scrollViewMoved_ = true
		end
	elseif arg_5_1.name == "ended" then
		arg_5_0.prevX_ = arg_5_1.x
		arg_5_0.prevY_ = arg_5_1.y
	end
end

function var_0_0.initLayout(arg_6_0)
	arg_6_0.panelEquip_:setVisible(false)
	arg_6_0.panelAttr_:setVisible(false)
	arg_6_0.panelProcess_:setVisible(false)
	arg_6_0.panelFumo_:setVisible(false)
	arg_6_0.itemList_:setVisible(false)
	arg_6_0:nodeByName("bg_fumo"):setVisible(false)
	arg_6_0:nodeByName("bg_fumo_touming"):setVisible(true)
	arg_6_0:nodeByName("pic_succeed"):setVisible(false)
	arg_6_0:nodeByName("panel_board"):setVisible(true)
	arg_6_0:nodeByName("txt_chat"):setString(var_0_10.txt_chat)
end

function var_0_0.didOpen(arg_7_0)
	arg_7_0.effect = {}

	xyd.WindowManager.get():openWindow("toast", {
		message = var_0_8:translation("ENCHANT_SELECT_PARTNER")
	})
	arg_7_0:nodeByName(var_0_0.CHOOSE_BUTTON):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			arg_7_0:nodeByName(var_0_0.CHOOSE_BUTTON):setScale(0.9)
		end

		if arg_8_1 == ccui.TouchEventType.moved then
			arg_7_0:nodeByName(var_0_0.CHOOSE_BUTTON):setScale(1)
		end

		if arg_8_1 == ccui.TouchEventType.ended then
			arg_7_0:nodeByName(var_0_0.CHOOSE_BUTTON):setScale(1)
			xyd.WindowManager.get():openWindow("fumo_hero")
		end
	end)
	arg_7_0:nodeByName("txt_yijian"):setString(var_0_10.yijian)
	arg_7_0:nodeByName(var_0_0.BTN_YIJIAN):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			arg_7_0:nodeByName(var_0_0.BTN_YIJIAN):setScale(0.9)
		end

		if arg_9_1 == ccui.TouchEventType.ended then
			arg_7_0:nodeByName(var_0_0.BTN_YIJIAN):setScale(1)

			local function var_9_0()
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("DAILY_FUMO_INFO"), function()
					if arg_7_0.player_.crystal < arg_7_0.buyCoinCost then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_8:translation("ZUANSHI_ABSENCE"), function()
							local var_12_0 = {}

							var_12_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_12_0)
						end, nil, nil, arg_7_0.colorMode)

						return
					end

					local var_11_0 = {
						partner_id = arg_7_0.hero_:getHeroID(),
						equip_index = arg_7_0.equipIndex,
						consume_id = xyd.DailyConsumeType.Magicka
					}

					xyd.Backend.get():request(xyd.mid.DAILY_CONSUNME, var_11_0, function(arg_13_0, arg_13_1)
						if arg_13_0 == xyd.error.OK then
							arg_7_0.quickTimes = arg_7_0.quickTimes + 1
							arg_7_0.items = {}
							arg_7_0.materials = {}
							arg_7_0.initMoneng = 0
							arg_7_0.equipItem.moneng_ = arg_13_1.fumo

							arg_7_0.player_:getHeroByID(var_11_0.partner_id):updateFumo(arg_13_1.fumo, var_11_0.equip_index)
							arg_7_0:updateEquipByID(arg_7_0.equipIndex, true)
							arg_7_0:updateEquipAttr(var_11_0.equip_index)
							arg_7_0:updateProcess(false)
							arg_7_0.itemList_:reload()
						end
					end, {
						player_id = playerID
					}, false, true)
				end, nil, 0, arg_7_0.colorMode)
			end

			if arg_7_0.quickTimes >= arg_7_0.maxTime then
				local var_9_1 = xyd.tables.translation:translation("DAILY_TIMES_OVER")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_1
				})

				return
			elseif arg_7_0.equipItem.moneng_ >= arg_7_0.equipItem:getTotalFumo() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_8:translation("ENCHANT_MAX")
				})

				return
			else
				var_9_0()
			end
		end
	end)
	arg_7_0:nodeByName("txt_fumo"):setString(var_0_10.fumo)
	arg_7_0:nodeByName(var_0_0.BTN_FUMO):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.began then
			arg_7_0:nodeByName(var_0_0.BTN_FUMO):setScale(0.9)
		end

		if arg_14_1 == ccui.TouchEventType.ended then
			arg_7_0:nodeByName(var_0_0.BTN_FUMO):setScale(1)

			if not arg_7_0.materials or #arg_7_0.materials <= 0 then
				return
			end

			local function var_14_0()
				local var_15_0 = {
					partner_id = arg_7_0.hero_:getHeroID(),
					materials = arg_7_0.materials,
					equip_index = arg_7_0.equipIndex
				}

				xyd.Backend.get():request(xyd.mid.FUMO, var_15_0, function(arg_16_0, arg_16_1, arg_16_2)
					if arg_16_0 == xyd.error.OK then
						local var_16_0 = var_15_0.materials

						arg_7_0.hero_.fumoLev_ = arg_16_1.fumo_lev

						for iter_16_0 = 1, #var_16_0 do
							local var_16_1 = {
								itemID = var_16_0[iter_16_0]
							}

							var_16_1.itemNum = 1

							arg_7_0.player_:getBackpack():removeItem(var_16_1)
							arg_7_0.player_:getHeroByID(var_15_0.partner_id):updateFumo(arg_16_1.fumo, var_15_0.equip_index)
						end

						arg_7_0.items = {}
						arg_7_0.materials = {}
						arg_7_0.initMoneng = 0

						arg_7_0:updateEquipByID(arg_7_0.equipIndex, true)
						arg_7_0:updateProcess(false)
						arg_7_0:updateEquipAttr(var_15_0.equip_index)
						arg_7_0:updateListWithOutReload()
					end
				end, {
					player_id = playerID
				}, false, true)
			end

			if arg_7_0:getTotalFumo() * xyd.tables.item:fumoMana(arg_7_0.equipItem:getTableID()) > arg_7_0.player_.mana then
				xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):judgePush(4)
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_8:translation("JINBI_ABSENCE"), function()
					local var_17_0 = xyd.FunctionID.ID_GOLD_HAND

					if arg_7_0.player_:isFuncOpen(var_17_0) == true then
						xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
					else
						local var_17_1 = xyd.tables.functionOpen:level(var_17_0)
						local var_17_2 = string.format(var_0_8:translation("FUNCTION_OPEN_TIP_LEVEL"), var_17_1)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_17_2
						})
					end
				end, nil, nil, arg_7_0.colorMode)
			else
				var_14_0()
			end
		end
	end)
end

function var_0_0.updateListWithOutReload(arg_18_0)
	local var_18_0 = 0
	local var_18_1 = arg_18_0.itemList_.scrollNode:getPositionY()

	if var_18_1 > 0 then
		if var_18_1 > var_0_5 * math.ceil(#arg_18_0:getMonengItems() / var_0_4) and var_18_1 > arg_18_0.itemList_:getViewRectInWorldSpace().height then
			var_18_1 = var_0_5 * math.ceil(#arg_18_0:getMonengItems() / var_0_4)
		end

		arg_18_0.itemList_.scrollNode:setPosition(0, var_18_1)
	end

	arg_18_0.idx = math.floor(var_18_1 / var_0_5)

	for iter_18_0 = -1, 1 do
		local var_18_2 = false

		if arg_18_0.idx + iter_18_0 > 0 then
			if arg_18_0:getMonengItems()[(arg_18_0.idx + iter_18_0) * var_0_4 - (var_0_4 - 1)] and arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - (var_0_4 - 1)] ~= nil then
				for iter_18_1 = var_0_4 - 1, 0, -1 do
					if arg_18_0:getMonengItems()[(arg_18_0.idx + iter_18_0) * var_0_4 - iter_18_1] ~= nil and arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - iter_18_1] and arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - iter_18_1].setParams then
						arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - iter_18_1]:setParams(arg_18_0:getMonengItems()[(arg_18_0.idx + iter_18_0) * var_0_4 - iter_18_1])
						arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - iter_18_1]:contentView():nodeByName("decrease"):setVisible(false)
					else
						if arg_18_0:getMonengItems() and arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - iter_18_1] and not tolua.isnull(arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - iter_18_1]) then
							arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - iter_18_1]:setVisible(false)

							arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - iter_18_1] = nil
						end

						var_18_2 = true

						break
					end
				end
			else
				if arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - (var_0_4 - 1)] and arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - 2] == nil and not tolua.isnull(arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - (var_0_4 - 1)]) then
					arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - (var_0_4 - 1)]:setVisible(false)

					arg_18_0.cells[(arg_18_0.idx + iter_18_0) * var_0_4 - (var_0_4 - 1)] = nil
				end

				var_18_2 = true

				break
			end
		end

		if var_18_2 == true then
			break
		end
	end
end

function var_0_0.setHero(arg_19_0, arg_19_1)
	arg_19_0:initLayout()
	arg_19_0:nodeByName("panel_board"):setVisible(false)
	arg_19_0:nodeByName("bg_fumo"):setVisible(true)
	arg_19_0:nodeByName("bg_fumo_touming"):setVisible(false)

	arg_19_0.hero_ = arg_19_1
	arg_19_0.items = {}
	arg_19_0.materials = {}
	arg_19_0.initMoneng = 0
	arg_19_0.equip = nil

	arg_19_0:nodeByName(var_0_0.HERO_NAME):removeAllChildren()

	local var_19_0 = cc.Node:create()
	local var_19_1 = arg_19_1:getName()
	local var_19_2 = {
		color = cc.c3b(255, 255, 255),
		text = var_19_1
	}
	local var_19_3 = xyd.AssetLoader:get():loadLabel(var_19_2)

	var_19_0:addChild(var_19_3)
	var_19_3:setAnchorPoint(cc.p(0, 0))

	local var_19_4 = arg_19_0:nodeByName(var_0_0.HERO_NAME):getContentSize().width - var_19_3:getContentSize().width

	var_19_0:setPosition(var_19_4 / 2, 2)
	var_19_0:setAnchorPoint(cc.p(0, 0))
	arg_19_0:nodeByName(var_0_0.HERO_NAME):addChild(var_19_0)
	arg_19_0.touxiang_:removeAllChildren()
	arg_19_0:nodeByName("bg_touxiang"):setVisible(false)
	xyd.setAvatarBorderNewUI(arg_19_0.hero_, arg_19_0.touxiang_)

	local var_19_5 = xyd.AssetLoader.get():loadSprite("windows/common/lv_di.png")

	var_19_5:setScale(1.3)

	local var_19_6 = var_19_5:getWidth()
	local var_19_7 = arg_19_0.touxiang_:getWidth()
	local var_19_8 = arg_19_0.touxiang_:getHeight()

	var_19_5:setAnchorPoint(cc.p(0, 0.5))
	var_19_5:addTo(arg_19_0.touxiang_)
	var_19_5:setPosition(1, var_19_8 / 3)

	local var_19_9 = {
		size = 20,
		color = cc.c3b(255, 255, 255)
	}
	local var_19_10 = xyd.AssetLoader.get():loadLabel(var_19_9)

	var_19_10:setString(arg_19_1:getLevel())
	var_19_10:addTo(arg_19_0.touxiang_)
	var_19_10:setAnchorPoint(cc.p(0, 0.5))
	var_19_10:setPosition(8, var_19_5:getPositionY())
	var_19_10:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_19_0.touxiang_:getChildByName("border"):setLocalZOrder(var_19_10:getLocalZOrder() + 1)
	arg_19_0:updateEquip()
	arg_19_0.panelEquip_:setVisible(true)
end

function var_0_0.updateEquipByID(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = arg_20_0.hero_:getEquipByIndex(arg_20_1)
	local var_20_1 = "windows/fumo_window/common_effect_hero2_new"
	local var_20_2 = var_20_1 .. ".json"
	local var_20_3 = var_20_1 .. ".atlas"

	arg_20_0.effect[arg_20_1] = var_0_3.new(var_20_2, var_20_3, 1)

	arg_20_0.effect[arg_20_1]:setAnchorPoint(cc.p(0, 0))
	arg_20_0.effect[arg_20_1]:addTo(arg_20_0.panelEquip_)
	arg_20_0.effect[arg_20_1]:setPosition((arg_20_1 - 1) % 3 * 135 + 55, (1 - math.floor((arg_20_1 - 1) / 3)) * 135 + 55)

	if arg_20_0.equipItems[arg_20_1] and arg_20_2 then
		arg_20_0:nodeByName("pic_succeed"):setVisible(true)
		arg_20_0.equipItems[arg_20_1]:setParams(var_20_0, arg_20_2)
		arg_20_0.effect[arg_20_1]:play(function()
			arg_20_0:nodeByName("pic_succeed"):setVisible(false)
		end, false, 0.6)

		if var_20_0:getTableID() == 0 then
			arg_20_0.equipItems[arg_20_1]:contentView():nodeByName("not_equip"):setVisible(true)
		else
			arg_20_0.equipItems[arg_20_1]:contentView():nodeByName("not_equip"):setVisible(false)
		end
	else
		local var_20_4 = var_0_2.new()

		var_20_4:setParams(var_20_0)

		arg_20_0.equipItems[arg_20_1] = var_20_4

		if var_20_0:getTableID() == 0 then
			arg_20_0.equipItems[arg_20_1]:contentView():nodeByName("not_equip"):setVisible(true)
		else
			arg_20_0.equipItems[arg_20_1]:contentView():nodeByName("not_equip"):setVisible(false)
		end

		var_20_4.equipIndex = arg_20_1

		var_20_4:setPosition((arg_20_1 - 1) % 3 * 135, (1 - math.floor((arg_20_1 - 1) / 3)) * 135)
		arg_20_0.panelEquip_:addChild(var_20_4)
		var_20_4:setTouchEnabled(true)
		var_20_4:setTouchSwallowEnabled(false)
		var_20_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
			local var_22_0 = var_20_4:getEquipItem()

			if not var_22_0:isCollected() then
				return
			end

			if arg_22_0.name == "began" then
				var_20_4:contentView():nodeByName("container"):setScale(0.9)

				return true
			elseif arg_22_0.name == "ended" then
				if arg_20_0.lastEquipItem then
					for iter_22_0, iter_22_1 in ipairs(arg_20_0.monengItems) do
						arg_20_0.lastEquipItem:removeFumo(iter_22_1)
					end
				end

				arg_20_0.items = {}
				arg_20_0.materials = {}
				arg_20_0.monengItems = {}

				var_20_4:contentView():nodeByName("container"):setScale(1)

				local var_22_1 = var_22_0:getMaxFumoStar()

				if var_22_1 <= 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_8:translation("ENCHANT_UNQUALIFIED")
					})
					arg_20_0.panelFumo_:setVisible(false)
					arg_20_0.panelAttr_:setVisible(false)
					arg_20_0.itemList_:setVisible(false)
					arg_20_0.panelProcess_:setVisible(false)
					arg_20_0:nodeByName(var_0_0.TXT_TYPE):setVisible(false)

					return
				else
					if arg_20_0.equip then
						arg_20_0.equip:unSelectEquip()
					end

					arg_20_0.equip = var_20_4
					arg_20_0.equipItem = var_22_0
					arg_20_0.equipIndex = var_20_4.equipIndex
					arg_20_0.initMoneng = var_20_0.moneng_

					arg_20_0.equip:selectEquip()
					arg_20_0:nodeByName(var_0_0.TXT_TYPE):setVisible(true)

					if var_22_1 <= var_22_0:getFumoLev() then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_8:translation("ENCHANT_MAX_ALREADY")
						})
						arg_20_0:updateProcess(false)
						arg_20_0.panelProcess_:setVisible(true)
						arg_20_0.panelFumo_:setVisible(true)
						arg_20_0.panelAttr_:setVisible(true)
						arg_20_0:updateEquipAttr(var_20_4.equipIndex)
						arg_20_0.itemList_:setVisible(false)
						arg_20_0:nodeByName("fomo_dingji_txt_jinbi"):setVisible(true)
						arg_20_0:nodeByName("fomo_dingji_txt_jinbi"):setString(var_0_8:translation("ENCHANT_MAX_ALREADY_LABEL"))
						arg_20_0:nodeByName(var_0_0.TXT_JINBI):setString("")
						arg_20_0:nodeByName("txt_zuanshi"):setVisible(false)
						arg_20_0:nodeByName("icon_coin"):setVisible(false)
						arg_20_0:nodeByName("icon_crystal"):setVisible(false)
						arg_20_0:nodeByName("fomo_dingji_txt"):setVisible(true)
						arg_20_0:nodeByName("fomo_dingji_txt"):setString(var_0_8:translation("ENCHANT_MAX_ALREADY_LABEL"))
						arg_20_0:nodeByName("fomo_dingji_txt_middle"):setVisible(true)
						arg_20_0:nodeByName("fomo_dingji_txt_middle"):setString(var_0_8:translation("ENCHANT_MAX_ALREADY_LABEL"))
						arg_20_0.txtProcess:setString(var_0_8:translation("ENCHANT_MAX_ALREADY_LABEL"))
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_8:translation("ENCHANT_ADD_MATERIAL")
						})
						arg_20_0:nodeByName("fomo_dingji_txt_jinbi"):setString(var_0_8:translation("ENCHANT_ADD_MATERIAL"))
						arg_20_0:nodeByName("icon_coin"):setVisible(true)
						arg_20_0:nodeByName("icon_crystal"):setVisible(true)
						arg_20_0:nodeByName("fomo_dingji_txt_jinbi"):setVisible(false)
						arg_20_0:updateProcess(false)
						arg_20_0.panelProcess_:setVisible(true)
						arg_20_0.panelFumo_:setVisible(true)
						arg_20_0.panelAttr_:setVisible(true)
						arg_20_0:updateEquipAttr(var_20_4.equipIndex)
						arg_20_0.itemList_:setVisible(true)
						arg_20_0:nodeByName("fomo_dingji_txt"):setVisible(false)
						arg_20_0:nodeByName("txt_zuanshi"):setVisible(true)
						arg_20_0:nodeByName("fomo_dingji_txt_middle"):setVisible(false)

						arg_20_0.lastEquipItem = var_22_0
						arg_20_0.scrollToX_, arg_20_0.scrollToY_ = arg_20_0.itemList_.scrollNode:getPosition()

						arg_20_0.itemList_:reload()

						if arg_20_0.scrollToY_ > 0 or arg_20_0.scrollToX_ > 0 then
							arg_20_0.itemList_:scrollTo(arg_20_0.scrollToX_, arg_20_0.scrollToY_)
						end
					end
				end
			end
		end)
	end
end

function var_0_0.updateEquip(arg_23_0)
	arg_23_0.panelEquip_:removeAllChildren()

	local var_23_0 = 1

	for iter_23_0 = 1, 2 do
		for iter_23_1 = 1, 3 do
			arg_23_0:updateEquipByID(var_23_0)

			var_23_0 = var_23_0 + 1
		end
	end
end

function var_0_0.updateProcess(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_0.equipItem
	local var_24_1 = var_24_0:getMaxFumoStar()
	local var_24_2 = var_24_0:getFumoLev()
	local var_24_3 = var_24_0:getCurrentLevelMoneng()
	local var_24_4 = var_24_0:getFumoNeed()

	if arg_24_1 then
		arg_24_0.processBar:setVisible(false)
		arg_24_0.processBar2:setVisible(true)
	else
		arg_24_0.processBar:setVisible(true)
		arg_24_0.processBar2:setVisible(false)
	end

	local var_24_5 = 0
	local var_24_6 = 0

	if var_24_1 <= var_24_2 then
		var_24_6 = var_24_1
	else
		var_24_6 = var_24_2 + 1
	end

	local var_24_7 = var_24_4[var_24_6]
	local var_24_8 = math.min(var_24_3 / var_24_7 * 100, 100)

	arg_24_0.processBar:setPercent(var_24_8)
	arg_24_0.processBar2:setPercent(var_24_8)
	arg_24_0.txtProcess:setString(var_24_3 .. "/" .. var_24_7)
	arg_24_0:nodeByName(var_0_0.TXT_TYPE):setString(var_0_9[var_24_6])

	local var_24_9 = arg_24_0:getTotalFumo()

	if var_24_9 > 0 then
		arg_24_0:nodeByName(var_0_0.TXT_JINBI):setString(var_24_9 * xyd.tables.item:fumoMana(arg_24_0.equipItem:getTableID()))

		if var_24_9 * xyd.tables.item:fumoMana(arg_24_0.equipItem:getTableID()) > arg_24_0.player_.mana then
			arg_24_0:nodeByName(var_0_0.TXT_JINBI):setColor(cc.c4b(255, 0, 0, 150))
		else
			arg_24_0:nodeByName(var_0_0.TXT_JINBI):setColor(cc.c4b(255, 255, 255, 150))
		end
	else
		arg_24_0:nodeByName(var_0_0.TXT_JINBI):setString(var_0_8:translation("NO_MATERIAL"))
		arg_24_0:nodeByName(var_0_0.TXT_JINBI):setColor(cc.c4b(255, 255, 255, 150))
	end
end

function var_0_0.updateEquipAttr(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_0.hero_:getEquipByIndex(arg_25_1)

	arg_25_0:nodeByName(var_0_0.TXT_NAME):setString(var_25_0:getName())

	local var_25_1 = var_25_0:getFumoLev()

	if var_25_1 <= 0 then
		arg_25_0:nodeByName(var_0_0.FUMO_TYPE):setString(var_0_8:translation("NO_FUMO"))
	else
		arg_25_0:nodeByName(var_0_0.FUMO_TYPE):setString(var_0_9[var_25_1])
	end

	local var_25_2 = var_25_0:getAttr()
	local var_25_3 = var_25_0:getFumoAttr()

	arg_25_0.attrList:removeAllItems()

	local var_25_4 = arg_25_0:nodeByName(var_0_0.ATTR_LIST):getContentSize().width
	local var_25_5 = 0

	for iter_25_0, iter_25_1 in pairs(var_25_2) do
		local var_25_6 = arg_25_0.attrList:newItem()
		local var_25_7 = display.newNode()
		local var_25_8 = {
			color = cc.c3b(57, 64, 70)
		}
		local var_25_9 = xyd.AssetLoader:get():loadLabel(var_25_8)

		var_25_9:setString(xyd.tables.attr:name(iter_25_0) .. ":")
		var_25_9:addTo(var_25_7)

		local var_25_10 = {
			color = cc.c3b(234, 74, 74)
		}
		local var_25_11 = xyd.AssetLoader:get():loadLabel(var_25_10)
		local var_25_12 = var_25_9:getContentSize().width + 5

		var_25_11:setString(iter_25_1)
		var_25_11:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
		var_25_11:addTo(var_25_7)
		var_25_11:setPosition(var_25_12, 0)

		if var_25_3[iter_25_0] then
			local var_25_13 = {
				color = cc.c3b(57, 177, 44)
			}
			local var_25_14 = xyd.AssetLoader:get():loadLabel(var_25_13)
			local var_25_15 = var_25_12 + var_25_11:getContentSize().width + 5

			var_25_14:setString("+" .. var_25_3[iter_25_0])
			var_25_14:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
			var_25_14:addTo(var_25_7)
			var_25_14:setPosition(var_25_15, 0)
		end

		var_25_6:addContent(var_25_7)
		var_25_7:setContentSize(var_25_4, 28)
		var_25_6:setItemSize(var_25_4, 35)
		arg_25_0.attrList:addItem(var_25_6)
	end

	arg_25_0.attrList:reload()
end

function var_0_0.getTotalFumo(arg_26_0)
	local var_26_0 = arg_26_0.equipItem
	local var_26_1 = 0

	for iter_26_0 = 1, #arg_26_0.materials do
		var_26_1 = var_26_1 + xyd.tables.item:moneng(arg_26_0.materials[iter_26_0])
	end

	local var_26_2 = var_26_0:getTotalFumo() - arg_26_0.initMoneng

	if var_26_2 < var_26_1 then
		var_26_1 = var_26_2
	end

	return var_26_1
end

function var_0_0.getMonengItems(arg_27_0)
	local var_27_0 = arg_27_0.player_:getBackpack():getItemsByTypes(var_0_7)

	for iter_27_0 = #var_27_0, 1, -1 do
		if xyd.tables.item:moneng(var_27_0[iter_27_0].itemID) <= 0 then
			table.remove(var_27_0, iter_27_0)
		end
	end

	local var_27_1 = arg_27_0.player_:getBackpack():getItemsByTypes({
		xyd.ItemType.CONSUMABLES
	})

	for iter_27_1, iter_27_2 in ipairs(var_27_1) do
		if xyd.tables.item:moneng(iter_27_2.itemID) > 0 then
			table.insert(var_27_0, 1, iter_27_2)
		end
	end

	return var_27_0
end

function var_0_0.itemDelegate(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	if cc.ui.UIListView.COUNT_TAG == arg_28_2 then
		return (math.ceil(#arg_28_0:getMonengItems() / var_0_4))
	elseif cc.ui.UIListView.CELL_TAG == arg_28_2 then
		local var_28_0 = arg_28_0.itemList_:dequeueItem()

		if not var_28_0 then
			var_28_0 = arg_28_0.itemList_:newItem()
		else
			var_28_0:removeAllChildren(true)
		end

		local var_28_1 = 900
		local var_28_2 = 115

		var_28_0:setItemSize(var_28_1, var_28_2)

		local var_28_3 = display.newNode()

		var_28_3:setContentSize(var_28_1, 115)

		for iter_28_0 = 1, var_0_4 do
			local var_28_4 = (arg_28_3 - 1) * var_0_4 + iter_28_0

			if var_28_4 > #arg_28_0:getMonengItems() then
				break
			end

			local var_28_5 = var_0_1.new()

			var_28_5:setPosition(125 * iter_28_0 - 125, 0)
			var_28_3:addChild(var_28_5)
			var_28_5:setTouchEnabled(true)
			var_28_5:setTouchSwallowEnabled(false)
			var_28_5:contentView():nodeByName("item"):setTouchEnabled(true)
			var_28_5:contentView():nodeByName("item"):setTouchSwallowEnabled(false)
			var_28_5:contentView():nodeByName("container"):setTouchSwallowEnabled(false)

			if arg_28_0.cells == nil then
				arg_28_0.cells = {}
			end

			arg_28_0.cells[(arg_28_3 - 1) * var_0_4 + iter_28_0] = var_28_5

			local var_28_6 = arg_28_0:getMonengItems()[var_28_4]

			var_28_5:setParams(var_28_6)

			if arg_28_0.items[var_28_5:getFumoItem().itemID] then
				var_28_5:updateNums(arg_28_0.items[var_28_5:getFumoItem().itemID])
			end

			local function var_28_7()
				if not arg_28_0.equipItem then
					return
				end

				if arg_28_0.equipItem.moneng_ >= arg_28_0.equipItem:getTotalFumo() then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_8:translation("ENCHANT_MAX")
					})

					return
				end

				if var_28_5.getFumoItem == nil then
					return
				end

				if arg_28_0.items[var_28_5:getFumoItem().itemID] == nil then
					table.insert(arg_28_0.monengItems, var_28_5:getFumoItem())

					arg_28_0.items[var_28_5:getFumoItem().itemID] = 1

					arg_28_0.equipItem:addFumo(var_28_5:getFumoItem())
					table.insert(arg_28_0.materials, var_28_5:getFumoItem().itemID)
					arg_28_0:updateProcess(true)
				elseif arg_28_0.items[var_28_5:getFumoItem().itemID] < var_28_5:getFumoItem().itemNum then
					table.insert(arg_28_0.monengItems, var_28_5:getFumoItem())

					arg_28_0.items[var_28_5:getFumoItem().itemID] = 1 + arg_28_0.items[var_28_5:getFumoItem().itemID]

					arg_28_0.equipItem:addFumo(var_28_5:getFumoItem())
					table.insert(arg_28_0.materials, var_28_5:getFumoItem().itemID)
					arg_28_0:updateProcess(true)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_8:translation("ENCHANT_OUT_OF_MATERIAL")
					})
				end

				var_28_5:updateNums(arg_28_0.items[var_28_5:getFumoItem().itemID])
			end

			local var_28_8 = false

			var_28_5:contentView():nodeByName("item"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
				local var_30_0 = var_28_5:contentView():nodeByName("container"):convertToNodeSpace(cc.p(arg_30_0.x, arg_30_0.y))

				if var_30_0.x >= 67 and var_30_0.x <= 116 and var_30_0.y >= 65 and var_30_0.y <= 117 and var_28_5:contentView():nodeByName("decrease"):isVisible() and var_28_8 == false then
					return true
				end

				if arg_30_0.name == "began" then
					var_28_8 = true

					var_28_5:contentView():nodeByName("container"):setScale(0.9)

					local var_30_1 = 0

					arg_28_0.handle1 = var_0_6.performWithDelayGlobal(function()
						arg_28_0.handle2 = var_0_6.scheduleGlobal(function()
							if var_30_1 < 2 then
								var_28_7()

								var_30_1 = var_30_1 + 0.05
							elseif var_30_1 < 4 and var_30_1 >= 2 then
								for iter_32_0 = 1, 5 do
									var_28_7()
								end

								var_30_1 = var_30_1 + 0.05
							else
								for iter_32_1 = 1, 10 do
									var_28_7()
								end
							end
						end, 0.05)
					end, 1)

					return true
				end

				if arg_30_0.name == "moved" then
					if arg_28_0.scrollViewMoved_ then
						var_28_5:contentView():nodeByName("container"):setScale(1)

						if arg_28_0.handle1 then
							var_0_6.unscheduleGlobal(arg_28_0.handle1)
						end

						if arg_28_0.handle2 then
							var_0_6.unscheduleGlobal(arg_28_0.handle2)
						end
					end

					return true
				end

				if arg_30_0.name == "ended" then
					var_28_8 = false

					if arg_28_0.handle1 then
						var_0_6.unscheduleGlobal(arg_28_0.handle1)
					end

					if arg_28_0.handle2 then
						var_0_6.unscheduleGlobal(arg_28_0.handle2)
					end

					var_28_5:contentView():nodeByName("container"):setScale(1)

					if arg_28_0.scrollViewMoved_ then
						return
					end

					var_28_7()
				end
			end)

			local function var_28_9()
				if var_28_5.getFumoItem == nil then
					return
				end

				if arg_28_0.items[var_28_5:getFumoItem().itemID] == nil or arg_28_0.items[var_28_5:getFumoItem().itemID] <= 0 then
					return
				else
					arg_28_0.items[var_28_5:getFumoItem().itemID] = arg_28_0.items[var_28_5:getFumoItem().itemID] - 1

					arg_28_0.equipItem:removeFumo(var_28_5:getFumoItem())

					for iter_33_0 = 1, #arg_28_0.monengItems do
						if arg_28_0.monengItems[iter_33_0] and arg_28_0.monengItems[iter_33_0].itemID == var_28_5:getFumoItem().itemID then
							table.remove(arg_28_0.monengItems, iter_33_0)
						end
					end

					for iter_33_1 = #arg_28_0.materials, 1, -1 do
						if arg_28_0.materials[iter_33_1] == var_28_5:getFumoItem().itemID then
							table.remove(arg_28_0.materials, iter_33_1)

							break
						end
					end

					arg_28_0:updateProcess(true)
				end

				var_28_5:updateNums(arg_28_0.items[var_28_5:getFumoItem().itemID])
			end

			var_28_5:contentView():nodeByName("decrease"):addTouchEventListener(function(arg_34_0, arg_34_1)
				if arg_34_1 == ccui.TouchEventType.began then
					var_28_5:contentView():nodeByName("decrease"):setScale(0.8)

					local var_34_0 = 0

					arg_28_0.handle3 = var_0_6.performWithDelayGlobal(function()
						arg_28_0.handle4 = var_0_6.scheduleGlobal(function()
							if var_34_0 < 2 then
								var_28_9()

								var_34_0 = var_34_0 + 0.05
							elseif var_34_0 < 4 and var_34_0 >= 2 then
								for iter_36_0 = 1, 5 do
									var_28_9()
								end

								var_34_0 = var_34_0 + 0.05
							else
								for iter_36_1 = 1, 10 do
									var_28_9()
								end
							end
						end, 0.05)
					end, 1)

					return true
				end

				if arg_34_1 == ccui.TouchEventType.moved then
					var_28_5:contentView():nodeByName("decrease"):setScale(1)

					if arg_28_0.scrollViewMoved_ then
						if arg_28_0.handle1 then
							var_0_6.unscheduleGlobal(arg_28_0.handle3)
						end

						if arg_28_0.handle2 then
							var_0_6.unscheduleGlobal(arg_28_0.handle4)
						end
					end

					return true
				end

				if arg_34_1 == ccui.TouchEventType.ended then
					var_28_5:contentView():nodeByName("decrease"):setScale(1)

					if arg_28_0.handle3 then
						var_0_6.unscheduleGlobal(arg_28_0.handle3)
					end

					if arg_28_0.handle4 then
						var_0_6.unscheduleGlobal(arg_28_0.handle4)
					end

					if var_28_5.getFumoItem == nil then
						return
					end

					if arg_28_0.items[var_28_5:getFumoItem().itemID] == nil or arg_28_0.items[var_28_5:getFumoItem().itemID] <= 0 then
						return
					else
						arg_28_0.items[var_28_5:getFumoItem().itemID] = arg_28_0.items[var_28_5:getFumoItem().itemID] - 1

						arg_28_0.equipItem:removeFumo(var_28_5:getFumoItem())

						for iter_34_0 = 1, #arg_28_0.monengItems do
							if arg_28_0.monengItems[iter_34_0] and arg_28_0.monengItems[iter_34_0].itemID == var_28_5:getFumoItem().itemID then
								table.remove(arg_28_0.monengItems, iter_34_0)
							end
						end

						for iter_34_1 = #arg_28_0.materials, 1, -1 do
							if arg_28_0.materials[iter_34_1] == var_28_5:getFumoItem().itemID then
								table.remove(arg_28_0.materials, iter_34_1)

								break
							end
						end

						arg_28_0:updateProcess(true)
					end

					var_28_5:updateNums(arg_28_0.items[var_28_5:getFumoItem().itemID])
				end
			end)
		end

		var_28_0:addContent(var_28_3)

		return var_28_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_28_2 then
		-- block empty
	end
end

function var_0_0.didClose(arg_37_0)
	if arg_37_0.handle1 then
		var_0_6.unscheduleGlobal(arg_37_0.handle1)
	end

	if arg_37_0.handle2 then
		var_0_6.unscheduleGlobal(arg_37_0.handle2)
	end

	if arg_37_0.handle3 then
		var_0_6.unscheduleGlobal(arg_37_0.handle3)
	end

	if arg_37_0.handle4 then
		var_0_6.unscheduleGlobal(arg_37_0.handle4)
	end

	var_0_0.super.didClose()
end

return var_0_0
