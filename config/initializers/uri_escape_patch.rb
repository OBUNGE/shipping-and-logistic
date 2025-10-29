# config/initializers/uri_escape_patch.rb
require "uri"
require "cgi"

module URI
  def self.escape(str)
    CGI.escape(str.to_s).gsub("+", "%20")
  end
end
