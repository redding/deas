require 'deas'

class Deas::Server

  root File.expand_path("..", __FILE__)

  get '/show',            'ShowTest'
  get '/halt',            'HaltTest'
  get '/error',           'ErrorTest'
  get '/with_layout',     'WithLayoutTest'
  get '/alt_with_layout', 'AlternateWithLayoutTest'

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

class WithLayoutTest
  include Deas::ViewHandler
  layouts 'layout1', 'layout2', 'layout3'

  def run!
    render 'with_layout'
  end

end

class AlternateWithLayoutTest
  include Deas::ViewHandler

  def run!
    render 'layout1' do
      render 'layout2' do
        render 'layout3' do
          render 'with_layout'
        end
      end
    end
  end

end
