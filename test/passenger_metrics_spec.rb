# frozen_string_literal: true

require 'nokogiri'
require_relative './spec_helper.rb'
require_relative '../bin/metrics-passenger-status.rb'

class PassengerMetrics
  at_exit do
    @@autorun = false
  end

  def critical(msg = nil)
    "triggered critical: #{msg}"
  end

  def warning(msg = nil)
    "triggered warning: #{msg}"
  end

  def ok(msg = nil)
    "triggered ok: #{msg}"
  end

  def unknown(msg = nil)
    "triggered unknown: #{msg}"
  end
end

describe 'PassengerMetrics' do
  before :all do
    @check =  PassengerMetrics.new
  end

  describe 'When settings are default' do
    it 'ran sucessfully' do
      allow(@check).to receive(:passenger_status).and_return(open(File.dirname(__FILE__) + '/fixture/output.txt').read)
      expect { @check.run }.to_not raise_error
    end
  end
end
