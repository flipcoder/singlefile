exports.config = {
    port: 3000,
    base: 'default'
};
exports.npm = {
    name: 'singlefile-es6-example'
};

exports.views = { 'index.pug':`
    doctype html
    html(lang='en')
        head
            script(src='client.js')
        body
            p Hello World!
`};

exports.client = async () => {
    class ES6Class {
        constructor() {
            console.log('client');
        }
    }
    new ES6Class();
};
exports.server = async (app) => {
    app.get('/', function(req, res){
        res.render('index.pug');
    });
    await app.run();
    console.log('server running');
};
