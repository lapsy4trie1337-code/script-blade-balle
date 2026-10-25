local ok, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/lapsy4trie1337-code/script-blade-ball/main/blade-ball-autoparry.lua", true))()
end)
if not ok then warn(err) end
