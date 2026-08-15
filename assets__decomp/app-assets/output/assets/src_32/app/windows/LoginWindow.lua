local var_0_0 = class("LoginWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = cc.Director:getInstance():getVisibleSize()
local var_0_3 = (var_0_2.width - xyd.STAGE_WIDTH) / 2
local var_0_4 = (var_0_2.height - xyd.STAGE_HEIGHT) / 2

function var_0_0.willOpen(arg_1_0, arg_1_1)
	display.removeUnusedSpriteFrames()

	local var_1_0 = arg_1_0:nodeByName("login_container")

	arg_1_0.isSDKLogin = arg_1_1.isSDKLogin
	arg_1_0.sid = arg_1_1.sid
	arg_1_0.token = arg_1_1.token

	if xyd.db.meta.regionID then
		arg_1_0.currentRegion = {
			region_id = xyd.db.meta.regionID,
			name = xyd.db.meta.regionName
		}
		arg_1_0.lastLogin = clone(arg_1_0.currentRegion)
	end

	arg_1_0:nodeByName("region_change_text"):setString(var_0_1:translation("CLICKED_CHANGE_REGION"))
	arg_1_0:nodeByName("region_change_text"):enableOutline(cc.c4b(37, 37, 37, 255), 2)

	arg_1_0.regionBtn = arg_1_0:nodeByName("region_button")

	arg_1_0.regionBtn:setTouchSwallowEnabled(true)
	arg_1_0:nodeByName("sid_field_bg"):setTouchSwallowEnabled(false)
	arg_1_0:nodeByName("region_text"):enableOutline(cc.c4b(37, 37, 37, 255), 2)
	arg_1_0:nodeByName("sid_txt"):enableOutline(cc.c4b(37, 37, 37, 255), 2)

	if xyd.db.meta.regionID > 0 then
		arg_1_0:nodeByName("region_text"):setString(string.format(var_0_1:translation("REGION_QU_NAME"), xyd.db.meta.regionID, xyd.db.meta.regionName or ""))
		arg_1_0:requestAnnounce_()
	else
		local var_1_1 = {}

		if arg_1_0.isSDKLogin then
			var_1_1.sid = arg_1_0.sid
			var_1_1.login_token = arg_1_0.token
		end

		xyd.Backend.get():request(xyd.mid.LOAD_USER_REGIONS, var_1_1, function(arg_2_0, arg_2_1)
			if arg_2_0 == xyd.error.OK then
				local var_2_0 = arg_2_1.regions

				if not var_2_0 then
					return
				end

				table.sort(var_2_0, function(arg_3_0, arg_3_1)
					if arg_3_0.region_id > arg_3_1.region_id then
						return true
					end
				end)

				local var_2_1

				if xyd.isDebug() then
					var_2_1 = var_2_0[2]
				else
					var_2_1 = var_2_0[4]
				end

				arg_1_0:nodeByName("region_text"):setString(string.format(var_0_1:translation("REGION_QU_NAME"), var_2_1.region_id, var_2_1.name or ""))

				arg_1_0.currentRegion = {
					region_id = var_2_1.region_id,
					name = var_2_1.name
				}
				arg_1_0.lastLogin = clone(arg_1_0.currentRegion)

				if not arg_2_1.players or not next(arg_2_1.players) then
					arg_1_0:dispatchEvent({
						name = xyd.event.LOGIN,
						sid = arg_1_0.sid,
						region = arg_1_0.currentRegion
					})
				else
					arg_1_0:requestAnnounce_()
				end
			end
		end)
	end

	if not arg_1_0.isSDKLogin then
		xyd.nodeEventSample(arg_1_0.regionBtn, {
			scale = 1
		}, function(arg_4_0)
			local var_4_0 = xyd.tables.sound:getSound("ui_button_click")

			if #arg_1_0:nodeByName("sid_txt"):getString() then
				xyd.Backend.get():request(xyd.mid.LOAD_USER_REGIONS, {
					sid = arg_1_0:nodeByName("sid_txt"):getString()
				}, function(arg_5_0, arg_5_1)
					if arg_5_0 == xyd.error.OK then
						local var_5_0 = arg_5_1.regions

						if var_5_0 ~= nil then
							table.sort(var_5_0, function(arg_6_0, arg_6_1)
								if arg_6_0.region_id > arg_6_1.region_id then
									return true
								end
							end)
							xyd.WindowManager.get():openWindow("region", {
								userRegions = arg_5_1,
								lastLogin = arg_1_0.lastLogin,
								recommendRegion = var_5_0[1]
							})
						end
					end
				end)
			else
				print("please input your account and select a region first!")
			end
		end)

		local var_1_2 = "windows/login/transparent.png"

		xyd.AssetLoader.get():loadSprite(var_1_2, cc.rect(28, 28, 1, 1))

		arg_1_0.sidEditbox_ = ccui.EditBox:create(cc.size(400, 30), var_1_2):align(display.CENTER, 640, 57):addTo(var_1_0)

		arg_1_0:nodeByName("sid_txt"):setString(xyd.db.meta.sid)
		arg_1_0.sidEditbox_:registerScriptEditBoxHandler(handler(arg_1_0, arg_1_0.inputboxEventHandler))
		arg_1_0.sidEditbox_:setInputFlag(3)
	else
		xyd.nodeEventSample(arg_1_0.regionBtn, {
			scale = 1
		}, function(arg_7_0)
			local var_7_0 = xyd.tables.sound:getSound("ui_button_click")

			audio.playSound(var_7_0, false)
			xyd.Backend.get():request(xyd.mid.LOAD_USER_REGIONS, {
				login_token = arg_1_0.token,
				sid = arg_1_0.sid
			}, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					local var_8_0 = arg_8_1.regions

					if var_8_0 ~= nil then
						table.sort(var_8_0, function(arg_9_0, arg_9_1)
							if arg_9_0.region_id > arg_9_1.region_id then
								return true
							end
						end)
						xyd.WindowManager.get():openWindow("region", {
							userRegions = arg_8_1,
							lastLogin = arg_1_0.lastLogin,
							recommendRegion = var_8_0[1]
						})
					end
				end
			end)
		end)
		arg_1_0:nodeByName("sid_txt"):setVisible(false)
		arg_1_0:nodeByName("sid_field_bg"):setVisible(false)
	end

	arg_1_0:nodeByName("lb_start"):runAction(cc.RepeatForever:create(cc.Sequence:create({
		cc.FadeTo:create(2, 50),
		cc.FadeTo:create(2, 255)
	})))
end

function var_0_0.requestAnnounce_(arg_10_0)
	xyd.Backend.get():request(7, {}, function(arg_11_0, arg_11_1)
		if arg_11_1 == nil or arg_11_1.contents == nil then
			return
		end

		local var_11_0 = json.decode(arg_11_1.contents)

		if var_11_0 == nil then
			return
		end

		if arg_11_0 == xyd.error.OK then
			for iter_11_0, iter_11_1 in pairs(var_11_0.contents) do
				if iter_11_1 ~= nil then
					xyd.WindowManager.get():openWindow("announce", var_11_0)

					return
				end
			end
		end
	end)
end

function var_0_0.inputboxEventHandler(arg_12_0, arg_12_1)
	if arg_12_1 == "return" then
		local var_12_0 = arg_12_0.sidEditbox_:getText()

		arg_12_0:nodeByName("sid_txt"):setString(var_12_0)
		arg_12_0.sidEditbox_:setText("")
	elseif arg_12_1 == "began" then
		local var_12_1 = arg_12_0:nodeByName("sid_txt"):getString()

		arg_12_0.sidEditbox_:setText(var_12_1)
		arg_12_0:nodeByName("sid_txt"):setString("")
	end
end

function var_0_0.didOpen(arg_13_0, arg_13_1)
	arg_13_0.loginLayer = display.newNode()

	arg_13_0.loginLayer:setContentSize(1280, 720)
	arg_13_0.loginLayer:setAnchorPoint(0, 0)
	arg_13_0.loginLayer:setPosition(0, 0)
	arg_13_0.loginLayer:addTo(arg_13_0)
	arg_13_0.loginLayer:setTouchEnabled(true)
	arg_13_0.loginLayer:setTouchSwallowEnabled(false)
	arg_13_0.loginLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.x and arg_14_0.y and arg_14_0.x >= 390 + var_0_3 and arg_14_0.x <= 890 + var_0_3 and arg_14_0.y <= 200 + var_0_4 then
			return
		end

		if arg_14_0.name == "ended" then
			if not arg_13_0.isSDKLogin then
				local var_14_0 = xyd.tables.sound:getSound("ui_button_click")

				audio.playSound(var_14_0, false)

				if #arg_13_0:nodeByName("sid_txt"):getString() > 0 and arg_13_0.currentRegion then
					arg_13_0:dispatchEvent({
						name = xyd.event.LOGIN,
						sid = arg_13_0:nodeByName("sid_txt"):getString(),
						region = arg_13_0.currentRegion
					})
				else
					print("please input your account and select a region first!")
				end
			else
				local var_14_1 = xyd.tables.sound:getSound("ui_button_click")

				audio.playSound(var_14_1, false)

				if arg_13_0.currentRegion then
					arg_13_0:dispatchEvent({
						name = xyd.event.LOGIN,
						sid = arg_13_0.sid,
						region = arg_13_0.currentRegion
					})
				else
					print("please input your account and select a region first!")
				end
			end
		end

		return true
	end)
	xyd.EventDispatcher.get():addEventListener(xyd.event.REGION_SELECTED, function(arg_15_0)
		local var_15_0 = arg_15_0.params.region

		if var_15_0 then
			arg_13_0:nodeByName("region_text"):setString(string.format(var_0_1:translation("REGION_QU_NAME"), var_15_0.region_id, var_15_0.name))

			arg_13_0.currentRegion = var_15_0
		end
	end)
	arg_13_0:playMusic()
end

function var_0_0.playMusic(arg_16_0)
	if not audio.isMusicPlaying() then
		audio.playMusic("sound/loading.ogg", true)
	end
end

return var_0_0
