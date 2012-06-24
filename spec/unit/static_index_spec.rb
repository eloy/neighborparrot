require 'spec_helper'
require 'neighborparrot'

class StaticIndexEndPoint
  attr_accessor :service, :env, :use_polyfill, :template_env

  def get_template_cache
    @@template_cache
  end

  def fake_template_cache(cache)
    @@template_cache = cache
  end
end

describe StaticIndexEndPoint do

  # index_template parse
  #-----------------------------------------------

  describe 'index_template' do
    before :each do
      @s = StaticIndexEndPoint.new
      @s.clear_cache
      @s.stub(:prepare_env)
      @s.stub(:parse_template) { 'test-template'}
    end

    it 'should call prepare_env' do
      @s.should_receive(:prepare_env)
      @s.env =  { 'REQUEST_URI' => '/?service=es' }
      @s.index_template
    end

    it 'should call parse template if hash is not in cache' do
      @s.should_receive(:parse_template)
      @s.env =  { 'REQUEST_URI' => '/?service=es' }
      @s.index_template.should eq 'test-template'
    end

    it 'should the template from cache if present' do
      @s.env =  { 'REQUEST_URI' => '/?service=es' }
      @s.fake_template_cache({'/?service=es' => 'test-html'})
      @s.should_not_receive(:parse_template)
      @s.index_template.should eq 'test-html'
    end
  end

  # clear_cache
  #-----------------------------------------------

  describe 'clear_cache' do
    it 'should reset @@template_cache' do
      @s = StaticIndexEndPoint.new
      @s.fake_template_cache({ 'a' => 'b'})
      @s.clear_cache
      @s.get_template_cache.empty?.should be_true
    end
  end


  # prepare_env
  #-----------------------------------------------

  describe 'prepare_env' do
    before :each do
      @s = StaticIndexEndPoint.new
      @s.env = double('env').as_null_object
    end

    it 'should fail if no service' do
      @s.env.stub(:params) {}
      expect { @s.prepare_env }.should raise_error
    end
    it 'should fail if invalid service' do
      @s.env.stub(:params) { { 'service' => 'invalid' }}
      expect { @s.prepare_env }.should raise_error
    end

    it 'should set use_polyfill to false  if not configured' do
      @s.env.stub(:params) { { 'service' => 'es' }}
      @s.env.stub(:config) { {:server_url => nil, :assets_path => nil } }
      @s.prepare_env
      @s.use_polyfill.should be_false
    end

    it 'should set use_polyfill to true if configured' do
      @s.env.stub(:params) { { 'service' => 'es', 'use_polyfill' => 'true' }}
      @s.env.stub(:config) { {:server_url => nil, :assets_path => nil } }
      @s.prepare_env
      @s.use_polyfill.should be_true
    end

    it 'should create a template_env' do
      @s.env.stub(:params) { { 'service' => 'es' }}
      @s.env.stub(:config) { {:server_url => nil, :assets_path => nil } }
      @s.prepare_env
      @s.template_env.should_not be_nil
    end

    it 'should use default server if not configured' do
      @s.env.stub(:params) { { 'service' => 'es' }}
      @s.env.stub(:config) {{ }}
      @s.prepare_env
      @s.template_env.server_url.should eq Neighborparrot::SERVER_URL
    end

    it 'should use custom server if configured' do
      @s.env.stub(:params) { { 'service' => 'es' }}
      @s.env.stub(:config) {{ :server_url => 'http://test.server' }}
      @s.prepare_env
      @s.template_env.server_url.should eq 'http://test.server'
    end

    it 'should use default asset path if not configured' do
      @s.env.stub(:params) { { 'service' => 'es' }}
      @s.env.stub(:config) {{ }}
      @s.prepare_env
      @s.template_env.assets_url.should eq Neighborparrot::ASSETS_URL
    end

    it 'should use custom asset url if configured' do
      @s.env.stub(:params) { { 'service' => 'es' }}
      @s.env.stub(:config) {{ :assets_url =>  'http://test.server'}}
      @s.prepare_env
      @s.template_env.assets_url.should eq 'http://test.server'
    end
  end

  # parse index template
  #-----------------------------------------------

  describe 'parse_template' do
    before :each do
      @s = StaticIndexEndPoint.new
      @s.env = double('env').as_null_object
    end

    it 'should return the websocket template if service is ws' do
      @s.service = 'ws'
      @s.template_env = StaticIndexEndPoint::TemplateEnv.new
      @s.parse_template.should match 'Web Socket service'
    end

    it 'should return the websocket polyfill if service is ws and use_polyfill true' do
      template_env = StaticIndexEndPoint::TemplateEnv.new
      template_env.use_polyfill = true
      @s.service = 'ws'
      @s.template_env = template_env
      @s.parse_template.should match 'web_socket.js'
    end

    it 'should return the event source template if service is es' do
      template_env = StaticIndexEndPoint::TemplateEnv.new
      @s.service = 'es'
      @s.template_env = StaticIndexEndPoint::TemplateEnv.new
      @s.parse_template.should match 'Event Source service'
    end

    it 'should return the eventsource polyfill if service is es and use_polyfill true' do
      template_env = StaticIndexEndPoint::TemplateEnv.new
      template_env.use_polyfill = true
      @s.service = 'es'
      @s.template_env = template_env
      @s.parse_template.should match 'eventsource.js'
    end
  end
end
