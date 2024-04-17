let users = [];

exports.addUser = ({ id, name, room , isHost, player }) => {
  if (!name || !room) return { error: "Username and room are required." };

  const user = { id, name, room, isHost,player };

  users.push(user);

  return { user };
};

exports.removeUser = (id) => {
  const index = users.findIndex((user) => user.id === id);
  return users[index];
};

exports.getRoomUser = (room) => {
  return  users.filter(function(user){ return user.room === room});
}
