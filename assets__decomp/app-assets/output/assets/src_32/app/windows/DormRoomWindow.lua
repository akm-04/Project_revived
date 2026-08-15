local var_0_0 = class("DormRoomWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.dormFurnitureItem
local var_0_3 = xyd.tables.dormFurnitureMaintype
local var_0_4 = xyd.tables.dormFurnitureSubtype
local var_0_5 = xyd.tables.dormHouse
local var_0_6 = xyd.tables.dormHouseType
local var_0_7 = xyd.tables.dormAct
local var_0_8 = xyd.tables.dormExpand
local var_0_9 = import("framework.scheduler")
local var_0_10 = import("app.model.Hero")
local var_0_11 = xyd.DormUnit.xunit
local var_0_12 = xyd.DormUnit.yunit
local var_0_13 = 2
local var_0_14 = 6
local var_0_15 = xyd.DormPanelType
local var_0_16 = {
	All = 1,
	SubType = 3,
	MainType = 2
}
local var_0_17 = "skeletons/ui_effect/dorm_expand/"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_1_0.backPack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.houseDetail = arg_1_0.dorm.houseDetail
	arg_1_0.houseSize = arg_1_0.dorm.houseSize
	arg_1_0.baseItemRecord = arg_1_2.item_record
	arg_1_0.itemRecord = clone(arg_1_0.baseItemRecord)
	arg_1_0.expPartners = arg_1_2.exp_partners
	arg_1_0.isSelfDorm = arg_1_0.dorm:isSelfDorm()

	arg_1_0:initHeros()

	arg_1_0.classType = var_0_16.All
	arg_1_0.furnitureType = 1
	arg_1_0.isOnChangeItem = false
	arg_1_0.isShowOwnItem = false
	arg_1_0.notClearItem = {}
	arg_1_0.houseTableId = arg_1_0.dorm.houseInfo.table_id
	arg_1_0.houseType = var_0_5:maintype(arg_1_0.houseTableId)
	arg_1_0.heroNumLimit = var_0_6:heroNum(var_0_5:maintype(arg_1_0.houseTableId))
end

function var_0_0.initHeros(arg_2_0)
	arg_2_0.heros = {}
	arg_2_0.heroItems = {}
	arg_2_0.partnerInfos = arg_2_0.dorm.houseInfo.partner_infos or {}

	for iter_2_0 = 1, #arg_2_0.partnerInfos do
		local var_2_0 = arg_2_0.partnerInfos[iter_2_0]

		if arg_2_0.isSelfDorm then
			table.insert(arg_2_0.heros, arg_2_0.selfPlayer:getHeroByID(var_2_0.partner_id))
		else
			local var_2_1 = var_0_10.new()

			var_2_1:populate(var_2_0)
			table.insert(arg_2_0.heros, var_2_1)
		end
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:initSelectContainer()
	arg_3_0:initNetRect()
	arg_3_0:layout()
	arg_3_0:initHeroModel()
	arg_3_0:createScheduler()
	arg_3_0:selectType(var_0_16.All)
	arg_3_0:updateComfortInfo()
	arg_3_0:setShowBaseOnIsChageItem()
	arg_3_0:updatePraise()
	arg_3_0:showBasedOnIsSelfRoom()
end

function var_0_0.showBasedOnIsSelfRoom(arg_4_0)
	if arg_4_0.isSelfDorm then
		arg_4_0:initChatBox()
	else
		arg_4_0:nodeByName("furniture_btn"):setVisible(false)
		arg_4_0:nodeByName("edit_container"):setVisible(false)
		arg_4_0:nodeByName("owner_touch"):setVisible(false)
		arg_4_0:nodeByName("save_btn"):setVisible(false)
		arg_4_0:nodeByName("clear_btn"):setVisible(false)
		arg_4_0:nodeByName("msg_btn"):setPositionY(arg_4_0:nodeByName("furniture_btn"):getPositionY())
		arg_4_0:nodeByName("eye_open"):setTouchEnabled(false)
	end
end

function var_0_0.updatePraise(arg_5_0)
	if arg_5_0.isSelfDorm or arg_5_0.dorm.houseInfo.is_has_praise == 1 then
		arg_5_0:nodeByName("heart_red"):setVisible(true)
		arg_5_0:nodeByName("heart_gray"):setOpacity(0)
	else
		arg_5_0:nodeByName("heart_red"):setVisible(false)
		arg_5_0:nodeByName("heart_gray"):setOpacity(255)
	end

	arg_5_0:nodeByName("praise_num_txt"):setString(arg_5_0.dorm.houseInfo.praise_num)
end

function var_0_0.updateRoomEye(arg_6_0)
	if arg_6_0.dorm.houseInfo.is_hide == 1 then
		arg_6_0:nodeByName("eye_open"):setOpacity(0)
		arg_6_0:nodeByName("eye_close"):setVisible(true)
	else
		arg_6_0:nodeByName("eye_open"):setOpacity(255)
		arg_6_0:nodeByName("eye_close"):setVisible(false)
	end
end

function var_0_0.setShowBaseOnIsChageItem(arg_7_0)
	arg_7_0:nodeByName("furniture_container"):setPositionY(0)
	arg_7_0:nodeByName("furniture_container"):setVisible(arg_7_0.isOnChangeItem)

	if arg_7_0.isOnChangeItem then
		arg_7_0:nodeByName("save_btn"):setVisible(true)
		arg_7_0:nodeByName("clear_btn"):setVisible(true)
		arg_7_0:nodeByName("msg_btn"):setVisible(false)
		arg_7_0:nodeByName("furniture_btn"):setVisible(false)
		arg_7_0:nodeByName("hide_btn"):setVisible(true)
		arg_7_0:nodeByName("cancel_btn"):setVisible(true)
		arg_7_0:nodeByName("close"):setVisible(false)
	else
		arg_7_0:nodeByName("save_btn"):setVisible(false)
		arg_7_0:nodeByName("clear_btn"):setVisible(false)
		arg_7_0:nodeByName("msg_btn"):setVisible(true)
		arg_7_0:nodeByName("furniture_btn"):setVisible(true)
		arg_7_0:nodeByName("hide_btn"):setVisible(false)
		arg_7_0:nodeByName("cancel_btn"):setVisible(false)
		arg_7_0:nodeByName("close"):setVisible(true)
	end

	if arg_7_0.isOnChangeItem and arg_7_0.handle then
		var_0_9.unscheduleGlobal(arg_7_0.handle)

		arg_7_0.handle = nil

		arg_7_0:nodeByName("down_time_txt"):setVisible(false)

		if arg_7_0.heroItems and next(arg_7_0.heroItems) then
			for iter_7_0, iter_7_1 in pairs(arg_7_0.heroItems) do
				iter_7_1:setVisible(false)
			end
		end

		arg_7_0:clearBedItemEffect()
	elseif not arg_7_0.isOnChangeItem and not arg_7_0.handle then
		arg_7_0:reInitHeroItems()
		arg_7_0:createScheduler()
	end
end

function var_0_0.reInitHeroItems(arg_8_0)
	local var_8_0 = {}
	local var_8_1 = arg_8_0.maps[var_0_15.Floor]

	if arg_8_0.heroItems and next(arg_8_0.heroItems) then
		for iter_8_0, iter_8_1 in pairs(arg_8_0.heroItems) do
			iter_8_1:setVisible(true)

			local var_8_2 = arg_8_0:resolveKey(iter_8_1.key)

			if iter_8_1.state == xyd.DormGirlState.OnBed and not var_8_1[iter_8_1.bedKey] then
				local var_8_3, var_8_4, var_8_5 = arg_8_0:getRandomAct(iter_8_1)

				arg_8_0:setHeroState(iter_8_1, var_8_3, var_8_4, var_8_5)
			elseif iter_8_1.state == xyd.DormGirlState.OnBed and var_8_1[iter_8_1.bedKey] then
				var_8_1[iter_8_1.bedKey].item:addSleepEffect()
			elseif not arg_8_0:isCanAddItem(var_8_2.item_id, var_8_2.coordX, var_8_2.coordY, var_8_2.panel_type) then
				arg_8_0:reSetHeroItemState(iter_8_1, var_8_0)
				table.insert(var_8_0, iter_8_1)
			end
		end
	end
end

function var_0_0.reSetHeroItemState(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_0:resolveKey(arg_9_1.key)

	if not arg_9_0:isCanAddItem(var_9_0.item_id, var_9_0.coordX, var_9_0.coordY, var_9_0.panel_type, arg_9_2) then
		var_9_0.coordX, var_9_0.coordY = arg_9_0:getInitCoordinate(var_9_0.item_id, var_9_0.is_flipped, arg_9_2)

		arg_9_1:setKey(arg_9_0:getKeyByAttrs(var_9_0))
	end

	local var_9_1, var_9_2, var_9_3 = arg_9_0:getRandomAct(arg_9_1)

	arg_9_0:setHeroState(arg_9_1, var_9_1, var_9_2, var_9_3)
end

function var_0_0.updateComfortInfo(arg_10_0)
	if not arg_10_0.currentComfort then
		arg_10_0.currentComfort = arg_10_0:getTotalComfort()
	end

	local var_10_0 = arg_10_0.houseTableId
	local var_10_1 = arg_10_0.dorm.houseInfo.expand_lev
	local var_10_2 = var_0_5:type(var_10_0)
	local var_10_3 = var_0_5:attr(var_10_0)
	local var_10_4 = var_0_5:comfort(var_10_0)

	if arg_10_0.houseType == xyd.DormType.VILLA then
		local var_10_5 = var_0_8:getAttrsByType(var_10_2)
		local var_10_6 = var_0_8:getComforts()

		var_10_3 = xyd.mergeTable(var_10_3, var_10_5)
		var_10_4 = xyd.mergeTable(var_10_4, var_10_6)
	end

	local var_10_7 = var_0_5:getHouseLevByComfort(var_10_0, arg_10_0.currentComfort)
	local var_10_8 = arg_10_0:getExpandComfortLev(var_10_4, arg_10_0.currentComfort)

	if var_10_8 > var_10_7 + (var_10_1 or 0) then
		arg_10_0:nodeByName("next_comfort_text"):setString(var_0_1:translation("DORM_NEED_EXPAND_TEXT"))
		arg_10_0:nodeByName("next_comfort_text"):setColor(cc.c3b(255, 0, 0))

		var_10_8 = var_10_7 + (var_10_1 or 0)
	else
		arg_10_0:nodeByName("next_comfort_text"):setString(var_0_1:translation("DORM_NEXT_LEV_TEXT"))
		arg_10_0:nodeByName("next_comfort_text"):setColor(cc.c3b(135, 97, 115))
	end

	local var_10_9 = arg_10_0:getAttrsGrowByLev(var_10_3, var_10_8)
	local var_10_10 = arg_10_0:getAttrsGrowByLev(var_10_3, var_10_8 + 1)

	arg_10_0:nodeByName("comfort_txt"):setString(arg_10_0.currentComfort)
	arg_10_0:nodeByName("current_comfort_txt"):setString(arg_10_0.currentComfort)
	arg_10_0:nodeByName("next_comfort_txt"):setString(var_10_4[var_10_8 + 1] or "")
	arg_10_0:nodeByName("face_pos"):removeAllChildren()

	local var_10_11

	if arg_10_0.houseType == xyd.DormType.LOUNGE then
		var_10_11 = "windows/dorm/my_house/face_" .. tostring(3) .. ".png"

		local var_10_12 = xyd.tables.misc.dormExpBase + xyd.tables.misc.dormExpRatio * arg_10_0.currentComfort

		arg_10_0:nodeByName("exp_increase_txt"):setString(string.format(var_0_1:translation("DORM_EXP_INCREASE_TXT"), var_10_12))
	else
		var_10_11 = "windows/dorm/my_house/face_" .. tostring(var_10_7) .. ".png"

		arg_10_0:nodeByName("exp_increase_txt"):setVisible(false)
	end

	xyd.AssetLoader.get():loadSprite(var_10_11):addTo(arg_10_0:nodeByName("face_pos"))

	if var_10_1 and var_10_1 > 0 then
		arg_10_0:nodeByName("owner_bg"):setVisible(false)
		arg_10_0:nodeByName("owner_bg_expand"):setVisible(true)
		arg_10_0:nodeByName("attr_bg"):setVisible(false)
		arg_10_0:nodeByName("attr_bg_expand"):setVisible(true)
	else
		arg_10_0:nodeByName("owner_bg"):setVisible(true)
		arg_10_0:nodeByName("owner_bg_expand"):setVisible(false)
		arg_10_0:nodeByName("attr_bg"):setVisible(true)
		arg_10_0:nodeByName("attr_bg_expand"):setVisible(false)
	end

	if var_10_8 + 1 > #var_10_4 then
		arg_10_0:nodeByName("next_comfort_text"):setVisible(false)
		arg_10_0:nodeByName("next_attr_grow_text"):setVisible(false)
		arg_10_0:nodeByName("arrow1"):setVisible(false)
		arg_10_0:nodeByName("arrow2"):setVisible(false)
	else
		arg_10_0:nodeByName("next_comfort_text"):setVisible(true)
		arg_10_0:nodeByName("next_attr_grow_text"):setVisible(true)
		arg_10_0:nodeByName("arrow1"):setVisible(true)
		arg_10_0:nodeByName("arrow2"):setVisible(true)
	end

	for iter_10_0 = 1, #var_10_9 do
		local var_10_13 = xyd.tables.attr:name(iter_10_0) .. "+" .. tostring(var_10_9[iter_10_0]) .. tostring("%")

		if var_10_9[iter_10_0] <= 0 then
			var_10_13 = ""
		end

		local var_10_14

		if var_10_10 and var_10_10[iter_10_0] then
			var_10_14 = xyd.tables.attr:name(iter_10_0) .. "+" .. tostring(var_10_10[iter_10_0]) .. tostring("%")
		else
			var_10_14 = ""
		end

		if iter_10_0 == xyd.AttributeType.STRENGTH then
			arg_10_0:nodeByName("strength_increase_txt"):setString(var_10_13)
			arg_10_0:nodeByName("current_strength_increase_txt"):setString(var_10_13)
			arg_10_0:nodeByName("next_strength_increase_txt"):setString(var_10_14)
		elseif iter_10_0 == xyd.AttributeType.WISE then
			arg_10_0:nodeByName("wise_increase_txt"):setString(var_10_13)
			arg_10_0:nodeByName("current_wise_increase_txt"):setString(var_10_13)
			arg_10_0:nodeByName("next_wise_increase_txt"):setString(var_10_14)
		elseif iter_10_0 == xyd.AttributeType.AGILE then
			arg_10_0:nodeByName("agile_increase_txt"):setString(var_10_13)
			arg_10_0:nodeByName("current_agile_increase_txt"):setString(var_10_13)
			arg_10_0:nodeByName("next_agile_increase_txt"):setString(var_10_14)
		end
	end

	arg_10_0:udpateOwnerName()

	if arg_10_0.dorm.houseInfo.house_name ~= "" then
		arg_10_0:nodeByName("name_txt"):setString(arg_10_0.dorm.houseInfo.house_name)
	else
		arg_10_0:nodeByName("name_txt"):setString(var_0_5:name(arg_10_0.houseTableId))
	end
end

function var_0_0.getExpandComfortLev(arg_11_0, arg_11_1, arg_11_2)
	for iter_11_0 = #arg_11_1, 1, -1 do
		if arg_11_2 >= arg_11_1[iter_11_0] then
			return iter_11_0
		end
	end
end

function var_0_0.getAttrsGrowByLev(arg_12_0, arg_12_1, arg_12_2)
	return xyd.splitToNumber(arg_12_1[arg_12_2], ",")
end

function var_0_0.udpateOwnerName(arg_13_0)
	arg_13_0.girlsCoolTime = xyd.tables.misc.dormGirlsCoolTime + arg_13_0.dorm.houseInfo.last_enter_time - xyd.ServerTime.get():getServerTime()

	if arg_13_0.houseType == xyd.DormType.LOUNGE then
		arg_13_0.girlsCoolTime = 0
	end

	if arg_13_0.heros and next(arg_13_0.heros) then
		for iter_13_0 = 1, 3 do
			arg_13_0.heros[1]:getEquipAttr(iter_13_0)
		end

		arg_13_0:nodeByName("owner_text"):setString(var_0_1:translation("DORM_OWNER_TEXT"))
		arg_13_0:nodeByName("owner_name_txt"):setString(arg_13_0.heros[1]:getName())
	else
		arg_13_0:nodeByName("owner_text"):setString(var_0_1:translation("DORM_SELECT_HERO_TOP"))
		arg_13_0:nodeByName("owner_name_txt"):setString("")
	end
end

function var_0_0.getTotalComfort(arg_14_0)
	local var_14_0 = 0

	for iter_14_0, iter_14_1 in pairs(var_0_15) do
		local var_14_1 = arg_14_0.maps[iter_14_1] or {}
		local var_14_2 = table.keys(var_14_1)

		for iter_14_2, iter_14_3 in pairs(var_14_2) do
			local var_14_3 = arg_14_0:resolveKey(iter_14_3)

			var_14_0 = var_14_0 + var_0_2:comfort(var_14_3.item_id)
		end
	end

	return var_14_0
end

function var_0_0.createScheduler(arg_15_0)
	if arg_15_0.handle then
		var_0_9.unscheduleGlobal(arg_15_0.handle)

		arg_15_0.handle = nil
	end

	arg_15_0.sameDirectionCount = 0
	arg_15_0.girlsCoolTime = xyd.tables.misc.dormGirlsCoolTime + arg_15_0.dorm.houseInfo.last_enter_time - xyd.ServerTime.get():getServerTime()

	if arg_15_0.houseType == xyd.DormType.LOUNGE then
		arg_15_0.girlsCoolTime = 0
	end

	arg_15_0:updateDownTime()

	arg_15_0.handle = var_0_9.scheduleGlobal(function()
		if arg_15_0 and not tolua.isnull(arg_15_0) then
			arg_15_0:updateHeroModel()

			arg_15_0.girlsCoolTime = arg_15_0.girlsCoolTime - xyd.tables.misc.dormGirlsSpeedTime

			arg_15_0:updateDownTime()
		end
	end, xyd.tables.misc.dormGirlsSpeedTime)
end

function var_0_0.updateDownTime(arg_17_0)
	if arg_17_0.girlsCoolTime <= 0 then
		arg_17_0:nodeByName("down_time_txt"):setVisible(false)
	else
		arg_17_0:nodeByName("down_time_txt"):setVisible(true)
		arg_17_0:nodeByName("down_time_txt"):setString(xyd.secondsToString1(arg_17_0.girlsCoolTime, 2))
	end
end

function var_0_0.updateHeroModel(arg_18_0)
	local var_18_0 = arg_18_0.maps[var_0_15.Floor]

	for iter_18_0, iter_18_1 in pairs(arg_18_0.heroItems) do
		if not iter_18_1.isOnTouch then
			iter_18_1.time = (iter_18_1.time or 0) - xyd.tables.misc.dormGirlsSpeedTime
		end

		if not iter_18_1.isOnTouch and iter_18_1.time <= 0 then
			local var_18_1, var_18_2, var_18_3 = arg_18_0:getRandomAct(iter_18_1)
			local var_18_4

			if iter_18_1.state == xyd.DormGirlState.OnBed and iter_18_1.bedKey and var_18_1 ~= xyd.DormGirlState.OnBed and var_18_0[iter_18_1.bedKey] then
				local var_18_5 = arg_18_0.dorm:getItemSearchCoordinate(var_18_0[iter_18_1.bedKey].item)
				local var_18_6 = arg_18_0.masks[var_0_15.Floor]

				for iter_18_2, iter_18_3 in pairs(var_18_5) do
					local var_18_7 = var_18_6[arg_18_0:getIndexByCoordinate(math.ceil(iter_18_3.x), math.ceil(iter_18_3.y))]

					if not var_18_7 or not var_18_7[var_0_13] and not arg_18_0:isCoordHasHero(math.ceil(iter_18_3.x), math.ceil(iter_18_3.y)) then
						var_18_4 = iter_18_3
					end
				end
			end

			if var_18_4 then
				local var_18_8 = arg_18_0:setKeyCoordinate(iter_18_1.key, var_18_4.x, var_18_4.y)

				iter_18_1:setKey(var_18_8)
			elseif iter_18_1.state == xyd.DormGirlState.OnBed then
				var_18_1 = xyd.DormGirlState.OnBed
				var_18_3 = iter_18_1.bedKey
			end

			arg_18_0:setHeroState(iter_18_1, var_18_1, var_18_2, var_18_3)
		end

		if not iter_18_1.isOnTouch and iter_18_1.state == xyd.DormGirlState.Walk then
			arg_18_0:heroItemWalk(iter_18_1)
		end
	end
end

function var_0_0.updateHeroItemZOrder(arg_19_0, arg_19_1)
	local var_19_0 = {
		item_id = xyd.DormRoomGirlItemID
	}

	var_19_0.is_flipped = 0
	var_19_0.coordX, var_19_0.coordY = arg_19_1.coordX, arg_19_1.coordY

	local var_19_1 = arg_19_0:getKeyByAttrs(var_19_0)

	if arg_19_0.keyToZOrder[var_19_1] then
		arg_19_1:setLocalZOrder(arg_19_0.keyToZOrder[var_19_1])
	end
end

function var_0_0.getBedAddHero(arg_20_0, arg_20_1)
	for iter_20_0 = 1, #arg_20_0.heroItems do
		if arg_20_0.heroItems[iter_20_0].bedKey == arg_20_1 then
			return arg_20_0.heroItems[iter_20_0]
		end
	end
end

function var_0_0.setHeroState(arg_21_0, arg_21_1, arg_21_2, arg_21_3, arg_21_4)
	local var_21_0 = arg_21_0.maps[var_0_15.Floor]

	if arg_21_1.state == xyd.DormGirlState.OnBed and var_21_0[arg_21_1.bedKey] then
		var_21_0[arg_21_1.bedKey].item:removeSleepEffect()
	end

	if arg_21_2 == xyd.DormGirlState.OnBed and var_21_0[arg_21_4] then
		var_21_0[arg_21_4].item:addSleepEffect()

		local var_21_1 = arg_21_0:resolveKey(arg_21_4)
		local var_21_2 = arg_21_0:getItemSize(var_21_1)
		local var_21_3 = arg_21_0:setKeyCoordinate(arg_21_1.key, var_21_1.coordX + math.floor(var_21_2.long / 2), var_21_1.coordY + math.floor(var_21_2.width / 2))

		arg_21_1:setKey(var_21_3)
	end

	arg_21_1:setHeroState(arg_21_2, arg_21_3, arg_21_4)
	arg_21_0:updateHeroItemZOrder(arg_21_1)
end

function var_0_0.isCoordHasHero(arg_22_0, arg_22_1, arg_22_2)
	for iter_22_0, iter_22_1 in pairs(arg_22_0.heroItems) do
		if iter_22_1.coordX == arg_22_1 and iter_22_1.coordY == arg_22_2 then
			return true
		end
	end

	return false
end

function var_0_0.getRandomAct(arg_23_0, arg_23_1)
	local var_23_0 = 3
	local var_23_1 = math.random(1, var_23_0)
	local var_23_2
	local var_23_3

	if var_23_1 == xyd.DormGirlState.OnBed and arg_23_1 then
		local var_23_4 = arg_23_0.masks[var_0_15.Floor]
		local var_23_5 = arg_23_0.dorm:getBedSearchCoordinate(arg_23_1.coordX, arg_23_1.coordY)

		for iter_23_0, iter_23_1 in pairs(var_23_5) do
			local var_23_6 = var_23_4[arg_23_0:getIndexByCoordinate(math.ceil(iter_23_1.x), math.ceil(iter_23_1.y))]

			if var_23_6 and var_23_6[var_0_13] and var_23_6[var_0_13] ~= -1 then
				local var_23_7 = var_23_6[var_0_13]
				local var_23_8 = arg_23_0:resolveKey(var_23_7)

				if var_0_2:actType(var_23_8.item_id) == xyd.DormInteractionType.Sleep and not arg_23_0:isBedUsed(var_23_7) then
					var_23_3 = var_23_7

					break
				end
			end
		end
	end

	if var_23_1 == xyd.DormGirlState.OnBed and not var_23_3 then
		var_23_1 = (var_23_1 + math.random(1, var_23_0 - 1)) % var_23_0
	end

	local var_23_9 = arg_23_0:getActionTime(var_23_1)

	return var_23_1, var_23_9, var_23_3
end

function var_0_0.getActionTime(arg_24_0, arg_24_1)
	local var_24_0 = var_0_7:time(arg_24_1)

	return (math.random(var_24_0[1], var_24_0[2]))
end

function var_0_0.heroItemWalk(arg_25_0, arg_25_1)
	arg_25_1.sameDirectionCount = arg_25_1.sameDirectionCount or 0

	local var_25_0 = arg_25_0:resolveKey(arg_25_1.key)

	if not arg_25_1.randomDirection then
		arg_25_1.randomDirection = arg_25_0:randomNewDirection(arg_25_1)
	end

	local var_25_1, var_25_2 = arg_25_0.dorm:getItemMaxCoord(arg_25_1)
	local var_25_3 = var_25_0.coordX
	local var_25_4 = var_25_0.coordY

	if arg_25_1.randomDirection == 1 then
		var_25_3 = var_25_3 - 1
		var_25_0.is_flipped = 1
	elseif arg_25_1.randomDirection == 2 then
		var_25_0.is_flipped = 1
		var_25_4 = var_25_4 + 1
	elseif arg_25_1.randomDirection == 3 then
		var_25_3 = var_25_3 + 1
		var_25_0.is_flipped = 0
	else
		var_25_4 = var_25_4 - 1
		var_25_0.is_flipped = 0
	end

	if not arg_25_0:isCanAddItem(var_25_0.item_id, var_25_3, var_25_4, var_25_0.panel_type, arg_25_0.heroItems) or var_25_3 < 0 or var_25_4 < 0 or var_25_1 < var_25_3 or var_25_2 < var_25_4 then
		arg_25_1.randomDirection = arg_25_0:randomNewDirection(arg_25_1)

		arg_25_1:setKey(arg_25_0:getKeyByAttrs(var_25_0))
	else
		var_25_0.coordX, var_25_0.coordY = var_25_3, var_25_4

		arg_25_1:setKey(arg_25_0:getKeyByAttrs(var_25_0), 0.5)

		arg_25_1.sameDirectionCount = (arg_25_1.sameDirectionCount or 0) + 1

		if math.random() < arg_25_0:getChangeDirectionProb(arg_25_1.sameDirectionCount) then
			arg_25_1.randomDirection = arg_25_0:randomNewDirection(arg_25_1)
		end
	end

	arg_25_0:updateHeroItemZOrder(arg_25_1)
end

function var_0_0.randomNewDirection(arg_26_0, arg_26_1)
	arg_26_1.sameDirectionCount = 0

	local var_26_0 = math.random(1, 4)

	if var_26_0 == arg_26_1.randomDirection then
		var_26_0 = (var_26_0 + math.random(1, 3)) % 4 + 1
	end

	return var_26_0
end

function var_0_0.getChangeDirectionProb(arg_27_0, arg_27_1)
	return 1 / (1 + math.exp(-arg_27_1 / 10)) - 0.5
end

function var_0_0.initNetRect(arg_28_0)
	local var_28_0 = var_0_15.Floor
	local var_28_1 = arg_28_0.dorm:createNetRect(var_28_0)

	var_28_1:addTo(arg_28_0:getPanelPos(var_28_0))
	var_28_1:setPosition(arg_28_0.dorm:getPanelBasePosition(var_28_0))
	var_28_1:setName("floor_net")

	arg_28_0.floorNet = var_28_1

	local var_28_2 = var_0_15.LeftWall
	local var_28_3 = arg_28_0.dorm:createNetRect(var_28_2)

	var_28_3:addTo(arg_28_0:getPanelPos(var_28_2))
	var_28_3:setPosition(xyd.addPosition(arg_28_0.dorm:getPanelBasePosition(var_28_2), arg_28_0.dorm:getWallCorrectPositon()))
	var_28_3:setName("left_net")

	arg_28_0.leftNet = var_28_3

	local var_28_4 = var_0_15.RightWall
	local var_28_5 = arg_28_0.dorm:createNetRect(var_28_4)

	var_28_5:addTo(arg_28_0:getPanelPos(var_28_4))
	var_28_5:setPosition(xyd.addPosition(arg_28_0.dorm:getPanelBasePosition(var_28_4), arg_28_0.dorm:getWallCorrectPositon()))
	var_28_5:setName("right_net")

	arg_28_0.rightNet = var_28_5
	arg_28_0.houseBaseWall = arg_28_0.dorm:getHouseBaseWall()

	arg_28_0.houseBaseWall:addTo(arg_28_0:getPanelPos(var_0_15.Floor))
	arg_28_0.houseBaseWall:setName("base_wall")
	arg_28_0.houseBaseWall:setPositionY(5)

	arg_28_0.notClearItem = {
		"floor_net",
		"left_net",
		"right_net",
		"base_wall"
	}

	arg_28_0.floorNet:setLocalZOrder(var_0_13)
	arg_28_0.leftNet:setLocalZOrder(var_0_13)
	arg_28_0.rightNet:setLocalZOrder(var_0_13)
end

function var_0_0.didOpen(arg_29_0, arg_29_1)
	var_0_0.super:didOpen(arg_29_1)
	arg_29_0:playExpEffect()
end

function var_0_0.playExpEffect(arg_30_0)
	if not arg_30_0.expPartners then
		return
	end

	for iter_30_0, iter_30_1 in pairs(arg_30_0.expPartners) do
		for iter_30_2 = 1, #arg_30_0.heroItems do
			if arg_30_0.heroItems[iter_30_2].hero:getHeroID() == iter_30_1.partner_id then
				if iter_30_1.newLev > iter_30_1.oldLev then
					arg_30_0.heroItems[iter_30_2]:playLevelUpEffect()
				end

				arg_30_0.heroItems[iter_30_2]:playExpEffect(100 or iter_30_1.exp - iter_30_1.oldExp)
			end
		end
	end
end

function var_0_0.willClose(arg_31_0, arg_31_1)
	var_0_0.super:willClose(arg_31_1)

	local var_31_0 = xyd.WindowManager.get():getWindow("floor_view")

	if var_31_0 and not tolua.isnull(var_31_0) then
		var_31_0:updateListInfo()
		var_31_0.list:refreshList(1)
	end

	local var_31_1 = xyd.WindowManager.get():getWindow("my_house")

	if var_31_1 and not tolua.isnull(var_31_1) then
		var_31_1:updateListInfo()
		var_31_1.list:refreshList()
	end
end

function var_0_0.didClose(arg_32_0, arg_32_1)
	var_0_0.super:didClose(arg_32_1)

	if arg_32_0.handle then
		var_0_9.unscheduleGlobal(arg_32_0.handle)

		arg_32_0.handle = nil
	end

	local var_32_0 = xyd.WindowManager.get():getWindow("hero_main")

	if var_32_0 and not tolua.isnull(var_32_0) then
		var_32_0:updateBtnShow()
		var_32_0:updateAttrScore()
		var_32_0:updateExp()
		var_32_0:updateAttrLabels()
	end
end

function var_0_0.initHeroModel(arg_33_0)
	local var_33_0 = arg_33_0.heros

	arg_33_0.heros = {}

	arg_33_0:changeHeros(var_33_0)
end

function var_0_0.changeHeros(arg_34_0, arg_34_1)
	local var_34_0 = {}

	for iter_34_0, iter_34_1 in ipairs(arg_34_1) do
		table.insert(var_34_0, iter_34_1:getTableID())
	end

	local var_34_1 = {}
	local var_34_2 = {}

	for iter_34_2 = 1, #arg_34_1 do
		table.insert(var_34_1, arg_34_1[iter_34_2]:getHeroID())
	end

	for iter_34_3 = 1, #arg_34_0.heros do
		table.insert(var_34_2, arg_34_0.heros[iter_34_3]:getHeroID())
	end

	for iter_34_4 = #arg_34_0.heros, 1, -1 do
		if not xyd.isInTable(var_34_1, arg_34_0.heros[iter_34_4]:getHeroID()) then
			table.remove(arg_34_0.heros, iter_34_4)

			if arg_34_0.heroItems[iter_34_4] then
				arg_34_0.heroItems[iter_34_4]:removeFromParent()
				table.remove(arg_34_0.heroItems, iter_34_4)
			end
		end
	end

	for iter_34_5 = 1, #arg_34_1 do
		if not xyd.isInTable(var_34_2, arg_34_1[iter_34_5]:getHeroID()) then
			local var_34_3 = #arg_34_0.heros + 1

			arg_34_0.heros[var_34_3] = arg_34_1[iter_34_5]

			local var_34_4 = {
				item_id = xyd.DormRoomGirlItemID
			}

			var_34_4.is_flipped = 0
			var_34_4.coordX, var_34_4.coordY = arg_34_0:getInitCoordinate(var_34_4.item_id, var_34_4.is_flipped, arg_34_0.heroItems)

			local var_34_5 = arg_34_0:getKeyByAttrs(var_34_4)
			local var_34_6 = {
				key = var_34_5,
				hero = arg_34_0.heros[var_34_3]
			}

			arg_34_0.heroItems[var_34_3] = import("app.windows.DormRoomItem").new(var_34_6)

			local var_34_7 = arg_34_0:getParentItemByKey(var_34_5)

			arg_34_0.heroItems[var_34_3]:addTo(var_34_7)
			arg_34_0.heroItems[var_34_3]:setHeroState(xyd.DormGirlState.Walk)
			arg_34_0:addHeroEvent(arg_34_0.heroItems[var_34_3])
			arg_34_0:updateHeroItemZOrder(arg_34_0.heroItems[var_34_3])
		end
	end

	arg_34_0:udpateOwnerName()
	arg_34_0:updateDresserEffect()
end

function var_0_0.playExpandEffect(arg_35_0, arg_35_1)
	for iter_35_0, iter_35_1 in pairs(arg_35_0.heroItems) do
		iter_35_1:setVisible(false)
	end

	for iter_35_2, iter_35_3 in ipairs(arg_35_0:nodeByName("floor_pos"):getChildren()) do
		if not xyd.isInTable(arg_35_0.notClearItem, iter_35_3:getName()) and not xyd.isInTable({
			"house_expand"
		}, iter_35_3:getName()) then
			iter_35_3:setVisible(false)
		end
	end

	arg_35_0.effects = {}

	local var_35_0 = {
		"huaxiong",
		"caoren",
		"xuchudorm",
		"zhangliao"
	}
	local var_35_1 = {
		"run",
		"run",
		"treasure",
		"run"
	}
	local var_35_2 = {
		"treasure",
		"treasure",
		"treasure",
		"treasure"
	}
	local var_35_3 = {
		cc.p(-250, 100),
		cc.p(-250, -100),
		cc.p(250, 100),
		cc.p(250, -100)
	}

	for iter_35_4 = 1, #var_35_0 do
		local var_35_4 = xyd.createEffect(var_0_17 .. var_35_0[iter_35_4])

		var_35_4:addTo(arg_35_0:nodeByName("centre_pos"))
		var_35_4:play(nil, true, nil, var_35_1[iter_35_4])
		var_35_4:setFlipX(true)
		var_35_4:setPosition(cc.p(var_0_11 * 19 + iter_35_4 * 2 * var_0_11, -var_0_12 * 19 / 2))

		local var_35_5 = cc.MoveBy:create(3, cc.p(-19 * var_0_11 - (#var_35_0 - iter_35_4) * 2 * var_0_11, 0))

		var_35_4:runActionOnce(cc.Sequence:create({
			var_35_5,
			cc.CallFunc:create(function()
				var_35_4:setFlipX(iter_35_4 <= 2)
			end),
			cc.MoveBy:create(3, var_35_3[iter_35_4]),
			cc.CallFunc:create(function()
				var_35_4:play(nil, true, nil, var_35_2[iter_35_4])
				var_35_4:setFlipX(iter_35_4 > 2)
			end),
			cc.DelayTime:create(3),
			cc.CallFunc:create(function()
				if arg_35_1 then
					arg_35_1()
				end
			end)
		}))
	end
end

function var_0_0.updateDresserEffect(arg_39_0)
	local var_39_0 = arg_39_0.maps[var_0_15.Floor]

	for iter_39_0, iter_39_1 in pairs(table.keys(var_39_0)) do
		local var_39_1 = arg_39_0:resolveKey(iter_39_1)

		if var_0_2:actType(var_39_1.item_id) == xyd.DormInteractionType.Dress then
			if arg_39_0:isCanEquip() then
				var_39_0[iter_39_1].item:setDresserEffectVisible(true)
			else
				var_39_0[iter_39_1].item:setDresserEffectVisible(false)
			end

			return
		end
	end
end

function var_0_0.isCanEquip(arg_40_0)
	for iter_40_0, iter_40_1 in pairs(arg_40_0.heros) do
		local var_40_0 = iter_40_1:getHouseEquips()
		local var_40_1 = iter_40_1:getDormItemList()

		for iter_40_2 = 1, iter_40_1:getStar() do
			if not iter_40_1:isSuper() and iter_40_1:getColor() >= 16 and var_40_0[iter_40_2] == 0 and var_40_0[iter_40_2] == 0 and var_40_1[iter_40_2] and var_40_1[iter_40_2] > 0 and arg_40_0.backPack:getItemNumByID(var_40_1[iter_40_2]) > 0 or iter_40_1:isSuper() and var_40_0[iter_40_2] == 0 and var_40_0[iter_40_2] == 0 and var_40_1[iter_40_2] and var_40_1[iter_40_2] > 0 and arg_40_0.backPack:getItemNumByID(var_40_1[iter_40_2]) > 0 then
				return true
			end
		end
	end

	return false
end

function var_0_0.initSelectContainer(arg_41_0)
	if arg_41_0.selectInfo then
		arg_41_0.selectInfo.selectContent:removeFromParent()

		arg_41_0.selectInfo = nil
	end

	local var_41_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/dorm/room/select_container.csb")

	var_41_0:retain()

	local var_41_1 = {}
	local var_41_2 = var_41_0:getChildByName("container")

	var_41_1.flipBtn = var_41_2:getChildByName("flip_btn")
	var_41_1.confirmBtn = var_41_2:getChildByName("confirm_btn")
	var_41_1.deleteBtn = var_41_2:getChildByName("delete_btn")
	var_41_1.itemPos = var_41_2:getChildByName("item_pos")
	var_41_1.selectContent = var_41_0
	var_41_1.itemTree = nil
	arg_41_0.selectInfo = var_41_1

	var_41_1.flipBtn:addTouchEventListener(function(arg_42_0, arg_42_1)
		if arg_42_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_41_0:flipSelectItem()
		end
	end)
	var_41_1.confirmBtn:addTouchEventListener(function(arg_43_0, arg_43_1)
		if arg_43_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_41_0:confirmSelectItem()
		end
	end)
	var_41_1.deleteBtn:addTouchEventListener(function(arg_44_0, arg_44_1)
		if arg_44_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_41_0:deleteSelectItem()
			arg_41_0:initSelectContainer()
		end
	end)
	var_41_2:getChildByName("circle"):setTouchEnabled(true)
	var_41_2:getChildByName("circle"):setTouchSwallowEnabled(true)
	var_41_2:getChildByName("circle"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_45_0)
		local var_45_0 = arg_41_0.selectInfo.itemTree.item

		if arg_45_0.name == "began" then
			arg_41_0.itemPos = cc.p(var_45_0:getPosition())
			arg_41_0.orgPos = cc.p(arg_45_0.x, arg_45_0.y)
			arg_41_0.orgCoordX, arg_41_0.orgCoordY = var_45_0.coordX, var_45_0.coordY

			return true
		elseif arg_45_0.name == "moved" then
			local var_45_1 = xyd.subPosition(arg_45_0, arg_41_0.orgPos)
			local var_45_2 = xyd.addPosition(arg_41_0.itemPos, var_45_1)
			local var_45_3, var_45_4 = arg_41_0.dorm:getPanelCoordByPiexl(var_45_2.x, var_45_2.y, var_45_0, false)
			local var_45_5, var_45_6 = arg_41_0.dorm:getItemMaxCoord(var_45_0)

			if var_45_0.panelType == var_0_15.LeftWall and var_45_3 > var_45_5 + 0.5 or var_45_0.panelType == var_0_15.RightWall and var_45_3 < -0.5 then
				arg_41_0:swapWall()
			else
				local var_45_7, var_45_8 = arg_41_0:correctCoordByPanel(var_45_0, var_45_3, var_45_4)

				var_45_0:setKey(arg_41_0:setKeyCoordinate(var_45_0.key, var_45_7, var_45_8))
			end

			arg_41_0:updateSelectInfo()

			arg_41_0.orgCoordX, arg_41_0.orgCoordY = var_45_0.coordX, var_45_0.coordY

			return true
		elseif arg_45_0.name == "ended" then
			local var_45_9 = cc.p(var_45_0:getPosition())
			local var_45_10, var_45_11 = arg_41_0.dorm:getPanelCoordByPiexl(var_45_9.x, var_45_9.y, var_45_0, true)

			var_45_0:setKey(arg_41_0:setKeyCoordinate(var_45_0.key, var_45_10, var_45_11))
			arg_41_0:updateSelectInfo()

			arg_41_0.orgCoordX, arg_41_0.orgCoordY = nil
		end
	end)
end

function var_0_0.confirmSelectItem(arg_46_0)
	arg_46_0:setNetVisible(false)

	local var_46_0 = arg_46_0.selectInfo.addKey
	local var_46_1 = arg_46_0.selectInfo.itemTree

	if var_46_1 and not var_46_0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = xyd.tables.translation:translation("DORM_PLACE_CURRENT_SELECT")
		})

		return false
	end

	if not var_46_0 or not var_46_1 then
		return true
	end

	if arg_46_0.dorm:isRootItem(var_46_0) then
		local var_46_2 = arg_46_0:resolveKey(var_46_0)
		local var_46_3 = arg_46_0:getItemSize(var_46_2)

		if #arg_46_0:getFreeGrid() - var_46_3.long * var_46_3.width < arg_46_0.heroNumLimit then
			xyd.WindowManager.get():openWindow("toast", {
				message = xyd.tables.translation:translation("DORM_NO_SPACE_LEFT_2")
			})

			return false
		end
	end

	var_46_1.item:removePieceRect()
	arg_46_0:addItemTree(var_46_0, var_46_1)
	arg_46_0:initSelectContainer()

	return true
end

function var_0_0.setNetVisible(arg_47_0, arg_47_1, arg_47_2)
	arg_47_0.floorNet:setVisible(false)
	arg_47_0.leftNet:setVisible(false)
	arg_47_0.rightNet:setVisible(false)

	if arg_47_1 then
		if arg_47_2 == var_0_15.Floor then
			arg_47_0.floorNet:setVisible(arg_47_1)
		else
			arg_47_0.leftNet:setVisible(arg_47_1)
			arg_47_0.rightNet:setVisible(arg_47_1)
		end
	end
end

function var_0_0.swapWall(arg_48_0)
	local var_48_0 = arg_48_0.selectInfo
	local var_48_1 = arg_48_0.selectInfo.itemTree.item
	local var_48_2 = arg_48_0:resolveKey(var_48_1.key)

	var_48_2.is_flipped = 1 - var_48_2.is_flipped

	if var_48_2.is_flipped == 0 then
		var_48_2.coordX = arg_48_0.houseSize.long - var_48_1.l
	else
		var_48_2.coordX = 0
	end

	var_48_2.coordX, var_48_2.coordY = arg_48_0.dorm:getStandardCoord(var_48_2.coordX, var_48_2.coordY)

	local var_48_3 = arg_48_0:getKeyByAttrs(var_48_2)

	var_48_1:setKey(var_48_3)

	local var_48_4, var_48_5 = arg_48_0:correctCoordByPanel(var_48_1, var_48_2.coordX, var_48_2.coordY)

	var_48_1:setKey(arg_48_0:setKeyCoordinate(var_48_1.key, var_48_4, var_48_5))
end

function var_0_0.correctCoordByPanel(arg_49_0, arg_49_1, arg_49_2, arg_49_3)
	local var_49_0 = arg_49_0:getIndexByCoordinate(arg_49_0.dorm:getStandardCoord(arg_49_2, arg_49_3))
	local var_49_1 = arg_49_0.masks[arg_49_1.panelType]
	local var_49_2, var_49_3 = arg_49_0.dorm:getItemMaxCoord(arg_49_1)
	local var_49_4 = var_49_1[var_49_0] or {}
	local var_49_5 = var_0_2:floor(arg_49_1.tableId)

	if var_49_5 > var_0_13 and var_49_4[var_0_13] then
		return arg_49_2, arg_49_3
	elseif var_49_5 > var_0_13 and (var_49_2 < arg_49_2 or var_49_3 < arg_49_3) then
		local var_49_6 = arg_49_0:getIndexByCoordinate(arg_49_0.dorm:getStandardCoord(arg_49_1.coordX, arg_49_3))

		if var_49_4[var_0_13] then
			return arg_49_1.coordX, arg_49_3
		end

		local var_49_7 = arg_49_0:getIndexByCoordinate(arg_49_0.dorm:getStandardCoord(arg_49_2, arg_49_1.coordY))

		if var_49_4[var_0_13] then
			return arg_49_2, arg_49_1.coordY
		end

		if var_49_2 < arg_49_1.coordX or var_49_3 < arg_49_1.coordY then
			return arg_49_1.coordX, arg_49_1.coordY
		end
	end

	arg_49_2 = math.max(arg_49_2, 0)
	arg_49_3 = math.max(arg_49_3, 0)
	arg_49_2 = math.min(var_49_2, arg_49_2)
	arg_49_3 = math.min(var_49_3, arg_49_3)

	return arg_49_2, arg_49_3
end

function var_0_0.getAddKey(arg_50_0, arg_50_1, arg_50_2, arg_50_3, arg_50_4)
	local var_50_0

	for iter_50_0 = var_0_14, 1, -1 do
		local var_50_1 = {
			item_id = arg_50_2.tableId,
			is_flipped = arg_50_2.isFlipped,
			parent_key = arg_50_1[iter_50_0]
		}

		if arg_50_1[iter_50_0] and arg_50_1[iter_50_0] ~= -1 then
			var_50_1.coordX, var_50_1.coordY = arg_50_0:getRelativeCoordinate(arg_50_3, arg_50_4, arg_50_1[iter_50_0])
			var_50_0 = arg_50_0:getKeyByAttrs(var_50_1)

			break
		elseif iter_50_0 <= var_0_13 and not arg_50_1[iter_50_0] then
			var_50_1.coordX, var_50_1.coordY = arg_50_3, arg_50_4
			var_50_0 = arg_50_0:getKeyByAttrs(var_50_1)
		end
	end

	return var_50_0
end

function var_0_0.setSelectBtnSate(arg_51_0)
	local var_51_0 = arg_51_0.selectInfo
	local var_51_1 = var_51_0.itemTree.item
	local var_51_2 = arg_51_0.selectInfo.addKey
	local var_51_3 = arg_51_0:resolveKey(var_51_1.key)

	if not var_51_2 then
		var_51_0.confirmBtn:setBright(false)
		var_51_0.confirmBtn:setTouchEnabled(false)

		if var_51_0.itemTree.children and next(var_51_0.itemTree.children) then
			var_51_0.deleteBtn:setBright(false)
			var_51_0.deleteBtn:setTouchEnabled(false)
		else
			var_51_0.deleteBtn:setTouchEnabled(true)
			var_51_0.deleteBtn:setBright(true)
		end
	else
		var_51_0.confirmBtn:setBright(true)
		var_51_0.deleteBtn:setBright(true)
		var_51_0.confirmBtn:setTouchEnabled(true)
		var_51_0.deleteBtn:setTouchEnabled(true)
	end

	if var_0_2:actType(var_51_3.item_id) == xyd.DormInteractionType.Dress then
		var_51_0.deleteBtn:setBright(false)
		var_51_0.deleteBtn:setTouchEnabled(false)
	end
end

function var_0_0.getRelativeCoordinate(arg_52_0, arg_52_1, arg_52_2, arg_52_3)
	local var_52_0 = arg_52_0:getItemMaskInfo(arg_52_3)

	return arg_52_1 - var_52_0.coordX - var_52_0.size.height, arg_52_2 - var_52_0.coordY - var_52_0.size.height
end

function var_0_0.selectItemTree(arg_53_0, arg_53_1)
	arg_53_0.itemChanged = true

	local var_53_0 = arg_53_0:resolveKey(arg_53_1)
	local var_53_1 = arg_53_0.maps[var_53_0.panel_type][arg_53_1]

	if not arg_53_1 or not var_53_1 then
		return
	end

	local var_53_2 = var_53_1.item
	local var_53_3 = arg_53_0.selectInfo

	var_53_3.itemTree = var_53_1

	local var_53_4 = arg_53_0:getItemMaskInfo(arg_53_1)
	local var_53_5 = arg_53_0:replaceKeyParent(arg_53_1, nil)
	local var_53_6 = arg_53_0:setKeyCoordinate(var_53_5, var_53_4.coordX, var_53_4.coordY)

	var_53_2:removeFromParent()
	var_53_2:addTo(arg_53_0:getParentItemByKey(var_53_6))
	var_53_2:setOpacity(155)
	var_53_2:setKey(var_53_6)
	var_53_3.selectContent:addTo(var_53_2.addPoint)
	var_53_3.selectContent:setPosition(cc.p(-197.5, -197.5))

	if arg_53_0.dorm:getPanelTypeByKey(var_53_6) ~= var_0_15.Floor then
		var_53_3.flipBtn:setBright(false)
		var_53_3.flipBtn:setTouchEnabled(false)
	else
		var_53_3.flipBtn:setBright(true)
		var_53_3.flipBtn:setTouchEnabled(true)
	end

	arg_53_0:removeItemTreeInfo(arg_53_1)
	arg_53_0:updateSelectInfo()
	arg_53_0:initMasks(var_53_0.panel_type)
	arg_53_0:setNetVisible(true, var_53_0.panel_type)
end

function var_0_0.updateSelectInfo(arg_54_0)
	local var_54_0 = arg_54_0.selectInfo.itemTree.item

	if arg_54_0.orgCoordX and math.floor(var_54_0.coordX + 0.5) == math.floor(arg_54_0.orgCoordX + 0.5) and math.floor(var_54_0.coordY + 0.5) == math.floor(arg_54_0.orgCoordY + 0.5) then
		var_54_0:updatePieceRectPosition()

		return
	end

	local var_54_1, var_54_2 = arg_54_0:getItemMask(var_54_0, math.floor(var_54_0.coordX + 0.5), math.floor(var_54_0.coordY + 0.5))
	local var_54_3 = arg_54_0:getAddKey(var_54_2, var_54_0, math.floor(var_54_0.coordX + 0.5), math.floor(var_54_0.coordY + 0.5))

	arg_54_0.selectInfo.addKey = var_54_3

	var_54_0:updatePieceRect(var_54_1)
	arg_54_0:setSelectBtnSate()
end

function var_0_0.addHeroEvent(arg_55_0, arg_55_1)
	arg_55_1.touchNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_56_0)
		if arg_56_0.name == "began" then
			arg_55_1.isHeroMoved = false
			arg_55_1.isOnTouch = true
			arg_55_0.itemPos = cc.p(arg_55_1:getPosition())
			arg_55_0.orgPos = cc.p(arg_56_0.x, arg_56_0.y)
			arg_55_0.orgKey = arg_55_1.key
			arg_55_0.maxDistance = cc.p(0, 0)

			arg_55_1:setLocalZOrder(200000)

			return true
		elseif arg_56_0.name == "moved" then
			if math.abs(arg_56_0.x - arg_55_0.orgPos.x) > arg_55_0.maxDistance.x then
				arg_55_0.maxDistance.x = math.abs(arg_56_0.x - arg_55_0.orgPos.x)
			end

			if math.abs(arg_56_0.y - arg_55_0.orgPos.y) > arg_55_0.maxDistance.y then
				arg_55_0.maxDistance.y = math.abs(arg_56_0.y - arg_55_0.orgPos.y)
			end

			local var_56_0 = 5

			if (var_56_0 <= arg_55_0.maxDistance.x or var_56_0 <= arg_55_0.maxDistance.y) and not arg_55_1.isHeroMoved then
				arg_55_1.contentView_:attacked()

				arg_55_1.isHeroMoved = true
			end

			local var_56_1 = xyd.subPosition(arg_56_0, arg_55_0.orgPos)
			local var_56_2 = xyd.addPosition(arg_55_0.itemPos, var_56_1)
			local var_56_3, var_56_4 = arg_55_0.dorm:getPanelCoordByPiexl(var_56_2.x, var_56_2.y, arg_55_1, false)
			local var_56_5, var_56_6 = arg_55_0:correctCoordByPanel(arg_55_1, var_56_3, var_56_4)

			arg_55_1:setKey(arg_55_0:setKeyCoordinate(arg_55_1.key, var_56_5, var_56_6))
			arg_55_1:setLocalZOrder(200000)

			return true
		elseif arg_56_0.name == "ended" then
			arg_55_0:updateHeroItemByPosition(arg_55_1, arg_55_0.orgKey)

			if not arg_55_1.isHeroMoved and arg_55_1.state == xyd.DormGirlState.Rest then
				arg_55_1:resetModelState()
				arg_55_1:playExpression()
			elseif arg_55_1.isHeroMoved and arg_55_1.state ~= xyd.DormGirlState.OnBed then
				local var_56_7 = xyd.DormGirlState.Rest
				local var_56_8 = arg_55_0:getActionTime(var_56_7)

				arg_55_0:setHeroState(arg_55_1, var_56_7, var_56_8)
				arg_55_1:playExpression()
			end

			arg_55_1.isHeroMoved = false
			arg_55_1.isOnTouch = false
		end
	end)
end

function var_0_0.updateHeroItemByPosition(arg_57_0, arg_57_1, arg_57_2, arg_57_3)
	local var_57_0 = cc.p(arg_57_1:getPosition())
	local var_57_1, var_57_2 = arg_57_0.dorm:getPanelCoordByPiexl(var_57_0.x, var_57_0.y, arg_57_1, true)
	local var_57_3, var_57_4 = arg_57_0:correctCoordByPanel(arg_57_1, var_57_1, var_57_2)
	local var_57_5, var_57_6 = arg_57_0:getInteraction(var_57_3, var_57_4)
	local var_57_7 = {}

	for iter_57_0 = 1, #arg_57_0.heroItems do
		if arg_57_0.heroItems[iter_57_0].hero:getHeroID() ~= arg_57_1.hero:getHeroID() then
			table.insert(var_57_7, arg_57_0.heroItems[iter_57_0])
		end
	end

	if arg_57_0:isCanAddItem(arg_57_1.tableId, var_57_3, var_57_4, var_0_15.Floor, var_57_7) then
		arg_57_1:setKey(arg_57_0:setKeyCoordinate(arg_57_1.key, var_57_3, var_57_4))
		arg_57_0:reSetHeroItemState(arg_57_1)
	elseif var_57_5 and var_57_6 then
		local var_57_8

		if var_57_5 == xyd.DormInteractionType.Sleep then
			var_57_8 = xyd.DormGirlState.OnBed
		end

		if var_57_8 == xyd.DormGirlState.OnBed then
			local var_57_9 = arg_57_0:getActionTime(var_57_8)

			arg_57_0:setHeroState(arg_57_1, var_57_8, var_57_9, var_57_6)
		end
	elseif arg_57_2 then
		arg_57_1:setKey(arg_57_2)

		if arg_57_1.state == xyd.DormGirlState.OnBed then
			arg_57_1.contentView_:setVisible(false)
		end
	end
end

function var_0_0.getInteraction(arg_58_0, arg_58_1, arg_58_2)
	local var_58_0 = arg_58_0.masks[var_0_15.Floor][arg_58_0:getIndexByCoordinate(arg_58_1, arg_58_2)]

	if var_58_0 and var_58_0[var_0_13] and var_58_0[var_0_13] ~= -1 then
		local var_58_1 = var_58_0[var_0_13]
		local var_58_2 = arg_58_0:resolveKey(var_58_1)

		if var_0_2:actType(var_58_2.item_id) == xyd.DormInteractionType.Sleep then
			if not arg_58_0:isBedUsed(var_58_1) then
				return xyd.DormInteractionType.Sleep, var_58_1
			end
		elseif var_0_2:actType(var_58_2.item_id) == xyd.DormInteractionType.Attack then
			return xyd.DormInteractionType.Attack, var_58_1
		end
	end
end

function var_0_0.isBedUsed(arg_59_0, arg_59_1)
	for iter_59_0 = 1, #arg_59_0.heroItems do
		if arg_59_0.heroItems[iter_59_0].state == xyd.DormGirlState.OnBed and arg_59_0.heroItems[iter_59_0].bedKey == arg_59_1 then
			return true
		end
	end
end

function var_0_0.addEvent(arg_60_0, arg_60_1)
	if arg_60_1.specialType == xyd.DormSpecialType.AutoFull then
		return
	end

	arg_60_1.contentView_:setTouchEnabled(true)
	arg_60_1.contentView_:setTouchSwallowEnabled(true)
	arg_60_1.contentView_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_61_0)
		if arg_61_0.name == "began" then
			arg_60_0.orgPosition = cc.p(arg_61_0.prevX, arg_61_0.prevY)

			if not arg_60_0.isOnChangeItem then
				arg_60_0.bedHeroItem = arg_60_0:getBedAddHero(arg_60_1.key)
			else
				arg_60_0.bedHeroItem = nil
			end

			if arg_60_0.bedHeroItem then
				arg_60_0.bedHeroItem.isHeroMoved = true

				arg_60_0.bedHeroItem.contentView_:attacked()
				arg_60_0.bedHeroItem.contentView_:setVisible(true)
				arg_60_0.bedHeroItem:setLocalZOrder(200000)

				arg_60_0.orgKey = arg_60_0.bedHeroItem.key
			end

			return true
		elseif arg_61_0.name == "moved" then
			local var_61_0 = arg_60_0:resolveKey(arg_60_1.key)

			if arg_60_0.bedHeroItem then
				local var_61_1 = arg_60_0:getPanelPos(var_0_15.Floor):convertToNodeSpace(xyd.subPosition(arg_61_0, cc.p(0, var_0_12 / 2)))

				arg_60_0.bedHeroItem:setPosition(var_61_1)
			elseif var_0_2:actType(var_61_0.item_id) == xyd.DormInteractionType.Dress and arg_60_0.isSelfDorm and arg_60_0.heros and next(arg_60_0.heros) then
				return true
			else
				local var_61_2 = arg_60_0:resolveKey(arg_60_1.key)

				if not arg_60_0.isOnChangeItem then
					local var_61_3 = cc.p(arg_60_0:nodeByName("centre_pos"):getPosition())
					local var_61_4 = xyd.subPosition(arg_61_0, cc.p(arg_61_0.prevX, arg_61_0.prevY))

					arg_60_0:nodeByName("centre_pos"):setPosition(arg_60_0:correctCentrePosPosition(xyd.addPosition(var_61_3, var_61_4)))
				end
			end

			return true
		elseif arg_61_0.name == "ended" then
			if arg_60_0.bedHeroItem then
				arg_60_0:updateHeroItemByPosition(arg_60_0.bedHeroItem, arg_60_0.orgKey)

				arg_60_0.bedHeroItem.isHeroMoved = false
			elseif not arg_60_0.isOnChangeItem then
				local var_61_5 = arg_60_0:resolveKey(arg_60_1.key)

				if var_0_2:actType(var_61_5.item_id) == xyd.DormInteractionType.Dress and arg_60_0.isSelfDorm and arg_60_0.heros and next(arg_60_0.heros) then
					if not arg_60_0.heros[1]:isSuper() and arg_60_0.heros[1]:getColor() < 16 then
						xyd.WindowManager.get():openWindow("toast", {
							message = xyd.tables.translation:translation("DORM_LIMIT")
						})

						return
					end

					local function var_61_6()
						if arg_60_0 and not tolua.isnull(arg_60_0) then
							arg_60_0:updateDresserEffect()
						end
					end

					local var_61_7 = {
						hero = arg_60_0.heros[1],
						house_id = arg_60_0.houseDetail.house_id,
						callback = var_61_6
					}

					xyd.WindowManager.get():openWindow("dorm_equip", var_61_7)
				end
			elseif not arg_60_0.selectInfo.itemTree then
				arg_60_0:selectItemTree(arg_60_1.key)
			elseif arg_60_0.selectInfo.itemTree.item ~= arg_60_1 and arg_60_0:confirmSelectItem() then
				arg_60_0:selectItemTree(arg_60_1.key)
			end
		end
	end)
end

function var_0_0.layout(arg_63_0)
	arg_63_0:nodeByName("comment_text"):setString(var_0_1:translation("DORM_COMMENT_TEXT"))
	arg_63_0:nodeByName("comfort_text"):setString(var_0_1:translation("DORM_COMFORT_TEXT"))
	arg_63_0:nodeByName("owner_text"):setString(var_0_1:translation("DORM_OWNER_TEXT"))
	arg_63_0:nodeByName("current_comfort_text"):setString(var_0_1:translation("DORM_CURRENT_COMFORT_TEXT"))
	arg_63_0:nodeByName("next_comfort_text"):setString(var_0_1:translation("DORM_NEXT_LEV_TEXT"))
	arg_63_0:nodeByName("current_attr_grow_text"):setString(var_0_1:translation("DORM_ATTR_GROW_TEXT"))
	arg_63_0:nodeByName("next_attr_grow_text"):setString(var_0_1:translation("DORM_ATTR_GROW_TEXT"))
	arg_63_0:nodeByName("select_txt"):setString(var_0_1:translation("DORM_ITEM_HAS_TEXT"))

	arg_63_0.scroll = arg_63_0:nodeByName("scroll")

	local var_63_0 = arg_63_0.scroll:getContentSize()

	arg_63_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_63_0.width, var_63_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_63_0.scroll):onScroll(handler(arg_63_0, arg_63_0.scrollListener))

	arg_63_0.scrollList:setDelegate(handler(arg_63_0, arg_63_0.scrollListDelegate))

	arg_63_0.classScroll = arg_63_0:nodeByName("class_scroll")

	local var_63_1 = arg_63_0.classScroll:getContentSize()

	arg_63_0.classScrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_63_1.width, var_63_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_63_0.classScroll):onScroll(handler(arg_63_0, arg_63_0.scrollListener))

	arg_63_0.classScrollList:setDelegate(handler(arg_63_0, arg_63_0.classScrollListDelegate))
	arg_63_0:updateScrollList()
	arg_63_0:setButtonClick()
	arg_63_0:initItemTables()
	arg_63_0:initRoomShow()
	arg_63_0:setNetVisible(false)
	arg_63_0:updateRoomEye()
end

function var_0_0.setButtonClick(arg_64_0)
	arg_64_0:nodeByName("furniture_btn"):addTouchEventListener(function(arg_65_0, arg_65_1)
		if arg_65_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_64_0.isOnChangeItem = true

			arg_64_0:setShowBaseOnIsChageItem()
		end
	end)
	arg_64_0:nodeByName("all_select_icon"):setTouchEnabled(true)
	arg_64_0:nodeByName("all_select_icon"):setTouchSwallowEnabled(true)
	arg_64_0:nodeByName("all_select_icon"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_66_0)
		if arg_66_0.name == "began" then
			return true
		elseif arg_66_0.name == "moved" then
			return true
		elseif arg_66_0.name == "ended" then
			if arg_64_0.classType == var_0_16.SubType then
				arg_64_0:selectType(var_0_16.All)
			else
				return
			end
		end
	end)
	arg_64_0:nodeByName("select"):setVisible(arg_64_0.isShowOwnItem)
	arg_64_0:nodeByName("select_box"):setTouchEnabled(true)
	arg_64_0:nodeByName("select_box"):setTouchSwallowEnabled(true)
	arg_64_0:nodeByName("select_box"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_67_0)
		if arg_67_0.name == "began" then
			return true
		elseif arg_67_0.name == "moved" then
			return true
		elseif arg_67_0.name == "ended" then
			arg_64_0.isShowOwnItem = not arg_64_0.isShowOwnItem

			arg_64_0:nodeByName("select"):setVisible(arg_64_0.isShowOwnItem)
			arg_64_0:updateScrollList()
		end
	end)
	arg_64_0:nodeByName("comfort_detail"):setVisible(false)

	if arg_64_0.houseType ~= xyd.DormType.LOUNGE then
		arg_64_0:nodeByName("comfort_touch"):setTouchEnabled(true)
		arg_64_0:nodeByName("comfort_touch"):setTouchSwallowEnabled(true)
		arg_64_0:nodeByName("comfort_touch"):addTouchEventListener(function(arg_68_0, arg_68_1)
			if arg_68_1 == ccui.TouchEventType.began then
				arg_64_0:nodeByName("comfort_detail"):setVisible(true)
			elseif arg_68_1 == ccui.TouchEventType.ended then
				arg_64_0:nodeByName("comfort_detail"):setVisible(false)
			end
		end)
	end

	arg_64_0:nodeByName("owner_touch_btn"):addTouchEventListener(function(arg_69_0, arg_69_1)
		if arg_69_1 == ccui.TouchEventType.ended then
			if arg_64_0.isOnChangeItem or not arg_64_0.isSelfDorm then
				return
			end

			if arg_64_0.girlsCoolTime > 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("DORM_GIRL_COOL_TIME_TIP")
				})

				return
			end

			var_0_9.performWithDelayGlobal(function()
				if arg_64_0 and not tolua.isnull(arg_64_0) then
					arg_64_0:nodeByName("owner_touch_btn"):setTouchEnabled(true)
				end
			end, 0.5)
			arg_64_0:nodeByName("owner_touch_btn"):setTouchEnabled(false)

			local function var_69_0(arg_71_0)
				arg_64_0:changeHeros(arg_71_0)
			end

			local var_69_1 = {
				callback = var_69_0,
				enterHeros = arg_64_0.heros,
				hero_num_limit = arg_64_0.heroNumLimit,
				table_id = arg_64_0.houseTableId
			}

			xyd.WindowManager.get():openWindow("dorm_room_select_hero", var_69_1)
		end
	end)
	arg_64_0:nodeByName("save_btn"):addTouchEventListener(function(arg_72_0, arg_72_1)
		if arg_72_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not arg_64_0:confirmSelectItem() then
				return
			end

			if not arg_64_0.itemChanged then
				arg_64_0.isOnChangeItem = false

				arg_64_0:setShowBaseOnIsChageItem()

				return
			end

			local var_72_0 = {
				house_id = arg_64_0.houseDetail.house_id,
				furniture_record = arg_64_0:getFormationRecord()
			}

			arg_64_0.dorm:saveFurnitures(var_72_0, function(arg_73_0, arg_73_1)
				if arg_73_0 == xyd.error.OK then
					arg_64_0.isOnChangeItem = false
					arg_64_0.itemChanged = false

					arg_64_0:setShowBaseOnIsChageItem()

					arg_64_0.baseItemRecord = clone(arg_64_0.itemRecord)
				end

				if arg_73_1.wrong_key then
					arg_64_0:selectItemTree(arg_73_1.wrong_key)
				end
			end)
		end
	end)
	arg_64_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_74_0, arg_74_1)
		if arg_74_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_64_0:initItemTables()
			arg_64_0:initRoomShow()

			arg_64_0.isOnChangeItem = false

			arg_64_0:setShowBaseOnIsChageItem()

			arg_64_0.currentComfort = nil

			arg_64_0:updateComfortInfo()
			arg_64_0:setNetVisible(false)
			arg_64_0:initSelectContainer()

			arg_64_0.itemRecord = clone(arg_64_0.baseItemRecord)

			arg_64_0.scrollList:refreshList()
		end
	end)
	arg_64_0:nodeByName("clear_btn"):addTouchEventListener(function(arg_75_0, arg_75_1)
		if arg_75_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not arg_64_0:confirmSelectItem() then
				return
			end

			arg_64_0:clearMaps()

			arg_64_0.currentComfort = nil

			arg_64_0:updateComfortInfo()

			arg_64_0.itemChanged = true

			arg_64_0:initSelectContainer()
		end
	end)
	arg_64_0:nodeByName("heart_gray"):setTouchEnabled(true)
	arg_64_0:nodeByName("heart_gray"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_76_0)
		if arg_76_0.name == "began" then
			return true
		elseif arg_76_0.name == "moved" then
			return true
		elseif arg_76_0.name == "ended" then
			if arg_64_0.isSelfDorm then
				local var_76_0 = {
					house_id = arg_64_0.houseDetail.house_id
				}

				var_76_0.start = 0
				var_76_0.offset = arg_64_0.dorm.singlePageMsgNum

				arg_64_0.dorm:getPraiseList(var_76_0, function(arg_77_0, arg_77_1)
					if arg_77_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("dorm_praise")
					end
				end)
			else
				local var_76_1 = {
					house_id = arg_64_0.houseDetail.house_id
				}

				arg_64_0.dorm:praiseHouse(var_76_1, function(arg_78_0, arg_78_1)
					if arg_78_0 == xyd.error.OK then
						arg_64_0.dorm.houseInfo.praise_num = arg_78_1.praise_num
						arg_64_0.dorm.houseInfo.is_has_praise = arg_78_1.is_has_praise

						arg_64_0:updatePraise()
					end
				end)
			end
		end
	end)
	arg_64_0:nodeByName("room_name"):setTouchEnabled(true)
	arg_64_0:nodeByName("room_name"):setTouchSwallowEnabled(true)
	arg_64_0:nodeByName("eye_open"):setTouchEnabled(true)
	arg_64_0:nodeByName("eye_open"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_79_0)
		if arg_79_0.name == "began" then
			return true
		elseif arg_79_0.name == "moved" then
			return true
		elseif arg_79_0.name == "ended" then
			local var_79_0 = {
				house_id = arg_64_0.houseDetail.house_id
			}

			arg_64_0.dorm:hideHouse(var_79_0, function(arg_80_0, arg_80_1)
				if arg_80_0 == xyd.error.OK then
					arg_64_0:updateRoomEye()

					if arg_64_0.dorm.houseInfo.is_hide == 0 then
						xyd.WindowManager.get():openWindow("toast", {
							message = xyd.tables.translation:translation("DORM_ROOM_OPEN_TIP")
						})
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = xyd.tables.translation:translation("DORM_ROOM_CLOSE_TIP")
						})
					end
				end
			end)
		end
	end)
	arg_64_0:nodeByName("msg_btn"):addTouchEventListener(function(arg_81_0, arg_81_1)
		if arg_81_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_81_0 = {
				house_id = arg_64_0.houseDetail.house_id
			}

			var_81_0.start = 0
			var_81_0.offset = 20
			var_81_0.total_num = 0

			arg_64_0.dorm:getCommentList(var_81_0, function(arg_82_0, arg_82_1)
				if arg_82_0 == xyd.error.OK then
					local var_82_0 = {
						data = arg_82_1.comment_list,
						house_id = arg_64_0.houseDetail.house_id
					}

					xyd.WindowManager.get():openWindow("dorm_message_board", var_82_0)
				end
			end)
		end
	end)
	arg_64_0:nodeByName("switch_container"):setTouchEnabled(true)
	arg_64_0:nodeByName("switch_container"):setTouchSwallowEnabled(true)
	arg_64_0:nodeByName("hide_btn"):setTouchEnabled(true)
	arg_64_0:nodeByName("hide_btn"):setTouchSwallowEnabled(true)
	arg_64_0:nodeByName("hide_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_83_0)
		if arg_83_0.name == "began" then
			return true
		elseif arg_83_0.name == "moved" then
			return true
		elseif arg_83_0.name == "ended" then
			xyd.playButtonSound()

			arg_64_0.isFurnitureHide = true

			arg_64_0:nodeByName("hide_btn"):setVisible(false)
			arg_64_0:nodeByName("show_btn"):setVisible(true)

			local var_83_0 = arg_64_0:nodeByName("furniture_container"):getContentSize().height
			local var_83_1 = cc.p(arg_64_0:nodeByName("furniture_container"):getPositionX(), -var_83_0)

			arg_64_0:nodeByName("furniture_container"):runActionOnce(cc.MoveTo:create(0.5, var_83_1))
		end
	end)
	arg_64_0:nodeByName("show_btn"):setTouchEnabled(true)
	arg_64_0:nodeByName("show_btn"):setTouchSwallowEnabled(true)
	arg_64_0:nodeByName("show_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_84_0)
		if arg_84_0.name == "began" then
			return true
		elseif arg_84_0.name == "moved" then
			return true
		elseif arg_84_0.name == "ended" then
			xyd.playButtonSound()

			arg_64_0.isFurnitureHide = false

			arg_64_0:nodeByName("hide_btn"):setVisible(true)
			arg_64_0:nodeByName("show_btn"):setVisible(false)

			local var_84_0 = cc.p(arg_64_0:nodeByName("furniture_container"):getPositionX(), 0)

			arg_64_0:nodeByName("furniture_container"):runActionOnce(cc.MoveTo:create(0.5, var_84_0))
		end
	end)
	arg_64_0:nodeByName("main_bg"):setTouchEnabled(true)
	arg_64_0:nodeByName("main_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_85_0)
		if arg_85_0.name == "began" then
			return true
		elseif arg_85_0.name == "moved" then
			local var_85_0 = cc.p(arg_64_0:nodeByName("centre_pos"):getPosition())
			local var_85_1 = xyd.subPosition(arg_85_0, cc.p(arg_85_0.prevX, arg_85_0.prevY))

			arg_64_0:nodeByName("centre_pos"):setPosition(arg_64_0:correctCentrePosPosition(xyd.addPosition(var_85_0, var_85_1)))

			return true
		elseif arg_85_0.name == "ended" then
			-- block empty
		end
	end)
	arg_64_0:nodeByName("slide_point"):setTouchEnabled(true)

	arg_64_0.barLen = arg_64_0:nodeByName("scale_bar"):getContentSize().width

	arg_64_0:updateRoomScale()
	arg_64_0:nodeByName("slide_point"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_86_0)
		if arg_86_0.name == "began" then
			return true
		elseif arg_86_0.name == "moved" then
			local var_86_0 = arg_64_0:nodeByName("scale_bar"):convertToNodeSpace(cc.p(arg_86_0.x, arg_86_0.y))

			arg_64_0.posX = var_86_0.x

			if arg_64_0.posX < 0 then
				arg_64_0.posX = 0
			elseif arg_64_0.posX > arg_64_0.barLen then
				arg_64_0.posX = arg_64_0.barLen
			end

			arg_64_0:nodeByName("slide_point"):setPositionX(arg_64_0.posX)
			arg_64_0:updateRoomScale()

			return true
		elseif arg_86_0.name == "ended" then
			-- block empty
		end
	end)
end

function var_0_0.clearBedItemEffect(arg_87_0)
	local var_87_0 = arg_87_0.maps[var_0_15.Floor]

	for iter_87_0, iter_87_1 in pairs(var_87_0) do
		local var_87_1 = arg_87_0:resolveKey(iter_87_0)

		if var_0_2:actType(var_87_1.item_id) == xyd.DormInteractionType.Sleep then
			iter_87_1.item:removeSleepEffect()
		end
	end
end

function var_0_0.correctCentrePosPosition(arg_88_0, arg_88_1)
	local var_88_0 = arg_88_0.dorm.houseSize
	local var_88_1 = 0.5 + 0.5 * (arg_88_0.posX / arg_88_0.barLen)
	local var_88_2 = var_88_0.long * var_0_11 * 2 * var_88_1
	local var_88_3 = var_88_0.long * var_0_12 * var_88_1
	local var_88_4 = var_88_0.height * var_0_12 * var_88_1
	local var_88_5 = math.min(var_88_2 / 2, 1280 - var_88_2 / 2) - 10
	local var_88_6 = math.max(var_88_2 / 2, 1280 - var_88_2 / 2) + 10
	local var_88_7 = math.min(720 - var_88_4, var_88_3) - 10
	local var_88_8 = math.max(720 - var_88_4, var_88_3) + 10

	arg_88_1.x = math.max(var_88_5, arg_88_1.x)
	arg_88_1.y = math.max(var_88_7, arg_88_1.y)
	arg_88_1.x = math.min(arg_88_1.x, var_88_6)
	arg_88_1.y = math.min(arg_88_1.y, var_88_8)

	return arg_88_1
end

function var_0_0.updateRoomScale(arg_89_0)
	if not arg_89_0.posX then
		arg_89_0.posX = arg_89_0.barLen * (var_0_5:scale(arg_89_0.houseTableId) - 0.5) * 2

		if arg_89_0.dorm:isCanExpand(arg_89_0.dorm.houseInfo) then
			arg_89_0.posX = 0
		end

		arg_89_0:nodeByName("slide_point"):setPositionX(arg_89_0.posX)
	end

	arg_89_0:nodeByName("scale_bar"):setPercent(arg_89_0.posX * 100 / arg_89_0.barLen)

	local var_89_0 = 0.5 + 0.5 * (arg_89_0.posX / arg_89_0.barLen)

	arg_89_0:nodeByName("centre_pos"):setScale(var_89_0)
	arg_89_0:nodeByName("progress_txt"):setString(tostring(math.floor(var_89_0 * 100)) .. "%")
	arg_89_0:nodeByName("centre_pos"):setPosition(arg_89_0:correctCentrePosPosition(cc.p(arg_89_0:nodeByName("centre_pos"):getPosition())))
end

function var_0_0.getFormationRecord(arg_90_0)
	local var_90_0 = {}

	for iter_90_0, iter_90_1 in pairs(var_0_15) do
		var_90_0[iter_90_1] = arg_90_0.dorm:getFormationMap(arg_90_0.maps[iter_90_1])
	end

	return var_90_0
end

function var_0_0.initItemTables(arg_91_0)
	arg_91_0.masks = {}
	arg_91_0.maps = {}

	local var_91_0 = arg_91_0.houseDetail.record

	for iter_91_0, iter_91_1 in pairs(var_0_15) do
		local var_91_1 = var_91_0[iter_91_1] or {}

		arg_91_0.maps[iter_91_1] = arg_91_0.dorm:parseMap(var_91_1)
	end
end

function var_0_0.initRoomShow(arg_92_0)
	for iter_92_0, iter_92_1 in ipairs(arg_92_0:nodeByName("floor_pos"):getChildren()) do
		if not xyd.isInTable(arg_92_0.notClearItem, iter_92_1:getName()) and not xyd.isInTable(arg_92_0.heroItems, iter_92_1) then
			iter_92_1:removeSelf()
		end
	end

	for iter_92_2, iter_92_3 in pairs(var_0_15) do
		arg_92_0:initMaps(iter_92_3)
		arg_92_0:initMasks(iter_92_3)
	end

	arg_92_0:reSetZOrder()
	arg_92_0:updateExpanded(true)
end

function var_0_0.updateExpanded(arg_93_0, arg_93_1)
	local var_93_0 = arg_93_0.dorm.houseInfo

	if arg_93_0.houseType ~= xyd.DormType.VILLA or not var_93_0.expand_lev or var_93_0.expand_lev >= 3 or not arg_93_0.isSelfDorm then
		return
	end

	local var_93_1 = 3 - var_93_0.expand_lev
	local var_93_2 = (var_93_0.expand_lev or 0) + 1
	local var_93_3 = var_0_8:houseExpand(var_93_2)
	local var_93_4 = xyd.AssetLoader.get():loadSprite(var_93_3)
	local var_93_5 = var_0_8:brand(var_93_2)
	local var_93_6 = xyd.AssetLoader.get():loadSprite(var_93_5)

	var_93_4:setAnchorPoint(cc.p(0.5, 0))
	var_93_4:setPositionY(-var_0_12 * 19 - 28)

	local var_93_7 = arg_93_0:getPanelPos(var_0_15.Floor)

	if var_93_7:getChildByName("house_expand") then
		var_93_7:getChildByName("house_expand"):removeSelf()
	end

	local var_93_8 = arg_93_0.dorm:getPiexlPosition(var_93_1 * 1 / 2 + 0.3, -3, var_0_15.Floor)

	var_93_4:addTo(arg_93_0:getPanelPos(var_0_15.Floor))
	var_93_4:setLocalZOrder(100000)
	var_93_4:setName("house_expand")
	var_93_6:addTo(var_93_4)
	var_93_6:setAnchorPoint(cc.p(0.5, 0))
	var_93_6:setPosition(xyd.addPosition(cc.p(0, 19 * var_0_12 / 2), var_93_8))

	local function var_93_9(...)
		arg_93_0:updateExpanded()
	end

	var_93_6:setTouchEnabled(true)
	var_93_6:setTouchSwallowEnabled(true)
	var_93_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_95_0)
		if arg_95_0.name == "began" then
			return true
		elseif arg_95_0.name == "moved" then
			return true
		elseif arg_95_0.name == "ended" and not arg_93_0.scrollViewMoved_ and not arg_93_0.isExpanding and not arg_93_0.isOnChangeItem then
			local var_95_0 = {
				callback = var_93_9
			}

			xyd.WindowManager.get():openWindow("dorm_room_expand", var_95_0)
		end
	end)

	if var_93_0.expand_start_time and var_93_0.expand_start_time > 0 then
		if not arg_93_1 then
			arg_93_0.isExpanding = true

			arg_93_0:playExpandEffect(function()
				local var_96_0 = {
					callback = var_93_9
				}

				arg_93_0.isExpanding = false

				xyd.WindowManager.get():openWindow("dorm_room_expand_wating", var_96_0)
			end)
		else
			local var_93_10 = {
				callback = var_93_9
			}

			xyd.WindowManager.get():openWindow("dorm_room_expand_wating", var_93_10)
		end
	end
end

function var_0_0.clearMaps(arg_97_0)
	for iter_97_0, iter_97_1 in pairs(var_0_15) do
		local var_97_0 = {}
		local var_97_1 = table.keys(arg_97_0.maps[iter_97_1])

		for iter_97_2, iter_97_3 in pairs(var_97_1) do
			local var_97_2 = arg_97_0:resolveKey(iter_97_3).item_id

			if var_0_2:actType(var_97_2) == xyd.DormInteractionType.Dress then
				var_97_0[iter_97_3] = arg_97_0.maps[iter_97_1][iter_97_3]
			else
				arg_97_0.itemRecord[tostring(var_97_2)] = arg_97_0.itemRecord[tostring(var_97_2)] - 1
			end
		end

		arg_97_0.maps[iter_97_1] = var_97_0
	end

	arg_97_0.scrollList:refreshList()
	arg_97_0:initRoomShow()
end

function var_0_0.initMaps(arg_98_0, arg_98_1)
	for iter_98_0, iter_98_1 in pairs(arg_98_0.maps[arg_98_1]) do
		if arg_98_0.dorm:isRootItem(iter_98_0) then
			arg_98_0:initMap(iter_98_0)
		end
	end
end

function var_0_0.initTopMask(arg_99_0)
	arg_99_0.topMask = {}
	arg_99_0.topologyKeys = {}

	local var_99_0 = arg_99_0.maps[var_0_15.Floor]
	local var_99_1 = table.keys(var_99_0)
	local var_99_2 = arg_99_0:getFreeGrid()

	for iter_99_0, iter_99_1 in pairs(var_99_2) do
		local var_99_3 = {
			item_id = xyd.DormRoomGirlItemID
		}

		var_99_3.is_flipped = 0
		var_99_3.coordX, var_99_3.coordY = iter_99_1.x, iter_99_1.y

		local var_99_4 = arg_99_0:getKeyByAttrs(var_99_3)

		table.insert(var_99_1, var_99_4)
	end

	for iter_99_2, iter_99_3 in pairs(var_99_1) do
		arg_99_0:updateTopMask(iter_99_3)
	end
end

function var_0_0.updateTopMask(arg_100_0, arg_100_1)
	local var_100_0 = arg_100_0:resolveKey(arg_100_1)

	if arg_100_0.dorm:isRootItem(arg_100_1) and var_0_2:floor(var_100_0.item_id) >= var_0_13 then
		table.insert(arg_100_0.topologyKeys, arg_100_1)

		local var_100_1 = arg_100_0:getItemSize(var_100_0)

		if var_100_1.height < 1 then
			var_100_1.height = 1
		end

		for iter_100_0 = 0, var_100_1.long + var_100_1.height - 1 do
			for iter_100_1 = 0, var_100_1.width + var_100_1.height - 1 do
				local var_100_2 = var_100_0.coordX + iter_100_0
				local var_100_3 = var_100_0.coordY + iter_100_1

				if (var_100_2 >= var_100_0.coordX + var_100_1.long or var_100_3 >= var_100_0.coordY + var_100_1.width) and iter_100_1 >= iter_100_0 - var_100_1.long and iter_100_0 >= iter_100_1 - var_100_1.width then
					local var_100_4 = arg_100_0:getIndexByCoordinate(var_100_2, var_100_3)

					arg_100_0.topMask[var_100_4] = arg_100_0.topMask[var_100_4] or {}

					table.insert(arg_100_0.topMask[var_100_4], arg_100_1)
				end
			end
		end
	end
end

function var_0_0.getItemTopologyParent(arg_101_0, arg_101_1)
	local var_101_0 = {}
	local var_101_1 = arg_101_0:resolveKey(arg_101_1)
	local var_101_2 = arg_101_0:getItemSize(var_101_1)

	for iter_101_0 = 0, var_101_2.long - 1 do
		for iter_101_1 = 0, var_101_2.width - 1 do
			local var_101_3 = var_101_1.coordX + iter_101_0
			local var_101_4 = var_101_1.coordY + iter_101_1
			local var_101_5 = arg_101_0:getIndexByCoordinate(var_101_3, var_101_4)
			local var_101_6 = arg_101_0.topMask[var_101_5]

			if var_101_6 and next(var_101_6) then
				for iter_101_2 = 1, #var_101_6 do
					if not xyd.isInTable(var_101_0, var_101_6[iter_101_2]) and var_101_6[iter_101_2] ~= arg_101_1 then
						table.insert(var_101_0, var_101_6[iter_101_2])
					end
				end
			end
		end
	end

	return var_101_0
end

function var_0_0.reSetZOrder(arg_102_0)
	local var_102_0 = arg_102_0.maps[var_0_15.Floor]
	local var_102_1 = table.keys(var_102_0)
	local var_102_2 = arg_102_0.topologyKeys
	local var_102_3 = {}

	for iter_102_0 = 1, #var_102_2 do
		var_102_3[var_102_2[iter_102_0]] = {
			parent = {},
			child = {}
		}
	end

	for iter_102_1 = 1, #var_102_2 do
		local var_102_4 = arg_102_0:getItemTopologyParent(var_102_2[iter_102_1])

		var_102_3[var_102_2[iter_102_1]].parent = var_102_4
		var_102_3[var_102_2[iter_102_1]].inDegree = #var_102_4

		for iter_102_2, iter_102_3 in pairs(var_102_4) do
			table.insert(var_102_3[iter_102_3].child, var_102_2[iter_102_1])
		end
	end

	local var_102_5 = {}

	while #var_102_5 < #var_102_2 do
		local var_102_6 = {}

		for iter_102_4, iter_102_5 in pairs(var_102_3) do
			if iter_102_5.inDegree <= 0 and not xyd.isInTable(var_102_5, iter_102_4) then
				table.insert(var_102_5, iter_102_4)

				for iter_102_6 = 1, #iter_102_5.child do
					local var_102_7 = iter_102_5.child[iter_102_6]

					var_102_3[var_102_7].inDegree = var_102_3[var_102_7].inDegree - 1
				end

				var_102_3[iter_102_4] = nil
			end
		end
	end

	arg_102_0.keyToZOrder = {}

	for iter_102_7 = 1, #var_102_5 do
		arg_102_0.keyToZOrder[var_102_5[iter_102_7]] = 20000 + #var_102_5 - iter_102_7
	end

	for iter_102_8 = 1, #var_102_5 do
		if var_102_0[var_102_5[iter_102_8]] then
			var_102_0[var_102_5[iter_102_8]].item:setLocalZOrder(arg_102_0.keyToZOrder[var_102_5[iter_102_8]])
		end
	end
end

function var_0_0.initMap(arg_103_0, arg_103_1)
	if not arg_103_1 then
		return arg_103_1
	end

	local var_103_0 = arg_103_0:resolveKey(arg_103_1)
	local var_103_1 = arg_103_0.maps[var_103_0.panel_type][arg_103_1]

	if not var_103_1 then
		return
	end

	local var_103_2 = {
		key = arg_103_1
	}
	local var_103_3 = import("app.windows.DormRoomItem").new(var_103_2)

	var_103_3:retain()

	local var_103_4 = arg_103_0:getParentItemByKey(arg_103_1)

	var_103_3:addTo(var_103_4)

	var_103_1.item = var_103_3

	arg_103_0:addEvent(var_103_3)

	for iter_103_0, iter_103_1 in pairs(var_103_1.children) do
		arg_103_0:initMap(iter_103_1)
	end
end

function var_0_0.initMasks(arg_104_0, arg_104_1)
	arg_104_0.masks[arg_104_1] = {}

	for iter_104_0, iter_104_1 in pairs(arg_104_0.maps[arg_104_1]) do
		if arg_104_0.dorm:isRootItem(iter_104_0) then
			arg_104_0:initMask(iter_104_0, arg_104_1)
		end
	end

	if arg_104_1 == var_0_15.Floor then
		arg_104_0:initTopMask()
	end
end

function var_0_0.initMask(arg_105_0, arg_105_1, arg_105_2)
	if not arg_105_1 then
		return
	end

	local var_105_0 = arg_105_0:resolveKey(arg_105_1)

	arg_105_2 = arg_105_2 or var_105_0.panel_type

	local var_105_1, var_105_2 = arg_105_0.dorm:getPanelSize(arg_105_2)
	local var_105_3 = arg_105_0.masks[arg_105_2]
	local var_105_4 = arg_105_0:getItemMaskInfo(arg_105_1)
	local var_105_5 = var_105_4.size

	for iter_105_0 = 0, var_105_5.long - 1 do
		for iter_105_1 = 0, var_105_5.width - 1 do
			local var_105_6 = var_105_4.coordX + iter_105_0
			local var_105_7 = var_105_4.coordY + iter_105_1
			local var_105_8 = arg_105_0:getIndexByCoordinate(var_105_6, var_105_7)

			if var_105_4.canBePile == 1 and var_105_4.layer >= var_0_13 then
				for iter_105_2 = 1, var_105_5.height do
					if var_105_1 <= var_105_6 + iter_105_2 or var_105_2 <= var_105_7 + iter_105_2 then
						local var_105_9 = arg_105_0:getIndexByCoordinate(var_105_6 + iter_105_2, var_105_7 + iter_105_2)

						if not var_105_3[var_105_9] then
							var_105_3[var_105_9] = {}
						end

						var_105_3[var_105_9][var_0_13] = -1
					end
				end
			end

			local var_105_10 = arg_105_0:getIndexByCoordinate(var_105_6 + var_105_5.height, var_105_7 + var_105_5.height)

			var_105_3[var_105_8] = var_105_3[var_105_8] or {}

			if var_105_4.layer <= var_0_13 then
				var_105_3[var_105_8][var_105_4.layer] = var_105_4.key
			else
				var_105_3[var_105_8][var_105_4.layer] = nil
			end

			if var_105_4.canBePile == 1 and var_105_4.layer >= var_0_13 and (not var_105_4.startPoint or var_105_4.startPoint and var_105_4.endPoint and iter_105_0 >= var_105_4.startPoint[1] and iter_105_0 < var_105_4.endPoint[1] and iter_105_1 >= var_105_4.startPoint[2] and iter_105_1 < var_105_4.endPoint[2]) then
				var_105_3[var_105_10] = var_105_3[var_105_10] or {}
				var_105_3[var_105_10][var_105_4.layer + 1] = var_105_4.key
			end
		end
	end

	local var_105_11 = arg_105_0.maps[arg_105_2][arg_105_1]

	for iter_105_3, iter_105_4 in pairs(var_105_11.children) do
		arg_105_0:initMask(iter_105_4, arg_105_2)
	end
end

function var_0_0.getIndexByCoordinate(arg_106_0, arg_106_1, arg_106_2, arg_106_3)
	return arg_106_0.dorm:getIndexByCoordinate(arg_106_1, arg_106_2, arg_106_3)
end

function var_0_0.getItemMaskInfo(arg_107_0, arg_107_1)
	local var_107_0 = {}
	local var_107_1 = xyd.split(arg_107_1, "|")
	local var_107_2 = 0
	local var_107_3 = 0

	for iter_107_0 = 1, #var_107_1 do
		local var_107_4 = arg_107_0:resolveKey(var_107_1[iter_107_0])

		var_107_2, var_107_3 = arg_107_0.dorm:moveCoordinate(var_107_2, var_107_3, var_107_4.coordX, var_107_4.coordY)

		if iter_107_0 <= #var_107_1 - 1 then
			local var_107_5 = var_0_2:coverHeight(var_107_4.item_id)

			var_107_2, var_107_3 = arg_107_0.dorm:moveCoordinate(var_107_2, var_107_3, var_107_5, var_107_5)
		end

		if iter_107_0 == #var_107_1 then
			if var_0_2:isPileLimit(var_107_4.item_id) == 1 then
				var_107_0.isPileLimit = true

				local var_107_6 = var_0_2:pileLimitCoordinateStart(var_107_4.item_id)
				local var_107_7 = var_0_2:pileLimitCoordinateEnd(var_107_4.item_id)

				if var_107_4.is_flipped == 0 then
					var_107_0.startPoint = var_107_6
					var_107_0.endPoint = var_107_7
				else
					var_107_0.startPoint = {
						var_107_6[2],
						var_107_6[1]
					}
					var_107_0.endPoint = {
						var_107_7[2],
						var_107_7[1]
					}
				end
			end

			arg_107_0:initItemRelatedMaskInfo(var_107_0, var_107_4)

			if var_0_2:floor(var_107_4.item_id) >= var_0_13 then
				var_107_0.layer = #var_107_1 + var_0_13 - 1
			else
				var_107_0.layer = var_0_2:floor(var_107_4.item_id)
			end
		end
	end

	var_107_0.coordX = var_107_2
	var_107_0.coordY = var_107_3
	var_107_0.key = arg_107_1

	return var_107_0
end

function var_0_0.initItemRelatedMaskInfo(arg_108_0, arg_108_1, arg_108_2)
	local var_108_0 = arg_108_2.item_id

	arg_108_1.size = arg_108_0:getItemSize(arg_108_2)
	arg_108_1.canPile = var_0_2:canPile(var_108_0)
	arg_108_1.canBePile = var_0_2:canBePile(var_108_0)
end

function var_0_0.resolveKey(arg_109_0, arg_109_1)
	return arg_109_0.dorm:resolveKey(arg_109_1)
end

function var_0_0.swapKeyCoordinate(arg_110_0, arg_110_1)
	local var_110_0 = arg_110_0:resolveKey(arg_110_1)

	var_110_0.coordX, var_110_0.coordY = var_110_0.coordY, var_110_0.coordX

	return arg_110_0:getKeyByAttrs(var_110_0)
end

function var_0_0.getFlippedKey(arg_111_0, arg_111_1, arg_111_2)
	local var_111_0 = arg_111_0:resolveKey(arg_111_1)

	if arg_111_2 then
		var_111_0.parent_key = arg_111_2
	end

	local var_111_1 = arg_111_0:getItemSize(var_111_0)

	var_111_0.coordX, var_111_0.coordY = arg_111_0.dorm:flipCoordinate(var_111_0.coordX, var_111_0.coordY, var_111_1.long, var_111_1.width)
	var_111_0.is_flipped = 1 - var_111_0.is_flipped

	return arg_111_0:getKeyByAttrs(var_111_0)
end

function var_0_0.replaceKeyParent(arg_112_0, arg_112_1, arg_112_2)
	local var_112_0 = arg_112_0:resolveKey(arg_112_1)

	var_112_0.parent_key = arg_112_2

	return arg_112_0:getKeyByAttrs(var_112_0)
end

function var_0_0.moveKeyCoordinate(arg_113_0, arg_113_1, arg_113_2, arg_113_3)
	local var_113_0 = arg_113_0:resolveKey(arg_113_1)

	var_113_0.coordX = var_113_0.coordX + arg_113_2
	var_113_0.coordY = var_113_0.coordY + arg_113_3

	return arg_113_0:getKeyByAttrs(var_113_0)
end

function var_0_0.setKeyCoordinate(arg_114_0, arg_114_1, arg_114_2, arg_114_3)
	local var_114_0 = arg_114_0:resolveKey(arg_114_1)

	var_114_0.coordX, var_114_0.coordY = arg_114_2, arg_114_3

	return arg_114_0:getKeyByAttrs(var_114_0)
end

function var_0_0.getKeyByAttrs(arg_115_0, arg_115_1)
	return arg_115_0.dorm:getKeyByAttrs(arg_115_1)
end

function var_0_0.flipSelectItem(arg_116_0)
	local var_116_0 = arg_116_0.selectInfo.selectContent
	local var_116_1 = arg_116_0.selectInfo.itemTree
	local var_116_2 = var_116_1.item
	local var_116_3 = arg_116_0.maps[var_116_2.panelType]
	local var_116_4 = arg_116_0:getFlippedKey(var_116_2.key)

	var_116_2:setKey(var_116_4)

	local var_116_5 = var_116_1.children
	local var_116_6 = {}

	for iter_116_0 = 1, #var_116_5 do
		arg_116_0:flipItem(var_116_5[iter_116_0], var_116_4)
		table.insert(var_116_6, arg_116_0:getChildFilpedKey(var_116_5[iter_116_0], var_116_4))
	end

	var_116_1.children = var_116_6

	arg_116_0:updateSelectInfo()
	arg_116_0:setSelectBtnSate()
end

function var_0_0.flipItem(arg_117_0, arg_117_1, arg_117_2)
	local var_117_0 = arg_117_0:resolveKey(arg_117_1)
	local var_117_1 = arg_117_0.maps[var_117_0.panel_type]
	local var_117_2 = var_117_1[arg_117_1]
	local var_117_3 = arg_117_0:getChildFilpedKey(arg_117_1, arg_117_2)

	var_117_1[arg_117_1] = nil
	var_117_1[var_117_3] = var_117_2

	var_117_2.item:setKey(var_117_3)

	local var_117_4 = var_117_2.children
	local var_117_5 = {}

	for iter_117_0 = 1, #var_117_4 do
		arg_117_0:flipItem(var_117_4[iter_117_0], var_117_3)
		table.insert(var_117_5, arg_117_0:getChildFilpedKey(var_117_4[iter_117_0], var_117_3))
	end

	var_117_2.children = var_117_5
end

function var_0_0.getChildFilpedKey(arg_118_0, arg_118_1, arg_118_2)
	local var_118_0 = arg_118_0:resolveKey(arg_118_1)

	var_118_0.coordX, var_118_0.coordY = var_118_0.coordY, var_118_0.coordX
	var_118_0.is_flipped = 1 - var_118_0.is_flipped

	if arg_118_2 then
		var_118_0.parent_key = arg_118_2
	end

	return arg_118_0:getKeyByAttrs(var_118_0)
end

function var_0_0.getItemMask(arg_119_0, arg_119_1, arg_119_2, arg_119_3)
	local var_119_0 = arg_119_2 or arg_119_1.coordX
	local var_119_1 = arg_119_3 or arg_119_1.coordY
	local var_119_2 = arg_119_1.l
	local var_119_3 = arg_119_1.w
	local var_119_4 = {}
	local var_119_5 = arg_119_0.masks[arg_119_0.dorm:getPanelTypeByKey(arg_119_1.key)]
	local var_119_6
	local var_119_7 = var_0_2:floor(arg_119_1.tableId)
	local var_119_8 = var_0_14

	if var_119_7 >= var_0_13 then
		var_119_7 = var_0_13
	end

	if var_119_7 < var_0_13 then
		var_119_8 = var_119_7
	end

	for iter_119_0 = 0, var_119_2 - 1 do
		for iter_119_1 = 0, var_119_3 - 1 do
			local var_119_9 = var_119_0 + iter_119_0
			local var_119_10 = var_119_1 + iter_119_1
			local var_119_11 = var_119_5[arg_119_0:getIndexByCoordinate(var_119_9, var_119_10)] or {}

			if not var_119_6 then
				var_119_6 = clone(var_119_11)

				for iter_119_2 = 1, var_119_7 - 1 do
					var_119_6[iter_119_2] = -1
				end

				for iter_119_3 = var_119_8 + 1, var_0_14 do
					var_119_6[iter_119_3] = -1
				end
			end

			for iter_119_4 = var_119_7, var_119_8 do
				local var_119_12 = var_119_11[iter_119_4]

				if var_119_12 and iter_119_4 > var_0_13 then
					local var_119_13 = arg_119_0:resolveKey(var_119_12)

					if var_0_2:floor(var_119_13.item_id) < var_0_2:floor(arg_119_1.tableId) then
						var_119_4[arg_119_0:getIndexByCoordinate(iter_119_0, iter_119_1, var_119_2)] = var_119_12
					else
						var_119_6[iter_119_4] = -1
					end
				elseif var_119_12 and iter_119_4 <= var_0_13 then
					var_119_4[arg_119_0:getIndexByCoordinate(iter_119_0, iter_119_1, var_119_2)] = -1
					var_119_6[iter_119_4] = -1
				elseif iter_119_4 <= var_0_13 and (var_119_9 < 0 or var_119_10 < 0 or var_119_9 > arg_119_0.houseSize.long - 1 or var_119_10 > arg_119_0.houseSize.width - 1) then
					var_119_4[arg_119_0:getIndexByCoordinate(iter_119_0, iter_119_1, var_119_2)] = -1
					var_119_6[iter_119_4] = -1
				end

				if var_119_12 ~= var_119_6[iter_119_4] then
					var_119_6[iter_119_4] = -1
				end
			end
		end
	end

	return var_119_4, var_119_6
end

function var_0_0.getItemSize(arg_120_0, arg_120_1)
	return var_0_2:getItemSize(arg_120_1.item_id, arg_120_1.is_flipped)
end

function var_0_0.getInitCoordinate(arg_121_0, arg_121_1, arg_121_2, arg_121_3)
	local var_121_0 = var_0_2:getItemSize(arg_121_1, arg_121_2)
	local var_121_1 = arg_121_0.dorm:getItemPanelType(arg_121_1, arg_121_2)
	local var_121_2, var_121_3 = arg_121_0.dorm:getPanelSize(var_121_1)
	local var_121_4 = arg_121_0.dorm:getSearchCoordinateList(var_121_1)

	for iter_121_0, iter_121_1 in pairs(var_121_4) do
		if iter_121_1.x < 0 or iter_121_1.x > var_121_2 - var_121_0.long or iter_121_1.y < 0 or iter_121_1.y > var_121_3 - var_121_0.width then
			-- block empty
		elseif arg_121_0:isCanAddItem(arg_121_1, iter_121_1.x, iter_121_1.y, var_121_1, arg_121_3) then
			return math.ceil(iter_121_1.x), math.ceil(iter_121_1.y)
		end
	end

	arg_121_0.dorm:getSearchCoordinateList(var_121_1)
end

function var_0_0.isCanAddItem(arg_122_0, arg_122_1, arg_122_2, arg_122_3, arg_122_4, arg_122_5)
	local var_122_0 = var_0_2:getItemSize(arg_122_1)
	local var_122_1 = var_0_2:floor(arg_122_1)

	if var_122_1 > var_0_13 then
		var_122_1 = var_0_13
	end

	arg_122_5 = arg_122_5 or {}

	for iter_122_0, iter_122_1 in pairs(arg_122_5) do
		if arg_122_2 == iter_122_1.coordX and arg_122_3 == iter_122_1.coordY then
			return false
		end
	end

	local var_122_2 = arg_122_0.masks[arg_122_4]
	local var_122_3 = true

	for iter_122_2 = 0, var_122_0.long - 1 do
		for iter_122_3 = 0, var_122_0.width - 1 do
			local var_122_4 = arg_122_0:getIndexByCoordinate(arg_122_2 + iter_122_2, arg_122_3 + iter_122_3)

			if var_122_2[var_122_4] and var_122_2[var_122_4][var_122_1] then
				var_122_3 = false
			end

			if not var_122_3 then
				return false
			end
		end
	end

	return var_122_3
end

function var_0_0.deleteSelectItem(arg_123_0)
	local var_123_0 = arg_123_0.selectInfo.addKey
	local var_123_1 = arg_123_0.selectInfo.itemTree

	var_123_0 = var_123_0 or var_123_1.item.key

	local var_123_2 = arg_123_0:resolveKey(var_123_0)
	local var_123_3 = var_123_1.children
	local var_123_4 = arg_123_0.maps[var_123_2.panel_type]

	var_123_4[var_123_0] = nil

	for iter_123_0 = 1, #var_123_3 do
		local var_123_5 = var_123_4[var_123_3[iter_123_0]]

		var_123_4[var_123_3[iter_123_0]] = nil

		local var_123_6 = arg_123_0:resolveKey(var_123_3[iter_123_0])
		local var_123_7 = arg_123_0:replaceKeyParent(var_123_3[iter_123_0], var_123_2.parent_key)
		local var_123_8 = arg_123_0:moveKeyCoordinate(var_123_7, var_123_2.coordX, var_123_2.coordY)

		arg_123_0:addItemTree(var_123_8, var_123_5)
	end

	var_123_1.item:removeFromParent()
	arg_123_0:changeItemRecord(var_123_2.item_id, -1)
	arg_123_0:initMasks(var_123_2.panel_type)
	arg_123_0:setNetVisible(false)
end

function var_0_0.changeItemRecord(arg_124_0, arg_124_1, arg_124_2)
	arg_124_0.itemRecord[tostring(arg_124_1)] = (arg_124_0.itemRecord[tostring(arg_124_1)] or 0) + arg_124_2

	arg_124_0.scrollList:refreshList()

	arg_124_0.currentComfort = arg_124_0.currentComfort + var_0_2:comfort(arg_124_1) * arg_124_2

	arg_124_0:updateComfortInfo()
end

function var_0_0.removeItemTreeInfo(arg_125_0, arg_125_1)
	local var_125_0 = arg_125_0:resolveKey(arg_125_1)
	local var_125_1 = arg_125_0.maps[var_125_0.panel_type]
	local var_125_2 = var_125_1[arg_125_1]

	if var_125_0.parent_key then
		local var_125_3 = var_125_1[var_125_0.parent_key].children

		for iter_125_0 = 1, #var_125_3 do
			if var_125_3[iter_125_0] == arg_125_1 then
				table.remove(var_125_3, iter_125_0)

				break
			end
		end
	end

	var_125_1[arg_125_1] = nil

	arg_125_0:initMasks(var_125_0.panel_type)
end

function var_0_0.addItemTree(arg_126_0, arg_126_1, arg_126_2)
	local var_126_0 = arg_126_2.item

	var_126_0:setOpacity(255)
	var_126_0:removeFromParent()
	var_126_0:addTo(arg_126_0:getParentItemByKey(arg_126_1))
	arg_126_0:addEvent(var_126_0)

	local var_126_1 = arg_126_0:resolveKey(arg_126_1)
	local var_126_2 = arg_126_0.maps[var_126_1.panel_type]

	if var_126_1.parent_key then
		table.insert(var_126_2[var_126_1.parent_key].children, arg_126_1)
	end

	var_126_2[arg_126_1] = arg_126_2

	arg_126_0:updateKeyRecursively(arg_126_1)
	arg_126_0:initMask(arg_126_1, var_126_1.panel_type)
	arg_126_0:initTopMask()
	arg_126_0:reSetZOrder()
end

function var_0_0.getParentItemByKey(arg_127_0, arg_127_1)
	local var_127_0 = arg_127_0:resolveKey(arg_127_1)

	if not var_127_0.parent_key then
		return arg_127_0:getPanelPos(var_127_0.panel_type)
	else
		return arg_127_0.maps[var_127_0.panel_type][var_127_0.parent_key].item
	end
end

function var_0_0.getPanelPos(arg_128_0, arg_128_1)
	return arg_128_0:nodeByName("floor_pos")
end

function var_0_0.updateKeyRecursively(arg_129_0, arg_129_1)
	local var_129_0 = arg_129_0:resolveKey(arg_129_1)
	local var_129_1 = arg_129_0.maps[var_129_0.panel_type]
	local var_129_2 = var_129_1[arg_129_1]

	var_129_2.item:setKey(arg_129_1)
	arg_129_0:addEvent(var_129_2.item)

	local var_129_3 = var_129_2.children
	local var_129_4 = {}

	for iter_129_0 = 1, #var_129_3 do
		local var_129_5 = arg_129_0:replaceKeyParent(var_129_3[iter_129_0], arg_129_1)

		table.insert(var_129_4, var_129_5)

		local var_129_6 = var_129_1[var_129_3[iter_129_0]]

		var_129_1[var_129_3[iter_129_0]] = nil
		var_129_1[var_129_5] = var_129_6

		arg_129_0:updateKeyRecursively(var_129_5)
	end

	var_129_2.children = var_129_4
end

function var_0_0.selectType(arg_130_0, arg_130_1, arg_130_2)
	arg_130_0:nodeByName("all_select_icon"):setOpacity(0)
	arg_130_0:nodeByName("all_text"):setVisible(false)
	arg_130_0:nodeByName("return_icon"):setVisible(true)

	if arg_130_1 == var_0_16.All then
		arg_130_0.classType = var_0_16.All
		arg_130_0.furnitureTypes = var_0_3:ids()

		arg_130_0:nodeByName("all_select_icon"):setOpacity(255)
		arg_130_0:nodeByName("all_text"):setVisible(true)
		arg_130_0:nodeByName("return_icon"):setVisible(false)
	elseif arg_130_1 == var_0_16.MainType then
		arg_130_0.classType = var_0_16.SubType
		arg_130_0.furnitureTypes = var_0_3:subTypes(arg_130_2)
		arg_130_0.furnitureType = arg_130_0.furnitureTypes[1]
	elseif arg_130_1 == var_0_16.SubType then
		arg_130_0.classType = var_0_16.SubType
		arg_130_0.furnitureType = arg_130_2
	end

	arg_130_0.classScrollList:reload()
	arg_130_0:updateScrollList()
end

function var_0_0.updateScrollList(arg_131_0)
	arg_131_0.itemIds = arg_131_0:getFurnitureIds(arg_131_0.classType, arg_131_0.furnitureType, arg_131_0.isShowOwnItem)

	arg_131_0.scrollList:reload()
end

function var_0_0.initSelectItems(arg_132_0)
	for iter_132_0, iter_132_1 in pairs(arg_132_0.selectItems) do
		arg_132_0:nodeByName("all_select_icon"):setOpacity(0)
		iter_132_1:getChildByName("container"):getChildByName("class_select_icon"):setVisible(false)
	end
end

function var_0_0.getFurnitureIds(arg_133_0, arg_133_1, arg_133_2, arg_133_3)
	local var_133_0 = {}

	if arg_133_1 == var_0_16.All then
		local var_133_1 = var_0_3:ids()

		for iter_133_0, iter_133_1 in pairs(var_133_1) do
			var_133_0 = xyd.mergeTable(var_133_0, var_0_3:subTypes(iter_133_1), true)
		end
	elseif arg_133_1 == var_0_16.SubType then
		table.insert(var_133_0, arg_133_2)
	end

	local var_133_2 = {}

	for iter_133_2, iter_133_3 in pairs(var_133_0) do
		xyd.mergeTable(var_133_2, var_0_4:itemIds(iter_133_3), true)
	end

	if arg_133_3 then
		for iter_133_4 = #var_133_2, 1, -1 do
			local var_133_3 = var_133_2[iter_133_4]

			if arg_133_0.backPack:getItemNumByID(var_133_3) - (arg_133_0.itemRecord[tostring(var_133_3)] or 0) <= 0 then
				table.remove(var_133_2, iter_133_4)
			end
		end
	end

	return var_133_2
end

function var_0_0.scrollListDelegate(arg_134_0, arg_134_1, arg_134_2, arg_134_3)
	if cc.ui.UIListView.COUNT_TAG == arg_134_2 then
		return #arg_134_0.itemIds
	elseif cc.ui.UIListView.CELL_TAG == arg_134_2 then
		local var_134_0
		local var_134_1 = arg_134_0.scrollList:dequeueItem()

		if not var_134_1 then
			var_134_1 = arg_134_0.scrollList:newItem()
		else
			var_134_1:removeAllChildren(true)
		end

		local var_134_2 = arg_134_0:createListContent(arg_134_0.itemIds[arg_134_3])
		local var_134_3 = var_134_2:getWidth()
		local var_134_4 = var_134_2:getHeight()

		var_134_1:setItemSize(var_134_3, var_134_4)
		var_134_1:addContent(var_134_2)

		return var_134_1
	end
end

function var_0_0.createListContent(arg_135_0, arg_135_1)
	local var_135_0 = display.newNode()
	local var_135_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/dorm/room/item.csb")
	local var_135_2 = var_135_1:getChildByName("container")
	local var_135_3 = var_135_2:getChildByName("icon_container")
	local var_135_4 = var_0_2:icon(arg_135_1)
	local var_135_5 = var_135_3:getContentSize().width
	local var_135_6 = xyd.AssetLoader.get():loadSprite(var_135_4)

	var_135_6:setScale(math.min(120 / var_135_6:getContentSize().width, 120 / var_135_6:getContentSize().height))
	var_135_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_135_6:addTo(var_135_3)
	var_135_6:setPosition(cc.p(var_135_3:getContentSize().width / 2, var_135_3:getContentSize().height / 2))
	var_135_2:getChildByName("comfort_txt"):setString(var_0_2:comfort(arg_135_1))

	local function var_135_7()
		local var_136_0 = arg_135_0.backPack:getItemNumByID(arg_135_1)

		var_135_2:getChildByName("num_txt"):setString(tostring(var_136_0 - (arg_135_0.itemRecord[tostring(arg_135_1)] or 0)) .. "/" .. tostring(var_136_0))
	end

	var_135_3:setTouchEnabled(true)
	var_135_3:addTouchEventListener(function(arg_137_0, arg_137_1)
		if arg_137_1 == ccui.TouchEventType.ended and not arg_135_0.scrollViewMoved_ then
			if not arg_135_0:confirmSelectItem() then
				return
			end

			if arg_135_0.backPack:getItemNumByID(arg_135_1) - (arg_135_0.itemRecord[tostring(arg_135_1)] or 0) <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("DORM_FURNITRE_NOT_ENOUGH")
				})

				return
			end

			local var_137_0 = arg_135_0:initItem(arg_135_1)

			arg_135_0.itemChanged = true
		end
	end)
	var_135_7()
	var_135_1:addTo(var_135_0)
	var_135_1:setAnchorPoint(cc.p(0, 0))
	var_135_0:setContentSize(var_135_2:getContentSize())
	var_135_1:setName("source")

	return var_135_0
end

function var_0_0.classScrollListDelegate(arg_138_0, arg_138_1, arg_138_2, arg_138_3)
	if cc.ui.UIListView.COUNT_TAG == arg_138_2 then
		return #arg_138_0.furnitureTypes
	elseif cc.ui.UIListView.CELL_TAG == arg_138_2 then
		local var_138_0
		local var_138_1 = arg_138_0.scrollList:dequeueItem()

		if not var_138_1 then
			var_138_1 = arg_138_0.scrollList:newItem()
		else
			var_138_1:removeAllChildren(true)
		end

		local var_138_2 = arg_138_0:createClassListContent(arg_138_3)
		local var_138_3 = var_138_2:getWidth()
		local var_138_4 = var_138_2:getHeight()

		var_138_1:setItemSize(var_138_3, var_138_4)
		var_138_1:addContent(var_138_2)

		return var_138_1
	end
end

function var_0_0.createClassListContent(arg_139_0, arg_139_1)
	local var_139_0 = display.newNode()
	local var_139_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/dorm/room/class_item.csb")
	local var_139_2 = var_139_1:getChildByName("container")
	local var_139_3

	if arg_139_0.classType == var_0_16.All then
		local var_139_4 = arg_139_0.furnitureTypes[arg_139_1]

		var_139_2:getChildByName("class_name_txt"):setString(var_0_3:name(var_139_4))

		local var_139_5 = var_0_3:icon(var_139_4)

		var_139_3 = xyd.AssetLoader.get():loadSprite(var_139_5)
		var_139_3.classType = var_0_16.MainType
		var_139_3.furnitureType = var_139_4

		var_139_2:getChildByName("class_select_icon"):setVisible(false)
	else
		local var_139_6 = arg_139_0.furnitureTypes[arg_139_1]

		var_139_2:getChildByName("class_name_txt"):setString(var_0_4:name(var_139_6))

		local var_139_7 = var_0_4:icon(var_139_6)

		var_139_3 = xyd.AssetLoader.get():loadSprite(var_139_7)
		var_139_3.classType = var_0_16.SubType
		var_139_3.furnitureType = var_139_6

		if arg_139_0.furnitureType == var_139_6 then
			var_139_2:getChildByName("class_select_icon"):setVisible(true)
		else
			var_139_2:getChildByName("class_select_icon"):setVisible(false)
		end
	end

	var_139_3:addTo(var_139_2:getChildByName("icon_pos"))
	var_139_1:setTouchEnabled(true)
	var_139_1:setTouchSwallowEnabled(false)
	var_139_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_140_0)
		if arg_140_0.name == "began" then
			return true
		elseif arg_140_0.name == "moved" then
			return true
		elseif arg_140_0.name == "ended" and not arg_139_0.scrollViewMoved_ then
			arg_139_0:selectType(var_139_3.classType, var_139_3.furnitureType)
		end
	end)
	var_139_1:addTo(var_139_0)
	var_139_1:setAnchorPoint(cc.p(0, 0))
	var_139_0:setContentSize(var_139_2:getContentSize())
	var_139_1:setName("source")

	return var_139_0
end

function var_0_0.initItem(arg_141_0, arg_141_1)
	local var_141_0 = {
		item_id = arg_141_1
	}

	var_141_0.is_flipped = 0
	var_141_0.coordX, var_141_0.coordY = arg_141_0:getInitCoordinate(arg_141_1, var_141_0.is_flipped)

	if (not var_141_0.coordX or not var_141_0.coordY) and arg_141_0.dorm:getItemPanelType(arg_141_1) == var_0_15.LeftWall and var_0_2:specialType(arg_141_1) ~= xyd.DormSpecialType.AutoFull then
		var_141_0.is_flipped = 1
		var_141_0.coordX, var_141_0.coordY = arg_141_0:getInitCoordinate(arg_141_1, var_141_0.is_flipped)
	end

	if var_0_2:specialType(arg_141_1) == xyd.DormSpecialType.AutoFull then
		var_141_0.coordX, var_141_0.coordY = 0, 0

		arg_141_0:clearCurrentWallOrFloor(arg_141_1)
	end

	if not var_141_0.coordX or not var_141_0.coordY then
		xyd.WindowManager.get():openWindow("toast", {
			message = xyd.tables.translation:translation("DORM_NO_SPACE_LEFT")
		})

		return false
	elseif arg_141_0.dorm:getItemPanelType(arg_141_1) == var_0_15.Floor and var_0_2:floor(arg_141_1) >= var_0_13 then
		local var_141_1 = arg_141_0:getFloorFreeGridNum()
		local var_141_2 = var_0_2:getItemSize(arg_141_1)

		if var_141_1 - var_141_2.long * var_141_2.width < arg_141_0.heroNumLimit then
			xyd.WindowManager.get():openWindow("toast", {
				message = xyd.tables.translation:translation("DORM_NO_SPACE_LEFT")
			})

			return false
		end
	end

	local var_141_3 = arg_141_0:getKeyByAttrs(var_141_0)
	local var_141_4 = {
		children = {},
		item = arg_141_0:getInitItem(var_141_3)
	}

	arg_141_0:addItemTree(var_141_3, var_141_4)
	arg_141_0:changeItemRecord(arg_141_1, 1)

	return true
end

function var_0_0.getFloorFreeGridNum(arg_142_0)
	local var_142_0 = arg_142_0.dorm.houseSize
	local var_142_1 = var_142_0.long * var_142_0.width
	local var_142_2 = arg_142_0.masks[var_0_15.Floor]

	for iter_142_0 = 0, var_142_0.long - 1 do
		for iter_142_1 = 0, var_142_0.width - 1 do
			local var_142_3 = var_142_2[arg_142_0:getIndexByCoordinate(iter_142_0, iter_142_1)]

			if var_142_3 and var_142_3[var_0_13] then
				var_142_1 = var_142_1 - 1
			end
		end
	end

	return var_142_1
end

function var_0_0.getFreeGrid(arg_143_0)
	local var_143_0 = {}
	local var_143_1 = arg_143_0.dorm.houseSize
	local var_143_2 = arg_143_0.masks[var_0_15.Floor]

	for iter_143_0 = 0, var_143_1.long - 1 do
		for iter_143_1 = 0, var_143_1.width - 1 do
			local var_143_3 = var_143_2[arg_143_0:getIndexByCoordinate(iter_143_0, iter_143_1)]

			if not var_143_3 or not var_143_3[var_0_13] then
				table.insert(var_143_0, cc.p(iter_143_0, iter_143_1))
			end
		end
	end

	return var_143_0
end

function var_0_0.clearCurrentWallOrFloor(arg_144_0, arg_144_1)
	if var_0_2:specialType(arg_144_1) ~= xyd.DormSpecialType.AutoFull then
		return
	end

	local var_144_0 = arg_144_0.dorm:getItemPanelType(arg_144_1)
	local var_144_1 = arg_144_0.maps[var_144_0]

	for iter_144_0, iter_144_1 in pairs(var_144_1) do
		local var_144_2 = arg_144_0:resolveKey(iter_144_0)

		if var_0_2:specialType(var_144_2.item_id) == xyd.DormSpecialType.AutoFull then
			iter_144_1.item:removeFromParent()
			arg_144_0:changeItemRecord(var_144_2.item_id, -1)

			var_144_1[iter_144_0] = nil
		end
	end
end

function var_0_0.getInitItem(arg_145_0, arg_145_1)
	local var_145_0 = {
		key = arg_145_1
	}
	local var_145_1 = import("app.windows.DormRoomItem").new(var_145_0)

	var_145_1:retain()

	return var_145_1
end

function var_0_0.scrollListener(arg_146_0, arg_146_1)
	if arg_146_1.name == "began" then
		arg_146_0.scrollViewMoved_ = false
		arg_146_0.prevX_ = arg_146_1.x
	elseif arg_146_1.name == "moved" and 5 <= math.abs(arg_146_1.x - arg_146_0.prevX_) then
		arg_146_0.scrollViewMoved_ = true
	end
end

function var_0_0.initChatBox(arg_147_0)
	local var_147_0 = xyd.AssetLoader.get()
	local var_147_1 = 24
	local var_147_2 = arg_147_0:nodeByName("edit_container")
	local var_147_3 = "windows/login/transparent.png"
	local var_147_4 = var_147_0:loadSprite(var_147_3)

	arg_147_0.chatBox_ = ccui.EditBox:create(var_147_2:getContentSize(), var_147_3)

	arg_147_0.chatBox_:setAnchorPoint(0, 0)
	arg_147_0.chatBox_:pos(0, 0):addTo(var_147_2)
	arg_147_0.chatBox_:setFont(var_147_0.FONT_NAME, var_147_1)
	arg_147_0.chatBox_:setPlaceholderFont(var_147_0.FONT_NAME, var_147_1)
	arg_147_0.chatBox_:setPlaceHolder(var_0_1:translation("CHAT_INPUT_MESSAGE"))
	arg_147_0.chatBox_:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_147_0.chatBox_:setFontColor(cc.c3b(0, 0, 0))
	arg_147_0.chatBox_:registerScriptEditBoxHandler(handler(arg_147_0, arg_147_0.inputboxEventHandler))
	arg_147_0.chatBox_:setInputFlag(3)
end

function var_0_0.inputboxEventHandler(arg_148_0, arg_148_1)
	if arg_148_1 == "return" then
		local var_148_0 = arg_148_0.chatBox_:getText()

		arg_148_0.chatBox_:setText("")

		local var_148_1 = xyd.getTextLen(var_148_0)

		if var_148_1 <= 0 then
			return
		elseif var_148_1 > 6 then
			local var_148_2 = string.format(xyd.tables.translation:translation("DORM_ROOM_NAME_LEN_LIMIT"), 6)

			xyd.WindowManager.get():openWindow("toast", {
				message = var_148_2
			})

			return
		end

		local var_148_3 = {
			house_id = arg_148_0.houseDetail.house_id,
			house_name = var_148_0
		}

		arg_148_0.dorm:changeHouseName(var_148_3, function(arg_149_0, arg_149_1)
			if arg_149_0 == xyd.error.OK and arg_148_0 and not tolua.isnull(arg_148_0) then
				arg_148_0:nodeByName("name_txt"):setString(var_148_0)
			end
		end)
	elseif arg_148_1 == "began" then
		arg_148_0.chatBox_:setText("")
	end
end

return var_0_0
