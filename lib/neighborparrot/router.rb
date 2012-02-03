# Router class
# Manage all incoming connections and map request

# Need override some default avoiding rack server /
module Rack
   class Static
     def can_serve(path)
       return false if path == "/"
       return true if path.index('/js') == 0
       return true if path.index('/pf') == 0
       return true if path.index('/tests') == 0
     end
   end
 end

fiber_pool = FiberPool.new(600)
Goliath::Request.execute_block = proc do |&block|
  fiber_pool.spawn(&block)
end

class Router < Goliath::API

  def initialize
    EM.error_handler do |e|
      logger.info "Error raised during event loop: #{e.message}"
      logger.info e.backtrace.inspect
    end
  end

  # Don't serve static pages on production
  if Neighborparrot.devel?
    puts "Will serve static content. Make sure set production enviroment when deploy"
    use Rack::Static, :urls => ["/js", "/tests"], :root => Goliath::Application.app_path("/../../public")
  end

  if Neighborparrot.test?
    use Goliath::Rack::Tracer
  end

  def response(env)
    raise Goliath::Validation::NotFoundError
  end

  get '/'        ,StaticIndexEndPoint
  map '/open'    ,EventSourceEndPoint
  post '/send'   ,SendRequestEndPoint
  map '/ws'      ,WebSocketEndPoint

end

# For run a custom runner
# runner = Goliath::Runner.new(ARGV, nil)
# runner.api = Router.new
# runner.app = Goliath::Rack::Builder.build(Router, runner.api)
# runner.run
