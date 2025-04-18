require 'socket'

module Nobject
  # this class is used by the client application, wraps a local object, pushes
  # it to a Nobject::Serve4r, which will then  send method calls to a matching
  # Nobject::Remote object
  class Local
    # host: the hostname of the server to push obj to
    # port: the port number of the server to push obj to
    # obj: the obj to store over the network
    #
    # ex:
    #   # this will create a new Nobject::Local, then push it to the specified
    #   server Nobject::Local.new('localhost', 1234, <object>)
    def initialize(host, port, obj)
      @msg_counter = 0
      @socket = TCPSocket.new(host, port)
      obj_bytes = Marshal.dump(obj)

      File.open('/tmp/nobject.log', 'a') {|f| f.puts "L:##{@msg_counter += 1} sz#{obj_bytes.length}"; f.flush }
      @socket.send([obj_bytes.length].pack('Q>'), 0)
      @socket.send(obj_bytes, 0)
      @socket.flush
    end

    def method_missing(method, *args, **kwargs, &block)
      msg = { method: method, args: args }
      msg_bytes = Marshal.dump(msg)

      begin
        @socket.send([msg_bytes.length].pack('Q>'), 0)
        File.open('/tmp/nobject.log', 'a') {|f| f.puts "  LMS:##{@msg_counter += 1} sz#{msg_bytes.length} m:#{method}"; f.flush }
        @socket.send(msg_bytes, 0)
        @socket.flush
      rescue Exception
        raise Local::MethodRequestFailure.new("did not receive response from call to `#{method}' over the network")
      end

      return_data = begin
                      msg_size = @socket.recv(8).unpack('Q>').first
                      File.open('/tmp/nobject.log', 'a') {|f| f.puts "    LMGotit :##{@msg_counter += 1} sz#{msg_size} m:#{method}"; f.flush }
                      raw_bytes = @socket.recv(msg_size)
                      Marshal.load(raw_bytes)
                    rescue Exception => e
                      error_msg = <<~MSG
                        did not receive response from call to `#{method}' over the network
                        would have been msg_id #{@msg_counter} OR #{@msg_counter + 1} when trying to receive #{msg_size} bytes
                        caused by #{e.class.name}
                          exception backtrace:
                          #{e.backtrace.join("\n    ")}
                      MSG
                      raise Local::MethodResponseFailure.new(error_msg)
                    end

      case return_data.first
      when :ok then return_data.last
      when :raise then raise return_data.last
      else
        raise Local::UnknownReturnDataType.new("unknown data type '#{return_data.first}' within Nobject::Local (Nobject::Local::UnknownReturnDataType)")
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
    def to_s;           method_missing(:to_s);          end
  end

  class Local::UnknownReturnDataType < RuntimeError; end
  class Local::InvalidMethod < RuntimeError; end
  class Local::MethodRequestFailure < RuntimeError; end
  class Local::MethodResponseFailure < RuntimeError; end
end
