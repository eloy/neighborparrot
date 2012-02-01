require 'em-mongo'
require 'em-synchrony/em-mongo'
module Neighborparrot
  module Mongo
    # class db connection
    @@db = nil

    def mongo_connect
      db_name = 'nparrot'
      db_name << '-test' if Goliath.env == :test
      @@db = EM::Mongo::Connection.new('localhost').db(db_name)
    end

    def mongo_connected?
      @@db && @@db.connection.connected?
    end

    def mongo_db
      mongo_connect unless mongo_connected?
      return @@db
    end

    # Return first matched record
    def mongo_first(collection, query)
      resp = mongo_db.collection(collection).first(query)
      attach_errback resp
    end

    def mongo_increment(collection, api_id, field, increment=1)
      mongo.db.collection(collection).update({ :api_id => api_id}, {"$addToSet" =>  {field => 0}, "$inc" => { field => increment} } )
    end

    private
    def attach_errback(response)
      response.errback do |err|
        env.logger.info "Error!! #{err}"
        raise Goliath::Validation::BadRequestError.new("invalid application")
      end
      return response
    end
  end
end
