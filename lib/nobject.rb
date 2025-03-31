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
        puts "Nobject got: #{msg.inspect}"

        network_return([
          :raise,
          NoMethodError.new("undefined method '#{method}' for an instance of #{self.class.name} (NoMethodError)")
        ]) unless msg[:method].to_s.start_with?('n_')

        local_method = msg[:method].to_s.sub(/\An_/, '')
        network_return([
          :raise,
          NoMethodError.new("undefined method '#{local_method}' for a network instance of #{@obj.class.name} (Nobject::NoMethodError)")
        ]) unless @obj.respond_to?(local_method)

        result = @obj.send(local_method, *msg[:args])
        puts "returning #{result}"
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
