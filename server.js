var _ = require('lodash');
var express = require('express');
var cors = require('cors');
var morgan = require('morgan')
var app = express();
var server = require('http').createServer()
var WebSocketServer = require('ws').Server
var wss = new WebSocketServer({ server: server })
var port = 1234;

app.use(cors());
app.use(morgan('dev'));

var db = {
  users: {
    0: { name: "Kirk", id: 0, color: "blue" },
    1: { name: "Yoni", id: 1, color: "blue" },
    2: { name: "Molly", id: 2, color: "purple" },
    3: { name: "Dan", id: 3, color: "orange" },
    4: { name: "Elise", id: 4, color: "brown" },
  },
  friends: {
    0: [1, 2, 3, 4],
    1: [0],
  },
};

app.get('/', function(req, res, next) {
  res.send('Hello World!')
})

app.get('/friends', function(req, res, next) {
  var loggedInUserId = req.query.loggedInUserId;
  if (!loggedInUserId) {
    return res.json(db.users);
  }
  var friendIdsOfLoggedInUser = _.get(db.friends, _.toNumber(loggedInUserId), []);
  var friendsOfLoggedInUser = _.filter(_.map(friendIdsOfLoggedInUser, (friendId) => {
    return db.users[friendId];
  }));
  return res.json(friendsOfLoggedInUser);
})

app.get('/user/:id', function(req, res, next) {
  var requestedUserId = req.params.id;
  if (!requestedUserId) {
    // throw error
    console.error('Missing requestedUserId');
    return;
  }
  var requestedUser = _.get(db.users, _.toNumber(requestedUserId));
  if (!requestedUser) {
    console.error(`User with id ${requestedUserId} not found`);
    return;
  }
  return res.json(requestedUser);
})

wss.on('connection', function connection(ws) {
  var location = url.parse(ws.upgradeReq.url, true);
  // you might use location.query.access_token to authenticate or share sessions
  // or ws.upgradeReq.headers.cookie (see http://stackoverflow.com/a/16395220/151312)

  ws.on('message', function incoming(message) {
    console.log('received: %s', message);
  });

  ws.send('something');
});

server.on('request', app);
server.listen(port, function () { console.log('Listening on ' + server.address().port) });
