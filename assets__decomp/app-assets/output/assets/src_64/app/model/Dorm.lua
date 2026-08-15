local var_0_0 = class("Dorm", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.DormUnit.xunit
local var_0_3 = xyd.DormUnit.yunit
local var_0_4 = xyd.tables.dormFurnitureItem
local var_0_5 = xyd.tables.dormHouse
local var_0_6 = xyd.tables.dormExpand
local var_0_7 = {
	"dorm",
	"dorm_room",
	"my_house",
	"floor_view",
	"drom_room_select_hero",
	"select_key",
	"dorm_friend_list",
	"achievement",
	"red_envelope",
	"envelope_record",
	"grab_result"
}
local var_0_8 = xyd.DormPanelType
local var_0_9 = xyd.DormItemState

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.singlePageMsgNum = xyd.tables.misc.personCommentEveryPageMsgNum
end

function var_0_0.getHouseList(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0

	if arg_2_1 then
		({}).host_id = arg_2_1.host_id
	else
		local var_2_1 = {}
	end

	local var_2_2 = arg_2_1 or {}
	local var_2_3 = {
		host_id = var_2_2.host_id
	}

	xyd.Backend.get():request(xyd.mid.GET_HOUSE_LIST, var_2_3, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0.dormBaseInfo = arg_3_1.house_list
			arg_2_0.openFunctions = arg_3_1.open_functions

			if var_2_2.host_info then
				arg_2_0.dormPlayerID = var_2_2.host_info.player_id
			else
				arg_2_0.dormPlayerID = arg_2_0.selfPlayer.playerID
			end

			arg_2_0.dormPlayerInfo = var_2_2.host_info or arg_2_0.selfPlayer

			xyd.closeWindows(var_0_7)
			xyd.WindowManager.get():openWindow("dorm", var_2_2)

			if arg_2_0.dormPlayerID == arg_2_0.selfPlayer.playerID then
				arg_2_0:setOpenSelfRoom(true)
			end
		end

		if arg_2_2 then
			arg_2_2(arg_3_0, arg_3_1)
		end
	end)
end

function var_0_0.setOpenSelfRoom(arg_4_0, arg_4_1)
	arg_4_0.willOpenSelfRoom = arg_4_1
end

function var_0_0.getHouseBaseInfo(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in pairs(arg_5_0.dormBaseInfo) do
		for iter_5_2, iter_5_3 in pairs(iter_5_1) do
			if iter_5_3.house_id == arg_5_1 then
				return iter_5_3
			end
		end
	end
end

function var_0_0.setHouseBaseInfo(arg_6_0, arg_6_1)
	for iter_6_0, iter_6_1 in pairs(arg_6_0.dormBaseInfo) do
		for iter_6_2, iter_6_3 in pairs(iter_6_1) do
			if iter_6_3.house_id == arg_6_1.house_id then
				iter_6_1[iter_6_2] = arg_6_1
			end
		end
	end

	arg_6_0.houseInfo = arg_6_1
end

function var_0_0.openHouse(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.OPEN_HOUSE, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			-- block empty
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.visitRandomHouse(arg_9_0, arg_9_1)
	local var_9_0 = {}

	xyd.Backend.get():request(xyd.mid.VISIT_RANDOM_HOUSE, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0.dormBaseInfo = arg_10_1.house_infos.house_list
			arg_9_0.openFunctions = arg_10_1.house_infos.open_functions
			arg_9_0.dormPlayerID = arg_10_1.host_info.player_id
			arg_9_0.dormPlayerInfo = arg_10_1.host_info

			xyd.closeWindows(var_0_7)
			xyd.WindowManager.get():openWindow("dorm")
		end

		if arg_9_1 then
			arg_9_1(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.getHouseDetail(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	var_11_0.host_id = arg_11_0.dormPlayerID or arg_11_0.selfPlayer.playerID

	xyd.Backend.get():request(xyd.mid.GET_HOUSE_DETAIL, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0:handleResponse(arg_12_1)

			arg_11_0.houseDetail = arg_12_1.house_detail
			arg_11_0.houseInfo = arg_11_0:getHouseBaseInfo(arg_11_0.houseDetail.house_id)
			arg_11_0.houseSize = xyd.tables.dormHouse:areaSize(arg_11_0.houseInfo.table_id)

			if arg_11_0.houseInfo.expand_lev then
				arg_11_0.houseSize.long, arg_11_0.houseSize.width = arg_11_0.houseSize.long + arg_11_0.houseInfo.expand_lev, arg_11_0.houseSize.width + arg_11_0.houseInfo.expand_lev
			end

			arg_11_0:initRoomInfo()
			xyd.WindowManager.get():closeWindow("dorm_room")
			xyd.WindowManager.get():openWindow("dorm_room", arg_12_1)
		end

		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.initRoomInfo(arg_13_0)
	arg_13_0.commenList = {}
	arg_13_0.commentNum = 0
	arg_13_0.praiseList = {}
	arg_13_0.praiseTotalum = 0
end

function var_0_0.saveFurnitures(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_1 or {}

	xyd.Backend.get():request(xyd.mid.SAVE_FURNITURES, var_14_0, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK then
			arg_14_0.houseDetail.record = var_14_0.furniture_record

			arg_14_0:handleResponse(arg_15_1)
		end

		if arg_14_2 then
			arg_14_2(arg_15_0, arg_15_1)
		end
	end)
end

function var_0_0.houseEquip(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_1 or {}

	xyd.Backend.get():request(xyd.mid.HOUSE_EQUIP, var_16_0, function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK then
			arg_16_0:handleResponse(arg_17_1)
		end

		if arg_16_2 then
			arg_16_2(arg_17_0, arg_17_1)
		end
	end)
end

function var_0_0.enterHero(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = arg_18_1 or {}

	xyd.Backend.get():request(xyd.mid.ENTER_HERO, var_18_0, function(arg_19_0, arg_19_1)
		if arg_19_0 == xyd.error.OK then
			arg_18_0:handleResponse(arg_19_1)
		end

		if arg_18_2 then
			arg_18_2(arg_19_0, arg_19_1)
		end
	end)
end

function var_0_0.changeHouseName(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = arg_20_1 or {}

	xyd.Backend.get():request(xyd.mid.CHANGE_HOUSE_NAME, var_20_0, function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK then
			arg_20_0:handleResponse(arg_21_1)
		end

		if arg_20_2 then
			arg_20_2(arg_21_0, arg_21_1)
		end
	end)
end

function var_0_0.hideHouse(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = arg_22_1 or {}

	xyd.Backend.get():request(xyd.mid.HIDE_HOUSE, var_22_0, function(arg_23_0, arg_23_1)
		if arg_23_0 == xyd.error.OK then
			arg_22_0:handleResponse(arg_23_1)
		end

		if arg_22_2 then
			arg_22_2(arg_23_0, arg_23_1)
		end
	end)
end

function var_0_0.praiseHouse(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = arg_24_1 or {}

	var_24_0.host_id = arg_24_0.dormPlayerID or arg_24_0.selfPlayer.playerID

	xyd.Backend.get():request(xyd.mid.PRAISE_HOUSE, var_24_0, function(arg_25_0, arg_25_1)
		if arg_25_0 == xyd.error.OK then
			-- block empty
		end

		if arg_24_2 then
			arg_24_2(arg_25_0, arg_25_1)
		end
	end)
end

function var_0_0.getPraiseList(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = arg_26_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_DORM_PRAISE_LIST, var_26_0, function(arg_27_0, arg_27_1)
		if arg_27_0 == xyd.error.OK then
			arg_26_0.praiseList = arg_27_1.praise_list or {}
			arg_26_0.praiseTotalum = arg_27_1.total_num or 0
		end

		if arg_26_2 then
			arg_26_2(arg_27_0, arg_27_1)
		end
	end)
end

function var_0_0.toHouse(arg_28_0, arg_28_1, arg_28_2)
	if not arg_28_0:isSelfDorm() and arg_28_1.is_hide == 1 then
		xyd.WindowManager.get():openWindow("toast", {
			message = xyd.tables.translation:translation("DORM_VISIT_ROOM_HIDE_TIP")
		})

		return
	end

	local var_28_0 = {
		house_id = arg_28_1.house_id
	}

	arg_28_0:getHouseDetail(var_28_0, function(arg_29_0, arg_29_1)
		if arg_29_0 == xyd.error.OK and arg_28_2 then
			arg_28_2()
		end
	end)
end

function var_0_0.toLoungeHouse(arg_30_0)
	local var_30_0 = arg_30_0:getLoungeHouseInfo()

	arg_30_0:toHouse(var_30_0)
end

function var_0_0.getLoungeHouseInfo(arg_31_0)
	return arg_31_0.dormBaseInfo[xyd.DormType.LOUNGE][1]
end

function var_0_0.getPraiseInfos(arg_32_0)
	return arg_32_0.praiseList
end

function var_0_0.updatePraiseList(arg_33_0, arg_33_1)
	for iter_33_0 = 1, #arg_33_1 do
		table.insert(arg_33_0.praiseList, arg_33_1[iter_33_0])
	end
end

function var_0_0.getDormPraiseList(arg_34_0, arg_34_1, arg_34_2)
	if arg_34_1 then
		arg_34_0.praiseList = {}
	end

	local var_34_0 = arg_34_0:getPraiseInfos()

	if arg_34_0.praiseTotalum > 0 and #var_34_0 == arg_34_0.praiseTotalum then
		return
	end

	local var_34_1 = #arg_34_0.praiseList
	local var_34_2 = {
		start = var_34_1,
		offset = arg_34_0.singlePageMsgNum,
		house_id = arg_34_0.houseInfo.house_id
	}

	if arg_34_0.praiseTotalum and arg_34_0.praiseTotalum > 0 then
		var_34_2.total_num = arg_34_0.praiseTotalum
	end

	xyd.Backend.get():request(xyd.mid.GET_DORM_PRAISE_LIST, var_34_2, function(arg_35_0, arg_35_1, arg_35_2)
		if arg_35_0 == xyd.error.OK then
			if arg_35_1.praise_list and next(arg_35_1.praise_list) then
				arg_34_0:updatePraiseList(arg_35_1.praise_list)
			end

			if arg_35_1.total_num then
				arg_34_0.praiseTotalum = arg_35_1.total_num
			end

			if arg_34_2 then
				arg_34_2(arg_35_0, arg_35_1)
			end
		end
	end)
end

function var_0_0.commentHouse(arg_36_0, arg_36_1, arg_36_2)
	local var_36_0 = arg_36_1 or {}

	var_36_0.host_id = arg_36_0.dormPlayerID

	xyd.Backend.get():request(xyd.mid.COMMENT_HOUSE, var_36_0, function(arg_37_0, arg_37_1)
		if arg_37_0 == xyd.error.OK then
			arg_36_0:updateSpaceInfo(arg_37_1)
		end

		if arg_36_2 then
			arg_36_2(arg_37_0, arg_37_1)
		end
	end)
end

function var_0_0.getCommentList(arg_38_0, arg_38_1, arg_38_2)
	local var_38_0 = arg_38_1 or {}

	var_38_0.host_id = arg_38_0.dormPlayerID

	xyd.Backend.get():request(xyd.mid.GET_DORM_COMMENT_LIST, var_38_0, function(arg_39_0, arg_39_1)
		if arg_39_0 == xyd.error.OK then
			arg_38_0:updateSpaceInfo(arg_39_1)
		end

		if arg_38_2 then
			arg_38_2(arg_39_0, arg_39_1)
		end
	end)
end

function var_0_0.getDormCommentList(arg_40_0, arg_40_1, arg_40_2)
	if #arg_40_0:getCommentInfos(arg_40_1.pageNum) == arg_40_0.singlePageMsgNum then
		if arg_40_2 then
			arg_40_2(xyd.error.OK)
		end

		return
	end

	local var_40_0 = #arg_40_0.commenList
	local var_40_1 = {
		host_id = arg_40_0.dormPlayerID,
		start = var_40_0,
		offset = arg_40_0.singlePageMsgNum,
		house_id = arg_40_0.houseInfo.house_id
	}

	if arg_40_0.commentNum > 0 then
		var_40_1.comment_num = arg_40_0.commentNum
	end

	xyd.Backend.get():request(xyd.mid.GET_DORM_COMMENT_LIST, var_40_1, function(arg_41_0, arg_41_1, arg_41_2)
		if arg_41_0 == xyd.error.OK and arg_41_1.comment_list and next(arg_41_1.comment_list) then
			arg_40_0:updateCommentList(arg_41_1.comment_list)
		end

		if arg_40_2 then
			arg_40_2(arg_41_0, arg_41_1)
		end
	end)
end

function var_0_0.updateSpaceInfo(arg_42_0, arg_42_1)
	if arg_42_1.best_comments then
		arg_42_0.bestComments = arg_42_1.best_comments
	end

	if arg_42_1.comment_list then
		arg_42_0.commenList = arg_42_1.comment_list
	end

	if arg_42_1.comment_num then
		arg_42_0.commentNum = arg_42_1.comment_num
	end
end

function var_0_0.updateCommentList(arg_43_0, arg_43_1)
	arg_43_0.commenList = arg_43_0.commenList or {}

	if arg_43_1 and next(arg_43_1) then
		for iter_43_0 = 1, #arg_43_1 do
			table.insert(arg_43_0.commenList, arg_43_1[iter_43_0])
		end
	end
end

function var_0_0.getSearchCoordinateList(arg_44_0, arg_44_1)
	local var_44_0 = {}
	local var_44_1, var_44_2 = arg_44_0:getPanelSize(arg_44_1)
	local var_44_3 = cc.p(math.ceil(var_44_1 / 2), math.ceil(var_44_2 / 2))

	for iter_44_0 = 0, math.ceil(var_44_1 / 2) do
		for iter_44_1 = 0, iter_44_0 do
			table.insert(var_44_0, cc.p(iter_44_0, iter_44_1))
			table.insert(var_44_0, cc.p(-iter_44_0, iter_44_1))
			table.insert(var_44_0, cc.p(iter_44_0, -iter_44_1))
			table.insert(var_44_0, cc.p(-iter_44_0, -iter_44_1))

			if iter_44_0 ~= iter_44_1 then
				table.insert(var_44_0, cc.p(iter_44_1, iter_44_0))
				table.insert(var_44_0, cc.p(-iter_44_1, iter_44_0))
				table.insert(var_44_0, cc.p(iter_44_1, -iter_44_0))
				table.insert(var_44_0, cc.p(-iter_44_1, -iter_44_0))
			end
		end
	end

	for iter_44_2 = 1, #var_44_0 do
		var_44_0[iter_44_2] = xyd.addPosition(var_44_0[iter_44_2], var_44_3)
	end

	return var_44_0
end

function var_0_0.getBedSearchCoordinate(arg_45_0, arg_45_1, arg_45_2)
	return {
		cc.p(arg_45_1 + 1, arg_45_2),
		cc.p(arg_45_1 - 1, arg_45_2),
		cc.p(arg_45_1, arg_45_2 - 1),
		cc.p(arg_45_1, arg_45_2 + 1)
	}
end

function var_0_0.getItemSearchCoordinate(arg_46_0, arg_46_1)
	local var_46_0 = {}
	local var_46_1 = arg_46_1.l
	local var_46_2 = arg_46_1.w
	local var_46_3 = cc.p(arg_46_1.coordX - 1, arg_46_1.coordY - 1)
	local var_46_4 = cc.p(arg_46_1.coordX + var_46_1, arg_46_1.coordY + var_46_2)

	for iter_46_0 = 1, var_46_1 do
		table.insert(var_46_0, xyd.addPosition(var_46_3, cc.p(iter_46_0, 0)))
		table.insert(var_46_0, xyd.subPosition(var_46_4, cc.p(iter_46_0, 0)))
	end

	for iter_46_1 = 1, var_46_2 do
		table.insert(var_46_0, xyd.addPosition(var_46_3, cc.p(0, iter_46_1)))
		table.insert(var_46_0, xyd.subPosition(var_46_4, cc.p(0, iter_46_1)))
	end

	local var_46_5, var_46_6 = arg_46_0:getPanelSize(arg_46_1.panelType)

	for iter_46_2 = #var_46_0, 1, -1 do
		if var_46_0[iter_46_2].x < 0 or var_46_0[iter_46_2].x > var_46_5 - 1 or var_46_0[iter_46_2].y < 0 or var_46_0[iter_46_2].y > var_46_6 - 1 then
			table.remove(var_46_0, iter_46_2)
		end
	end

	return var_46_0
end

function var_0_0.getSpaceInfo(arg_47_0, arg_47_1)
	if arg_47_1 < 1 then
		return
	end

	local var_47_0 = {}

	for iter_47_0 = (arg_47_1 - 1) * arg_47_0.singlePageMsgNum + 1, #arg_47_0.commenList do
		table.insert(var_47_0, arg_47_0.commenList[iter_47_0])
	end

	return var_47_0
end

function var_0_0.getCommentInfos(arg_48_0, arg_48_1)
	if arg_48_1 < 1 then
		return
	end

	local var_48_0 = {}

	if arg_48_1 == 1 then
		for iter_48_0 = 1, #arg_48_0.bestComments do
			arg_48_0.bestComments[iter_48_0].isBest = true

			table.insert(var_48_0, arg_48_0.bestComments[iter_48_0])
		end
	end

	local var_48_1 = (arg_48_1 - 1) * arg_48_0.singlePageMsgNum + 1

	if arg_48_1 > 1 then
		var_48_1 = var_48_1 - #arg_48_0.bestComments
	end

	local var_48_2 = arg_48_0.singlePageMsgNum - #var_48_0

	for iter_48_1 = var_48_1, #arg_48_0.commenList do
		if var_48_2 > 0 then
			table.insert(var_48_0, arg_48_0.commenList[iter_48_1])

			var_48_2 = var_48_2 - 1

			if var_48_2 <= 0 then
				break
			end
		end
	end

	return var_48_0
end

function var_0_0.removeComment(arg_49_0, arg_49_1)
	for iter_49_0 = 1, #arg_49_0.commenList do
		if arg_49_0.commenList[iter_49_0].comment_id == arg_49_1 then
			table.remove(arg_49_0.commenList, iter_49_0)

			break
		end
	end

	for iter_49_1 = 1, #arg_49_0.bestComments do
		if arg_49_0.bestComments[iter_49_1].comment_id == arg_49_1 then
			table.remove(arg_49_0.bestComments, iter_49_1)

			break
		end
	end

	return #arg_49_0.commenList
end

function var_0_0.getMaxCommentPage(arg_50_0)
	return math.max(1, math.ceil(arg_50_0.commentNum / arg_50_0.singlePageMsgNum))
end

function var_0_0.praiseComment(arg_51_0, arg_51_1, arg_51_2)
	local var_51_0 = arg_51_1 or {}

	var_51_0.host_id = arg_51_0.dormPlayerID

	xyd.Backend.get():request(xyd.mid.PRAISE_COMMENT, var_51_0, function(arg_52_0, arg_52_1)
		if arg_52_0 == xyd.error.OK then
			arg_51_0:handleResponse(arg_52_1)
			arg_51_0:updateCommentItemInfo(arg_52_1.comment_info or {})
		end

		if arg_51_2 then
			arg_51_2(arg_52_0, arg_52_1)
		end
	end)
end

function var_0_0.exchangeDormKey(arg_53_0, arg_53_1, arg_53_2)
	local var_53_0 = arg_53_1 or {}

	xyd.Backend.get():request(xyd.mid.EXCHANGE_DORM_KEY, var_53_0, function(arg_54_0, arg_54_1)
		if arg_54_0 == xyd.error.OK then
			arg_53_0:handleResponse(arg_54_1)

			local var_54_0 = {
				itemID = var_53_0.item_id,
				itemNum = var_53_0.item_num
			}

			dump(var_54_0)
			arg_53_0.selfPlayer:getBackpack():removeItem(var_54_0)
		end

		if arg_53_2 then
			arg_53_2(arg_54_0, arg_54_1)
		end
	end)
end

function var_0_0.startExpandHouse(arg_55_0, arg_55_1, arg_55_2)
	local var_55_0 = arg_55_1 or {}

	xyd.Backend.get():request(xyd.mid.START_EXPAND_HOUSE, var_55_0, function(arg_56_0, arg_56_1)
		if arg_56_0 == xyd.error.OK then
			arg_55_0:handleResponse(arg_56_1)
		end

		if arg_55_2 then
			arg_55_2(arg_56_0, arg_56_1)
		end
	end)
end

function var_0_0.finishExpandHouse(arg_57_0, arg_57_1, arg_57_2)
	local var_57_0 = arg_57_1 or {}

	xyd.Backend.get():request(xyd.mid.FINISH_EXPAND_HOUSE, var_57_0, function(arg_58_0, arg_58_1)
		if arg_58_0 == xyd.error.OK then
			arg_57_0:handleResponse(arg_58_1)
		end

		if arg_57_2 then
			arg_57_2(arg_58_0, arg_58_1)
		end
	end)
end

function var_0_0.updateCommentItemInfo(arg_59_0, arg_59_1)
	for iter_59_0 = 1, #arg_59_0.commenList do
		if arg_59_0.commenList[iter_59_0].comment_id == arg_59_1.comment_id then
			arg_59_0.commenList[iter_59_0] = arg_59_1

			break
		end
	end
end

function var_0_0.deleteComment(arg_60_0, arg_60_1, arg_60_2)
	local var_60_0 = arg_60_1 or {}
	local var_60_1 = var_60_0.pageNum

	var_60_0.pageNum = nil

	xyd.Backend.get():request(xyd.mid.DELETE_COMMENT, var_60_0, function(arg_61_0, arg_61_1)
		if arg_61_0 == xyd.error.OK and arg_60_0:removeComment(var_60_0.comment_id) <= var_60_1 * arg_60_0.singlePageMsgNum then
			local var_61_0 = {
				pageNum = var_60_1
			}

			arg_60_0.commentNum = arg_60_0.commentNum - 1

			arg_60_0:getDormCommentList(var_61_0, function(arg_62_0, arg_62_1)
				if arg_60_2 then
					arg_60_2(arg_62_0, arg_62_1)
				end
			end)
		end

		if arg_60_2 then
			arg_60_2(arg_61_0, arg_61_1)
		end
	end)
end

function var_0_0.removeComment(arg_63_0, arg_63_1)
	for iter_63_0 = 1, #arg_63_0.commenList do
		if arg_63_0.commenList[iter_63_0].comment_id == arg_63_1 then
			table.remove(arg_63_0.commenList, iter_63_0)

			break
		end
	end

	for iter_63_1 = 1, #arg_63_0.bestComments do
		if arg_63_0.bestComments[iter_63_1].comment_id == arg_63_1 then
			table.remove(arg_63_0.bestComments, iter_63_1)

			break
		end
	end

	return #arg_63_0.commenList
end

function var_0_0.handleResponse(arg_64_0, arg_64_1)
	if arg_64_1.house_info then
		arg_64_0:setHouseBaseInfo(arg_64_1.house_info)
	end

	if arg_64_1.best_comments then
		arg_64_0.bestComments = arg_64_1.best_comments
	end

	if arg_64_1.exp_partners then
		arg_64_0:updateExpPartners(arg_64_1.exp_partners)
	end

	if arg_64_1.changed_heroes then
		for iter_64_0, iter_64_1 in pairs(arg_64_1.changed_heroes) do
			arg_64_0.selfPlayer:getHeroByID(tonumber(iter_64_0)):setHouseInfo(iter_64_1)
		end
	end

	if arg_64_1.changed_houses then
		for iter_64_2, iter_64_3 in pairs(arg_64_1.changed_houses) do
			arg_64_0:setHouseBaseInfo(iter_64_3)
		end
	end
end

function var_0_0.updateExpPartners(arg_65_0, arg_65_1)
	local var_65_0 = xyd.tables.player:heroMaxLev(arg_65_0.selfPlayer.lev)

	for iter_65_0, iter_65_1 in pairs(arg_65_1) do
		local var_65_1 = arg_65_0.selfPlayer:getHeroByID(iter_65_1.partner_id)
		local var_65_2 = var_65_1:getLevel()

		iter_65_1.oldExp = var_65_1:getExp()
		iter_65_1.oldLev = var_65_1:getLevel()

		var_65_1:setExp(iter_65_1.exp, var_65_0)

		iter_65_1.newLev = var_65_1:getLevel()
	end
end

function var_0_0.updateBaseInfo(arg_66_0, arg_66_1, arg_66_2)
	table.insert(arg_66_0.dormBaseInfo[arg_66_1], arg_66_2)
end

function var_0_0.parseMap(arg_67_0, arg_67_1)
	local var_67_0 = {}

	for iter_67_0, iter_67_1 in pairs(arg_67_1) do
		var_67_0[iter_67_0] = {
			children = xyd.split(iter_67_1, "@") or {}
		}
	end

	return var_67_0
end

function var_0_0.getFormationMap(arg_68_0, arg_68_1)
	if not arg_68_1 then
		return {}
	end

	local var_68_0 = {}

	for iter_68_0, iter_68_1 in pairs(arg_68_1) do
		local var_68_1 = arg_68_0:resolveKey(iter_68_0)

		if not var_68_1.parent_key or arg_68_1[var_68_1.parent_key] then
			var_68_0[iter_68_0] = xyd.joinTable(iter_68_1.children, "@")
		end
	end

	return var_68_0
end

function var_0_0.onRegister(arg_69_0)
	var_0_0.super.onRegister(arg_69_0)
end

function var_0_0.resolveKey(arg_70_0, arg_70_1)
	local var_70_0 = xyd.split(arg_70_1, "|")
	local var_70_1

	for iter_70_0 = 1, #var_70_0 - 1 do
		if not var_70_1 then
			var_70_1 = var_70_0[iter_70_0]
		else
			var_70_1 = var_70_1 .. "|" .. var_70_0[iter_70_0]
		end
	end

	local var_70_2 = xyd.splitToNumber(var_70_0[#var_70_0], "#")
	local var_70_3 = {
		item_id = var_70_2[1],
		coordX = var_70_2[2] - 1,
		coordY = var_70_2[3] - 1,
		is_flipped = var_70_2[4],
		parent_key = var_70_1
	}

	var_70_3.panel_type = arg_70_0:getItemPanelType(var_70_3.item_id, var_70_3.is_flipped)

	return var_70_3
end

function var_0_0.getKeyByAttrs(arg_71_0, arg_71_1)
	local var_71_0 = ""

	if arg_71_1.parent_key then
		var_71_0 = arg_71_1.parent_key .. "|"
	end

	local var_71_1 = "#"

	return var_71_0 .. tostring(arg_71_1.item_id) .. var_71_1 .. tostring(arg_71_1.coordX + 1) .. var_71_1 .. tostring(arg_71_1.coordY + 1) .. var_71_1 .. tostring(arg_71_1.is_flipped)
end

function var_0_0.isRootItem(arg_72_0, arg_72_1)
	if not arg_72_0:resolveKey(arg_72_1).parent_key then
		return true
	end

	return false
end

function var_0_0.flipCoordinate(arg_73_0, arg_73_1, arg_73_2, arg_73_3, arg_73_4)
	local var_73_0 = arg_73_3 - arg_73_4
	local var_73_1 = arg_73_1 + var_73_0
	local var_73_2 = arg_73_2 - var_73_0

	return var_73_1, var_73_2
end

function var_0_0.moveCoordinate(arg_74_0, arg_74_1, arg_74_2, arg_74_3, arg_74_4)
	local var_74_0 = arg_74_1 + arg_74_3
	local var_74_1 = arg_74_2 + arg_74_4

	return var_74_0, var_74_1
end

function var_0_0.calculateZOrder(arg_75_0, arg_75_1, arg_75_2, arg_75_3, arg_75_4, arg_75_5)
	local var_75_0, var_75_1 = arg_75_0:getPanelSize(arg_75_5)
	local var_75_2 = 0

	if arg_75_5 == var_0_8.RightWall then
		var_75_2 = 10000
	elseif arg_75_5 == var_0_8.Floor then
		var_75_2 = 20000
	end

	local var_75_3 = math.max(arg_75_3, arg_75_4)
	local var_75_4 = 0 + var_75_0 - arg_75_1 + (var_75_1 - arg_75_2) * 100

	return math.ceil(var_75_4 + 26 + var_75_2)
end

function var_0_0.getTopAddPosition(arg_76_0, arg_76_1, arg_76_2)
	local var_76_0 = arg_76_1:getAnchorPoint()
	local var_76_1 = arg_76_1:getContentSize().width

	return cc.p(var_76_1 * var_76_0.x, arg_76_2 * var_0_3)
end

function var_0_0.getPiexlPosition(arg_77_0, arg_77_1, arg_77_2, arg_77_3)
	if arg_77_3 == var_0_8.Floor then
		return cc.p((arg_77_1 - arg_77_2) * var_0_2, (arg_77_1 + arg_77_2) * var_0_3 / 2)
	elseif arg_77_3 == var_0_8.LeftWall then
		return cc.p(arg_77_1 * var_0_2, (arg_77_2 + arg_77_1 / 2) * var_0_3)
	elseif arg_77_3 == var_0_8.RightWall then
		return cc.p(arg_77_1 * var_0_2, (arg_77_2 - arg_77_1 / 2) * var_0_3)
	end
end

function var_0_0.getPanelCoordByPiexl(arg_78_0, arg_78_1, arg_78_2, arg_78_3, arg_78_4)
	local var_78_0 = arg_78_3.panelType
	local var_78_1 = arg_78_3.basePosition

	arg_78_1, arg_78_2 = arg_78_1 - var_78_1.x, arg_78_2 - var_78_1.y

	local var_78_2, var_78_3 = arg_78_0:getCoordinateByPiexl(arg_78_1, arg_78_2, var_78_0)

	if arg_78_4 then
		var_78_2, var_78_3 = arg_78_0:getStandardCoord(var_78_2, var_78_3)
	end

	return var_78_2, var_78_3
end

function var_0_0.getWallCorrectPositon(arg_79_0)
	local var_79_0 = 30

	return cc.p(0, var_79_0)
end

function var_0_0.getPanelPositionByCoord(arg_80_0, arg_80_1, arg_80_2, arg_80_3)
	local var_80_0 = arg_80_0:getPanelBasePosition(arg_80_3)

	return arg_80_0:calculatePosition(arg_80_1, arg_80_2, arg_80_3, var_80_0)
end

function var_0_0.getPanelBasePosition(arg_81_0, arg_81_1)
	local var_81_0

	if arg_81_1 == var_0_8.Floor then
		var_81_0 = cc.p(0, -arg_81_0.houseSize.long * var_0_3)
	elseif arg_81_1 == var_0_8.LeftWall then
		var_81_0 = cc.p(-arg_81_0.houseSize.long * var_0_2, -arg_81_0.houseSize.long * var_0_3 / 2)
	elseif arg_81_1 == var_0_8.RightWall then
		var_81_0 = cc.p(0, 0)
	end

	return var_81_0
end

function var_0_0.getCoordinateByPiexl(arg_82_0, arg_82_1, arg_82_2, arg_82_3, arg_82_4)
	local var_82_0
	local var_82_1

	if arg_82_3 == var_0_8.Floor then
		var_82_0 = (2 * arg_82_2 * var_0_2 + arg_82_1 * var_0_3) / (2 * var_0_2 * var_0_3)
		var_82_1 = (2 * arg_82_2 * var_0_2 - arg_82_1 * var_0_3) / (2 * var_0_2 * var_0_3)
	elseif arg_82_3 == var_0_8.LeftWall then
		var_82_0 = arg_82_1 / var_0_2
		var_82_1 = arg_82_2 / var_0_3 - var_82_0 / 2
	elseif arg_82_3 == var_0_8.RightWall then
		var_82_0 = arg_82_1 / var_0_2
		var_82_1 = arg_82_2 / var_0_3 + var_82_0 / 2
	end

	if arg_82_4 then
		var_82_0, var_82_1 = arg_82_0:getStandardCoord(var_82_0, var_82_1)
	end

	return var_82_0, var_82_1
end

function var_0_0.getStandardCoord(arg_83_0, arg_83_1, arg_83_2)
	return math.floor(arg_83_1 + 0.5), math.floor(arg_83_2 + 0.5)
end

function var_0_0.caculateDeltaPosition(arg_84_0, arg_84_1, arg_84_2)
	return cc.p(arg_84_1 * var_0_2, arg_84_2 * var_0_3)
end

function var_0_0.calculatePosition(arg_85_0, arg_85_1, arg_85_2, arg_85_3, arg_85_4)
	local var_85_0 = arg_85_0:getPiexlPosition(arg_85_1, arg_85_2, arg_85_3)

	return cc.p(arg_85_4.x + var_85_0.x, arg_85_4.y + var_85_0.y)
end

function var_0_0.calculateAnchorPoint(arg_86_0, arg_86_1, arg_86_2, arg_86_3)
	if arg_86_3 == var_0_8.Floor then
		return cc.p(arg_86_2 / (arg_86_2 + arg_86_1), 0)
	elseif arg_86_3 == var_0_8.LeftWall then
		return cc.p(0, 0)
	elseif arg_86_3 == var_0_8.RightWall then
		return cc.p(0, arg_86_1 / 2 / (arg_86_1 / 2 + arg_86_2))
	end
end

function var_0_0.getIndexByCoordinate(arg_87_0, arg_87_1, arg_87_2, arg_87_3)
	arg_87_3 = arg_87_3 or arg_87_0.houseSize.long * 2

	return arg_87_2 * arg_87_3 + arg_87_1 + 1
end

function var_0_0.getPieceRect(arg_88_0, arg_88_1)
	return arg_88_0:createPieceRect(arg_88_1.l, arg_88_1.w, arg_88_1.panelType, var_0_9.OnGround)
end

function var_0_0.createNetRect(arg_89_0, arg_89_1)
	local var_89_0
	local var_89_1
	local var_89_2 = display.newNode()
	local var_89_3
	local var_89_4
	local var_89_5 = arg_89_0.houseSize

	if arg_89_1 == var_0_8.Floor then
		var_89_3 = "windows/dorm/room/floor_net_piece.png"
		var_89_4 = cc.p(0.5, 0)
		var_89_0, var_89_1 = var_89_5.long, var_89_5.width
	elseif arg_89_1 == var_0_8.LeftWall then
		var_89_3 = "windows/dorm/room/left_net_piece.png"
		var_89_4 = cc.p(0, 0)
		var_89_0, var_89_1 = var_89_5.long, var_89_5.height
	elseif arg_89_1 == var_0_8.RightWall then
		var_89_3 = "windows/dorm/room/right_net_piece.png"
		var_89_4 = cc.p(0, 0.3333333333333333)
		var_89_0, var_89_1 = var_89_5.width, var_89_5.height
	end

	local var_89_6 = display.newNode()

	for iter_89_0 = 0, var_89_0 - 1 do
		for iter_89_1 = 0, var_89_1 - 1 do
			local var_89_7 = xyd.AssetLoader.get():loadSprite(var_89_3)

			var_89_7:addTo(var_89_6)
			var_89_7:setAnchorPoint(var_89_4)
			var_89_7:setPosition(arg_89_0:getPiexlPosition(iter_89_0, iter_89_1, arg_89_1))
		end
	end

	return var_89_6
end

function var_0_0.getPanelItem(arg_90_0, arg_90_1, arg_90_2, arg_90_3)
	local var_90_0 = arg_90_0:getItemPanelType(arg_90_1)

	if var_90_0 == var_0_8.Floor then
		return arg_90_0:getItemByPiece(arg_90_1, arg_90_2, arg_90_3, var_90_0, 0)
	else
		local var_90_1 = display.newNode()
		local var_90_2 = arg_90_0:getItemByPiece(arg_90_1, arg_90_2, arg_90_3, var_0_8.LeftWall, 0, true)

		var_90_2:setAnchorPoint(cc.p(0, 0))
		var_90_2:addTo(var_90_1)

		local var_90_3 = arg_90_0:getItemByPiece(arg_90_1, arg_90_2, arg_90_3, var_0_8.RightWall, 1)

		var_90_3:addTo(var_90_1)
		var_90_3:setAnchorPoint(cc.p(0, 0))
		var_90_3:setPositionX(var_90_2:getContentSize().width)
		var_90_1:setContentSize(var_90_2:getContentSize().width * 2, var_90_2:getContentSize().height)

		return var_90_1
	end
end

function var_0_0.getHouseBaseWall(arg_91_0)
	local var_91_0 = arg_91_0.houseInfo
	local var_91_1 = var_0_5:house(var_91_0.table_id)

	if var_91_0.expand_lev and var_91_0.expand_lev > 0 then
		if var_91_0.expand_lev < 3 then
			var_91_1 = var_0_6:bg(var_91_0.expand_lev)
		else
			var_91_1 = var_0_6:bg(var_91_0.expand_lev)
		end
	end

	local var_91_2 = xyd.AssetLoader.get():loadSprite(var_91_1)
	local var_91_3 = arg_91_0.houseSize

	var_91_2:setAnchorPoint(cc.p(0.5, var_91_3.long / (var_91_3.long + var_91_3.height + 1)))

	return var_91_2
end

function var_0_0.getItemByPiece(arg_92_0, arg_92_1, arg_92_2, arg_92_3, arg_92_4, arg_92_5, arg_92_6)
	local var_92_0 = var_0_4:getItemSize(arg_92_1, arg_92_5)
	local var_92_1 = var_0_4:wallIcon(arg_92_1)
	local var_92_2 = var_0_4:icon(arg_92_1)
	local var_92_3 = arg_92_0:calculateAnchorPoint(var_92_0.long, var_92_0.width, arg_92_4)
	local var_92_4 = arg_92_0:calculateAnchorPoint(arg_92_2, arg_92_3, arg_92_4)
	local var_92_5 = var_0_4:expandIcons(arg_92_1)
	local var_92_6 = display.newNode()

	if arg_92_4 == var_0_8.Floor then
		var_92_6:setContentSize(arg_92_2 * var_0_2 * 2, arg_92_3 * var_0_3)
	else
		var_92_6:setContentSize(arg_92_2 * var_0_2, (arg_92_3 + arg_92_2 / 2) * var_0_3)
	end

	for iter_92_0 = 0, math.ceil(arg_92_2 / var_92_0.long) - 1 do
		for iter_92_1 = 0, math.ceil(arg_92_3 / var_92_0.width) - 1 do
			local var_92_7 = var_92_2

			if arg_92_4 == var_0_8.LeftWall and iter_92_0 == 0 or arg_92_4 == var_0_8.RightWall and iter_92_0 == math.ceil(arg_92_2 / var_92_0.long) - 1 then
				var_92_7 = var_92_1
			end

			local var_92_8 = iter_92_0 * var_92_0.long
			local var_92_9 = iter_92_1 * var_92_0.width
			local var_92_10 = xyd.AssetLoader.get():loadSprite(var_92_7)

			if arg_92_4 == var_0_8.Floor then
				if iter_92_0 > math.floor(arg_92_2 / var_92_0.long) - 1 and iter_92_1 > math.floor(arg_92_3 / var_92_0.width) - 1 then
					var_92_10 = xyd.AssetLoader.get():loadSprite(var_92_5[3])
				elseif iter_92_0 > math.floor(arg_92_2 / var_92_0.long) - 1 then
					var_92_10 = xyd.AssetLoader.get():loadSprite(var_92_5[2])
				elseif iter_92_1 > math.floor(arg_92_3 / var_92_0.width) - 1 then
					var_92_10 = xyd.AssetLoader.get():loadSprite(var_92_5[1])
				end
			end

			if arg_92_6 then
				var_92_10 = display.newFilteredSprite(var_92_7, "BRIGHTNESS", {
					-0.05
				})
			end

			var_92_10:setFlippedX(arg_92_5 == 1)
			var_92_10:setAnchorPoint(var_92_3)
			var_92_10:addTo(var_92_6)

			local var_92_11 = arg_92_0:getPiexlPosition(var_92_8, var_92_9, arg_92_4)
			local var_92_12 = var_92_6:getContentSize()
			local var_92_13 = cc.p(var_92_4.x * var_92_12.width, var_92_4.y * var_92_12.height)

			var_92_10:setPosition(xyd.addPosition(var_92_13, var_92_11))
		end
	end

	return var_92_6
end

function var_0_0.createPieceRect(arg_93_0, arg_93_1, arg_93_2, arg_93_3, arg_93_4)
	local var_93_0 = display.newNode()

	for iter_93_0 = 0, arg_93_1 - 1 do
		for iter_93_1 = 0, arg_93_2 - 1 do
			for iter_93_2, iter_93_3 in pairs(var_0_9) do
				local var_93_1 = arg_93_0:getIndexByCoordinate(iter_93_0, iter_93_1, arg_93_1)
				local var_93_2 = arg_93_0:getPieceByState(arg_93_3, iter_93_3)

				if iter_93_3 == arg_93_4 then
					var_93_2:setVisible(true)
				else
					var_93_2:setVisible(false)
				end

				if arg_93_3 == var_0_8.Floor then
					var_93_2:setAnchorPoint(cc.p(0.5, 0))
				elseif arg_93_3 == var_0_8.LeftWall then
					var_93_2:setAnchorPoint(cc.p(0, 0))
				elseif arg_93_3 == var_0_8.RightWall then
					var_93_2:setAnchorPoint(cc.p(0, 0.3333333333333333))
				end

				var_93_2:addTo(var_93_0)
				var_93_2:setPosition(arg_93_0:getPiexlPosition(iter_93_0, iter_93_1, arg_93_3))
				var_93_2:setName(tostring(var_93_1) .. "|" .. tostring(iter_93_3))
			end
		end
	end

	var_93_0.long = arg_93_1
	var_93_0.width = arg_93_2
	var_93_0.panelType = arg_93_3

	return var_93_0
end

function var_0_0.getPieceByState(arg_94_0, arg_94_1, arg_94_2)
	local var_94_0

	if arg_94_2 == var_0_9.OnGround then
		if arg_94_1 == var_0_8.Floor then
			var_94_0 = "windows/dorm/room/floor_piece_green.png"
		elseif arg_94_1 == var_0_8.LeftWall then
			var_94_0 = "windows/dorm/room/wall_piece_green_left.png"
		elseif arg_94_1 == var_0_8.RightWall then
			var_94_0 = "windows/dorm/room/wall_piece_green_right.png"
		end
	elseif arg_94_2 == var_0_9.OnItem then
		if arg_94_1 == var_0_8.Floor then
			var_94_0 = "windows/dorm/room/floor_piece_blue.png"
		elseif arg_94_1 == var_0_8.LeftWall then
			var_94_0 = "windows/dorm/room/wall_piece_blue_left.png"
		elseif arg_94_1 == var_0_8.RightWall then
			var_94_0 = "windows/dorm/room/wall_piece_blue_right.png"
		end
	elseif arg_94_2 == var_0_9.Warmming then
		if arg_94_1 == var_0_8.Floor then
			var_94_0 = "windows/dorm/room/floor_piece_red.png"
		elseif arg_94_1 == var_0_8.LeftWall then
			var_94_0 = "windows/dorm/room/wall_piece_red_left.png"
		elseif arg_94_1 == var_0_8.RightWall then
			var_94_0 = "windows/dorm/room/wall_piece_red_right.png"
		end
	end

	return (xyd.AssetLoader.get():loadSprite(var_94_0))
end

function var_0_0.setPieceRectState(arg_95_0, arg_95_1, arg_95_2)
	local var_95_0 = arg_95_2[1]
	local var_95_1 = true

	for iter_95_0 = 1, arg_95_1.long * arg_95_1.width do
		if arg_95_2[iter_95_0] ~= var_95_0 then
			var_95_0 = nil
		end

		if not arg_95_2[iter_95_0] or arg_95_2[iter_95_0] == -1 then
			var_95_1 = false
		end
	end

	for iter_95_1 = 0, arg_95_1.long - 1 do
		for iter_95_2 = 0, arg_95_1.width - 1 do
			local var_95_2 = arg_95_0:getIndexByCoordinate(iter_95_1, iter_95_2, arg_95_1.long)

			for iter_95_3, iter_95_4 in pairs(var_0_9) do
				local var_95_3 = tostring(var_95_2) .. "|" .. tostring(iter_95_4)

				arg_95_1:getChildByName(var_95_3):setVisible(false)

				if not var_95_0 and var_95_1 then
					if iter_95_4 == var_0_9.Warmming then
						arg_95_1:getChildByName(var_95_3):setVisible(true)
					end
				elseif arg_95_2[var_95_2] == -1 and iter_95_4 == var_0_9.Warmming or arg_95_2[var_95_2] and arg_95_2[var_95_2] ~= -1 and iter_95_4 == var_0_9.OnItem or not arg_95_2[var_95_2] and iter_95_4 == var_0_9.OnGround then
					arg_95_1:getChildByName(var_95_3):setVisible(true)
				end
			end
		end
	end
end

function var_0_0.getPanelTypeByKey(arg_96_0, arg_96_1)
	if not arg_96_1 then
		return
	end

	local var_96_0 = arg_96_0:resolveKey(arg_96_1)

	return arg_96_0:getItemPanelType(var_96_0.item_id, var_96_0.is_flipped)
end

function var_0_0.getItemPanelType(arg_97_0, arg_97_1, arg_97_2)
	local var_97_0 = var_0_4:placeWall(arg_97_1)
	local var_97_1 = var_97_0[1]

	if var_97_1 ~= var_0_8.Floor and arg_97_2 == 1 and xyd.isInTable(var_97_0, var_0_8.RightWall) then
		var_97_1 = var_0_8.RightWall
	elseif var_97_1 ~= var_0_8.Floor then
		var_97_1 = var_0_8.LeftWall
	end

	return var_97_1 or var_0_8.Floor
end

function var_0_0.getPanelSize(arg_98_0, arg_98_1)
	local var_98_0 = arg_98_0.houseSize

	if arg_98_1 == var_0_8.Floor then
		return var_98_0.long, var_98_0.width
	elseif arg_98_1 == var_0_8.LeftWall then
		return var_98_0.long, var_98_0.height
	elseif arg_98_1 == var_0_8.RightWall then
		return var_98_0.width, var_98_0.height
	end
end

function var_0_0.getItemMaxCoord(arg_99_0, arg_99_1)
	local var_99_0, var_99_1 = arg_99_0:getPanelSize(arg_99_1.panelType)

	return var_99_0 - arg_99_1.l, var_99_1 - arg_99_1.w
end

function var_0_0.isSelfDorm(arg_100_0)
	return not arg_100_0.dormPlayerID or arg_100_0.dormPlayerID == arg_100_0.selfPlayer.playerID
end

function var_0_0.checkDormOpen(arg_101_0, arg_101_1)
	if arg_101_0:isSelfDorm() then
		return arg_101_0.selfPlayer:isFuncOpen(arg_101_1)
	else
		return arg_101_0:checkOtherDormOpen(arg_101_1)
	end
end

function var_0_0.checkOtherDormOpen(arg_102_0, arg_102_1)
	for iter_102_0, iter_102_1 in pairs(arg_102_0.openFunctions) do
		if iter_102_1 == arg_102_1 then
			return true
		end
	end

	return false
end

function var_0_0.getHousePiexlSize(arg_103_0)
	return {
		width = arg_103_0.houseSize.long * var_0_2 * 2,
		height = (arg_103_0.houseSize.long + arg_103_0.houseSize.height) * var_0_3
	}
end

function var_0_0.toHeroHouse(arg_104_0, arg_104_1)
	local var_104_0 = arg_104_1:getHouseInfo()

	if not var_104_0 or not var_104_0.house_id or var_104_0.house_id <= 0 then
		return
	end

	if not arg_104_0.dormBaseInfo or not arg_104_0:isSelfDorm() then
		arg_104_0:getHouseList(nil, function(arg_105_0, arg_105_1)
			if arg_105_0 == xyd.error.OK then
				local var_105_0 = arg_104_0:getHouseBaseInfo(var_104_0.house_id)

				arg_104_0:toHouse(var_105_0)
			end
		end)
	else
		local var_104_1 = arg_104_0:getHouseBaseInfo(var_104_0.house_id)

		arg_104_0:toHouse(var_104_1)
	end
end

function var_0_0.isCanExpand(arg_106_0, arg_106_1)
	if var_0_5:maintype(arg_106_1.table_id) == xyd.DormType.VILLA and (not arg_106_1.expand_lev or arg_106_1.expand_lev < 3) then
		return true
	end

	return false
end

return var_0_0
