class Router < Goliath::API


  get '/'        ,StaticIndexEndPoint
  map '/open'    ,EventSourceEndPoint

end
