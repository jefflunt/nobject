require 'socket'

# this class wraps a local object, listens for method invocations over the
# network, and sends the method invocations onwards to the local object.
class Nobject
  def initialize(socket)
    @socket = socket
    obj_size = @socket.recv(8).unpack('Q>').first
    @obj = Marshal.load(@socket.recv(obj_size))
  end

  def serve!
    Thread.new do
      loop do
        msg_size = @socket.recv(8).unpack('Q>').first
        msg = Marshal.load(@socket.recv(msg_size))

        result = @obj.send(msg[:method], *msg[:args]) #local_method, *msg[:args])
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
    @socket.send(data_bytes, 0)
  end
end

class Nobject::NoMethodError < NameError; end
