fx_version 'cerulean'
game 'gta5'

author 'RP-Alpha'
description 'RP-Alpha Tuning System - Mechanic shops + handling tuning'
version '2.0.0'

dependency 'rpa-lib'

shared_script 'config.lua'

client_scripts {
    '@ox_lib/init.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

lua54 'yes'
