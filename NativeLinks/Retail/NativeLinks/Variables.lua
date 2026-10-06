NativeLinks_base = "12.1.0.69933";   -- version
NativeLinks_date = "2026-10-06"; -- date of creation base

NativeLinks_lang = "en";      -- language

if (GetLocale() == "zhCN") then
    NativeLinks_Messages = {
        loaded     = "加载完成",
        loaderror  = "NativeLinks加载错误，请下载最新版本。",
        loaderrorexp = "NativeLinks加载错误，请下载对应资料片版本的客户端。",
        newversion = "NativeLinks有新版本，请及时在CurseForge或其他平台更新。",
        isactive   = "已启用",
        isinactive = "未启用",
        author     = "作者：Silvermoon (EU) - Nekonia",

        cmdon          = "NativeLinks 已启用。",
        cmdoff         = "NativeLinks 已停用。",
        cmdchaton      = "NativeLinks：已开启其他玩家消息中的链接翻译。",
        cmdchatoff     = "NativeLinks：已关闭其他玩家消息中的链接翻译。",
        cmdchatboth    = "NativeLinks：其他玩家的链接将并排显示译名与原名。",
        cmdchatreplace = "NativeLinks：其他玩家的链接将只显示译名。",
        help = {
            "/nl on                      - 启用链接改写",
            "/nl off                     - 停用链接改写",
            "/nl chat on                 - 翻译其他玩家消息中的链接",
            "/nl chat off                - 不翻译其他玩家消息中的链接",
            "/nl chat both               - 译名与原名并排显示",
            "/nl chat replace            - 用译名替换原名",
            "/nl config                  - 打开设置面板",
        },

        optactive      = "启用 Native Links",
        optactivetip   = "将你发送的链接改写为英文名称，并在鼠标提示中显示英文名称。",
        optchat        = "翻译其他玩家消息中的链接",
        optchattip     = "将其他玩家发送的物品、法术和成就链接显示为当前客户端语言的名称。",
        optmode        = "链接显示方式",
        optmodetip     = "并排显示：在译名后的括号中保留原名。替换原名：只显示译名。",
        optmodeboth    = "译名与原名并排显示",
        optmodereplace = "用译名替换原名",
    };
else
    NativeLinks_Messages = {
        loaded     = "Loaded",
        loaderror  = "NativeLinks load error, please download the latest version.",
        loaderrorexp = "Failed to load NativeLinks, please download the addon matching the current expansion.",
        newversion = "NativeLinks has a more recent version, please update it from CurseForge or other platform.",
        isactive   = "Active",
        isinactive = "InActive",
        author     = "Author: Silvermoon (EU) - Nekonia",

        cmdon          = "NativeLinks enabled.",
        cmdoff         = "NativeLinks disabled.",
        cmdchaton      = "NativeLinks: links in other players' messages are translated.",
        cmdchatoff     = "NativeLinks: links in other players' messages are no longer translated.",
        cmdchatboth    = "NativeLinks: translated links show the translation and the original side by side.",
        cmdchatreplace = "NativeLinks: translated links show the translation only.",
        help = {
            "/nl on                      - enable link rewriting",
            "/nl off                     - disable link rewriting",
            "/nl chat on                 - translate the links in other players' messages",
            "/nl chat off                - do not translate the links in other players' messages",
            "/nl chat both               - show the translation and the original side by side",
            "/nl chat replace            - replace the original with the translation",
            "/nl config                  - open the options",
        },

        optactive      = "Enable Native Links",
        optactivetip   = "Rewrite the links you post into English and show the English name in tooltips.",
        optchat        = "Translate links in other players' messages",
        optchattip     = "Show the item, spell and achievement links posted by other players in the language of your game client.",
        optmode        = "Translated link display",
        optmodetip     = "Side by side keeps the original name in brackets after the translation. Replace shows the translation only.",
        optmodeboth    = "Translation and original side by side",
        optmodereplace = "Replace the original",
    };
end