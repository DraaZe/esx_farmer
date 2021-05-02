local spawnedPlants = 0
local cornPlants = {}
local isPickingUp, isProcessing = false, false

-- Traitement

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

		if GetDistanceBetweenCoords(coords, Config.CircleZones.CornProcess.coords, true) < 3 then
			if not isProcessing then
				ESX.ShowHelpNotification(_U('corn_processprompt'))
			end

			if IsControlJustReleased(0, 38) and not isProcessing then
				ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
					if isInService then
						ESX.TriggerServerCallback('esx_farmer:corn_count', function(xCorn)
							ProcessCorn(xCorn)
						end)
					else
						ESX.ShowNotification(_U('not_in_service'))
					end
				end, 'farmer')
			end
		else
			Citizen.Wait(500)
		end
	end
end)

function ProcessCorn(xCorn)
	isProcessing = true
	ESX.ShowNotification(_U('corn_processingstarted'))
  	TriggerServerEvent('esx_farmer:processCorn')
	if(xCorn <= 3) then
		xCorn = 0
	end
  	local timeLeft = (Config.Delays.CornProcessing * xCorn) / 1000
	local playerPed = PlayerPedId()

	while timeLeft > 0 do
		Citizen.Wait(1000)
		timeLeft = timeLeft - 1

		if GetDistanceBetweenCoords(GetEntityCoords(playerPed), Config.CircleZones.CornProcess.coords, false) > 4 then
			ESX.ShowNotification(_U('corn_processingtoofar'))
			TriggerServerEvent('esx_farmer:cancelProcessing')
			TriggerServerEvent('esx_farmer:outofbound')
			break
		end
	end

	isProcessing = false
end

-- Récolte

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(500)
		local coords = GetEntityCoords(PlayerPedId())

		if GetDistanceBetweenCoords(coords, Config.CircleZones.CornField.coords, true) < Config.DrawDistance then
			SpawnCornPlants()
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local nearbyObject, nearbyID

		for i=1, #cornPlants do
			if GetDistanceBetweenCoords(coords, GetEntityCoords(cornPlants[i]), false) < 2 then
				nearbyObject, nearbyID = cornPlants[i], i
			end
		end

		local currentVehicle = GetVehiclePedIsIn(playerPed)

		if nearbyObject then
			if currentVehicle ~= 0 then
				local VehicleModel = GetEntityModel(currentVehicle)
				if VehicleModel == GetHashKey(Config.VehicleModel) then
					if not isPickingUp then
						ESX.ShowHelpNotification(_U('corn_pickupprompt'))
					end
		
					if IsControlJustReleased(0, Config.PickupKey) and not isPickingUp then
						ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
							if isInService then
								isPickingUp = true
				
								ESX.TriggerServerCallback('esx_farmer:canPickUp', function(canPickUp)
									if canPickUp then
										FreezeEntityPosition(currentVehicle, true)		
										exports['progressBars']:startUI(Config.Delays.CornPickup, "Récolte en cours..")
										Citizen.Wait(Config.Delays.CornPickup)
										FreezeEntityPosition(currentVehicle, false)
						
										ESX.Game.DeleteObject(nearbyObject)
						
										table.remove(cornPlants, nearbyID)
										spawnedPlants = spawnedPlants - 1
						
										TriggerServerEvent('esx_farmer:pickedUpCorn')
									else
										ESX.ShowNotification(_U('corn_inventoryfull'))
									end
				
									isPickingUp = false
								end, 'corn')
							else
								ESX.ShowNotification(_U('not_in_service'))
							end
						end, 'farmer')
					end
				else
					ESX.ShowNotification(_U('wrong_vehicle'))
				end
			else 
				ESX.ShowNotification(_U('wrong_vehicle'))
			end
		else
			Citizen.Wait(500)
		end
	end
end)

-- Event --> Si la ressource se stop, permet de retirer tout les objets déjà créé.
AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for i=1, #cornPlants do
			ESX.Game.DeleteObject(cornPlants[i])
		end
	end
end)

-- Fonction --> Permet de créer les différents objets.
function SpawnCornPlants()
	while spawnedPlants < 10 do
		Citizen.Wait(0)
		local cornCoords = GenerateCornCoords()

		ESX.Game.SpawnLocalObject('prop_veg_grass_01_a', cornCoords, function(obj)
			PlaceObjectOnGroundProperly(obj)
			FreezeEntityPosition(obj, true)

			table.insert(cornPlants, obj)
			spawnedPlants = spawnedPlants + 1
		end)
	end
end

-- Fonction --> Permet de valider les coodonnées générées ci-dessous.
function ValidateCornCoord(plantCoord)
	if spawnedPlants > 0 then
		local validate = true

		for i=1, #cornPlants do
			if GetDistanceBetweenCoords(plantCoord, GetEntityCoords(cornPlants[i]), true) < 5 then
				validate = false
			end
		end

		if GetDistanceBetweenCoords(plantCoord, Config.CircleZones.CornField.coords, false) > 50 then
			validate = false
		end

		return validate
	else
		return true
	end
end

-- Fonction --> Permet de générer les coordonnées des différents objets.
function GenerateCornCoords()
	while true do
		Citizen.Wait(1)

		local cornCoordX, cornCoordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-10, 10)

		Citizen.Wait(100)

		math.randomseed(GetGameTimer())
		local modY = math.random(-10, 10)

		cornCoordX = Config.CircleZones.CornField.coords.x + modX
		cornCoordY = Config.CircleZones.CornField.coords.y + modY

		local coordZ = GetCoordZ(cornCoordX, cornCoordY)
		local coord = vector3(cornCoordX, cornCoordY, coordZ)

		if ValidateCornCoord(coord) then
			return coord
		end
	end
end


-- Fonction --> Permet de récupérer la coordonnée Z adéquate.
function GetCoordZ(x, y)
	local groundCheckHeights = { 31.0, 31.1, 31.2, 31.3, 31.4, 31.5, 31.6, 31.7, 31.8, 31.9, 32.0, 32.1, 32.2, 32.3, 32.4, 32.5, 32.6, 32.7, 32.8, 32.9, 33.0, 33.1, 33.2, 33.3, 33.4, 33.5, 33.6, 33.7, 33.8, 33.9, 34.0, 34.1, 34.2, 34.3, 34.4, 34.5, 34.6, 34.7, 34.8, 34.9, 35.0 }

	for i=1, #groundCheckHeights do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, groundCheckHeights[i])

		if foundGround then
			return z
		end
	end

	return 33.5
end
