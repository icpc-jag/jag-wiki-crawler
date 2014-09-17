#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'date'
require 'pathname'
require 'uri'
require 'yaml'

require 'rubygems'
require 'bundler/setup'
require 'google_drive'
require 'mechanize'

require_relative 'lib/pukiwiki'

def extract_metadata(source)
  if source =~ /tag:/ or (source =~ /難度/ and source =~ /分野/)
    return {
      'Author' => source.scan(/投稿\s*[:：]\s*(.*?)\s*$/).flatten.join(';'),
      'Source' => source.scan(/出典\s*[:：]\s*(.*?)\s*$/).flatten.join(';'),
      'Date' => source.scan(/時期\s*[:：]\s*(.*?)\s*$/).flatten.map {|s| s.gsub(%r{(\d{4})\s*/\s*(\d{1,2})}, '\1年\2月') }.join(''),
      'Genre' => source.scan(/tag:genre:([a-z]+)/).flatten.sort.join(';'),
      'Difficulty' => source.scan(/tag:diff:([a-z]+)/).flatten.sort.join(';'),
      'Target' => source.scan(/tag:target:([a-z]+)/).flatten.sort.join(';')
    }
  end
end

config = YAML.load_file(Pathname(__FILE__).dirname + 'config.yml')

pukiwiki = PukiWiki.new(config[:pukiwiki][:location]).login(config[:pukiwiki][:username], config[:pukiwiki][:password])
gdrive = GoogleDrive.login(config[:gdrive][:username], config[:gdrive][:password])
ws = gdrive.spreadsheet_by_key(config[:gdrive][:workbook]).worksheets.find {|ws| ws.title = 'Problems' }

pukiwiki.list.select {|page| page.name =~ %r{^(?:未推薦|推薦|未解決|使用済み|棄却済み)問題/[^/]+$} }.each do |page|
  status, title = page.name.split('/', 2)
  next if title == 'template'

  begin
    if record = ws.list.find {|record| record['Title'] == title }
      if record['Status'] != status or record['LastModified'] != page.last_modified or record['URI'] != page.uri
        record['Status'] = status
        record['LastModified'] = page.last_modified
        record['URI'] = page.uri
        if data = extract_metadata(pukiwiki.get(page))
          record.update(data)
        end
        puts "Updating record: #{title}"
      end
    elsif data = extract_metadata(pukiwiki.get(page))
      data.merge!('Title' => title, 'Status' => status, 'URI' => page.uri, 'LastModified' => page.last_modified)
      ws.list.push(data)
      puts "Inserting record: #{title}"
    else
      puts "Ill-formed problem page: #{page.name}"
    end

    ws.synchronize if ws.dirty?
  rescue => e
    puts "...failed: #{e}"
  end
end
