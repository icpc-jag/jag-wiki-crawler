#!/usr/bin/env ruby
$: << File.join(__dir__, 'lib')

require 'bundler/setup'

require 'stringio'
require 'json'

require 'aws-sdk-ssm'
require 'google_drive'

require 'jag_wiki_crawler'

PARAM_PATH_PUKIWIKI = '/jag-maintenance/pukiwiki'
PARAM_PATH_GOOGLE = '/jag-maintenance/google'

$ssm = Aws::SSM::Client.new

$worksheet = GoogleDrive::Session.from_service_account_key(
  StringIO.new($ssm.get_parameter(name: PARAM_PATH_GOOGLE, with_decryption: true).parameter.value)
).spreadsheet_by_key(ENV.fetch('SPREADSHEET_ID')).worksheet_by_title('Problems')

$jagwiki = JagWikiCrawler.new(JSON.parse(
  $ssm.get_parameter(name: PARAM_PATH_PUKIWIKI, with_decryption: true).parameter.value,
  symbolize_names: true
))

def main(*)
  $worksheet.reload
  $jagwiki.scan($worksheet)
  $worksheet.save
end
