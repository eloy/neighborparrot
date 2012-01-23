class Router < Goliath::API


  get '/'        ,StaticIndexEndPoint
  map '/open'    ,EventSourceEndPoint
  map '/send'    ,SendRequestEndPoint

end
