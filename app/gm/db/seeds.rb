# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

role_list = [
  [ 'admin', 'admin', 1 ],
  [ 'p0', 'p0', 2 ],
  [ 'p1', 'p1', 3 ],
  [ 'p2', 'p2', 4 ],
  [ 'p3', 'p3', 5 ],
  [ 'p4', 'p4', 6 ],
  [ 'p5', 'p5', 7 ],
  [ 'p6', 'p6', 8 ],
]

role_list.each do |name, type, id|
  Role.create( name: name, authorizable_type: type, authorizable_id: id )
end

user_list = [
  [ 'duwenjie', 'duwenjie@gmail.com', '123456Fv' ]
]

user_list.each do |username, email, password|
  SiteUser.create( username: username, email: email, password: password, password_confirmation: password, verified: true )
end

SiteUser.find(1).roles << Role.find(1)
# SiteUser.find(2).roles << Role.find(6)
