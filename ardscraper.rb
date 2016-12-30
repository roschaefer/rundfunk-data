require 'wombat'
require 'csv'
require 'pp'


header = ['title', 'station', 'description', 'issues', 'medium', 'character', 'url', 'imageURL', 'bcastId', 'documentId']
media = ['radio', 'tv']
characters = ('A'..'Z').to_a + ['0-9']
scraped = []
base_url =  "http://www.ardmediathek.de"

media.each do |medium|
  characters.each do |character|
    puts "Medium: #{medium} - Character #{character}..."
    scraped_character = Wombat.crawl do
      base_url "#{base_url}/"
      path "#{medium}/sendungen-a-z?buchstabe=#{character}"

      content 'css=.onlyWithJs .textWrapper', :iterator do
        title 'css=h4.headline'
        station 'css=p.subtitle'
        ardMediathek "xpath=a[contains(@class, 'textLink')]", :follow do
          description 'css=.onlyWithJs .teasertext'
          imageURL "xpath=//img[contains(@class, 'hideOnNoScript')]/@data-ctrl-image" do |s|
            "#{base_url}#{s[/'urlScheme':'(.*)##width##'/, 1]}320"
          end
        end
        issues 'css=p.dachzeile' do |s|
          s[/(\d+) Ausgabe/, 1]
        end
        medium medium.to_s
        character "#{character}"
        ardMediathekURL "xpath=a[contains(@class, 'textLink')]/@href" do |s|
          "#{base_url}#{s}"
        end
        documentId "xpath=a[contains(@class, 'textLink')]/@href" do |s|
          s[/documentId=(\d+)/, 1]
        end
        bcastId "xpath=a[contains(@class, 'textLink')]/@href" do |s|
          s[/bcastId=(\d+)/, 1]
        end
      end
    end
    scraped.push(*scraped_character['content'])
  end
end

CSV.open("broadcasts.csv", "w", force_quotes: true) do |csv|
  csv << header
  scraped.each do |row|
    csv << [row['title'], row['station'], row['ardMediathek'][0]['description'], row['issues'], row['medium'], row['character'], row['ardMediathekURL'], row['ardMediathek'][0]['imageURL'], row['bcastId'], row['documentId']]
  end
end
