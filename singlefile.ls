#!/usr/bin/lsc

argv = []
argv = Object.assign argv, process.argv.slice(0)

_ = require('lodash')
fs = require('fs')
{promisify} = require('util')
#async = require('async')
path = require('path')

plugin = (script, name)->
    if !!script.config
        if !!script.config.stack
            return name in script.config.stack
        else
            if name in ['pug','stylus'] # defaults
                return true
    return false

interpreters =
    #js: 'node' # javascript
    ts: 'ts-node' # typescript
    coffee: 'coffeescript'
    ls: 'livescript'

launchers =
    node: 'node'
    electron: 'electron'

# client side libs to inject into script's generated package.json
client_libs = [
    'express',
    'grunt',
    'grunt-browserify',
    'body-parser',
    'method-override',
]

plugin_libs = {
    'pug': ['pug'],
    'stylus': ['stylus', 'nib'],
    'electron': ['electron']
    'session': ['express-session']
}

if process.env.SINGLEFILE # launching wrapper
    # include interpreter since we're generating singlefile.js and we need script require()s

    interpreter = void
    if process.env.SINGLEFILE == 'coffee'
        require('coffeescript').register()
    else if process.env.SINGLEFILE == 'ts'
        require('typescript-require')
    else if process.env.SINGLEFILE != 'js'
        interpreter = require(interpreters[process.env.SINGLEFILE])

    fn = path.resolve(process.env.SINGLEFILE_SCRIPT)
    scriptdir = path.dirname(fn)
    script = require(fn)
    cfg = script.config
    if cfg.stack or cfg.stack == ''
        cfg.stack = cfg.stack.split(' ')

    if not cfg.base or cfg.base == 'default' or cfg.base == 'express'
        express = require('express')
        if plugin(script,'session')
            session = require('express-session')
        if plugin(script,'stylus')
            stylus = require('stylus')
            nib = require('nib')
        if plugin(script,'pug')
            pug = require('pug')
        http = require('http')
        bodyParser = require('body-parser')
        methodOverride = require('method-override')
        
        app = express()
        
        env = process.env.NODE_ENV || 'development'
        if process.env.NODE_ENV=='development'
            app.locals.pretty = true
        
        app.use(methodOverride())
        app.use(bodyParser.urlencoded({ extended: true }))
        app.use(bodyParser.json())
        if cfg.store
            session['store'] = cfg.store
        if cfg.secret
            session['secret'] = cfg.secret
        if plugin(script,'session')
            sessionConfig =
                resave: false
                saveUninitialized: true
            app.use session sessionConfig

        if plugin(script,'pug')
            app.set 'view engine', 'pug'

        app.set 'views', __dirname + '/views/'

        if plugin(script,'stylus')
            compile = (str, p) ->
                return stylus(str)
                    .set('filename', p)
                    .use(nib())
            app.use stylus.middleware do
                src: __dirname + '/views/'
                dest: __dirname + '/public/'
                serve: true
                compress: true
                warn: true
                compile: compile

        app.use(express.static('public'))
        app.run = (cb)->>
            httpServer = http.createServer app
            
            if env=='development'
                httpServer.on 'uncaughtException', (req,res,route,err) ->
                    console.log err
                    if !res.headersSent
                        return res.send(500, {ok:false})
                    res.write '\n'
                    res.end()
            
            httpServer.listen cfg.port || 3000, ->
                cb void, httpServer
    else if cfg.base == 'electron'
        app = require('electron')
    else
        app = {}
    if script.server.constructor.name == 'AsyncFunction'
        app.run = promisify(app.run)
        script.server(app)
    else
        script.server(app)
    return

child_process = require('child_process')

#if argv[0].endsWith 'electron'
#    argv.shift()
if argv[0].endsWith 'node'
    argv.shift()
if argv[0].endsWith 'lsc'
    argv.shift()
if argv[0].endsWith 'coffee'
    argv.shift()

if argv.length <= 1
    console.log 'singlefile <file>'
    return

fn = path.resolve(argv[1])
cwd = process.cwd()

# TODO: check first/second line of script for compiler

compilers =
    #js: 'node' # javascript
    coffee: 'coffee -c' # coffeescript
    ls: 'lsc -c' # livescript

scriptfn = path.basename(argv[1])
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
if ext == 'coffee'
    require('coffeescript').register()
else if ext == 'ts'
    require('typescript-require')
script = require(fn)
if !script.config
    script.config = {}

# if they're missing, inject singlefile wrapper dependencies into script's package.json
inject_libs = (pkg)->
    libs = client_libs.slice()
    if ext != 'js'
        if ext in Object.keys(interpreters)
            libs = [interpreters[ext]].concat(libs)
    if not ('dependencies' in Object.keys(pkg))
        pkg.dependencies = {}
    for lib in libs
        if not (lib in Object.keys(pkg.dependencies))
            pkg.dependencies[lib] = '*'

    if script.config.stack
        script.config.stack = script.config.stack.split(' ')
    else
        script.config.stack = ['pug', 'stylus']

    plugin_lib_keys = Object.keys(plugin_libs)
    #console.log plugin_libs
    for stacklib in script.config.stack
        if stacklib in plugin_lib_keys
            for stackpkg in plugin_libs[stacklib]
                pkg.dependencies[stackpkg] = '*'
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
                    src: ['client-pre-browserify.js'],
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
            
            grunt_cmd = path.join(path.dirname(argv[0]),'node_modules','grunt','bin','grunt')
            if not fs.existsSync grunt_cmd
                grunt_cmd = 'grunt'
            
            child_process.exec grunt_cmd, {cwd:scriptdir} (err, stdout, stderr)->
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

# electron base
if script.config.base == 'electron'
    script.config.stack = 'pug stylus electron'
    pak = void
    if script.npm
        pak = script.npm
    else if script.yarn
        pak = script.yarn
    if pak
        pak.main = 'wrapper.js'
        if !pak.scripts
            pak.scripts = {}
        pak.scripts['start'] = 'electron .'

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
if script.client?
    client_code = script.client.toString()
    if client_code.lastIndexOf("\n")>0
        client_code = client_code.substring(client_code.indexOf('\n')+1)
        if client_code.lastIndexOf("\n")>0
            client_code = client_code.substring(0, client_code.lastIndexOf('\n'))
        last_nl = client_code.lastIndexOf("\n")
        #if last_nl>=0
        # TODO: cut livescript return statement from last line
        return_line = client_code.substring(last_nl+1)
        client_code = client_code.substring(0, Math.max(last_nl,0))
        if return_line.indexOf('return ') >= 0
            return_line = return_line.substring(return_line.indexOf('return ')+'return '.length)
        client_code = client_code + '\n' + return_line
        # TODO: cut 1 level of indentation
else
    client_code = ''

err <- fs.writeFile path.join(scriptdir,'client-pre-babel.js'), client_code, {'flag':'w'} # overwrite
if err
    console.log 'could not write client.js file'

#console.log path.join(path.dirname(argv[0]),'node_modules','babel-cli','bin','babel.js') +
#    '  ' + path.join(scriptdir,'client-pre-babel.js') + ' --outname ' + path.join(scriptdir,'client-pre-browserify.js')



# local babel?
exists = fs.existsSync path.join(path.dirname(argv[0]),'node_modules','babel-cli','bin','babel.js')

if exists
    # use local babel
    child_process.execSync path.join(path.dirname(argv[0]),'node_modules','babel-cli','bin','babel.js') +
        '  ' + path.join(scriptdir,'client-pre-babel.js') + ' --out-file ' + path.join(scriptdir,'client-pre-browserify.js')
else
    # use global babel
    child_process.execSync 'babel ' + '  ' + path.join(scriptdir,'client-pre-babel.js') +
        ' --out-file ' + path.join(scriptdir,'client-pre-browserify.js')

if err
    console.log err
    process.exit(1)

err <- run_grunt script
if err
    console.log err
    process.exit(1)

err <- fs.unlink path.join(scriptdir,'client-pre-browserify.js')
err <- fs.unlink path.join(scriptdir,'client-pre-babel.js')

#err, template <- async.eachLimit Object.keys(template), 1, (template,cb)->
#    console.log template
#    return cb void

#app = void
#if cfg.stack or cfg.stack == ''
#    cfg.stack = cfg.stack.split(' ')
#if cfg
#    if cfg.base=='default'
#        express = require('express')

# generate views/templates dir
dedent= require('dentist').dedent

try
    fs.mkdirSync path.join(scriptdir,'views')
for template, content of script.views
    fs.writeFileSync path.join(scriptdir,'views',template), dedent(content), {'flag':'w'}

# generate static/public dir
try
    fs.mkdirSync path.join(scriptdir,'public')
for staticfile, content of script.pub
    fs.writeFileSync path.join(scriptdir,'public', staticfile), dedent(content), {'flag':'w'}

env =
    #NODE_PATH: path.join(scriptdir,'node_modules')
    SINGLEFILE: ext
    SINGLEFILE_SCRIPT: argv[argv.length-1]

_.extend env, process.env

wrapperls = path.join(scriptdir,'wrapper.ls')
exists = fs.existsSync wrapperls
if exists
    console.log 'cannot build, wrapper.ls would be replaced'
    process.exit(1)
err <- fs.copyFile argv[0], path.join(scriptdir,'wrapper.ls')
child_process.execSync 'lsc -c ' + path.join(scriptdir,'wrapper.ls')
err <- fs.unlink path.join(scriptdir,'wrapper.ls')
#repchar = (s, idx, r)-> s.substr(0, idx) + r + s.substr(idx + r.length)
#singlefile = argv[0]
#singlefilejs = repchar(argv[0],argv[0].length-2,'j')
#singlefilejs_path = path

launcher = script.config.launcher || 'node'

if script.config.base == 'electron' or launcher == 'electron'
    launcher = 'electron'
    #console.log 'electron'
    #p = ['electron',path.join(scriptdir,'wrapper.js'),argv[argv.length-1]]
    #child_process.exec('electron wrapper.js '+argv[argv.length-1]).unref()
    #process.exit()
    #console.log argv[argv.length-1]
    p = [launcher,path.join(scriptdir,'wrapper.js'),argv[argv.length-1]]
else
    p = [launcher,path.join(scriptdir,'wrapper.js'),argv[argv.length-1]]
ps = p.join(' ')

#child = child_process.exec ps, {env:env}
if launcher=='electron'
    child = child_process.execSync ps, {env:env}
else
    child = child_process.exec ps, {env:env}
    child.stdout.on 'data', (data) ->
        console.log data
    child.stderr.on 'data', (data) ->
        console.log data

