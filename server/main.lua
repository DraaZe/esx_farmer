ESX = nil
local playersProcessingCorn = {}
local outofbound = true
local alive = true

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

TriggerEvent('esx_service:activateService', 'farmer', 1000) -- 1000joueurs Maximum en service pour être sur.

RegisterServerEvent('esx_farmer:sell')
AddEventHandler('esx_farmer:sell', function(itemName, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local price = Config.Vente[itemName]
	local xItem = xPlayer.getInventoryItem(itemName)

	if not price then
		print(('esx_farmer: %s a tenté de vendre un item invalide!'):format(xPlayer.identifier))
		return
	end

	if xItem.count < amount then
		xPlayer.showNotification(_U('seller_notenough'))
		return
	end

	price = ESX.Math.Round(price * amount)
	xPlayer.addMoney(price)

	xPlayer.removeInventoryItem(xItem.name, amount)
	xPlayer.showNotification(_U('seller_sold', amount, xItem.label, ESX.Math.GroupDigits(price)))
end)

RegisterServerEvent('esx_farmer:pickedUpCorn')
AddEventHandler('esx_farmer:pickedUpCorn', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	local cime = math.random(1,10)

	if xPlayer.canCarryItem('corn', cime) then
		xPlayer.addInventoryItem('corn', cime)
	else
		xPlayer.showNotification(_U('corn_inventoryfull'))
	end
end)

ESX.RegisterServerCallback('esx_farmer:canPickUp', function(source, cb, item)
	local xPlayer = ESX.GetPlayerFromId(source)
	cb(xPlayer.canCarryItem(item, 1))
end)

RegisterServerEvent('esx_farmer:outofbound')
AddEventHandler('esx_farmer:outofbound', function()
	outofbound = true
end)

RegisterServerEvent('esx_farmer:quitprocess')
AddEventHandler('esx_farmer:quitprocess', function()
	can = false
end)

ESX.RegisterServerCallback('esx_farmer:corn_count', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xCorn = xPlayer.getInventoryItem('corn').count
	cb(xCorn)
end)

RegisterServerEvent('esx_farmer:processCorn')
AddEventHandler('esx_farmer:processCorn', function()
  	if not playersProcessingCorn[source] then
		local _source = source
		local xPlayer = ESX.GetPlayerFromId(_source)
		local xCorn = xPlayer.getInventoryItem('corn')
		local can = true
		outofbound = false
    	if xCorn.count >= 3 then
      		while outofbound == false and can do
				if playersProcessingCorn[_source] == nil then
					playersProcessingCorn[_source] = ESX.SetTimeout(Config.Delays.CornProcessing , function()
            			if xCorn.count >= 3 then
              				if xPlayer.canSwapItem('corn', 3, 'bread', 1) then
								xPlayer.removeInventoryItem('corn', 3)
								xPlayer.addInventoryItem('bread', 1)
								xPlayer.showNotification(_U('corn_processed'))
							else
								can = false
								xPlayer.showNotification(_U('corn_processingfull'))
								TriggerEvent('esx_farmer:cancelProcessing')
							end
						else						
							can = false
							xPlayer.showNotification(_U('corn_processingenough'))
							TriggerEvent('esx_farmer:cancelProcessing')
						end

						playersProcessingCorn[_source] = nil
					end)
				else
					Wait(Config.Delays.CornProcessing)
				end	
			end
		else
			xPlayer.showNotification(_U('corn_processingenough'))
			TriggerEvent('esx_farmer:cancelProcessing')
		end	
			
	else
		print(('esx_farmer: %s a tenté d\'exploiter la transformation du blé!'):format(GetPlayerIdentifiers(source)[1]))
	end
end)

function CancelProcessing(playerId)
	if playersProcessingCorn[playerId] then
		ESX.ClearTimeout(playersProcessingCorn[playerId])
		playersProcessingCorn[playerId] = nil
	end
end

RegisterServerEvent('esx_farmer:cancelProcessing')
AddEventHandler('esx_farmer:cancelProcessing', function()
	CancelProcessing(source)
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
	CancelProcessing(playerId)
end)

RegisterServerEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
	CancelProcessing(source)
end)
