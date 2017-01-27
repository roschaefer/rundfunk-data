require 'rdf/blazegraph'
require 'sparql'
require 'pry'
require_relative '../lib/lib.rb'



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

#sse = SPARQL.parse(query)
#sse.execute(repo) do |result|
  #broadcast, scraped  = result['broadcast'], result['scraped']
  #graph << RDF::Statement(broadcast, RDF::Vocab::DC11.type, ont('broadcast'))
  #graph << RDF::Statement(broadcast, ont('mediathekId') , result['mediathekId'] )

  #build_broadcast_query(broadcast).execute(repo) do |b_result|
    #graph << RDF::Statement(broadcast, ont('description'), b_result['description'])
    #graph << RDF::Statement(broadcast, ont('title'),       b_result['title'])
    #graph << RDF::Statement(broadcast, ont("medium"),      b_result['medium'])
  #end

  #build_scraped_query(scraped).execute(repo) do |s_result|
    #graph << RDF::Statement(broadcast, ont("station"),      s_result['station'])
    #graph << RDF::Statement(broadcast, ont("issues"),      s_result['issues'])
    #graph << RDF::Statement(broadcast, ont("url"),      s_result['url'])
    #graph << RDF::Statement(broadcast, ont("imageUrl"),      s_result['imageUrl'])
    #graph << RDF::Statement(broadcast, ont("issues"),      s_result['issues'])
  #end
#end


#puts "Before: #{repo.count} triples"
#puts "#{graph.count} statements in graph"
#repo << graph.statements
#puts "After: #{repo.count} triples"

def get_all_stations
  query = <<~BC
          SELECT REDUCED ?station WHERE {
            ?scraped <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/station> ?station .
          }
          BC
  SPARQL.parse(query)
end

def run_query
  repo = RDF::Blazegraph::Repository.new(Config['sparql_endpoint'])
  query = <<~QUERY
          Select ?broadcast ?scraped ?mediathekId ?primaryKey
          Where {
            ?broadcast <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/primary_key> ?primaryKey .
            ?scraped <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/scraped> ?website .
            ?broadcast <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/mediathekId> ?mediathekId .
            ?scraped   <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/mediathekId> ?mediathekId .
          }
  QUERY

  stations = []
  get_all_stations.execute(repo).each_with_index do |row, i|
    puts row['station']
  end

  #sse = SPARQL.parse(query)
  #sse.execute(repo) do |result|
    #broadcast_uri, scraped_uri  = result['broadcast'], result['scraped']

    #b = Broadcast.find(result['primaryKey'].to_s.to_i)

    #build_scraped_query(scraped_uri).execute(repo) do |s_result|
      #s = stations.find {|s| s.name == s_result['station'].to_s } 
      #b.station = s
    #end

    #p b
  #end
end
