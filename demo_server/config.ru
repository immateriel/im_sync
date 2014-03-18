require 'demo_server'

use Rack::ShowExceptions
run Rack::DemoServer.new