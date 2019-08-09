every :day, at: '12:00pm' do
	command "cd /usr/local/rs && rake log:compress"
end