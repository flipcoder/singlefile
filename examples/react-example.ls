#!/usr/bin/singlefile

export config =
    port: 3000
    base: 'default'

export npm =
    name: 'singlefile-react-example'
    dependencies:
        react: '*'
        'react-dom': '*'
        'create-react-class': '*'
        'react-hyperscript': '*'
        'hyperscript-helpers': '*'

export views =
    'index.pug': '''
        doctype html
        html(lang='en')
            head
                link(rel='stylesheet', href='main.css')
            body
                div#root
                script(src='client.js')
    ''',
    'main.styl': '''
        body
            background-color: blue
    '''

export client = ->
    h = require('react-hyperscript')
    React = require('react')
    createReactClass = require('create-react-class')
    ReactDOM = require('react-dom')
    { div, button } = require('hyperscript-helpers')(h)

    Hello = createReactClass do
        getInitialState: ->
            return { message: 'hello!' }
        handleClick: ->
            alert(this.state.message)
        render: ->
            return button({ onClick=this.handleClick }, 'Push')

    ReactDOM.render React.createElement(Hello), document.getElementById('root')

export server = (app)->
    app.get '/', (req,res) ->
        res.render 'index.pug'

    <- app.run
    console.log 'server running'

