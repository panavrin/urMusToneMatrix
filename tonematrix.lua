--[[


bugs
1. more than 10 toggle will make the patch.  crash. 
2. once registered for handle I can't access by function name
]]

SetPage(2);
DPrint("")
FreeAllRegions();
FreeAllFlowboxes()
n = Region()
n.notes = {	0,	2,	4,	5,	7,	9,	11,	12}

n. color = {{0.8392,0.3137,0.2353},{0.9098,0.4314,0.2451},{0.9804,0.549,0.2549},{0.7804,0.7196,0.2529},{0.5804,0.8902,0.251},{0.1804,0.7882,0.4039},{0.2255,0.7922,0.6667},{0.2706,0.7961,0.9294},{0.3392,0.6667,0.9275},{0.4078,0.5373,0.9255},{0.5706,0.4059,0.8627},{0.7333,0.2745,0.8}}
local log = math.log
local pow = math.pow 

function freq2Norm(freqHz)
	return 12.0/96.0*log(freqHz/55)/log(2)
end

function noteNum2Freq(num)
	return pow(2,(num-57)/12) * 440 
end



n.host = "67.194.194.117"
n.post = 8888


n.freq = freq2Norm(0.5)
n.rowNum = 7
n.colNum = 8

n.baseNum = 60
--			1	2	3	4	5	6	7	8	9	10	11	12	13

n.noteNames = { "C","C#","D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}


dac = FBDac
pAsymTarget = {}
pFreq = {}
pAsymTau = {}
asymp = {}
sinosc = {}
n.polyPhonyNum = 2
for i=0,n.polyPhonyNum do
	pAsymTarget[i] = {}
	pAsymTau[i] = {}
	pFreq[i] = {}
	asymp[i] = {}
	sinosc[i] = {}
end


function buildATone(i,j)
	pAsymTarget[i][j] = FlowBox(FBPush)
	pAsymTau[i][j] = FlowBox(FBPush)
	asymp[i][j] = FlowBox(FBAsymp)
	pFreq[i][j] = FlowBox(FBPush)
	sinosc[i][j]= FlowBox(FBSinOsc)
	sinosc[i][j].Amp:SetPull(asymp[i][j].Out)
	pAsymTarget[i][j].Out:SetPush(asymp[i][j].In)
	pAsymTau[i][j].Out:SetPush(asymp[i][j].Tau)
	pFreq[i][j].Out:SetPush(sinosc[i][j].Freq)
	pAsymTarget[i][j]:Push(0)
	pAsymTau[i][j]:Push(0)
	dac.In:SetPull(sinosc[i][j].Out)
end

function setFreq(i,j,noteNum)	
	pFreq[i][j]:Push(freq2Norm(noteNum2Freq(noteNum)))
end

function play(i,j)
	r.t:SetSolidColor(0,255,0,255)
	
end

function stop(i,j)
	r.t:SetSolidColor(255,0,0,255)
	--	pAsymTarget[i][j]:Push(0)
	--	pAsymTau[i][j]:Push(-0.5);
end

n.buttons = {}
n.labels = {}

n.slideInstrument = 1
n.swidth = ScreenWidth()
n.sheight = ScreenHeight();
n.offset = 50

n.margin = 10
n.bpm =120
function updateSize()
	n.minLength = math.min((n.swidth- n.offset)/(n.colNum+n.slideInstrument), n.sheight/n.rowNum)
	n.numSize =  n.minLength - n.margin/2;
end
updateSize()
n.time = math.ceil(Time())+1;
n.interval =  1/(n.bpm/60)
n.nextTickTime = n.time + n.interval;
n.currentTime = Time()
n.avgElapsed = 0;
n.alpha = 0.2
n.count = 0;

function update(self, elapsed)
	local totalNoteNum=0
	n.avgElapsed = n.avgElapsed * n.alpha + (1-n.alpha) * elapsed;
	n.currentTime = Time()
	if n.currentTime >= n.nextTickTime - n.avgElapsed/2 then
		n.count = ((n.count+1) % n.colNum) 
		if n.count== 0 then
			n.count = n.colNum
		end
		
		while n.currentTime >= n.nextTickTime - n.avgElapsed/2 do
			n.nextTickTime  = n.nextTickTime + n.interval
		end
		--	SendOSCMessage(n.host,n.post,"/urMus/numbers",1,2)
		n.playBar:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT",n.offset + n.margin/2+ (n.count-1) * (n.numSize + n.margin/2),n.margin/2)
		for i=1, n.rowNum do
			if(n.buttons[i][n.count].toggle) then
				totalNoteNum = totalNoteNum+1;
				
				if table.getn(sinosc[n.count%n.polyPhonyNum]) < totalNoteNum then
					buildATone(n.count%n.polyPhonyNum, totalNoteNum)
				end
				setFreq(n.count%n.polyPhonyNum, totalNoteNum, n.notes[i] + n.baseNum)
			end
			
		end   
		--		DPrint("totalNum:"..totalNoteNum);
		for k=1, table.getn(pAsymTau[(n.count+1)%n.polyPhonyNum]) do
			pAsymTau[(n.count+1)%n.polyPhonyNum][k]:Push(-0.2);
			pAsymTarget[(n.count+1)%n.polyPhonyNum][k]:Push(0)
		end	
		for k=1, totalNoteNum do
			pAsymTau[n.count%n.polyPhonyNum][k]:Push(-0.8);
			pAsymTarget[n.count%n.polyPhonyNum][k]:Push(1)
		end	
		
	end
	
end

n:Handle("OnUpdate", update)
for i=1,n.rowNum do
	n.buttons[i] = {}
end

function toggleButton(self)
	SendOSCMessage(n.host,n.post,"/urMus/numbers",0,self.row, self.col)
	self.toggle = not self.toggle
	--	DPrint(self.row..","..self.col.." pressed")
	
	drawCell(self)
end

function updateNoteName(i)
	local noteNum = (n.baseNum + n.notes[i])%12+1
	n.labels[i].t = n.labels[i]:Texture(n.color[noteNum][1]*150,n.color[noteNum][2]*150,n.color[noteNum][3]*150,255)
	n.labels[i].tl:SetLabel(n.noteNames[noteNum]..math.floor((n.baseNum + n.notes[i])/12))
end

function createNoteName(i)
	local newregion = Region()
	newregion:SetWidth(n.offset - n.margin/2 )
	newregion.tl = newregion:TextLabel()
	
	newregion.tl:SetFontHeight(20)
	newregion.tl:SetColor(0,0,0,255)
	newregion:SetHeight(n.numSize )
	newregion:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT", n.margin/2 , n.margin/2 + (i-1)* n.minLength)
	
	newregion:Show()
	newregion:SetLayer("LOW")
	if n.labels[i] then
		n.labels[i] = nil;
	end
	n.labels[i] = newregion
	updateNoteName(i)
	
	
end

function drawCell(self)
	local noteNum = (n.baseNum + n.notes[self.row])%12+1
	
	self:SetWidth(n.numSize )
	self:SetHeight(n.numSize )
	--	self.tl:SetLabel(self.row..","..self.col)
	
	if(self.toggle) then
		self.t = self:Texture(n.color[noteNum][1]*240,n.color[noteNum][2]*240,n.color[noteNum][3]*240,255)
	else
		self.t = self:Texture(n.color[noteNum][1]*120,n.color[noteNum][2]*120,n.color[noteNum][3]*120,150)
		
	end
	self:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT", n.offset+ n.margin/2 + (self.col-1)*n.minLength, n.margin/2 + (self.row-1)* n.minLength)
end

function createCell(i,j)
	--  DPrint(i..j)
	local newregion = Region()
	newregion:SetWidth(n.numSize )
	newregion:SetHeight(n.numSize )
	newregion.tl = newregion:TextLabel()
	newregion.tl:SetFontHeight(10)
	newregion.tl:SetColor(0,0,0,255)
	newregion.row = i;
	newregion.col = j;
	
	newregion:EnableInput(true)
	newregion:Handle("OnTouchDown",toggleButton)
	newregion.toggle = false;
	drawCell(newregion)
	newregion:Show()
	if n.buttons[i][j] then
		n.buttons[i][j] = nil;
	end
	
	n.buttons[i][j] = newregion
end

for i=1,n.rowNum do
	for j=1, n.colNum do
		createCell(i,j)
	end
	createNoteName(i)
end

n.playBar = Region()
n.playBar:SetWidth(n.numSize)
n.playBar:SetHeight((n.numSize + n.margin/2) * n.rowNum- n.margin/2)
--n.playBar.t = n.playBar:Texture(100,0,0,0)

n.playBar.t = n.playBar:Texture(255,255,255,100)
n.playBar.t:SetBlendMode("BLEND")
r,g,b,a = n.playBar.t:SolidColor()

--n.playBar.t:SetTexture(255,80,10,10)
n.playBar:SetAlpha(50)

n.playBar:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT",n.offset + n.margin/2,n.margin/2)
n.playBar:Show()


function sliderTouchUp(self)
	DPrint("touchUp")
end
local nextPower2X = 1
local nextPower2Y = 1

function sliderMoved(self,x,y,dx,dy)
	self.t:Clear(150,150,100,255)
	DPrint("OnMove:"..y..","..self:Height()..","..nextPower2Y)
	
	self.t:Line(0,y*nextPower2Y,x*nextPower2X,y*nextPower2Y)
	
	--	self:SetAnchor("BOTTOMLEFT", UIParent, "BOTTOMLEFT", n.offset + n.minLength*n.colNum+ n.margin/2, y+dy)---self:Height()/2)
end

function sliderTouchDown(self)
	DPrint("touchDown")
end

function createSlider()
	n.slider = Region()
	n.slider:SetWidth(n.numSize)
	n.slider:SetHeight((n.numSize + n.margin/2) * n.rowNum- n.margin/2)
	n.slider.t = n.slider:Texture(150,150,100,255)
	n.slider:SetAnchor("BOTTOMLEFT", UIParent, "BOTTOMLEFT", n.offset + n.minLength*n.colNum+ n.margin/2, n.margin/2)
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

if n.slideInstrument ==1 then
	createSlider()
end



function drawKeys()
	for i=1,n.rowNum do
		updateNoteName(i)
		for j=1,n.colNum do
			drawCell(n.buttons[i][j])
		end
	end
end
function insertRow(i)
	n.rowNum = n.rowNum +1
	
	local numRow
	for numRow = n.rowNum ,i+1,-1  do
		n.buttons[numRow] = n.buttons[numRow-1]
		--DPrint("numRow:"..numRow.."/i:"..i);
		
		for j=1,n.colNum do
			n.buttons[numRow][j].row = n.buttons[numRow][j].row +1
			drawCell(n.buttons[numRow][j])
		end
		n.labels[numRow] = n.labels[numRow-1]
		n.labels[numRow]:SetHeight(n.numSize)
		n.labels[numRow]:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT", n.margin/2 , n.margin/2 + (numRow-1)* n.minLength)
		
	end
	n.buttons[i] = nil
	n.buttons[i] = {}
	
	for j=1, n.colNum do
		createCell(i,j)
		
	end
	
	createNoteName(i)
	n.playBar:SetHeight((n.numSize + n.margin/2) * n.rowNum- n.margin/2)
	n.playBar:SetLayer("HIGH")
	n.playBar:Show()
	
	drawKeys()
	
end

function putMsg(msg, pushfunction)
	newregion = Region()
	newregion:SetWidth(200)
	newregion:SetHeight(50 )
	newregion.tl = newregion:TextLabel()
	newregion.tl:SetFontHeight(30)
	newregion.tl:SetColor(100,100,100,255)
	newregion.tl:SetLabel(msg)
	newregion:EnableInput(true)
	newregion:Handle("OnTouchDown",pushfunction)
	newregion.toggle = false;
	newregion:Show()
	newregion.t = newregion:Texture(255,255,255,255)
	newregion:SetAnchor("CENTER",UIParent,"CENTER", 0,400)
end