--[[
n.baseNum = 60
--			1	2	3	4	5	6	7	8	9	10	11	12	13
n.notes = {	0,	1,	2,	3,	4,	5,	6,	7,	8,	9,	10,	11,	12}

]]
n.notes = {	0,	2,	4,	5,	7,	9,	11}

n.baseNum = 60
--n.notes[0] = 12

function updateNoteName(i)
	n.labels[i].tl:SetLabel(n.noteNames[(n.baseNum + n.notes[i])%12 + 1])
end

for i=1,n.rowNum do
	updateNoteName(i)
end
