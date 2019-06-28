exports.config = {
  port: 3000,
  base: 'default'
};
exports.npm = {
  name: 'singlefile-example',
  dependencies:
    express: "*",
    pug: "*",
    stylus: "*"
};

exports.views = { 'index.pug':`
doctype html
html(lang='en')
  head
    script(src='client.js')
  body
    p Hello World!
`};

exports.client = function(){
  console.log('client');
};
exports.server = function(app){
  app.get('/', function(req, res){
    return res.render('index.pug');
  });
  return app.run(function(){
    return console.log('server running');
  });
};
