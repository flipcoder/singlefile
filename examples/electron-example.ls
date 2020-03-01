#!/usr/bin/singlefile

export config =
    port: 3000
    base: 'minimal'
    launcher: 'electron'
    stack: ''

export npm =
    name: 'electron-example'
    main: 'wrapper.js'
    scripts:
        'start': 'electron .'
    dependencies:
        electron: '*'

export views =
    'index.pug': '''
        doctype html
        html(lang='en')
          head
            script(src='client.js')
          body
            p Hello World!
    '''

export client = ->
    console.log 'client'

export server = ->

    electron = require('electron')
    #app = electron.remote.app
    app = electron.app
    BrowserWindow = electron.BrowserWindow
    url = require('url')
    path = require('path')

    win = void

    createWindow = ->
       win = new BrowserWindow({width: 800, height: 600})
           
       #win.loadURL url.format do
       #   pathname: path.join(__dirname, 'index.pug'),
       #   protocol: 'file:',
       #   slashes: true
       win.loadFile 'index.pug'

    app.on 'ready', createWindow
    #app.whenReady().then createWindow

