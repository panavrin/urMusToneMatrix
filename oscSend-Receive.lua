-osc receive part

-- num 
function gotOSC(self, msgType,  num1, num2, num5)
	DPrint("OSC received: "..msgType)
	
	if msgType == 0 then -- button pressed/unpressed
		toggleButton(n.buttons[num1][num2])
	elseif msgType == 1 then -- sync time
		n.nextTickTime = num1
	end
	
	
end

n:Handle("OnOSCMessage",gotOSC)
SetOSCPort(8888)

host,port = StartOSCListener()
DPrint("OSC: "..host..":"..port)


-- osc send part

--n.oldToggleButton = toggleButton
function toggleButton2(self)
	-- do something
	DPrint("I'm doing something");
	toggleButton(self)
	
end
n.buttons[2][2]:Handle("OnTouchDown", toggleButton2)
