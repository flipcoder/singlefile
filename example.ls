#!/usr/bin/singlefile

export pkg =
    name: 'testapp'

export templates =
    'index.pug': '''
        doctype html
        html(lang='en')
          head
          body
            p Hello World!
    '''

export client = ->
    console.log 'client'
    return

export server = ->
    console.log 'server'

