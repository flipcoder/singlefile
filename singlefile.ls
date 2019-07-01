#!/usr/bin/lsc

argv = []
argv = Object.assign argv, process.argv.slice(0)

fs = require('fs')
#async = require('async')
path = require('path')

plugin = (script,name)->
    return true # TEMP

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

    if cfg.base == 'default' or cfg.base == 'express'
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

        if plugin(script,'pug')
            app.set 'view engine', 'pug'

        app.set 'views', __dirname + '/views/'

        if plugin(script,'stylus')
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
    else
        app = {}
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
    if ext != 'js'
        if ext in Object.keys(interpreters)
            libs = [interpreters[ext]].concat(libs)
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

        fs.writeFile path.join(scriptdir, 'package.json'), JSON.stringify(script.npm,null,4), {'flag':'w'}, (err,a)->
            if err
                console.log 'package.json (npm) failed'
                return cb err
            child_process.exec 'npm install', {cwd:scriptdir}, (err, stdout, stderr)->
                if stdout
                    console.log stdout
                if stderr
                    console.log stderr
                if err
                    console.log 'npm install failed'
                return cb err
        return
    else
        return cb void

run_yarn = (script,cb)->
    if script.yarn
        inject_libs(script.yarn)

        fs.writeFile path.join(scriptdir, 'package.json'), JSON.stringify(script.yarn,null,4), {'flag':'w'}, (err)->
            if err
                console.log 'package.json (yarn) failed'
                return cb err
            child_process.exec 'yarn', {cwd:scriptdir}, (err, stdout, stderr)->
                if stdout
                    console.log stdout
                if stderr
                    console.log stderr
                if err
                    console.log 'yarn failed'
                return cb err
        return
    else
        return cb void

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

        fs.writeFile path.join(scriptdir,'Gruntfile.js'), g, {'flag':'w'}, (err)->
            if err
                console.log 'gruntfile.js write failed'
                return cb err
            child_process.exec 'grunt', {cwd:scriptdir} (err, stdout, stderr)->
                if stdout
                    console.log stdout
                if stderr
                    console.log stderr
                if err
                    console.log 'grunt failed'
                return cb err
        return
    else
        return cb void

err <- run_yarn script
if err
    console.log err
    process.exit(1)

err <- run_npm script
if err
    console.log err
    process.exit(1)

# cut first and last line of client code (function wrapping)
#client_code = app.client.toString().split('\n',1)[0]
#try
#    fs.mkdirSync os.path.join(scriptdir,'public')
client_code = script.client.toString()
if client_code.lastIndexOf("\n")>0
    client_code = client_code.substring(client_code.indexOf('\n')+1)
    if client_code.lastIndexOf("\n")>0
        client_code = client_code.substring(0, client_code.lastIndexOf('\n'))
    last_nl = client_code.lastIndexOf("\n")
    if last_nl>0
        # TODO: cut livescript return statement from last line
        return_line = client_code.substring(last_nl+1)
        client_code = client_code.substring(0, last_nl)
        console.log return_line
        if return_line.indexOf('return ') >= 0
            return_line = return_line.substring(return_line.indexOf('return ')+'return '.length)
        client_code = client_code + '\n' + return_line
    # TODO: cut 1 level of indentation

err <- fs.writeFile path.join(scriptdir,'client-pre.js'), client_code, {'flag':'w'} # overwrite
if err
    console.log 'could not write client.js file'

err <- run_grunt script
if err
    console.log err
    process.exit(1)

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
    fs.writeFileSync path.join(scriptdir,'views',template), content, {'flag':'w'}

# generate static/public dir
try
    fs.mkdirSync path.join(scriptdir,'public')
for staticfile, content of script.public
    fs.writeFileSync path.join(scriptdir,'public', staticfile), content, {'flag':'w'}

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

wrapperls = path.join(scriptdir,'wrapper.ls')
exists <- fs.exists wrapperls
if exists
    console.log 'cannot build, wrapper.ls would be replaced'
    processs.exit(1)
err <- fs.copyFile argv[2], path.join(scriptdir,'wrapper.ls')
child_process.execSync 'lsc -c ' + path.join(scriptdir,'wrapper.ls')
err <- fs.unlink path.join(scriptdir,'wrapper.ls')
#repchar = (s, idx, r)-> s.substr(0, idx) + r + s.substr(idx + r.length)
#singlefilejs = repchar(argv[2],argv[2].length-2,'j')
#singlefilejs_path = path

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

