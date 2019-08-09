
require "em-synchrony/mysql2"

module Mysql2
  module EM
    class Client

      def query(sql, opts={})
        deferable = aquery(sql, opts)

        # if EM is not running, we just get the sql result directly
        # if we get a deferable, then let's do the deferable thing.
        return deferable unless deferable.kind_of? ::EM::DefaultDeferrable

        deferable.timeout @read_timeout if @read_timeout

        f = Fiber.current
        deferable.callback { |res| f.resume(res) }
        deferable.errback  { |err| f.resume(err || Mysql2::Error.new('Timeout reading query result')) }

        Fiber.yield.tap do |result|
          raise result if result.is_a?(::Exception)
        end
      end
      
    end
  end
end
