require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')

describe "Neighborparrot" do
  before :each do
    @key = 'test_key'
    @parrot = Neighborparrot.new(@key, "http://127.0.0.1:9000")
  end
  after :each do
    @parrot.close
  end

  it 'should allow clients to connect with valid credentials' do
    connected = false
    @parrot.on_connect do
      connected = true
    end

    @parrot.open('test')
    sleep(2)
    connected.should be_true
  end

  it 'should broadcast messges to a channel' do
    received = []
    @parrot.on_message do |msg|
      received.push msg
    end
    @parrot.open('test')
    sleep(2)
    @parrot.post('other', 'other')
    @parrot.post('test', 'message')
    sleep(1)
    received.length.should eq 1
    received.first.should eq 'message'
  end

  [32, 64, 128, 256, 512, 1024, 2048, 4096].each do |size|
    it "Should manage messages with size = #{size}" do
      message =  Array.new(size, ".").join
      received = nil
      @parrot.on_message do |msg|
        received = msg
      end
      @parrot.open('test')
      sleep(2)
      @parrot.post('test', message)
      sleep(1)
      received.should eq message
    end
  end


end
