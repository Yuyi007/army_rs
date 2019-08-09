# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Stat::Application.initialize!

ActiveSupport::Dependencies.autoload_paths << "#{Rails.root}/.."
ActiveSupport::Dependencies.autoload_paths << "#{Rails.root}/../../lib/boot"
