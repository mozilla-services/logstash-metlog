require 'socket'
host = 'localhost'
port = 1234
s = UDPSocket.new
s.send("1", 0, host, port)
5.times do
    s.send('this is a test\n', 0, host, port)
end
