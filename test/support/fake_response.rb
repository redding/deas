class FakeResponse < Struct.new(:status, :headers, :body)

  def initialize(args = nil)
    args ||= {}
    super(*[
      args[:status]  || Factory.integer,
      args[:headers] || Rack::Utils::HeaderHash.new,
      args[:body]    || [Factory.text]
    ])
  end

end
