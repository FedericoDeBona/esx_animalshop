fx_version 'adamant'
game 'gta5'


description 'ESX Animal Shop'

client_scripts {
  '@es_extended/locale.lua',
  'client/main.lua',
  'config.lua',
  'locales/en.lua',
  'locales/it.lua'
}

server_scripts {
  '@mysql-async/lib/MySQL.lua',
  '@es_extended/locale.lua',
  'server/main.lua',
  'config.lua',
  'locales/en.lua',
  'locales/it.lua'
}
