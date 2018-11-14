--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleBackgroundData.lua");
local StyleBackgroundData = commonlib.gettable("System.Windows.mcml.style.StyleBackgroundData");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/OutlineValue.lua");
local OutlineValue = commonlib.gettable("System.Windows.mcml.style.OutlineValue");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");

local StyleBackgroundData = commonlib.gettable("System.Windows.mcml.style.StyleBackgroundData");
StyleBackgroundData.__index = StyleBackgroundData;

function StyleBackgroundData:new(background, color, outline)
	local o = {};
	-- background is standard string
	o.m_background = background;
	-- color is standard string
	o.m_color = color or ComputedStyle.initialBackgroundColor();

	o.m_outline = outline or OutlineValue:new();

	setmetatable(o, self);
	return o;
end

function StyleBackgroundData:clone()
	return StyleBackgroundData:new(self.m_background, self.m_color:clone(), self.m_outline:clone());
end

function StyleBackgroundData:Background()
	return self.m_background;
end

StyleBackgroundData.Image = StyleBackgroundData.Background;

function StyleBackgroundData:Color()
	return self.m_color;
end

function StyleBackgroundData:Outline()
	return self.m_outline;
end

function StyleBackgroundData.__eq(a, b)
	return a.m_background == b.m_background and a.m_color == b.m_color and a.m_outline == b.m_outline;
end

function StyleBackgroundData.Create()
	return StyleBackgroundData:new();
end

function StyleBackgroundData:copy()
	return self:clone();
end