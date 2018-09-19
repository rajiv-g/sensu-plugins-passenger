# frozen_string_literal: true

require 'nokogiri'
require_relative './spec_helper.rb'
require_relative '../bin/check-passenger-status.rb'

class PassengerCheck
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

describe 'PassengerCheck' do
  before :all do
    @check =  PassengerCheck.new(['--queue-warning', '1', '--queue-critical', '1.5'])
  end

  describe 'When settings are default' do
    it 'ran sucessfully' do
      allow(@check).to receive(:passenger_status).and_return(open(File.dirname(__FILE__) + '/fixture/output.txt').read)
      expect(@check.run).to eq('triggered ok: Request Queue under 1.0')
    end
  end

  describe 'When threshold reached critical' do
    it 'Raise critical' do
      config = {
        qwarn: 0,
        qcrit: 1
      }
      @check.config = config
      allow(@check).to receive(:passenger_status).and_return(open(File.dirname(__FILE__) + '/fixture/warn.txt').read)
      expect(@check.run).to eq('triggered critical: Request Queue Length: 0, Application Queue Length: 1')
    end
  end

  describe 'When threshold reached warning' do
    it 'Raise critical' do
      config = {
        qwarn: 1,
        qcrit: 2
      }
      @check.config = config
      allow(@check).to receive(:passenger_status).and_return(open(File.dirname(__FILE__) + '/fixture/warn.txt').read)
      expect(@check.run).to eq('triggered warning: Request Queue Length: 0, Application Queue Length: 1')
    end
  end
end
