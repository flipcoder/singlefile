#!/usr/bin/lsc

exec = require('child_process').exec
fs = require('fs')
async = require('async')

langs =
    # no need to include languages where the parser is the same name as extension ('coffee')
    js: 'node' # javascript
    ls: 'lsc' # livescript

# TODO: include arg file
# TODO: check parameter for language
# TODO: compile using langs
app = require('./example')

run_yarn = (cb)->
    if app.pkg
        fs.writeFile 'package.json', JSON.stringify(app.pkg), (err)->
            if err
                return cb err
            exec 'yarn', (err, stdout, stderr)->
                if err
                    return cb err
                return cb void
        return
    else
        return cb 'no pkg'

run_grunt = (cb)->
    if app.grunt
        fs.writeFile 'Gruntfile.js', JSON.stringify(app.grunt), (err)->
            if err
                return cb err
            err, stdout, stderr <- exec 'grunt'
            return cb err
        return
    else
        return cb 'no grunt'

err <- run_yarn()
err <- run_grunt()

# cut first and last line of client code (function wrapping)
#client_code = app.client.toString().split('\n',1)[0]
client_code = app.client.toString()
if client_code.lastIndexOf("\n")>0
    client_code = client_code.substring(client_code.indexOf('\n')+1)
    if client_code.lastIndexOf("\n")>0
        client_code = client_code.substring(0, client_code.lastIndexOf('\n'))
    # TODO: cut livescript return statement from last line
    # TODO: cut 1 level of indentation
err <- fs.writeFile 'client.js', client_code

#err, template <- async.eachLimit Object.keys(template), 1, (template,cb)->
#    console.log template
#    return cb void

app.server()

