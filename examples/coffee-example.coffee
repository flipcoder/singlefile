#!/usr/bin/singlefile
e = {}

e.config =
    port: 3000
    base: 'default'

e.npm =
    name: 'singlefile-example'

e.views =
    'index.pug': '''
        doctype html
        html(lang='en')
          head
            script(src='client.js')
          body
            p Hello World!
    '''

e.client = ->
    console.log 'client'

e.server = (app)->
    app.get '/', (req,res) ->
        res.render 'index.pug'

    app.run ->
        console.log 'server running'

module.exports = e

