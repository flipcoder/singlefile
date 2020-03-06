#!/usr/bin/singlefile

@config =
    base: 'default'

@npm =
    name: 'singlefile-example'

@views =
    'index.pug': '''
        doctype html
        html(lang='en')
          head
            script(src='client.js')
          body
            p Hello World!
    '''

@client = ()->
    console.log 'client'

@server = (app)->
    app.get '/', (req,res)->
        res.render 'index.pug'

    await app.run()
    
    console.log 'server running'

