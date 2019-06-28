#!/usr/bin/lsc

argv = []
argv = Object.assign argv, process.argv.slice(0)

fs = require('fs')
#async = require('async')
path = require('path')

interpreters =
    #js: 'node' # javascript
    coffee: 'coffeescript'
    ls: 'livescript'

if process.env.SINGLEFILE # launching wrapper
    # include interpreter since we're generating singlefile.js and we need script require()s

    interpreter = void
    if process.env.SINGELFILE != 'js'
        interpreter = require(interpreters[process.env.SINGLEFILE])
    fn = path.resolve(argv[2])
    scriptdir = path.dirname(fn)
    script = require(fn)
    cfg = script.config

    express = require('express')
    stylus = require('stylus')
    pug = require('pug')
    http = require('http')
    bodyParser = require('body-parser')

    app = express()
    # TODO: method override?
    app.use(bodyParser.urlencoded({ extended: true }))
    app.use(bodyParser.json())
    # TODO: session
    app.set 'view engine', 'pug'
    app.set 'views', __dirname + '/views/'
    compile = (str, p) ->
        return stylus(str)
            .set('filename', p)
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
    return script.server(app)

child_process = require('child_process')

if argv.length <= 3
    console.log 'singlefile <file>'
    return

fn = path.resolve(argv[3])
cwd = process.cwd()

# TODO: check first/second line of script for compiler

compilers =
    #js: 'node' # javascript
    coffee: 'coffee -c' # coffeescript
    ls: 'lsc -c' # livescript

scriptfn = path.basename(argv[3])
#console.log scriptfn
pp = path.parse(fn)
scriptdir = path.dirname(fn)
ext = pp.ext.substring(1)
scriptname = pp.name

# create subdir using project name (to keep things clean)
#try
#    fs.mkdirSync path.join(scriptdir,scriptname)

#jsname = path.join(scriptdir,scriptname,scriptname)
if ext in Object.keys(compilers)
    #console.log langs[ext] + ' ' + scriptfn
    r = child_process.execSync(compilers[ext] + ' ' + fn, {cwd=scriptdir})
    # copy new js to script dir
    #fs.renameSync path.join(scriptdir,scriptname+'.js'), path.join(scriptdir,scriptname,scriptname+'.js')

# check if script dir
#console.log fn
script = require(fn)

# if they're missing, inject singlefile wrapper dependencies into script's package.json
inject_libs = (pkg)->
    libs = [ 'express', 'pug', 'stylus', 'grunt-browserify', 'body-parser' ]
    if not ('dependencies' in Object.keys(pkg))
        pkg.dependencies = {}
    for lib in libs
        if not (lib in Object.keys(pkg.dependencies))
            pkg.dependencies[lib] = '*'
    return pkg

run_npm = (script,cb)->
    # create if it doesn't exist
    if not script.npm and not script.yarn
        script.npm = {}
    if script.npm
        inject_libs(script.npm)

        fs.writeFile path.join(scriptdir, 'package.json'), JSON.stringify(script.npm,null,4), (err,a)->
            if err
                console.log err
                return cb err
            child_process.exec 'npm install', {cwd:scriptdir}, (err, stdout, stderr)->
                if err
                    console.log err
                return cb err
        return
    else
        return cb 'no pkg'

run_yarn = (script,cb)->
    if script.yarn
        inject_libs(script.yarn)

        fs.writeFile path.join(scriptdir, 'package.json'), JSON.stringify(script.yarn,null,4), (err)->
            if err
                return cb err
            child_process.exec 'yarn', {cwd:scriptdir}, (err, stdout, stderr)->
                return cb err
        return
    else
        return cb 'no pkg'

run_grunt = (script,cb)->
    # TODO: inject browserify for client code
    if not script.grunt
        script.grunt = {}
        script.grunt.config =
            pkg: script.npm || script.yarn
            browserify:
                client:
                    src: ['client-pre.js'],
                    dest: 'public/client.js'
        script.grunt.load = ['grunt-browserify']
        script.grunt.register = ['browserify']

    if script.grunt

        g = "module.exports = function(grunt) { grunt.initConfig(\n"
        g += JSON.stringify(script.grunt.config,null,4) + '\n'
        g += ');\n'
        for load in script.grunt.load
            g += '\ngrunt.loadNpmTasks(\'' + load + '\');'
        g += '\ngrunt.registerTask(\'default\', ['
        for register in script.grunt.register
            g += '\''+register+'\','
        g += ']);\n}'

        fs.writeFile path.join(scriptdir,'Gruntfile.js'), g, (err)->
            if err
                return cb err
            child_process.exec 'grunt', (err, stdout, stderr)->
                return cb err
        return
    else
        return cb 'no grunt'

err <- run_yarn script
err <- run_npm script
err <- run_grunt script

# cut first and last line of client code (function wrapping)
#client_code = app.client.toString().split('\n',1)[0]
#try
#    fs.mkdirSync os.path.join(scriptdir,'public')
client_code = script.client.toString()
if client_code.lastIndexOf("\n")>0
    client_code = client_code.substring(client_code.indexOf('\n')+1)
    if client_code.lastIndexOf("\n")>0
        client_code = client_code.substring(0, client_code.lastIndexOf('\n'))
    # TODO: cut livescript return statement from last line
    # TODO: cut 1 level of indentation
err <- fs.writeFile path.join(scriptdir,'client-pre.js'), client_code
if err
    console.log 'could not write client.js file'

#err, template <- async.eachLimit Object.keys(template), 1, (template,cb)->
#    console.log template
#    return cb void

#app = void
cfg = script.config
#if cfg
#    if cfg.base=='default'
#        express = require('express')

# generate views/templates dir
try
    fs.mkdirSync path.join(scriptdir,'views')
for template, content of script.views
    fs.writeFileSync path.join(scriptdir,'views',template), content

# generate static/public dir
try
    fs.mkdirSync path.join(scriptdir,'public')
for staticfile, content of script.public
    fs.writeFileSync path.join(scriptdir,'public', staticfile), content

# TODO: instead of requiring, should:
#   (if not in script dir) compile and copy singlefile.js to project and re-run from script dir using script's node_modules
#   (if in script dir) require and run

env =
    #NODE_PATH: path.join(scriptdir,'node_modules')
    SINGLEFILE: ext
#console.log env
# TODO quote fn
#e = process.argv.join(' ')+' -r'
#console.log e
# "cwd":scriptdir, 
# TODO: pipe output

# compile self and copy in
#console.log 'lsc -c ' + process.argv[2]
child_process.execSync 'lsc -c ' + argv[2]
repchar = (s, idx, r)-> s.substr(0, idx) + r + s.substr(idx + r.length)
singlefilejs = repchar(argv[2],argv[2].length-2,'j')
singlefilejs_path = path
err <- fs.rename singlefilejs, path.join(scriptdir,'wrapper.js')

p = []
p = Object.assign process.argv.slice(0)
#console.log typeof p[p.length-1]
#if typeof p[p.length-1] == 'undefined'
#p.pop()

# singlefile.ls -> singlefile.js
#p[p.length-2] = repchar(p[p.length-2], p[p.length-2].length-2, 'j')
p[p.length-2] = path.join(scriptdir,'wrapper.js')
#p[p.length-1] = JSON.stringify(p[p.length-1])
# remove lsc
p.splice(1,1)
ps = p.join(' ')
#console.log ps

#child = child_process.exec ps, {env:env}
#console.log ps
child = child_process.exec ps, {env:env}
child.stdout.on 'data', (data) ->
    console.log data
child.stderr.on 'data', (data) ->
    console.log data

#console.log err, out

