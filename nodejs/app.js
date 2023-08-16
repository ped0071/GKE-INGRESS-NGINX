const http = require('http');
const os = require('os');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.write('Hello World\n');
  res.write(`Version: 0.1\n`);
  res.write(`Hostname: ${os.hostname()}\n`);
  res.end();
});

const port = 8080;
server.listen(port, () => {
  console.log(`Server running on port ${port}`);
});