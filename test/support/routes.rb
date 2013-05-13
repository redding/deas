require 'deas'

class DeasTestServer
  include Deas::Server

  root TEST_SUPPORT_ROOT

  logger TEST_LOGGER
  verbose_logging true

  set :a_setting, 'something'

  error do |exception|
    case exception
    when Sinatra::NotFound
      halt 404, "Couldn't be found"
    when Exception
      halt 500, "Oops, something went wrong"
    end
  end

  get  '/show',            'ShowHandler'
  get  '/halt',            'HaltHandler'
  get  '/error',           'ErrorHandler'
  get  '/with_layout',     'WithLayoutHandler'
  get  '/alt_with_layout', 'AlternateWithLayoutHandler'
  get  '/redirect',        'RedirectHandler'
  get  '/redirect_to',     'RedirectToHandler'
  post '/session',         'SetSessionHandler'
  get  '/session',         'UseSessionHandler'

  get '/handler/tests.json', 'HandlerTestsHandler'

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

class HandlerTestsHandler
  include Deas::ViewHandler

  def init!
    @data = {}
    set_data('app_settings_a_setting'){ self.app_settings.a_setting }
    set_data('logger_class_name'){ self.logger.class.name }
    set_data('request_method'){ self.request.request_method.to_s }
    set_data('response_firstheaderval'){ self.response.headers.sort.first.to_s }
    set_data('params_a_param'){ self.params['a-param'] }
    set_data('session_inspect'){ self.session.inspect }
  end

  def set_data(a, &block)
    begin
      @data[a] = block.call
    rescue Exception => e
    end
  end

  def run!
    require 'multi_json'
    [200, {}, MultiJson.encode(@data)]
  end

end
