require 'erb'

class StaticIndexEndPoint < Goliath::API
#  use ExceptionHandler

  @@template_cache = {}

  def response(env)
    @env = env
    [200, {}, index_template]
  end

  def index_template
    prepare_env
    hash = @env['REQUEST_URI']
    unless @@template_cache[hash]
      @@template_cache[hash] = parse_template
    end
    return @@template_cache[hash]
  end

  # Get and check parameters
  def prepare_env
    @service = @env.params['service']
    raise Goliath::Validation::BadRequestError.new("service is mandatory") if @service.nil?
    raise Goliath::Validation::BadRequestError.new("invalid service") unless Neighborparrot::SERVICES.include? @service
    @use_polyfill = @env.params['use_polyfill'] == 'true'
    @template_env = TemplateEnv.new
    @template_env.server_url = @env.config[:server_url] || Neighborparrot::SERVER_URL
    @template_env.assets_url = @env.config[:assets_url] || Neighborparrot::ASSETS_URL
    @template_env.use_polyfill = @use_polyfill
  end


  # Read the templete from disk and parseit
  def parse_template
    file = @service == 'es' ? Neighborparrot::ES_INDEX : Neighborparrot::WS_INDEX
    content = File.open(file).read
    template = ERB.new(content)
    template.result(@template_env.get_binding)
  end

  def clear_cache
    @@template_cache = {}
  end

#  private
  class TemplateEnv
    attr_accessor :use_polyfill, :server_url, :assets_url
    def get_binding
      binding
    end
  end
end
