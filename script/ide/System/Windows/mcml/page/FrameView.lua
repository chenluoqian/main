--[[
Title: FrameView
Author(s): LiPeng
Date: 2018/3/1
Desc: the layout manager used by mcml Page.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/page/FrameView.lua");
local FrameView = commonlib.gettable("System.Windows.mcml.page.FrameView");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/ScrollView.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/PaintInfo.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
NPL.load("(gl)script/ide/System/Windows/Application.lua");
NPL.load("(gl)script/ide/System/Core/Event.lua");
local Event = commonlib.gettable("System.Core.Event");
local Application = commonlib.gettable("System.Windows.Application");
local Point = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
local PaintInfo = commonlib.gettable("System.Windows.mcml.layout.PaintInfo");
local ScrollView = commonlib.gettable("System.Windows.mcml.platform.ScrollView");
local LayoutSize = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");

local LayoutRect = Rect;

local FrameView = commonlib.inherit(commonlib.gettable("System.Windows.mcml.platform.ScrollView"), commonlib.gettable("System.Windows.mcml.page.FrameView"));

function FrameView:ctor()
	self.m_frame = nil;

	self.uiElement = nil;
	self.page = nil;

	-- the vector of "IntRect"(System.Windows.mcml.platform.graphics.IntRect)
	self.repaintRects = commonlib.Array:new();
	self.repaintCount = 0;

	self.inLayout = false;


	self.transparent = false;
	self.dirty = false;
	self.dirtyArea = Rect:new();

	self.doFullRepaint = true;
	self.layoutRoot = nil;
	self.firstLayout = true;
	self.size = nil;

	-- a PageElement object;
	self.nodeToDraw = nil;

	self.isTrackingRepaints = false;
	self.trackedRepaintRects = commonlib.Array:new();

	self.m_isPainting = false;
end

function FrameView:init(frame)
	self.m_frame = frame;
	if(self.m_frame) then
		local page = self.m_frame:Page();
		if(page) then
			self.page = page;
		end
	end

	self:reset();

	self.size = LayoutSize:new();

	return self;
end

--PassRefPtr<FrameView> FrameView::create(Frame* frame, const IntSize& initialSize)
function FrameView.Create(frame, initialSize)
    local view = FrameView:new():init(frame);
	if(initialSize) then
		view:SetFrameRect(LayoutRect:new(view:Location(), initialSize));
	end
    --view->show();
    return view;
end

function FrameView:Frame()
	return self.m_frame;
end

function FrameView:reset()
	self.inLayout = false;
	self.repaintCount = 0;
	self.doFullRepaint = true;
	self.layoutRoot = nil;
	self.firstLayout = true;
	self.isTrackingRepaints = false;
end

function FrameView:IsTransparent()
    return self.transparent;
end

function FrameView:IsInLayout()
	return self.inLayout;
end

function FrameView:NeedsFullRepaint()
	return self.doFullRepaint;
end

-- initialize a top level layout manager for a given page object(uiElement).
function FrameView:SetPage(page, uiElement)
	self.uiElement = uiElement;
	self.page = page;
end

function FrameView:SetUIElement(uiElement)
	self.uiElement = uiElement;
	if(uiElement) then
		uiElement.layout = self;
	end
end

function FrameView:BeginDeferredRepaints()

end

function FrameView:EndDeferredRepaints()
	self:DoDeferredRepaints();
end

function FrameView:ShouldUpdate(immediateRequested)
	immediateRequested = if_else(immediateRequested == nil, false, immediateRequested);
--    if (!immediateRequested && isOffscreen() && !shouldUpdateWhileOffscreen())
--        return false;
    return true;
end

function FrameView:UpdateDeferredRepaintDelay()
--    Document* document = m_frame->document();
--    if (!document || (!document->parsing() && !document->cachedResourceLoader()->requestCount())) {
--        m_deferredRepaintDelay = s_deferredRepaintDelay;
--        return;
--    }
--    if (m_deferredRepaintDelay < s_maxDeferredRepaintDelayDuringLoading) {
--        m_deferredRepaintDelay += s_deferredRepaintDelayIncrementDuringLoading;
--        if (m_deferredRepaintDelay > s_maxDeferredRepaintDelayDuringLoading)
--            m_deferredRepaintDelay = s_maxDeferredRepaintDelayDuringLoading;
--    }
end

function FrameView:DoDeferredRepaints()
	--ASSERT(!m_deferringRepaints);
    if (not self:ShouldUpdate()) then
        self.repaintRects:clear();
        self.repaintCount = 0;
        return;
    end
    local size = self.repaintRects:size();
	for i = 1, size do
		--ScrollView::repaintContentRectangle(m_repaintRects[i], false);
		FrameView._super.RepaintContentRectangle(self, self.repaintRects[i], false);
	end
--    for (unsigned i = 0; i < size; i++) {
--#if USE(TILED_BACKING_STORE)
--        if (frame()->tiledBackingStore()) {
--            frame()->tiledBackingStore()->invalidate(m_repaintRects[i]);
--            continue;
--        }
--#endif
--        ScrollView::repaintContentRectangle(m_repaintRects[i], false);
--    }
    self.repaintRects:clear();
    self.repaintCount = 0;
    
    self:UpdateDeferredRepaintDelay();
end

--static inline RenderView* rootRenderer(const FrameView* view)
local function rootRenderer(view)
	if(view:Frame()) then
		return view:Frame():ContentRenderer()
	end
    return nil;
end

function FrameView:Layout()
	if(not self.page:LoadFinshed()) then
		return;
	end

	if(self.inLayout) then
		return;
	end

	if (self:IsPainting()) then
        return;
	end

	local document = self.m_frame:Document();

--	// Viewport-dependent media queries may cause us to need completely different style information.
--    // Check that here.
--    if (document->styleSelector()->affectedByViewportChange())
--        document->styleSelectorChanged(RecalcStyleImmediately);
--
--    // Always ensure our style info is up-to-date.  This can happen in situations where
--    // the layout beats any sort of style recalc update that needs to occur.
	document:UpdateStyleIfNeeded();

	--bool subtree = m_layoutRoot;
	local subtree = if_else(self.layoutRoot, true, false);

	local root = self.layoutRoot;
	if(not subtree) then
		root = document:Renderer();
	end

	if(not root) then
		return;
	end

	--m_doFullRepaint = !subtree && (m_firstLayout || toRenderView(root)->printing());
	self.doFullRepaint = not subtree and self.firstLayout;
	if(not subtree) then
		if (self.firstLayout) then
			self.firstLayout = false;
		end

		local oldSize = self.size:clone_from_pool();
		self.size:Reset(self:LayoutWidth(), self:LayoutHeight());

		if(not (oldSize == self.size)) then
			self.doFullRepaint = true;
			self:RepaintContentRectangle(LayoutRect:new(0, 0, self.size:Width(), self.size:Height()));
		end
	end
	local layer = root:EnclosingLayer();

	self.inLayout = true;
	self:BeginDeferredRepaints();
	root:Layout();
	self:EndDeferredRepaints();
	

	self.layoutRoot = nil;

    local offsetFromRoot, hasLayerOffset = layer:ComputeOffsetFromRoot();

	layer:UpdateLayerPositions(if_else(hasLayerOffset, offsetFromRoot, nil), "CheckForRepaint");

	local root = rootRenderer(self);
    root:UpdateWidgetPositions();

	self.inLayout = false;

	self:RepaintIfNeeded();
end

function FrameView:RepaintIfNeeded()
	-- if it's sub frameview, the main frameview must be paint before.
	if(self:Parent() and self:Parent():IsInLayout()) then
		return;
	end

	if(not self.dirty) then
        return false;
	end
    --layoutIfNeeded();
	self:Paint(nil, self.dirtyArea);


	--self.dirtyArea = WebCore::IntRect();
	self.dirtyArea:Reset();
    self.dirty = false;
end

-- recalculate the layout according to current uiElement (Window)'s size
function FrameView:activate()
	if (self.activated) then
        return false;
	end
	if(self.page and self.uiElement) then
		self.activated = true;
		self:Layout();
	end
end

function FrameView:PostLayoutRequestEvent()
	Application:postEvent(self:widget(), Event:new_static("LayoutRequestEvent"));
end

-- Updates the layout for GetParent().
function FrameView:update(layout_object)
    local layout = self;
    while (layout and layout.activated) do
        layout.activated = false;
        if (layout.topLevel) then
            Application:postEvent(layout:GetParent(), Event:new_static("LayoutRequestEvent"));
            break;
        end
        layout = layout:GetParent();
    end
end

function FrameView:widgetEvent(event)
	local type = event:GetType();
	if(type == "sizeEvent" or type == "LayoutRequestEvent") then
		if(type == "sizeEvent") then
			local usedWidth, usedHeight = self:GetUsedSize();
			local uiElement = self.uiElement;
			self:Resize(uiElement:width(), uiElement:height());
			if(usedWidth == 0 or usedHeight == 0 or self:Width() < usedWidth or self:Height() < usedHeight) then
				self:Layout();
			end
		else
			self:Layout();	
		end
	end
--	if(type == "sizeEvent") then
--		if (self.activated) then
--			self:doResize(event:width(), event:height());
--		else
--			self:activate();
--		end
--	elseif(type == "LayoutRequestEvent") then
--        if (self:GetParent() and self:GetParent():isVisible()) then
--            self:activate();
--		end
--	end
end

-- return the top level mcml page object. 
function FrameView:GetPage()
	return self.page;
end

-- If this item is a UI element, it is returned as a UI element; otherwise nil is returned. 
function FrameView:widget()
	return self.uiElement;
end

function FrameView:GetUsedSize()
	--TODO: fixed this function
	local root = rootRenderer(self);
	if(root and root:FirstChild()) then
		local htmlRender = root:FirstChild();
		return htmlRender:Width(), htmlRender:Height();
	end
	return 0, 0;
end

function FrameView:AddDirtyArea(x, y, w, h)
    if (w > 0 and h > 0) then
        self.dirtyArea:Unite(Rect:new_from_pool(x, y, w, h));
        self.dirty = true;
    end
end

function FrameView:InvalidateContentsAndWindow(updateRect, immediate)
	self:AddDirtyArea(updateRect:X(), updateRect:Y(), updateRect:Width(), updateRect:Height());
end

function FrameView:IsTrackingRepaints()
	return self.isTrackingRepaints;
end

function FrameView:SetTracksRepaints(trackRepaints)
    if (trackRepaints == self.isTrackingRepaints) then
        return;
	end
    
    self.trackedRepaintRects:clear();
    self.isTrackingRepaints = trackRepaints;
end

function FrameView:ResetTrackedRepaints()
	self.trackedRepaintRects:clear();
end

function FrameView:TrackedRepaintRects()
	return self.trackedRepaintRects;
end

local cRepaintRectUnionThreshold = 25;

--void FrameView::repaintContentRectangle(const LayoutRect& r, bool immediate)
function FrameView:RepaintContentRectangle(rect, immediate)
	immediate = if_else(immediate == nil, false, immediate);
    --ASSERT(!m_frame->ownerElement());
    
    if (self.isTrackingRepaints) then
        local repaintRect = rect:clone();
        repaintRect:Move(-self:ScrollOffset());
        self.trackedRepaintRects:append(repaintRect);
    end

	local paintRect = rect:clone();
    if (self:ClipsRepaints() and not self:PaintsEntireContents()) then
        paintRect:Intersect(self:VisibleContentRect());
	end
    if (paintRect:IsEmpty()) then
        return;
	end
    if (self.repaintCount == cRepaintRectUnionThreshold) then
        local unionedRect = LayoutRect:new();
		for i = 1, self.repaintRects:size() do
			unionedRect:Unite(self.repaintRects[i]);
		end
--        for (unsigned i = 0; i < cRepaintRectUnionThreshold; ++i)
--            unionedRect.unite(m_repaintRects[i]);
        self.repaintRects:clear();
        self.repaintRects:append(unionedRect);
    end
	--self.repaintRects:append(paintRect);
    if (self.repaintCount < cRepaintRectUnionThreshold) then
        self.repaintRects:append(paintRect);
    else
        self.repaintRects[1]:Unite(paintRect);
	end
    self.repaintCount = self.repaintCount + 1;
    
--    if (!m_deferringRepaints && !m_deferredRepaintTimer.isActive())
--            m_deferredRepaintTimer.startOneShot(delay);
--    return;

--    double delay = m_deferringRepaints ? 0 : adjustedDeferredRepaintDelay();
--    if ((m_deferringRepaints || m_deferredRepaintTimer.isActive() || delay) && !immediate) {
--        LayoutRect paintRect = r;
--        if (clipsRepaints() && !paintsEntireContents())
--            paintRect.intersect(visibleContentRect());
--        if (paintRect.isEmpty())
--            return;
--        if (m_repaintCount == cRepaintRectUnionThreshold) {
--            LayoutRect unionedRect;
--            for (unsigned i = 0; i < cRepaintRectUnionThreshold; ++i)
--                unionedRect.unite(m_repaintRects[i]);
--            m_repaintRects.clear();
--            m_repaintRects.append(unionedRect);
--        }
--        if (m_repaintCount < cRepaintRectUnionThreshold)
--            m_repaintRects.append(paintRect);
--        else
--            m_repaintRects[0].unite(paintRect);
--        m_repaintCount++;
--    
--        if (!m_deferringRepaints && !m_deferredRepaintTimer.isActive())
--             m_deferredRepaintTimer.startOneShot(delay);
--        return;
--    }
    
--    if (!shouldUpdate(immediate))
--        return;
--
--#if USE(TILED_BACKING_STORE)
--    if (frame()->tiledBackingStore()) {
--        frame()->tiledBackingStore()->invalidate(r);
--        return;
--    }
--#endif
--    ScrollView::repaintContentRectangle(r, immediate);
end

--void FrameView::paintContents(GraphicsContext* p, const LayoutRect& rect)
function FrameView:PaintContents(p, rect)
--	if (self:NeedsLayout()) then
--        return;
--	end

    local root = rootRenderer(self);
    if (not root) then
		LOG.std("", "error", "FrameView", "FrameView:PaintContents() paint with nil renderer");
        return;
    end

	self.m_isPainting = true;

    -- m_nodeToDraw is used to draw only one element (and its descendants)
    local eltRenderer;
	if(self.nodeToDraw) then
		eltRenderer = self.nodeToDraw:Renderer();
	end
    local rootLayer = root:Layer();

    rootLayer:Paint(p, rect, self.paintBehavior, eltRenderer);

--    if (rootLayer->containsDirtyOverlayScrollbars())
--        rootLayer->paintOverlayScrollbars(p, rect, m_paintBehavior, eltRenderer);

    self.m_isPainting = false;
end

--bool FrameView::isPainting() const
function FrameView:IsPainting()
    return self.m_isPainting;
end

--bool FrameView::needsLayout() const
function FrameView:NeedsLayout()
    -- This can return true in cases where the document does not have a body yet.
    -- Document::shouldScheduleLayout takes care of preventing us from scheduling
    -- layout in that case.
    if (not self.m_frame) then
        return false;
	end

    local root = rootRenderer(self);
	return root and root:NeedsLayout()
--    return layoutPending()
--        || (root && root->needsLayout())
--        || m_layoutRoot
--        || (m_deferSetNeedsLayouts && m_setNeedsLayoutWasDeferred);
end

function FrameView:SetNeedsLayout()
--    if (m_deferSetNeedsLayouts) {
--        m_setNeedsLayoutWasDeferred = true;
--        return;
--    }

	local root = rootRenderer(self)
    if (root) then
        root:SetNeedsLayout(true);
	end
end