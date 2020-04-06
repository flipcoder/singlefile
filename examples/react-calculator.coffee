#!/usr/bin/singlefile

@npm =
    name: 'r'
    dependencies:
        react: '*'
        'react-dom': '*'
        'create-react-class': '*'
        'react-hyperscript': '*'
        'hyperscript': '*'
        'hyperscript-helpers': '*'
        'jquery': '*'
        'bss': '*'
        'mathjs': '*'

h = require('hyperscript')
{ html, head, body, link, script } = require('hyperscript-helpers')(h)

@pub = pub =
    'index.html': [
        '<!DOCTYPE html>',
        html {lang:'en'}, [
            head [
                link {rel:'stylesheet', href:'main.css'}
            ],
            body [
                h('div#root'),
                script({src:'client.js'})
            ]
        ],
    ]

@views =
    'main.styl': '''
        body
            background-color: #bbbbbb
        input
            width: 89%
        button
            width: 9%
    '''

@client = ->
    window.jQuery = global.jQuery = $ = require('jquery')
    h = require('react-hyperscript')
    React = require('react')
    createReactClass = require('create-react-class')
    ReactDOM = require('react-dom')
    { p, link, script, html, head, body, div, button, ul, li, h3, form, label, input, br } = require('hyperscript-helpers')(h)
    css = require('bss')
    math = require('mathjs').evaluate

    class CalcApp extends React.Component
        constructor: (props) ->
            super props
            @state =
                items: []
                text: ''
            @handleChange = @handleChange.bind(this)
            @handleSubmit = @handleSubmit.bind(this)
        handleChange: (e)->
            @setState
                text: e.target.value
        handleSubmit: (e)->
            e.preventDefault()
            if @state.text.length == 0
                return
            try
                m = math(@state.text)
            catch
                m = 'ERROR'
            newItem =
                text: @state.text + ' = ' + m
                id: Date.now()
            @setState (state)->
                items: [newItem].concat state.items
        render: ->
            div [
                form({onSubmit:@handleSubmit},[
                    input({id:'new-entry',onChange:@handleChange,value:@state.text}),
                    button('=')
                ]),
                br(),
                h(CalcHistory, {items:@state.items}),
            ]
    
    class CalcHistory extends React.Component
        render: ->
            return h [
                h('div.ui.message', [
                    h('div.list', @props.items.map (item)-> h 'div.item', {key:item.id}, item.text),
                ]),
                br()
            ]
    
    ReactDOM.render React.createElement(CalcApp), document.getElementById('root')
    
@server = (app)->
    app.get '/', (req,res) ->
        res.render 'index.html'

    await app.run()
    console.log 'server running @ port 3000'

