#! /usr/bin/env ruby
# frozen_string_literal: true

#
# passenger-status
#
# DESCRIPTION:
#   This plugin retrieves machine-readable output of `passenger-status --show=xml`, parses
#   it, and generates Passenger metrics formatted for Graphite.
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   Apache module: passenger

#
# Passenger Metrics
#

require 'sensu-plugin/metric/cli'
require 'socket'
require 'nokogiri'

class PassengerMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         :description => "Metric naming scheme, text to prepend to metric",
         :long        => "--scheme SCHEME",
         :default     => "#{Socket.gethostname}.passenger"

  def output_process(process, app_group, count, timestamp)
    processed = process.xpath('.//processed')[0].children.to_s
    pid = process.xpath('.//pid')[0].children.to_s
    memory_node = process.xpath('.//real_memory')
    if !memory_node.empty?
      memory = memory_node[0].children.to_s
    end
    cpu_percent = process.xpath('.//cpu')[0].children.to_s
    start_time = Time.at(process.xpath('.//spawn_end_time').children[0].to_s.to_i/1000000)
    last_used = Time.at(process.xpath('.//last_used').children[0].to_s.to_i/1000000)
    uptime = Integer(Time.at(timestamp) - start_time)
    output "#{config[:scheme]}.#{app_group}.process_#{count}.processed", processed, timestamp
    output "#{config[:scheme]}.#{app_group}.process_#{count}.pid", pid, timestamp
    output "#{config[:scheme]}.#{app_group}.process_#{count}.uptime", uptime, timestamp
    output "#{config[:scheme]}.#{app_group}.process_#{count}.memory", memory, timestamp
    output "#{config[:scheme]}.#{app_group}.process_#{count}.cpu_percent", cpu_percent, timestamp
  end

  def process_application_groups(supergroups, timestamp)
    for group in supergroups.children.xpath('//supergroup')
      app_group = group.xpath('//supergroup/name')[0].children.to_s.gsub("\/", "_")
      app_queue = group.xpath('.//group/get_wait_list_size')[0].children.to_s
      app_capacity_used = group.xpath('//supergroup/capacity_used')[0].children.to_s
      processes_being_spawned = group.xpath('//supergroup/group/processes_being_spawned')[0].children.to_s
      output "#{config[:scheme]}.#{app_group}.queue", app_queue, timestamp
      output "#{config[:scheme]}.#{app_group}.processes", app_capacity_used, timestamp
      output "#{config[:scheme]}.#{app_group}.processes_being_spawned", processes_being_spawned, timestamp
      i = 1
      for process in group.xpath('//supergroup/group/processes').children.xpath('//process')
        output_process(process, app_group, i, timestamp)
        i = i + 1
      end
    end
  end

  def parser_main(command_output, timestamp)
      processes = command_output.xpath('//process_count').children[0].to_s
      max_pool_size = command_output.xpath('//max').children[0].to_s
      top_level_queue = command_output.xpath('//get_wait_list_size').children[0].to_s
      return max_pool_size, processes, top_level_queue, timestamp
  end

  def main_output(max_pool_size, processes, top_level_queue, timestamp)
      output "#{config[:scheme]}.max_pool_size", max_pool_size, timestamp
      output "#{config[:scheme]}.processes", processes, timestamp
      output "#{config[:scheme]}.top_level_queue", top_level_queue, timestamp
  end

  def run
    timestamp = Time.now.to_i
    command_output = Nokogiri::XML.parse `passenger-status --show=xml`
    if command_output
      main_output(*parser_main(command_output, timestamp))
      process_application_groups(command_output.xpath('//supergroups').xpath('//supergroup'), timestamp)
    end
    ok
  end
end