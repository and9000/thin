require 'spec_helper'

require 'timeout'

describe Server, "stopping" do
  before do
    start_server do |env|
      [200, { 'content-type' => 'text/html' }, ['ok']]
    end
    @done = false
  end
  
  it "should wait for current requests before soft stopping" do
    socket = TCPSocket.new('0.0.0.0', 3333)
    socket.write("GET / HTTP/1.1")
    EventMachine.next_tick do
      @server.stop # Stop the server in the middle of a request
      socket.write("\r\n\r\n")
      @done = true
    end
    
    Timeout.timeout(2) do
      Thread.pass until @done
    end
    
    out = socket.read
    socket.close
    
    expect(out).not_to be_empty
  end
  
  it "should not accept new requests when soft stopping" do
    socket = TCPSocket.new('0.0.0.0', 3333)
    socket.write("GET / HTTP/1.1")
    @server.stop # Stop the server in the middle of a request
    
    EventMachine.next_tick do
      expect { get('/') }.to raise_error(Errno::ECONNRESET)
    end
    
    socket.close
  end
  
  it "should drop current requests when hard stopping" do
    socket = TCPSocket.new('0.0.0.0', 3333)
    socket.write("GET / HTTP/1.1")
    @server.stop! # Force stop the server in the middle of a request
    
    EventMachine.next_tick do
      expect(socket).to be_closed
    end
  end
  
  after do
    stop_server
  end
end