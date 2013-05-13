# Deas

Handler-based web framework powered by Sinatra.

## Usage

```ruby
# in your rackup file (or whatever)

require 'deas'

class MyApp
  include Deas::Server

  get '/', 'HelloWorldHandler'

end

class HellowWorldHandler
  include Deas::ViewHandler

  def run!
    "<h1>Hello World</h1>"
  end

end

app = MyApp.new
run app
```

## Installation

Add this line to your application's Gemfile:

    gem 'deas'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install deas

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
