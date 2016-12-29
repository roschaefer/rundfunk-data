require 'wombat'
require 'pry'
require 'pp'


Wombat.configure do |config|
  config.set_user_agent "Linux Mozilla"
end

result = Wombat.crawl do
  base_url "http://www.ardmediathek.de/"
  path 'tv/sendungen-a-z?buchstabe=A'

  content 'css=.onlyWithJs .textWrapper', :iterator do
    ardmediathekURL "xpath=a[contains(@class, 'textLink')]/@href"
    documentId "xpath=a[contains(@class, 'textLink')]/@href" do |s|
      s[/documentId=(\d+)/, 1]
    end
    bcastId "xpath=a[contains(@class, 'textLink')]/@href" do |s|
      s[/bcastId=(\d+)/, 1]
    end
    issues 'css=p.dachzeile' do |s|
      s[/(\d+) Ausgabe/, 1]
    end
    title 'css=h4.headline'
    station 'css=p.subtitle'
  end
end

pp result
