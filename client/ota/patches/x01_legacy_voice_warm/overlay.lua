-- x01: warm the legacy voice set in the background, so the first tap on a girl is the old take.
--
-- The 1.164.0 client carried every voice file in the APK, so a line was playable the moment a table named it. Here the
-- files arrive lazily, and the team-select screens call audio.playSound directly: a girl whose legacy file has not
-- reached the device yet plays the stock line on that tap. Rather than fix that per screen, this queues the whole
-- legacy tree once per session through the normal lazy download, the same way the asset update delivers everything
-- else. It runs only while the 2018 toggle is on and stops as soon as the catalogue has nothing left to fetch.

local GXB_LEGACY_VOICE_KEY = "gxb_legacy_voice"
local GXB_LEGACY_VOICE_ROOT = "sound/legacy2018/hero_sound/"
local GXB_WARM_FIRST_DELAY = 12
local GXB_WARM_RETRY_DELAY = 60
local GXB_WARM_MAX_ATTEMPTS = 10

-- BEGIN GENERATED: legacy voice manifest (scratch/build_legacy_manifest.py)
local GXB_LEGACY_VOICES = {
	["aidehua"] = "123456789",
	["alice"] = "123456789",
	["bulianshi"] = "123456789",
	["buzhi"] = "123456789",
	["caiwenji"] = "123456789",
	["caocao"] = "123456789",
	["caochong"] = "123456789",
	["caofang"] = "123456789",
	["caohong"] = "123456789",
	["caopi"] = "123456789",
	["caoren"] = "123456789",
	["caorui"] = "123456789",
	["caoxing"] = "123456789",
	["caoxiu"] = "123456789",
	["caozhi"] = "123456789",
	["change"] = "123456789",
	["chengong"] = "123456789",
	["chengpu"] = "123456789",
	["chengyu"] = "123456789",
	["chitu"] = "123456789",
	["chongtianzongsi"] = "123456789",
	["christmas"] = "123457",
	["chunyuqiong"] = "123456789",
	["daqiao"] = "123456789",
	["dechuanjiakang"] = "123456789",
	["dengai"] = "123456789",
	["dianwei"] = "123456789",
	["diaochan"] = "123456789",
	["dingfeng"] = "123456789",
	["dongzhuo"] = "123456789",
	["dracula"] = "123456789",
	["dutu"] = "123456789",
	["fangtianhuaji"] = "123456789",
	["fazheng"] = "123456789",
	["feiyi"] = "123456789",
	["fengchenxiuji"] = "123456789",
	["fububanzang"] = "123456789",
	["ganfuren"] = "123456789",
	["ganning"] = "123456789",
	["gaoshun"] = "123456789",
	["gongsunzan"] = "123456789",
	["guanlu"] = "123456789",
	["guanxing"] = "123456789",
	["guanyinping"] = "123456789",
	["guanyu"] = "123456789",
	["guohuan"] = "123456789",
	["guojia"] = "123456789",
	["guyong"] = "123456789",
	["halloween"] = "123457",
	["handang"] = "123456789",
	["hansui"] = "123456789",
	["hanxiandi"] = "123456789",
	["hejin"] = "123456789",
	["hetaihou"] = "123456789",
	["houcheng"] = "123456789",
	["huangchengyan"] = "123456789",
	["huanggai"] = "123456789",
	["huangyueying"] = "123456789",
	["huangzhong"] = "123456789",
	["huatuo"] = "123456789",
	["huaxiong"] = "123456789",
	["hucheer"] = "123456789",
	["jiabailie"] = "123456789",
	["jianggan"] = "123456789",
	["jiangwan"] = "123456789",
	["jiangwei"] = "123456789",
	["jiaxu"] = "123456789",
	["jiling"] = "123456789",
	["jushou"] = "123456789",
	["kamila"] = "123456789",
	["lafeier"] = "123456789",
	["liaohua"] = "123456789",
	["lidian"] = "123456789",
	["lingtong"] = "123456789",
	["liru"] = "123456789",
	["liubei"] = "123456789",
	["liubiao"] = "123456789",
	["liushan"] = "123456789",
	["lusu"] = "123456789",
	["luxifa"] = "123456789",
	["luxun"] = "123456789",
	["luzhi"] = "123456789",
	["lvbu"] = "123456789",
	["lvlingqi"] = "123456789",
	["lvmeng"] = "123456789",
	["machao"] = "123456789",
	["madai"] = "123456789",
	["maliang"] = "123456789",
	["maoliyuanjiu"] = "123456789",
	["masu"] = "123456789",
	["mayunlu"] = "123456789",
	["mazhong"] = "123456789",
	["menghuo"] = "123456789",
	["mifuren"] = "123456789",
	["miheng"] = "123456789",
	["mizhu"] = "123456789",
	["panfeng"] = "123456789",
	["pangde"] = "123456789",
	["pangtong"] = "123456789",
	["qianbenying"] = "123456789",
	["renyu"] = "123456789",
	["ruanji"] = "123456789",
	["shamoke"] = "123456789",
	["simahui"] = "123457",
	["simashi"] = "123456789",
	["simayi"] = "123456789",
	["simazhao"] = "123456789",
	["spring"] = "123456789",
	["sunce"] = "123456789",
	["sunjian"] = "123456789",
	["sunqian"] = "123456789",
	["sunquan"] = "123456789",
	["sunshangxiang"] = "123456789",
	["sunwukong"] = "123456789",
	["taishici"] = "123456789",
	["tianfeng"] = "123456789",
	["tongyuan"] = "123456789",
	["valentine"] = "123456789",
	["wanglang"] = "123456789",
	["wangshuang"] = "123456789",
	["wangyuanji"] = "123456789",
	["wangyun"] = "123456789",
	["wawa"] = "123456789",
	["weiyan"] = "123456789",
	["wenchou"] = "123456789",
	["xiahouba"] = "123456789",
	["xiahoudun"] = "123456789",
	["xiahoujuan"] = "123456789",
	["xiahouxuan"] = "123456789",
	["xiahouyuan"] = "123456789",
	["xiangchong"] = "123456789",
	["xiaoqiao"] = "123456789",
	["xuchu"] = "123456789",
	["xuelingyun"] = "123456789",
	["xuhuang"] = "123456789",
	["xunyou"] = "123456789",
	["xunyu"] = "123456789",
	["xusheng"] = "123456789",
	["xushu"] = "12345678",
	["yangwan"] = "123456789",
	["yangxiu"] = "123456789",
	["yanliang"] = "123456789",
	["yanyue"] = "123456789",
	["yidazhengzong"] = "123456789",
	["yuanfeizuozhu"] = "123456789",
	["yuanshao"] = "123456789",
	["yuanshu"] = "123456789",
	["yuejin"] = "123456789",
	["yufan"] = "123456789",
	["yuji"] = "123456789",
	["yujin"] = "123456789",
	["yutu"] = "123456789",
	["zhangbao"] = "123456789",
	["zhangchunhua"] = "123456789",
	["zhangdaoling"] = "123456789",
	["zhangerbao"] = "123456789",
	["zhangfei"] = "123456789",
	["zhanghe"] = "123456789",
	["zhanghong"] = "123456789",
	["zhangjiao"] = "123456789",
	["zhangliang"] = "123456789",
	["zhangliao"] = "123456789",
	["zhanglu"] = "123456789",
	["zhangxiu"] = "123456789",
	["zhangzhao"] = "12345689",
	["zhangzhongjing"] = "123456789",
	["zhaoyun"] = "123456789",
	["zhenji"] = "123456789",
	["zhentianxingcun"] = "123456789",
	["zhitianxinchang"] = "123456789",
	["zhitianxinnai"] = "123456789",
	["zhonghui"] = "123456789",
	["zhongyao"] = "123456789",
	["zhoutai"] = "123456789",
	["zhouyu"] = "123456789",
	["zhugejin"] = "123456789",
	["zhugeke"] = "123456789",
	["zhugeliang"] = "123456789",
	["zhuran"] = "123456789",
	["zhurong"] = "123456789",
	["zilong"] = "123456789",
	["zuoci"] = "123456789",
}

-- Every index in a girl's string is a slot the published tree carries.
-- END GENERATED

local gxbWarmAttempts = 0
local gxbWarmRunning = false
local gxbWarmArmed = false

local function gxbWarmEnabled()
	return cc.UserDefault:getInstance():getBoolForKey(GXB_LEGACY_VOICE_KEY, false)
end

local function gxbWarmSchedule(delay)
	local director = cc.Director and cc.Director:getInstance()

	if not director or not director.getScheduler then
		return
	end

	director:getScheduler():scheduleScriptFunc(gxbWarmLegacyVoices, delay, false)
end

function gxbWarmLegacyVoices()
	if gxbWarmRunning or gxbWarmAttempts >= GXB_WARM_MAX_ATTEMPTS then
		return
	end

	if not gxbWarmEnabled() then
		return
	end

	local download = var_0_1.get()

	if not download or not download.getDownloadVersionInfo or not download.downloadFiles then
		return
	end

	local paths = {}

	for girl, slots in pairs(GXB_LEGACY_VOICES) do
		for index in slots:gmatch("%d") do
			table.insert(paths, GXB_LEGACY_VOICE_ROOT .. girl .. "/" .. girl .. "_voice" .. index .. ".ogg")
		end
	end

	local rows = download:getDownloadVersionInfo(paths)

	if type(rows) ~= "table" or #rows == 0 then
		return
	end

	gxbWarmAttempts = gxbWarmAttempts + 1
	gxbWarmRunning = true
	print("gxb-legacy-voice: warming " .. #rows .. " files (attempt " .. gxbWarmAttempts .. ")")

	download:downloadFiles(rows, function(gxbWarmPercent, gxbWarmDone)
		if not gxbWarmDone then
			return
		end

		gxbWarmRunning = false
		print("gxb-legacy-voice: warm pass done")

		if gxbWarmAttempts < GXB_WARM_MAX_ATTEMPTS then
			gxbWarmSchedule(GXB_WARM_RETRY_DELAY)
		end
	end)
end

xyd.gxbLegacyVoiceWarm = gxbWarmLegacyVoices

-- Arm once the singleton is first used (boot), not at module load, so the scheduler and the user setting exist.
local gxbWarmGet = var_0_1.get

function var_0_1.get()
	local instance = gxbWarmGet()

	if not gxbWarmArmed then
		gxbWarmArmed = true
		gxbWarmSchedule(GXB_WARM_FIRST_DELAY)
	end

	return instance
end
