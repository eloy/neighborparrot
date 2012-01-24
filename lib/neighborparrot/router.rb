# Router class
# Manage all incoming connections and map request

# Need override some default avoiding rack server /
module Rack
   class Static
     def can_serve(path)
       return false if path == "/"
       return true if path.index('/js') == 0
       return true if path.index('/tests') == 0
     end
   end
 end

class Router < Goliath::API

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
  post '/send'    ,SendRequestEndPoint

end
