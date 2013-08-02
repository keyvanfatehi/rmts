require 'sinatra'
require 'haml'
require 'json'
require 'bait/build'
require 'sinatra/streaming'

module Bait
  class Api < Sinatra::Base
    attr_reader :subscribers
    def initialize
      super
      @subscribers = []
    end

    set :port, 8417

    get '/' do
      redirect '/build'
    end

    post '/' do
      if params && params["payload"]
        push = JSON.parse(params["payload"])
        Build.create({
          name: push["repository"]["name"],
          clone_url: push["repository"]["url"],
          owner_name: push["repository"]["owner"]["name"],
          owner_email: push["repository"]["owner"]["email"],
          ref: push["ref"]
        }).test_later
      end
    end

    get '/build' do
      @builds = Bait::Build.all
      haml :builds
    end

    post '/build/create' do
      build = Build.create({
        clone_url:params["clone_url"],
        name:params["clone_url"].split('/').last
      })
      build.test_later
      redirect '/build'
    end

    get '/build/:id/remove' do
      Build.destroy params["id"]
      redirect '/build'
    end

    get '/build/:id/retest' do
      build = Build.find params['id']
      build.tested = false
      build.output = ""
      build.save
      build.test_later
      redirect '/build'
    end

    # events
    helpers Sinatra::Streaming

    get '/events' do
      content_type 'text/event-stream'
      stream(:keep_open) do |out|
        self.subscribers << out
        out.callback { self.subscribers.delete(out) }
      end
    end

    get '/test' do
      self.subscribers.each do |out|
        out << "event: build_no_log_output\n\n"
        out << "data: foofoofoo\n\n"
      end
      "hi"
    end

  end
end
