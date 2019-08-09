# game_data_model.rb

class GameDataModel < Model

  include HashStorable
  include Loggable

  # init the game data model
  def initialize
    @delegate = ModelDelegate.new self
  end

  hash_field :instances

  gen_from_hash
  gen_to_hash

  def version=(ver)
    # puts "model.version=#{@version} (set to #{ver})"
    @version = ver
  end

  # callback validate the model before the model is saved to db
  # @return [Bool] true if the model can be persisted to db, false if can't
  def validate_model(id, zone)
    if chief
      # puts "chief.id=#{chief.id.is_a? Integer} id=#{id.is_a? Integer}"
      # puts "chief.id=#{chief.id} chief.zone=#{chief.zone} id=#{id} zone=#{zone}"
      valid = (id == chief.id && zone == chief.zone)
      if not valid then
        error "model.validate_model failed: #{id} #{zone}"
      end
      return valid
    else
      info "model.validate_model failed: no chief #{id} #{zone}"
      return false
    end
  end

  # callback: decorate the model before the model is saved to db
  # @return [Model]
  def before_update
  end

end
