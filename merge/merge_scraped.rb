require 'rdf/blazegraph'
require 'sparql'
require 'pry'
require_relative '../lib/lib.rb'

repo = RDF::Blazegraph::Repository.new('http://localhost:9999/blazegraph/sparql')
project_root = Pathname.new(File.dirname(__FILE__)).join('..')
out_file = project_root.join('data/nt/out.nt')

query = <<~QUERY
          Select ?broadcast ?scraped ?mediathekId
          Where {
            ?broadcast <http://purl.org/dc/elements/1.1/type> <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/broadcast> .
            ?scraped <http://purl.org/dc/elements/1.1/type> <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/scraped_broadcast> .
            ?broadcast <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/mediathekId> ?mediathekId .
            ?scraped <http://rdf.rundfunk-mitbestimmen.de/ontology/bc/mediathekId> ?mediathekId .
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

RDF::Writer.open(out_file) { |writer| writer << graph }

