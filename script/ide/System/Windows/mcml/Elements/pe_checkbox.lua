--[[
Title: checkbox element
Author(s): LiPeng
Date: 2017/10/3
Desc: it handles HTML tags of <checkbox> in HTML. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_checkbox.lua");
System.Windows.mcml.Elements.pe_checkbox:RegisterAs("pe:checkbox","checkbox");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutButton.lua");
local LayoutButton = commonlib.gettable("System.Windows.mcml.layout.LayoutButton");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local mcml = commonlib.gettable("System.Windows.mcml");

local pe_checkbox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_checkbox"));
pe_checkbox:Property({"class_name", "pe:checkbox"});

function pe_checkbox:ctor()
	self:SetTabIndex(0);
end

function pe_checkbox:CreateControl()
	local parentElem = self:GetParentControl();
	local _this = Button:new():init(parentElem);
	self:SetControl(_this);

	local polygonStyle = self:GetAttributeWithCode("polygonStyle", nil, true);
	local direction = self:GetAttributeWithCode("direction", nil, true);
	local _this = self.control;
	if(not _this) then
		_this = Button:new():init(parentElem);
		_this:SetPolygonStyle(polygonStyle or "check");
		self:SetControl(_this);
	end
	
	_this:ApplyCss(css);
	local buttonName = self:GetAttributeWithCode("name",nil,true); -- touch name
	_this:SetPolygonStyle(polygonStyle or "check");
	_this:SetDirection(direction);

	_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));
	_this:setCheckable(self:GetBool("enabled",true));

	local checked = self:GetAttributeWithCode("checked", nil, true);
	if(checked) then
		_this:setChecked(true);
	end
	local buttonName = self:GetAttributeWithCode("name",nil,true);
	_this:Connect("clicked", function()
		self:OnClick(buttonName);
	end)
	_this:Connect("clicked", function()
		self:OnClick(buttonName);
	end)
end

function pe_checkbox:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
--	local default_css = mcml:GetStyleItem(self.class_name);
--	css.float = css.float or true;
--	css.width = css.width or default_css.iconSize;
--	css.height = css.height or default_css.iconSize;
--	css["background"] = self:GetAttributeWithCode("UncheckedBG", nil, true) or default_css["background"];
--	css["background_checked"] = self:GetAttributeWithCode("CheckedBG", nil, true) or default_css["background_checked"];
	
--	local polygonStyle = self:GetAttributeWithCode("polygonStyle", nil, true);
--	local direction = self:GetAttributeWithCode("direction", nil, true);
--	local _this = self.control;
--	if(not _this) then
--		_this = Button:new():init(parentElem);
--		_this:SetPolygonStyle(polygonStyle or "check");
--		self:SetControl(_this);
--	end
--	
--	_this:ApplyCss(css);
--	_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));
--	_this:setCheckable(self:GetBool("enabled",true));
--
--	local checked = self:GetAttributeWithCode("checked", nil, true);
--	if(checked) then
--		_this:setChecked(true);
--	end
--	local buttonName = self:GetAttributeWithCode("name",nil,true);
--	_this:Connect("clicked", function()
--		self:OnClick(buttonName);
--	end)
end

function pe_checkbox:setChecked(checked)
	if(self.control) then
		self.control:setChecked(checked);
	end
	checked = if_else(checked, "true", "false");
	self:SetAttribute("checked", checked);
end

function pe_checkbox:getChecked()
	local checked = self:GetAttributeWithCode("checked", nil, true);
	if(checked) then
		checked = if_else(checked == "true" or checked == "checked",true,false);
	end
	return checked;
end

function pe_checkbox:OnClick()
	local ctl = self:GetControl();
	if(ctl and ctl:isCheckable()) then
		local checked = not (ctl:isChecked());
		ctl:setChecked(checked);
		self:SetAttribute("checked", if_else(checked, "true", "false"));
	end
	local result;
	local onclick = self.onclickscript or self:GetString("onclick");
	if(onclick == "")then
		onclick = nil;
	end
	if(onclick) then
		-- the callback function format is function(buttonName, self) end
		result = self:DoPageEvent(onclick, self:getChecked(), self);
	end
	return result;
end

-- virtual function: 
-- after child node layout is updated
function pe_checkbox:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
	end
end

--function pe_checkbox:CreateLayoutObject(arena, style)
--	return LayoutButton:new():init(self);
--end

--function pe_checkbox:attachLayoutTree()
--	pe_checkbox._super.attachLayoutTree(self);
--end