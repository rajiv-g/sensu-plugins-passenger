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
         long: '--queue-warning PERCENT',
         description: 'Warn if PERCENT or more of queue length',
         proc: proc(&:to_f),
         default: 1

  option :qcrit,
         long: '--queue-critical PERCENT',
         description: 'Critical if PERCENT or more of queue length',
         proc: proc(&:to_f),
         default: 1.5

  def usage_summary
    "Request Queue Length: #{@top_level_queue_length}, Application Queue Length: #{@application_queue_length}"
  end

  def passenger_status
    `sudo passenger-status --show=xml`
  end

  def process_application_groups(supergroups)
    app_queue_length = 0
    supergroups.children.xpath('//supergroup').each do |group|
      app_queue = group.xpath('.//group/get_wait_list_size')[0].children.to_s
      app_queue_length += app_queue.to_i if number?(app_queue)
    end
    app_queue_length
  end

  def run
    command_output = Nokogiri::XML.parse passenger_status
    @top_level_queue_length = 0
    top_level_queue = command_output.xpath('//get_wait_list_size').children[0].to_s
    @top_level_queue_length = top_level_queue.to_i if number?(top_level_queue)

    # Add application queues
    @application_queue_length = process_application_groups(command_output.xpath('//supergroups'))
    total_queue_length = @top_level_queue_length + @application_queue_length

    if total_queue_length >= config[:qcrit]
      critical usage_summary
    elsif total_queue_length >= config[:qwarn]
      warning usage_summary
    else
      ok "Request Queue under #{config[:qwarn]}"
    end
  end

  def number?(input)
    Float(input)
    true
  rescue StandardError
    false
  end
end
