xyd = xyd or {}
xyd.dbc = {}

local var_0_0 = require("cjson")
local var_0_1 = cc.Scene:create()
local var_0_2 = 4
local var_0_3 = 3
local var_0_4 = 0
local var_0_5 = 1
local var_0_6 = 2
local var_0_7 = 3
local var_0_8 = "http://119.81.215.217:9000/center/v1"
local var_0_9 = "http://119.81.215.217:9000/api/v1"
local var_0_10 = "http://xuemeien.carolgames.com:9000/center/v1"
local var_0_11 = xyd.versionUpdatePath .. ".download_infos"
local var_0_12 = "infos.xml"
local var_0_13 = "obbinfos.xml"
local var_0_14 = "atlases/update_ui.plist"
local var_0_15 = "fonts/main_font.ttf"
local var_0_16 = 0
local var_0_17 = 3
local var_0_18 = {
	"app.modules.loading_games.game01",
	"app.modules.loading_games.game02"
}
local var_0_19 = "version.json"
local var_0_20 = xyd.versionUpdatePath .. "download_version.json"
local var_0_21 = "__lazy__"
local var_0_22 = "__version_json_init__"
local var_0_23 = "__version_json_init_web_windows__"
local var_0_24 = (function(arg_1_0)
	local var_1_0 = {
		ctor = function()
			return
		end,
		__cname = arg_1_0
	}

	var_1_0.__ctype = 2
	var_1_0.__index = var_1_0

	function var_1_0.new(...)
		local var_3_0 = setmetatable({}, var_1_0)

		var_3_0.class = var_1_0

		var_3_0:ctor(...)

		return var_3_0
	end

	return var_1_0
end)("DownloadInfo")

function var_0_1.write2File(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = io.open(arg_4_2, "w")

	var_4_0:write(arg_4_1)
	var_4_0:close()
end

function var_0_1.readFromFile(arg_5_0, arg_5_1)
	return var_0_0.decode(cc.FileUtils:getInstance():getStringFromFile(arg_5_1))
end

function var_0_1.run(arg_6_0)
	arg_6_0:loadTranslations_()

	if xyd.dbc.downloadInfo == nil then
		xyd.dbc.downloadInfo = var_0_24.new()
		xyd.dbc.backDownloadInfo = var_0_24.new()

		print("xyd.dbc.backDownloadInfo is nil?:", xyd.dbc.backDownloadInfo == nil)
	end

	if not xyd.lazyFileManager then
		xyd.lazyFileManager = require("lazyFileManager")

		xyd.lazyFileManager:init()
	end

	local var_6_0 = var_0_20

	if cc.FileUtils:getInstance():isFileExist(var_6_0) then
		cc.FileUtils:getInstance():removeFile(var_6_0)
	end

	arg_6_0:setupScreen_()
	cc.SpriteFrameCache:getInstance():addSpriteFrames(var_0_14)
	arg_6_0:setupContentView_()
	arg_6_0:setupBackground_()

	if cc.Application:getInstance():getTargetPlatform() == var_0_16 then
		arg_6_0.source = "source"
	else
		arg_6_0.source = "src_64"
	end

	arg_6_0:registerSceneCallbacks_()

	if cc.Director:getInstance():getRunningScene() then
		cc.Director:getInstance():replaceScene(arg_6_0)
	else
		cc.Director:getInstance():runWithScene(arg_6_0)
	end
end

function var_0_1.onEnterTransitionFinish(arg_7_0)
	arg_7_0.packageInfos_ = cc.FileUtils:getInstance():getValueMapFromFile(var_0_12) or {}
	arg_7_0.obbInfos_ = cc.FileUtils:getInstance():getValueMapFromFile(var_0_13) or {}

	if cc.Application:getInstance():getTargetPlatform() == var_0_16 then
		var_0_8 = arg_7_0.packageInfos_.center_url
		var_0_9 = arg_7_0.packageInfos_.url

		arg_7_0:requestServerUrl_(var_0_8)
	else
		arg_7_0:requestServerUrl_(var_0_10)
	end
end

function var_0_1.onExit(arg_8_0)
	arg_8_0:setMessage_("", false)

	if arg_8_0.logo_ ~= nil then
		arg_8_0.logo_:unscheduleUpdate()
	end
end

function var_0_1.hideLabels(arg_9_0)
	if arg_9_0.messageLabel_ ~= nil then
		arg_9_0.messageLabel_:setVisible(false)
	end
end

function var_0_1.parseXmlPath(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_0:split(arg_10_1, "/")
	local var_10_1 = ""

	for iter_10_0, iter_10_1 in pairs(var_10_0) do
		if iter_10_0 ~= 1 then
			var_10_1 = var_10_1 .. "___"
		end

		var_10_1 = var_10_1 .. iter_10_1
	end

	return var_10_1
end

function var_0_1.requestServerUrl_(arg_11_0, arg_11_1)
	local var_11_0 = {
		mid = 20480,
		area = "tw",
		type = arg_11_0.packageInfos_.mode,
		app_v = xyd.getVersionName(),
		platform = cc.Application:getInstance():getTargetPlatform()
	}

	arg_11_0:setMessage_(__("CONNECTING_SERVER"), true)
	arg_11_0:webRequest_(arg_11_1, var_11_0, function(arg_12_0, arg_12_1)
		arg_11_0:setMessage_("")

		if arg_12_1 then
			xyd.serverUrl = arg_12_0.url
			xyd.serverID = arg_12_0.server_id
			xyd.back_domain = arg_12_0.back_domain
			xyd.resDownloadUrl = arg_12_0.res_download_url

			arg_11_0:checkUpdate_()
		elseif arg_11_1 ~= var_0_10 then
			arg_11_0:requestServerUrl_(var_0_10)
		else
			arg_11_0:alert_(__("FAILED_CONNECT_SERVER"), function(arg_13_0)
				arg_11_0:requestServerUrl_(var_0_8)
			end, {
				alertType = 0,
				yesText = __("RETRY")
			})
		end
	end)
end

function var_0_1.compareVersion(arg_14_0, arg_14_1, arg_14_2)
	if not arg_14_1 or arg_14_1 == "" then
		return -1
	elseif not arg_14_2 or arg_14_2 == "" then
		return 1
	end

	local var_14_0 = arg_14_0:split(arg_14_1, "%.")
	local var_14_1 = arg_14_0:split(arg_14_2, "%.")

	if tonumber(var_14_0[1]) ~= tonumber(var_14_1[1]) then
		return tonumber(var_14_0[1]) - tonumber(var_14_1[1])
	elseif tonumber(var_14_0[2]) ~= tonumber(var_14_1[2]) then
		return tonumber(var_14_0[2]) - tonumber(var_14_1[2])
	else
		return tonumber(var_14_0[3]) - tonumber(var_14_1[3])
	end
end

function var_0_1.pkgVersionCheck(arg_15_0)
	print("start UpdateScene pkgVersionCheck")

	local var_15_0 = xyd.getVersionName()
	local var_15_1 = arg_15_0:getVersion_()

	if var_15_1 == "" or arg_15_0:compareVersion(var_15_0, var_15_1) <= 0 then
		return
	end

	local var_15_2 = cc.FileUtils:getInstance()

	if not var_15_2:isFileExist(arg_15_0.source .. "/" .. var_0_19) then
		return
	end

	var_15_2:removeDirectory(xyd.versionUpdatePath .. "res/windows/")
	var_15_2:removeDirectory(xyd.versionUpdatePath .. "res/sound/")

	local var_15_3 = arg_15_0:readFromFile(arg_15_0.source .. "/" .. var_0_19)

	arg_15_0:write2File(var_0_0.encode(var_15_3), xyd.versionUpdatePath .. var_0_19)
	arg_15_0:setResourceVersion_(var_15_0)
	print("finish UpdateScene pkgVersionCheck")
end

function var_0_1.split(arg_16_0, arg_16_1, arg_16_2)
	if arg_16_1 == "" or arg_16_1 == nil then
		return nil
	end

	local var_16_0 = {}

	while true do
		local var_16_1 = string.find(arg_16_1, arg_16_2)

		if not var_16_1 then
			var_16_0[#var_16_0 + 1] = arg_16_1

			break
		end

		local var_16_2 = string.sub(arg_16_1, 1, var_16_1 - 1)

		var_16_0[#var_16_0 + 1] = var_16_2
		arg_16_1 = string.sub(arg_16_1, var_16_1 + 1, #arg_16_1)
	end

	return var_16_0
end

function var_0_1.checkUpdate_(arg_17_0)
	arg_17_0:pkgVersionCheck()
	arg_17_0:setVersionLabel_(arg_17_0:getResourceVersion_())
	print("check updates")
	arg_17_0:checkVersion_(function(arg_18_0)
		local var_18_0 = arg_18_0.is_appstore ~= 0
		local var_18_1 = arg_18_0.is_inapp ~= 0
		local var_18_2

		var_18_2 = tonumber(arg_18_0.need_restart or 0) ~= 0

		local var_18_3 = true
		local var_18_4 = true
		local var_18_5 = tonumber(arg_18_0.is_review or 0) ~= 0

		arg_17_0.gameType_ = 0

		local var_18_6 = xyd.getVersionName()

		if arg_17_0.gameType_ > 0 and var_0_18[arg_17_0.gameType_] == nil then
			print("error: game type does not exist")

			arg_17_0.gameType_ = 0
		end

		local var_18_7 = cc.FileUtils:getInstance()
		local var_18_8 = cc.UserDefault:getInstance()
		local var_18_9 = xyd.lazyFileManager

		local function var_18_10(arg_19_0)
			if #(var_18_8:getStringForKey(var_0_22) or "") ~= 0 then
				return
			end

			local var_19_0 = cc.Crypto

			for iter_19_0, iter_19_1 in pairs(arg_19_0) do
				local var_19_1 = iter_19_1.path
				local var_19_2 = iter_19_1.force
				local var_19_3 = iter_19_1.md5

				if var_19_1 and var_19_2 ~= 1 then
					local var_19_4 = true
					local var_19_5 = xyd.versionUpdatePath .. string.gsub(var_19_1, "/web/", "/")

					if var_18_7:isFileExist(var_19_5) then
						if var_19_3 == var_19_0:MD5File(var_19_5) then
							var_19_4 = false
						else
							var_18_7:removeFile(var_19_5)
						end
					end

					if var_19_4 then
						local var_19_6 = {
							version = iter_19_1.version,
							size = iter_19_1.size,
							md5 = var_19_3,
							path = var_19_1
						}
						local var_19_7 = var_0_0.encode(var_19_6) or ""
						local var_19_8 = ""
						local var_19_9 = arg_17_0:split(var_19_1, "/")

						for iter_19_2, iter_19_3 in pairs(var_19_9) do
							if iter_19_2 ~= 1 then
								var_19_8 = var_19_8 .. "___"
							end

							var_19_8 = var_19_8 .. iter_19_3
						end

						var_18_9:setStringForKeyNoFlush(var_0_21 .. var_19_8, var_19_7)
					end
				end
			end

			var_18_9:flush()
			var_18_8:setStringForKey(var_0_22, "success")
		end

		local function var_18_11(arg_20_0)
			if #(var_18_8:getStringForKey(var_0_23) or "") ~= 0 then
				return
			end

			local var_20_0 = cc.Crypto

			for iter_20_0, iter_20_1 in pairs(arg_20_0) do
				local var_20_1 = iter_20_1.path
				local var_20_2 = iter_20_1.force
				local var_20_3 = iter_20_1.md5
				local var_20_4

				if var_20_1 then
					var_20_4 = string.match(var_20_1, "/web/windows/")
					var_20_4 = var_20_4 or string.match(var_20_1, "/web/sound/")
				end

				if var_20_1 and var_20_4 and var_20_2 ~= 1 then
					local var_20_5 = true
					local var_20_6 = xyd.versionUpdatePath .. string.gsub(var_20_1, "/web/", "/")

					if var_18_7:isFileExist(var_20_6) then
						if var_20_3 == var_20_0:MD5File(var_20_6) then
							var_20_5 = false
						else
							var_18_7:removeFile(var_20_6)
						end
					end

					if var_20_5 then
						local var_20_7 = {
							version = iter_20_1.version,
							size = iter_20_1.size,
							md5 = var_20_3,
							path = var_20_1
						}
						local var_20_8 = var_0_0.encode(var_20_7) or ""
						local var_20_9 = ""
						local var_20_10 = arg_17_0:split(var_20_1, "/")

						for iter_20_2, iter_20_3 in pairs(var_20_10) do
							if iter_20_2 ~= 1 then
								var_20_9 = var_20_9 .. "___"
							end

							var_20_9 = var_20_9 .. iter_20_3
						end

						var_18_9:setStringForKeyNoFlush(var_0_21 .. var_20_9, var_20_8)
					end
				end
			end

			var_18_9:flush()
			var_18_8:setStringForKey(var_0_23, "success")
		end

		local var_18_12

		if var_18_7:isFileExist(xyd.versionUpdatePath .. var_0_19) then
			var_18_12 = arg_17_0:readFromFile(xyd.versionUpdatePath .. var_0_19)
		elseif var_18_7:isFileExist(xyd.versionUpdatePath .. "src_64/" .. var_0_19) then
			var_18_12 = arg_17_0:readFromFile(xyd.versionUpdatePath .. "src_64/" .. var_0_19)

			arg_17_0:write2File(var_0_0.encode(var_18_12), xyd.versionUpdatePath .. var_0_19)
		elseif var_18_7:isFileExist(arg_17_0.source .. "/" .. var_0_19) then
			var_18_12 = arg_17_0:readFromFile(arg_17_0.source .. "/" .. var_0_19)

			arg_17_0:write2File(var_0_0.encode(var_18_12), xyd.versionUpdatePath .. var_0_19)
		end

		if var_18_12 then
			var_18_10(var_18_12)
			var_18_11(var_18_12)
		else
			var_18_12 = {}
		end

		local var_18_13 = {}

		for iter_18_0, iter_18_1 in pairs(var_18_12) do
			local var_18_14 = iter_18_1.md5

			var_18_13[iter_18_1.path .. var_18_14] = iter_18_1
		end

		local function var_18_15()
			local var_21_0

			if var_18_7:isFileExist(xyd.versionUpdatePath .. "src_64/" .. var_0_19) then
				var_21_0 = arg_17_0:readFromFile(xyd.versionUpdatePath .. "src_64/" .. var_0_19)
			else
				return
			end

			local var_21_1 = {}

			for iter_21_0, iter_21_1 in pairs(var_21_0) do
				local var_21_2 = iter_21_1.md5
				local var_21_3 = iter_21_1.path
				local var_21_4 = iter_21_1.force

				if var_21_3 and not var_18_13[var_21_3 .. var_21_2] and var_21_4 ~= 1 then
					local var_21_5 = arg_17_0:split(var_21_3, "/")
					local var_21_6 = {
						version = iter_21_1.version,
						size = iter_21_1.size,
						path = var_21_3,
						md5 = var_21_2
					}
					local var_21_7 = var_0_0.encode(var_21_6) or ""
					local var_21_8 = ""

					for iter_21_2, iter_21_3 in pairs(var_21_5) do
						if iter_21_2 ~= 1 then
							var_21_8 = var_21_8 .. "___"
						end

						var_21_8 = var_21_8 .. iter_21_3
					end

					var_18_9:setStringForKeyNoFlush(var_0_21 .. var_21_8, var_21_7)
				end

				var_21_1[iter_21_1.path] = iter_21_1
			end

			arg_17_0:write2File(var_0_0.encode(var_21_0), xyd.versionUpdatePath .. var_0_19)
			var_18_9:flush()
			var_18_8:setStringForKey(var_0_22, "success")
		end

		if var_18_0 then
			arg_17_0:alert_(__("APP_STORE_UPDATE_PROMPT"), function(arg_22_0)
				if arg_22_0 then
					local var_22_0 = cc.Application:getInstance():getTargetPlatform()

					if var_22_0 <= 2 then
						print("you platform: " .. var_22_0 .. " does not support in appstore update")
						cc.Application:getInstance():openURL("http://www.game168.tw")
					else
						cc.Application:getInstance():openURL(xyd.versionUpdateURL)
					end
				elseif var_18_4 then
					local var_22_1 = __("APP_UPDATE_DETAILS")

					cc.Application:getInstance():openURL(var_22_1)
				else
					arg_17_0:startGame_()
				end
			end, {
				alertType = 3,
				skipClose = true
			})
		elseif var_18_1 then
			if not var_18_5 then
				arg_17_0:alert_(__("UPDATE_PROMPT"), function(arg_23_0)
					if arg_23_0 then
						arg_17_0:update_(arg_18_0.res, var_18_15, function()
							if restart_game then
								restart_game()
							else
								xyd.exitProgram()
							end
						end)
					elseif var_18_3 then
						xyd.exitProgram()
					else
						arg_17_0:startGame_()
					end
				end, {
					alertType = 1
				})
			else
				arg_17_0:update_(arg_18_0.res, var_18_15, function()
					if restart_game then
						restart_game()
					else
						xyd.exitProgram()
					end
				end)
			end
		else
			arg_17_0:startGame_()
		end
	end)
end

function var_0_1.loadTranslations_(arg_26_0)
	if __ == nil then
		local var_26_0 = {}
		local var_26_1 = require("data.tables.translation")

		for iter_26_0, iter_26_1 in pairs(var_26_1.rows) do
			var_26_0[iter_26_1[1]] = iter_26_1[2]
		end

		function __(arg_27_0)
			return var_26_0[arg_27_0] or arg_27_0
		end
	end
end

function var_0_1.setupScreen_(arg_28_0)
	local var_28_0 = cc.Director:getInstance()

	var_28_0:setAnimationInterval(0.016666666666666666)

	local var_28_1 = var_28_0:getOpenGLView()
	local var_28_2 = var_28_1:getFrameSize()
	local var_28_3 = 0
	local var_28_4 = var_28_2.width / var_28_2.height < 1.5

	if var_28_4 then
		var_28_3 = var_0_2
	else
		var_28_3 = var_0_3
	end

	var_28_0:setContentScaleFactor(1)
	var_28_1:setDesignResolutionSize(1280, 720, var_28_3)

	arg_28_0.viewSize_ = var_28_0:getVisibleSize()

	if var_28_4 then
		arg_28_0.viewSize_.height = 0.5625 * arg_28_0.viewSize_.width
	else
		arg_28_0.viewSize_.width = 1.7777777777777777 * arg_28_0.viewSize_.height
	end
end

function var_0_1.registerSceneCallbacks_(arg_29_0)
	local function var_29_0(arg_30_0)
		if arg_30_0 == "enterTransitionFinish" then
			arg_29_0:onEnterTransitionFinish()
		elseif arg_30_0 == "exit" then
			arg_29_0:onExit()
		end
	end

	arg_29_0:registerScriptHandler(var_29_0)
end

function var_0_1.setupContentView_(arg_31_0)
	if arg_31_0.contentView_ ~= nil then
		return
	end

	local var_31_0 = cc.Director:getInstance():getVisibleSize()

	arg_31_0.contentView_ = cc.Node:create()

	arg_31_0.contentView_:setContentSize(arg_31_0.viewSize_)
	arg_31_0.contentView_:setAnchorPoint(arg_31_0:point(0.5, 0.5))
	arg_31_0.contentView_:setPosition(arg_31_0:point(0.5 * var_31_0.width, 0.5 * var_31_0.height))
	arg_31_0:addChild(arg_31_0.contentView_)
end

function var_0_1.setupBackground_(arg_32_0)
	if arg_32_0.background_ ~= nil then
		return
	end

	local var_32_0 = arg_32_0.contentView_:getContentSize()

	print("size: (" .. var_32_0.width .. ", " .. var_32_0.height .. ")")

	local var_32_1 = ""
	local var_32_2 = 0

	if cc.Application:getInstance():getTargetPlatform() == var_0_17 then
		local var_32_3 = require("luaj")
		local var_32_4 = "org/cocos2dx/lua/AppActivity"
		local var_32_5 = "getChannel"
		local var_32_6 = {}
		local var_32_7 = "()I"
		local var_32_8, var_32_9 = var_32_3.callStaticMethod(var_32_4, var_32_5, var_32_6, var_32_7)

		if var_32_8 then
			var_32_2 = var_32_9
		end
	end

	arg_32_0.clippingNode = cc.ClippingRectangleNode:create()

	arg_32_0.clippingNode:setClippingRegion(arg_32_0:rect(0, 0, var_32_0.width, var_32_0.height))
	arg_32_0.contentView_:addChild(arg_32_0.clippingNode, -1)

	if var_32_2 ~= 0 then
		var_32_1 = "_" .. var_32_2
	end

	arg_32_0.background_ = cc.Sprite:create("images/startup" .. var_32_1 .. ".png")

	arg_32_0.background_:setAnchorPoint(arg_32_0:point(0.5, 0.5))
	arg_32_0.background_:setPosition(arg_32_0:point(0.5 * var_32_0.width, 0.5 * var_32_0.height))
	arg_32_0.clippingNode:addChild(arg_32_0.background_)

	local var_32_10 = "effects/common_effect_logo_spin"
	local var_32_11 = var_32_10 .. ".json"
	local var_32_12 = var_32_10 .. ".atlas"

	arg_32_0.logoEffect_ = sp.SkeletonAnimation:create(var_32_11, var_32_12, 0.7)

	arg_32_0.logoEffect_:setAnchorPoint(arg_32_0:point(0.5, 0.5))
	arg_32_0.logoEffect_:setPosition(arg_32_0:point(0.84 * var_32_0.width, 0.83 * var_32_0.height))
	arg_32_0.logoEffect_:setAnimation(0, "texiao", true)
	arg_32_0.contentView_:addChild(arg_32_0.logoEffect_)

	local var_32_13 = cc.ParticleSystemQuad:create("effects/yuanparticle_texture.plist")

	var_32_13:setPosition(arg_32_0:point(var_32_0.width + 200, var_32_0.height - 150))
	arg_32_0.contentView_:addChild(var_32_13, 1)

	local var_32_14 = cc.ParticleSystemQuad:create("effects/huabanparticle_texture.plist")

	var_32_14:setPosition(arg_32_0:point(var_32_0.width + 200, var_32_0.height - 150))
	arg_32_0.contentView_:addChild(var_32_14, 1)

	arg_32_0.isLoadingAnimationComplete_ = true
end

function var_0_1.alert_(arg_33_0, arg_33_1, arg_33_2, arg_33_3)
	local var_33_0 = 34
	local var_33_1 = 174
	local var_33_2 = 64
	local var_33_3 = 240

	if arg_33_0.alertView_ == nil then
		local var_33_4 = arg_33_0.contentView_:getContentSize()
		local var_33_5 = arg_33_0:size(450, 283)

		arg_33_0.alertView_ = ccui.Scale9Sprite:createWithSpriteFrameName("update_alert_bg.png")

		arg_33_0.alertView_:retain()
		arg_33_0.alertView_:setContentSize(var_33_5)
		arg_33_0.alertView_:setAnchorPoint(arg_33_0:point(0.5, 0.5))
		arg_33_0.alertView_:setPosition(arg_33_0:point(0.5 * var_33_4.width, 0.5 * var_33_4.height))

		arg_33_0.alertLabel_ = cc.Label:createWithTTF("", var_0_15, 28)

		arg_33_0.alertLabel_:setTextColor({
			g = 179,
			a = 255,
			b = 118,
			r = 231
		})
		arg_33_0.alertLabel_:enableShadow()
		arg_33_0.alertLabel_:setAlignment(1, 0)
		arg_33_0.alertLabel_:setWidth(440)
		arg_33_0.alertLabel_:setAnchorPoint(arg_33_0:point(0.5, 1))
		arg_33_0.alertLabel_:setPosition(arg_33_0:point(0.5 * var_33_5.width, 200))
		arg_33_0.alertView_:addChild(arg_33_0.alertLabel_)

		arg_33_0.alertYesButton_ = ccui.Button:create("update_btn_yes.png", "update_btn_yes.png", "", 1)

		arg_33_0.alertYesButton_:setContentSize(var_33_1, var_33_2)
		arg_33_0.alertYesButton_:setAnchorPoint(arg_33_0:point(0, 0))
		arg_33_0.alertYesButton_:setPosition(arg_33_0:point(0, var_33_0))
		arg_33_0.alertYesButton_:setTitleFontName(var_0_15)
		arg_33_0.alertYesButton_:setTitleFontSize(30)
		arg_33_0.alertYesButton_:getTitleRenderer():enableShadow()
		arg_33_0.alertView_:addChild(arg_33_0.alertYesButton_)

		arg_33_0.alertNoButton_ = ccui.Button:create("update_btn_yes.png", "update_btn_yes.png", "", 1)

		arg_33_0.alertNoButton_:setContentSize(var_33_1, var_33_2)
		arg_33_0.alertNoButton_:setAnchorPoint(arg_33_0:point(0, 0))
		arg_33_0.alertNoButton_:setPosition(arg_33_0:point(0, var_33_0))
		arg_33_0.alertNoButton_:setTitleFontName(var_0_15)
		arg_33_0.alertNoButton_:setTitleFontSize(30)
		arg_33_0.alertNoButton_:getTitleRenderer():enableShadow()
		arg_33_0.alertView_:addChild(arg_33_0.alertNoButton_)
	end

	if arg_33_0.alertView_:getParent() == nil then
		arg_33_0.contentView_:addChild(arg_33_0.alertView_, 1)
	else
		return
	end

	arg_33_3 = arg_33_3 or {}

	local var_33_6 = arg_33_0.alertView_:getContentSize()

	local function var_33_7(arg_34_0)
		if arg_33_3.skipClose then
			if arg_33_2 ~= nil then
				arg_33_2(arg_34_0)
			end

			return
		end

		if arg_33_0.alertView_ ~= nil and arg_33_0.alertView_:getParent() ~= nil then
			arg_33_0.alertView_:runAction(cc.Sequence:create({
				cc.EaseBackIn:create(cc.ScaleTo:create(0.3, 0)),
				cc.CallFunc:create(function()
					arg_33_0.alertView_:removeFromParent()

					if arg_33_2 ~= nil then
						arg_33_2(arg_34_0)
					end
				end)
			}))
		end
	end

	if arg_33_3.alertType == 1 then
		arg_33_0.alertYesButton_:setPosition(arg_33_0:point(var_33_3, var_33_0))
		arg_33_0.alertYesButton_:setTitleText(arg_33_3.yesText or __("YES"))
		arg_33_0.alertYesButton_:addTouchEventListener(function(arg_36_0, arg_36_1)
			if arg_36_1 == var_0_6 then
				var_33_7(true)
			end
		end)
		arg_33_0.alertNoButton_:setPosition(arg_33_0:point(var_33_6.width - var_33_3 - var_33_1, var_33_0))
		arg_33_0.alertNoButton_:setTitleText(arg_33_3.noText or __("NO"))
		arg_33_0.alertNoButton_:addTouchEventListener(function(arg_37_0, arg_37_1)
			if arg_37_1 == var_0_6 then
				var_33_7(false)
			end
		end)
		arg_33_0.alertNoButton_:setVisible(true)
	elseif arg_33_3.alertType == 3 then
		arg_33_0.alertYesButton_:setPosition(arg_33_0:point(var_33_3, var_33_0))
		arg_33_0.alertYesButton_:setTitleText(arg_33_3.yesText or __("GOTO"))
		arg_33_0.alertYesButton_:addTouchEventListener(function(arg_38_0, arg_38_1)
			if arg_38_1 == var_0_6 then
				var_33_7(true)
			end
		end)
		arg_33_0.alertNoButton_:setPosition(arg_33_0:point(var_33_6.width - var_33_3 - var_33_1, var_33_0))
		arg_33_0.alertNoButton_:setTitleText(arg_33_3.noText or __("CHECK_THE_DETAILS"))
		arg_33_0.alertNoButton_:addTouchEventListener(function(arg_39_0, arg_39_1)
			if arg_39_1 == var_0_6 then
				var_33_7(false)
			end
		end)
		arg_33_0.alertNoButton_:setVisible(true)
	else
		arg_33_0.alertYesButton_:setPosition(arg_33_0:point(0.5 * (var_33_6.width - var_33_1), var_33_0))
		arg_33_0.alertYesButton_:setTitleText(arg_33_3.yesText or __("CONFIRM"))
		arg_33_0.alertYesButton_:addTouchEventListener(function(arg_40_0, arg_40_1)
			if arg_40_1 == var_0_6 then
				var_33_7(true)
			end
		end)
		arg_33_0.alertNoButton_:setVisible(false)
	end

	arg_33_0.alertLabel_:setString(arg_33_1)
	arg_33_0.alertView_:setScale(0)
	arg_33_0.alertView_:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(0.3, 1)))
end

function var_0_1.setVersionLabel_(arg_41_0, arg_41_1)
	if arg_41_0.versionLabel_ == nil then
		local var_41_0 = arg_41_0.contentView_:getContentSize()
		local var_41_1 = 10

		arg_41_0.versionLabel_ = cc.Label:createWithTTF("", var_0_15, 18)

		arg_41_0.versionLabel_:enableShadow()
		arg_41_0.versionLabel_:setAnchorPoint(arg_41_0:point(1, 0))
		arg_41_0.versionLabel_:setPosition(arg_41_0:point(var_41_0.width - var_41_1, var_41_1))
		arg_41_0.contentView_:addChild(arg_41_0.versionLabel_)
	end

	arg_41_0.versionLabel_:setString(string.format("v%s", arg_41_1))
end

function var_0_1.setMessage_(arg_42_0, arg_42_1, arg_42_2)
	if arg_42_0.messageLabel_ == nil then
		local var_42_0 = arg_42_0.contentView_:getContentSize()

		arg_42_0.messageLabel_ = cc.Label:createWithTTF("", var_0_15, 32)

		arg_42_0.messageLabel_:enableShadow()
		arg_42_0.messageLabel_:setAnchorPoint(arg_42_0:point(0.5, 0.5))
		arg_42_0.messageLabel_:setPosition(arg_42_0:point(0.5 * var_42_0.width, 150))
		arg_42_0.contentView_:addChild(arg_42_0.messageLabel_)

		arg_42_0.messageLabel_.npoint = 3
		arg_42_0.messageLabel_.pointContainer = cc.Node:create()
		arg_42_0.messageLabel_.points = {}

		arg_42_0.contentView_:addChild(arg_42_0.messageLabel_.pointContainer)

		local var_42_1 = 5
		local var_42_2 = 0

		for iter_42_0 = 1, arg_42_0.messageLabel_.npoint do
			local var_42_3 = cc.Sprite:create("images/update_p.png")

			var_42_3:setAnchorPoint(arg_42_0:point(0.5, 0.5))
			var_42_3:setPosition(arg_42_0:point(var_42_2, 0))
			arg_42_0.messageLabel_.pointContainer:addChild(var_42_3)
			table.insert(arg_42_0.messageLabel_.points, var_42_3)

			var_42_2 = var_42_2 + var_42_3:getContentSize().width + var_42_1
		end
	end

	local var_42_4 = arg_42_0.messageLabel_.pointContainer:getScheduler()

	if arg_42_0.messageLabel_.pointContainer.animationHandle ~= nil then
		var_42_4:unscheduleScriptEntry(arg_42_0.messageLabel_.pointContainer.animationHandle)
	end

	arg_42_0.messageLabel_.pointContainer:setVisible(false)
	arg_42_0.messageLabel_:setString(arg_42_1)

	if arg_42_2 then
		local var_42_5 = arg_42_0.messageLabel_:getBoundingBox()
		local var_42_6 = 0

		local function var_42_7(arg_43_0)
			local var_43_0 = arg_43_0 % (arg_42_0.messageLabel_.npoint + 1)

			for iter_43_0 = 1, arg_42_0.messageLabel_.npoint do
				arg_42_0.messageLabel_.points[iter_43_0]:setVisible(iter_43_0 <= var_43_0)
			end
		end

		arg_42_0.messageLabel_.pointContainer:setVisible(true)
		arg_42_0.messageLabel_.pointContainer:setPosition(arg_42_0:point(var_42_5.x + var_42_5.width + 12, var_42_5.y + 5))
		var_42_7(var_42_6)

		arg_42_0.messageLabel_.pointContainer.animationHandle = var_42_4:scheduleScriptFunc(function()
			var_42_6 = var_42_6 + 1

			var_42_7(var_42_6)
		end, 1, false)
	end
end

function var_0_1.prepareProgressLabel_(arg_45_0)
	if arg_45_0.progressLabel_ == nil then
		local var_45_0 = arg_45_0.contentView_:getContentSize()

		arg_45_0.progressLabel_ = cc.Label:createWithTTF("", var_0_15, 24)

		arg_45_0.progressLabel_:enableShadow()
		arg_45_0.progressLabel_:setAnchorPoint(arg_45_0:point(0.5, 0.5))
		arg_45_0.progressLabel_:setPosition(arg_45_0:point(0.5 * var_45_0.width, 72))
		arg_45_0.contentView_:addChild(arg_45_0.progressLabel_)
	end
end

function var_0_1.setDownloadProgressMessage_(arg_46_0, arg_46_1, arg_46_2)
	if arg_46_0:game() then
		arg_46_0:game():setDownloadProgressMessage_(arg_46_1, arg_46_2)

		return
	end

	local var_46_0 = (arg_46_1 or 0) / (arg_46_2 or 1024)
	local var_46_1 = string.format("%6.2f%%", var_46_0 * 100)

	arg_46_0:prepareProgressLabel_()
	arg_46_0.progressLabel_:setString(string.format(__("DOWNLOAD_PROGRESS"), var_46_1))
end

function var_0_1.setUnzipProgressMessage_(arg_47_0, arg_47_1)
	if arg_47_0:game() then
		arg_47_0:game():setUnzipProgressMessage_(arg_47_1)

		return
	end

	local var_47_0 = string.format("%6.2f%%", arg_47_1 * 100)

	arg_47_0:prepareProgressLabel_()
	arg_47_0.progressLabel_:setString(string.format(__("UNZIP_PROGRESS"), var_47_0))
end

function var_0_1.setDownloadSpeedMessage_(arg_48_0, arg_48_1, arg_48_2)
	if arg_48_0:game() then
		return
	end

	if arg_48_0.downloadSpeedLabel_ == nil then
		local var_48_0 = arg_48_0.progressBackground_:getBoundingBox()
		local var_48_1 = var_48_0.x + var_48_0.width

		arg_48_0.downloadSpeedLabel_ = cc.Label:createWithTTF("", var_0_15, 24)

		arg_48_0.downloadSpeedLabel_:enableShadow()
		arg_48_0.downloadSpeedLabel_:setAnchorPoint(arg_48_0:point(1, 0.5))
		arg_48_0.downloadSpeedLabel_:setPosition(var_48_1, 72)
		arg_48_0.contentView_:addChild(arg_48_0.downloadSpeedLabel_)
	end

	arg_48_0.downloadSpeedLabel_:setVisible(not arg_48_2)
	arg_48_0.downloadSpeedLabel_:setString(string.format("%.2fKB/S", arg_48_1))
end

function var_0_1.setProgress_(arg_49_0, arg_49_1)
	if arg_49_0:game() then
		arg_49_0:game():setProgress_(arg_49_1)

		return
	end

	if arg_49_0.progressBar_ == nil then
		local var_49_0 = arg_49_0.contentView_:getContentSize()
		local var_49_1 = 606
		local var_49_2 = 20

		arg_49_0.progressBackground_ = ccui.Scale9Sprite:createWithSpriteFrameName("update_progress_bg.png", arg_49_0:rect(27, 0, 1, var_49_2))

		arg_49_0.progressBackground_:setContentSize(arg_49_0:size(var_49_1, var_49_2))
		arg_49_0.progressBackground_:setAnchorPoint(arg_49_0:point(0.5, 0.5))
		arg_49_0.progressBackground_:setPosition(arg_49_0:point(0.5 * var_49_0.width, 108))
		arg_49_0.contentView_:addChild(arg_49_0.progressBackground_)

		local var_49_3 = cc.Sprite:createWithSpriteFrameName("update_progress.png")

		arg_49_0.progressBar_ = cc.ProgressTimer:create(var_49_3)

		arg_49_0.progressBar_:setType(1)
		arg_49_0.progressBar_:setMidpoint(arg_49_0:point(0, 0))
		arg_49_0.progressBar_:setBarChangeRate(arg_49_0:point(1, 0))
		arg_49_0.progressBar_:setPercentage(0)
		arg_49_0.progressBar_:setAnchorPoint(arg_49_0:point(0.5, 0.5))
		arg_49_0.progressBar_:setPosition(arg_49_0:point(0.5 * var_49_1, 0.5 * var_49_2))
		arg_49_0.progressBackground_:addChild(arg_49_0.progressBar_)
	end

	arg_49_0.progressBar_:setPercentage(arg_49_1 * 100)
end

function var_0_1.webRequest_(arg_50_0, arg_50_1, arg_50_2, arg_50_3)
	if arg_50_0.request_ ~= nil then
		return
	end

	local function var_50_0(arg_51_0, arg_51_1)
		arg_50_0.request_ = nil

		if arg_50_3 ~= nil then
			arg_50_3(arg_51_0 or {}, arg_51_1)
		end
	end

	local function var_50_1(arg_52_0)
		if arg_52_0.name ~= "completed" and arg_52_0.name ~= "failed" then
			return
		end

		if arg_52_0.name ~= "completed" then
			var_50_0()
			print(string.format("Web request failed, url = %s", arg_50_1))

			return
		end

		local var_52_0 = arg_52_0.request:getResponseString()
		local var_52_1 = arg_52_0.request:getResponseStatusCode()

		print(string.format("Received from web code(%d) -- %s", var_52_1, var_52_0))

		if var_52_1 ~= 200 then
			var_50_0()

			return
		end

		var_50_0(var_0_0.decode(var_52_0), true)
	end

	local var_50_2 = var_0_0.encode(arg_50_2 or {})

	arg_50_0.request_ = cc.HTTPRequest:createWithUrl(var_50_1, arg_50_1, cc.kCCHTTPRequestMethodPOST)

	arg_50_0.request_:addPOSTValue("payload", var_50_2)
	print(string.format("Request web %s, post data %s", arg_50_1, var_50_2))
	arg_50_0.request_:setAcceptEncoding(cc.kCCHTTPRequestAcceptEncodingGzip)
	arg_50_0.request_:setTimeout(10)
	arg_50_0.request_:start()
end

function var_0_1.checkVersion_(arg_53_0, arg_53_1)
	local function var_53_0()
		local var_54_0 = {
			mid = 2,
			platform = cc.Application:getInstance():getTargetPlatform(),
			app_v = xyd.getVersionName(),
			v = arg_53_0:getResourceVersion_(),
			clean = arg_53_0:isCleanVersion_(),
			full = arg_53_0.packageInfos_.full == "true"
		}

		arg_53_0:setMessage_(__("CONNECTING_SERVER"), true)
		arg_53_0:webRequest_(arg_53_0:versionCheckURL_(), var_54_0, function(arg_55_0, arg_55_1)
			arg_53_0:setMessage_("")

			if arg_55_1 then
				if arg_53_1 ~= nil then
					arg_53_1(arg_55_0)
				end
			else
				arg_53_0:alert_(__("FAILED_CONNECT_SERVER"), function()
					var_53_0()
				end, {
					alertType = 0,
					yesText = __("RETRY")
				})
			end
		end)
	end

	local function var_53_1()
		local var_57_0 = require("luaj")
		local var_57_1 = "org/cocos2dx/lua/AppActivity"
		local var_57_2 = "getAPKExpansionFile"
		local var_57_3 = {}
		local var_57_4 = "()Ljava/lang/String;"
		local var_57_5, var_57_6 = var_57_0.callStaticMethod(var_57_1, var_57_2, var_57_3, var_57_4)

		print(string.format("Start unzip obb file: %s", var_57_6))

		if var_57_5 and var_57_6 ~= nil and var_57_6 ~= "" and arg_53_0.obbInfos_ ~= nil and cc.Crypto:MD5File(var_57_6) == arg_53_0.obbInfos_.obbmd5 then
			arg_53_0:unzipObb_(var_57_6, var_53_0)
		else
			print("call getAPKExpansionFIle() failed or obb file md5 not match:", var_57_6)
			var_53_0()
		end
	end

	arg_53_0:setMessage_(__("CHECKING_UPDATE"))

	local var_53_2 = cc.Application:getInstance():getTargetPlatform()

	print(string.format("platform:%d,android platform:%d", var_53_2, var_0_17))

	if var_53_2 == var_0_17 and arg_53_0:isCleanVersion_() then
		var_53_1()
	else
		var_53_0()
	end
end

function var_0_1.versionCheckURL_(arg_58_0)
	return xyd.serverUrl or var_0_9
end

function var_0_1.unzipObb_(arg_59_0, arg_59_1, arg_59_2)
	local var_59_0 = 0
	local var_59_1 = cc.FileUtils:getInstance():getFileSize(arg_59_1)

	arg_59_0:setMessage_(__("UNZIP_RESOURCE"), true)
	cc.Device:setKeepScreenOn(true)
	xyd.UnzipUtils:unzipFile(arg_59_1, xyd.versionUpdatePath, function(arg_60_0)
		if arg_59_0:is164up() then
			var_59_0 = var_59_0 + arg_60_0

			arg_59_0:setProgress_(var_59_0 / var_59_1)
			arg_59_0:setUnzipProgressMessage_(var_59_0 / var_59_1)
		end
	end, function(arg_61_0, arg_61_1)
		cc.Device:setKeepScreenOn(false)

		if arg_61_0 == xyd.UnzipUtils.RESULT_SUCCESS then
			local var_61_0 = xyd.getVersionName()

			arg_59_0:setResourceVersion_(var_61_0)
			arg_59_0:setVersionLabel_(var_61_0)
		end

		arg_59_2()
	end)
end

function var_0_1.update_(arg_62_0, arg_62_1, arg_62_2, arg_62_3)
	if #arg_62_1 <= 0 then
		return arg_62_3()
	end

	local var_62_0, var_62_1 = arg_62_0:recoverDownloadProgress_(arg_62_1)
	local var_62_2 = 0
	local var_62_3 = var_62_0 / var_62_1

	if arg_62_0.gameType_ > 0 and var_62_1 > 20971520 then
		arg_62_0:initGame()
	end

	arg_62_0:setProgress_(var_62_3)
	arg_62_0:setDownloadProgressMessage_(var_62_0, var_62_1)

	local function var_62_4()
		arg_62_2()

		local var_63_0 = arg_62_1[#arg_62_1].version

		arg_62_0:setResourceVersion_(var_63_0)
		arg_62_0:setVersionLabel_(var_63_0)
		arg_62_0:clearDownloadInfos_()
		arg_62_0:saveDownloadInfos_()

		if arg_62_0:game() then
			arg_62_0:setProgress_(1)
			arg_62_0:game():beforeDownLoadCompleted()
			arg_62_0:alert_(__("DOWNLOAD_COMPLETED"), function()
				arg_62_0:game():downLoadCompleted(function()
					arg_62_0.game_ = nil

					arg_62_3()
				end)
			end)

			return
		end

		arg_62_3()
	end

	local function var_62_5(arg_66_0)
		if arg_66_0 > #arg_62_1 then
			return var_62_4()
		end

		local var_66_0 = arg_62_1[arg_66_0]
		local var_66_1 = arg_62_0:getDownloadInfo_(var_66_0)

		cc.Device:setKeepScreenOn(true)
		arg_62_0:setDownloadSpeedMessage_(0, true)
		xyd.UnzipUtils:unzipFile(var_66_1.zipFile, xyd.versionUpdatePath, function(arg_67_0)
			if arg_62_0:is164up() then
				var_62_2 = var_62_2 + arg_67_0

				arg_62_0:setProgress_(var_62_2 / var_62_1)
				arg_62_0:setUnzipProgressMessage_(var_62_2 / var_62_1)
			end
		end, function(arg_68_0, arg_68_1)
			cc.Device:setKeepScreenOn(false)

			if arg_68_0 == xyd.UnzipUtils.RESULT_SUCCESS then
				var_62_5(arg_66_0 + 1)
			else
				local var_68_0 = ""

				if arg_68_0 == 2 then
					var_68_0 = __("MEMORY_NOT_ENOUGH")
				else
					var_68_0 = string.format("%s (%d, %d)", __("FAILED_UNZIP"), arg_68_0, arg_68_1)
				end

				arg_62_0:alert_(var_68_0, function()
					arg_62_0:cleanupDownloadInfo_(var_66_1)
					arg_62_0:saveDownloadInfos_()
					arg_62_0:update_(arg_62_1, arg_62_3)
				end, {
					alertType = 0,
					yesText = __("RETRY_DOWNLOAD")
				})
			end
		end)
	end

	local function var_62_6(arg_70_0)
		if arg_70_0 > #arg_62_1 then
			arg_62_0:setMessage_(__("UNZIP_RESOURCE"), true)

			return var_62_5(1)
		end

		local var_70_0 = arg_62_1[arg_70_0]
		local var_70_1 = arg_62_0:getDownloadInfo_(var_70_0)

		if arg_62_0:isDownloadFinished_(var_70_1) then
			return var_62_6(arg_70_0 + 1)
		end

		arg_62_0:setMessage_(__("DOWNLOADING_RESOURCE"))
		arg_62_0:downloadVersion_(var_62_0, var_62_1, var_70_1, var_70_0, function(arg_71_0, arg_71_1)
			var_62_0 = var_62_0 + arg_71_1
			var_62_3 = var_62_0 / var_62_1

			arg_62_0:setProgress_(var_62_3)
			arg_62_0:setDownloadProgressMessage_(var_62_0, var_62_1)
		end, function(arg_72_0, arg_72_1, arg_72_2)
			if arg_72_0 == xyd.FileDownloader.RESULT_SUCCESS and cc.Crypto:MD5File(var_70_1.zipFile) == var_70_0.md5 then
				var_62_6(arg_70_0 + 1)
			else
				local var_72_0 = ""

				if arg_62_0:is164up() then
					var_72_0 = string.format("%s (%d, %d)", __("FAILED_DOWNLOAD"), arg_72_0, arg_72_1)
				else
					var_72_0 = __("FAILED_DOWNLOAD")
				end

				arg_62_0:alert_(var_72_0, function()
					if arg_72_2 then
						var_62_0 = var_62_0 - var_70_1.finishedSize

						arg_62_0:cleanupDownloadInfo_(var_70_1)
						arg_62_0:saveDownloadInfos_()
					end

					var_62_6(arg_70_0)
				end, {
					alertType = 0,
					yesText = __("RETRY")
				})
			end
		end)
	end

	var_62_6(1)
end

function var_0_1.isDownloadFinished_(arg_74_0, arg_74_1)
	return arg_74_1 ~= nil and arg_74_1.finishedVolumes == arg_74_1.volumes and arg_74_1.finishedSize == arg_74_1.size
end

function var_0_1.isDownloadInfoForVersion_(arg_75_0, arg_75_1, arg_75_2)
	return arg_75_1 ~= nil and arg_75_2 ~= nil and arg_75_1.version == arg_75_2.version and arg_75_1.volumes == arg_75_2.volume and arg_75_1.size == arg_75_2.size
end

function var_0_1.recoverDownloadProgress_(arg_76_0, arg_76_1)
	if arg_76_0.downloadInfos_ == nil then
		arg_76_0.downloadInfos_ = cc.FileUtils:getInstance():getValueMapFromFile(var_0_11) or {}
	end

	local var_76_0 = 0
	local var_76_1 = 0

	for iter_76_0, iter_76_1 in ipairs(arg_76_1) do
		local var_76_2 = iter_76_1.md5

		var_76_0 = var_76_0 + iter_76_1.size

		local var_76_3 = arg_76_0.downloadInfos_[var_76_2]

		if arg_76_0:isDownloadInfoForVersion_(var_76_3, iter_76_1) then
			var_76_1 = var_76_1 + var_76_3.finishedSize
		end
	end

	return var_76_1, var_76_0
end

function var_0_1.getDownloadInfo_(arg_77_0, arg_77_1)
	local var_77_0 = arg_77_1.md5
	local var_77_1 = arg_77_0.downloadInfos_[var_77_0]

	if var_77_1 == nil or not arg_77_0:isDownloadInfoForVersion_(var_77_1, arg_77_1) then
		arg_77_0:cleanupDownloadInfo_(var_77_1)
		arg_77_0:saveDownloadInfos_()

		var_77_1 = {
			finishedSize = 0,
			finishedVolumes = 0,
			version = arg_77_1.version,
			volumes = arg_77_1.volume,
			size = arg_77_1.size,
			zipFile = xyd.versionUpdatePath .. arg_77_1.version .. ".zip"
		}
	end

	arg_77_0.downloadInfos_[var_77_0] = var_77_1

	return var_77_1
end

function var_0_1.clearDownloadInfos_(arg_78_0)
	for iter_78_0, iter_78_1 in pairs(arg_78_0.downloadInfos_) do
		arg_78_0:cleanupDownloadInfo_(iter_78_1)
	end

	arg_78_0.downloadInfos_ = {}

	arg_78_0:saveDownloadInfos_()
end

function var_0_1.cleanupDownloadInfo_(arg_79_0, arg_79_1)
	if arg_79_1 == nil then
		return
	end

	if arg_79_1.zipFile ~= nil then
		cc.FileUtils:getInstance():removeFile(arg_79_1.zipFile)
	end

	arg_79_1.version = nil
	arg_79_1.volumes = nil
	arg_79_1.size = nil
	arg_79_1.finishedVolumes = nil
	arg_79_1.finishedSize = nil
	arg_79_1.zipFile = nil
end

function var_0_1.saveDownloadInfos_(arg_80_0)
	if arg_80_0.downloadInfos_ ~= nil then
		cc.FileUtils:getInstance():writeToFile(arg_80_0.downloadInfos_, var_0_11)
	end
end

function var_0_1.downloadVersion_(arg_81_0, arg_81_1, arg_81_2, arg_81_3, arg_81_4, arg_81_5, arg_81_6)
	print(string.format("Start downloading resource of version %s", arg_81_4.version))

	local var_81_0 = arg_81_3.zipFile

	local function var_81_1(arg_82_0)
		if arg_82_0 > arg_81_3.volumes then
			if arg_81_0:isDownloadFinished_(arg_81_3) then
				return arg_81_6(xyd.FileDownloader.RESULT_SUCCESS, 0, false)
			else
				return arg_81_6(xyd.FileDownloader.RESULT_FAILED, 0, true)
			end
		end

		local var_82_0 = string.format("%s.%03d", arg_81_4.resource, arg_82_0)
		local var_82_1 = arg_81_3.finishedSize
		local var_82_2 = 0
		local var_82_3 = 0

		print(string.format("Start downloading resource %s", var_82_0))
		cc.Device:setKeepScreenOn(true)
		xyd.FileDownloader:download(var_82_0, var_81_0, var_82_1, 10, function(arg_83_0, arg_83_1, arg_83_2)
			var_82_2 = arg_83_1
			arg_81_1 = arg_81_1 + (arg_83_0 - var_82_3)
			var_82_3 = arg_83_0

			local var_83_0 = arg_81_1 / arg_81_2

			arg_81_0:setProgress_(var_83_0)
			arg_81_0:setDownloadProgressMessage_(arg_81_1, arg_81_2)
			arg_81_0:setDownloadSpeedMessage_(arg_83_2 / 1024)
		end, function(arg_84_0, arg_84_1, arg_84_2)
			cc.Device:setKeepScreenOn(false)

			if arg_84_0 == xyd.FileDownloader.RESULT_SUCCESS then
				arg_81_3.finishedVolumes = arg_81_3.finishedVolumes + 1
				arg_81_3.finishedSize = arg_81_3.finishedSize + var_82_2

				arg_81_0:saveDownloadInfos_()
				arg_81_5(finishedVolumes, var_82_2)
				var_81_1(arg_82_0 + 1)
			else
				arg_81_6(arg_84_0, arg_84_1, arg_84_2)
			end
		end)
	end

	var_81_1(arg_81_3.finishedVolumes + 1)
end

function var_0_1.startGame_(arg_85_0)
	print("start game")

	if not arg_85_0.isLoadingAnimationComplete_ then
		print("not complete")
		arg_85_0:runAction(cc.Sequence:create({
			cc.DelayTime:create(1),
			cc.CallFunc:create(function()
				if tolua.isnull(arg_85_0) then
					return
				end

				arg_85_0:startGame_()
			end)
		}))

		return
	end

	arg_85_0:setMessage_(__("LOADING_RESOURCE"))
	arg_85_0:cleanUp_()
	arg_85_0:runAction(cc.Sequence:create({
		cc.DelayTime:create(0.1),
		cc.CallFunc:create(function()
			if cc.Application:getInstance():getTargetPlatform() == 0 then
				package.path = "source/"
			else
				package.path = xyd.versionUpdatePath .. "src_64/;src_64/"
			end

			require("app.Game").new():run()
		end)
	}))
end

function var_0_1.getVersion_(arg_88_0)
	if arg_88_0.version_ == nil then
		arg_88_0.version_ = cc.UserDefault:getInstance():getStringForKey(xyd.USER_DEFAULTS_VERSION_KEY) or ""
		arg_88_0.isClean_ = #arg_88_0.version_ <= 0
	end

	return arg_88_0.version_
end

function var_0_1.getResourceVersion_(arg_89_0)
	return cc.UserDefault:getInstance():getStringForKey(xyd.USER_DEFAULTS_VERSION_KEY) or ""
end

function var_0_1.setResourceVersion_(arg_90_0, arg_90_1)
	cc.UserDefault:getInstance():setStringForKey(xyd.USER_DEFAULTS_VERSION_KEY, arg_90_1)

	arg_90_0.version_ = arg_90_1
	arg_90_0.isClean_ = #arg_90_0.version_ <= 0
end

function var_0_1.isCleanVersion_(arg_91_0)
	if arg_91_0.isClean_ == nil then
		arg_91_0:getVersion_()
	end

	return arg_91_0.isClean_
end

function var_0_1.cleanUp_(arg_92_0)
	cc.Director:getInstance():purgeCachedData()

	arg_92_0.request_ = nil

	if arg_92_0.alertView_ ~= nil then
		arg_92_0.alertView_:release()

		arg_92_0.alertView_ = nil
	end

	if arg_92_0.progressBackground_ ~= nil then
		arg_92_0.progressBackground_:setVisible(false)
	end

	if arg_92_0.progressLabel_ ~= nil then
		arg_92_0.progressLabel_:setVisible(false)
	end

	if arg_92_0.downloadSpeedLabel_ ~= nil then
		arg_92_0.downloadSpeedLabel_:setVisible(false)
	end

	__ = nil
	package.loaded["data.tables.translation"] = nil
	package.loaded.cjson = nil
	package.loaded.UpdateScene = nil
end

function var_0_1.is164up(arg_93_0)
	return true
end

function var_0_1.point(arg_94_0, arg_94_1, arg_94_2)
	return {
		x = arg_94_1,
		y = arg_94_2
	}
end

function var_0_1.size(arg_95_0, arg_95_1, arg_95_2)
	return {
		width = arg_95_1,
		height = arg_95_2
	}
end

function var_0_1.rect(arg_96_0, arg_96_1, arg_96_2, arg_96_3, arg_96_4)
	return {
		x = arg_96_1,
		y = arg_96_2,
		width = arg_96_3,
		height = arg_96_4
	}
end

function var_0_1.initGame(arg_97_0)
	local var_97_0 = require(var_0_18[arg_97_0.gameType_])

	var_97_0.get():init()
	var_97_0.get():setParent(arg_97_0.contentView_)
	var_97_0.get():play()

	arg_97_0.game_ = var_97_0.get()
end

function var_0_1.game(arg_98_0)
	return arg_98_0.game_
end

return var_0_1
