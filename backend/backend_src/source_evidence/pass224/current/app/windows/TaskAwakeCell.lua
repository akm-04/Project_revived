local var_0_0 = class("TaskAwakeCell", import("app.common.ui.BaseNode"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = import("app.common.ui.CommonInputBox")
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = xyd.tables.translation
local var_0_6 = xyd.tables.mission
local var_0_7 = "#44505B"
local var_0_8 = "#7F0DA1B7"
local var_0_9 = "#7FA90DB7"
local var_0_10 = "skeletons/ui_effect/task_awake/task_refresh"

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0)

	arg_1_0.taskInfo = arg_1_1.taskInfo
	arg_1_0.tableID = arg_1_0.taskInfo.table_id
	arg_1_0.awakeType = arg_1_0.taskInfo.awake_type
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)

	if arg_1_0.awakeType == xyd.AwakeType.HERO then
		arg_1_0.defaultImageType = xyd.DefaultImageType.AWAKE_HERO_ICON
	elseif arg_1_0.awakeType == xyd.AwakeType.HERO_TWICE then
		arg_1_0.defaultImageType = xyd.DefaultImageType.BLOODLINE
	elseif arg_1_0.awakeType == xyd.AwakeType.PET then
		arg_1_0.defaultImageType = xyd.DefaultImageType.AWAKE_PET_ICON
	end
end

function var_0_0.layout(arg_2_0)
	arg_2_0:showTaskByID(arg_2_0.tableID)
end

function var_0_0.showTaskByID(arg_3_0, arg_3_1)
	arg_3_0.curShowID = arg_3_1

	arg_3_0:clearRes()
	arg_3_0:loadRes("windows/task/task_awake_cell.csb")
	arg_3_0:setBackground()

	local var_3_0 = xyd.SpriteLoader.new(var_0_6:title(arg_3_1) .. ".png", nil, nil, xyd.DefaultImageType.COMMON_TITLE)

	if not var_3_0 then
		return
	end

	var_3_0:setAnchorPoint(0.5, 0.5)
	var_3_0:addTo(arg_3_0:background())
	var_3_0:setPosition(arg_3_0:nodeByName("pos_title"):getPosition())

	local var_3_1 = xyd.createAutoFixLabel({
		height = 65,
		fontSize = 24,
		txtColor = "#44454D",
		width = 850,
		text = var_0_6:heroDesc(arg_3_1),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_3_1:addTo(arg_3_0:background())
	var_3_1:setAnchorPoint(0, 1)

	local var_3_2, var_3_3 = arg_3_0:nodeByName("pos_txt_hero_desc"):getPosition()

	var_3_1:setPosition(var_3_2 + 15, var_3_3 - 3)

	local var_3_4 = var_0_2.new({
		size = 863,
		color = var_0_7,
		align = xyd.SplitLineAlign.CENTER
	})

	var_3_4:addTo(arg_3_0:background())
	var_3_4:setAnchorPoint(0.5, 0.5)
	var_3_4:setPosition(arg_3_0:nodeByName("pos_splitline"):getPosition())

	local var_3_5

	if arg_3_0.awakeType == xyd.AwakeType.PET then
		local var_3_6 = var_0_6:beforeAwakenID(arg_3_1)
		local var_3_7 = arg_3_0.selfPlayer:getPetByTableID(var_3_6):getStar()

		var_3_5 = var_0_6:heroIcons(arg_3_1)[var_3_7] .. ".png"
	else
		var_3_5 = var_0_6:heroIcons(arg_3_1) .. ".png"
	end

	local var_3_8 = xyd.SpriteLoader.new(var_3_5, nil, nil, arg_3_0.defaultImageType)

	var_3_8:addTo(arg_3_0:background())
	var_3_8:setAnchorPoint(0.5, 0.5)
	var_3_8:setScale(0.8)
	var_3_8:setPosition(arg_3_0:nodeByName("pos_hero_model"):getPosition())

	local var_3_9 = xyd.createAutoFixLabel({
		height = 32,
		fontSize = 22,
		txtColor = "#44454D",
		width = 670,
		text = var_0_6:missionDesc(arg_3_1),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_3_9:addTo(arg_3_0:background())
	var_3_9:setAnchorPoint(0, 1)
	var_3_9:setPosition(arg_3_0:nodeByName("pos_txt_task_desc"):getPosition())

	local var_3_10

	if arg_3_0.tableID == xyd.AwakeIDs.LVBU_AWAKE then
		var_3_10 = var_0_5:translation("LVBU_AWAKEN_TIP")
	elseif arg_3_0.tableID == xyd.AwakeIDs.ZHUGE_AWAKE_ID then
		var_3_10 = var_0_5:translation("ZHUGE_AWAKEN_TIP")
	elseif arg_3_0.tableID == xyd.AwakeIDs.MIJIALE_AWAKE_ID or arg_3_0.tableID == xyd.AwakeIDs.LUXIFA_AWAKE_ID then
		var_3_10 = var_0_5:translation("CAMP_WAR_AWAKEN_TIP")
	elseif arg_3_0.tableID == xyd.AwakeIDs.LVQILING_AWAKE_ID then
		var_3_10 = var_0_5:translation("LVLINGQI_BLOODLINE_MISSION_TEXT")
	elseif arg_3_0.tableID == xyd.AwakeIDs.KONGMINGDENG_AWAKE_ID then
		var_3_10 = var_0_5:translation("KONGMINGDENG_AWAKEN_MISSION_TEXT")
	elseif arg_3_0.tableID == xyd.AwakeIDs.FENGXIAN_AWAKE_ID then
		var_3_10 = var_0_5:translation("LVLINGQI_BLOODLINE_MISSION_TEXT")
	elseif arg_3_0.tableID == xyd.AwakeIDs.WOLONG_AWAKE_ID then
		var_3_10 = var_0_5:translation("WOLONG_AWAKEN_MISSION_TEXT")
	elseif arg_3_0.tableID == xyd.AwakeIDs.SPSIMAZHAO_AWAKE_ID then
		var_3_10 = var_0_5:translation("CANNOT_MISSION_TEXT")
	else
		var_3_10 = var_0_5:translation("AWAKEN_TIP")
	end

	local var_3_11 = var_0_6:stage(arg_3_1)

	if var_0_6:stage(arg_3_1) == 1 then
		local var_3_12 = xyd.createAutoFixLabel({
			height = 30,
			fontSize = 20,
			txtColor = "#FF7E3E",
			width = 600,
			text = var_3_10,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_CENTER
		})

		var_3_12:addTo(arg_3_0:background())
		var_3_12:setAnchorPoint(0, 1)
		var_3_12:setPosition(arg_3_0:nodeByName("pos_txt_task_tip"):getPosition())
	end

	local var_3_13 = "windows/task/icon_stage_" .. var_3_11 .. ".png"
	local var_3_14 = xyd.AssetLoader.get():loadSprite(var_3_13)

	var_3_14:addTo(arg_3_0:background())
	var_3_14:setAnchorPoint(0.5, 0.5)
	var_3_14:setPosition(arg_3_0:nodeByName("pos_stage_num"):getPosition())

	arg_3_0.stageNode = display.newNode()

	arg_3_0.stageNode:setContentSize(var_3_14:getContentSize())
	arg_3_0.stageNode:setAnchorPoint(0.5, 0.5)
	arg_3_0.stageNode:addTo(arg_3_0:background())
	arg_3_0.stageNode:setPosition(var_3_14:getPosition())
	arg_3_0.stageNode:setTouchEnabled(true)
	arg_3_0:updateBottle()
	arg_3_0:addTargetInfo(arg_3_1)

	if arg_3_1 == arg_3_0.tableID and arg_3_0.taskInfo.is_going == 0 then
		arg_3_0:nodeByName("bg_awake_mask"):setVisible(true)
		arg_3_0:nodeByName("bg_awake_mask"):setLocalZOrder(5)

		arg_3_0.openBtn = var_0_1.new({
			sprite = "windows/button/btn195_2.png",
			titleSize = 24,
			title = var_0_5:translation("BTN_NAME_OPEN_TASK"),
			clickMode = xyd.ButtonClickMode.SCALE,
			capInsets = cc.rect(100, 1, 1, 1)
		})

		arg_3_0.openBtn:setButtonSize(247, 68)
		arg_3_0.openBtn:addTo(arg_3_0:background())
		arg_3_0.openBtn:setAnchorPoint(0.5, 0.5)
		arg_3_0.openBtn:setPosition(arg_3_0:nodeByName("pos_btn_open_task"):getPosition())
		arg_3_0.openBtn:setLocalZOrder(6)

		if arg_3_0.giveUpBtn and not tolua.isnull(arg_3_0.giveUpBtn) then
			arg_3_0.giveUpBtn:setDisabled(true)
		end

		if arg_3_0.gotoBtn and not tolua.isnull(arg_3_0.gotoBtn) then
			arg_3_0.gotoBtn:setDisabled(true)
		end

		if arg_3_0.stageNode and not tolua.isnull(arg_3_0.stageNode) then
			arg_3_0.stageNode:setTouchEnabled(false)
		end
	end

	if arg_3_1 ~= arg_3_0.tableID then
		if arg_3_0.giveUpBtn and not tolua.isnull(arg_3_0.giveUpBtn) then
			arg_3_0.giveUpBtn:setDisabled(true)
		end

		if arg_3_0.gotoBtn and not tolua.isnull(arg_3_0.gotoBtn) then
			arg_3_0.gotoBtn:setDisabled(true)
		end
	end

	arg_3_0:onRegister()
end

function var_0_0.setBackground(arg_4_0)
	if arg_4_0.taskInfo.awake_type == xyd.AwakeType.HERO_TWICE then
		arg_4_0:nodeByName("bg_awake_twice"):setVisible(true)
		arg_4_0:nodeByName("bg_awake_normal"):setVisible(false)
		arg_4_0:nodeByName("bg_awake_sub_blue"):setVisible(false)
		arg_4_0:nodeByName("bg_awake_sub_red"):setVisible(true)
		arg_4_0:nodeByName("bg_mini_white"):setVisible(false)
		arg_4_0:nodeByName("bg_mini_yellow"):setVisible(true)
		arg_4_0:nodeByName("bg_awake_mask"):setVisible(false)
		arg_4_0:nodeByName("bg_awake_pet_paw"):setVisible(false)
		arg_4_0:nodeByName("bg_matrix"):setColor(xyd.convertHex2RGB(var_0_9))
	elseif arg_4_0.taskInfo.awake_type == xyd.AwakeType.PET then
		arg_4_0:nodeByName("bg_awake_twice"):setVisible(false)
		arg_4_0:nodeByName("bg_awake_normal"):setVisible(true)
		arg_4_0:nodeByName("bg_awake_sub_blue"):setVisible(true)
		arg_4_0:nodeByName("bg_awake_sub_red"):setVisible(false)
		arg_4_0:nodeByName("bg_mini_white"):setVisible(true)
		arg_4_0:nodeByName("bg_mini_yellow"):setVisible(false)
		arg_4_0:nodeByName("bg_awake_mask"):setVisible(false)
		arg_4_0:nodeByName("bg_awake_pet_paw"):setVisible(true)
		arg_4_0:nodeByName("bg_matrix"):setColor(xyd.convertHex2RGB(var_0_8))
	else
		arg_4_0:nodeByName("bg_awake_twice"):setVisible(false)
		arg_4_0:nodeByName("bg_awake_normal"):setVisible(true)
		arg_4_0:nodeByName("bg_awake_sub_blue"):setVisible(true)
		arg_4_0:nodeByName("bg_awake_sub_red"):setVisible(false)
		arg_4_0:nodeByName("bg_mini_white"):setVisible(true)
		arg_4_0:nodeByName("bg_mini_yellow"):setVisible(false)
		arg_4_0:nodeByName("bg_awake_mask"):setVisible(false)
		arg_4_0:nodeByName("bg_awake_pet_paw"):setVisible(false)
		arg_4_0:nodeByName("bg_matrix"):setColor(xyd.convertHex2RGB(var_0_8))
	end
end

function var_0_0.addTargetInfo(arg_5_0, arg_5_1)
	local var_5_0 = var_0_6:stage(arg_5_1)

	if var_5_0 == 1 then
		local var_5_1 = var_0_6:items(arg_5_1)

		xyd.setItemBorder(arg_5_0:nodeByName("icon_container"), var_5_1)
	elseif var_5_0 == 2 then
		local var_5_2 = var_0_6:campaignIcons(arg_5_1)
		local var_5_3 = arg_5_0:nodeByName("icon_container"):getWidth()
		local var_5_4 = xyd.AssetLoader.get():loadSprite(var_5_2)
		local var_5_5 = var_5_3 / var_5_4:getWidth()

		var_5_4:setScale(var_5_5)
		var_5_4:addTo(arg_5_0:nodeByName("icon_container"))
		var_5_4:setAnchorPoint(0, 0)
		var_5_4:setPosition(0, 0)
	end

	local var_5_6

	if var_5_0 == 1 then
		var_5_6 = var_0_6:missionTypeName(arg_5_1)[1]
	elseif var_5_0 == 2 then
		var_5_6 = string.format(var_0_6:missionTypeName(arg_5_1)[1], xyd.tables.campaign:chapter(xyd.getMissionGoIDs(arg_5_1)))
	end

	local var_5_7 = xyd.createAutoFixLabel({
		height = 30,
		fontSize = 24,
		txtColor = "#606D95",
		width = 220,
		text = var_5_6,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_5_7:addTo(arg_5_0:background())
	var_5_7:setAnchorPoint(0, 1)
	var_5_7:setPosition(arg_5_0:nodeByName("pos_txt_target_name"):getPosition())

	local var_5_8

	if var_5_0 == 1 then
		var_5_8 = xyd.tables.item:name(var_0_6:items(arg_5_1))
	elseif var_5_0 == 2 then
		var_5_8 = xyd.tables.campaign:campaignName(xyd.getMissionGoIDs(arg_5_1))
	end

	local var_5_9 = xyd.createAutoFixLabel({
		height = 40,
		fontSize = 24,
		txtColor = "#FD7515",
		width = 220,
		text = var_5_8,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_5_9:addTo(arg_5_0:background())
	var_5_9:setAnchorPoint(0, 1)
	var_5_9:setPosition(arg_5_0:nodeByName("pos_txt_target_desc"):getPosition())

	if arg_5_0.taskInfo.is_complete == 1 then
		local var_5_10 = xyd.AssetLoader.get():loadSprite("windows/common/icons/icon_completed.png")

		var_5_10:addTo(arg_5_0:background())
		var_5_10:setAnchorPoint(0.5, 0.5)
		var_5_10:setPosition(arg_5_0:nodeByName("pos_icon_completed"):getPosition())
	else
		arg_5_0.giveUpBtn = var_0_1.new({
			titleSize = 24,
			sprite = "windows/button/btn127_1.png",
			title = var_0_5:translation("BTN_NAME_GIVE_UP"),
			clickMode = xyd.ButtonClickMode.SCALE
		})

		arg_5_0.giveUpBtn:addTo(arg_5_0:background())
		arg_5_0.giveUpBtn:setAnchorPoint(0.5, 0.5)
		arg_5_0.giveUpBtn:setPosition(arg_5_0:nodeByName("pos_giveup_btn"):getPosition())

		arg_5_0.gotoBtn = var_0_1.new({
			titleSize = 24,
			sprite = "windows/button/btn127_2.png",
			title = var_0_5:translation("BUTTON_NAME_GO"),
			clickMode = xyd.ButtonClickMode.SCALE
		})

		arg_5_0.gotoBtn:addTo(arg_5_0:background())
		arg_5_0.gotoBtn:setAnchorPoint(0.5, 0.5)
		arg_5_0.gotoBtn:setPosition(arg_5_0:nodeByName("pos_goto_btn"):getPosition())
	end
end

function var_0_0.updateBottle(arg_6_0)
	if arg_6_0.awakeType == xyd.AwakeType.HERO then
		local var_6_0 = arg_6_0.backpack:getItemNumByID(xyd.tables.misc.awakeItem)

		if var_6_0 > 0 then
			arg_6_0.isAwakeItem = true
		end

		arg_6_0:nodeByName("bottle_container"):setVisible(true)
		arg_6_0:nodeByName("txt_bottle_num"):setString(var_6_0)
		arg_6_0:nodeByName("icon_bottle"):setTouchEnabled(true)
	else
		arg_6_0.isAwakeItem = false

		arg_6_0:nodeByName("bottle_container"):setVisible(false)
		arg_6_0:nodeByName("icon_bottle"):setTouchEnabled(false)
	end

	local var_6_1 = xyd.tables.misc:getValue("awake_partner_wish_not")

	for iter_6_0 = 1, #var_6_1 do
		if arg_6_0.tableID == var_6_1[iter_6_0] then
			arg_6_0:nodeByName("bottle_container"):setVisible(false)
		end
	end
end

function var_0_0.useAwakeItem(arg_7_0, arg_7_1)
	local var_7_0 = var_0_6:awakeMaterial(arg_7_1)
	local var_7_1 = var_0_6:items(arg_7_1)

	if var_7_1 == 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("AWAKEN_HERO_NOT_NEED")
		})
	else
		local function var_7_2()
			xyd.ModelManager.get():loadModel(xyd.ModelType.TASK):getAwakeItem(function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():addItemsByID(arg_9_1.item_id, arg_9_1.item_num)

					local var_9_0 = {
						{
							table_id = arg_9_1.item_id,
							item_num = arg_9_1.item_num
						}
					}

					xyd.WindowManager.get():openWindow("alert_award", {
						awards = var_9_0
					})
				end
			end)
		end

		local var_7_3 = {
			rcallBefore = 0,
			txt = var_0_5:translation("GET_AWAKEN_ITEM_NOW"),
			rcallback = function(arg_10_0)
				if arg_10_0.name == "ended" then
					local var_10_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack()

					if var_10_0:getItemNumByID(var_7_1) > 0 or var_10_0:getItemNumByID(var_7_0) > 0 then
						local var_10_1 = {
							txt = var_0_5:translation("ALREADY_GET_AWAKEN_ITEM"),
							rcallback = function(arg_11_0)
								if arg_11_0.name == "ended" then
									var_7_2()
								end
							end
						}

						xyd.WindowManager.get():openWindow("common_alert", var_10_1)
					else
						var_7_2()
					end
				end
			end
		}

		xyd.WindowManager.get():openWindow("common_alert", var_7_3)
	end
end

function var_0_0.onRegister(arg_12_0)
	if arg_12_0.isAwakeItem and arg_12_0.taskInfo.is_open == 1 and arg_12_0.taskInfo.is_complete == 0 then
		local var_12_0 = arg_12_0:nodeByName("icon_bottle")

		var_12_0:setTouchEnabled(true)
		var_12_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
			if arg_13_0.name == "began" then
				var_12_0:setScale(0.95)

				return true
			elseif arg_13_0.name == "ended" then
				var_12_0:setScale(1)
				arg_12_0:useAwakeItem(arg_12_0.tableID)
			end
		end)
	end

	if arg_12_0.stageNode and not tolua.isnull(arg_12_0.stageNode) then
		arg_12_0.stageNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
			if arg_14_0.name == "began" then
				return true
			elseif arg_14_0.name == "ended" then
				local var_14_0 = var_0_6:sufMissionID(arg_12_0.curShowID)

				if var_14_0 and var_14_0 > 0 then
					arg_12_0:showTaskByID(var_14_0)
				else
					local var_14_1 = var_0_6:preMissionID(arg_12_0.curShowID)

					if var_14_1 and var_14_1 > 0 then
						arg_12_0:showTaskByID(var_14_1)
					end
				end
			end
		end)
	end

	if arg_12_0.giveUpBtn and not tolua.isnull(arg_12_0.giveUpBtn) then
		arg_12_0.giveUpBtn:addTouchEvent(function(arg_15_0)
			if arg_15_0.name == "ended" then
				local function var_15_0(arg_16_0, arg_16_1, arg_16_2)
					if arg_16_1 and arg_16_1.name ~= "ended" then
						return
					end

					if arg_16_2 and (not arg_16_2.inputBox or arg_16_2.inputBox:getText() ~= "YES") then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_5:translation("INPUT_ERROR")
						})

						return true
					end

					local var_16_0 = arg_16_0.taskID
					local var_16_1 = arg_16_0.awakeType

					xyd.ModelManager.get():loadModel(xyd.ModelType.TASK):giveUpTask(var_16_0, var_16_1)
				end

				local function var_15_1(arg_17_0)
					local var_17_0 = var_0_3.new({
						height = 50,
						bg = "windows/common/background/bg_common_input.png",
						width = 430
					})

					var_17_0:addTo(arg_17_0.container)
					var_17_0:setAnchorPoint(0.5, 0.5)
					var_17_0:setPosition(arg_17_0.width / 2, arg_17_0.height / 2 - 50)

					arg_17_0.inputBox = var_17_0

					arg_17_0.txtLabel:setPositionY(arg_17_0.height / 2 + 25)
				end

				if var_0_6:stage(arg_12_0.tableID) == 1 then
					local var_15_2

					if arg_12_0.awakeType == xyd.AwakeType.HERO_TWICE then
						var_15_2 = var_0_5:translation("GIVE_UP_BLOOD_WARNING")
					else
						var_15_2 = var_0_5:translation("GIVE_UP_AWAKE_HERO_WARNING")
					end

					local var_15_3 = {
						rcallBefore = 0,
						txt = var_15_2,
						addNewComponent = var_15_1,
						rcallback = var_15_0,
						callbackParams = {
							taskID = arg_12_0.tableID,
							awakeType = arg_12_0.awakeType
						}
					}

					xyd.WindowManager.get():openWindow("common_alert", var_15_3)
				else
					local var_15_4 = {
						taskID = arg_12_0.tableID,
						awakeType = arg_12_0.awakeType
					}

					var_15_0(var_15_4)
				end
			end
		end)
	end

	if arg_12_0.gotoBtn and not tolua.isnull(arg_12_0.gotoBtn) then
		arg_12_0.gotoBtn:addTouchEvent(function(arg_18_0)
			if arg_18_0.name == "ended" then
				local var_18_0 = var_0_6:stage(arg_12_0.tableID)

				if var_18_0 == 1 then
					arg_12_0:goTargetInStageOne(arg_12_0.tableID)
				elseif var_18_0 == 2 then
					arg_12_0:goTargetInStageTwo(arg_12_0.tableID)
				end
			end
		end)
	end

	if arg_12_0.openBtn and not tolua.isnull(arg_12_0.openBtn) then
		arg_12_0.openBtn:addTouchEvent(function(arg_19_0)
			if arg_19_0.name == "ended" then
				if arg_12_0.taskInfo.is_going ~= 0 then
					return
				end

				local var_19_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)

				if var_19_0:isHasAwakeOpen(arg_12_0.awakeType) then
					local var_19_1 = {
						txt = var_0_5:translation("CAN_NOT_OPEN_AWAKE_MISSION"),
						type = xyd.CommonAlertType.ONE_BTN
					}

					xyd.WindowManager.get():openWindow("common_alert", var_19_1)

					return
				end

				local var_19_2 = arg_12_0.tableID

				var_19_0:openAwakeTask(var_19_2, arg_12_0.awakeType)
			end
		end)
	end

	if arg_12_0.taskInfo.is_complete == 1 then
		local var_12_1 = false
		local var_12_2 = 0
		local var_12_3 = 0

		arg_12_0:setTouchEnabled(true)
		arg_12_0:setTouchSwallowEnabled(false)
		arg_12_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
			if arg_20_0.name == "began" then
				arg_12_0:setScale(0.95)

				var_12_2 = arg_20_0.x
				var_12_3 = arg_20_0.y
				var_12_1 = false

				return true
			elseif arg_20_0.name == "moved" then
				if math.abs(arg_20_0.y - var_12_3) > 10 or math.abs(arg_20_0.x - var_12_2) > 10 then
					var_12_1 = true
				end
			elseif arg_20_0.name == "ended" then
				arg_12_0:setScale(1)

				if var_12_1 then
					return
				end

				if arg_12_0.awakeType == xyd.AwakeType.HERO then
					arg_12_0:finishHeroAwake()
				elseif arg_12_0.awakeType == xyd.AwakeType.HERO_TWICE then
					arg_12_0:finishHeroTwiceAwake()
				elseif arg_12_0.awakeType == xyd.AwakeType.PET then
					arg_12_0:finishPetAwake()
				end
			end
		end)
	end
end

function var_0_0.goTargetInStageOne(arg_21_0, arg_21_1)
	if arg_21_0.awakeType == xyd.AwakeType.HERO then
		arg_21_0:goAwakeStageOne(arg_21_1)
	elseif arg_21_0.awakeType == xyd.AwakeType.HERO_TWICE then
		arg_21_0:goTwiceAwakeStageOne(arg_21_1)
	elseif arg_21_0.awakeType == xyd.AwakeType.PET then
		arg_21_0:goPetAwakeStageOne(arg_21_1)
	end
end

function var_0_0.goTargetInStageTwo(arg_22_0, arg_22_1)
	if arg_22_0.awakeType == xyd.AwakeType.HERO then
		arg_22_0:goAwakeStageTwo(arg_22_1)
	elseif arg_22_0.awakeType == xyd.AwakeType.HERO_TWICE then
		arg_22_0:goTwiceAwakeStageTwo(arg_22_1)
	elseif arg_22_0.awakeType == xyd.AwakeType.PET then
		arg_22_0:goPetAwakeStageTwo(arg_22_1)
	end
end

function var_0_0.goAwakeStageOne(arg_23_0, arg_23_1)
	if arg_23_1 == xyd.AwakeIDs.LVBU_AWAKE then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("LVBU_AWAKEN_TIP")
		})

		return
	end

	if arg_23_1 == xyd.AwakeIDs.ZHUGE_AWAKE_ID then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("ZHUGE_AWAKEN_TIP")
		})

		return
	end

	if arg_23_1 == xyd.AwakeIDs.MIJIALE_AWAKE_ID or arg_23_1 == xyd.AwakeIDs.LUXIFA_AWAKE_ID then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("CAMP_WAR_AWAKEN_TIP")
		})

		return
	end

	if arg_23_1 == xyd.AwakeIDs.LVQILING_AWAKE_ID then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("LVLINGQI_BLOODLINE_MISSION_TEXT")
		})

		return
	end

	if arg_23_1 == xyd.AwakeIDs.KONGMINGDENG_AWAKE_ID then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("KONGMINGDENG_AWAKEN_MISSION_TEXT")
		})

		return
	end

	if arg_23_1 == xyd.AwakeIDs.WOLONG_AWAKE_ID then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("KONGMINGDENG_AWAKEN_MISSION_TEXT")
		})

		return
	end

	if arg_23_1 == xyd.AwakeIDs.FENGXIAN_AWAKE_ID then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("FENGXIAN_AWAKEN_TIP")
		})

		return
	end

	if arg_23_1 == xyd.AwakeIDs.AODING_AWAKE_ID then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("AODING_AWAKEN_MISSION_TEXT")
		})

		return
	end

	local var_23_0 = xyd.getMissionGoIDs(arg_23_1)

	if var_23_0 == xyd.FunctionID.ID_OCCULT then
		local var_23_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
		local var_23_2 = xyd.tables.creatsChapterSelect:getChapterByMissionId(arg_23_1)

		var_23_1:openOccultWindow(var_23_2)
	elseif var_23_0 > 0 then
		if arg_23_0.selfPlayer.super_chapter_id >= xyd.tables.campaign:chapter(var_23_0) then
			xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD):loadGuildMap(function(arg_24_0)
				if arg_24_0 == xyd.error.OK then
					if xyd.WindowManager.get():getWindow("map_window") then
						xyd.WindowManager.get():closeWindow("map_window")
					end

					local var_24_0
					local var_24_1 = xyd.tables.campaign:campaignType(var_23_0) >= 1 and xyd.tables.campaign:campaignType(var_23_0) <= 2 and 1 or xyd.tables.campaign:campaignType(var_23_0) - 1
					local var_24_2 = var_0_6:awakeMaterial(arg_23_1)
					local var_24_3 = {}

					var_24_3.isStoneCampaign = true
					var_24_3.chapter = xyd.tables.campaign:chapter(var_23_0)
					var_24_3.campaignID = var_23_0
					var_24_3.campaignType = var_24_1
					var_24_3.itemComposeID = xyd.tables.item:compose(var_24_2, 1)
					var_24_3.needItemComposeNum = xyd.tables.item:composeNum(var_24_2, 1)

					xyd.WindowManager.get():openWindow("map_window", var_24_3)
				else
					if xyd.WindowManager.get():getWindow("map_window") then
						xyd.WindowManager.get():closeWindow("map_window")
					end

					local var_24_4
					local var_24_5 = xyd.tables.campaign:campaignType(var_23_0) >= 1 and xyd.tables.campaign:campaignType(var_23_0) <= 2 and 1 or xyd.tables.campaign:campaignType(var_23_0) - 1
					local var_24_6 = var_0_6:awakeMaterial(arg_23_1)
					local var_24_7 = {
						isStoneCampaign = true,
						chapter = xyd.tables.campaign:chapter(var_23_0),
						campaignID = var_23_0,
						campaignType = var_24_5,
						itemComposeID = xyd.tables.item:compose(var_24_6, 1),
						needItemComposeNum = xyd.tables.item:composeNum(var_24_6, 1)
					}

					xyd.WindowManager.get():openWindow("map_window", var_24_7)
				end
			end)
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_5:translation("CHAPTER_NOT_AVAILABLE")
			})
		end
	end
end

function var_0_0.goTwiceAwakeStageOne(arg_25_0, arg_25_1)
	if arg_25_1 == xyd.TwiceAwakeIDs.LVQILING_TWICE_AWAKE_ID then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("LVLINGQI_BLOODLINE_MISSION_TEXT")
		})

		return
	end

	if arg_25_1 == xyd.TwiceAwakeIDs.MIJIAKLE_TWICE_AWAKE_ID then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("TIANSHI_BLOODLINE_MISSION_TEXT")
		})

		return
	end

	if arg_25_1 == xyd.TwiceAwakeIDs.LVXIFA_TWICE_AWAKE_ID then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("TIANSHI_BLOODLINE_MISSION_TEXT")
		})

		return
	end

	if arg_25_1 == xyd.TwiceAwakeIDs.DECHUANJIAKANG_TWICE_AWAKE_ID then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("DECHUANJIAKANG_BLOODLINE_MISSION_TEXT")
		})

		return
	end

	if arg_25_1 == xyd.TwiceAwakeIDs.KONGMINGDENG_AWAKE_TWICE_ID then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("DECHUANJIAKANG_BLOODLINE_MISSION_TEXT")
		})

		return
	end

	if arg_25_1 == xyd.TwiceAwakeIDs.AODING_AWAKE_TWICE_ID then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("DECHUANJIAKANG_BLOODLINE_MISSION_TEXT")
		})

		return
	end

	local var_25_0 = xyd.getMissionGoIDs(arg_25_1)

	xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD):loadGuildMap(function(arg_26_0)
		if arg_26_0 == xyd.error.OK then
			xyd.WindowManager.get():closeWindow("map_window")

			local var_26_0 = xyd.tables.campaign
			local var_26_1
			local var_26_2 = var_26_0:campaignType(var_25_0) >= 1 and xyd.tables.campaign:campaignType(var_25_0) <= 2 and 1 or var_26_0:campaignType(var_25_0) - 1
			local var_26_3 = var_0_6:awakeMaterial(arg_25_1)
			local var_26_4 = {}

			var_26_4.isStoneCampaign = true
			var_26_4.chapter = var_26_0:chapter(var_25_0)
			var_26_4.campaignID = var_25_0
			var_26_4.campaignType = var_26_2
			var_26_4.itemComposeID = xyd.tables.item:compose(var_26_3, 1)
			var_26_4.needItemComposeNum = xyd.tables.item:composeNum(var_26_3, 1)

			xyd.WindowManager.get():openWindow("map_window", var_26_4)
		end
	end)
end

function var_0_0.goPetAwakeStageOne(arg_27_0, arg_27_1)
	if xyd.getMissionGoIDs(arg_27_1) > 0 then
		xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN):getCampaignInfo(function(arg_28_0)
			if arg_28_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("pet_campaign")
			end
		end)
	end
end

function var_0_0.goAwakeStageTwo(arg_29_0, arg_29_1)
	local var_29_0 = xyd.getMissionGoIDs(arg_29_1)

	if var_29_0 > 0 then
		local var_29_1
		local var_29_2 = xyd.tables.campaign:campaignType(var_29_0) >= 1 and xyd.tables.campaign:campaignType(var_29_0) <= 2 and 1 or xyd.tables.campaign:campaignType(var_29_0) - 1

		if var_29_2 == 2 and arg_29_0.selfPlayer.super_chapter_id >= xyd.tables.campaign:chapter(var_29_0) or var_29_2 == 1 and arg_29_0.selfPlayer.normal_chapter_id >= xyd.tables.campaign:chapter(var_29_0) then
			xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD):loadGuildMap(function(arg_30_0)
				if arg_30_0 == xyd.error.OK then
					if xyd.WindowManager.get():getWindow("map_window") then
						xyd.WindowManager.get():closeWindow("map_window")
					end

					if xyd.tables.campaign:campaignType(var_29_0) >= 1 and xyd.tables.campaign:campaignType(var_29_0) <= 2 then
						var_29_2 = 1
					else
						var_29_2 = xyd.tables.campaign:campaignType(var_29_0) - 1
					end

					local var_30_0 = {}

					var_30_0.isStoneCampaign = true
					var_30_0.chapter = xyd.tables.campaign:chapter(var_29_0)
					var_30_0.campaignID = var_29_0
					var_30_0.campaignType = var_29_2

					xyd.WindowManager.get():openWindow("map_window", var_30_0)
				else
					if xyd.WindowManager.get():getWindow("map_window") then
						xyd.WindowManager.get():closeWindow("map_window")
					end

					if xyd.tables.campaign:campaignType(var_29_0) >= 1 and xyd.tables.campaign:campaignType(var_29_0) <= 2 then
						var_29_2 = 1
					else
						var_29_2 = xyd.tables.campaign:campaignType(var_29_0) - 1
					end

					local var_30_1 = {
						isStoneCampaign = true,
						chapter = xyd.tables.campaign:chapter(var_29_0),
						campaignID = var_29_0,
						campaignType = var_29_2
					}

					xyd.WindowManager.get():openWindow("map_window", var_30_1)
				end
			end)
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_5:translation("CHAPTER_NOT_AVAILABLE")
			})
		end
	end
end

function var_0_0.goPetAwakeStageTwo(arg_31_0, arg_31_1)
	local var_31_0 = tonumber(xyd.getMissionGoIDs(arg_31_1))
	local var_31_1 = arg_31_0.selfPlayer.trialInfos_

	if var_31_0 >= 11 and var_31_0 <= 13 then
		xyd.WindowManager.get():openWindow("trial", nil, function()
			if var_31_1[var_31_0] and tonumber(var_31_1[var_31_0].isOpen) == 1 then
				xyd.WindowManager.get():openWindow("select_trial", var_31_1[var_31_0])
			end
		end)
	elseif var_31_0 >= 14 and var_31_0 <= 15 then
		xyd.WindowManager.get():openWindow("time_trial", nil, function()
			if var_31_1[var_31_0] and tonumber(var_31_1[var_31_0].isOpen) == 1 then
				xyd.WindowManager.get():openWindow("select_trial", var_31_1[var_31_0])
			end
		end)
	elseif var_31_0 >= 16 and var_31_0 <= 20 then
		xyd.WindowManager.get():openWindow("unlimitchallenge", nil, function()
			local var_34_0 = xyd.WindowManager.get():getWindow("unlimitchallenge")

			if var_34_0 and var_34_0.challengeID == var_31_0 then
				local var_34_1 = {
					challenges = arg_31_0.challenges,
					campaigns = arg_31_0.campaigns
				}

				xyd.WindowManager.get():openWindow("difficultchoice", var_34_1)
			end
		end)
	else
		xyd.WindowManager.get():openWindow("cloud_city", nil, function()
			if var_31_1[var_31_0] and tonumber(var_31_1[var_31_0].isOpen) == 1 then
				local var_35_0 = {
					trialID = var_31_0,
					campaigns = arg_31_0.selfPlayer.worldMaps_,
					trial = var_31_1[var_31_0]
				}

				xyd.WindowManager.get():openWindow("select_cloud_difficult", var_35_0)
			end
		end)
	end
end

function var_0_0.goTwiceAwakeStageTwo(arg_36_0, arg_36_1)
	xyd.WindowManager.get():openWindow("awake_twice_select_team", {
		missionId = arg_36_1,
		heroId = var_0_6:beforeAwakenID(arg_36_1)
	})
end

function var_0_0.finishHeroAwake(arg_37_0)
	local var_37_0 = var_0_6:sufMissionID(arg_37_0.tableID)

	if var_37_0 and var_37_0 > 0 then
		arg_37_0:generateEffect():play(function()
			arg_37_0.task:getTaskReward(arg_37_0.tableID, xyd.TaskType.AWAKE)
		end, false)
	else
		local var_37_1 = arg_37_0.tableID

		arg_37_0.task:getTaskReward(var_37_1, xyd.TaskType.AWAKE, function(arg_39_0)
			if arg_39_0 == xyd.error.OK then
				local var_39_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
				local var_39_1 = var_0_6:beforeAwakenID(var_37_1)
				local var_39_2 = var_39_0:getHeroByTableID(var_39_1)
				local var_39_3 = var_39_2:getTableID()
				local var_39_4 = var_0_6:afterAwakenID(var_37_1)
				local var_39_5 = var_39_2:getZhandouli()

				var_39_2:setTableID(var_0_6:afterAwakenID(var_37_1))

				var_39_2.skillLev_[xyd.SKILL_INDEX.Awake] = xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake] + 1

				local var_39_6 = {
					oldHeroID = var_39_3,
					newHeroID = var_39_4,
					oldHeroForce = var_39_5
				}

				xyd.WindowManager.get():openWindow("awake_hero_wnd", var_39_6)
			end
		end)
	end
end

function var_0_0.finishHeroTwiceAwake(arg_40_0)
	arg_40_0:generateEffect():play(function()
		local var_41_0 = arg_40_0.tableID

		arg_40_0.task:getTaskReward(arg_40_0.tableID, xyd.TaskType.AWAKE, function(arg_42_0)
			if arg_42_0 == xyd.error.OK then
				local var_42_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
				local var_42_1 = var_0_6:beforeAwakenID(var_41_0)

				var_42_0:getHeroByTableID(var_42_1).skillLev_[xyd.SKILL_INDEX.AwakeTwice] = xyd.SKILL_EXTRA[xyd.SKILL_INDEX.AwakeTwice] + 1
			end
		end)
	end, false)
end

function var_0_0.finishPetAwake(arg_43_0)
	local var_43_0 = var_0_6:sufMissionID(arg_43_0.tableID)

	if var_43_0 and var_43_0 > 0 then
		arg_43_0:generateEffect():play(function()
			arg_43_0.task:getTaskReward(arg_43_0.tableID, xyd.TaskType.AWAKE)
		end, false)
	else
		local var_43_1 = arg_43_0.tableID

		arg_43_0.task:getTaskReward(var_43_1, xyd.TaskType.AWAKE, function(arg_45_0)
			if arg_45_0 == xyd.error.OK then
				local var_45_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
				local var_45_1 = var_0_6:beforeAwakenID(var_43_1)
				local var_45_2 = var_45_0:getPetByTableID(var_45_1)
				local var_45_3 = var_45_2:getTableID()
				local var_45_4 = var_0_6:afterAwakenID(var_43_1)
				local var_45_5 = var_45_2:getZhandouli()

				var_45_2:setTableID(var_0_6:afterAwakenID(var_43_1))

				var_45_2.skillLev_[xyd.SKILL_INDEX.Awake] = xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake] + 1

				local var_45_6 = {
					oldHeroID = var_45_3,
					newHeroID = var_45_4,
					oldHeroForce = var_45_5
				}

				var_45_6.isPet = true

				xyd.WindowManager.get():openWindow("awake_complete", var_45_6)
			end
		end)
	end
end

function var_0_0.generateEffect(arg_46_0)
	local var_46_0 = 1006
	local var_46_1 = 414
	local var_46_2 = display.newClippingRegionNode(cc.rect(0, 0, var_46_0, var_46_1))

	var_46_2:setAnchorPoint(0, 0)
	var_46_2:setPosition(0, 12)

	local var_46_3 = var_0_10 .. ".json"
	local var_46_4 = var_0_10 .. ".atlas"
	local var_46_5 = var_0_4.new(var_46_3, var_46_4, 1)

	var_46_5:addTo(var_46_2)
	var_46_5:setAnchorPoint(0, 0)
	var_46_5:setPosition(var_46_0 / 2 - 90, var_46_1 / 2 - 60)
	var_46_2:addTo(arg_46_0:background())

	return var_46_5
end

return var_0_0
