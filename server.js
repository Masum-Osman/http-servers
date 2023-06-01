const http = require('http');
const mysql = require('mysql');

const connection = mysql.createConnection({
  host: 'localhost',
  user: 'username',
  password: 'password',
  database: 'dbname',
});

connection.connect((err) => {
  if (err) {
    console.error('MySQL connection error:', err);
    return;
  }
  console.log('Connected to MySQL database');
});

const server = http.createServer((req, res) => {
  if (req.url === '/users' && req.method === 'GET') {
    connection.query('SELECT * FROM users', (err, results) => {
      if (err) {
        console.error('MySQL query error:', err);
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('500 Internal Server Error');
        return;
      }
      const users = results.map((row) => ({
        id: row.id,
        username: row.username,
        email: row.email,
      }));
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(users));
    });
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('404 Not Found');
  }
});

const PORT = 8080;
server.listen(PORT, () => {
  console.log(`Server started on http://localhost:${PORT}`);
});
