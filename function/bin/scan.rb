#!/usr/bin/env ruby
ENV['SPREADSHEET_ID'] = ARGV[0]

require_relative '../handler.rb'
main
