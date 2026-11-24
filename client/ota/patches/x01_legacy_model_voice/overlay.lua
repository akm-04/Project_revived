-- x01: the model's own voice files (idle, victory, attacks, death) follow the same legacy switch.
--
-- The hero page's 2.5D bust plays xyd.tables.model:getAttack4Sound(modelId), and the battle/stand-up animations read the
-- other model sound columns (model.lua sound_move/sound_victory/sound_skill0..4), so wrapping only the hero-table
-- accessors leaves those on the modern cast. model.lua points each of those columns at the same nine hero voice files,
-- and the 1.164.0 client used the identical columns, so the only difference here is which file the path resolves to.
--
-- Availability comes from the generated manifest rather than a lazy-catalogue lookup, so a slot the published tree
-- carries is always redirected; x01_voice_on_demand downloads it and falls back to the stock line only when the fetch
-- fails.

local GXB_LEGACY_VOICE_KEY = "gxb_legacy_voice"
local GXB_VOICE_PREFIX = "sound/hero_sound/"
local GXB_VOICE_LEGACY_ROOT = "sound/legacy2018/hero_sound/"

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

local function gxbModelLegacyEnabled()
	return cc.UserDefault:getInstance():getBoolForKey(GXB_LEGACY_VOICE_KEY, false)
end

local function gxbModelLegacyParts(path)
	local relative = path:sub(#GXB_VOICE_LEGACY_ROOT + 1)
	local girl, name = relative:match("^([^/]+)/([^/]+)$")

	if not girl or not name then
		return nil
	end

	local index = name:match("_voice(%d)%.ogg$")

	if not index then
		return nil
	end

	return girl, tonumber(index)
end

local function gxbModelLegacyAvailable(path)
	if cc.FileUtils:getInstance():isFileExist(path) then
		return true
	end

	local girl, index = gxbModelLegacyParts(path)
	local slots = girl and GXB_LEGACY_VOICES[girl]

	if slots and slots[index] then
		return true
	end

	local download = xyd.AssetDownload and xyd.AssetDownload.get and xyd.AssetDownload.get()

	if not download or not download.getDownloadVersionInfo then
		return false
	end

	local rows = download:getDownloadVersionInfo({ path })

	return rows ~= nil and #rows > 0
end

local function gxbModelLegacyMap(path)
	if type(path) ~= "string" or path == "" then
		return path
	end

	if not gxbModelLegacyEnabled() then
		return path
	end

	if path:sub(1, #GXB_VOICE_PREFIX) ~= GXB_VOICE_PREFIX then
		return path
	end

	local legacy = GXB_VOICE_LEGACY_ROOT .. path:sub(#GXB_VOICE_PREFIX + 1)

	if not gxbModelLegacyAvailable(legacy) then
		return path
	end

	return legacy
end

for _, gxbModelAccessor in ipairs({
	"getMoveSound",
	"getWinSound",
	"getNormalAttackSound",
	"getAttack1Sound",
	"getAttack2Sound",
	"getAttack3Sound",
	"getAttack4Sound",
	"deathSound",
}) do
	local gxbModelOriginal = var_0_2[gxbModelAccessor]

	if gxbModelOriginal then
		var_0_2[gxbModelAccessor] = function(gxbModelSelf, gxbModelId)
			return gxbModelLegacyMap(gxbModelOriginal(gxbModelSelf, gxbModelId))
		end
	end
end
