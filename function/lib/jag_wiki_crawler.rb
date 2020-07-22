require 'pukiwiki'

class JagWikiCrawler
  def initialize(config)
    @pukiwiki = PukiWiki.new(config[:location]).login(config[:username], config[:password])
  end

  def scan(ws)
    @pukiwiki.select {|page| page.name =~ %r{\A(?:未推薦|推薦|未解決|使用済み|棄却済み)問題/[^/]+\z} }.each do |page|
      status, title = page.name.split('/', 2)
      next if title == 'template'

      info = {'Title' => title, 'Status' => status, 'URI' => page.uri, 'LastModified' => page.last_modified}

      begin
        if record = ws.list.find {|record| record['Title'] == title }
          if info.any? {|k, v| v != record[k] }
            metadata = extract_metadata(@pukiwiki.get(page)) || {}
            metadata.merge(info).each do |k, v|
              record[k] = v if record[k] != v
            end
            puts "Updating record: #{title}"
          end
        elsif metadata = extract_metadata(@pukiwiki.get(page))
          ws.list.push(metadata.merge(info))
          puts "Inserting record: #{title}"
        else
          puts "Ill-formed problem page: #{page.name}"
        end
      rescue => e
        $stderr.puts "...failed: #{e} at #{e.backtrace.join(' from ')}"
      end
    end

  end

  private

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
        'Target' => source.scan(/tag:target:([a-z]+)/).flatten.sort.join(';'),
      }
    end
  end
end
