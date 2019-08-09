# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

bills = Bill.create([ 
  { sdk: 'ndcom', platform: 'android', transId: 'transId', goodsId: 'id_000', playerId: 'test', zone: 1, count: 1, price: 100, status: 0 }
])