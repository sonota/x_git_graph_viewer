# -*- coding: utf-8 -*-

require "sinatra"
require "sinatra/reloader"
require "json"
require "./git"
 
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

# --------------------------------

def _api(params)
  api_params = JSON.parse(params[:apiParams])
  status = "NG"
  data = {}

  begin
    data = yield(api_params)
    status = "OK"
  rescue => e
    $stderr.puts e.class, e.message, e.backtrace
    data = {
      :msg => "#{e.class}: #{e.message}",
      :trace => e.backtrace.join("\n")
    }
  end

  content_type :json
  JSON.generate({
    "status" => status,
    "data" => data
  })
end

# --------------------------------

get "/" do
  send_file "v_root.html"
end

get "/api/graph" do
  # for development
  load "./git.rb"

  _api(params) do |api_params|
    dir = api_params["dir"]
    git = Git.new(dir)
    git.load
    git.to_hash
  end
end
