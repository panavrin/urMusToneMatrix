

SetPage(2);
FreeAllRegions();
FreeAllFlowboxes()
--[[
drum = nil
fbPush:RemovePushLink(0,fbSinOsc, 0) ;
fbZpulse:RemovePullLink(0,fbSinOsc,0);
dac:RemovePullLink(0,fbZpulse,0)
dac:RemovePullLink(0,drum,0)
drumAmpPush:RemovePushLink(0,drum,0)
drumRatePush:RemovePushLink(0,drum,1)
drumPosPush:RemovePushLink(0,drum,2)
drumSampPush:RemovePushLink(0,drum,3)
drumLoopPush:RemovePushLink(0,drum,4)
SetPage(2);
FreeAllRegions();
]]
dac = FBDac
push = FlowBox(FBPush)
--accel = FlowBox(FBAccel)
sinosc = FlowBox(FBSinOsc)

--accel.X:SetPush(sinosc.Freq)
zPulse = FlowBox(FBZPuls)
push.Out:SetPush(sinosc.Freq)  
zPulse.In:SetPull(sinosc.Out);
dac.In:SetPull(zPulse.Out)


local log = math.log
freqHz = 0.5
freq = 12.0/96.0*log(freqHz/55)/log(2)

push:Push(freq);

drum = FlowBox(FBSample)
drumAmpPush = FlowBox(FBPush)
drumRatePush = FlowBox(FBPush)
drumPosPush = FlowBox(FBPush)
drumSampPush = FlowBox(FBPush)
drumLoopPush = FlowBox(FBPush)
drum:AddFile("Clap.wav")
drum:AddFile("ClosedHat.wav")
drum:AddFile("sine.wav")
drum:AddFile("square.wav")
drum:AddFile("Scratch.wav")

drumAmpPush:SetPushLink(0,drum,0)
drumRatePush:SetPushLink(0,drum,1)
drumPosPush:SetPushLink(0,drum,2)
drumSampPush:SetPushLink(0,drum,3)
drumLoopPush:SetPushLink(0,drum,4)

dac:SetPullLink(0,drum,0)

drumAmpPush:Push(0.8)
drumRatePush:Push(0.5)
drumPosPush:Push(1.0)
drumSampPush:Push(0.0)
drumLoopPush:Push(0.0)

n = Region()
n.buttons = {}
n.swidth = ScreenWidth()
n.sheight = ScreenHeight();

n.rowNum = 10
n.colNum = 10
n.margin = 10
n.bpm =120
n.minLength = math.min(n.swidth/n.colNum, n.sheight/n.rowNum)
n.numSize =  n.minLength - n.margin/2;
n.time = math.ceil(Time())+1;
n.interval =  1/(n.bpm/60)
n.nextTickTime = n.time + n.interval;
n.currentTime = Time()
n.avgElapsed = 0;
n.alpha = 0.2
n.count = 0;
DPrint(n.time);
function update(self, elapsed)
    n.avgElapsed = n.avgElapsed * n.alpha + (1-n.alpha) * elapsed;
    n.currentTime = Time()
    if n.currentTime >= n.nextTickTime - n.avgElapsed/2 then
        n.count = (n.count+1) % n.colNum
      --  DPrint(n.currentTime.." elapsed: "..n.avgElapsed)
        while n.currentTime >= n.nextTickTime - n.avgElapsed/2 do
            n.nextTickTime  = n.nextTickTime + n.interval
        end
        n.playBar:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT",n.count * (n.numSize + n.margin/2),n.margin/2)
        for i=0, n.colNum-1 do
            if(n.buttons[i][n.count].toggle) then
                DPrint("Boom("..i..","..n.count..") in ".. n.colNum .. " so "..(i/(n.colNum)*2-1));
--                drumSampPush:Push((i/(n.colNum)*2-1))
                drumSampPush:Push(0)
                drumPosPush:Push(0) 
            end
        end           
        
    end
    
end

n:Handle("OnUpdate", update)
for i=0,n.rowNum-1 do
    n.buttons[i] = {}
end

function buttonPressed(self)
    DPrint(self.row..","..self.col.." pressed")
end

function toggleButton(self)
    self.toggle = not self.toggle
    if(self.toggle) then
        self.t = self:Texture(200,200,255,255)
    else
        self.t = self:Texture(220,200,200,255)
    end
    
end

function createCell(i,j)
    --  DPrint(i..j)
    local newregion = Region()
    newregion:SetWidth(n.numSize )
    newregion:SetHeight(n.numSize )
    newregion.tl = newregion:TextLabel()
    newregion.tl:SetLabel(i..","..j)
    newregion.tl:SetFontHeight(10)
    newregion.tl:SetColor(0,0,0,255)
    
    newregion.t = newregion:Texture(220,200,200,255)
    newregion:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT", n.margin/2 + j*n.minLength, n.margin/2 + i* n.minLength)
    newregion:Show()
    newregion:Handle("OnTouchDown",buttonPressed)
    newregion.row = i;
    newregion.col = j;
    newregion:EnableInput(true)
    newregion:Handle("OnTouchDown",toggleButton)
    newregion.toggle = false;
    newregion:Show()
    n.buttons[i][j] = newregion
end

for i=0,(n.rowNum-1) do
    for j=0, n.colNum-1 do
        createCell(i,j)
    end
end

n.playBar = Region()

n.playBar:SetWidth(n.numSize + n.margin/2)
n.playBar:SetHeight((n.numSize + n.margin/2) * n.rowNum)
--n.playBar.t = n.playBar:Texture(100,0,0,0)

n.playBar.t = n.playBar:Texture(100,0,0,100)
n.playBar.t:SetBlendMode("BLEND")
r,g,b,a = n.playBar.t:SolidColor()

--n.playBar.t:SetTexture(255,80,10,10)
n.playBar:SetAlpha(50)

n.playBar:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT",n.margin/2,n.margin/2)
n.playBar:Show()