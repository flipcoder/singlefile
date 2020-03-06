#!/usr/bin/singlefile

@config =
    port: 3000
    base: 'svelte'

@npm =
    name: 'svelte-example'
    
@pub =
    'main.pug': '''
        p Hello {name}!
    ''',
    
    'main.styl': '''
        body
            background-color: blue
    '''
    
@client = ()->
    @name = 'world'

@server = (app)->
    app.get '*', (req,res)->
        res.render('index')
    await app.run()
    console.log 'server running'

