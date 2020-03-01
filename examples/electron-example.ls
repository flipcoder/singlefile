#!/usr/bin/singlefile

export config =
    base: 'electron'

export npm =
    name: 'electron-example'

export views =
    'index.pug': '''
        doctype html
        html(lang='en')
          head
            script(src='client.js')
          body
            p Hello World!
    '''

export server = (electron)->

    pug = require('pug')
    url = require('url')
    path = require('path')

    app = electron.app
    BrowserWindow = electron.BrowserWindow

    win = void

    html = pug.render views['index.pug']
    html = 'data:text/html;charset=UTF-8,' + encodeURIComponent(html)

    createWindow = ->
        win = new BrowserWindow({width: 800, height: 600})
        win.loadURL html

    app.on 'ready', createWindow

