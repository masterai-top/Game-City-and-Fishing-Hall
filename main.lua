-- @Author: WangZh
-- @Date:   2016-07-16 10:10:37
-- @Last Modified by:   WangZh
-- @Last Modified time: 2016-08-26 15:24:57

local fileInstance = cc.FileUtils:getInstance()
fileInstance:setPopupNotify(false)

local writablePath = fileInstance:getWritablePath()
fileInstance:createDirectory(writablePath.."/update/")

fileInstance:addSearchPath("src/", true)
fileInstance:addSearchPath("res/", true)

fileInstance:addSearchPath(writablePath.."/update/", true)
fileInstance:addSearchPath(writablePath.."/update/".."src/", true)
fileInstance:addSearchPath(writablePath.."/update/".."res/", true)

local targetPlatform = cc.Application:getInstance():getTargetPlatform()

local ignorNames = {
    ["math"] = true,
    ["string"] = true,
    ["table"] = true,
}

function require_ex( _mname )
    if ignorNames[_mname] ~= nil then
        return require(_mname)
    end
    --print( string.format("require_ex = %s", _mname) )
    if package.loaded[_mname] then
        --print( string.format("require_ex module[%s] reload", _mname))
    end
    package.loaded[_mname] = nil
    return require(_mname)
end

require_ex "game_config"
require_ex "cocos.init"

local function initFont()
   cc.Configuration:getInstance():setValue("GAME_DEFAULT_FONT_NAME", "gameres/fonts/fangzhengcuyuan.ttf")
end

local function startCMD()
    local configs = {
        viewsRoot  = "cmd",
        modelsRoot = "cmd",
        defaultSceneName = "CMDUpdater",
    }
    require_ex("cmd.CMDApp"):create(configs):run()
end

local function startGame()
    require_ex "GameClass"
    Game:init()

    -- sdk等待回调
    if not sdk_util.isThirdSDK() then
        Game:gameStart()
    end
end

local function iosReset()
    -- if (cc.PLATFORM_OS_IPHONE == targetPlatform  or cc.PLATFORM_OS_IPAD == targetPlatform) then
    --     PHP_HOST = "http://"..DOMAIN_NAME..":8888/"
    -- end
end

local function preStartGame()
    if cc.UserDefault:getInstance():getBoolForKey("game_reload") then
        cc.UserDefault:getInstance():setBoolForKey("game_reload", false)
        startGame()
    else
        startCMD()
    end
end

local function setOpenList(list)
    for index , num in ipairs(list) do
        local key = FUNC_TAB[index]
        local bOpen = (num == 1)
        if type(GAME_OPEN_FUNC_CFG[key]) == "table" then
            GAME_OPEN_FUNC_CFG[key][1] = bOpen
        end
    end
end

local function checkCountry()
    local confOpenList =  {1,0,1,0,0,0,1,1,0,0,1,1,1,1,1,0,0,1,1,0,0,1,1,1,0,1,1,0,0,1,0,0,0,0,0}
    setOpenList(confOpenList)
    local httpCom = require("util.HttpCom")
    --local urlCheck = "http://cn2.open.mmcy808.com/block-func-list"
    local urlCheck = "http://cn2.open.mmcy808.com/get-app-info"
    local check_key = "5b48da2313dddcd719f99c07f6466b20"
    local currtime = os.time()
    local packageId = platform_util.getAppBundleId()
    local version = platform_util.getAppVersion()
    -- packageId = "com.mcy.jxyxddz"
    -- version = "1.42.00"
    local sign = common_util.md5(check_key.."package_id"..packageId.."version"..version.."enc1".."time_stamp"..currtime..check_key)
    local url = urlCheck
    url = url.."?package_id="..packageId
    url = url.."&version="..version
    url = url.."&time_stamp="..currtime
    url = url.."&flag="..sign
    url = url.."&enc=1"

    local function _callback(info)
        --dump(info)
        local testBody = aeslua.decryptSimple("789xMen123DdZ456", info, aeslua.AES128, aeslua.ECBMODE);
        --dump(testBody)
        local t = json.decode(testBody)
        dump(t)
        if t ~= nil and type(t) == "table" then
            local retcode = t.ret_code
            if tonumber(retcode) == 0 then
                cc.exports.HOST_COUNTRY = t.alpha2
                cc.exports.ONLINE_SVR_VER = t.cur_server_ver
                cc.exports.NEW_APP_DOWNLOAD = t.update_url

                local nowVersion = platform_util.getAppVersion()
                -- nowVersion = "1.42.00"

                if nowVersion ~= ONLINE_SVR_VER then
                    if ONLINE_SVR_VER < nowVersion then
                        DOMAIN_NAME = "ddziosts.mmcy808.com"
                        dump(DOMAIN_NAME)
                        if ServerListConfig and ServerListConfig[DOMAIN_NAME] then
                            host = cc.LuaCHelper:theHelper():getHostIP(ServerListConfig[DOMAIN_NAME].host_name)
                            port = ServerListConfig[DOMAIN_NAME].port
                            WEB_PAGE_NAME = ServerListConfig[DOMAIN_NAME].web_host
                            LOGIN_HOST = ServerListConfig[DOMAIN_NAME].login_host
                            PHP_HOST = ServerListConfig[DOMAIN_NAME].php_host
                            RECHARGE_HOST = ServerListConfig[DOMAIN_NAME].recharge_host
                            UPDNOTICE_PAGE = ServerListConfig[DOMAIN_NAME].updnotice_page
                            GAME_OPEN_FUNC_CFG.GM[1] = (ServerListConfig[DOMAIN_NAME].gm_state == 1)
                        end
                    end
                end

                local appState = tonumber(t.audit_status)
                if appState == 1 then
                    local blockList = t.block_function
                    if #blockList > 0 then
                        local allOpenList = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
                        for k,v in pairs(blockList) do
                            local index = tonumber(v)
                            if allOpenList[index] ~= nil then
                                allOpenList[index] = 1
                            end
                        end
                        allOpenList[2] = 0  --gm指令始终不开启
                        setOpenList(allOpenList)
                    end
                end
            else
                cc.exports.HOST_COUNTRY = ""
                local nowVersion = platform_util.getAppVersion()
                cc.exports.ONLINE_SVR_VER = nowVersion
            end
        end
        preStartGame()
    end

    local function _callbackf(info)
        cc.exports.HOST_COUNTRY = ""
        local nowVersion = platform_util.getAppVersion()
        cc.exports.ONLINE_SVR_VER = nowVersion
        preStartGame()
    end
    dump(url)
    httpCom:httpGet(url, _callback, _callbackf)
end

local function main()
    cc.Director:getInstance():setLogFilePath(platform_util.getStorageEx().."/gamelog.log")
    cc.FileUtils:getInstance():writeStringToFile("Game Begin >>>\n", cc.Director:getInstance():getLogFilePath())
    iosReset()
    initFont()
    if (cc.PLATFORM_OS_IPHONE == targetPlatform  or cc.PLATFORM_OS_IPAD == targetPlatform)  then
        checkCountry()
        -- local confOpenList =  {1,0,1,0,0,0,1,1,0,0,1,1,1,1,1,0,0,1,1,0,0,1,1,1,0,1,1,0,0,1,0,0,0,0,0}
        -- setOpenList(confOpenList)
        -- cc.exports.HOST_COUNTRY = ""
        -- local nowVersion = platform_util.getAppVersion()
        -- cc.exports.ONLINE_SVR_VER = "1.42.00"
        -- DOMAIN_NAME = "ddziosts.mmcy808.com"
        -- dump(DOMAIN_NAME)
        -- if ServerListConfig and ServerListConfig[DOMAIN_NAME] then
        --     host = cc.LuaCHelper:theHelper():getHostIP(DOMAIN_NAME)
        --     port = ServerListConfig[DOMAIN_NAME].port
        --     WEB_PAGE_NAME = ServerListConfig[DOMAIN_NAME].web_host
        --     LOGIN_HOST = ServerListConfig[DOMAIN_NAME].login_host
        --     PHP_HOST = ServerListConfig[DOMAIN_NAME].php_host
        --     RECHARGE_HOST = ServerListConfig[DOMAIN_NAME].recharge_host
        --     UPDNOTICE_PAGE = ServerListConfig[DOMAIN_NAME].updnotice_page
        --     GAME_OPEN_FUNC_CFG.GM[1] = (ServerListConfig[DOMAIN_NAME].gm_state == 1)
        -- end
        -- preStartGame()
    else
        preStartGame()
    end
    sdk_util.init()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
    if GAME_OPEN_C_ASSERT == true then
        local CHelper = cc.LuaCHelper:theHelper()
        CHelper:luaCAssert()
    end
end
