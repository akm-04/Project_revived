local var_0_0 = class("StoryData")

function var_0_0.get()
	if var_0_0.INSTANCE == nil then
		var_0_0.INSTANCE = var_0_0.new()
	end

	return var_0_0.INSTANCE
end

function var_0_0.ctor(arg_2_0)
	arg_2_0.FIRST_STAGE = 101001
	arg_2_0.SECOND_STAGE = 101002
	arg_2_0.FIRST_MAP_LAST_STAGE = 101007
	arg_2_0.HUOLIAOHUA_ID = 10006002
	arg_2_0.heroGuideStep = 0
	arg_2_0.storyID_ = 0
	arg_2_0.storyState_ = 0
	arg_2_0.guideID_ = 0
	arg_2_0.stageID_ = 0
	arg_2_0.funcIDs_ = {}

	xyd.EventDispatcher.get():addEventListener(xyd.event.BATTLE_ENDED, function(arg_3_0)
		local var_3_0 = arg_3_0.instance_type
		local var_3_1 = arg_3_0.instance_id
		local var_3_2 = xyd.tables.stage:lev(var_3_1)

		if var_3_0 == xyd.InstanceType.INSTANCE and arg_2_0.stageID_ == nil or var_3_1 > arg_2_0.stageID_ and arg_3_0.is_win and var_3_2 == 1 then
			arg_2_0.stageID_ = var_3_1
		end
	end)
end

function var_0_0.onDataFromBackend(arg_4_0, arg_4_1)
	arg_4_0.storyID_ = arg_4_1.story_id
	arg_4_0.storyState_ = arg_4_1.story_state
	arg_4_0.guideID_ = arg_4_1.guide_id
end

function var_0_0.updateDataFromStorage(arg_5_0)
	local var_5_0 = xyd.db.storyGuideData.storyID
	local var_5_1 = xyd.db.storyGuideData.guideID
	local var_5_2 = xyd.db.storyGuideData.funcIDs

	if var_5_0 > arg_5_0.storyID_ then
		arg_5_0.storyID_ = var_5_0
	end

	if var_5_1 > arg_5_0.guideID_ then
		arg_5_0.guideID_ = var_5_1
	end

	if var_5_2 ~= nil and next(var_5_2) ~= nil then
		arg_5_0.funcIDs_ = var_5_2
	end
end

function var_0_0.reset(arg_6_0)
	arg_6_0.storyID_ = 0
	arg_6_0.storyState_ = 0
	arg_6_0.guideID_ = 0
	arg_6_0.stageID_ = 0
	arg_6_0.funcIDs_ = {}
end

function var_0_0.isMapOpen(arg_7_0, arg_7_1)
	if arg_7_0.storyID_ < xyd.tables.map:openStoryID(arg_7_1 - arg_7_1 % 1000) then
		return false
	else
		return true
	end
end

function var_0_0.setStoryID(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if arg_8_0.storyID_ == nil or arg_8_1 > arg_8_0.storyID_ or arg_8_1 == arg_8_0.storyID_ and arg_8_2 > arg_8_0.storyState_ or arg_8_3 then
		arg_8_0.storyID_ = arg_8_1
		arg_8_0.storyState_ = arg_8_2
		xyd.db.storyGuideData.storyID = arg_8_1
	end
end

function var_0_0.persist(arg_9_0, arg_9_1)
	xyd.Backend.get():request(xyd.mid.SAVE_STORY, {
		story_id = arg_9_0.storyID_,
		story_state = arg_9_0.storyState_,
		guide_id = arg_9_1 or arg_9_0.guideID_
	}, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK and arg_9_0.guideID_ == xyd.GuideStoryType.GUIDE_END then
			xyd.fbTracking(xyd.FBInAppEventName.TUTORIAL_COMPLETION)
		end
	end, nil, nil, false)
	xyd.db.storyGuideData:persist()
end

function var_0_0.getStoryID(arg_11_0)
	return arg_11_0.storyID_
end

function var_0_0.getStoryState(arg_12_0)
	return arg_12_0.storyState_
end

function var_0_0.setGuideID(arg_13_0, arg_13_1, arg_13_2)
	if arg_13_0.guideID_ == nil or arg_13_1 > arg_13_0.guideID_ or arg_13_2 then
		arg_13_0.guideID_ = arg_13_1
		xyd.db.storyGuideData.guideID = arg_13_1
	end
end

function var_0_0.getGuideID(arg_14_0)
	return arg_14_0.guideID_ or 0
end

function var_0_0.setStageID(arg_15_0, arg_15_1)
	if arg_15_0.stageID_ == nil or arg_15_1 > arg_15_0.stageID_ then
		arg_15_0.stageID_ = arg_15_1
	end
end

function var_0_0.getStageID(arg_16_0)
	return arg_16_0.stageID_
end

function var_0_0.setFuncIDs(arg_17_0, arg_17_1)
	arg_17_0.funcIDs_ = arg_17_1
	xyd.db.storyGuideData.funcIDs = arg_17_1
end

function var_0_0.getFuncIDs(arg_18_0)
	return arg_18_0.funcIDs_ or {}
end

function var_0_0.removeFuncID(arg_19_0, arg_19_1)
	local var_19_0 = false

	for iter_19_0 = 1, #arg_19_0.funcIDs_ do
		if arg_19_0.funcIDs_[iter_19_0] == arg_19_1 then
			table.remove(arg_19_0.funcIDs_, iter_19_0)

			var_19_0 = true

			break
		end
	end

	if var_19_0 then
		xyd.db.storyGuideData:persist()
	end
end

return var_0_0
