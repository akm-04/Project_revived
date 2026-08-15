local var_0_0 = class("TeamCreateWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc.teamIcons[1]

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:nodeByName("name_words_text"):setString(var_0_3:translation("GUILD_NAME") .. var_0_3:translation("COLON"))
	arg_3_0:nodeByName("icon_text"):setString(var_0_3:translation("TEAM_ICON_TITLE") .. var_0_3:translation("COLON"))
	arg_3_0:nodeByName("cost_text"):setString(var_0_3:translation("CREATE_COST"))
	arg_3_0:nodeByName("change_text"):setString(var_0_3:translation("SHE_TUAN_TEXT_46"))
	arg_3_0:nodeByName("create_btn_text"):setString(var_0_3:translation("SHE_TUAN_TEXT_40"))

	local var_3_0 = var_0_2.new({
		size = 718
	})

	var_3_0:addTo(arg_3_0:nodeByName("line1"))
	var_3_0:setAnchorPoint(0, 0.5)

	local var_3_1 = var_0_2.new({
		size = 718
	})

	var_3_1:addTo(arg_3_0:nodeByName("line2"))
	var_3_1:setAnchorPoint(0, 0.5)
	arg_3_0:updateIcon()

	local var_3_2 = xyd.tables.misc.guildCreateDiamond

	arg_3_0:nodeByName("create_bottom_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("create_bottom_btn"), arg_4_1)

		arg_3_0.teamName = arg_3_0:nodeByName("name_text"):getString()

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_4_0, var_4_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.FILTER_WORD):warningStrGsub(arg_3_0.teamName)

			if arg_3_0.teamName == "" then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_3:translation("TEAM_INPUT_NAME_REQUIST_ALERT"), nil, nil, nil, arg_3_0.colorMode)
			elseif var_4_1 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_3:translation("INPUT_WITH_BAD_WORDS"), nil, nil, nil, arg_3_0.colorMode)
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("TEAM_CREATE_ALERT"), function()
					local var_5_0 = {
						icon_frame = 0,
						name = arg_3_0.teamName,
						icon = arg_3_0.iconId
					}

					if var_3_2 > arg_3_0.player.crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
							local var_6_0 = {}

							var_6_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_6_0)
						end, nil, nil, arg_3_0.colorMode)
					else
						local var_5_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

						var_5_1:createTeam(var_5_0, function(arg_7_0)
							if arg_7_0 == xyd.error.OK then
								var_5_1:loadSelfGuild(function(arg_8_0)
									xyd.WindowManager.get():openWindow("team")
									xyd.WindowManager.get():closeWindow(arg_3_0)
									xyd.WindowManager.get():closeWindow("team_main")

									return true
								end)
							end
						end)
					end
				end, nil, 0, arg_3_0.colorMode)
			end
		end
	end)
	arg_3_0:nodeByName("change_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("change_btn"), arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("team_create_icon")
		end
	end)
	arg_3_0.iconContainerNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			return true
		elseif arg_10_0.name == "ended" then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("team_create_icon")
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.TEAM_ICON_REFRESH, function(arg_11_0)
		arg_3_0:updateIcon(arg_11_0.params)
	end)
end

function var_0_0.updateIcon(arg_12_0, arg_12_1)
	if arg_12_1 == nil then
		arg_12_1 = var_0_4
		arg_12_0.iconId = var_0_4
	end

	local var_12_0 = "images/icon/skill_icon/" .. arg_12_1 .. "_icon.png"
	local var_12_1 = arg_12_0:nodeByName("icon_container")
	local var_12_2 = xyd.SpriteLoader.new(var_12_0, nil, extra_params, xyd.DefaultImageType.SKILL_ICON)
	local var_12_3 = var_12_1:getContentSize()

	if not var_12_2 then
		var_12_2 = xyd.AssetLoader.get():loadSprite("images/icon/skill_icon/" .. var_0_4 .. "_icon.png")
	else
		arg_12_0.iconId = arg_12_1
	end

	local var_12_4 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")
	local var_12_5 = cc.ClippingNode:create()

	var_12_5:setStencil(var_12_4)
	var_12_5:setInverted(false)
	var_12_5:setAlphaThreshold(0)
	var_12_5:addChild(var_12_2)
	var_12_2:align(display.CENTER, var_12_3.width / 2, var_12_3.height / 2)
	var_12_2:scale(var_12_3.width / var_12_2:getWidth())
	var_12_4:addTo(var_12_1, -1)
	var_12_4:align(display.CENTER, var_12_3.width / 2, var_12_3.height / 2)
	var_12_4:scale((var_12_3.width - 3) / var_12_4:getWidth())
	var_12_1:addChild(var_12_5)

	local var_12_6 = xyd.AssetLoader.get():loadSprite("windows/corporation_window/bg_skill_icon.png")
	local var_12_7 = clone(var_12_6:getContentSize())

	xyd.displaySpriteOnContainer(var_12_6, var_12_1, true)

	local var_12_8 = display.newNode()

	var_12_8:setName("view")
	var_12_8:setContentSize(var_12_7)
	var_12_8:setAnchorPoint(cc.p(0, 0))
	var_12_8:setPosition(cc.p(0, 0))
	var_12_8:setScale(var_12_3.width / var_12_7.width, var_12_3.height / var_12_7.height)
	var_12_1:addChild(var_12_8)
end

function var_0_0.layout(arg_13_0)
	arg_13_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	local var_13_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_13_0, cc.rect(28, 28, 1, 1))

	arg_13_0.sidEditbox_ = ccui.EditBox:create(cc.size(arg_13_0:nodeByName("kuang"):getWidth(), arg_13_0:nodeByName("kuang"):getHeight()), var_13_0):align(display.CENTER, arg_13_0:nodeByName("kuang"):getX(), arg_13_0:nodeByName("kuang"):getY()):addTo(arg_13_0:nodeByName("container"))

	arg_13_0:nodeByName("name_text"):setString("")

	arg_13_0.teamName = ""

	arg_13_0.sidEditbox_:registerScriptEditBoxHandler(handler(arg_13_0, arg_13_0.inputboxEventHandler))
	arg_13_0.sidEditbox_:setInputFlag(3)
	arg_13_0:nodeByName("need_money_text"):setString(xyd.tables.misc.guildCreateDiamond)

	arg_13_0.iconContainerNode = cc.Node:create()

	arg_13_0.iconContainerNode:setContentSize(arg_13_0:nodeByName("icon_container"):getWidth(), arg_13_0:nodeByName("icon_container"):getHeight())
	arg_13_0.iconContainerNode:addTo(arg_13_0)
	arg_13_0.iconContainerNode:setAnchorPoint(cc.p(0, 0))
	arg_13_0.iconContainerNode:pos(arg_13_0:nodeByName("icon_container"):getX() + arg_13_0:nodeByName("container"):getX(), arg_13_0:nodeByName("icon_container"):getY() + arg_13_0:nodeByName("container"):getY())
	arg_13_0.iconContainerNode:setTouchEnabled(true)
end

function var_0_0.inputboxEventHandler(arg_14_0, arg_14_1)
	if arg_14_1 == "began" then
		local var_14_0 = arg_14_0:nodeByName("name_text"):getString()

		arg_14_0:nodeByName("name_text"):setString("")
		arg_14_0.sidEditbox_:setText(var_14_0)
	end

	if arg_14_1 == "return" then
		local var_14_1 = arg_14_0.sidEditbox_:getText()
		local var_14_2 = xyd.getTextLen(var_14_1)

		if var_14_1 ~= nil and var_14_2 <= xyd.tables.misc.guildNameMaxCharNum then
			arg_14_0:nodeByName("name_text"):setString(var_14_1)

			arg_14_0.teamName = var_14_1
		else
			local var_14_3 = string.format(var_0_3:translation("TEAM_INPUT_NAME_LIMMIT_ALERT"), tonumber(xyd.tables.misc.guildNameMaxCharNum))

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_14_3, nil, nil, nil, arg_14_0.colorMode)
		end

		arg_14_0.sidEditbox_:setText("")
		arg_14_0.sidEditbox_:setVisible(true)
	end
end

return var_0_0
