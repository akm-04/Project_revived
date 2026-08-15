local var_0_0 = class("Achievement", import(".BaseModel"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.achieveList = {}
	arg_1_0.unfinishList = {}
	arg_1_0.baseInfo = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadAchievementInfo(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_ACHIEVEMENT_INFO, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK and arg_4_1 then
			arg_3_0.achieveList = arg_4_1.achieve_list
			arg_3_0.baseInfo = arg_4_1.base_info

			arg_3_0:deleteHideAchievements()
			arg_3_0:initialUnfinishList()
		end

		if arg_3_2 then
			arg_3_2(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.deleteHideAchievements(arg_5_0)
	for iter_5_0 = #arg_5_0.achieveList, 1, -1 do
		if xyd.tables.achievement:isHide(arg_5_0.achieveList[iter_5_0].achieve_id) == 1 then
			table.remove(arg_5_0.achieveList, iter_5_0)
		end
	end
end

function var_0_0.handleNewAchievementNotice(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1

	if not var_6_0 then
		return
	end

	arg_6_0.baseInfo.point_level = var_6_0.point_level
	arg_6_0.baseInfo.total_points = var_6_0.total_points
	arg_6_0.baseInfo.rank = var_6_0.rank
	arg_6_0.isHasNewNotice = true

	local var_6_1 = {
		achieve_id = var_6_0.achieve_id,
		complete_time = var_6_0.complete_time,
		progress = var_6_0.progress
	}
	local var_6_2 = false

	for iter_6_0 = 1, #arg_6_0.achieveList do
		if arg_6_0.achieveList[iter_6_0].achieve_id == var_6_1.achieve_id then
			table.remove(arg_6_0.achieveList, iter_6_0)
			table.insert(arg_6_0.achieveList, 1, var_6_1)

			local var_6_3 = true

			break
		end
	end

	if not arg_6_0.isHasAchieveId then
		table.insert(arg_6_0.achieveList, 1, var_6_1)
	end

	arg_6_0:initialUnfinishList()

	local var_6_4 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_6_4 and not tolua.isnull(var_6_4) then
		var_6_4:updateAchievementRedMark(true)
	end

	local var_6_5 = xyd.WindowManager.get():getWindow("achievement")

	if var_6_5 and not tolua.isnull(var_6_5) then
		var_6_5:refreshWindow()
	end
end

function var_0_0.initialUnfinishList(arg_7_0)
	arg_7_0.unfinishList = {}

	for iter_7_0, iter_7_1 in pairs(arg_7_0.achieveList) do
		if arg_7_0:getLatestIndex(iter_7_1.complete_time) == 0 then
			table.insert(arg_7_0.unfinishList, iter_7_1)
		end
	end
end

function var_0_0.getLatestIndex(arg_8_0, arg_8_1)
	for iter_8_0 = #arg_8_1, 1, -1 do
		if arg_8_1[iter_8_0] ~= 0 then
			return iter_8_0
		end
	end

	return 0
end

function var_0_0.getLatestIndexById(arg_9_0, arg_9_1)
	for iter_9_0 = 1, #arg_9_0.achieveList do
		if arg_9_0.achieveList[iter_9_0].achieve_id == arg_9_1 then
			return arg_9_0:getLatestIndex(arg_9_0.achieveList[iter_9_0].complete_time)
		end
	end

	return 1
end

function var_0_0.getShowAwardLev(arg_10_0)
	for iter_10_0 = 2, #arg_10_0.baseInfo.award_status do
		if arg_10_0.baseInfo.award_status[iter_10_0] ~= -1 or xyd.tables.achievementLevel:isMaxCanAwardLev(iter_10_0) then
			return iter_10_0
		end
	end
end

function var_0_0.getCanAwardLev(arg_11_0)
	if not arg_11_0.baseInfo or not arg_11_0.baseInfo.point_level or arg_11_0.baseInfo.point_level < 2 then
		return 0
	end

	for iter_11_0 = 2, arg_11_0.baseInfo.point_level do
		local var_11_0 = xyd.tables.achievementLevel:items(iter_11_0)

		if arg_11_0.baseInfo.award_status[iter_11_0] == 1 and #var_11_0 >= 1 and var_11_0[1] > 0 then
			return iter_11_0
		end
	end

	return 0
end

function var_0_0.getAchievementAward(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_ACHIEVEMENT_AWARD, var_12_0, function(arg_13_0, arg_13_1)
		if arg_12_2 then
			arg_12_2(arg_13_0, arg_13_1)
		end
	end)
end

function var_0_0.checkAchievement(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_1 or {}

	xyd.Backend.get():request(xyd.mid.CHECK_ACHIEVEMENT, var_14_0, function(arg_15_0, arg_15_1)
		if arg_14_2 then
			arg_14_2(arg_15_0, arg_15_1)
		end
	end)
end

function var_0_0.getOfflineInfo(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_OFFLINE_INFO, var_16_0, function(arg_17_0, arg_17_1)
		if arg_16_2 then
			arg_16_2(arg_17_0, arg_17_1)
		end
	end)
end

function var_0_0.setItemClip(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = xyd.SpriteLoader.new(arg_18_2, nil, nil, xyd.DefaultImageType.SKILL_ICON)
	local var_18_1
	local var_18_2 = arg_18_1:getContentSize().width
	local var_18_3 = arg_18_1:getContentSize().height
	local var_18_4 = xyd.AssetLoader:get():loadSprite("windows/playerwindow/touxiang_clip.png")

	var_18_4:setPosition(var_18_2 / 2, var_18_3 / 2)
	var_18_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_18_4:setScale(var_18_3 / (var_18_4:getHeight() - 196))

	local var_18_5 = cc.ClippingNode:create()

	var_18_5:setStencil(var_18_4)
	var_18_5:setInverted(true)
	var_18_5:setAlphaThreshold(0)
	arg_18_1:addChild(var_18_5)
	var_18_5:addChild(var_18_0)
	var_18_0:setPosition(var_18_2 / 2, var_18_3 / 2)
	var_18_0:setAnchorPoint(cc.p(0.5, 0.5))

	local var_18_6 = var_18_3 / var_18_0:getHeight()

	var_18_0:setScale(var_18_6)
	var_18_5:setLocalZOrder(-1)
end

function var_0_0.createFinishedTimeString(arg_19_0, arg_19_1)
	return os.date("%Y.%m.%d", arg_19_1) .. var_0_2:translation("WILL_GET")
end

function var_0_0.addEffect(arg_20_0, arg_20_1, arg_20_2, arg_20_3, arg_20_4)
	local var_20_0 = arg_20_1 .. ".json"
	local var_20_1 = arg_20_1 .. ".atlas"
	local var_20_2 = var_0_1.new(var_20_0, var_20_1, 1)

	var_20_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_20_2:addTo(arg_20_2)
	var_20_2:setPosition(arg_20_3)
	var_20_2:setName("iconEffect")
	var_20_2:play(nil, true)

	if arg_20_4 then
		var_20_2:setScale(arg_20_4)
	end
end

return var_0_0
