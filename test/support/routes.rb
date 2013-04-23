require 'deas'

class Deas::Server

  root File.expand_path("..", __FILE__)

  get '/show',  'ShowTest'
  get '/halt',  'HaltTest'
  get '/error', 'ErrorTest'

end

class ShowTest
  include Deas::ViewHandler

  attr_reader :message

  def init!
    @message = params['message']
  end

  def run!
    render 'show'
  end

end

class HaltTest
  include Deas::ViewHandler

  def init!
    halt params['with'].to_i
  end

end

class ErrorTest
  include Deas::ViewHandler

  def run!
    raise 'test'
  end

end
