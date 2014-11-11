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

  get  '/show',              'ShowHandler'
  get  '/show.html',         'ShowHtmlHandler'
  get  '/show.json',         'ShowJsonHandler'
  get  '/show-latin1-json',  'ShowLatinJsonHandler'
  get  '/show-text',         'ShowTextHandler'
  get  '/show-headers-text', 'ShowHeadersTextHandler'

  get  '/halt',     'HaltHandler'
  get  '/error',    'ErrorHandler'
  get  '/redirect', 'RedirectHandler'
  post '/session',  'SetSessionHandler'
  get  '/session',  'UseSessionHandler'

  get  '/with_layout',           'WithLayoutHandler'
  get  '/alt_with_layout',       'AlternateWithLayoutHandler'
  get  '/haml_with_layout',      'HamlWithLayoutHandler'
  get  '/with_haml_layout',      'WithHamlLayoutHandler'
  get  '/haml_with_haml_layout', 'HamlWithHamlLayoutHandler'
  get  '/partial.html',          'PartialHandler'

  get '/handler/tests.json', 'HandlerTestsHandler'

  redirect '/route_redirect',   '/somewhere'
  redirect('/:prefix/redirect'){ "/#{params['prefix']}/somewhere" }

end

class DeasDevServer
  include Deas::Server

  # this server mimics a server in a "development" mode, that is, it has
  # show_exceptions set to true

  root TEST_SUPPORT_ROOT

  logger TEST_LOGGER
  verbose_logging true

  show_exceptions true

  get  '/error', 'ErrorHandler'

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

class ShowHtmlHandler
  include Deas::ViewHandler

  def run!; render 'show.html'; end

end

class ShowJsonHandler
  include Deas::ViewHandler

  def run!; render 'show.json'; end

end

class ShowLatinJsonHandler
  include Deas::ViewHandler

  def run!
    content_type :json, :charset => 'latin1'
    render 'show_json'
  end

end

class ShowTextHandler
  include Deas::ViewHandler

  def run!
    hdrs = {'Content-Type' => 'text/plain'}
    halt 200, hdrs, render('show.json')
  end

end

class ShowHeadersTextHandler
  include Deas::ViewHandler

  def run!
    headers 'Content-Type' => 'text/plain'
    render('show.json')
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

class HamlWithLayoutHandler
  include Deas::ViewHandler
  layouts 'layout1'

  def run!
    render 'haml_with_layout'
  end

end

class WithHamlLayoutHandler
  include Deas::ViewHandler
  layouts 'haml_layout1'

  def run!
    render 'with_layout'
  end

end

class HamlWithHamlLayoutHandler
  include Deas::ViewHandler
  layouts 'haml_layout1'

  def run!
    render 'haml_with_layout'
  end

end

class PartialHandler
  include Deas::ViewHandler

  def run!; partial 'info', :info => 'some-info'; end

end

class RedirectHandler
  include Deas::ViewHandler

  def run!
    redirect 'http://google.com', 'wrong place, buddy'
  end

end

class SetSessionHandler
  include Deas::ViewHandler

  def run!
    session[:secret] = 'session_secret'
    redirect '/session'
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
