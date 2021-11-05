# Extended Command Bar Docs
ECB is a simple to use command bar library designed for Roblox. ECB is **not** made with production software in mind but feel free to use it for that use if you wish. ECB was designed to be used with Synapse X but it could be ported over to regular roblox by soemone else. I do not plan to do this at the moment.

# Loading the ECB Module

To load the ECB Module, create a variable referencing the loadstring.
```lua
local ECB = loadstring(game:HttpGet("https://raw.githubusercontent.com/plainenglishh/Extended-Command-Bar/main/library.lua", true))()
```

If for whatever reason the above code works, go to https://raw.githubusercontent.com/plainenglishh/Extended-Command-Bar/main/library.lua and copy the code, paste it into pastebin and use the raw link for that as a temporary replacement.

# ECB Library
The variable referenced above will contain a table with the following functions / globals.
* RegisterCommands(Commands: table)
* SetTheme(<void>) [NOT FUNCTIONAL YET]
* Console: table
* GetTextColour(Colour Name: string)  
