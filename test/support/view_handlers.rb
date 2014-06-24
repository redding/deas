require 'deas/view_handler'

class TestViewHandler
  include Deas::ViewHandler

end

class TestRunnerViewHandler
  include Deas::ViewHandler

  attr_accessor :custom_value

  def run!
    'run has run'
  end

end

class RenderViewHandler
  include Deas::ViewHandler

  def run!
    render "my_template", :some => :option
  end
end

class PartialViewHandler
  include Deas::ViewHandler

  def run!
    partial "my_partial", :some => 'locals'
  end
end

class SendFileViewHandler
  include Deas::ViewHandler

  def run!
    send_file "my_file.txt", :some => :option
  end
end

class FlagViewHandler
  include Deas::ViewHandler
  before{ @before_hook_called = true }
  after{  @after_hook_called  = true }
  layout 'web'

  attr_reader :before_init_called, :init_bang_called, :after_init_called
  attr_reader :before_run_called, :run_bang_called, :after_run_called
  attr_reader :before_hook_called, :after_hook_called, :second_before_init_called

  before_init do
    @before_init_called = true
  end
  before_init do
    @second_before_init_called = true
  end

  def init!
    @init_bang_called = true
  end

  after_init do
    @after_init_called = true
  end

  before_run do
    @before_run_called = true
  end

  def run!
    @run_bang_called = true
  end

  after_run do
    @after_run_called = true
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
