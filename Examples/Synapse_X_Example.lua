_G.ECB_Settings = {
	Open_Keybind = Enum.KeyCode.Home,
	Output_Keybind = Enum.KeyCode.F6,
	Debug = false
}

local ECB = loadstring(game:HttpGet("https://raw.githubusercontent.com/plainenglishh/Extended-Command-Bar/main/library.lua", true))() -- Execute the Command Bar
ECB.RegisterCommands({
  ["btools"] = {
		Description = "Spawns btools.",
		Usage = "btools",
		Callback = function(Args)
			Instance.new("HopperBin", LocalPlayer:FindFirstChildOfClass("Backpack")).BinType = 1
			Instance.new("HopperBin", LocalPlayer:FindFirstChildOfClass("Backpack")).BinType = 2
			Instance.new("HopperBin", LocalPlayer:FindFirstChildOfClass("Backpack")).BinType = 3
			Instance.new("HopperBin", LocalPlayer:FindFirstChildOfClass("Backpack")).BinType = 4
      ECB.Console.Out("Gave btools!", "success")
		end
	}
})

