
function pushChange(self)
	n.notes = {	0,	2,	4,	5,	7,	9,	10,	11,	12,14}
	insertRow(7)
	self:Hide()
	self = nil;
end

putMsg("Insert D6", pushChange);
