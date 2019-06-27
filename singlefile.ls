#!/usr/bin/lsc

exec = require('child_process').exec
fs = require('fs')
async = require('async')

langs =
    js: 'node' # javascript
    coffee: 'coffee' # coffeescript
    ls: 'lsc' # livescript

# TODO: include arg file
# TODO: check parameter for language
# TODO: compile using langs
script = require('./' + process.argv[2])

run_npm = (script,cb)->
    if script.npm
        fs.writeFile 'package.json', JSON.stringify(script.npm), (err)->
            if err
                return cb err
            exec 'yarn', (err, stdout, stderr)->
                if err
                    return cb err
                return cb void
        return
    else
        return cb 'no pkg'

run_yarn = (script,cb)->
    if script.yarn
        fs.writeFile 'package.json', JSON.stringify(script.yarn), (err)->
            if err
                return cb err
            exec 'yarn', (err, stdout, stderr)->
                if err
                    return cb err
                return cb void
        return
    else
        return cb 'no pkg'

run_grunt = (script,cb)->
    if script.grunt
        fs.writeFile 'Gruntfile.js', JSON.stringify(script.grunt), (err)->
            if err
                return cb err
            err, stdout, stderr <- exec 'grunt'
            return cb err
        return
    else
        return cb 'no grunt'

err <- run_yarn script
err <- run_npm script
err <- run_grunt script

# cut first and last line of client code (function wrapping)
#client_code = app.client.toString().split('\n',1)[0]
try
    fs.mkdirSync 'public'
client_code = script.client.toString()
if client_code.lastIndexOf("\n")>0
    client_code = client_code.substring(client_code.indexOf('\n')+1)
    if client_code.lastIndexOf("\n")>0
        client_code = client_code.substring(0, client_code.lastIndexOf('\n'))
    # TODO: cut livescript return statement from last line
    # TODO: cut 1 level of indentation
err <- fs.writeFile 'public/client.js', client_code

#err, template <- async.eachLimit Object.keys(template), 1, (template,cb)->
#    console.log template
#    return cb void

#app = void
cfg = script.config
#if cfg
#    if cfg.base=='default'
#        express = require('express')

# TODO: detect technologies from singlefile cfg
express = require('express')
stylus = require('stylus')
pug = require('pug')
http = require('http')

# generate views/templates dir
try
    fs.mkdirSync 'views'
for template, content of script.views
    fs.writeFileSync 'views/'+template, content

app = express()
app.set 'view engine', 'pug'
app.set 'views', __dirname + '/views/'
compile = (str, path) ->
    return stylus(str)
        .set('filename', path)
app.use stylus.middleware do
    src: __dirname + '/views/'
    dest: __dirname + '/public/'
    serve: true
    compress: true
    warn: true
    compile: compile
app.use(express.static('public'))
app.run = (cb)->
    httpserver = http.createServer app
    app.listen cfg.port || 3000, ->
        cb void
script.server(app)

