namespace 'apache' do
  desc 'setup a simple apache webserver on mac'
  task :setup do
    user = ENV['USER']
    return if user == 'jenkins'
    file = IO.read('misc/user.conf')
    file = file.sub('USER', user)
    IO.write("misc/#{user}.conf", file)
    system("sudo cp misc/#{user}.conf /etc/apache2/users/")
    system('sudo cp misc/httpd.conf /etc/apache2/')
    system('sudo cp misc/httpd-userdir.conf /etc/apache2/extra')
    system('mkdir -p ~/Sites/rs')
    system('sudo apachectl restart')
  end
end
