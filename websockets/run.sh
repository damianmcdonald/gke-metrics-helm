
#!/bin/sh
npm install ws

cat << EOS > server.js
console.log("Server started");

var os = require("os");

var Msg = '';
var WebSocketServer = require('ws').Server
    , wss = new WebSocketServer({port: 8010});
    wss.on('connection', function(ws) {
        ws.on('message', function(message) {
        console.log('Received from client: %s', message);
        console.log('Pod hostname is: %s', os.hostname());
        ws.send('Client message: ' + message + ' on pod: ' + os.hostname());
    });
 });
EOS

node server.js
