const http = require("http");
const express = require("express");

const app = express();
const server = http.createServer(app);
const io = require("socket.io")(server, {
  cors: {
    origin: ["http://localhost:8100","http://localhost:3000"],
    methods: ["GET", "POST"],
    allowedHeaders: ["my-custom-header"],
    credentials: true,
  },
});
const { addUser, removeUser, getRoomUser } = require("./user");

const PORT = 5000;

io.on("connection", (socket) => {
  socket.on("join", ({ name, room,player }, callBack) => {
    let currentUsers = getRoomUser(room);
    const { user, error } = addUser({ id: socket.id, name, room,isHost:(currentUsers.length < 1) ,player});
    if (error) return callBack(error);

    socket.join(user.room);
    socket.emit("message", {
      user: "Admin",
      text: {content:`Welcome to ${user.room}`,type:"WELCOME",users:currentUsers},
    });

    socket.broadcast
      .to(user.room)
      .emit("message", { user: "Admin", text: {content:`${user.name} has joined!`,type:"PLAYER",action:"NEW" ,value:player } });
    callBack(null);


    socket.on("sendMessage", ({ message }) => {
      io.to(user.room).emit("message", {
        user: user.name,
        text: message,
      });
    });

  });
  socket.on("disconnect", () => {
    const user = removeUser(socket.id);
    console.log(user);
     if(user !== undefined){
       io.to(user.room).emit("message", {
         user: "Admin",
         text: {content:`${user.name} just left the room`,type:"CHAT"} ,
       });
       console.log("A disconnection has been made");
     }
  });
});

server.listen(PORT, () => console.log(`Server is Quannected to Port ${PORT}`));
