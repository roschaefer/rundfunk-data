require 'linkeddata'
require 'csv'
require 'pry'

def ont(prop)
  RDF::URI.new("http://rundfunk-mitbestimmen.de/ontology/bc/#{prop}")
end

medium_mapping = {}
['tv', 'radio', 'other', 'online'].each do |key|
  medium_mapping[key] = ont(key)
end

graph = RDF::Graph.new

CSV.foreach('broadcasts.csv', :headers => true) do |row|
  node = ont("id##{row['id']}")
  graph << RDF::Statement(node, RDF::Vocab::DC11.type, ont('broadcast'))

  statements = [
    RDF::Statement(node, ont('description'), RDF::Literal.new(row['description'])),
    RDF::Statement(node, ont('title'), RDF::Literal.new(row['title'])),
    RDF::Statement(node, ont("medium"), medium_mapping[row['medium']]),
    RDF::Statement(node, ont("mediathekId"), RDF::Literal::Integer.new(row['mediathek_identification'])),
  ]
  statements = statements.select {|s| s.predicate && s.object }
  statements.each {|s| graph << s }
end

RDF::Writer.open("broadcasts.nq", format: :nquads) { |writer| writer << graph }

