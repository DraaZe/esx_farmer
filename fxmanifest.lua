fx_version 'adamant'

game 'gta5'

description 'ESX Farmer, modifié par DraZe (DraZe#5289)'

version '1.0.0'

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'locales/fr.lua',
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/fr.lua',
	'config.lua',
	'client/main.lua',
	'client/bread.lua'
}

dependencies {
	'es_extended'
}
