local var_0_0 = class("TeamSettingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc.teamLevelMax
local var_0_5 = xyd.tables.misc.teamLevelMin
local var_0_6 = xyd.tables.misc.teamIcons[1]

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:nodeByName("close_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("close_btn"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_4_0, false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)

	local function var_3_0(arg_5_0, arg_5_1)
		if arg_5_0 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)

			if arg_5_1 == true then
				arg_3_0.team_type = arg_3_0.team_type + 1
			else
				arg_3_0.team_type = arg_3_0.team_type - 1
			end

			if arg_3_0.team_type == 3 then
				arg_3_0.team_type = 0
			elseif arg_3_0.team_type == -1 then
				arg_3_0.team_type = 2
			end

			arg_3_0:updateType()
		end
	end

	arg_3_0:nodeByName("left_1_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("left_1_btn"), arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			var_3_0(arg_6_1, false)
		end
	end)
	arg_3_0:nodeByName("right_1_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("right_1_btn"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			var_3_0(arg_7_1, true)
		end
	end)
	arg_3_0:nodeByName("left_2_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("left_2_btn"), arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:changeLevel(arg_8_1, false)
		end
	end)
	arg_3_0:nodeByName("right_2_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("right_2_btn"), arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:changeLevel(arg_9_1, true)
		end
	end)
	arg_3_0:nodeByName("change_icon_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("change_icon_btn"), arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("team_create_icon")
		end
	end)
	arg_3_0:nodeByName("change_kuang_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("change_kuang_btn"), arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_3:translation("FUNCTION_NOT_OPEN"), nil, nil, nil, arg_3_0.colorMode)
		end
	end)

	arg_3_0.iconFrame = 0

	arg_3_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("ok_btn"), arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			params_ = {
				icon = tonumber(arg_3_0.iconId),
				icon_frame = arg_3_0.iconFrame,
				min_allow_level = arg_3_0.min_level,
				apply_type = arg_3_0.team_type,
				name = arg_3_0.team_name
			}

			arg_3_0.guild:settingTeam(params_, function(arg_13_0)
				if arg_13_0 == xyd.error.OK then
					return true
				end
			end)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0.iconContainerNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" then
			return true
		elseif arg_14_0.name == "ended" then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("team_create_icon")
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.TEAM_ICON_REFRESH, function(arg_15_0)
		arg_3_0:updateIcon(arg_15_0.params)
	end)
end

function var_0_0.updateIcon(arg_16_0, arg_16_1)
	if arg_16_1 == nil then
		arg_16_1 = var_0_6
		arg_16_0.iconId = var_0_6
	end

	local var_16_0 = "images/icon/skill_icon/" .. arg_16_1 .. "_icon.png"
	local var_16_1 = arg_16_0:nodeByName("icon_container")
	local var_16_2 = xyd.AssetLoader.get():loadSprite(var_16_0)
	local var_16_3 = var_16_1:getContentSize()

	if not var_16_2 then
		var_16_2 = xyd.AssetLoader.get():loadSprite("images/icon/skill_icon/" .. var_0_6 .. "_icon.png")
	else
		arg_16_0.iconId = arg_16_1
	end

	local var_16_4 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")
	local var_16_5 = cc.ClippingNode:create()

	var_16_5:setStencil(var_16_4)
	var_16_5:setInverted(false)
	var_16_5:setAlphaThreshold(0)
	var_16_5:addChild(var_16_2)
	var_16_2:align(display.CENTER, var_16_3.width / 2, var_16_3.height / 2)
	var_16_2:scale(var_16_3.width / var_16_2:getWidth())
	var_16_4:addTo(var_16_1, -1)
	var_16_4:align(display.CENTER, var_16_3.width / 2, var_16_3.height / 2)
	var_16_4:scale((var_16_3.width - 3) / var_16_4:getWidth())
	var_16_1:addChild(var_16_5)

	local var_16_6 = xyd.getAvatarBorder(2)
	local var_16_7 = clone(var_16_6:getContentSize())

	xyd.displaySpriteOnContainer(var_16_6, var_16_1, true)

	local var_16_8 = display.newNode()

	var_16_8:setName("view")
	var_16_8:setContentSize(var_16_7)
	var_16_8:setAnchorPoint(cc.p(0, 0))
	var_16_8:setPosition(cc.p(0, 0))
	var_16_8:setScale(var_16_3.width / var_16_7.width, var_16_3.height / var_16_7.height)
	var_16_1:addChild(var_16_8)
end

function var_0_0.layout(arg_17_0)
	arg_17_0:nodeByName("level_text_1"):setString(var_0_3:translation("MIN_PLAYER_LEV") .. var_0_3:translation("COLON"))
	arg_17_0:nodeByName("type_text_1"):setString(var_0_3:translation("GUILD_TYPE") .. var_0_3:translation("COLON"))
	arg_17_0:nodeByName("name_text_1"):setString(var_0_3:translation("GUILD_NAME") .. var_0_3:translation("COLON"))
	arg_17_0:nodeByName("icon_text"):setString(var_0_3:translation("TEAM_ICON_TITLE") .. var_0_3:translation("COLON"))
	arg_17_0:nodeByName("title"):setString(var_0_3:translation("GUILD_SETTING"))
	arg_17_0:nodeByName("change_icon_text"):setString(var_0_3:translation("SHE_TUAN_TEXT_17"))
	arg_17_0:nodeByName("change_kuang_text"):setString(var_0_3:translation("SHE_TUAN_TEXT_18"))
	arg_17_0:nodeByName("change_name_text"):setString(var_0_3:translation("SHE_TUAN_TEXT_19"))
	arg_17_0:nodeByName("ok_text"):setString(var_0_3:translation("SHE_TUAN_TEXT_20"))

	arg_17_0.team_type = arg_17_0.guild.apply_type
	arg_17_0.min_level = arg_17_0.guild.min_lev
	arg_17_0.iconId = arg_17_0.guild.guild_icon
	arg_17_0.iconFrame = 0
	arg_17_0.team_name = arg_17_0.guild.guild_name

	arg_17_0:nodeByName("name_text"):setString(arg_17_0.team_name)
	arg_17_0:updateType()
	arg_17_0:changeLevel()
	arg_17_0:updateIcon(arg_17_0.iconId)

	local var_17_0 = var_0_2.new({
		size = 690
	})

	var_17_0:addTo(arg_17_0:nodeByName("line"))
	var_17_0:setAnchorPoint(0, 0.5)

	local var_17_1 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_17_1, cc.rect(28, 28, 1, 1))

	arg_17_0.sidEditbox_ = ccui.EditBox:create(cc.size(arg_17_0:nodeByName("on_bg_2"):getWidth() / 2, arg_17_0:nodeByName("on_bg_2"):getHeight()), var_17_1):align(display.CENTER, arg_17_0:nodeByName("on_bg_2"):getX(), arg_17_0:nodeByName("on_bg_2"):getY()):addTo(arg_17_0:nodeByName("container"))

	arg_17_0.sidEditbox_:registerScriptEditBoxHandler(handler(arg_17_0, arg_17_0.inputLevEventHandler))
	arg_17_0.sidEditbox_:setInputFlag(3)
	arg_17_0:nodeByName("change_name_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		xyd.buttonScaleAnim(arg_17_0:nodeByName("change_name_btn"), arg_18_1)

		if arg_18_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("team_setting_name", {
				name = arg_17_0.team_name,
				parent = arg_17_0
			})
		end
	end)

	arg_17_0.iconContainerNode = cc.Node:create()

	arg_17_0.iconContainerNode:setContentSize(arg_17_0:nodeByName("icon_container"):getWidth(), arg_17_0:nodeByName("icon_container"):getHeight())
	arg_17_0.iconContainerNode:addTo(arg_17_0)
	arg_17_0.iconContainerNode:setAnchorPoint(cc.p(0, 0))
	arg_17_0.iconContainerNode:pos(arg_17_0:nodeByName("icon_container"):getX() + arg_17_0:nodeByName("container"):getX(), arg_17_0:nodeByName("icon_container"):getY() + arg_17_0:nodeByName("container"):getY())
	arg_17_0.iconContainerNode:setTouchEnabled(true)
end

function var_0_0.updateTeamName(arg_19_0, arg_19_1)
	arg_19_0.team_name = arg_19_1

	arg_19_0:nodeByName("name_text"):setString(arg_19_0.team_name)
end

function var_0_0.inputLevEventHandler(arg_20_0, arg_20_1)
	if arg_20_1 == "changed" then
		local var_20_0 = arg_20_0.sidEditbox_:getText()

		if tonumber(var_20_0) ~= nil and tonumber(var_20_0) <= var_0_4 and tonumber(var_20_0) >= var_0_5 then
			arg_20_0.min_level = tonumber(var_20_0)

			arg_20_0:changeLevel()
		else
			local var_20_1 = string.format(var_0_3:translation("TEAM_LEVEL_RANGE"), var_0_5, var_0_4)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_20_1, nil, nil, nil, arg_20_0.colorMode)
		end
	elseif arg_20_1 == "began" then
		local var_20_2 = arg_20_0:nodeByName("level_num_text"):getString()

		arg_20_0.sidEditbox_:setText(var_20_2)
	elseif arg_20_1 == "return" then
		arg_20_0.sidEditbox_:setText("")
		arg_20_0.sidEditbox_:setVisible(true)
	end
end

function var_0_0.changeLevel(arg_21_0, arg_21_1, arg_21_2)
	if arg_21_1 == ccui.TouchEventType.ended then
		local var_21_0 = xyd.tables.sound:getSound("ui_close_window")

		audio.playSound(var_21_0, false)

		if arg_21_2 == true then
			if arg_21_0.min_level < var_0_4 then
				arg_21_0.min_level = arg_21_0.min_level + 1
			end
		elseif arg_21_0.min_level > var_0_5 then
			arg_21_0.min_level = arg_21_0.min_level - 1
		end

		arg_21_0:nodeByName("level_num_text"):setString(arg_21_0.min_level)
	elseif arg_21_1 == nil then
		arg_21_0:nodeByName("level_num_text"):setString(arg_21_0.min_level)
	end

	if arg_21_0.min_level == var_0_5 then
		arg_21_0:nodeByName("left_2_btn"):setEnabled(false)
	else
		arg_21_0:nodeByName("left_2_btn"):setEnabled(true)
	end

	if arg_21_0.min_level == var_0_4 then
		arg_21_0:nodeByName("right_2_btn"):setEnabled(false)
	else
		arg_21_0:nodeByName("right_2_btn"):setEnabled(true)
	end
end

function var_0_0.updateType(arg_22_0)
	if arg_22_0.team_type == 0 then
		arg_22_0:nodeByName("team_type_text"):setString(var_0_3:translation("TEAM_APPLY_TYPE_NEED"))
	elseif arg_22_0.team_type == 2 then
		arg_22_0:nodeByName("team_type_text"):setString(var_0_3:translation("TEAM_APPLY_TYPE_NO"))
	else
		arg_22_0:nodeByName("team_type_text"):setString(var_0_3:translation("TEAM_APPLY_TYPE_ALL"))
	end
end

return var_0_0
