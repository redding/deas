require 'deas/view_handler'

class EmptyViewHandler
  include Deas::ViewHandler

end

class TestRunnerViewHandler
  include Deas::ViewHandler

  attr_accessor :custom_value

  def run!
    'run has run'
  end

end

class DeasRunnerViewHandler
  include Deas::ViewHandler

  attr_reader :before_called, :after_called
  attr_reader :init_bang_called, :run_bang_called

  layout 'web'

  before{ @before_called = true }
  after{  @after_called  = true }

  def init!; @init_bang_called = true; end
  def run!;  @run_bang_called  = true; end

end

class RenderViewHandler
  include Deas::ViewHandler

  def run!
    render "my_template", :some => :option
  end
end

class SendFileViewHandler
  include Deas::ViewHandler

  def run!
    send_file "my_file.txt", :some => :option
  end
end

class HaltViewHandler
  include Deas::ViewHandler

  def run!
    halt_args = [ params['code'].to_i, params['headers'], params['body'] ].compact
    halt(*halt_args)
  end

end

class ContentTypeViewHandler
  include Deas::ViewHandler

  def run!
    content_type 'text/plain', :charset => 'latin1'
  end

end

class StatusViewHandler
  include Deas::ViewHandler

  def run!
    status 422
  end

end

class HeadersViewHandler
  include Deas::ViewHandler

  def run!
    headers \
      'other' => "other",
      'a-header' => 'some value'
  end

end
