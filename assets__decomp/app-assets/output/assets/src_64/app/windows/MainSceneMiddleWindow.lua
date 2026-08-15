local var_0_0 = class("MainSceneMiddleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = 0.2
local var_0_3 = 1
local var_0_4 = 2
local var_0_5 = 3
local var_0_6 = cc.Director:getInstance():getVisibleSize()
local var_0_7 = (var_0_6.width - xyd.STAGE_WIDTH) / 2
local var_0_8 = (var_0_6.height - xyd.STAGE_HEIGHT) / 2
local var_0_9 = {
	{
		nodeName = "map",
		windowName = "map_window",
		points = {
			{
				x = 894,
				y = 123
			},
			{
				x = 952,
				y = 356
			},
			{
				x = 1219,
				y = 376
			},
			{
				x = 1206,
				y = 65
			}
		},
		clickAnchor = {
			0.49,
			0.53
		},
		actionAnchor = cc.p(1202.19, 213.18),
		actionScale = {
			[0] = {
				x = 0.5,
				y = 1
			},
			{
				x = 1,
				y = 1
			},
			{
				x = 0.98,
				y = 0.98
			},
			{
				x = 1,
				y = 1
			}
		},
		actionTime = {
			[0] = 0.23,
			0.1,
			0.1,
			0.16
		}
	},
	{
		nodeName = "pk",
		windowName = "sub_arena",
		funcId = xyd.FunctionID.ID_ARENA,
		points = {
			{
				x = 765,
				y = 155
			},
			{
				x = 773,
				y = 355
			},
			{
				x = 931,
				y = 368
			},
			{
				x = 875,
				y = 140
			}
		},
		clickAnchor = {
			0.51,
			0.51
		},
		actionAnchor = cc.p(843.07, 357.1),
		actionScale = {
			[0] = {
				x = 1,
				y = 0.25
			},
			{
				x = 1.03,
				y = 1.03
			},
			{
				x = 0.98,
				y = 0.98
			},
			{
				x = 1,
				y = 1
			}
		},
		actionTime = {
			[0] = 0.06,
			0.1,
			0.13,
			0.16
		}
	},
	{
		nodeName = "summon",
		windowName = "summon",
		points = {
			{
				x = 797,
				y = 383
			},
			{
				x = 793,
				y = 571
			},
			{
				x = 903,
				y = 606
			},
			{
				x = 885,
				y = 393
			}
		},
		clickAnchor = {
			0.62,
			0.51
		},
		actionAnchor = cc.p(789.69, 486.22),
		actionScale = {
			[0] = {
				x = 0.5,
				y = 1
			},
			{
				x = 1.08,
				y = 1.08
			},
			{
				x = 0.98,
				y = 0.98
			},
			{
				x = 1,
				y = 1
			}
		},
		actionTime = {
			[0] = 0.1,
			0.1,
			0.1,
			0.2
		}
	},
	{
		nodeName = "test",
		windowName = "sub_exam",
		funcId = xyd.FunctionID.ID_THROW_SANDBAG,
		points = {
			{
				x = 915,
				y = 492
			},
			{
				x = 923,
				y = 599
			},
			{
				x = 1085,
				y = 652
			},
			{
				x = 1097,
				y = 537
			}
		},
		clickAnchor = {
			0.46,
			0.51
		},
		actionAnchor = cc.p(997.75, 618.03),
		actionScale = {
			[0] = {
				x = 1,
				y = 0.5
			},
			{
				x = 1.03,
				y = 1.03
			},
			{
				x = 0.98,
				y = 0.98
			},
			{
				x = 1,
				y = 1
			}
		},
		actionTime = {
			[0] = 0.13,
			0.1,
			0.1,
			0.16
		}
	},
	{
		nodeName = "college",
		windowName = "sub_college",
		points = {
			{
				x = 904,
				y = 375
			},
			{
				x = 911,
				y = 477
			},
			{
				x = 1094,
				y = 517
			},
			{
				x = 1108,
				y = 400
			}
		},
		clickAnchor = {
			0.5,
			0.5
		},
		actionAnchor = cc.p(993.71, 389.38),
		actionScale = {
			[0] = {
				x = 1,
				y = 0.5
			},
			{
				x = 1.03,
				y = 1.03
			},
			{
				x = 0.98,
				y = 0.98
			},
			{
				x = 1,
				y = 1
			}
		},
		actionTime = {
			[0] = 0.06,
			0.06,
			0.1,
			0.16
		}
	},
	{
		nodeName = "research",
		windowName = "sub_research",
		funcId = xyd.FunctionID.ID_FUMO,
		points = {
			{
				x = 1118,
				y = 525
			},
			{
				x = 1105,
				y = 630
			},
			{
				x = 1236,
				y = 653
			},
			{
				x = 1261,
				y = 558
			}
		},
		clickAnchor = {
			0.5,
			0.5
		},
		actionAnchor = cc.p(1250.61, 566.92),
		actionScale = {
			[0] = {
				x = 0.5,
				y = 0.5
			},
			{
				x = 1.03,
				y = 1.03
			},
			{
				x = 0.98,
				y = 0.98
			},
			{
				x = 1,
				y = 1
			}
		},
		actionTime = {
			[0] = 0.23,
			0.1,
			0.1,
			0.13
		}
	},
	{
		nodeName = "rise",
		windowName = "sub_dev",
		funcId = xyd.FunctionID.ID_TREASURE,
		points = {
			{
				x = 1127,
				y = 384
			},
			{
				x = 1114,
				y = 507
			},
			{
				x = 1259,
				y = 538
			},
			{
				x = 1256,
				y = 398
			}
		},
		clickAnchor = {
			0.5,
			0.5
		},
		actionAnchor = cc.p(1124.18, 499.67),
		actionScale = {
			[0] = {
				x = 0.5,
				y = 0.5
			},
			{
				x = 1.03,
				y = 1.03
			},
			{
				x = 0.98,
				y = 0.98
			},
			{
				x = 1,
				y = 1
			}
		},
		actionTime = {
			[0] = 0.26,
			0.06,
			0.1,
			0.13
		}
	}
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.GuideHands = {}
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.redMarks = {}
	arg_2_0.redMarks[xyd.RedMarks.SUMMON] = arg_2_0:nodeByName("red_point_machine")
	arg_2_0.redMarks[xyd.RedMarks.PK] = arg_2_0:nodeByName("red_point_pk")
	arg_2_0.redMarks[xyd.RedMarks.TOWER] = arg_2_0:nodeByName("red_point_rise")
	arg_2_0.redMarks[xyd.RedMarks.TEST] = arg_2_0:nodeByName("red_point_test")
	arg_2_0.redMarks[xyd.RedMarks.YANJIUSUO] = arg_2_0:nodeByName("red_point_research")
	arg_2_0.redMarks[xyd.RedMarks.COLLEGE] = arg_2_0:nodeByName("red_point_college")

	for iter_2_0, iter_2_1 in pairs(arg_2_0.redMarks) do
		iter_2_1:setVisible(false)
	end

	for iter_2_2, iter_2_3 in pairs(arg_2_0.GuideHands) do
		for iter_2_4, iter_2_5 in pairs(iter_2_3.nodes) do
			iter_2_5:setVisible(true)
		end
	end

	for iter_2_6 = 1, #var_0_9 do
		local var_2_0 = var_0_9[iter_2_6]

		arg_2_0:nodeByName(var_2_0.nodeName):setTouchEnabled(true)
		arg_2_0:nodeByName(var_2_0.nodeName):setTouchSwallowEnabled(false)
		arg_2_0:nodeByName(var_2_0.nodeName):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
			if arg_3_0.name == "began" then
				if not arg_2_0:isEventPossibleOnNode(var_2_0.points, arg_3_0.x - var_0_7, arg_3_0.y - var_0_8) then
					return
				end

				arg_2_0:nodeByName(var_2_0.nodeName):setScale(0.9)

				return true
			elseif arg_3_0.name == "moved" then
				if arg_2_0:isEventPossibleOnNode(var_2_0.points, arg_3_0.x - var_0_7, arg_3_0.y - var_0_8) then
					return
				end

				arg_2_0:nodeByName(var_2_0.nodeName):setScale(1)
			elseif arg_3_0.name == "ended" then
				arg_2_0:nodeByName(var_2_0.nodeName):setScale(1)

				if not arg_2_0:isEventPossibleOnNode(var_2_0.points, arg_3_0.x - var_0_7, arg_3_0.y - var_0_8) then
					return
				end

				xyd.playButtonSound()

				if var_2_0.windowName == nil then
					return
				end

				if xyd.WindowManager.get():isWindowOpen("guide") then
					xyd.WindowManager.get():closeWindow("guide")
				end

				if var_2_0.funcId and arg_2_0.selfPlayer:isFuncOpen(var_2_0.funcId) ~= true and var_2_0.noTip == nil then
					local var_3_0
					local var_3_1 = xyd.tables.functionOpen
					local var_3_2 = xyd.tables.translation
					local var_3_3 = string.format(var_3_2:translation("FUNCTION_OPEN_TIP_LEVEL"), var_3_1:level(var_2_0.funcId))

					if xyd.WindowManager.get():getWindow("toast") ~= nil then
						xyd.WindowManager.get():closeWindow("toast")
					end

					xyd.WindowManager.get():openWindow("toast", {
						message = var_3_3
					})

					return true
				end

				if var_2_0.nodeName == "summon" then
					local var_3_4 = xyd.StoryData.get():getGuideID()

					if var_3_4 < xyd.GuideStoryType.GUIDE_SUMMON_FREE_TWO then
						xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SUMMON_FREE_ONE, true)
					elseif var_3_4 < xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_TWO then
						xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_ONE, true)
					end

					xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):loadSummonInfo(nil, function()
						xyd.sendGudieBtnClick("summon")
						xyd.WindowManager.get():openWindow("summon")

						if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_SUMMON_FREE_TWO then
							arg_2_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_SUMMON)
						end
					end, true)
				elseif var_2_0.nodeName == "map" then
					arg_2_0.selfPlayer:loadWorldMap(function(arg_5_0)
						if arg_5_0 ~= xyd.error.OK then
							return
						end

						arg_2_0.guild:loadGuildMap(function(arg_6_0)
							if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_CAMPAIGN_START then
								arg_2_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN)
							end

							if arg_6_0 == xyd.error.OK then
								local var_6_0 = {}

								var_6_0.chapter_type = 1
								var_6_0.newFuncIDs = newFuncIDs

								xyd.WindowManager.get():openWindow(var_2_0.windowName, var_6_0)
							else
								xyd.WindowManager.get():openWindow(var_2_0.windowName, {
									chapter_type = 1,
									newFuncIDs = newFuncIDs
								})
							end
						end)
					end)
				else
					xyd.WindowManager.get():openWindow(var_2_0.windowName)
				end

				local var_3_5

				;(function(arg_7_0)
					local var_7_0 = arg_2_0.GuideHands[arg_7_0]

					if var_7_0 ~= nil then
						if var_7_0.nodes and next(var_7_0.nodes) then
							for iter_7_0, iter_7_1 in pairs(var_7_0.nodes) do
								arg_2_0:removeChild(iter_7_1)
							end
						end

						var_3_5 = var_7_0.funcIDs

						if var_7_0.funcIDs and next(var_7_0.funcIDs) then
							for iter_7_2, iter_7_3 in pairs(var_7_0.funcIDs) do
								xyd.StoryData.get():removeFuncID(iter_7_3)
							end
						end

						arg_2_0.GuideHands[arg_7_0] = nil
					end
				end)(var_2_0.nodeName)
			end
		end)
	end

	arg_2_0:onEnterAction()
end

function var_0_0.isEventPossibleOnNode(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = arg_8_1[1]
	local var_8_1 = arg_8_1[2]
	local var_8_2 = arg_8_1[3]
	local var_8_3 = arg_8_1[4]
	local var_8_4 = (var_8_1.x - var_8_0.x) * (arg_8_3 - var_8_0.y) - (var_8_1.y - var_8_0.y) * (arg_8_2 - var_8_0.x)
	local var_8_5 = (var_8_2.x - var_8_1.x) * (arg_8_3 - var_8_1.y) - (var_8_2.y - var_8_1.y) * (arg_8_2 - var_8_1.x)
	local var_8_6 = (var_8_3.x - var_8_2.x) * (arg_8_3 - var_8_2.y) - (var_8_3.y - var_8_2.y) * (arg_8_2 - var_8_2.x)
	local var_8_7 = (var_8_0.x - var_8_3.x) * (arg_8_3 - var_8_3.y) - (var_8_0.y - var_8_3.y) * (arg_8_2 - var_8_3.x)

	if var_8_4 >= 0 and var_8_5 >= 0 and var_8_6 >= 0 and var_8_7 >= 0 or var_8_4 <= 0 and var_8_5 <= 0 and var_8_6 <= 0 and var_8_7 <= 0 then
		return true
	else
		return false
	end
end

function var_0_0.functionClickRecord(arg_9_0, arg_9_1)
	local var_9_0

	if arg_9_1 == "summon" then
		var_9_0 = xyd.FunctionClick.SUMMON
	elseif arg_9_1 == "shop" then
		var_9_0 = xyd.FunctionClick.SHOP
	elseif arg_9_1 == "forge" or arg_9_1 == "forge_out" then
		var_9_0 = xyd.FunctionClick.FORGE
	elseif arg_9_1 == "act_centre" then
		var_9_0 = xyd.FunctionClick.EVENT_CENTRE
	elseif arg_9_1 == "library" then
		var_9_0 = xyd.FunctionClick.LIBRARY
	elseif arg_9_1 == "arena" or arg_9_1 == "arena_out" then
		var_9_0 = xyd.FunctionClick.ARENA
	elseif arg_9_1 == "peak_arena" then
		var_9_0 = xyd.FunctionClick.PEAK_ARENA
	elseif arg_9_1 == "region_arena" then
		var_9_0 = xyd.FunctionClick.REGION_ARENA
	elseif arg_9_1 == "march" or arg_9_1 == "march_out" then
		var_9_0 = xyd.FunctionClick.MARCH
	elseif arg_9_1 == "sky" then
		var_9_0 = xyd.FunctionClick.SKY
	elseif arg_9_1 == "cloud_city" then
		var_9_0 = xyd.FunctionClick.CLOUD_CITY
	elseif arg_9_1 == "treasure" or arg_9_1 == "treasure_in" then
		var_9_0 = xyd.FunctionClick.TREASURE
	elseif arg_9_1 == "times" then
		var_9_0 = xyd.FunctionClick.TIMES
	elseif arg_9_1 == "trial" then
		var_9_0 = xyd.FunctionClick.TRIAL
	elseif arg_9_1 == "prophecy" then
		var_9_0 = xyd.FunctionClick.PROPHECY
	elseif arg_9_1 == "illusion" then
		var_9_0 = xyd.FunctionClick.ILLUSION
	elseif arg_9_1 == "incubus" then
		var_9_0 = xyd.FunctionClick.INCUBUS
	elseif arg_9_1 == "conquer_school" then
		var_9_0 = xyd.FunctionClick.CONQUER_SCHOOL
	elseif arg_9_1 == "practice_btn" then
		var_9_0 = xyd.FunctionClick.PRACTICE
	elseif arg_9_1 == "academy_arena" then
		var_9_0 = xyd.FunctionClick.ACADEMY_ARENA
	elseif arg_9_1 == "inscription_btn" then
		var_9_0 = xyd.FunctionClick.INSCRIPTION
	elseif arg_9_1 == "course" then
		var_9_0 = xyd.FunctionClick.COURSE
	elseif arg_9_1 == "time_travel" then
		var_9_0 = xyd.FunctionClick.TIME_TRAVEL
	elseif arg_9_1 == "conquer_school" then
		var_9_0 = xyd.FunctionClick.CONQUER_SCHOOL
	elseif arg_9_1 == "memories_of_school" then
		var_9_0 = xyd.FunctionClick.MEMORIES_OF_SCHOOL
	elseif arg_9_1 == "occult" then
		var_9_0 = xyd.FunctionClick.OCCULT
	elseif arg_9_1 == "furniture_factory" then
		var_9_0 = xyd.FunctionClick.FURNITURE_FACTORY
	elseif arg_9_1 == "dorm" then
		var_9_0 = xyd.FunctionClick.DORM
	elseif arg_9_1 == "super_partner" then
		var_9_0 = xyd.FunctionClick.SUPER_PARTNER
	end

	if var_9_0 then
		arg_9_0.selfPlayer:sendFunctionClick(var_9_0)
	end
end

function var_0_0.didOpen(arg_10_0)
	if arg_10_0.selfPlayer.arenaRedMarkEnable then
		arg_10_0.redMarks[xyd.RedMarks.ARENA] = true
	else
		arg_10_0.redMarks[xyd.RedMarks.ARENA] = false
	end

	if arg_10_0.selfPlayer.peakArenaRedMarkEnable then
		arg_10_0.redMarks[xyd.RedMarks.PEAK] = true
	else
		arg_10_0.redMarks[xyd.RedMarks.PEAK] = false
	end

	arg_10_0:checkPKRedMark()
	arg_10_0:checkRedMark(xyd.CheckMiddleRed.TREASURE)
	arg_10_0.selfPlayer:loadSummonInfo(nil, function()
		local var_11_0 = xyd.WindowManager.get():getWindow("main_scene_middle")

		if var_11_0 then
			var_11_0:checkRedMark(xyd.CheckMiddleRed.SUMMON)
		end
	end, true)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_10_0):addEventListener(xyd.event.CHECK_MIDDLE_RED_MARK, function(arg_12_0)
		local var_12_0 = xyd.WindowManager.get():getWindow("main_scene_middle")

		if var_12_0 then
			var_12_0:checkRedMark(arg_12_0.params)
		end
	end)

	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_PET_ONE then
		arg_10_0:playGuide(var_0_3)
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_10_0):addEventListener(xyd.event.PET_GUIDE_TO_CAMPAIGN, function(arg_13_0)
		arg_10_0:playGuide(var_0_3)
	end)
	arg_10_0:checkRedMark(xyd.CheckMiddleRed.LIBRARY)
	arg_10_0:checkRedMark(xyd.CheckMiddleRed.COURSE)
	arg_10_0:checkRedMark(xyd.CheckMiddleRed.SUPER_PARTNER)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_10_0):addEventListener(xyd.event.MAIN_SCENE_ACTION_START, function(arg_14_0)
		arg_10_0:onEnterAction(arg_14_0.params and arg_14_0.params.quickAction)
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_10_0):addEventListener(xyd.event.MAIN_SCENE_ACTION_END, function(arg_15_0)
		arg_10_0:onEnterActionEnd()
	end)
	xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION):loadIllusionInfos()
end

function var_0_0.checkRedMark(arg_16_0, arg_16_1)
	local var_16_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE)
	local var_16_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)

	if arg_16_1 == xyd.CheckMiddleRed.SUMMON then
		local var_16_2 = false
		local var_16_3 = false

		if arg_16_0.selfPlayer:getFreeManaNum() and arg_16_0.selfPlayer:getNextFreeManaSummonTime() and arg_16_0.selfPlayer:getFreeManaNum() > 0 and arg_16_0.selfPlayer:getNextFreeManaSummonTime() == 0 then
			var_16_2 = true
		end

		if arg_16_0.selfPlayer:getNextFreeCrystalSummonTime() == 0 then
			var_16_3 = true
		end

		if var_16_2 or var_16_3 then
			arg_16_0.redMarks[xyd.RedMarks.SUMMON]:setVisible(true)
		else
			arg_16_0.redMarks[xyd.RedMarks.SUMMON]:setVisible(false)
		end
	elseif arg_16_1 == xyd.CheckMiddleRed.SKY then
		if xyd.WindowManager.get():getWindow("pet_campaign") == nil and var_16_1.has_red == true then
			var_16_1.begin_sweep_time = 0
			arg_16_0.redMarks[xyd.RedMarks.SKY] = true
		else
			var_16_1.has_red = nil
			arg_16_0.redMarks[xyd.RedMarks.SKY] = false
		end

		arg_16_0:checkTowerRedMark()
	elseif arg_16_1 == xyd.CheckMiddleRed.TREASURE then
		if var_16_0.has_red == true then
			arg_16_0.redMarks[xyd.RedMarks.TREASURE] = true
		else
			arg_16_0.redMarks[xyd.RedMarks.TREASURE] = false
		end

		arg_16_0:checkTowerRedMark()
	elseif arg_16_1 == xyd.CheckMiddleRed.ARENA then
		arg_16_0.redMarks[xyd.RedMarks.ARENA] = true

		arg_16_0:checkPKRedMark()
	elseif arg_16_1 == xyd.CheckMiddleRed.ARENA_CANCEL then
		arg_16_0.redMarks[xyd.RedMarks.ARENA] = false

		arg_16_0:checkPKRedMark()
	elseif arg_16_1 == xyd.CheckMiddleRed.PEAK then
		arg_16_0.redMarks[xyd.RedMarks.PEAK] = true

		arg_16_0:checkPKRedMark()
	elseif arg_16_1 == xyd.CheckMiddleRed.PEAK_CANCEL then
		arg_16_0.redMarks[xyd.RedMarks.PEAK] = false

		arg_16_0:checkPKRedMark()
	elseif arg_16_1 == xyd.CheckMiddleRed.EVENT_CENTRE then
		arg_16_0.redMarks[xyd.RedMarks.EVENT_CENTRE] = true

		arg_16_0:checkYanjiusuoRedMark()
	elseif arg_16_1 == xyd.CheckMiddleRed.EVENT_CENTRE_CANCEL then
		arg_16_0.redMarks[xyd.RedMarks.EVENT_CENTRE] = false

		arg_16_0:checkYanjiusuoRedMark()
	elseif arg_16_1 == xyd.CheckMiddleRed.LIBRARY then
		arg_16_0:checkLibraryRedMark()
		arg_16_0:checkCollegeRedMark()
	elseif arg_16_1 == xyd.CheckMiddleRed.COURSE then
		arg_16_0:checkCourseRedMark()
		arg_16_0:checkCollegeRedMark()
	elseif arg_16_1 == xyd.CheckMiddleRed.ILLUSION then
		local var_16_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)
		local var_16_5 = xyd.ServerTime.get():getSecondsOfDay()

		if var_16_4.isOpen and var_16_4.times == var_16_4.initTimes and var_16_4.buyPre == 0 and var_16_5 > xyd.tables.misc.dungenBossStart and var_16_5 < xyd.tables.misc.dungenBossStop then
			arg_16_0.redMarks[xyd.RedMarks.TEST]:setVisible(true)
		else
			arg_16_0.redMarks[xyd.RedMarks.TEST]:setVisible(false)
		end
	elseif arg_16_1 == xyd.CheckMiddleRed.PRACTICE then
		arg_16_0:checkPracticeRedMark()
		arg_16_0:checkYanjiusuoRedMark()
	elseif arg_16_1 == xyd.CheckMiddleRed.SUPER_PARTNER then
		arg_16_0:checkSuperPartnerRedMark()
		arg_16_0:checkYanjiusuoRedMark()
	elseif arg_16_1 == xyd.CheckMiddleRed.OCCULT then
		-- block empty
	elseif arg_16_1 == xyd.CheckMiddleRed.WHITE_ALBUM then
		arg_16_0:checkWhiteAlbumRedMark()
		arg_16_0:checkCollegeRedMark()
	end
end

function var_0_0.checkPKRedMark(arg_17_0)
	if arg_17_0.redMarks[xyd.RedMarks.ARENA] or arg_17_0.redMarks[xyd.RedMarks.PEAK] then
		arg_17_0.redMarks[xyd.RedMarks.PK]:setVisible(true)
	else
		arg_17_0.redMarks[xyd.RedMarks.PK]:setVisible(false)
	end
end

function var_0_0.checkLibraryRedMark(arg_18_0)
	if arg_18_0.library:isLibraryRedPointShow() then
		arg_18_0.redMarks[xyd.RedMarks.LIBRARY] = true
	else
		arg_18_0.redMarks[xyd.RedMarks.LIBRARY] = false
	end
end

function var_0_0.checkCourseRedMark(arg_19_0)
	if arg_19_0.course:isCourseRedPointShow() then
		arg_19_0.redMarks[xyd.RedMarks.COURSE] = true
	else
		arg_19_0.redMarks[xyd.RedMarks.COURSE] = false
	end
end

function var_0_0.checkCollegeRedMark(arg_20_0)
	if arg_20_0.redMarks[xyd.RedMarks.LIBRARY] or arg_20_0.redMarks[xyd.RedMarks.COURSE] or arg_20_0.redMarks[xyd.RedMarks.WHITE_ALBUM] then
		arg_20_0.redMarks[xyd.RedMarks.COLLEGE]:setVisible(true)
	else
		arg_20_0.redMarks[xyd.RedMarks.COLLEGE]:setVisible(false)
	end
end

function var_0_0.checkPracticeRedMark(arg_21_0)
	if arg_21_0.selfPlayer:checkPracticeRedMark() then
		arg_21_0.redMarks[xyd.RedMarks.PRACTICE] = true
	else
		arg_21_0.redMarks[xyd.RedMarks.PRACTICE] = false
	end
end

function var_0_0.checkSuperPartnerRedMark(arg_22_0)
	if arg_22_0.selfPlayer:checkSuperPartnerRedMark() then
		arg_22_0.redMarks[xyd.RedMarks.SUPER_PARTNER] = true
	else
		arg_22_0.redMarks[xyd.RedMarks.SUPER_PARTNER] = false
	end
end

function var_0_0.checkYanjiusuoRedMark(arg_23_0)
	if arg_23_0.redMarks[xyd.RedMarks.PRACTICE] or arg_23_0.redMarks[xyd.RedMarks.SUPER_PARTNER] or arg_23_0.redMarks[xyd.RedMarks.EVENT_CENTRE] then
		arg_23_0.redMarks[xyd.RedMarks.YANJIUSUO]:setVisible(true)
	else
		arg_23_0.redMarks[xyd.RedMarks.YANJIUSUO]:setVisible(false)
	end
end

function var_0_0.checkTowerRedMark(arg_24_0)
	if arg_24_0.redMarks[xyd.RedMarks.TREASURE] or arg_24_0.redMarks[xyd.RedMarks.SKY] then
		arg_24_0.redMarks[xyd.RedMarks.TOWER]:setVisible(true)
	else
		arg_24_0.redMarks[xyd.RedMarks.TOWER]:setVisible(false)
	end
end

function var_0_0.checkWhiteAlbumRedMark(arg_25_0, ...)
	if arg_25_0.selfPlayer.albumNormalRedP or arg_25_0.selfPlayer.albumSpecialRedP then
		arg_25_0.redMarks[xyd.RedMarks.WHITE_ALBUM] = true
	else
		arg_25_0.redMarks[xyd.RedMarks.WHITE_ALBUM] = false
	end
end

function var_0_0.checkGuideIntoWar(arg_26_0)
	local var_26_0 = xyd.StoryData.get():getGuideID()

	if var_26_0 <= xyd.GuideStoryType.GUIDE_CAMPAIGN_END or var_26_0 == xyd.GuideStoryType.GUIDE_SUPER_BATTLE_START or var_26_0 >= xyd.GuideStoryType.GUIDE_FIGHT_2_START and var_26_0 < xyd.GuideStoryType.GUIDE_FIGHT_2_END or var_26_0 >= xyd.GuideStoryType.GUIDE_LEVUP_FOUR and var_26_0 <= xyd.GuideStoryType.GUIDE_LEVUP_END or var_26_0 >= xyd.GuideStoryType.ACTIVITY_SIX and var_26_0 <= xyd.GuideStoryType.ACTIVITY_END or var_26_0 >= xyd.GuideStoryType.GUIDE_FIGHT_4_START and var_26_0 <= xyd.GuideStoryType.GUIDE_FIGHT_4_END or var_26_0 >= xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_SIX and var_26_0 <= xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_END or var_26_0 >= xyd.GuideStoryType.GUIDE_FIGHT_5_START and var_26_0 < xyd.GuideStoryType.GUIDE_FIGHT_5_END or var_26_0 >= xyd.GuideStoryType.GUIDE_FIGHT_3_START and var_26_0 <= xyd.GuideStoryType.GUIDE_FIGHT_3_END or var_26_0 >= xyd.GuideStoryType.GUIDE_MISSION_START and var_26_0 <= xyd.GuideStoryType.GUIDE_MISSION_TWO or var_26_0 >= xyd.GuideStoryType.GUIDE_FIGHT_6_START and var_26_0 < xyd.GuideStoryType.GUIDE_FIGHT_6_END then
		return true
	end

	return false
end

function var_0_0.setIDBeforeGuideWnd(arg_27_0)
	local var_27_0 = xyd.StoryData.get():getGuideID()

	if var_27_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_START, true)
	elseif var_27_0 >= xyd.GuideStoryType.GUIDE_FIGHT_2_START and var_27_0 < xyd.GuideStoryType.GUIDE_FIGHT_2_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_START, true)
	elseif var_27_0 >= xyd.GuideStoryType.ACTIVITY_SIX and var_27_0 <= xyd.GuideStoryType.ACTIVITY_END then
		arg_27_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_4_1)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_START, true)
	elseif var_27_0 >= xyd.GuideStoryType.GUIDE_FIGHT_4_START and var_27_0 <= xyd.GuideStoryType.GUIDE_FIGHT_4_END then
		arg_27_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_4_1)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_START, true)
	elseif var_27_0 >= xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_SIX and var_27_0 <= xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_END then
		arg_27_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_5_1)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_5_START, true)
	elseif var_27_0 >= xyd.GuideStoryType.GUIDE_FIGHT_5_START and var_27_0 < xyd.GuideStoryType.GUIDE_FIGHT_5_END then
		arg_27_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_5_1)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_5_START, true)
	elseif var_27_0 >= xyd.GuideStoryType.GUIDE_FIGHT_3_START and var_27_0 <= xyd.GuideStoryType.GUIDE_FIGHT_3_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_START, true)
	elseif var_27_0 >= xyd.GuideStoryType.GUIDE_FIGHT_6_START and var_27_0 < xyd.GuideStoryType.GUIDE_FIGHT_6_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_6_ONE, true)
	elseif var_27_0 >= xyd.GuideStoryType.GUIDE_FIGHT_3_END and var_27_0 <= xyd.GuideStoryType.GUIDE_MISSION_TWO then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_START, true)
	end
end

function var_0_0.playGuide(arg_28_0, arg_28_1)
	if xyd.WindowManager.get():getWindow("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	if arg_28_1 == nil then
		if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_SUMMON_END and (not arg_28_0.selfPlayer:getHeroByID(2) or not arg_28_0.selfPlayer:getHeroByID(3)) then
			xyd.WindowManager.get():openWindow("guide")

			local var_28_0 = xyd.WindowManager.get():getWindow("guide")

			var_28_0:addNode()
			var_28_0:setStencil(110, 188, 848, 477, 0, {
				main_scene = true,
				position = {
					700,
					200
				}
			})
		elseif arg_28_0:checkGuideIntoWar() then
			xyd.WindowManager.get():closeAllWindowsForGuide()
			arg_28_0:setIDBeforeGuideWnd()
			xyd.WindowManager.get():openWindow("guide")

			local var_28_1 = xyd.WindowManager.get():getWindow("guide")

			var_28_1:addNode()
			var_28_1:setStencil(290, 290, 1066, 220, 0, {
				main_scene = true,
				position = {
					700,
					200
				},
				effect_pos = cc.p(100, -50)
			})
		end
	elseif arg_28_1 == var_0_3 then
		xyd.WindowManager.get():openWindow("guide")

		local var_28_2 = xyd.WindowManager.get():getWindow("guide")

		var_28_2:addNode()
		var_28_2:setStencil(150, 150, 1189.5, 459.5, 0, {
			main_scene = true,
			position = {
				700,
				200
			}
		})
	elseif arg_28_1 == var_0_4 then
		xyd.WindowManager.get():openWindow("guide")

		local var_28_3 = xyd.WindowManager.get():getWindow("guide")

		var_28_3:addNode()
		var_28_3:setStencil(150, 150, 1189.5, 459.5, 0, {
			main_scene = true,
			position = {
				700,
				200
			}
		})
	end
end

function var_0_0.playFunctionGuide(arg_29_0, arg_29_1)
	local var_29_0
	local var_29_1 = 0
	local var_29_2 = 40
	local var_29_3 = 0
	local var_29_4 = 0
	local var_29_5 = false
	local var_29_6 = xyd.tables.translation
	local var_29_7 = var_29_6:translation("OPEN_FUNCTION")

	local function var_29_8(arg_30_0, arg_30_1, arg_30_2, arg_30_3, arg_30_4, arg_30_5, arg_30_6, arg_30_7)
		if arg_30_1 then
			local var_30_0 = arg_29_0:nodeByName(arg_30_1)
			local var_30_1 = var_30_0:getPositionX()
			local var_30_2 = var_30_0:getPositionY()
			local var_30_3 = var_30_0:getContentSize().width
			local var_30_4 = var_30_0:getContentSize().height
			local var_30_5 = display.newNode()

			var_30_5:setPosition(var_30_1, var_30_2)

			local var_30_6 = import("app.windows.GuideHand").new()

			var_30_5:addChild(var_30_6)
			var_30_6:setPosition(0, 0)

			local var_30_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/function/function_open.csb")

			var_30_5:addChild(var_30_7)
			var_30_7:setPosition(arg_30_2, arg_30_3)
			var_30_7:getChildByName("tip_container"):getChildByName("text_open"):setString(arg_30_5)
			var_30_7:getChildByName("tip_container"):setFlippedY(arg_30_7)
			var_30_7:getChildByName("tip_container"):getChildByName("text_open"):setFlippedY(arg_30_7)

			local var_30_8 = var_30_7:getChildByName("tip_container"):getChildByName("tip_arrow")

			if arg_30_4 ~= 0 then
				local var_30_9 = cc.p(var_30_8:getPosition())

				var_30_8:setPosition(cc.p(var_30_9.x + arg_30_4, var_30_9.y))
			end

			if arg_30_6 ~= 0 then
				var_30_8:setSkewY(arg_30_6)
			end

			if arg_29_0.GuideHands[arg_30_1] == nil then
				arg_29_0:addChild(var_30_5)

				arg_29_0.GuideHands[arg_30_1] = {
					nodes = {
						var_30_5
					},
					funcIDs = {
						arg_30_0
					}
				}
			else
				table.insert(arg_29_0.GuideHands[arg_30_1].nodes, var_30_5)
				table.insert(arg_29_0.GuideHands[arg_30_1].funcIDs, arg_30_0)
			end
		end
	end

	if arg_29_1 == xyd.FunctionID.ID_ARENA then
		var_29_0 = "pk"
		var_29_1 = -70
		var_29_3 = 30
		var_29_4 = 40
		var_29_7 = var_29_7 .. var_29_6:translation("ARENA_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_SUPER_BATTLE then
		var_29_0 = "map"
		var_29_2 = 60
		var_29_7 = var_29_7 .. var_29_6:translation("ARENA_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_MARCH then
		var_29_0 = "rise"
		var_29_1 = -70
		var_29_3 = 30
		var_29_4 = -40
		var_29_7 = var_29_7 .. var_29_6:translation("MARCH_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_FUMO then
		var_29_0 = "research"
		var_29_1 = -80
		var_29_2 = -40
		var_29_3 = 30
		var_29_4 = 40
		var_29_5 = true
		var_29_7 = var_29_7 .. var_29_6:translation("ZHUJIAN_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_PRACTICE then
		var_29_0 = "research"
		var_29_1 = -80
		var_29_2 = -40
		var_29_3 = 30
		var_29_4 = 40
		var_29_5 = true
		var_29_7 = var_29_7 .. var_29_6:translation("YANJIUSUO_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_TREASURE then
		var_29_0 = "rise"
		var_29_1 = -100
		var_29_3 = 30
		var_29_4 = 40
		var_29_7 = var_29_7 .. var_29_6:translation("TREASURE_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_PEAK_ARENA then
		var_29_0 = "pk"
		var_29_7 = var_29_7 .. var_29_6:translation("PEAK_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_REGION_ARENA then
		var_29_0 = "pk"
		var_29_7 = var_29_7 .. var_29_6:translation("REGION_ARENA_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_ACT_CENTRE then
		var_29_0 = "college"
		var_29_7 = var_29_7 .. var_29_6:translation("EVENT_CENTRE")
	elseif arg_29_1 == xyd.FunctionID.ID_EXERCISE then
		var_29_0 = "test"
		var_29_1 = -70
		var_29_2 = -40
		var_29_3 = 30
		var_29_4 = 40
		var_29_5 = true
		var_29_7 = var_29_7 .. var_29_6:translation("EXERCISE_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_CAVE then
		var_29_0 = "test"
		var_29_1 = -70
		var_29_2 = -40
		var_29_3 = 30
		var_29_4 = 40
		var_29_5 = true
		var_29_7 = var_29_7 .. var_29_6:translation("TRIAL_TIME_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_ILLUSION then
		var_29_0 = "test"
		var_29_1 = -70
		var_29_2 = -40
		var_29_3 = 30
		var_29_4 = 40
		var_29_5 = true
		var_29_7 = var_29_7 .. var_29_6:translation("ILLUSION_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_OCCULT then
		var_29_0 = "test"
		var_29_1 = -70
		var_29_2 = -40
		var_29_3 = 30
		var_29_4 = 40
		var_29_5 = true
		var_29_7 = var_29_7 .. var_29_6:translation("OCCULT_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_CLOUD_CITY then
		var_29_0 = "rise"
		var_29_1 = -100
		var_29_3 = 30
		var_29_4 = 40
		var_29_7 = var_29_7 .. var_29_6:translation("CLOUD_CITY_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_CONQUER_SCHOOL then
		var_29_0 = "rise"
		var_29_1 = -100
		var_29_3 = 30
		var_29_4 = 40
		var_29_7 = var_29_7 .. var_29_6:translation("CONQUER_SCHOOL_TXT")
	elseif arg_29_1 == xyd.FunctionID.ID_SUPER_PARTNER then
		var_29_0 = "research"
		var_29_1 = -80
		var_29_2 = -40
		var_29_3 = 30
		var_29_4 = 40
		var_29_5 = true
		var_29_7 = var_29_7 .. var_29_6:translation("TAITAN_TEXT_12")
	elseif arg_29_1 == xyd.FunctionID.ID_COURSE then
		var_29_0 = "college"
		var_29_1 = -70
		var_29_3 = 30
		var_29_4 = 40
		var_29_7 = var_29_7 .. var_29_6:translation("COURSE_STUDY_TEXT")
	elseif arg_29_1 == xyd.FunctionID.ID_FURNITURE_FACTORY then
		var_29_0 = "college"
		var_29_1 = -70
		var_29_3 = 30
		var_29_4 = 40
		var_29_7 = var_29_7 .. var_29_6:translation("FURNITURE_FACTORY_TEXT")
	elseif arg_29_1 == xyd.FunctionID.ID_DORM then
		var_29_0 = "college"
		var_29_1 = -70
		var_29_3 = 30
		var_29_4 = 40
		var_29_7 = var_29_7 .. var_29_6:translation("DORM_TEXT")
	end

	var_29_8(arg_29_1, var_29_0, var_29_1, var_29_2, var_29_4, var_29_7, var_29_3, var_29_5)
end

function var_0_0.playWindowMove(arg_31_0, arg_31_1)
	local var_31_0 = arg_31_0:nodeByName("background")

	if arg_31_1 then
		arg_31_0.oldPosition = cc.p(var_31_0:getPosition())

		var_31_0:runAction(cc.MoveTo:create(0.5, cc.p(xyd.STAGE_WIDTH, arg_31_0.oldPosition.y)))
	else
		var_31_0:runAction(cc.MoveTo:create(0.5, cc.p(arg_31_0.oldPosition.x, arg_31_0.oldPosition.y)))
	end
end

function var_0_0.onEnterAction(arg_32_0, arg_32_1)
	for iter_32_0 = 1, #var_0_9 do
		local var_32_0 = var_0_9[iter_32_0]
		local var_32_1 = arg_32_0:nodeByName(var_32_0.nodeName)

		var_32_1:setVisible(false)
		var_32_1:setTouchEnabled(false)
		var_32_1:stopAllActions()
		xyd.changeAnchorPointByWorldSpacePoint(var_32_1, arg_32_0:convertToWorldSpace(var_32_0.actionAnchor))
		var_32_1:setScale(var_32_0.actionScale[0].x, var_32_0.actionScale[0].y)
		var_32_1:runAction(cc.Sequence:create({
			cc.DelayTime:create(var_32_0.actionTime[0]),
			cc.CallFunc:create(function()
				var_32_1:setVisible(true)
			end),
			cc.ScaleTo:create(var_32_0.actionTime[1], var_32_0.actionScale[1].x, var_32_0.actionScale[1].y),
			cc.ScaleTo:create(var_32_0.actionTime[2], var_32_0.actionScale[2].x, var_32_0.actionScale[2].y),
			cc.ScaleTo:create(var_32_0.actionTime[3], var_32_0.actionScale[3].x, var_32_0.actionScale[3].y),
			cc.CallFunc:create(function()
				xyd.changeAnchorPoint(var_32_1, var_32_0.clickAnchor[1], var_32_0.clickAnchor[2])

				if var_32_0.nodeName == "map" and arg_32_1 then
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.MAIN_SCENE_ACTION_END
					})
				end
			end)
		}))
	end

	for iter_32_1, iter_32_2 in pairs(arg_32_0.GuideHands) do
		for iter_32_3, iter_32_4 in pairs(iter_32_2.nodes) do
			if iter_32_4 and not tolua.isnull(iter_32_4) then
				iter_32_4:setVisible(false)
			end
		end
	end
end

function var_0_0.onEnterActionEnd(arg_35_0)
	for iter_35_0 = 1, #var_0_9 do
		arg_35_0:nodeByName(var_0_9[iter_35_0].nodeName):setTouchEnabled(true)
	end

	for iter_35_1, iter_35_2 in pairs(arg_35_0.GuideHands) do
		for iter_35_3, iter_35_4 in pairs(iter_35_2.nodes) do
			if iter_35_4 and not tolua.isnull(iter_35_4) then
				iter_35_4:setVisible(true)
			end
		end
	end
end

return var_0_0
