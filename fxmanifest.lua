fx_version 'cerulean'
game 'gta5'

author 'RP-Alpha'
description 'RP-Alpha Tuning Shop'
version '1.0.0'

dependency 'rpa-lib'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

client_script 'client/main.lua'
server_script 'server/main.lua'

lua54 'yes'
