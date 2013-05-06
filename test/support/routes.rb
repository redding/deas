require 'deas'

class Deas::Server

  root File.expand_path("..", __FILE__)

  log_file_path = File.expand_path("../../../log/test.log", __FILE__)

  logger Logger.new(File.open(log_file_path, 'w'))
  verbose_logging true

  get  '/show',            'ShowHandler'
  get  '/halt',            'HaltHandler'
  get  '/error',           'ErrorHandler'
  get  '/with_layout',     'WithLayoutHandler'
  get  '/alt_with_layout', 'AlternateWithLayoutHandler'
  get  '/redirect',        'RedirectHandler'
  get  '/redirect_to',     'RedirectToHandler'
  post '/session',         'SetSessionHandler'
  get  '/session',         'UseSessionHandler'

end

class ShowHandler
  include Deas::ViewHandler

  attr_reader :message

  def init!
    @message = params['message']
  end

  def run!
    render 'show'
  end

end

class HaltHandler
  include Deas::ViewHandler

  def init!
    halt params['with'].to_i
  end

end

class ErrorHandler
  include Deas::ViewHandler

  def run!
    raise 'test'
  end

end

class WithLayoutHandler
  include Deas::ViewHandler
  layouts 'layout1', 'layout2', 'layout3'

  def run!
    render 'with_layout'
  end

end

class AlternateWithLayoutHandler
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

class RedirectHandler
  include Deas::ViewHandler

  def run!
    redirect 'http://google.com', 'wrong place, buddy'
  end

end

class RedirectToHandler
  include Deas::ViewHandler

  def run!
    redirect_to '/somewhere'
  end

end

class SetSessionHandler
  include Deas::ViewHandler

  def run!
    session[:secret] = 'session_secret'
    redirect_to '/session'
  end

end

class UseSessionHandler
  include Deas::ViewHandler

  def run!
    session[:secret]
  end

end
