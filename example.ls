#!/usr/bin/singlefile

export cfg =
    port: 3000
    base: 'default'

export yarn =
    name: 'singlefile-example'

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
    return

export server = (app)->
    app.get '/', (req,res) ->
        res.render 'index.pug'

    <- app.run
    console.log 'server running'

