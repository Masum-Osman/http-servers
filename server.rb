require 'json'
require 'mysql2'
require 'webrick'

# MySQL connection settings
DB_HOST = 'localhost'
DB_USER = 'username'
DB_PASSWORD = 'password'
DB_NAME = 'dbname'

class UserHandler < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(request, response)
    if request.path == '/users'
      begin
        client = Mysql2::Client.new(host: DB_HOST, username: DB_USER, password: DB_PASSWORD, database: DB_NAME)

        query = 'SELECT * FROM users'
        results = client.query(query)

        users = []
        results.each do |row|
          user = { id: row['id'], username: row['username'], email: row['email'] }
          users << user
        end

        response.status = 200
        response['Content-Type'] = 'application/json'
        response.body = users.to_json

        client.close
      rescue Mysql2::Error => e
        puts "MySQL Error: #{e.message}"
        response.status = 500
        response['Content-Type'] = 'text/plain'
        response.body = '500 Internal Server Error'
      end
    else
      response.status = 404
      response['Content-Type'] = 'text/plain'
      response.body = '404 Not Found'
    end
  end
end

server = WEBrick::HTTPServer.new(Port: 8080)
server.mount '/users', UserHandler

trap('INT') { server.shutdown }

puts 'Server started on http://localhost:8080'
server.start
