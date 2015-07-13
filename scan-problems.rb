#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'pathname'
require 'uri'
require 'yaml'

require 'rubygems'
require 'bundler/setup'
require 'google_drive'

require_relative 'lib/pukiwiki'

# s: date-like string
def normalize_date(s)
  s.tr('０-９', '0-9').gsub(%r{(\d{4})\s*[年/]\s*(\d{1,2})\s*月?}) { "#{$1}年#{$2.rjust(2, '0')}月" }
end

def extract_metadata(source)
  if source =~ /tag:/ or (source =~ /難度/ and source =~ /分野/)
    return {
      'Author' => source.scan(/投稿\s*[:：]\s*(.*?)\s*$/).flatten.join(';'),
      'Source' => source.scan(/出典\s*[:：]\s*(.*?)\s*$/).flatten.join(';'),
      'Date' => source.scan(/時期\s*[:：]\s*(.*?)\s*$/).flatten.map(&method(:normalize_date)).join(''),
      'Genre' => source.scan(/tag:genre:([a-z]+)/).flatten.sort.join(';'),
      'Difficulty' => source.scan(/tag:diff:([a-z]+)/).flatten.sort.join(';'),
      'Target' => source.scan(/tag:target:([a-z]+)/).flatten.sort.join(';')
    }
  end
end

params = ARGV.getopts(nil, 'dryrun', 'verbose')
dryrun = params['dryrun']
verbose = params['verbose']

config = YAML.load_file(Pathname(__FILE__).dirname + 'config.yml')

cred_store = Pathname(__FILE__).dirname + 'credentials.json'
auth = Signet::OAuth2::Client.new(open(cred_store) {|f| JSON.parse(f.read) })
auth.refresh!
open(Pathname(__FILE__).dirname + 'credentials.json', 'w', 0600) {|f| f.write(auth.to_json) }

pukiwiki = PukiWiki.new(config[:pukiwiki][:location]).login(config[:pukiwiki][:username], config[:pukiwiki][:password])
gdrive = GoogleDrive.login_with_oauth(auth.access_token)
ws = gdrive.spreadsheet_by_key(config[:gdrive][:workbook]).worksheets.find {|ws| ws.title = 'Problems' }

pukiwiki.select {|page| page.name =~ %r{^(?:未推薦|推薦|未解決|使用済み|棄却済み)問題/[^/]+$} }.each do |page|
  status, title = page.name.split('/', 2)
  next if title == 'template'

  info = {'Title' => title, 'Status' => status, 'URI' => page.uri, 'LastModified' => page.last_modified}

  begin
    if record = ws.list.find {|record| record['Title'] == title }
      if info.any? {|k, v| v != record[k] }
        metadata = extract_metadata(pukiwiki.get(page)) || {}
        record.update(metadata.merge(info))
        puts "Updating record: #{title}"
      end
    elsif metadata = extract_metadata(pukiwiki.get(page))
      ws.list.push(metadata.merge(info))
      puts "Inserting record: #{title}"
    else
      puts "Ill-formed problem page: #{page.name}"
    end

    ws.synchronize if !dryrun and ws.dirty?
  rescue => e
    $stderr.puts "...failed: #{e} at #{e.backtrace.join(' from ')}"
  end
end
