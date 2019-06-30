#!/usr/bin/singlefile

export config =
    port: 3000
    base: 'default'

export npm =
    name: 'singlefile-example'
    dependencies:
        livescript: '*'
        react: '*'
        'react-dom': '*'
        'react-hyperscript': '*'

export views =
    'index.pug': '''
        doctype html
        html(lang='en')
          head
          body
            div#root
            script(src='client.js')
    '''

export client = ->
    h = require('react-hyperscript')
    React = require('react')
    ReactDOM = require('react-dom')
    root = document.getElementById('root')
    content = h 'div', {}, 'Hello World'
    ReactDOM.render content, root
    return

export server = (app)->
    app.get '/', (req,res) ->
        res.render 'index.pug'

    <- app.run
    console.log 'server running'

