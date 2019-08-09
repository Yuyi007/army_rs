# Anytime you filter a set with more than one requirement, you
# internally use a `MultiSet`. `MultiSet` is a bit slower than just
# a `Set` because it has to `SINTERSTORE` all the keys prior to
# retrieving the members, size, etc.
#
# Example:
#
#   User.all.kind_of?(Ohm::Set)
#   # => true
#
#   User.find(:name => "John").kind_of?(Ohm::Set)
#   # => true
#
#   User.find(:name => "John", :age => 30).kind_of?(Ohm::MultiSet)
#   # => true
#
module Ohm
  class MultiSet < Ohm::BasicSet
    attr_reader :namespace
    attr_reader :model
    attr_reader :command

    def initialize(namespace, model, command)
      @namespace = namespace
      @model = model
      @command = command
    end

    # Chain new fiters on an existing set.
    #
    # Example:
    #
    #   set = User.find(:name => "John", :age => 30)
    #   set.find(:status => 'pending')
    #
    def find(dict)
      MultiSet.new(
        namespace, model, Command[:sinterstore, command, intersected(dict)]
      )
    end

    # Reduce the set using any number of filters.
    #
    # Example:
    #
    #   set = User.find(:name => "John")
    #   set.except(:country => "US")
    #
    #   # You can also do it in one line.
    #   User.find(:name => "John").except(:country => "US")
    #
    def except(dict)
      MultiSet.new(
        namespace, model, Command[:sdiffstore, command, unioned(dict)]
      )
    end

    # Do a union to the existing set using any number of filters.
    #
    # Example:
    #
    #   set = User.find(:name => "John")
    #   set.union(:name => "Jane")
    #
    #   # You can also do it in one line.
    #   User.find(:name => "John").union(:name => "Jane")
    #
    def union(dict)
      MultiSet.new(
        namespace, model, Command[:sunionstore, command, intersected(dict)]
      )
    end

    private

    def redis
      model.redis
    end

    def intersected(dict)
      Command[:sinterstore, *model.filters(dict)]
    end

    def unioned(dict)
      Command[:sunionstore, *model.filters(dict)]
    end

    def execute
      # namespace[:tmp] is where all the temp keys should be stored in.
      # redis will be where all the commands are executed against.
      response = command.call(namespace[:tmp], redis)

      begin

        # At this point, we have the final aggregated set, which we yield
        # to the caller. the caller can do all the normal set operations,
        # i.e. SCARD, SMEMBERS, etc.
        yield response

      ensure

        # We have to make sure we clean up the temporary keys to avoid
        # memory leaks and the unintended explosion of memory usage.
        command.clean
      end
    end
  end
end
