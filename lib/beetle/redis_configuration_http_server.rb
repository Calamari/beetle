require 'evma_httpserver'

module Beetle
  class RedisConfigurationHttpServer < EM::Connection
     include EM::HttpServer

     def post_init
       super
       no_environment_strings
     end

    cattr_accessor :config_server

    def process_http_request
      # the http request details are available via the following instance variables:
      #   @http_protocol
      #   @http_request_method
      #   @http_cookie
      #   @http_if_none_match
      #   @http_content_type
      #   @http_path_info
      #   @http_request_uri
      #   @http_query_string
      #   @http_post_content
      #   @http_headers
      response = EM::DelegatedHttpResponse.new(self)
      # headers = @http_headers.split("\0").inject({}){|h, s| (s =~ /^([^:]+): (.*)$/ && (h[$1] = $2)); h }

      case @http_request_uri
      when '/', '/.html'
        response.content_type 'text/html'
        server_status(response, "html")
      when "/.json"
        response.content_type 'application/json'
        server_status(response, "json")
      when "/.txt"
        response.content_type 'text/plain'
        server_status(response, "plain")
      else
        not_found(response)
      end
      response.send_response
    end

    def server_status(response, type)
      response.status = 200
      status = config_server.status
      response.content =
        case type
        when "plain"
          plain_text_response(status)
        when "json"
          status.to_json
        when "html"
          html_response(status)
        end
    end

    def plain_text_response(status)
      status.keys.sort_by{|k| k.to_s}.map do |k|
        name = k.to_s # .split('_').join(" ")
        if (value = status[k]).is_a?(Array)
          value = value.join(", ")
        end
        "#{name}: #{value}"
      end.join("\n")
    end

    def html_response(status)
      b = "<!doctype html>\n"
      b << "<html><head><title>Beetle Configuration Server Status</title>#{html_styles(status)}</head>"
      b << "<body><h1>Beetle Configuration Server Status</h1><table cellspacing=0>\n"
      plain_text_response(status).split("\n").compact.each do |row|
        row =~/(^[^:]+): (.*$)/
        b << "<tr><td>#{$1}</td><td>#{$2}</td></tr>\n"
      end
      b << "</table></body></html>"
    end

    def html_styles(status)
      warn_color = status[:redis_master_available?] ? "#5780b2" : "#A52A2A"
      <<"EOS"
<style media="screen" type="text/css">
html { font: 1.25em/1.5 arial, sans-serif;}
body { margin: 1em; }
table tr:nth-child(2n+1){ background:#fff; }
td { padding: 0.1em 0.2em; }
h1 { color: #{warn_color}; margin-bottom: 0.2em;}
</style>
EOS
    end

    def not_found(response)
      response.content_type 'text/plain'
      response.status = 404
    end
  end
end
