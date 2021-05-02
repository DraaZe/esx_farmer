Config = {}

Config.Locale = 'fr'

Config.DrawDistance = 25.0 -- Distance d'affichage du champs

Config.Delays = {
	CornPickup = 5000, -- 5 secondes de temps de récolte.
	CornProcessing = 5000 -- 5 secondes temps de traitement.
}

Config.Vente = {
	bread = 25
}

Config.VehicleModel = "tractor2" -- Model du véhicule pour récolter
Config.PedModelProcess = "a_m_m_farmer_01" -- Model du PNJ de traitement.
Config.PedModelSell = "a_m_y_business_02" -- Model du PNJ de traitement.
Config.PedModelVestiaire = "a_m_m_hillbilly_01" -- Model du PNJ du vestiaire.

Config.PickupKey = 47 -- Touche pour récolter.

Config.Tenues = {
	Male = {
		tshirt_1 = 46,
		tshirt_2 = 0,
		torso_1 = 43,
		torso_2 = 0,
		arms = 70,
		pants_1 = 90,
		pants_2 = 0,
		shoes_1 = 25,
		shoes_2 = 0,
		helmet_1 = 76,
		helmet_2 = 15
	},

	Female = {
		tshirt_1 = 51,
		tshirt_2 = 1,
		torso_1 = 0,
		torso_2 = 2,
		arms = 84,
		pants_1 = 93,
		pants_2 = 0,
		shoes_1 = 25,
		shoes_2 = 0,
		helmet_1 = 75,
		helmet_2 = 15
	}
}

Config.Vestiaire = {
	coords = vector3(2336.87, 4858.44, 41.81), 
	heading = 224.98,
	name = _U('blip_vestiaire'), 
	color = 2, 
	sprite = 540,
}

Config.SpawnVehicle = {
	coords = vector3(2357.95, 4892.11, 42.06), 
	heading = 135.97,
}

Config.CircleZones = {
	--Champs de récoltes.
	CornField = {coords = vector3(2543.44, 4808.33, 33.59), name = _U('blip_cornfield'), color = 2, sprite = 540},
	--Emplacement du traitement.
	CornProcess = {coords = vector3(1725.35, 4713.94, 42.1), heading = 194.61, name = _U('blip_cornprocess'), color = 2, sprite = 540},
	-- Emplacement du vendeur.
	Seller = {coords = vector3(1958.7, 3837.22, 32.03), heading = 302.5, name = _U('blip_seller'), color = 2, sprite = 540},
}