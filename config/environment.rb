# Load the rails application
require File.expand_path('../application', __FILE__)

class Logger
  def format_message(severity, timestamp, progname, msg)
    "#{timestamp} (#{$$}) #{msg}\n"
  end
end

# Initialize the rails application
ScholarSphere::Application.initialize!
ActiveRecord::Base.connection.execute("SET AUTOCOMMIT=1") if ActiveRecord::Base.connection.instance_of? ActiveRecord::ConnectionAdapters::Mysql2Adapter 
#ActiveRecord::Base.connection.instance_of? ActiveRecord::ConnectionAdapters::Mysql2Adapter ActiveRecord::Base.connection.execute("SET AUTOCOMMIT=1") 
