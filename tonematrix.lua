--[[
bugs
1. more than 10 toggle will make the patch.  crash. 
]]

SetPage(2);
FreeAllRegions();
FreeAllFlowboxes()


local log = math.log
local pow = math.pow 

function freq2Norm(freqHz)
	return 12.0/96.0*log(freqHz/55)/log(2)
end

function noteNum2Freq(num)
	return pow(2,(num-57)/12) * 440 
end


n = Region()

n.host = "67.194.194.117"
n.post = 8888


n.freq = freq2Norm(0.5)
n.rowNum = 7
n.colNum = 8

n.baseNum = 65
--			1	2	3	4	5	6	7	8	9	10	11	12	13
n.notes = {	0,	2,	4,	5,	7,	9,	11}

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
n.swidth = ScreenWidth()
n.sheight = ScreenHeight();
n.offset = 50
n.margin = 10
n.bpm =120
n.minLength = math.min((n.swidth- n.offset)/n.colNum, n.sheight/n.rowNum)
n.numSize =  n.minLength - n.margin/2;
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
		n.playBar:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT",n.offset + (n.count-1) * (n.numSize + n.margin/2),n.margin/2)
		for i=1, n.rowNum do
			if(n.buttons[i][n.count].toggle) then
				totalNoteNum = totalNoteNum+1;
				
				if table.getn(sinosc[n.count%n.polyPhonyNum]) < totalNoteNum then
					buildATone(n.count%n.polyPhonyNum, totalNoteNum)
				end
				setFreq(n.count%n.polyPhonyNum, totalNoteNum, n.notes[i] + n.baseNum)
			end
			
		end   
		
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
	drawCell(self)
	
end

function createNoteName(i)
	local newregion = Region()
	newregion:SetWidth(n.offset - n.margin/2 )
	newregion:SetHeight(n.numSize )
	newregion.tl = newregion:TextLabel()
	local noteNum = n.baseNum + n.notes[i];
--	DPrint(i..","..noteNum..".."..n.noteNames[noteNum%12 + 1])
	newregion.tl:SetLabel(n.noteNames[noteNum%12 + 1])
	newregion.tl:SetFontHeight(10)
	newregion.tl:SetColor(0,0,0,255)
	newregion:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT", n.margin/2 , n.margin/2 + (i-1)* n.minLength)
	
	newregion.t = newregion:Texture(220,200,200,255)
	newregion:Show()
	n.labels[i] = newregion
	
end

function drawCell(self)
	if(self.toggle) then
		self.t = self:Texture(200,200,255,255)
	else
		self.t = self:Texture(220,200,200,255)
	end
	self:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT", n.offset+ n.margin/2 + (self.col-1)*n.minLength, n.margin/2 + (self.row-1)* n.minLength)
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
	newregion.row = i;
	newregion.col = j;
	newregion:EnableInput(true)
	newregion:Handle("OnTouchDown",toggleButton)
	newregion.toggle = false;
	drawCell(newregion)
	newregion:Show()
	n.buttons[i][j] = newregion
end

for i=1,n.rowNum do
	for j=1, n.colNum do
		createCell(i,j)
	end
	createNoteName(i)
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

n.playBar:SetAnchor("BOTTOMLEFT",UIParent,"BOTTOMLEFT",n.offset + n.margin/2,n.margin/2)
n.playBar:Show()
