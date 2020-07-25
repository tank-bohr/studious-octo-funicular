#!/usr/bin/env ruby
require 'pp'
require 'socket'

socket = Socket.new(:INET, :STREAM)
socket.setsockopt(:SOCKET, :REUSEADDR, true)
sockaddr = Socket.pack_sockaddr_in(2200, '127.0.0.1')
socket.bind(sockaddr)
socket.listen(_backlog = 3)

run = true
clients = []
to_read, to_write = IO.pipe
Signal.trap('TERM') { to_write.puts 'TERM' }

while run do
  ready_to_read, _ready_to_write, _errors = select([to_read, socket] + clients, [], [])
  if ready_to_read.nil?
    puts 'beat'
    next
  end
  ready_to_read.each do |io|
    if io == to_read
      signal = to_read.gets.chomp
      run = false if signal == 'TERM'
    elsif io == socket
      client_socket, _client_addrinfo = socket.accept
      clients << client_socket
    else
      begin
        input = io.read_nonblock(4096)
        io.puts "#{input.chomp.reverse}"
      rescue Errno::ECONNRESET
        clients.delete(io)
      end
    end
  end
end
