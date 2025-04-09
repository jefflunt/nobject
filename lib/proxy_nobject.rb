require 'socket'

# this is the class that accepts instantiated objects in the main program, and
# then pushes them to a remote server
class ProxyNobject
  # host: the hostname of the server to push obj to
  # port: the port number of the server to push obj to
  # obj: the obj to store over the network
  #
  # ex:
  #   # this will create a new ProxyNobject, then put it to the specified server
  #   ProxyNobject.new('localhost', 1234, <object>)
  def initialize(host, port, obj)
    @socket = TCPSocket.new(host, port)
    obj_bytes = Marshal.dump(obj)

    @socket.send([obj_bytes.length].pack('Q>'), 0)
    @socket.send(obj_bytes, 0)
  end

  def method_missing(method, *args, **kwargs, &block)
    msg = { method: method, args: args }
    msg_bytes = Marshal.dump(msg)

    @socket.send([msg_bytes.length].pack('Q>'), 0)
    @socket.send(msg_bytes, 0)

    return_size = @socket.recv(8).unpack('Q>').first
    return_data = Marshal.load(@socket.recv(return_size))

    case return_data.first
    when :ok then return_data.last
    when :raise then raise return_data.last
    else
      raise ProxyNobject::UnknownReturnDataType.new("unknown data type '#{return_data.first}' within ProxyNobject (ProxyNobject::UnknownReturnDataType)")
    end
  end

  #####################################
  # method overridden from Object class
  #####################################
  def !~(other);      method_missing(:is_a?, other);  end
  def <=>(other);     method_missing(:<=>, other);    end
  def ===(other);     method_missing(:<=>, other);    end
  def is_a?(klass);   method_missing(:is_a?, klass);  end
  def inspect;        method_missing(:inspect);       end
  def object_id;      method_missing(:object_id);     end
end

class ProxyNobject::UnknownReturnDataType < RuntimeError; end
class ProxyNobject::InvalidMethod < RuntimeError; end
