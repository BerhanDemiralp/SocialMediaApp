// Simple Socket.io manual test script for Task 8.4
// Usage (PowerShell):
//   $env:TOKEN = "<access_token_from_login>"
//   node scripts/test-socket.js

const { io } = require('socket.io-client');

const token = process.env.TOKEN;

if (!token) {
  // eslint-disable-next-line no-console
  console.error('TOKEN env var is required. Set it to your Supabase access token.');
  process.exit(1);
}

const socket = io('http://localhost:3000', {
  auth: { token },
});

socket.on('connect', () => {
  // eslint-disable-next-line no-console
  console.log('Connected to Socket.io server, id =', socket.id);
  // eslint-disable-next-line no-console
  console.log('Emitting joinMatch / sendMessage / typing...');

  const matchId = 'test-match-1';

  // Join room
  socket.emit('joinMatch', { matchId }, (response) => {
    // eslint-disable-next-line no-console
    console.log('joinMatch response:', response);
    if (!response || response.event !== 'joined') {
      console.error('joinMatch did not succeed, skipping sendMessage/typing');
      return;
    }

    // Defer sending a message slightly so that the room join completes.
    setTimeout(() => {
      // Send a test message
      socket.emit(
        'sendMessage',
        { matchId, content: 'Hello from test script' },
        (resp) => {
          // eslint-disable-next-line no-console
          console.log('sendMessage ack:', resp);
        },
      );

      // Typing indicator
      socket.emit(
        'typing',
        { matchId, isTyping: true },
        (resp) => {
          // eslint-disable-next-line no-console
          console.log('typing ack:', resp);
        },
      );
    }, 300);
  });
});

socket.on('connect_error', (err) => {
  // eslint-disable-next-line no-console
  console.error('connect_error:', err.message);
});

// NestJS WebSocket exceptions (e.g., guards) are emitted on 'exception'
socket.on('exception', (err) => {
  // eslint-disable-next-line no-console
  console.error('exception event from server:', err);
});

socket.on('newMessage', (msg) => {
  // eslint-disable-next-line no-console
  console.log('newMessage event:', msg);
});

socket.on('userTyping', (data) => {
  // eslint-disable-next-line no-console
  console.log('userTyping event:', data);
});

socket.on('disconnect', (reason) => {
  // eslint-disable-next-line no-console
  console.log('Disconnected:', reason);
});
