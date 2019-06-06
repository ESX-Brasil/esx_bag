resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'ESX Bag'

version '1.1.1'

client_scripts {
  '@es_extended/locale.lua',
  'locales/br.lua',
  'client/main.lua',
  'config.lua'
}

server_scripts {
  '@es_extended/locale.lua',
  'locales/br.lua',
  'server/main.lua',
  'config.lua',
  '@mysql-async/lib/MySQL.lua'
}
