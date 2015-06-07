# -*- coding: utf-8 -*-

require "sinatra"
require "sinatra/reloader"
 
# sinatraでDNS逆引きを止める | TechRacho
# http://techracho.bpsinc.jp/baba/2012_11_02/6367
class Rack::Handler::WEBrick
  class << self
    alias_method :run_original, :run
  end
  def self.run(app, options={})
    options[:DoNotReverseLookup] = true
    run_original(app, options)
  end
end

set :bind, '0.0.0.0'

get "/" do
  send_file "v_root.html"
end
