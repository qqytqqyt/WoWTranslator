NativeLinks_base = "5.5.1.63421";   -- version
NativeLinks_date = "2025-09-27"; -- date of creation base

NativeLinks_lang = "en";      -- language

if (GetLocale() == "zhCN") then
    NativeLinks_Messages = {   
        loaded     = "加载完成", 
        loaderror  = "NativeLinks加载错误，请下载最新版本。",
        loaderrorexp = "NativeLinks加载错误，请下载对应资料片版本的客户端。",
        newversion = "NativeLinks有新版本，请及时在CurseForge或其他平台更新。",
        isactive   = "已启用", 
        isinactive = "未启用",         
        author     = "作者：Shek'zeer (EU classic) - Nekomio",
    };
else
    NativeLinks_Messages = {   
        loaded     = "Loaded", 
        loaderror  = "NativeLinks load error, please download the latest version.",
        loaderrorexp = "Failed to load NativeLinks, please download the addon matching the current expansion.",
        newversion = "NativeLinks has a more recent version, please update it from CurseForge or other platform.",
        isactive   = "Active", 
        isinactive = "InActive", 
        author     = "Author: Shek'zeer (EU classic) - Nekomio",
    };
end