require 'rdf/blazegraph'
require 'sparql'
require 'pry'
require_relative '../lib/lib.rb'


options = {}
OptionParser.new do |opts|
  opts.on("-h", "--host=url", String, 'blazegraph sparql endpoint') do |url|
    options[:host] = url
  end
end.parse!
missing_arguments = [:host].select {|o| options[o].nil? }
missing_arguments.each { |a| raise OptionParser::MissingArgument.new(a) }

repo = RDF::Blazegraph::Repository.new(options[:host])

query = <<~QUERY
          Select ?broadcast ?scraped ?mediathekId
          Where {
            ?broadcast <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/primary_key> ?primaryKey .
            ?scraped <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/scraped> ?website .
            ?broadcast <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/mediathekId> ?mediathekId .
            ?scraped   <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/mediathekId> ?mediathekId .
          }
        QUERY

graph = RDF::Graph.new

def build_broadcast_query(uri)
  query = <<~BC
          Select ?title ?description ?medium
          Where {
            <#{uri}> <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/title> ?title .
            <#{uri}> <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/description> ?description .
            <#{uri}> <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/medium> ?medium .
          }
          BC
  SPARQL.parse(query)
end

def build_scraped_query(uri)
  query = <<~BC
          Select ?station ?issues ?url ?imageUrl
          Where {
            <#{uri}> <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/issues> ?issues .
            <#{uri}> <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/url> ?url .
            <#{uri}> <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/imageUrl> ?imageUrl .
            <#{uri}> <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/station> ?station .
          }
          BC
  SPARQL.parse(query)
end

sse = SPARQL.parse(query)
sse.execute(repo) do |result|
  node = result['broadcast']
  graph << RDF::Statement(node, RDF::Vocab::DC11.type, ont('broadcast'))
  graph << RDF::Statement(node, ont('mediathekId') , result['mediathekId'] )

  build_broadcast_query(result['broadcast']).execute(repo) do |b_result|
    graph << RDF::Statement(node, ont('description'), b_result['description'])
    graph << RDF::Statement(node, ont('title'),       b_result['title'])
    graph << RDF::Statement(node, ont("medium"),      b_result['medium'])
  end

  build_scraped_query(result['scraped']).execute(repo) do |s_result|
    graph << RDF::Statement(node, ont("station"),      s_result['station'])
    graph << RDF::Statement(node, ont("issues"),      s_result['issues'])
    graph << RDF::Statement(node, ont("url"),      s_result['url'])
    graph << RDF::Statement(node, ont("imageUrl"),      s_result['imageUrl'])
    graph << RDF::Statement(node, ont("issues"),      s_result['issues'])
  end
end


puts "Before: #{repo.count} triples"
puts "#{graph.count} statements in graph"
repo << graph.statements
puts "After: #{repo.count} triples"
