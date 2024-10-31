--
--
--
--
local fileInstance = cc.FileUtils:getInstance()
fileInstance:setPopupNotify(false)

local writablePath = fileInstance:getWritablePath()
fileInstance:createDirectory(writablePath.."/update/")

fileInstance:addSearchPath("src/", true)
fileInstance:addSearchPath("res/", true)

fileInstance:addSearchPath(writablePath.."/update/", true)
fileInstance:addSearchPath(writablePath.."/update/".."src/", true)
fileInstance:addSearchPath(writablePath.."/update/".."res/", true)
require("main")