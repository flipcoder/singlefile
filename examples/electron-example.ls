#!/usr/bin/singlefile

export config =
    port: 3000
    base: 'minimal'
    launcher: 'electron'

export npm =
    name: 'electron-example'
    main: 'wrapper.js'
    scripts:
        'start': 'electron .'
    dependencies:
        electron: '*'
        pug: '*'

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
    pug = require('pug')
    app = electron.app
    BrowserWindow = electron.BrowserWindow
    url = require('url')
    path = require('path')

    win = void

    html = pug.render views['index.pug']
    html = 'data:text/html;charset=UTF-8,' + encodeURIComponent(html)

    createWindow = ->
        win = new BrowserWindow({width: 800, height: 600})
        win.loadURL html

    app.on 'ready', createWindow

