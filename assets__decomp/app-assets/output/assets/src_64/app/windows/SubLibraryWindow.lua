local var_0_0 = class("SubLibraryWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.functionOpen
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()

	local var_2_0 = arg_2_0:nodeByName("adventure_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ADVENTURE) then
		xyd.nodeEventSample(var_2_0, {}, function()
			xyd.WindowManager.get():openWindow("adventure_event")
		end)
	else
		arg_2_0:addLock(var_2_0, xyd.FunctionID.ID_ADVENTURE)
	end

	xyd.nodeEventSample(arg_2_0:nodeByName("hero_handbook_node"), {}, function()
		arg_2_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.HERO_TUJIAN)
		xyd.WindowManager.get():openWindow("tujian_hero")
	end)

	local var_2_1 = arg_2_0:nodeByName("pet_handbook_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) then
		xyd.nodeEventSample(var_2_1, {}, function()
			xyd.WindowManager.get():openWindow("tujian_pet")
		end)
	else
		arg_2_0:addLock(var_2_1, xyd.FunctionID.ID_PET)
	end

	xyd.nodeEventSample(arg_2_0:nodeByName("equip_handbook_node"), {}, function()
		arg_2_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.HERO_TUJIAN)
		xyd.WindowManager.get():openWindow("tujian")
	end)
	xyd.nodeEventSample(arg_2_0:nodeByName("memory_node"), {}, function()
		xyd.WindowManager.get():openWindow("memory_collect")
	end)
	xyd.nodeEventSample(arg_2_0:nodeByName("story_node"), {}, function()
		arg_2_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.SCHOOL_STORY)
		xyd.WindowManager.get():openWindow("school_story")
	end)
	xyd.nodeEventSample(arg_2_0:nodeByName("stroll_node"), {}, function()
		xyd.WindowManager.get():openWindow("library_bg")
	end)

	arg_2_0.storyRedP = arg_2_0:nodeByName("story_red_p")
	arg_2_0.memoryRedP = arg_2_0:nodeByName("memory_red_p")

	arg_2_0:updateRedMarkShow()
	arg_2_0:updateMemoryCollectRedMark()

	local var_2_2 = "skeletons/dynamic_card/caozhijuexing/caozhijuexingdongtai"

	xyd.EffectLoader.new(var_2_2, 3, 0.77, {
		x = 210,
		y = -170
	}):addTo(arg_2_0:nodeByName("background"))
end

function var_0_0.addLock(arg_10_0, arg_10_1, arg_10_2)
	arg_10_1:runActionOnce(cc.TintBy:create(0, -100, -100, -100))

	local var_10_0 = xyd.AssetLoader.get():loadSprite("windows/common/lock.png")

	var_10_0:addTo(arg_10_1)

	local var_10_1 = arg_10_1:getContentSize()

	var_10_0:setPosition(var_10_1.width / 2, var_10_1.height / 2)
	xyd.nodeEventSample(arg_10_1, {}, function()
		local var_11_0 = var_0_1:tip(arg_10_2)

		dump(arg_10_2)
		dump(var_11_0)

		if var_11_0 == "" then
			var_11_0 = var_0_2:translation("FUNCTION_OPEN_TIP_OTHER")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_11_0
		})
	end)
end

function var_0_0.updateRedMarkShow(arg_12_0)
	if arg_12_0.storyRedP then
		arg_12_0.storyRedP:setVisible(arg_12_0.library:isSchoolStoryRedPointShow() or false)
	end
end

function var_0_0.updateMemoryCollectRedMark(arg_13_0)
	if arg_13_0.memoryRedP then
		arg_13_0.memoryRedP:setVisible(arg_13_0.library:isMemoryCollectRedPointShow() or false)
	end
end

return var_0_0
