module Nobject
  # this class is used by the Nobject::Server to receive objects pushed to the
  # Nobject::Server, listens for method invocations over the network, and sends
  # the method invocations onwards to this object
  class Remote
    def initialize(socket)
      @msg_counter = 0
      @socket = socket
      obj_size = @socket.recv(8).unpack('Q>').first
      File.open('/tmp/nobject.log', 'a') {|f| f.puts "R:##{@msg_counter += 1} sz#{obj_size}"; f.flush }
      @obj = Marshal.load(@socket.recv(obj_size))
    end

    def serve!
      Thread.new do
        loop do
          msg_size = @socket.recv(8).unpack('Q>').first
          File.open('/tmp/nobject.log', 'a') {|f| f.puts "  RMR:##{@msg_counter += 1} sz#{msg_size}"; f.flush }
          msg = Marshal.load(@socket.recv(msg_size))

          result = @obj.send(msg[:method], *msg[:args])
          network_return([
            :ok,
            result
          ])
        end
      end
    end

    def network_return(data)
      data_bytes = Marshal.dump(data)

      @socket.send([data_bytes.length].pack('Q>'), 0)
      File.open('/tmp/nobject.log', 'a') {|f| f.puts "    RMResult:##{@msg_counter += 1} sz#{data_bytes.length}"; f.flush }
      @socket.send(data_bytes, 0)
    end
  end

  class Nobject::NoMethodError < NameError; end
end
