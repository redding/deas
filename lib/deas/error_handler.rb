module Deas

  class ErrorHandler

    def self.run(*args)
      self.new(*args).run
    end

    def initialize(exception, sinatra_call, error_procs)
      @exception    = exception
      @sinatra_call = sinatra_call

      @error_procs = [*error_procs].compact
    end

    def run
      response = nil
      @error_procs.each do |error_proc|
        begin
          result = @sinatra_call.instance_exec(@exception, &error_proc)
          response = result if result
        rescue Exception => proc_exception
          @exception = proc_exception
          # reset the response if an exception occurs while evaulating the
          # error procs -- a new exception will now be handled by the
          # remaining procs
          response = nil
        end
      end
      response
    end

  end

end
