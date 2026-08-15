local var_0_0 = import("framework.scheduler")
local var_0_1 = class("StoryWindow", import("app.common.ui.BaseWindow"))
local var_0_2 = xyd.tables.misc
local var_0_3 = 1
local var_0_4 = 2
local var_0_5 = 3
local var_0_6 = 1
local var_0_7 = 2
local var_0_8 = 3
local var_0_9 = require("framework.scheduler")

function var_0_1.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_1.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.battleID_ = arg_1_2.battle_id
	arg_1_0.storyID_ = arg_1_2.story_id
	arg_1_0.storyState_ = arg_1_2.story_state
	arg_1_0.storyPoint_ = 0
	arg_1_0.isBeforeStory = arg_1_2.is_before_story
	arg_1_0.isGuideStory = arg_1_2.is_guide_story
	arg_1_0.isAssistBattle = arg_1_2.is_assist
	arg_1_0.isChocolate = arg_1_2.is_chocolate_story

	if not arg_1_0.isGuideStory then
		arg_1_0.storyData_ = import("app.common.tables.StoryDataTable").new(arg_1_0.storyID_)
		arg_1_0.playingIndex_ = 0
	else
		arg_1_0.storyData_ = import("app.common.tables.GuideDataTable").new(arg_1_0.storyID_)
		arg_1_0.playingIndex_ = 0
	end

	if arg_1_2.callback then
		arg_1_0.callback = arg_1_2.callback
	end
end

function var_0_1.checkFileExist(arg_2_0)
	return true
end

function var_0_1.willOpen(arg_3_0, arg_3_1)
	var_0_1.super.willOpen(arg_3_0, arg_3_1)

	if arg_3_0:checkFileExist() then
		arg_3_0:hideOtherWindows()
		arg_3_0:layout()
	else
		xyd.WindowManager.get():closeWindow("story")
	end
end

function var_0_1.didOpen(arg_4_0, arg_4_1)
	var_0_1.super.didOpen(arg_4_0, arg_4_1)

	if arg_4_0:checkFileExist() then
		arg_4_0:nextPlay()
	else
		xyd.WindowManager.get():closeWindow("story")
	end
end

function var_0_1.hideOtherWindows(arg_5_0)
	local var_5_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleBottomWnd)
	local var_5_1 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleTopWnd)

	if var_5_1 then
		var_5_1:setVisible(false)
	end

	if var_5_0 then
		var_5_0:setVisible(false)
	end
end

function var_0_1.layout(arg_6_0)
	arg_6_0.maskColor = cc.c4f(0.5, 0.5, 0.5, 1)

	local var_6_0 = display.newNode()

	var_6_0:setName("role")
	var_6_0:size(arg_6_0:getContentSize())
	var_6_0:setAnchorPoint(cc.p(0, 0))
	var_6_0:setPosition(cc.p(0, 0))
	var_6_0:addTo(arg_6_0, -1)

	arg_6_0.roleLayer_ = var_6_0
	arg_6_0.leftIcon_ = ""
	arg_6_0.rightIcon_ = ""
	arg_6_0.middleIcon_ = ""

	arg_6_0:setTouchSwallowEnabled(false)

	arg_6_0.touchLayer_ = var_6_0:clone()

	arg_6_0.touchLayer_:addTo(arg_6_0)
	arg_6_0.touchLayer_:setTouchEnabled(true)
	arg_6_0.touchLayer_:setTouchSwallowEnabled(false)
	arg_6_0.touchLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "ended" and not arg_6_0.shaking_ and not arg_6_0:isAnimation() then
			arg_6_0:nextPlay()
		end

		return true
	end)
end

function var_0_1.isAnimation(arg_8_0)
	return arg_8_0.isAnimationLeft or arg_8_0.isAnimationRight or arg_8_0.isAnimationMiddle
end

function var_0_1.nextPlay(arg_9_0)
	if arg_9_0.timer then
		var_0_9.unscheduleGlobal(arg_9_0.timer)

		arg_9_0.timer = nil
	end

	if arg_9_0.functions == xyd.StoryFunctionType.EditPlayerName then
		arg_9_0:editPlayerName()
	elseif arg_9_0.functions == xyd.StoryFunctionType.StoryPoint and not arg_9_0.endBattleStory_ then
		arg_9_0:enterStoryPoint()
	end

	arg_9_0.functions = 0

	if arg_9_0.playingIndex_ >= arg_9_0.storyData_:getDialogNum() then
		arg_9_0:onEnded()

		return
	end

	arg_9_0.playingIndex_ = arg_9_0.playingIndex_ + 1

	arg_9_0:update()

	if arg_9_0.playingIndex_ > arg_9_0.storyData_:getDialogNum() then
		return
	end

	local var_9_0 = arg_9_0.storyData_:time(arg_9_0.playingIndex_)

	if var_9_0 > 0 then
		arg_9_0.timer = var_0_9.scheduleGlobal(handler(arg_9_0, arg_9_0.nextPlay), var_9_0)
	end
end

function var_0_1.update(arg_10_0)
	if arg_10_0.playingIndex_ > arg_10_0.storyData_:getDialogNum() or arg_10_0.shaking_ then
		return
	end

	local var_10_0 = clone(arg_10_0.storyData_:text(arg_10_0.playingIndex_))
	local var_10_1 = clone(arg_10_0.storyData_:name(arg_10_0.playingIndex_))
	local var_10_2 = arg_10_0.storyData_:iconL(arg_10_0.playingIndex_)
	local var_10_3 = arg_10_0.storyData_:iconR(arg_10_0.playingIndex_)
	local var_10_4 = arg_10_0.storyData_:iconM(arg_10_0.playingIndex_)
	local var_10_5 = arg_10_0.storyData_:position(arg_10_0.playingIndex_)
	local var_10_6 = arg_10_0.storyData_:trends(arg_10_0.playingIndex_)
	local var_10_7 = arg_10_0.storyData_:face(arg_10_0.playingIndex_)

	arg_10_0.functions = arg_10_0.storyData_:functions(arg_10_0.playingIndex_)

	if var_10_1:find("=playername=") then
		var_10_1 = arg_10_0:getPlayerName()
	end

	if var_10_0:find("=playername=") then
		local var_10_8 = clone(var_10_0)
		local var_10_9 = string.split(var_10_8, "=playername=")
		local var_10_10 = ""

		for iter_10_0 = 1, #var_10_9 do
			if iter_10_0 > 1 then
				var_10_10 = var_10_10 .. arg_10_0:getPlayerName() .. var_10_9[iter_10_0]
			else
				var_10_10 = var_10_10 .. var_10_9[iter_10_0]
			end
		end

		var_10_0 = var_10_10
	end

	arg_10_0:nodeByName("text"):setString(var_10_0)

	local var_10_11 = var_0_2:getValue("story_slide_time")
	local var_10_12 = var_0_2:getValue("story_slide_distance")
	local var_10_13 = var_0_2:getValue("story_fade_time")
	local var_10_14 = cc.MoveBy:create(var_10_11, cc.p(-var_10_12, 0))
	local var_10_15 = cc.MoveBy:create(var_10_11, cc.p(var_10_12, 0))
	local var_10_16 = cc.FadeIn:create(var_10_11)
	local var_10_17 = cc.FadeOut:create(var_10_11)
	local var_10_18 = cc.FadeIn:create(var_10_13)
	local var_10_19 = cc.FadeOut:create(var_10_13)
	local var_10_20 = xyd.tables.misc.storyCardDistance
	local var_10_21 = arg_10_0:getWidth() / 2

	if arg_10_0.leftIcon_ ~= var_10_2 then
		if arg_10_0.leftIcon_ ~= "" and var_10_2 ~= "" then
			arg_10_0.isAnimationLeft = true

			arg_10_0.roleLeft1_:runAction(cc.Sequence:create({
				cc.Spawn:create({
					var_10_14:clone(),
					var_10_17:clone()
				}),
				cc.CallFunc:create(function()
					if arg_10_0.roleLeft1_ and not tolua.isnull(arg_10_0.roleLeft1_) then
						arg_10_0.roleLeft1_:removeSelf()
					end

					arg_10_0.roleLeft1_ = xyd.SpriteLoader.new(var_10_2, nil, nil, xyd.DefaultImageType.HOME_CARD)

					arg_10_0.roleLeft1_:setAnchorPoint(cc.p(0.5, 0))
					arg_10_0.roleLeft1_:pos(var_10_21 - var_10_20 - var_10_12, 0)
					arg_10_0.roleLeft1_:setAnchorPoint(cc.p(0, 0))
					arg_10_0.roleLeft1_:addTo(arg_10_0.roleLayer_)
					arg_10_0.roleLeft1_:setVisible(var_10_5 == var_0_3)
					arg_10_0.roleLeft1_:setOpacity(0)
					arg_10_0.roleLeft1_:runAction(cc.Sequence:create({
						cc.Spawn:create({
							cc.MoveBy:create(var_10_11, cc.p(var_10_12, 0)),
							cc.FadeIn:create(var_10_11)
						}),
						cc.CallFunc:create(function()
							arg_10_0.isAnimationLeft = false
						end)
					}))
				end)
			}))
			arg_10_0.roleLeft2_:runAction(cc.Sequence:create({
				cc.Spawn:create({
					var_10_14:clone(),
					var_10_17:clone()
				}),
				cc.CallFunc:create(function()
					if arg_10_0.roleLeft2_ and not tolua.isnull(arg_10_0.roleLeft2_) then
						arg_10_0.roleLeft2_:removeSelf()
					end

					arg_10_0.roleLeft2_ = xyd.SpriteLoader.new(var_10_2, nil, nil, xyd.DefaultImageType.HOME_CARD)

					arg_10_0.roleLeft2_:setAnchorPoint(cc.p(0.5, 0))
					arg_10_0.roleLeft2_:pos(var_10_21 - var_10_20 - var_10_12, 0)
					arg_10_0.roleLeft2_:addTo(arg_10_0.roleLayer_)
					arg_10_0.roleLeft2_:setOpacity(0)
					arg_10_0:gray(arg_10_0.roleLeft2_)
					arg_10_0.roleLeft2_:setVisible(var_10_5 ~= var_0_3)
					arg_10_0.roleLeft2_:runAction(cc.Spawn:create({
						cc.MoveBy:create(var_10_11, cc.p(var_10_12, 0)),
						cc.FadeIn:create(var_10_11)
					}))
				end)
			}))
		elseif arg_10_0.leftIcon_ ~= "" then
			arg_10_0.isAnimationLeft = true

			arg_10_0.roleLeft1_:runAction(cc.Sequence:create({
				cc.Spawn:create({
					var_10_14:clone(),
					var_10_17:clone()
				}),
				cc.CallFunc:create(function()
					arg_10_0.isAnimationLeft = false

					if arg_10_0.roleLeft1_ and not tolua.isnull(arg_10_0.roleLeft1_) then
						arg_10_0.roleLeft1_:removeSelf()
					end
				end)
			}))
			arg_10_0.roleLeft2_:runAction(cc.Sequence:create({
				cc.Spawn:create({
					var_10_14:clone(),
					var_10_17:clone()
				}),
				cc.CallFunc:create(function()
					if arg_10_0.roleLeft2_ and not tolua.isnull(arg_10_0.roleLeft2_) then
						arg_10_0.roleLeft2_:removeSelf()
					end
				end)
			}))
		elseif var_10_2 ~= "" then
			arg_10_0.isAnimationLeft = true

			local var_10_22 = xyd.SpriteLoader.new(var_10_2, nil, nil, xyd.DefaultImageType.HOME_CARD)

			var_10_22:addTo(arg_10_0.roleLayer_)
			var_10_22:setAnchorPoint(cc.p(0.5, 0))
			var_10_22:pos(var_10_21 - var_10_20 - var_10_12, 0)
			var_10_22:setOpacity(0)

			local var_10_23 = var_10_22:clone()

			var_10_23:addTo(arg_10_0.roleLayer_)

			arg_10_0.roleLeft1_ = var_10_22
			arg_10_0.roleLeft2_ = var_10_23

			arg_10_0.roleLeft1_:setVisible(var_10_5 == var_0_3)
			arg_10_0.roleLeft2_:setVisible(var_10_5 ~= var_0_3)
			arg_10_0:gray(arg_10_0.roleLeft2_)
			arg_10_0.roleLeft1_:runAction(cc.Sequence:create({
				cc.Spawn:create({
					cc.MoveBy:create(var_10_11, cc.p(var_10_12, 0)),
					cc.FadeIn:create(var_10_11)
				}),
				cc.CallFunc:create(function()
					arg_10_0.isAnimationLeft = false
				end)
			}))
			arg_10_0.roleLeft2_:runAction(cc.Spawn:create({
				cc.MoveBy:create(var_10_11, cc.p(var_10_12, 0)),
				cc.FadeIn:create(var_10_11)
			}))
		end

		arg_10_0.leftIcon_ = var_10_2
	elseif arg_10_0.roleLeft1_ and not tolua.isnull(arg_10_0.roleLeft1_) then
		arg_10_0.roleLeft1_:setVisible(var_10_5 == var_0_3)
		arg_10_0.roleLeft2_:setVisible(var_10_5 ~= var_0_3)
	end

	if arg_10_0.rightIcon_ ~= var_10_3 then
		if arg_10_0.rightIcon_ ~= "" and var_10_3 ~= "" then
			arg_10_0.isAnimationRight = true

			arg_10_0.roleRight1_:runAction(cc.Sequence:create({
				cc.Spawn:create({
					var_10_15:clone(),
					var_10_17:clone()
				}),
				cc.CallFunc:create(function()
					if arg_10_0.roleRight1_ and not tolua.isnull(arg_10_0.roleRight1_) then
						arg_10_0.roleRight1_:removeSelf()
					end

					arg_10_0.roleRight1_ = xyd.SpriteLoader.new(var_10_3, nil, nil, xyd.DefaultImageType.HOME_CARD)

					arg_10_0.roleRight1_:setAnchorPoint(cc.p(0.5, 0))
					arg_10_0.roleRight1_:pos(var_10_21 + var_10_20 + var_10_12, 0)
					arg_10_0.roleRight1_:setOpacity(0)
					arg_10_0.roleRight1_:addTo(arg_10_0.roleLayer_)
					arg_10_0.roleRight1_:setVisible(var_10_5 == var_0_4)
					arg_10_0.roleRight1_:runAction(cc.Sequence:create({
						cc.Spawn:create({
							cc.MoveBy:create(var_10_11, cc.p(-var_10_12, 0)),
							cc.FadeIn:create(var_10_11)
						}),
						cc.CallFunc:create(function()
							arg_10_0.isAnimationRight = false
						end)
					}))
				end)
			}))
			arg_10_0.roleRight2_:runAction(cc.Sequence:create({
				cc.Spawn:create({
					var_10_15:clone(),
					var_10_17:clone()
				}),
				cc.CallFunc:create(function()
					if arg_10_0.roleRight2_ and not tolua.isnull(arg_10_0.roleRight2_) then
						arg_10_0.roleRight2_:removeSelf()
					end

					arg_10_0.roleRight2_ = xyd.SpriteLoader.new(var_10_3, nil, nil, xyd.DefaultImageType.HOME_CARD)

					arg_10_0.roleRight2_:setAnchorPoint(cc.p(0.5, 0))
					arg_10_0.roleRight2_:pos(var_10_21 + var_10_20 + var_10_12, 0)
					arg_10_0.roleRight2_:addTo(arg_10_0.roleLayer_)
					arg_10_0.roleRight2_:setOpacity(0)
					arg_10_0:gray(arg_10_0.roleRight2_)
					arg_10_0.roleRight2_:setVisible(var_10_5 ~= var_0_4)
					arg_10_0.roleRight2_:runAction(cc.Spawn:create({
						cc.MoveBy:create(var_10_11, cc.p(-var_10_12, 0)),
						cc.FadeIn:create(var_10_11)
					}))
				end)
			}))
		elseif arg_10_0.rightIcon_ ~= "" then
			arg_10_0.isAnimationRight = true

			arg_10_0.roleRight1_:runAction(cc.Sequence:create({
				cc.Spawn:create({
					var_10_15:clone(),
					var_10_17:clone()
				}),
				cc.CallFunc:create(function()
					arg_10_0.isAnimationRight = false

					if arg_10_0.roleRight1_ and not tolua.isnull(arg_10_0.roleRight1_) then
						arg_10_0.roleRight1_:removeSelf()
					end
				end)
			}))
			arg_10_0.roleRight2_:runAction(cc.Sequence:create({
				cc.Spawn:create({
					var_10_15:clone(),
					var_10_17:clone()
				}),
				cc.CallFunc:create(function()
					if arg_10_0.roleRight2_ and not tolua.isnull(arg_10_0.roleRight2_) then
						arg_10_0.roleRight2_:removeSelf()
					end
				end)
			}))
		elseif var_10_3 ~= "" then
			arg_10_0.isAnimationRight = true

			local var_10_24 = xyd.SpriteLoader.new(var_10_3, nil, nil, xyd.DefaultImageType.HOME_CARD)

			var_10_24:addTo(arg_10_0.roleLayer_)
			var_10_24:setAnchorPoint(cc.p(0.5, 0))
			var_10_24:setPosition(cc.p(var_10_21 + var_10_20 + var_10_12, 0))
			var_10_24:setOpacity(0)

			local var_10_25 = var_10_24:clone()

			var_10_25:addTo(arg_10_0.roleLayer_)

			arg_10_0.roleRight1_ = var_10_24
			arg_10_0.roleRight2_ = var_10_25

			arg_10_0.roleRight1_:setVisible(var_10_5 == var_0_4)
			arg_10_0.roleRight2_:setVisible(var_10_5 ~= var_0_4)
			arg_10_0:gray(arg_10_0.roleRight2_)
			arg_10_0.roleRight1_:runAction(cc.Sequence:create({
				cc.Spawn:create({
					cc.MoveBy:create(var_10_11, cc.p(-var_10_12, 0)),
					cc.FadeIn:create(var_10_11)
				}),
				cc.CallFunc:create(function()
					arg_10_0.isAnimationRight = false
				end)
			}))
			arg_10_0.roleRight2_:runAction(cc.Spawn:create({
				cc.MoveBy:create(var_10_11, cc.p(-var_10_12, 0)),
				cc.FadeIn:create(var_10_11)
			}))
		end

		arg_10_0.rightIcon_ = var_10_3
	elseif arg_10_0.roleRight1_ and not tolua.isnull(arg_10_0.roleRight1_) then
		arg_10_0.roleRight1_:setVisible(var_10_5 == var_0_4)
		arg_10_0.roleRight2_:setVisible(var_10_5 ~= var_0_4)
	end

	if arg_10_0.middleIcon_ ~= var_10_4 then
		if arg_10_0.middleIcon_ ~= "" and var_10_4 ~= "" then
			arg_10_0.isAnimationMiddle = true

			arg_10_0.roleMiddle1_:runAction(cc.Sequence:create({
				var_10_19:clone(),
				cc.CallFunc:create(function()
					if arg_10_0.roleMiddle1_ and not tolua.isnull(arg_10_0.roleMiddle1_) then
						arg_10_0.roleMiddle1_:removeSelf()
					end

					arg_10_0.roleMiddle1_ = xyd.SpriteLoader.new(var_10_4, nil, nil, xyd.DefaultImageType.HOME_CARD)

					arg_10_0.roleMiddle1_:pos(var_10_21, 0)
					arg_10_0.roleMiddle1_:setAnchorPoint(cc.p(0.5, 0))
					arg_10_0.roleMiddle1_:addTo(arg_10_0.roleLayer_)
					arg_10_0.roleMiddle1_:setOpacity(0)
					arg_10_0.roleMiddle1_:setVisible(var_10_5 == var_0_5)
					arg_10_0.roleMiddle1_:runAction(cc.Sequence:create({
						cc.FadeIn:create(var_10_13),
						cc.CallFunc:create(function()
							arg_10_0.isAnimationLeft = false
						end)
					}))
				end)
			}))
			arg_10_0.roleMiddle2_:runAction(cc.Sequence:create({
				var_10_19:clone(),
				cc.CallFunc:create(function()
					if arg_10_0.roleMiddle2_ and not tolua.isnull(arg_10_0.roleMiddle2_) then
						arg_10_0.roleMiddle2_:removeSelf()
					end

					arg_10_0.roleMiddle2_ = xyd.SpriteLoader.new(var_10_4, nil, nil, xyd.DefaultImageType.HOME_CARD)

					arg_10_0.roleMiddle1_:pos(var_10_21, 0)
					arg_10_0.roleMiddle2_:setAnchorPoint(cc.p(0.5, 0))
					arg_10_0.roleMiddle2_:addTo(arg_10_0.roleLayer_)
					arg_10_0.roleMiddle1_:setOpacity(0)
					arg_10_0:gray(arg_10_0.roleMiddle2_)
					arg_10_0.roleMiddle2_:setVisible(var_10_5 ~= var_0_5)
					arg_10_0.roleMiddle2_:runAction(cc.Sequence:create({
						cc.FadeIn:create(var_10_13)
					}))
				end)
			}))
		elseif arg_10_0.middleIcon_ ~= "" then
			arg_10_0.isAnimationMiddle = true

			arg_10_0.roleMiddle1_:runAction(cc.Sequence:create({
				var_10_19:clone(),
				cc.CallFunc:create(function()
					arg_10_0.isAnimationMiddle = false

					if arg_10_0.roleMiddle1_ and not tolua.isnull(arg_10_0.roleMiddle1_) then
						arg_10_0.roleMiddle1_:removeSelf()
					end
				end)
			}))
			arg_10_0.roleMiddle2_:runAction(cc.Sequence:create({
				var_10_19:clone(),
				cc.CallFunc:create(function()
					if arg_10_0.roleMiddle2_ and not tolua.isnull(arg_10_0.roleMiddle2_) then
						arg_10_0.roleMiddle2_:removeSelf()
					end
				end)
			}))
		elseif var_10_4 ~= "" then
			arg_10_0.isAnimationMiddle = true

			local var_10_26 = xyd.SpriteLoader.new(var_10_4, nil, nil, xyd.DefaultImageType.HOME_CARD)

			var_10_26:addTo(arg_10_0.roleLayer_)
			var_10_26:pos(var_10_21, 0)
			var_10_26:setAnchorPoint(cc.p(0.5, 0))
			var_10_26:setOpacity(0)

			local var_10_27 = var_10_26:clone()

			var_10_27:addTo(arg_10_0.roleLayer_)

			arg_10_0.roleMiddle1_ = var_10_26
			arg_10_0.roleMiddle2_ = var_10_27

			arg_10_0.roleMiddle1_:setVisible(var_10_5 == var_0_5)
			arg_10_0.roleMiddle2_:setVisible(var_10_5 ~= var_0_5)
			arg_10_0:gray(arg_10_0.roleMiddle2_)
			arg_10_0.roleMiddle1_:runActionOnce(var_10_18:clone(), false, function()
				arg_10_0.isAnimationMiddle = false
			end)
			arg_10_0.roleMiddle2_:runActionOnce(var_10_18:clone(), false)
		end

		arg_10_0.middleIcon_ = var_10_4
	elseif arg_10_0.roleMiddle1_ and not tolua.isnull(arg_10_0.roleMiddle1_) then
		arg_10_0.roleMiddle1_:setVisible(var_10_5 == var_0_5)
		arg_10_0.roleMiddle2_:setVisible(var_10_5 ~= var_0_5)
	end

	if var_10_5 == var_0_3 or var_10_5 == var_0_5 then
		arg_10_0:nodeByName("name_box1"):setVisible(true)
		arg_10_0:nodeByName("label_name1"):setString(var_10_1)
		arg_10_0:nodeByName("label_name1"):setVisible(true)
		arg_10_0:nodeByName("name_box2"):setVisible(false)
		arg_10_0:nodeByName("label_name2"):setVisible(false)
	else
		arg_10_0:nodeByName("name_box2"):setVisible(true)
		arg_10_0:nodeByName("label_name2"):setString(var_10_1)
		arg_10_0:nodeByName("label_name2"):setVisible(true)
		arg_10_0:nodeByName("name_box1"):setVisible(false)
		arg_10_0:nodeByName("label_name1"):setVisible(false)
	end

	arg_10_0.shaking_ = true

	arg_10_0:shake(var_10_5, var_10_6)
end

function var_0_1.iconFilter(arg_29_0, arg_29_1, arg_29_2, arg_29_3)
	if not arg_29_1 or not arg_29_2 then
		return
	end

	if arg_29_3 then
		arg_29_1:hide()
		arg_29_2:hide()
	else
		arg_29_2:hide()
		arg_29_1:show()
	end
end

function var_0_1.gray(arg_30_0, arg_30_1)
	local var_30_0 = cc.TintBy:create(0, 100, 100, 100)

	arg_30_1:runActionOnce(var_30_0)
end

function var_0_1.shake(arg_31_0, arg_31_1, arg_31_2)
	if arg_31_2 <= 0 then
		arg_31_0.shaking_ = false

		return
	end

	local var_31_0 = var_0_2.storyShakeDuration
	local var_31_1 = var_0_2.shakeOffPos1
	local var_31_2 = var_0_2.shakeOffPos2
	local var_31_3

	if arg_31_1 == var_0_3 then
		var_31_3 = arg_31_0.roleLeft1_
	elseif arg_31_1 == var_0_4 then
		var_31_3 = arg_31_0.roleRight1_
	else
		var_31_3 = arg_31_0.roleMiddle1_
	end

	if arg_31_2 == var_0_6 then
		local var_31_4 = var_0_2.storyShakeDuration
		local var_31_5 = var_0_2.shakeOffPos1
		local var_31_6 = xyd.Shake:create(var_31_4, 0, var_31_5)

		var_31_3:runActionOnce(var_31_6, nil, function()
			arg_31_0.shaking_ = false
		end)
	elseif arg_31_2 == var_0_7 then
		local var_31_7 = var_0_2.storyShakeDuration
		local var_31_8 = var_0_2.shakeOffPos2
		local var_31_9 = xyd.Shake:create(var_31_7, var_31_8, 0)

		var_31_3:runActionOnce(var_31_9, nil, function()
			arg_31_0.shaking_ = false
		end)
	elseif arg_31_2 == var_0_8 then
		local var_31_10 = var_0_2.storyShakeDuration
		local var_31_11 = var_0_2.shakeOffPos2
		local var_31_12 = xyd.Shake:create(var_31_10, 0, var_31_11)

		var_31_3:runActionOnce(var_31_12, nil, function()
			arg_31_0.shaking_ = false
		end)

		local var_31_13 = xyd.Shake:create(var_31_10, 0, var_31_11)

		arg_31_0:nodeByName("bottom"):runActionOnce(var_31_13, nil, function()
			arg_31_0.shaking_ = false
		end)
	end
end

function var_0_1.editPlayerName(arg_36_0)
	local var_36_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if not var_36_0.playerName or #var_36_0.playerName == 0 then
		local var_36_1 = xyd.WindowManager.get():openWindow("edit_player_name", {
			notClose = true
		})

		if var_36_1 then
			cc.EventProxy.new(var_36_1, var_36_1):addEventListener(xyd.event.EDIT_NAME_FINISHED, function(arg_37_0)
				arg_36_0:update()
			end)
		end
	end
end

function var_0_1.enterStoryPoint(arg_38_0)
	arg_38_0.storyPoint_ = arg_38_0.storyPoint_ + 1

	arg_38_0:dispatchEvent({
		name = xyd.event.STORY_COMPLETE,
		point = arg_38_0.storyPoint_
	})
	arg_38_0:hide()
	arg_38_0.touchLayer_:setTouchEnabled(false)
end

function var_0_1.resumeBattleStory(arg_39_0)
	arg_39_0:show()
	arg_39_0.touchLayer_:setTouchEnabled(true)
end

function var_0_1.endBattleStory(arg_40_0)
	arg_40_0.endBattleStory_ = true
end

function var_0_1.getPlayerName(arg_41_0)
	local var_41_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if not var_41_0.playerName or #var_41_0.playerName == 0 then
		return " "
	end

	return var_41_0.playerName
end

function var_0_1.onEnded(arg_42_0)
	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_CONQUER_SCHOOL_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CONQUER_SCHOOL_END)
		xyd.StoryData.get():persist()
	elseif arg_42_0.isBeforeStory then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_BEFORE_STORY)
		xyd.StoryData.get():persist()
	elseif arg_42_0.isAssistBattle or arg_42_0.isChocolate then
		-- block empty
	else
		xyd.StoryData.get():setStoryID(arg_42_0.battleID_, arg_42_0.storyState_)
		xyd.StoryData.get():persist()
	end

	xyd.WindowManager.get():closeWindow("story")
end

function var_0_1.didClose(arg_43_0)
	return
end

function var_0_1.willClose(arg_44_0)
	if not arg_44_0.isBeforeStory then
		local var_44_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleBottomWnd)
		local var_44_1 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleTopWnd)

		if var_44_1 then
			var_44_1:setVisible(true)
		end

		if var_44_0 then
			var_44_0:setVisible(true)
		end
	end

	arg_44_0:dispatchEvent({
		name = xyd.event.STORY_COMPLETE,
		state = arg_44_0.storyState_
	})

	if arg_44_0.callback then
		arg_44_0.callback()
	end
end

return var_0_1
