require 'wombat'
require 'csv'
require 'pp'

header = ['title', 'station', 'description', 'issues', 'medium', 'character', 'url', 'imageURL', 'bcastId', 'documentId']
characters = ('A'..'Z').to_a + ['0+-+9']
scraped = []
base_url = 'https://www.zdf.de/'

characters.each do |character|
  puts "Character #{character}..."
  begin
    scraped_character = Wombat.crawl do
      base_url "#{base_url}/"
      path "/sendungen-a-z?group=#{character}"

      content 'css=article.b-content-teaser-item', :iterator do
        title 'css=a.teaser-title-link'
        issues 'css=.teaser-label' do |s|
          s && s[/(\d+) Beiträg/,1]
        end
        url "xpath=.//a[contains(@class, 'teaser-title-link')]/@href" do |s|
          "#{base_url}#{s}"
        end
        zdfMediathek "xpath=.//a[contains(@class, 'teaser-title-link')]", :follow do
          station "xpath=.//article[contains(@class, 'b-cluster-teaser')]/@data-station"
          description "xpath=//meta[contains(@name, 'description')]/@content"
        end
        medium 'tv'
        character character.to_s
        imageURL "xpath=.//img[contains(@class, 'preview-image')]/@data-src"
      end
    end
    scraped.push(*scraped_character['content'])
  rescue Mechanize::ResponseCodeError
    puts "Mechanize::ResponseCodeError"
  end
end


CSV.open("broadcasts.csv", "w", force_quotes: true) do |csv|
  csv << header
  scraped.each do |row|
    csv << [row['title'], row['zdfMediathek'][0]['station'], row['zdfMediathek'][0]['description'], row['issues'], row['medium'], row['character'], row['url'], row['imageURL']]
  end
end
