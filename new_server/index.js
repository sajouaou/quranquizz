const { WebSocketServer } = require("ws")
const http = require("http")
const uuidv4 = require("uuid").v4
const url = require("url")

const server = http.createServer()
const wsServer = new WebSocketServer({ server })

const port = 5000
const host = "0.0.0.0";
const connections = {}
const users = {}
const rooms = {}

const handleMessage = (bytes, uuid,room) => {
  console.log(bytes);
  const message = JSON.parse(bytes.toString())
  const user = users[uuid]
  user.state = message
  broadcast()

  console.log(
    `${user.username} updated their updated state: ${JSON.stringify(
      user.state,
    )}`,
  )
}

const handleClose = (uuid,room) => {
  console.log(`${users[uuid].username} disconnected`)
  delete connections[uuid]
  delete users[uuid]
  broadcast()
}

const broadcast = () => {
  Object.keys(connections).forEach((uuid) => {
    const connection = connections[uuid]
    const message = JSON.stringify(users)
    connection.send(message)
  })
}

wsServer.on("connection", (connection, request) => {
  const { username,room } = url.parse(request.url, true).query
  console.log(`${username} connected`)
  const uuid = uuidv4()
  connections[uuid] = connection
  console.log(rooms[room]);
  if(typeof rooms[room] === 'undefined') { //Create room
    rooms[room] = {
        users: [{username,uuid}],
        host: uuid
    }
    console.log(`${username} create room ${room}`);
  }
  else { // Join room
    rooms[room].users.push({username,uuid});
    console.log(`${username} join room ${room}`);
  }
  users[uuid] = {
    username,
    state: {},
  }
  connection.on("message", (message) => handleMessage(message, uuid,room))
  connection.on("close", () => handleClose(uuid,room))
})

server.listen(port,host, () => {
  console.log(`WebSocket server is running on port ${port}`)
})