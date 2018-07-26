#!/usr/bin/env ruby

require 'pathname'

require 'bundler/setup'
require 'googleauth'
require 'googleauth/stores/file_token_store'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

scopes = %w[https://www.googleapis.com/auth/drive https://spreadsheets.google.com/feeds]
client_id = Google::Auth::ClientId.from_file(Pathname(__dir__) + 'client_secrets.json')
token_store = Google::Auth::Stores::FileTokenStore.new(file: Pathname(__dir__) + 'token.yml')
authorizer = Google::Auth::UserAuthorizer.new(client_id, scopes, token_store)

user_id = 'default'

unless authorizer.get_credentials(user_id)
  url = authorizer.get_authorization_url(base_url: OOB_URI)
  print("1. Open this page:\n#{url}\n\n")
  print("2. Enter the authorization code shown in the page: ")
  code = $stdin.gets.chomp
  credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
end
