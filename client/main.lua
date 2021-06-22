ESX = nil
local menuOpen = false
local wasOpen = false
local showDeleteMarker = false
local blips = {}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	ESX.PlayerData = ESX.GetPlayerData()
end)

function LoadModel(model)
	RequestModel(model)
	while not HasModelLoaded(model) do
		Citizen.Wait(100)
	end
end

function CreatePNJ(model, coords, h)
	LoadModel(model)
	local x, y, z = table.unpack(coords)
	local ped = CreatePed(5, model, x, y, z-1, h, false, true)
	SetPedCombatAttributes(ped, 46, true)                     
	SetPedFleeAttributes(ped, 0, 0)                      
	SetBlockingOfNonTemporaryEvents(ped, true)
	SetEntityAsMissionEntity(ped, true, true)
	SetEntityInvincible(ped, true)
	FreezeEntityPosition(ped, true)
end

-- Fonction --> Créer blips

function CreateBlip(coords, text, color, sprite)
	local blip = AddBlipForCoord(coords)

	SetBlipHighDetail(blip, true)
	SetBlipSprite (blip, sprite)
	SetBlipScale  (blip, 1.0)
	SetBlipColour (blip, color)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(text)
	EndTextCommandSetBlipName(blip)

	return blip
end

Citizen.CreateThread(function()
	CreateBlip(Config.Vestiaire.coords, Config.Vestiaire.name, Config.Vestiaire.color, Config.Vestiaire.sprite)
	CreatePNJ(GetHashKey(Config.PedModelProcess), Config.CircleZones.CornProcess.coords, Config.CircleZones.CornProcess.heading)
	CreatePNJ(GetHashKey(Config.PedModelSell), Config.CircleZones.Seller.coords, Config.CircleZones.Seller.heading)
	CreatePNJ(GetHashKey(Config.PedModelVestiaire), Config.Vestiaire.coords, Config.Vestiaire.heading)
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

		if showDeleteMarker then
			DrawMarker(39, Config.DeleteVehicle.coords, -77.0, -90.0, 0.0, -90.0, 0.0, 0.0, 3.0, 3.0, 3.0, 255, 0, 0, 100, false, false, 2, false, false, false, false)
		end

		if GetDistanceBetweenCoords(coords, Config.CircleZones.Seller.coords, true) < 1 then
			if not menuOpen then
				ESX.ShowHelpNotification(_U('seller_prompt'))

				if IsControlJustReleased(0, 38) then
					ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
						if isInService then
							wasOpen = true
							OpenSellerShop()
						else
							ESX.ShowNotification(_U('not_in_service'))
						end
					end, 'farmer')
				end
			else
				Citizen.Wait(500)
			end
		elseif GetDistanceBetweenCoords(coords, Config.Vestiaire.coords, true) < 1 then
			if not menuOpen then
				ESX.ShowHelpNotification(_U('vestiaire_prompt'))

				if IsControlJustReleased(0, 38) then
					wasOpen = true
					OpenVestiaire()
				end
			else
				Citizen.Wait(500)
			end
		elseif GetDistanceBetweenCoords(coords, Config.DeleteVehicle.coords, true) < 20 then
			if not showDeleteMarker then
				ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
					if isInService then
						showDeleteMarker = true
					end
				end, 'farmer')
			end

			if GetDistanceBetweenCoords(coords, Config.DeleteVehicle.coords, true) < 3 then
				if showDeleteMarker then
					ESX.ShowHelpNotification(_U('delete_vehicle'))
		
					if IsControlJustReleased(0, 38) then
						ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
							if isInService then
								local currentVehicle = GetVehiclePedIsIn(playerPed)
								if currentVehicle ~= 0 then
									local VehicleModel = GetEntityModel(currentVehicle)
									if VehicleModel == GetHashKey(Config.VehicleModel) then
										ESX.Game.DeleteVehicle(currentVehicle)
									else
										ESX.ShowNotification(_U('not_good_vehicle'))
									end
								else
									ESX.ShowNotification(_U('no_vehicle'))
								end
							else
								ESX.ShowNotification(_U('not_in_service'))
							end
						end, 'farmer')
					end
				end
			end
		else
			if wasOpen then
				wasOpen = false
				ESX.UI.Menu.CloseAll()
			end

			if showDeleteMarker then
				showDeleteMarker = false
			end

			menuOpen = false

			Citizen.Wait(500)
		end
	end
end)

function OpenSellerShop()
	ESX.UI.Menu.CloseAll()
	local elements = {}
	menuOpen = true

	local inventory = ESX.GetPlayerData().inventory

	for i=1, #inventory do
		local price = Config.Vente[inventory[i].name]

		if price and inventory[i].count > 0 then
			table.insert(elements, {
				label = ('%s - <span style="color:green;">%s</span>'):format(inventory[i].label, _U('seller_item', ESX.Math.GroupDigits(price))),
				name = inventory[i].name,
				price = price,

				-- menu properties
				type = 'slider',
				value = 1,
				min = 1,
				max = inventory[i].count
			})
		end
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'seller', {
		title    = _U('seller_title'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		TriggerServerEvent('esx_farmer:sell', data.current.name, data.current.value)
	end, function(data, menu)
		menu.close()
		menuOpen = false
	end)
end

function OpenVestiaire()
	ESX.UI.Menu.CloseAll()

	local elements = {
		{label = "Prendre son service", value = "enable_service"},
		{label = "Quitter son service", value = "disable_service"}
	}
	ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
		if isInService then
			table.insert(elements, {label = "Sortir un véhicule", value = "take_vehicle"})
		end
	end, 'farmer')
	menuOpen = true

	Citizen.Wait(150)

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'Vestiaire', {
		title    = 'Vestiaire',
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		if data.current.value == "enable_service" then
			ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
				if isInService then
					ESX.ShowNotification(_U('already_in_service'))
				else
					ESX.TriggerServerCallback('esx_service:enableService', function(canTakeService, maxInService, inServiceCount)

						if canTakeService then
						  ESX.ShowNotification(_U('enable_service'))
						else
						  ESX.ShowNotification('Service plein: ' .. inServiceCount .. '/' .. maxInService)
						end
					  
					end, 'farmer')
		
					ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
						if skin.sex == 0 then
							TriggerEvent('skinchanger:loadClothes', skin, Config.Tenues.Male)
						else
							TriggerEvent('skinchanger:loadClothes', skin, Config.Tenues.Female)
						end
					end)
					TriggerEvent('esx_farmer:refreshBlips')
					menuOpen = false
					menu.close()
				end
			end, 'farmer')
		elseif data.current.value == "disable_service" then
			ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
				if isInService then
					TriggerServerEvent('esx_service:disableService', 'farmer')
					ESX.ShowNotification(_U('disable_service'))
					ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
						TriggerEvent('skinchanger:loadSkin', skin)
					end)
					TriggerEvent('esx_farmer:refreshBlips')
					menuOpen = false
					menu.close()
				else
					ESX.ShowNotification(_U('not_in_service'))
				end
			end, 'farmer')
		elseif data.current.value == 'take_vehicle' then
			ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
				if isInService then
					local elements = {
						{label = "Tracteur",  value = 'tractor2'},
					}
	
					ESX.UI.Menu.CloseAll()
	
					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_vehicle', {
						title    = "Garage",
						align    = 'top-left',
						elements = elements
					}, function(data, menu)
						if ESX.Game.IsSpawnPointClear(Config.SpawnVehicle.coords, 5) then
							ESX.Game.SpawnVehicle(data.current.value, Config.SpawnVehicle.coords, Config.SpawnVehicle.heading, function(vehicle)
								local playerPed = PlayerPedId()
								TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
							end)
							menuOpen = false
							menu.close()
						else
							ESX.ShowNotification(_U('no_place'))
						end
					end, function(data, menu)
						menu.close()
					end)
				else
					ESX.ShowNotification(_U('not_in_service'))
				end
			end, 'farmer')
		end
	end, function(data, menu)
		menu.close()
		menuOpen = false
	end)
end

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		if menuOpen then
			ESX.UI.Menu.CloseAll()
		end
	end
end)

RegisterNetEvent('esx_farmer:refreshBlips')
AddEventHandler('esx_farmer:refreshBlips', function()
	ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
		if isInService then
			for _,zone in pairs(Config.CircleZones) do
				blip = CreateBlip(zone.coords, zone.name, zone.color, zone.sprite)
				table.insert(blips, blip)
			end
		else
			for i=1, #blips do
				RemoveBlip(blips[i])
			end
			blips = {}
		end
	end, 'farmer')
end)