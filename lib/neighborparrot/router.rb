class Router < Goliath::API

  def response(env)
    raise Goliath::Validation::NotFoundError
  end

  get '/'        ,StaticIndexEndPoint
  map '/open'    ,EventSourceEndPoint
  post '/send'    ,SendRequestEndPoint

end
