-- *******
-- Copyright (C) JSFOUR - All Rights Reserved
-- You are not allowed to sell this script or re-upload it
-- Visit my page at https://github.com/jonassvensson4
-- Written by Jonas Svensson, July 2018
-- *******

local open = false
local type = 'fleeca'

-- Notification
function hintToDisplay(text)
	SetTextComponentFormat("STRING")
	AddTextComponentString(text)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- Enter / Exit zones
Citizen.CreateThread(function ()
  SetNuiFocus(false, false)
	time = 500
	x = 1
  while true do
    Citizen.Wait(time)
		inMarker = false
		inBankMarker = false

    for i=1, #Config.ATMS, 1 do
      if GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)), Config.ATMS[i].x, Config.ATMS[i].y, Config.ATMS[i].z, true) < 2  then
				x = i
				time = 0
				if ( Config.ATMS[i].b == nil ) then
					inMarker = true
					hintToDisplay('Press ~INPUT_PICKUP~ to use this ATM')
				end
			elseif GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)), Config.ATMS[x].x, Config.ATMS[x].y, Config.ATMS[x].z, true) > 4 then
				time = 500
			end
    end

	end
end)

RegisterNetEvent("ples-atm:getMoneyC")
AddEventHandler("ples-atm:getMoneyC", function(dbank, dcash)
	SetNuiFocus(true, true)
	open = true
	SendNUIMessage({
		action = "open",
		bank = tonumber(dbank),
		cash = tonumber(dcash)
	})
end)

local dataUser = {}
RegisterNetEvent("ples-atm:getUSerC")
AddEventHandler("ples-atm:getUSerC", function(table)
	dataUser = table
end)

RegisterNetEvent("ples-atm:correctCode")
AddEventHandler("ples-atm:correctCode", function()
	TriggerEvent("chatMessage", "Ai introdus codul corect")
	SendNUIMessage({
		action = "correct"
	})
end)
RegisterNetEvent("ples-atm:wrongCode")
AddEventHandler("ples-atm:wrongCode", function()
	SendNUIMessage({
		action = "wrong"
	})
end)

-- Key event
Citizen.CreateThread(function ()
  while true do
    Citizen.Wait(1)
		if IsControlJustReleased(0, 38) and inMarker then
			TriggerServerEvent('ples-atm:getMoney')
		end
		if open then
      DisableControlAction(0, 1, true) -- LookLeftRight
      DisableControlAction(0, 2, true) -- LookUpDown
      DisableControlAction(0, 24, true) -- Attack
      DisablePlayerFiring(GetPlayerPed(-1), true) -- Disable weapon firing
      DisableControlAction(0, 142, true) -- MeleeAttackAlternate
      DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
    end
	end
end)

-- Insert money
RegisterNUICallback('insert', function(data, cb)
	cb('ok')
	--TriggerEvent("chatMessage", "INSERT: DONE")
	TriggerServerEvent('ples-atm:insert', data.money)
end)

-- Take money
RegisterNUICallback('take', function(data, cb)
	cb('ok')
	--TriggerEvent("chatMessage", "TAKE: DONE")
	TriggerServerEvent('ples-atm:take', data.money)
end)

-- Transfer money
RegisterNUICallback('transfer', function(data, cb)
	cb('ok')
	--TriggerEvent("chatMessage", "TRANSFER: DONE")
	TriggerServerEvent('ples-atm:transfer', data.money, data.account)
end)

local code = 0
RegisterNUICallback('number', function(data, cb)
	cb('ok')
	if code < 1000 then
		code = code * 10 + data.number
	end
end)

RegisterNUICallback('cancelcode', function(data, cb)
	cb('ok')
	code = 0
end)

RegisterNUICallback('entercode', function(data, cb)
	cb('ok')
	TriggerServerEvent("ples-atm:checkCode", code)
end)

-- Close the NUI/HTML window
RegisterNUICallback('escape', function(data, cb)
	SetNuiFocus(false, false)
	open = false
	code = 0
	cb('ok')
end)

-- Handles the error message
RegisterNUICallback('error', function(data, cb)
	SetNuiFocus(false, false)
	open = false
	code = 0
	cb('ok')
	TriggerEvent("chatMessage", 'This ATM it\'s already in use')
end)
