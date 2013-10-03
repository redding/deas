module Deas

  module Cgi
    # taken from http://ruby-doc.org/stdlib/libdoc/cgi/rdoc/index.html
    # => not requiring 'cgi' to save on memory usage

    def self.escape(string)
      string.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
        '%' + $1.unpack('H2' * $1.size).join('%').upcase
      end.gsub(' ', '%20')
    end

    def self.http_query(value, key_ns = nil)
      # optimized version taken from:
      # http://github.com/kelredd/useful/blob/master/lib/useful/ruby_extensions/hash.rb
      value.sort{|a,b| a[0].to_s <=> b[0].to_s}.collect do |key_val|
        key, val = key_val
        key_s = key_ns ? "#{key_ns}[#{key_val[0].to_s}]" : key_val[0].to_s
        if key_val[1].kind_of?(::Array)
          key_val[1].sort.collect{|i| "#{key_s}[]=#{Deas::Cgi.escape(i.to_s)}"}.join('&')
        elsif key_val[1].kind_of?(::Hash)
          Deas::Cgi.http_query(key_val[1], key_s)
        else
          "#{key_s}=#{Deas::Cgi.escape(key_val[1].to_s)}"
        end
      end.join('&')
    end

  end

end
