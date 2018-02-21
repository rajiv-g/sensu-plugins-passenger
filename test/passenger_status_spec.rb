require_relative './plugin_stub.rb'
require_relative './spec_helper.rb'
require_relative '../bin/metrics-passenger-status'
require_relative '../bin/check-passenger-status'

RSpec.configure do |c|
  c.before { allow($stdout).to receive(:puts) }
  c.before { allow($stderr).to receive(:puts) }
end

describe PassengerMetrics, 'run' do
  it 'returns metrics' do
    plugin = PassengerMetrics.new
    allow(plugin).to receive(:passenger_status).and_return(open(File.dirname(__FILE__) + '/fixture/output.txt').read)
    expect(-> { plugin.run }).to raise_error SystemExit
  end
end

describe PassengerMetrics, 'run' do
  it 'returns metrics' do
    plugin = PassengerCheck.new
    allow(plugin).to receive(:passenger_status).and_return(open(File.dirname(__FILE__) + '/fixture/output.txt').read)
    expect(-> { plugin.run }).to raise_error SystemExit
  end
end
