--[[
Title: CSSStyleDeclaration object
Author(s): LiPeng
Date: 2018/1/12
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleDeclaration.lua");
local CSSStyleDeclaration = commonlib.gettable("System.Windows.mcml.css.CSSStyleDeclaration");
local style = CSSStyleDeclaration:new();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSProperty.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");
local CSSProperty = commonlib.gettable("System.Windows.mcml.css.CSSProperty");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");

local type = type;
local tonumber = tonumber;
local string_gsub = string.gsub;
local string_lower = string.lower
local string_match = string.match;
local string_find = string.find;

local StyleChangeTypeEnum = PageElement.StyleChangeTypeEnum;

local CSSStyleDeclaration = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.css.CSSStyleDeclaration"));

function CSSStyleDeclaration:ctor()
	self.pageElement = nil;
	self.properties = commonlib.Array:new();
end

function CSSStyleDeclaration:init(pageElement)
	self.pageElement = pageElement;
	return self;
end

function CSSStyleDeclaration:SetNode(node)
	self.pageElement = node;
end

local property_fields = 
{
	--TODO: add all css properties later
	-- TODO: add css3 animation next step

	-- background
	["background"] = true,
	["background2"] = true,
	["background_checked"] = true,
	["background-color"] = true,
	["background_over"] = true,
	["background_down"] = true,

	-- border ["border"] = "border-width border-style border-color"
	["border-width"] = true,
	["border-style"] = true,
	["border-color"] = true,

	-- box 
	["overflow"] = true,
	["overflow-x"] = true,
	["overflow-y"] = true,

	-- dimension
	["width"] = true,
	["min-width"] = true,
	["max-width"] = true,
	["height"] = true,
	["min-height"] = true,
	["max-height"] = true,

	-- font
	["font"] = true,
	["font-family"] = true,
	["font-size"] = true,
	["font-weight"] = true,

	-- margin
	["margin"] = true,
	["margin-left"] = true,
	["margin-top"] = true,
	["margin-right"] = true,
	["margin-bottom"] = true,

	-- padding
	["padding"] = true,
	["padding-left"] = true,
	["padding-top"] = true,
	["padding-right"] = true,
	["padding-bottom"] = true,

	-- positioning
	["left"] = true,
	["top"] = true,
	["right"] = true,
	["bottom"] = true,
	["align"] = true,
	["valign"] = true,
	["display"] = true,
	["float"] = true,
	["position"] = true,
	["visibility"] = true,
	["z-index"] = true,

	-- text
	["color"] = true,
	["direction"] = true,
	["line-height"] = true,
	["text-align"] = true,
	["text-shadow"] = true,
}

-- merge style with current style. 
function CSSStyleDeclaration:Merge(style)
	if(style) then
		if(type(style) == "table") then
			for key, _ in pairs(property_fields) do
				self[key] = style[key] or self[key];
			end
		elseif(type(style) == "string") then
			self:AddString(style);
		end
	end
end

local inheritable_fields = {
	["color"] = true,
	["font-family"] = true,
	["font-size"] = true,
	["font-weight"] = true,
	["text-shadow"] = true,
};

-- only merge inheritable style like font, color, etc. 
function CSSStyleDeclaration:MergeInheritable(style)
	if(style) then
		for key, _ in pairs(inheritable_fields) do
			self[key] = style[key];
		end
	end
end

local layout_fields = 
{
	["height"] = true,
	["min-height"] = true,
	["max-height"] = true,
	["width"] = true,
	["min-width"] = true,
	["max-width"] = true,
	["left"] = true,
	["top"] = true,
	["right"] = true,
	["bottom"] = true,

	["margin"] = true,
	["margin-left"] = true,
	["margin-top"] = true,
	["margin-right"] = true,
	["margin-bottom"] = true,

	["padding"] = true,
	["padding-left"] = true,
	["padding-top"] = true,
	["padding-right"] = true,
	["padding-bottom"] = true,

	["border-width"] = true,
}

local number_fields = {
	["height"] = true,
	["min-height"] = true,
	["max-height"] = true,
	["width"] = true,
	["min-width"] = true,
	["max-width"] = true,
	["left"] = true,
	["top"] = true,
	["right"] = true,
	["bottom"] = true,
	["font-size"] = true,
	["spacing"] = true,
	["base-font-size"] = true,
	["border-width"] = true,
};

local color_fields = {
	["color"] = true,
	["border-color"] = true,
	["background-color"] = true,
};


local complex_fields = {
	["border"] = "border-width border-style border-color",
};

function CSSStyleDeclaration.isResetField(name)
	return layout_fields[name];
end

function CSSStyleDeclaration:Diff(changes)
	local style_change_type = "no_change";
	if(next(changes)) then
		for key,_ in pairs(changes) do
			if(layout_fields[key]) then
				return "change_layout";
			end
		end
	end
	return "change_update";
end

function CSSStyleDeclaration:ParseDeclaration(styleDeclaration)
	self.properties:clear();
	self:AddString(styleDeclaration);
end

-- @param style_code: mcml style attribute string like "background:url();margin:10px;"
function CSSStyleDeclaration:AddString(style_code)
	local name, value;
	for name, value in string.gfind(style_code, "([%w%-]+)%s*:%s*([^;]*)[;]?") do
		name = string_lower(name);
		value = string_gsub(value, "%s*$", "");
		local complex_name = complex_fields[name];
		if(complex_name) then
			self:AddComplexField(complex_name,value);
		else
			self:AddItem(name,value);
		end
	end
end

function CSSStyleDeclaration:AddComplexField(names_code,values_code)
	local names = commonlib.split(names_code, "%s");
	local values = commonlib.split(values_code, "%s");
	for i = 1, #names do
		self:AddItem(names[i], values[i]);
	end
end

function CSSStyleDeclaration:AddItem(name,value)
	if(not name or not value) then
		return;
	end
	name = string_lower(name);
	value = string_gsub(value, "%s*$", "");
--	if(number_fields[name] or string_find(name,"^margin") or string_find(name,"^padding")) then
--		local _, _, selfvalue = string_find(value, "([%+%-]?%d+[%%]?)");
--		if(selfvalue~=nil) then
--			value = tonumber(selfvalue);
--		else
--			value = nil;
--		end
--	elseif(color_fields[name]) then
--		value = StyleColor.ConvertTo16(value);
--	elseif(string_match(name, "^background[2]?$") or name == "background-image") then
	if(string_match(name, "^background[2]?$") or name == "background-image") then
		value = string_gsub(value, "url%((.*)%)", "%1");
		value = string_gsub(value, "#", ";");
	end
	--self.properties[name] = CSSProperty:new(name, value);
	self:SetPropertyInternal(CSSProperty:new(name, value))
end

function CSSStyleDeclaration:RemoveProperty(name, notifyChanged)
	local pos = self:FindPropertyPositionWithName(name);
	if(pos) then
		self.properties:remove(pos);
		
		if(notifyChanged) then
			self:SetNeedsStyleRecalc();
		end
	end
end

function CSSStyleDeclaration:SetProperty(name, value, notifyChanged)
	notifyChanged = if_else(notifyChanged == nil, true, notifyChanged);

	if(not value or value == "") then
		self:RemoveProperty(name, notifyChanged);
		return;
	end

	self:AddItem(name, value);
	if(notifyChanged) then
		self:SetNeedsStyleRecalc();
	end
end

function CSSStyleDeclaration:SetPropertyInternal(property)
	local pos = self:FindPropertyPositionWithName(property:Name());
	if(pos) then
		self.properties[pos] = property;
		return;
	end
	self.properties:append(property);
end

function CSSStyleDeclaration:FindPropertyPositionWithName(name)
	local properties = self.properties;
	local size = properties:size();
	for i = 1, size do
		if(properties:get(i):Name() == name) then
			return i;
		end
	end
	return nil;
end

function CSSStyleDeclaration:FindPropertyWithName(name)
	local pos = self:FindPropertyPositionWithName(name);
	if(pos) then
		return self.properties:get(pos);
	end
	return nil;
end

function CSSStyleDeclaration:first()
	return self.properties:first();
end

function CSSStyleDeclaration:Next()
	local properties = self.properties;
	local nSize = properties:size();
	local i = 1;
	return function ()
		local property;
		while i <= nSize do
			property = properties[i];
			i = i+1;
			return property;
		end
	end	
end

-- the user may special many font size, however, some font size is simulated with a base font and scaling. 
-- @return font, base_font_size, font_scaling: font may be nil if not specified. font_size is the base font size.
function CSSStyleDeclaration:GetFontSettings()
	local font;
	local scale = 1;
	local font_size = 12;
	if(self["font-family"] or self["font-size"] or self["font-weight"])then
		local font_family = self["font-family"] or "System";
		-- this is tricky. we convert font size to integer, and we will use scale if font size is either too big or too small. 
		font_size = math.floor(tonumber(self["font-size"] or 12));
--		local max_font_size = tonumber(self["base-font-size"]) or 14;
--		local min_font_size = tonumber(self["base-font-size"]) or 11;
--		if(font_size>max_font_size) then
--			scale = font_size / max_font_size;
--			font_size = max_font_size;
--		end
--		if(font_size<min_font_size) then
--			scale = font_size / min_font_size;
--			font_size = min_font_size;
--		end
		local font_weight = self["font-weight"] or "norm";
		font = string.format("%s;%d;%s", font_family, font_size, font_weight);
	else
		font = string.format("%s;%d;%s", "System", font_size, "norm");
	end
	return font, font_size, scale;
end

function CSSStyleDeclaration:GetTextAlignment()
	local alignment = 1;	-- center align
	if(self["text-align"]) then
		if(self["text-align"] == "right") then
			alignment = 2;
		elseif(self["text-align"] == "left") then
			alignment = 0;
		end
	end
	if(self["text-singleline"] ~= "false") then
		alignment = alignment + 32;
	else
		if(self["text-wordbreak"] == "true") then
			alignment = alignment + 16;
		end
	end
	if(self["text-noclip"] ~= "false") then
		alignment = alignment + 256;
	end
	if(self["text-valign"] ~= "top") then
		alignment = alignment + 4;
	end
	return alignment;
end

-- ����Ψһ����
local index = {}

-- ����Ԫ��
local mt = {
     __index = function (t, k)
          --print("access to element " .. tostring(k))		  
          return t[index][k]
     end,

     __newindex = function (t, k, v)
		t[index]["pageElement"]:ChangeCSSValue(k,v);
        --print("update of element " .. tostring(k))
        t[index][k] = v
     end
}

function CSSStyleDeclaration:CreateProxy(pageElement)
	local style_decl = CSSStyleDeclaration:new():init(pageElement);
	local proxy = {}
	proxy[index] = style_decl;
	setmetatable(proxy, mt);
	return proxy;
end

function CSSStyleDeclaration:IsInlineStyleDeclaration()
	if(self.pageElement and self.pageElement:InlineStyleDecl() == self) then
		return true;
	end
	return false;
end

function CSSStyleDeclaration:SetNeedsStyleRecalc()
    if (self.pageElement) then
        if (self:IsInlineStyleDeclaration()) then
            self.pageElement:SetNeedsStyleRecalc(StyleChangeTypeEnum.InlineStyleChange);
            --static_cast<StyledElement*>(m_node)->invalidateStyleAttribute();
--            if (m_node->document())
--                InspectorInstrumentation::didInvalidateStyleAttr(m_node->document(), m_node);
        else
            self.pageElement:SetNeedsStyleRecalc(StyleChangeTypeEnum.FullStyleChange);
		end
    end
end

function CSSStyleDeclaration:CssText()
	-- TODO: add latter. transform CSSStyleDeclaration to style string.
end