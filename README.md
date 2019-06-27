# singlefile

This project is working, but it is unfinished.

This script allows you to create single-file web apps, where you create and run your app 
with client, server, and template code embedded in just one file.  This is great for small
projects and demos.

Look at the examples/ folder to see how it can be used.

I have plans to make this very flexible, such as having it work with different languages, stacks, and base configurations.

Scripts support a shebang line, so you'll be able to simply execute the file and have all the necessary
temporary files generated when you run it.

## Features

[x] Basic functionality (see basic example)
[ ] Add browserify to grunt steps to get client-side require()
[ ] Allow setting path for custom compilers somehow (must be // or # comment on first/second line)
[ ] Selectable base for minimal boilerplate
[ ] Expand default express base (SSL, etc.)
[ ] Support other CSS alternatives
[ ] React support and example
[ ] Different view engines in addition to pug (could even make it detectable)
[ ] Live reloading when script file is modified
[ ] Generated folder paths inside of views and public (grunt nodemon)
[ ] Show npm, yarn, and grunt output if -v (verbose)
[ ] Native app bases

