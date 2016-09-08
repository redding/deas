require 'deas'

class DeasTestServer
  include Deas::Server

  root TEST_SUPPORT_ROOT

  logger TEST_LOGGER
  verbose_logging Factory.boolean

  error do |exception, context|
    case exception
    when Deas::NotFound
      [404, "Couldn't be found"]
    when *Deas::SinatraApp::STANDARD_ERROR_CLASSES
      [500, "Oops, something went wrong"]
    end
  end

  router do
    default_request_type_name 'desktop'
    add_request_type('regular'){ |r| r.path_info =~ /regular/ }
    add_request_type('mobile'){ |r| r.path_info =~ /mobile/ }

    get  '/show',              'ShowHandler'
    get  '/show.html',         'ShowHtmlHandler'
    get  '/show.json',         'ShowJsonHandler'
    get  '/show-latin1-json',  'ShowLatinJsonHandler'
    get  '/show-text',         'ShowTextHandler'
    get  '/show-headers-text', 'ShowHeadersTextHandler'

    get '/req-type-show/:type', 'regular' => 'ShowHandler',
                                'mobile'  => 'ShowMobileHandler'

    get  '/halt',     'HaltHandler'
    get  '/error',    'ErrorHandler'
    get  '/redirect', 'RedirectHandler'
    post '/session',  'SetSessionHandler'
    get  '/session',  'UseSessionHandler'

    get '/handler/tests', 'HandlerTestsHandler'

    redirect '/route_redirect',   '/somewhere'
    redirect('/:prefix/redirect'){ "/#{params['prefix']}/somewhere" }
  end

  use Rack::Session::Cookie, :key          => 'my.session',
                             :expire_after => Factory.integer,
                             :secret       => Factory.string

end

class DeasDevServer
  include Deas::Server

  # this server mimics a server in a "development" mode, that is, it has
  # show_exceptions set to true

  root TEST_SUPPORT_ROOT

  logger TEST_LOGGER
  verbose_logging true

  show_exceptions true

  router do
    get '/error', 'ErrorHandler'
  end

end

class ShowHandler
  include Deas::ViewHandler

  attr_reader :message

  def init!
    @message = params['message']
  end

  def run!
    body @message
  end

end

class ShowMobileHandler
  include Deas::ViewHandler

  attr_reader :message

  def init!
    @message = "[MOBILE] #{params['message']}"
  end

  def run!
    body @message
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
    content_type '.json', :charset => 'latin1'
  end

end

class ShowTextHandler
  include Deas::ViewHandler

  def run!
    hdrs = {'Content-Type' => 'text/plain'}
    halt 200, hdrs, ''
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
    raise Deas::SinatraApp::STANDARD_ERROR_CLASSES.sample, 'sinatra app standard error'
  end

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
    request.session[:secret] = 'session_secret'
    redirect '/session'
  end

end

class UseSessionHandler
  include Deas::ViewHandler

  def run!
    body request.session[:secret]
  end

end

class HandlerTestsHandler
  include Deas::ViewHandler

  def init!
    @data = {}
    set_data('logger_class_name'){ logger.class.name }
    set_data('request_method'){ request.request_method.to_s }
    set_data('params_a_param'){ params['a-param'] }
  end

  def set_data(a, &block)
    begin
      @data[a] = block.call
    rescue Exception => e
    end
  end

  def run!
    status 200
    body   @data.inspect
  end

end
