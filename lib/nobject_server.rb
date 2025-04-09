require 'socket'
require_relative './nobject'

##
# this class listens for incoming requests to store an object over the network,
# accepts connections and then hands those sockets off to server object storage
# and invocation.
#
# ex:
#   NobjectServer.new(1234).start!
class NobjectServer
  def initialize(port)
    @server = TCPServer.new(port)
    @keep_running = true
    @nobjects = []
  end

  def alive?
    @keep_running
  end

  def start!
    loop do
      break unless @keep_running

      begin
        incoming_socket = @server.accept_nonblock
        Nobject.new(incoming_socket).serve!
      rescue IO::EAGAINWaitReadable => e
        # no connection pending
        begin
          IO.select([@server])
          retry
        rescue Interrupt, IRB::Abort
          @keep_running = false
          @server&.close
        end
      end
    end
  end

  def stop!
    @keep_running = false
  end
end
