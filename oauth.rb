#!/usr/bin/env ruby

require 'pathname'

require 'rubygems'
require 'bundler/setup'
require 'google/api_client'

auth = Google::APIClient::ClientSecrets.load(Pathname(__FILE__).dirname).to_authorization
auth.scope = %[https://www.googleapis.com/auth/drive https://spreadsheets.google.com/feeds]

print("1. Open this page:\n#{auth.authorization_uri}\n\n")
print("2. Enter the authorization code shown in the page: ")
auth.code = $stdin.gets.chomp
auth.fetch_access_token!

open(Pathname(__FILE__).dirname + 'credentials.json', 'w', 0600) {|f| f.write(auth.to_json) }

puts("Done!")
