require 'rack'

class Rack::Request

  # Pulled from rack master on 2013-05-01. This modifies the rack port lookup
  # to look at HTTP_X_FORWARDED_PROTO and make a decision. This lookup is
  # missing from v1.5.2 and causes our Production setup (stunnel and haproxy)
  # to not work correctly.
  def port
    if port = host_with_port.split(/:/)[1]
      port.to_i
    elsif port = @env['HTTP_X_FORWARDED_PORT']
      port.to_i
    elsif @env.has_key?("HTTP_X_FORWARDED_HOST")
      DEFAULT_PORTS[scheme]
    elsif @env.has_key?("HTTP_X_FORWARDED_PROTO")
      DEFAULT_PORTS[@env['HTTP_X_FORWARDED_PROTO']]
    else
      @env["SERVER_PORT"].to_i
    end
  end

end
