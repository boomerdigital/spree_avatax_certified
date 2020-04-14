::Avatax::Client.prepend(Module.new do
  def initialize(*)
    super
    @connection.builder.handlers.delete(Faraday::Response::Logger)
  end
end)
