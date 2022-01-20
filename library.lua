--[[ Settings ]]--

_G.ECB_Globals = {
	Version = "0.1.0",
	BuildYear = "2021",
}

if not _G.ECB_Settings then _G.ECB_Settings = {} end

_G.ECB_Settings.Open_Keybind = _G.ECB_Settings.Open_Keybind or Enum.KeyCode.Insert
_G.ECB_Settings.Output_Keybind = _G.ECB_Settings.Output_Keybind or Enum.KeyCode.Home
_G.ECB_Settings.Debug = _G.ECB_Settings.Debug or false

--[[ Compatibility ]]--

local Synapse = false
if checkcaller then Synapse = true end

--[[ References ]]--

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local OpenActionName = HttpService:GenerateGUID(false)
local OutputActionName = HttpService:GenerateGUID(false)
local OriginalFieldOfView = Workspace.CurrentCamera.FieldOfView

local function GetTextColour(Type)
	if Type == "default" then
		return Color3.fromRGB(204, 204, 204)
	elseif Type == "err" then
		return  Color3.fromRGB(197, 15, 31)
	elseif Type == "warn" then
		return  Color3.fromRGB(193, 156, 0)
	elseif Type == "info" then
		return  Color3.fromRGB(0, 55, 218)
	elseif Type == "success" then
		return  Color3.fromRGB(19, 161, 14)
	end
end

--[[ GUI Production ]]--

local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = Lighting

local GUI = game:GetObjects("rbxassetid://7904336342")[1]
GUI.Output.Visible = true
if Synapse then syn.protect_gui(GUI) end
GUI.Parent = game:GetService("CoreGui")

local GuiOpen = true

local CommandBarContainer = GUI.CommandBar
local CommandBar = CommandBarContainer.Main
local Output = GUI.Output.ScrollingFrame
local Intellisense = CommandBarContainer.Intellisense

Intellisense.Visible = false
Intellisense.Text = ""

local function SetGuiOpen(Enabled)
	GuiOpen = Enabled
	CommandBarContainer.Visible = Enabled

	TweenService:Create(Blur, TweenInfo.new(0.15), {
		Size = Enabled and 15 or 0
	}):Play()

	TweenService:Create(Workspace.CurrentCamera, TweenInfo.new(0.15), {
		FieldOfView = (not Enabled) and OriginalFieldOfView or OriginalFieldOfView - 5
	}):Play()
end

function toInteger(color)
	return math.floor(color.r*255)*256^2+math.floor(color.g*255)*256+math.floor(color.b*255)
end

function toHex(color)
	local int = toInteger(color)

	local current = int
	local final = ""

	local hexChar = {
		"A", "B", "C", "D", "E", "F"
	}

	repeat local remainder = current % 16
		local char = tostring(remainder)

		if remainder >= 10 then
			char = hexChar[1 + remainder - 10]
		end

		current = math.floor(current/16)
		final = final..char
	until current <= 0

	return "#"..string.reverse(final)
end

local function Sanitise(String)
	String = string.gsub(String, "<", "&lt;")
	String = string.gsub(String, ">", "&gt;")
	String = string.gsub(String, "\"", "&quot;")
	String = string.gsub(String, "'", "&apos;")
	String = string.gsub(String, "&", "&amp;")
	return String
end


--[[ Console Library ]]--

local Console = {}

Console.Out = function(t, colour)
	t = t or ""
	colour = colour or "default"
	if type(colour) == "string" then colour = GetTextColour(colour) end

	t = ("<b><font color=\"%s\">%s</font></b>"):format(toHex(colour), Sanitise(t))
	Output.Out.Text = Output.Out.Text..t.."\n"

	Output.CanvasPosition = Vector2.new(0, 999999999)
end

Console.Clear = function()
	Output.Out.Text = "\n"
end

Output.Out:GetPropertyChangedSignal("Text"):Connect(function()
	Output.Out.Size = UDim2.new(1, 0, 0, Output.Out.TextBounds.Y)
end)

--[[ Utilities Library ]]--

local Utilities = {}

Utilities.GetPlayerMatches = function(Player)
	local Matches = {}
	for _, Player in pairs(Players:GetPlayers()) do
		if Player.Name:sub(1, #Player) == Player then
			table.insert(Matches, Player)
		end
	end
	return Matches
end

Utilities.GetPlayer = function(Player, AllowMultiple)
	if Player:lower() == "me" then
		return LocalPlayer
	elseif Player:lower() == "all" and AllowMultiple then
		return Players:GetPlayers()
	elseif Player:lower() == "others" then
		local PlayersList = Players:GetPlayers()
		table.remove(PlayersList, table.find(PlayersList, LocalPlayer))
		return PlayersList
	else
		for _, Player in pairs(Players:GetPlayers()) do
			if Player.Name:lower():sub(1, #Player) == Player:lower() then
				return Player
			end
		end
	end
end

--[[ Commands ]]--

local Commands
Commands = {
	["print"] = {
		Description = "Prints the inputted arguments.",
		Usage = "print <tuple>",
		Callback = function(Args)
			Console.Out(table.concat(Args, " "))
		end,
	},
	["cmds"] = {
		Description = "Lists all the registered commands.",
		Usage = "cmds",
		Callback = function(Args)
			for Name, Data in pairs(Commands) do
				Console.Out(("<b>%s</b> // %s"):format(Name, Data.Description or "No description specified."))
			end
		end,
	},
	["cls"] = {
		Description = "Clears the console.",
		Usage = "cls",
		Callback = function(Args)
			Console.Clear()
		end,
	},
	["usage"] = {
		Description = "Shows how to use a command.",
		Usage = "usage [Command: string]",
		Callback = function(Args)
			if not Commands[Args[1]] then
				Console.Out("Command not found", "err")
			else
				Console.Out(Commands[Args[1]].Usage or "No usage specified for this command.")
			end
		end,
	}
}

--[[ Command Interpreter ]]--

local function ParseCommand(Cmd: string)
	local CommandName = string.split(Cmd, " ")[1]
	local Arguments = {}

	local CommandArgString = string.sub(Cmd, #CommandName + 2, -1)

	local InString = false
	local PreviousChar = ""
	local CurrentArgText = ""

	for i, Character in pairs(string.split(CommandArgString, "")) do
		if (Character == " " and not InString) or i == #CommandArgString then
			if i == #CommandArgString and Character ~= "\"" then
				CurrentArgText = CurrentArgText..Character
			end

			table.insert(Arguments, CurrentArgText)
			CurrentArgText = ""
		elseif Character == "\"" then
			if PreviousChar ~= "\\" then
				InString = not InString
			end
		else
			CurrentArgText = CurrentArgText..Character
		end

		PreviousChar = Character
	end

	return CommandName, Arguments
end

local function RunCommand(Command, Args)
	if Commands[Command] then
		Commands[Command].Callback(Args)
	else
		Console.Out("Command does not exist!", "err")
	end
end

Output.Parent.Active = true
Output.Parent.Draggable = true

--[[ Command Bar Text Rendering & Cursor ]]--

CommandBar.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
	CommandBar.InputBox.Text = CommandBar.InputBox.Text:gsub("\t", "")
	local FormattedText = CommandBar.InputBox.Text

	FormattedText = FormattedText:gsub("<", "&lt;")
	FormattedText = FormattedText:gsub(">", "&gt;")

	for Command, _ in pairs(Commands) do
		local CommandMatch = ("^%s"):format(Command)
		FormattedText = FormattedText:gsub(CommandMatch, "<b>%1</b>")
	end

	CommandBar.InputDisplay.Text = FormattedText
end)

local CursorCoroutine = coroutine.create(function()
	while wait(0.5) do
		if UserInputService:GetFocusedTextBox() == CommandBar.InputBox then
			CommandBar.InputDisplay.Indicator.Visible = not CommandBar.InputDisplay.Indicator.Visible
		else
			CommandBar.InputDisplay.Indicator.Visible = false
		end
	end
end)

RunService.RenderStepped:Connect(function()
	local SelectedText = string.sub(
		CommandBar.InputBox.Text,
		0,
		CommandBar.InputBox.CursorPosition
	)

	--[[local CurrentChar = string.sub(
		CommandBar.InputBox.Text,
		CommandBar.InputBox.CursorPosition,
		CommandBar.InputBox.CursorPosition
	)]]

	local CursorPos = TextService:GetTextSize(SelectedText, 16, Enum.Font.Gotham, CommandBar.InputDisplay.AbsoluteSize).X
	--local CursorSize = TextService:GetTextSize(CurrentChar, 16, Enum.Font.Gotham, CommandBar.InputDisplay.AbsoluteSize).X
	CommandBar.InputDisplay.Indicator.Position = UDim2.new(0, CursorPos + 1, 0.5, 7)
	--CommandBar.InputDisplay.Indicator.Size = UDim2.new(0, CursorSize, 0, 2)
end)

coroutine.resume(CursorCoroutine)

--[[ Command Bar Running ]]--

CommandBar.InputBox.Focused:Connect(function()
	CommandBar.InputDisplay.Indicator.Visible = true
end)

CommandBar.InputBox.FocusLost:Connect(function(EnterPressed, InputCausingFocusLost)
	if EnterPressed then
		local RawCommand = CommandBar.InputBox.Text
		CommandBar.InputBox.Text = ""
		CommandBar.InputDisplay.Indicator.Visible = false

		if RawCommand ~= "" then
			Console.Out("&gt; "..RawCommand)
			local Success, Response = pcall(RunCommand, ParseCommand(RawCommand))
			if not Success then
				Console.Out("Command failed with: "..Response, "err")
			end
			Console.Out()
		end
	end

	SetGuiOpen(false)
end)

--[[ Intellisense ]]--

local IntellisenseCursor = 1
local IntellisenseCommand = ""

local function IntellisenseFrame()
	if CommandBar.InputBox.Text == "" then Intellisense.Visible = false return end

	local CommandName, _ = ParseCommand(CommandBar.InputBox.Text)
	
	local Matches = {}
	for Cmd, Data in pairs(Commands) do
		if Cmd:lower():sub(1, #CommandName) == CommandName:lower() then
			table.insert(Matches, {Name = Cmd, Text = Data.Usage or Cmd})
		end
	end

	if #Matches ~= 0 then
		IntellisenseCursor = math.clamp(IntellisenseCursor, 1, #Matches)

		local Text = "\n"
		for i, Data in pairs(Matches) do
			local DataText = Data.Text
			DataText = DataText:gsub("<", "&lt;")
			DataText = DataText:gsub(">", "&gt;")

			if i == IntellisenseCursor then
				Text = Text.."<b>&gt; "..DataText.."</b>\n"
				IntellisenseCommand = Data.Name
			else
				Text = Text..DataText.."\n"
			end
		end
		Intellisense.Text = Text
		Intellisense.Visible = true
		Intellisense.Size = UDim2.new(1, 0, 0, Intellisense.TextBounds.Y)
	else
		Intellisense.Visible = false
		IntellisenseCommand = ""
	end
end

CommandBar.InputBox:GetPropertyChangedSignal("Text"):Connect(IntellisenseFrame)

UserInputService.InputEnded:Connect(function(InputObject, GameProcessed)
	if InputObject.KeyCode == Enum.KeyCode.Tab then
		if IntellisenseCommand ~= "" then
			CommandBar.InputBox.Text = IntellisenseCommand.." "
			CommandBar.InputBox.CursorPosition = 999
		end
	elseif InputObject.KeyCode == Enum.KeyCode.Up then
		IntellisenseCursor = IntellisenseCursor - 1
		IntellisenseFrame()
	elseif InputObject.KeyCode == Enum.KeyCode.Down then
		IntellisenseCursor = IntellisenseCursor + 1
		IntellisenseFrame()
	end
end)

--[[ Open Button ]]--

ContextActionService:BindAction(OpenActionName, function(ActionName, InputState, InputObject)
	if InputState == Enum.UserInputState.End then
		SetGuiOpen(true)
		CommandBar.InputBox:CaptureFocus()
	end
end, false, _G.ECB_Settings.Open_Keybind)

ContextActionService:BindAction(OutputActionName, function(ActionName, InputState, InputObject)
	if InputState == Enum.UserInputState.End then
		Output.Parent.Visible = not Output.Parent.Visible
	end
end, false, _G.ECB_Settings.Output_Keybind)

--[[ Export ]]--

SetGuiOpen(false)
if not _G.ECB_Settings.AppData then
	Console.Out(("\nExtended Command Bar Library [%s]\n(C) plainenglish %s"):format(_G.ECB_Globals.Version, _G.ECB_Globals.BuildYear))
else
	Console.Out(("\n%s [%s] (C) %s %s"):format(_G.ECB_Settings.AppData.Name, _G.ECB_Settings.AppData.Version, _G.ECB_Settings.AppData.Author, _G.ECB_Settings.AppData.BuildYear))
	Console.Out(("Powered by Extended Command Bar [%s] (C) plainenglish %s"):format(_G.ECB_Globals.Version, _G.ECB_Globals.BuildYear))
end

if _G.ECB_Settings.Debug then Console.Out("DEBUG MODE ENABLED", "warn") end
Console.Out(("Press %s to toggle the console. Press %s to open the command bar."):format(tostring(_G.ECB_Settings.Output_Keybind), tostring(_G.ECB_Settings.Open_Keybind)), "info")

return {
	RegisterCommands = function(ExtraCommands)
		for Name, Data in pairs(ExtraCommands) do
			Commands[Name] = Data
		end
	end,
	SetTheme = function()

	end,
	Console = Console,
	Utilities = Utilities,
	GetTextColour = GetTextColour
}
