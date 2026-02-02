-- local random = math.random

-- function request()
--     local ip = string.format("%d.%d.%d.%d", random(0, 255), random(0, 255), random(0, 255), random(0, 255))
--     wrk.headers["X-Forwarded-For"] = ip
--     return wrk.format("GET", path)
-- end

local random = math.random

-- 生成随机字符串
function random_string(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for i = 1, length do
        local rand_index = random(1, #chars)
        result = result .. chars:sub(rand_index, rand_index)
    end
    return result
end

-- 生成随机User-Agent
function random_user_agent()
    local browsers = {
        "Chrome",
        "Firefox", 
        "Safari",
        "Edge"
    }
    
    local os_versions = {
        "Windows NT 10.0; Win64; x64",
        "Windows NT 6.1; WOW64",
        "Macintosh; Intel Mac OS X 10_15_7",
        "X11; Linux x86_64",
        "iPhone; CPU iPhone OS 17_3_1 like Mac OS X",
        "Linux; Android 10; SM-G973F"
    }
    
    local browser = browsers[random(1, #browsers)]
    local os = os_versions[random(1, #os_versions)]
    
    if browser == "Chrome" then
        local major = random(120, 125)
        local minor = random(0, 9)
        local build = random(0, 9999)
        return string.format("Mozilla/5.0 (%s) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%d.%d.%d Safari/537.36", 
                           os, major, minor, build)
    elseif browser == "Firefox" then
        local major = random(115, 125)
        return string.format("Mozilla/5.0 (%s; rv:%d.0) Gecko/20100101 Firefox/%d.0", os, major, major)
    elseif browser == "Safari" then
        local version = random(605, 610)
        local webkit_version = random(15, 17)
        return string.format("Mozilla/5.0 (%s) AppleWebKit/%d.1.15 (KHTML, like Gecko) Version/%d.3.1 Safari/%d.1.15", 
                           os, version, webkit_version, version)
    else -- Edge
        local major = random(120, 125)
        return string.format("Mozilla/5.0 (%s) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%d.0.0.0 Safari/537.36 Edg/%d.0.0.0", 
                           os, major, major)
    end
end

-- 生成随机请求路径
function random_path()
    local path_types = {
        function() return "/" .. random_string(random(3, 10)) end,
        function() return "/" .. random_string(random(3, 8)) .. "/" .. random_string(random(3, 8)) end,
        function() return "/api/v" .. random(1, 3) .. "/" .. random_string(random(3, 8)) end,
        function() return "/" .. random_string(random(3, 6)) .. ".html" end,
        function() return "/" .. random_string(random(3, 6)) .. ".php" end,
        function() return "/static/" .. random_string(random(3, 8)) .. "/" .. random_string(random(3, 10)) .. ".css" end,
        function() return "/static/js/" .. random_string(random(3, 10)) .. ".js" end,
        function() return "/images/" .. random_string(random(3, 10)) .. ".jpg" end,
        function() return "/" .. random_string(random(3, 8)) .. "/" .. random_string(random(3, 8)) .. "/" .. random_string(random(3, 8)) end
    }
    
    return path_types[random(1, #path_types)]()
end

function request()
    -- 生成随机IP
    local ip = string.format("%d.%d.%d.%d", random(0, 255), random(0, 255), random(0, 255), random(0, 255))
    
    -- 生成随机User-Agent
    local random_ua = random_user_agent()
    
    -- 生成随机请求路径
    local random_path = random_path()
    
    -- 设置请求头 - 添加多个IP相关头以模拟真实代理链
    wrk.headers["X-Forwarded-For"] = ip
    wrk.headers["X-Real-IP"] = ip
    wrk.headers["X-Client-IP"] = ip
    wrk.headers["CF-Connecting-IP"] = ip
    wrk.headers["True-Client-IP"] = ip
    wrk.headers["User-Agent"] = random_ua
    
    -- 随机添加其他常用头
    local accept_languages = {"zh-CN,zh;q=0.9", "en-US,en;q=0.8", "ja-JP,ja;q=0.7", "ko-KR,ko;q=0.6"}
    wrk.headers["Accept-Language"] = accept_languages[random(1, #accept_languages)]
    
    local accepts = {"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", "application/json, text/plain, */*"}
    wrk.headers["Accept"] = accepts[random(1, #accepts)]
    
    -- 随机添加Referer
    if random(1, 3) == 1 then  -- 1/3的概率添加Referer
        local domains = {"https://www.google.com", "https://www.baidu.com", "https://github.com", "https://stackoverflow.com"}
        wrk.headers["Referer"] = domains[random(1, #domains)] .. "/search?q=" .. random_string(8)
    end
    
    return wrk.format("GET", random_path)
end

-- wrk -s ./wrk.lua -c 500 -t 8 -d 600s -c 10 http://[target]
-- wrk -s ./wrk.lua -c 500 -t 8 -d 600s -c 150 http://[target]
-- wrk -s ./wrk.lua -c 500 -t 8 -d 600s -c 100000 http://[target]
