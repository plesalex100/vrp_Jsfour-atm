-- *******
-- Copyright (C) JSFOUR - All Rights Reserved
-- You are not allowed to sell this script or re-upload it
-- Visit my page at https://github.com/jonassvensson4
-- Written by Jonas Svensson, July 2018
-- *******

local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
MySQL = module("vrp_mysql", "MySQL")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","vRP_pAtms")

--[
MySQL.createCommand("vRP/getNames", 'SELECT firstname, name, registration FROM `vrp_user_identities` WHERE user_id = @user_id')
MySQL.createCommand("vRP/getNames2", 'SELECT firstname, name, registration FROM `vrp_user_identities` WHERE receiver = @receiver')
MySQL.createCommand("vRP/get_code", "SELECT * FROM `vrp_users` WHERE `id`=@user_id")
MySQL.createCommand("vRP/update_code", "UPDATE `vrp_users` SET `atmcode`=@pin1 WHERE `id`=@user_id")
--]]

-- Get money
RegisterServerEvent("ples-atm:getMoney")
AddEventHandler('ples-atm:getMoney', function()
	local user_id = vRP.getUserId({source})
  dbank = vRP.getBankMoney({user_id})
  dcash = vRP.getMoney({user_id})
	--TriggerClientEvent("chatMessage", source, "Server: Cash: "..tonumber(dcash).." | Bank: "..tonumber(dbank))
  TriggerClientEvent("ples-atm:getMoneyC", source, tonumber(dbank), tonumber(dcash))
end)

RegisterServerEvent("ples-atm:checkCode")
AddEventHandler("ples-atm:checkCode", function(codex)
	local user_id = vRP.getUserId({source})
	--TriggerClientEvent("chatMessage", source, "server-ul a primit codul: "..codex)
	MySQL.query("vRP/get_code", {user_id = user_id}, function(db, affected)
		--TriggerClientEvent("chatMessage", source, "1) codul in baza: "..db[1].atmcode)
		if #db > 0 then
			--TriggerClientEvent("chatMessage", source, "2) codul in baza: "..db[1].atmcode)
			if codex == db[1].atmcode then
				TriggerClientEvent("ples-atm:correctCode", vRP.getUserSource({user_id}))
			else
				TriggerClientEvent("ples-atm:wrongCode", vRP.getUserSource({user_id}))
			end
		end
	end)
end)

-- Get user info
RegisterServerEvent('ples-atm:getUser')
AddEventHandler("ples-atm:getUser", function()
	local user_id = vRP.getUserId({source})
  local userData = {}

  MySQL.query('vRP/getNames', {user_id = user_id},
  function (rows, affected)
    if (rows[1] ~= nil) then
      table.insert(userData, {
        firstname = rows[1].firstname,
        lastname = rows[1].name,
        account = rows[1].registration
      })
      TriggerClientEvent("ples-atm:getUSerC", source, userData)
    end
  end)
end)


-- Insert money
RegisterServerEvent('ples-atm:insert')
AddEventHandler('ples-atm:insert', function(amount)
	local user_id = vRP.getUserId({source})
	amount = tonumber(amount)
	if amount <= vRP.getMoney({user_id}) then
		vRP.giveMoney({user_id, -amount})
		local acount = vRP.getBankMoney({user_id})
		vRP.setBankMoney({user_id, acount + amount})
		vRPclient.notify(source, {'~w~You deposited ~g~$' .. amount..''})
	end
end)

-- Take money
RegisterServerEvent('ples-atm:take')
AddEventHandler('ples-atm:take', function(amount)
	local user_id = vRP.getUserId({source})
	amount = tonumber(amount)
	local accountMoney = vRP.getBankMoney({user_id})
	if accountMoney - amount >= 0 then
		vRP.setBankMoney({user_id, accountMoney - amount})
		vRP.giveMoney({user_id, amount})
		vRPclient.notify(source, {'~w~Withdrawn ~g~$' .. amount..''})
	end
end)

-- Transfer money
RegisterServerEvent('ples-atm:transfer')
AddEventHandler('ples-atm:transfer', function(amount, receiver)

  local user_id      = vRP.getUserId({source})
	local amount       = tonumber(amount)
	local accountMoney = vRP.getBankMoney({user_id})
  local source2      = vRP.getUserSource({receiver})

	if amount < accountMoney then
    local bankR = vRP.getBankMoney({receiver})
		vRP.setBankMoney({receiver, bankR + amount})
    vRP.setBankMoney({user_id, accountMoney - amount})
    MySQL.query('vRP/getNames2', {receiver = receiver},
    function (rows, affected)
      if (rows[1] ~= nil) then
        vRPclient.notify(source, {'~w~I-ai trimis ~g~' .. amount .. 'RON~w~ lui ' .. rows[1].firstname .. ' ' .. rows[1].name})
        vRPclient.notify(source2, {'~w~Ai primit ~g~' .. amount .. 'RON~w~ trimisi de catre ' .. GetPlayerName(source)})
      end
    end)
  end
end)

vRP.registerMenuBuilder({"main", function(add, data)
	local choicesx = {}
	choicesx["Change ATM PIN"] = {
		function(player, choice)
			local user_id = vRP.getUserId({player})
			if user_id ~= nil then
				vRP.prompt({player,"New PIN: ","1234",function(player, pin1)
		      pin1 = parseInt(pin1)
					pin1 = tonumber(pin1)
					if pin1 >= 1000 and pin1 <= 10000 then
			      vRP.prompt({player, "Repeat PIN-ul ", "", function(player, pin2)
							pin2 = parseInt(pin2)
							pin2 = tonumber(pin2)
							if pin1 == pin2 then
								MySQL.query("vRP/update_code", {pin1 = pin1, user_id = user_id})
								vRPclient.notify(player, {"~g~You've changed your PIN-ul\n~w~Your new PIN is: ~g~"..pin1})
							else
								vRPclient.notify(player, {"~r~PINs aren't the same."})
							end
						end})
					else
						vRPclient.notify(player, {"~r~The PIN must be 4 digits\n~r~The PIN can't have the first digit 0."})
					end
		    end})
			end
		end,
	"Change your ATM PIN"}
	add(choicesx)
end})
