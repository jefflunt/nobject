require 'socket'

# this is the class that accepts instantiated objects in the main program, and
# then pushes them to a remote server
class ProxyNobject
  # host: the hostname of the server to push obj to
  # port: the port number of the server to push obj to
  # obj: the obj to store over the network
  def initialize(host, port, obj)
    @socket = TCPSocket.new(host, port)
    obj_bytes = Marshal.dump(obj)

    @socket.send([obj_bytes.length].pack('Q>'), 0)
    @socket.send(obj_bytes, 0)
  end

  def method_missing(method, args)
    raise NoMethodError.new("undefined method '#{method}' for #{self.class.name}") unless method.start_with?('n_')

    msg = { method: method, args: args }
    puts "proxy sending: #{msg}"
    msg_bytes = Marshal.dump(msg)

    @socket.send([msg_bytes.length].pack('Q>'), 0)
    @socket.send(msg_bytes, 0)

    return_size = @socket.recv(8).unpack('Q>').first
    return_data = Marshal.load(@socket.recv(return_size))
    puts "proxy receiving #{return_size} bytes >> #{return_data.inspect}"

    case return_data.first
    when :ok then return_data.last
    when :raise then raise return_data.last
    else
      raise ProxyNobject::UnknownReturnDataType.new("unknown data type '#{return_data.first}' within ProxyNobject (ProxyNobject::UnknownReturnDataType)")
    end
  end
end

class ProxyNobject::UnknownReturnDataType < RuntimeError; end
