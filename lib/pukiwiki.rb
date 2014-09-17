# wrapper for PukiWiki
class PukiWiki
  Page = Struct.new(:name, :uri, :last_modified)

  def initialize(uri, encoding = 'UTF-8')
    @uri = uri.is_a?(URI::Generic) ? uri : URI.parse(uri.to_s)
    @encoding = encoding
    @agent = Mechanize.new
  end

  # set authentication credential
  def login(username, password)
    @agent.add_auth(@uri, username, password)
    @agent.head(@uri)
    self
  end

  # get the list of pages
  def list()
    now = DateTime.now
    @agent.get(@uri + '?cmd=list').search('div[@id="body"]/ul/li/ul/li')
      .map {|li| Page.new(li.xpath('./a/text()').to_s, li.xpath('./a/@href').to_s,
                          (now - li.xpath('./small/text()').to_s.gsub(/^\(|d\)$/, '').to_i).strftime('%Y/%m/%d')) }
  end

  def each(&block)
    list.each(&block)
  end

  # get the source code of a page
  def get(name)
    name = name.name if name.is_a?(Page)
    @agent.get(@uri + "?cmd=source&page=#{URI::escape(name.encode(@encoding)).gsub('+','%2B')}").at('#source').text
  end
end
