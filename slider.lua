SetPage(2)
FreeAllRegions()
FreeAllFlowboxes()
pModFreq = FlowBox(FBPush)

pModAmp = FlowBox(FBPush)
pCenterFreq = FlowBox(FBPush)
pAsymTarget = FlowBox(FBPush)
pAsymTau = FlowBox(FBPush)
asymp = FlowBox(FBAsymp)
sinosc = FlowBox(FBSinOsc)
sinosc2 = FlowBox(FBSinOsc)
add = FlowBox(FBAdd)
dac = FBDac


function play(self)
	r.t:SetSolidColor(0,255,0,255)
	pAsymTarget:Push(1)
	pAsymTau:Push(-0.8);
end

function stop(self)
	r.t:SetSolidColor(255,0,0,255)
	pAsymTarget:Push(0)
	pAsymTau:Push(-0.5);
end


function sliderTouchUp(self)
	DPrint("touchUp")
end
local nextPower2X = 1
local nextPower2Y = 1

function sliderMoved(self,x,y,dx,dy)
	self.t:Clear(150,150,100,255)
	local ratio = 2*(y / self:Height() - 0.5)
	DPrint("OnMove:"..self.i..","..ratio)
	self.t:Line(0,y*nextPower2Y,x*nextPower2X,y*nextPower2Y)
	if self.i == 0 then
		pCenterFreq:Push(ratio)
	elseif self.i==1 then
		pModFreq:Push(ratio)		
	elseif self.i==2 then
		pModAmp:Push(ratio)		
	end

	--	self:SetAnchor("BOTTOMLEFT", UIParent, "BOTTOMLEFT", n.offset + n.minLength*n.colNum+ n.margin/2, y+dy)---self:Height()/2)
end

function sliderTouchDown(self)
	DPrint("touchDown")
end
n = Region()
function createSlider(i)
	n.slider = Region()
	n.slider.i = i
	n.slider:SetWidth(100)
	n.slider:SetHeight(500)
	n.slider.t = n.slider:Texture(150,150,100,255)
	n.slider:SetAnchor("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 300*i,0)
	n.slider:Show()
	--	n.slider:EnableMoving(true)
	n.slider:EnableInput(true)
	n.slider:Handle("OnTouchUp",sliderTouchUp)
	n.slider:Handle("OnMove", sliderMoved)
	n.slider:Handle("OnTouchDown",sliderTouchDown)
	n.slider.t:SetBrushColor(255,0,0,255)
	n.slider.t:SetBrushSize(10)
	while nextPower2Y < n.slider:Height() do
		nextPower2Y = nextPower2Y *2
	end
	
	while nextPower2X < n.slider:Height() do
		nextPower2X = nextPower2X *2
	end	
	nextPower2X  = nextPower2X / n.slider:Width();
	nextPower2Y  = nextPower2Y / n.slider:Height();
	--[[	n.cursor = Region()
	n.cursor:SetWidth(n.numSize)
	n.cursor:SetHeight(n.numSize)
	n.cursor.t = n.cursor:Texture(255,0,255,200)
	n.cursor:SetAnchor("CENTER", n.slider, "CENTER", 0,0)
	n.cursor:Show()
	n.cursor:EnableInput(true)
	n.cursor:EnableHorizontalScroll(true)
	--	n.cursor:EnableMoving(true)
	
	
	--	n.cursor:Handle("OnTouchUp",sliderTouchUp)
	n.cursor:Handle("OnHorizontalScroll", sliderMoved)
	--	n.cursor:Handle("OnTouchDown",sliderTouchDown)
	]]
end

createSlider(0)
createSlider(1)
createSlider(2)



--x1 -> sineosc2.freq --> add2
-- y1 --> add1
-- add1 + 2 --> sinoscFreq
quant = FlowBox(FBQuant)

pModFreq.Out:SetPush(sinosc2.Freq)
pCenterFreq.Out:SetPush(quant.In)
quant.Out:SetPush(add.In1)

pModAmp.Out:SetPush(sinosc2.Amp)
add.In2:SetPull(sinosc2.Out)
sinosc.Freq:SetPull(add.Out)

--DPrint(sinosc2.Freq)
--:Get()
--(pModFreq)
--sinosc.Freq:SetPush(pCetnerFreq)

dac.In:SetPull(sinosc.Out)
--dac.In:SetPull(rev.Out)
--rev.In:SetPull(sinosc.Out)
sinosc.Amp:SetPull(asymp.Out)
pAsymTarget.Out:SetPush(asymp.In)
pAsymTau.Out:SetPush(asymp.Tau)

pAsymTarget:Push(1)
pAsymTau:Push(1)
