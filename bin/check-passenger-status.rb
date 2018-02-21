#! /usr/bin/env ruby
# frozen_string_literal: true

#
# passenger-status
#
# DESCRIPTION:
#   This plugin retrieves machine-readable output of `passenger-status --show=xml`, parses
#   it, and check teh request queue.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   Apache module: passenger

#
# Check Passenger request
#

require 'sensu-plugin/check/cli'
require 'socket'
require 'nokogiri'

class PassengerCheck < Sensu::Plugin::Check::CLI
  option :qwarn,
         short: '-w PERCENT',
         description: 'Warn if PERCENT or more of queue length',
         proc: proc(&:to_f),
         default: 1

  option :qcrit,
         short: '-c PERCENT',
         description: 'Critical if PERCENT or more of queue length',
         proc: proc(&:to_f),
         default: 1.5

  def usage_summary
    "Request Queue Length: #{@top_level_queue}"
  end

  def passenger_status
    `passenger-status --show=xml`
  end

  def run
    command_output = Nokogiri::XML.parse passenger_status
    @top_level_queue = command_output.xpath('//get_wait_list_size').children[0].to_s.to_f

    critical usage_summary if @top_level_queue >= config[:qcrit]
    warning usage_summary if @top_level_queue >= config[:qwarn]
    ok "Request Queue under #{config[:qwarn]}"
  end
end
