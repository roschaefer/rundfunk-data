require 'wombat'
require 'csv'
require 'pp'
require 'linkeddata'
require 'pry'
require_relative '../lib/lib.rb'


project_root = Pathname.new(File.dirname(__FILE__)).join('..')

out_file = project_root.join('data/nt/scraped.nt')
node_prefix = URI.join('file:///', out_file.realdirpath.to_s)


media = ['radio', 'tv']
characters = ('A'..'Z').to_a + ['0-9']
scraped = []
base_url =  "http://www.ardmediathek.de"

#media = [ 'tv']
#characters = ['Z']

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

graph = RDF::Graph.new
scraped.each_with_index do |scrape, i|
  node = RDF::URI.new("#{node_prefix}/#{i}")
  graph <<  RDF::Statement(node, RDF::Vocab::DC11.type, ont('scraped_broadcast'))

  statements = [
   RDF::Statement(node, ont('title') ,       RDF::Literal.new(            scrape['title']                          ) ),
   RDF::Statement(node, ont('station') ,     RDF::Literal.new(            scrape['station']                        ) ),
   RDF::Statement(node, ont('description') , RDF::Literal.new(            scrape['ardMediathek'][0]['description'] ) ),
   RDF::Statement(node, ont('issues') ,      RDF::Literal::Integer.new(   scrape['issues']                         ) ),
   RDF::Statement(node, ont('medium') ,      map(scrape['medium']                                                  ) ),
   RDF::Statement(node, ont('character') ,   RDF::Literal.new(            scrape['character']                      ) ),
   RDF::Statement(node, ont('url') ,         RDF::Literal.new(            scrape['ardMediathekURL']                ) ),
   RDF::Statement(node, ont('imageUrl') ,    RDF::Literal.new(            scrape['ardMediathek'][0]['imageURL']    ) ),
   RDF::Statement(node, ont('mediathekId') , RDF::Literal::Integer.new(   scrape['bcastId']                        ) ),
  ]
  statements = statements.select {|s| s.predicate && s.object }
  statements.each {|s| graph << s }
end

RDF::Writer.open(out_file) { |writer| writer << graph }


