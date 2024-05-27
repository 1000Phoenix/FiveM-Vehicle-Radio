fx_version 'cerulean'
game 'gta5'

author 'Phoenix'
description 'A customisable radio script to replace the default radial wheel!'
version '0.1'

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/styles.css',
    'html/images/*.png'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'xsound'
}