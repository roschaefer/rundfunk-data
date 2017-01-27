require 'wombat'
require 'pp'
require 'linkeddata'
require_relative '../lib/lib.rb'

def scrape
  characters = ('A'..'Z').to_a + ['0+-+9']
  scraped = []
  base_url = 'https://www.zdf.de/'

  characters = ['Z']

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


  #header = ['title', 'station', 'description', 'issues', 'medium', 'character', 'url', 'imageURL', 'bcastId', 'documentId']

  graph = RDF::Graph.new
  graph_uri = RDF::URI.new(base_url)
  scraped.each do |row|
    node = RDF::URI.new(row['url'])
    statements = [
      RDF::Statement(node, ont('scraped'), graph_uri),
      RDF::Statement(node, RDF::Vocab::DC11.type, ont('broadcast')),
      RDF::Statement(node, ont('title') ,       RDF::Literal.new(         row['title']                          )),
      RDF::Statement(node, ont('station') ,     RDF::Literal.new(         row['zdfMediathek'][0]['station']     )),
      RDF::Statement(node, ont('description') , RDF::Literal.new(         row['zdfMediathek'][0]['description'] )),
      RDF::Statement(node, ont('issues') ,      RDF::Literal::Integer.new(row['issues']                         )),
      RDF::Statement(node, ont('character') ,   RDF::Literal.new(         row['character']                      )),
      RDF::Statement(node, ont('url') ,         RDF::Literal.new(         row['url']                            )),
      RDF::Statement(node, ont('imageUrl') ,    RDF::Literal.new(         row['imageURL']                       )),
    ]
    statements = statements.select {|s| s.predicate && s.object }
    statements.each {|s| graph << s }

  end
  repo = RDF::Blazegraph::Repository.new(Config['sparql_endpoint'])
  puts "Before: #{repo.count} triples"
  repo << graph.statements
  puts "After: #{repo.count} triples"
end
