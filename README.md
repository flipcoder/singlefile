# singlefile

This script allows you to create web apps using a single source file, where you create and run your app 
with client, server, template, and style code embedded in just one file.  This is great for small
projects and demos.

I have plans to make this very flexible, such as having it work with different languages, stacks, and base configurations.

Scripts support a shebang line, so you'll be able to simply execute the file and have all the necessary
temporary files generated when you run it.

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

Create one file in its own folder.  You can use either javascript or livescript (coffeescript support is still in the works).

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

Keep in mind any functions that your server and client use must be nested in or included from the client
and server function themselves.  This allows separation.

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
- [ ] Selectable base for minimal boilerplate
- [ ] Expand default express base (SSL, etc.)
- [ ] Support other CSS alternatives
- [ ] React support and example
- [ ] Different view engines in addition to pug (could even make it detectable)
- [ ] Live reloading when script file is modified
- [ ] Generated folder paths inside of views and public (grunt nodemon)
- [ ] Native app bases

