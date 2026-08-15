local var_0_0 = class("LoadingScene", import("app.common.ui.BaseScene"))
local var_0_1 = "login"
local var_0_2 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	if arg_1_1 then
		arg_1_0.changeAccount = true
	end
end

function var_0_0.onEnterTransitionFinish(arg_2_0)
	var_0_0.super.onEnterTransitionFinish(arg_2_0)
	arg_2_0:setupModels_()
	xyd.db.init()
	arg_2_0:showBackground_()

	if (device.platform == "ios" or device.platform == "android") and not xyd.isDebug() then
		arg_2_0:showLoginSdkWindow()
	else
		arg_2_0:showLoginWindow_()
	end
end

function var_0_0.onExit(arg_3_0)
	var_0_0.super.onExit(arg_3_0)
end

function var_0_0.setupModels_(arg_4_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)
	xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	xyd.ModelManager.get():loadModel(xyd.ModelType.INVITE_FRIENDS_INFOS)
end

function var_0_0.showBackground_(arg_5_0)
	local var_5_0 = arg_5_0:getContentSize()

	if arg_5_0.background_ == nil then
		local var_5_1 = ""

		if xyd.getChannel() ~= 0 then
			var_5_1 = "_" .. xyd.getChannel()
		end

		arg_5_0.clippingNode = display.newClippingRegionNode()

		arg_5_0.clippingNode:setClippingRegion(cc.rect(0, 0, var_5_0.width, var_5_0.height))
		arg_5_0.clippingNode:addTo(arg_5_0, -1)

		arg_5_0.background_ = cc.Sprite:create("images/startup" .. var_5_1 .. ".png"):align(display.CENTER, 0.5 * var_5_0.width, 0.5 * var_5_0.height):addTo(arg_5_0.clippingNode)

		if LANGUAGE_VERSION ~= xyd.LanguageVersion.CN then
			arg_5_0.chatShowHandle = var_0_2.performWithDelayGlobal(function()
				local function var_6_0(arg_7_0)
					local var_7_0 = arg_7_0 .. ".json"
					local var_7_1 = arg_7_0 .. ".atlas"
					local var_7_2 = sp.SkeletonAnimation:create(var_7_0, var_7_1, 1)

					var_7_2:setAnchorPoint(arg_5_0:point(0.5, 0.5))
					var_7_2:setAnimation(0, "texiao", true)
					var_7_2:addTo(arg_5_0, -1)

					return var_7_2
				end

				arg_5_0.background_:setVisible(false)

				local var_6_1 = "skeletons/ui_effect/fengmian/fengmian"

				arg_5_0.spring_loadingEffect01 = var_6_0(var_6_1)
			end, 0.1)
		end

		local var_5_2 = "effects/common_effect_logo_spin"
		local var_5_3 = var_5_2 .. ".json"
		local var_5_4 = var_5_2 .. ".atlas"

		arg_5_0.logoEffect_ = sp.SkeletonAnimation:create(var_5_3, var_5_4, 1)

		arg_5_0.logoEffect_:setAnchorPoint(arg_5_0:point(0.5, 0.5))
		arg_5_0.logoEffect_:setPosition(arg_5_0:point(0.84 * var_5_0.width, 0.83 * var_5_0.height))
		arg_5_0.logoEffect_:setAnimation(0, "texiao", true)
		arg_5_0.logoEffect_:addTo(arg_5_0)
	end

	if arg_5_0.versionLabel_ == nil then
		local var_5_5 = 10

		arg_5_0.versionLabel_ = xyd.AssetLoader.get():loadLabel({
			size = 18,
			text = string.format("v%s", xyd.version())
		}):align(display.RIGHT_BOTTOM, var_5_0.width - var_5_5, var_5_5):addTo(arg_5_0)

		arg_5_0.versionLabel_:enableOutline(cc.c4b(20, 20, 20, 255), 2)
	end
end

function var_0_0.setMessage_(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_0.messageLabel_ == nil then
		local var_8_0 = arg_8_0:getContentSize()

		arg_8_0.messageLabel_ = xyd.AssetLoader.get():loadLabel({
			size = 32
		}):align(display.CENTER, 0.5 * var_8_0.width, 150):addTo(arg_8_0)

		arg_8_0.messageLabel_:enableShadow()

		arg_8_0.messageLabel_.npoint = 3
		arg_8_0.messageLabel_.pointContainer = display.newNode():addTo(arg_8_0)
		arg_8_0.messageLabel_.points = {}

		local var_8_1 = 5
		local var_8_2 = 0

		for iter_8_0 = 1, arg_8_0.messageLabel_.npoint do
			local var_8_3 = xyd.AssetLoader.get():loadSprite("update_p.png"):align(display.CENTER, var_8_2, 0):addTo(arg_8_0.messageLabel_.pointContainer)

			table.insert(arg_8_0.messageLabel_.points, var_8_3)

			var_8_2 = var_8_2 + var_8_3:getContentSize().width + var_8_1
		end
	end

	arg_8_0.messageLabel_.pointContainer:stopAllActions()
	arg_8_0.messageLabel_.pointContainer:setVisible(false)
	arg_8_0.messageLabel_:setString(arg_8_1)

	if arg_8_2 then
		local var_8_4 = arg_8_0.messageLabel_:getBoundingBox()
		local var_8_5 = 0

		local function var_8_6(arg_9_0)
			local var_9_0 = arg_9_0 % (arg_8_0.messageLabel_.npoint + 1)

			for iter_9_0 = 1, arg_8_0.messageLabel_.npoint do
				arg_8_0.messageLabel_.points[iter_9_0]:setVisible(iter_9_0 <= var_9_0)
			end
		end

		arg_8_0.messageLabel_.pointContainer:setVisible(true)
		arg_8_0.messageLabel_.pointContainer:pos(var_8_4.x + var_8_4.width + 12, var_8_4.y + 5)
		var_8_6(var_8_5)
		arg_8_0.messageLabel_.pointContainer:schedule(xyd.scb(arg_8_0, function()
			var_8_5 = var_8_5 + 1

			var_8_6(var_8_5)
		end), 1)
	end
end

function var_0_0.showLoginWindow_(arg_11_0)
	xyd.WindowManager.get():openWindow(var_0_1, {
		isSDKLogin = false
	}, function(arg_12_0)
		if arg_12_0 == nil then
			return
		end

		print("add login event ----- 4")
		cc.EventProxy.new(arg_12_0, arg_12_0):addEventListener(xyd.event.LOGIN, handler(arg_11_0, arg_11_0.login_))
	end)
end

function var_0_0.showLoginSdkWindow(arg_13_0)
	arg_13_0:sdkInit()

	if device.platform == "android" then
		local function var_13_0()
			xyd.LoadingProxy.get():addLoading()
		end

		local function var_13_1(arg_15_0)
			xyd.LoadingProxy.get():removeLoading()

			arg_13_0.token = arg_15_0

			local var_15_0 = xyd.WindowManager.get():getWindow(var_0_1)

			if var_15_0 then
				var_15_0.token = arg_15_0
			end
		end

		local function var_13_2(arg_16_0)
			xyd.WindowManager.get():openWindow(var_0_1, {
				isSDKLogin = true,
				sid = arg_16_0,
				token = arg_13_0.token
			}, function(arg_17_0)
				if arg_17_0 == nil then
					return
				end

				print("add login event ------ 1 ")
				cc.EventProxy.new(arg_17_0, arg_17_0):addEventListener(xyd.event.LOGIN, handler(arg_13_0, arg_13_0.login_))
			end)
		end

		local var_13_3 = "org/cocos2dx/lua/AppActivity"
		local var_13_4 = "xydNewLogin"
		local var_13_5 = {
			var_13_1,
			var_13_2,
			var_13_0
		}
		local var_13_6 = "(III)V"
		local var_13_7, var_13_8 = luaj.callStaticMethod(var_13_3, var_13_4, var_13_5, var_13_6)
	elseif device.platform == "ios" then
		local function var_13_9(arg_18_0)
			arg_13_0.token = arg_18_0.token

			if arg_18_0.is_success then
				xyd.WindowManager.get():openWindow(var_0_1, {
					isSDKLogin = true,
					sid = arg_18_0.sid,
					token = arg_13_0.token
				}, function(arg_19_0)
					if arg_19_0 == nil then
						return
					end

					print("add login event ----- 2")
					cc.EventProxy.new(arg_19_0, arg_19_0):addEventListener(xyd.event.LOGIN, handler(arg_13_0, arg_13_0.login_))
				end)
			end
		end

		luaoc.callStaticMethod("SdkIOS", "sdkShowLogin", {
			callback = var_13_9
		})
	end
end

function var_0_0.selectServer(arg_20_0, arg_20_1)
	if device.platform == "android" then
		local var_20_0 = "org/cocos2dx/lua/AppActivity"
		local var_20_1 = "xydSelectServer"
		local var_20_2 = {
			arg_20_1
		}
		local var_20_3 = "(I)V"
		local var_20_4, var_20_5 = luaj.callStaticMethod(var_20_0, var_20_1, var_20_2, var_20_3)
	elseif device.platform == "ios" then
		luaoc.callStaticMethod("SdkIOS", "enterServer", {
			server_id = arg_20_1
		})
	end
end

function var_0_0.directlyLogin(arg_21_0)
	if device.platform == "android" then
		arg_21_0:sdkInit()

		local function var_21_0(arg_22_0)
			arg_21_0.token = arg_22_0
		end

		local function var_21_1(arg_23_0)
			xyd.WindowManager.get():openWindow(var_0_1, {
				isSDKLogin = true,
				sid = arg_23_0
			}, function(arg_24_0)
				if arg_24_0 == nil then
					return
				end

				print("add login event ----- 3")
				cc.EventProxy.new(arg_24_0, arg_24_0):addEventListener(xyd.event.LOGIN, handler(arg_21_0, arg_21_0.login_))
			end)
		end

		local var_21_2 = "org/cocos2dx/lua/AppActivity"
		local var_21_3 = "xydAutoLogin"
		local var_21_4 = {
			var_21_0,
			var_21_1
		}
		local var_21_5 = "(II)V"
		local var_21_6, var_21_7 = luaj.callStaticMethod(var_21_2, var_21_3, var_21_4, var_21_5)
	elseif device.platform == "ios" then
		-- block empty
	end
end

function var_0_0.sdkInit(arg_25_0)
	if device.platform == "android" then
		-- block empty
	elseif device.platform == "ios" then
		local var_25_0 = luaoc.callStaticMethod("SdkIOS", "sdkInit")
	end
end

local function var_0_3(arg_26_0, arg_26_1)
	if arg_26_0.main ~= arg_26_1.main then
		return arg_26_0.main - arg_26_1.main
	elseif arg_26_0.mid ~= arg_26_1.mid then
		return arg_26_0.mid - arg_26_1.mid
	else
		return arg_26_0.sub - arg_26_1.sub
	end
end

local function var_0_4(arg_27_0)
	local var_27_0, var_27_1, var_27_2 = arg_27_0:match("(%d+)%.(%d+)%.(%d+)")
	local var_27_3 = {
		main = tonumber(var_27_0 or 0),
		mid = tonumber(var_27_1 or 0),
		sub = tonumber(var_27_2 or 0)
	}

	setmetatable(var_27_3, {
		__tostring = function()
			return arg_27_0
		end
	})

	return var_27_3
end

function var_0_0.login_(arg_29_0, arg_29_1)
	if arg_29_0.isLoggingIn_ then
		return
	end

	local var_29_0 = {
		sid = arg_29_1.sid,
		login_token = arg_29_0.token,
		region = arg_29_1.region.region_id,
		is_test = arg_29_1.is_test,
		v_ = xyd.version(),
		app_v = xyd.getVersionName(),
		platform = cc.Application:getInstance():getTargetPlatform()
	}

	print("------- login -------- ")
	dump(var_29_0)
	xyd.Backend.get():request(xyd.mid.RETRIEVE_TOKEN, var_29_0, xyd.scb(arg_29_0, function(arg_30_0, arg_30_1)
		if arg_30_0 == xyd.error.OK then
			local var_30_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

			arg_29_0:selectServer(arg_29_1.region.region_id)

			arg_29_0.isNew = tonumber(arg_30_1.is_new)
			var_30_0.storyABTest_ = tonumber(arg_30_1.story_type or xyd.storyABTest.Battle)
			var_30_0.isDebug = tonumber(arg_30_1.is_debug) or 0
			var_30_0.isOldTop = tonumber(arg_30_1.is_old_top) or 0

			arg_29_0:updateMeta_(arg_29_1.sid, arg_29_1.region)
			xyd.StoryData.get():updateDataFromStorage()
			xyd.ModelManager.get():loadModel(xyd.ModelType.MESSAGE_MANAGER)
			audio.stopMusic(true)

			if arg_29_0.isNew ~= 1 then
				display.replaceScene(xyd.MainScene.new())
			elseif var_30_0:getStoryABTestType() == xyd.storyABTest.Movie then
				if device.platform == "ios" then
					local var_30_1 = var_0_4(xyd.getVersionName() or "")
					local var_30_2 = var_0_4("1.8.0")

					if var_0_3(var_30_1, var_30_2) >= 0 then
						xyd.WindowManager.get():openWindow("start_story")
					else
						local var_30_3 = {
							herosA = xyd.tables.battleConfig.storyFormationA,
							herosB = {
								xyd.tables.battleConfig.storyFormationB
							},
							campaignType = xyd.CampaignType.STORY
						}

						display.replaceScene(xyd.BattleStoryScene.new(var_30_3))
					end
				elseif device.platform == "android" then
					xyd.WindowManager.get():openWindow("start_story")
				else
					display.replaceScene(xyd.MainScene.new())
				end
			else
				var_30_0.readPicNotice = 1

				xyd.WindowManager.get():openWindow("cg_show", {
					open_story_id = 1001,
					effect_type = 1,
					callback = function()
						local var_31_0 = {
							herosA = xyd.tables.battleConfig.storyFormationA,
							herosB = {
								xyd.tables.battleConfig.storyFormationB
							},
							campaignType = xyd.CampaignType.STORY
						}

						display.replaceScene(xyd.BattleStoryScene.new(var_31_0))
					end
				})
			end
		else
			print("login fail")

			if arg_30_1 and arg_30_1.error_msg ~= "" then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, arg_30_1.error_msg, function()
					xyd.exitProgram()
				end)
			elseif arg_30_1 and arg_30_1.error_code ~= 20018 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, xyd.tables.translation:translation("LOGIN_FAIL"))
			end
		end
	end))
end

function var_0_0.updateMeta_(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if xyd.db.meta.playerID ~= var_33_0.playerID then
		if xyd.db.meta.playerID > 0 then
			xyd.db.clearGameData()
		end

		xyd.db.meta.sid = arg_33_1
		xyd.db.meta.regionID = arg_33_2.region_id or 0
		xyd.db.meta.regionName = arg_33_2.name or ""
		xyd.db.meta.playerID = var_33_0.playerID
		xyd.db.meta.playerName = var_33_0.playerName

		xyd.db.meta:persist()
	end
end

function var_0_0.point(arg_34_0, arg_34_1, arg_34_2)
	return {
		x = arg_34_1,
		y = arg_34_2
	}
end

return var_0_0
