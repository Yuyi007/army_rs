class MatchMapType < Enum
	include EnumEachable
	enum_attr :MT_FOOTBALL, 0
	enum_attr :MT_COMPETITIVE, 1
  enum_attr :MT_PRACTICE, 2
end

class MatchCombatType < Enum
	include EnumEachable
  enum_attr :CT_1V1, 0
  enum_attr :CT_2V2, 1
	enum_attr :CT_3V3, 2
  enum_attr :CT_4V4, 3
	enum_attr :CT_5V5, 4  
end

class PoolProfile
	attr_accessor :id
	attr_accessor :map_type
	attr_accessor :combat_type
	attr_accessor :score_min
	attr_accessor :score_max

	include Jsonable
  include Loggable

  gen_from_hash
  gen_to_hash

  @@MAP_NAME = 		{ MatchMapType::MT_FOOTBALL => "matching_mtype_football",
  									  MatchMapType::MT_COMPETITIVE => "matching_mtype_competitive"}

  @@COMBAT_NAME = { MatchCombatType::CT_1V1 => "matching_ctype_1v1",
                      MatchCombatType::CT_2V2 => "matching_ctype_2v2",
                      MatchCombatType::CT_3V3 => "matching_ctype_3v3",
                      MatchCombatType::CT_4V4 => "matching_ctype_4v4",
  								    MatchCombatType::CT_5V5 => "matching_ctype_5v5"                      
                      }

  def initialize(	id = nil, map_type = MatchMapType::MT_COMPETITIVE, 
  								combat_type = MatchCombatType::CT_3V3,
  							 	score_min = 0, score_max = 0)
  	@id = id
  	@map_type = map_type
  	@combat_type = combat_type
  	@score_min = score_min
  	@score_max = score_max
  end

  def contain?(score)
  	(score >= score_min and score <= score_max)
  end

  def map_name
  	@@MAP_NAME[@map_type.to_i]
  end

  def comabt_name
  	@@COMBAT_NAME[@combat_type.to_i]
  end

  def self.MAP_NAME
  	@@MAP_NAME
  end

  def self.COMBAT_NAME
  	@@COMBAT_NAME
  end
end