-- @Author: WangZh
-- @Date:   2016-07-16 10:10:37
-- @Last Modified by:   ZhuL
-- @Last Modified time: 2017-09-21 11:38:39

setmetatable(_G, {
    __newindex = function(_, name, value)
        rawset(_G, name, value)
    end
})
print = release_print

require "lib.aeslua"
require "cocos.cocos2d.Cocos2d"
require "cocos.cocos2d.Cocos2dConstants"
require "cocos.init"
require "cocos.cocos2d.json"

require_ex("data.ConfigCom")
require_ex("util.util_init")

APP_ID = 10001
APP_KEY = "5b48da2313dddcd719f99c07f6466b20"
if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_IPAD
    or cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_IPHONE then
    APP_ID = 10002
    APP_KEY = "88wgtDTxsLz30xsjIt5wfkXsOjev4ypiemcwt9FbyI1kljvtieqejCf7rml3nEoq"
end

-- APK静默下载
UpdApkSilent = true

GAME_OPEN_C_ASSERT = false

-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 2

--@ game ids
WAIT_TYPE =
{
    NORMAL = 1,
    RUN_ANI = 2,
    NET_BAD = 3,
    WAIT_CLOSE = 4,
}

--@ game ids
SCENCE_ID =
{
    LOGO = 1,
    LOGIN = 2,
    PLATEFORM = 3,
    GAME1 = 4,
    GAME2 = 5,
    DDZ = 6,
    TCS = 7,
    GAME3 = 8,
    GAME4 = 9,
    GAME5 = 10,
    GAME6 = 11,
    GAME7 = 12,
    GAME8 = 13,
    GAME10 = 15,
}

GAMESIDX_TO_SCENCE_ID = {
    [1] = SCENCE_ID.GAME1,
    [2] = SCENCE_ID.GAME2,
    [3] = SCENCE_ID.GAME3,
    [4] = SCENCE_ID.GAME4,
    [5] = SCENCE_ID.GAME5,
    [6] = SCENCE_ID.GAME6,
    [7] = SCENCE_ID.GAME7,
    [8] = SCENCE_ID.GAME8,
    [10] = SCENCE_ID.GAME10,
}

SVR_2_CLN = {
    [8] = 7,
    [9] = 8,
}

--游戏功能
-- @ RECHARGE 充值 GM命令 JUN 集  VIP 会员 SINGNIN 签到 CHIJI 找刺激 BAOXIANG 宝箱 SUN_ER_NIANG 孙二娘 DUIHUANG 兑换
FUNC_TAB = {
    [1] = "RECHARGE",          --充值
    [2] = "GM",                --GM
    [3] = "JUN",               --聚宝阁
    [4] = "VIP",               --VIP
    [5] = "SINGNIN",           --签到
    [6] = "CHIJI",             --找刺激
    [7] = "BAOXIANG",          --宝箱
    [8] = "SUN_ER_NIANG",      --荷官
    [9] = "DUIHUANG",          --兑换
    [10] = "ACTIVITY",         --活动
    [11] = "TASK",             --任务
    [12] = "MATCH",            --比赛
    [13] = "HEROBOOK",         --英雄图鉴
    [14] = "STORE",            --商城
    [15] = "BAG",              --背包
    [16] = "ONLINE",           --在线礼包相关
    [17] = "MAIL",             --邮件
    [18] = "CB_PACK",          --主界面收纳按钮
    [19] = "BAG_DETAIL",       --背包详情
    [20] = "SYS_NOTICE",       --系统公告
    [21] = "RECHARGE_GIFT",    -- 充值赠送
    [22] = "ONLINE_NUM",       -- 主界面在线
    [23] = "HERO_MODE",        -- 斗地主英雄模式
    [24] = "RECHARGE_SKIP",    -- 是否直接打开充值界面跳过首冲
    [25] = "CMD_UPD",          -- CMD模块
    [26] = "JIPAIQI",          -- 记牌器开关
    [27] = "IOS_CHECK",        -- IOS审核
    [28] = "VIP_SYMBOL",       -- 是否开启VIP logo
    [29] = "MATCH_TEL_RCG",    -- 比赛话费场
    [30] = "APP_STORE",        -- 是否苹果充值
    [31] = "EXPLAIN",          -- 是否开启帮助
    [32] = "UPD_CHECK",        -- 是否开启更新
    [33] = "LUCKY_LOT",        -- 是否幸运转盘
    [34] = "RANKING",          -- 是否开启排行榜
    [35] = "GIFT_BOX",         -- 是否开启超值礼包
}

GAME_OPEN_FUNC_CFG = {
    RECHARGE        = {true, true},     -- 充值
    GM              = {true, true},     -- GM
    JUN             = {true, true},     -- 聚宝阁
    VIP             = {true, true},     -- VIP
    SINGNIN         = {true, true},     -- 签到
    CHIJI           = {true, true},     -- 找刺激
    BAOXIANG        = {true, true},     -- 宝箱
    SUN_ER_NIANG    = {true, true},     -- 荷官
    DUIHUANG        = {true, true},     -- 兑换
    ACTIVITY        = {true, true},     -- 活动
    TASK            = {true, true},     -- 任务
    MATCH           = {true, true},     -- 比赛
    HEROBOOK        = {true, true},     -- 英雄图鉴
    STORE           = {true, true},     -- 商城
    BAG             = {true, true},     -- 背包
    ONLINE          = {true, true},     -- 在线礼包相关
    MAIL            = {true, true},     -- 邮件
    CB_PACK         = {true, true},     -- 主界面收纳按钮
    BAG_DETAIL      = {true, true},     -- 背包详情
    SYS_NOTICE      = {true, true},     -- 系统公告
    RECHARGE_GIFT   = {true, true},     -- 充值赠送
    ONLINE_NUM      = {true, true},     -- 主界面在线
    HERO_MODE       = {true, true},     -- 斗地主英雄模式
    RECHARGE_SKIP   = {false, true},    -- 是否直接打开充值界面跳过首冲
    CMD_UPD         = {true, true},     -- CMD模块
    JIPAIQI         = {true, true},     -- 记牌器开关
    IOS_CHECK       = {false, true},    -- IOS审核
    VIP_SYMBOL      = {true, true},     -- 是否开启VIP logo
    MATCH_TEL_RCG   = {true, true},     -- 比赛话费场
    APP_STORE       = {false, true},    -- 是否苹果充值
    EXPLAIN         = {true, true},     -- 是否开启帮助
    UPD_CHECK       = {true, true},     -- 是否开启更新
    LUCKY_LOT       = {true, false},    -- 幸运轮盘
    RANKING         = {true, true},     -- 排行榜
    GIFT_BOX        = {true, true},     -- 超值礼包
}

GS_FUNC_CFG = {
    [17] = GAME_OPEN_FUNC_CFG.JUN,
}

-- 是否显示服务器选择按钮
SHOW_SEVER_SELECT = true

--开放列表
OPEN_LIST = {1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,0,0}
-- OPEN_LIST = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1}
--限制列表
LIMIT_LIST = {1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1}

-- use framework, will disable all deprecated API, false - use legacy API
CC_USE_FRAMEWORK = true

-- show FPS on screen
CC_SHOW_FPS = false

-- disable create unexpected global variable
CC_DISABLE_GLOBAL = true

GAME_USE_SCALE_UNKNOWN = true

FORCE_UI_CENTER = "center"

-- for module display
CC_DESIGN_RESOLUTION = {
    width = 1280,
    height = 720,
    autoscale = "UNKNOWN" --UNKNOWN  SHOW_ALL
}

CC_DESIGN_RESOLUTION_PAD = {
    width = 1280,
    height = 720,
    autoscale = "EXACT_FIT"
}

UIZorder = {
    TipsHeight = 3000,
    Highest = 2000,
    MsgTips  = 1024,
    Dialog = 400,
    PopWin = 400,
    Guide = 300,
    Hud = 50,
    ToolGain = 110,
    UILayer  = 100,
}

-- 系统限制是否开启
SYS_LIMITED = false

-- NEED_GUIDE = true

-- 开启主动弹窗
-- OPEN_ACTIVE_POP = true

-- 新用户自动登录游客账号
AUTO_VISITOR = false

LOGIN_DELAY = 0.2

-- 是否自动登录
AUTO_LOGIN = true

LOGIN_SKEY = "5b48da2313dddcd719f99c07f6466b20"

HOST_COUNTRY = "null"

DOMAIN_NAME = "gserverddz.mmcy808.com"
DOMAIN_NAME = "ddzandroiddev.mmcy808.com"
--@外网测试
if platform_util.isTestPackage() then
    DOMAIN_NAME = "ddzandroiddev.mmcy808.com"

--@外网同步
elseif platform_util.isTongBuPackage() then
    DOMAIN_NAME = "ddzandroidsyc.mmcy808.com"

--@外网android新服
elseif sdk_util.isMMSDK() then
    DOMAIN_NAME = "gserverddz.mmcy808.com"
end

--@begin-- 其他地址默认值及配置值 --
WEB_PAGE_NAME = "www.mmcy808.com"
LOGIN_HOST = "http://123.207.31.192:11001/"
PHP_HOST = "http://"..DOMAIN_NAME..":8888/"
RECHARGE_HOST = "http://"..DOMAIN_NAME..":8002/"
UPDNOTICE_PAGE = "http://www.mmcy818.cc/page/yxddz/game/notice.html"
host = cc.LuaCHelper:theHelper():getHostIP(DOMAIN_NAME)
port = 7788

if ServerListConfig and ServerListConfig[DOMAIN_NAME] then
    port = ServerListConfig[DOMAIN_NAME].port
    WEB_PAGE_NAME = ServerListConfig[DOMAIN_NAME].web_host
    LOGIN_HOST = ServerListConfig[DOMAIN_NAME].login_host
    PHP_HOST = ServerListConfig[DOMAIN_NAME].php_host
    RECHARGE_HOST = ServerListConfig[DOMAIN_NAME].recharge_host
    UPDNOTICE_PAGE = ServerListConfig[DOMAIN_NAME].updnotice_page
    GAME_OPEN_FUNC_CFG.GM[1] = ServerListConfig[DOMAIN_NAME].gm_state == 1
end
-- 迁移平台登录
-- LOGIN_HOST = "http://211.159.187.59:8001/"
--@end-- 其他地址默认值及配置值 --

--@打包需要关注  begin--------------------------------------------
-- host = "192.168.0.123"      --@晓鹏 Gate 服务器配置
-- port = 7777

host = "192.168.50.225"       --@伟栓 Gate 服务器配置
port = 8888

-- host = "192.168.0.161"      --@祥被 Gate 服务器配置
-- port = 7777

-- host = "192.168.0.253"       --@康华 Gate 服务器配置
-- port = 7777

-- host = "123.207.12.54"      --@版署 服务器配置
-- port = 7777

-- host = "192.168.0.200"      --@内网主干 Gate 服务器配置
-- port = 7777

-- host = "192.168.0.144"       --@DK Gate 服务器配置
-- port = 7777

-- host = "123.207.12.54"      --@外网测试 服务器配置
-- port = 7788

if host ~= nil then
    print(host)
end

if string.find(host, "192.168") then
    PHP_HOST = "http://123.207.12.54:8888/"
end

require_ex "protocolnew.slg_protocol"
netCom = require_ex "lib.netCom"
netCom.startSchedule()