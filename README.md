# singlefile

Create and run web apps using a single source file. 
Client, server, template/markup, and style code is embedded in just one file
This is great for prototyping small projects and demos.

I have plans to make this very flexible, such as having it work with different languages, stacks, and base configurations.

Scripts support a shebang line (except in the case of TypeScript), so you'll be able to simply execute the file and have all the necessary
temporary files generated when you run it.

**Currently supports**: JS, ES6, CoffeeScript, LiveScript

**Examples Included**: React.js, Electron

**Work-in-Progress**: TypeScript, Svelte

# Setup

To run the examples, run this command inside singlefile's dir:

```
sudo npm install -g
```

Then run one of our examples:

```
./examples/basic-example.ls
```

Now visit `localhost:3000` in a browser to see it in action.

# Usage

Create one file in its own folder.  This example will use livescript.

First, put a singlefile shebang line.  This allows file execution on Linux and Mac:

```ls
#!/usr/bin/singlefile
```

Now, let's make a "Hello World" page using pug and write a script line for client.js, which will be generated from
our client code inside this file:

```ls
export views =
    'index.pug': '''
        doctype html
        html(lang='en')
          head
            script(src='client.js')
          body
            p Hello World!
    '''
```

Still in the same file, let's write some client code, just to prove it works:

```ls
export client = ->
    console.log 'client'
```

Now let's write server code to serve our routes:
```ls
export server = (app)->
    app.get '/', (req,res) ->
        res.render 'index.pug'
    app.run()
```

We're done.  The client and server code can exist in the same file and are separated by singlefile.

Optionally, at the top of the file, you can inject a config for the boilerplate express server and npm package.json:

```ls
export config =
    port: 3000

export npm =
    name: 'singlefile-example'
    dependencies:
        example: '*'
```

Above we've also shown how to include a dependency such as you would in Node's package.json.  Our example
above doesn't use "example", but this is how you would include it.  The express dependencies required by the
boilerplate are automatically added, so you only need to add the dependencies you use in your own code.

Client-side require() of packages is also supported by using browserify invisibly in the background.

Keep in mind any functions that your client uses must be nested in or included from the client
function itself.  This allows separation.

Now that you know the anatomy of a singlefile app, run `./basic-example.ls` and open `localhost:3000` in your browser.

You should see "Hello World" and if you open the F12 developer console you'll see "client" which was printed by 
our client code.

You can also run singlefile apps by running:

```
./singlefile.ls ./my-app.js
```

or:

```
/path/to/livescript/lsc ./singlefile.ls ./my-app.js
```

Feel free to let me know if you find this useful or have any questions.  I am open to feature requests and pull requests.

## Features

- [x] Basic functionality (see basic example)
- [x] Add browserify to grunt steps to get client-side require()
- [ ] Allow setting path for custom compilers somehow (must be // or # comment on first/second line)
- [x] Selectable base for minimal boilerplate
- [ ] Expand default express base (SSL, etc.)
- [x] React support and example
- [ ] Live reloading when script file is modified
- [ ] Recursive subdirectories inside of views and public
- [x] Electron support

