# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Gm::Application.initialize!

# add load path
#Gm::Application.config.autoload_paths << "#{Rails.root}/.."
ActiveSupport::Dependencies.autoload_paths << "#{Rails.root}/.."
ActiveSupport::Dependencies.autoload_paths << "#{Rails.root}/../../lib/boot"