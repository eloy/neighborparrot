require 'em-mongo'

module Neighborparrot
  module Mongo
    # class db connection
    @@db = nil

    def mongo_connect
      @@db = EM::Mongo::Connection.new('localhost').db('nparrot')
    end

    def mongo_connected?
      @@db && @@db.connection.connected?
    end

    def mongo_db
      mongo_connect unless mongo_connected?
      return @@db
    end

    def mongo_first(collection, query)
      resp = mongo_db.collection(collection).first(query)
      attach_errback resp
    end


    private
    def attach_errback(response)
      response.errback do |err|
        env.logger.info "Error!! #{err}"
        raise Goliath::Validation::BadRequestError.new("invalid signature")
      end
      return response
    end

  end
end
