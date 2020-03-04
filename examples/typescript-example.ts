export var config = {
    port: 3000,
    base: 'default'
};

export var npm = {
    name: 'singlefile-example'
};

export var views = {
    'index.pug': `
        doctype html
        html(lang='en')
          head
            script(src='client.js')
          body
            p Hello World!
    `
};

export function client() {
    console.log('client');
};

export function server(app) {
    app.get('/', function(req,res) {
        res.render('index.pug');
    });

    app.run(() => {
        console.log('server running');
    });
};

