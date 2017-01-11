require 'linkeddata'
require 'csv'
require 'pry'

def ont(prop)
  "http://rundfunk-mitbestimmen.de/ontology/bc/#{prop}"
end

medium_mapping = {}
['tv', 'radio', 'other', 'online'].each do |key|
  medium_mapping[key] = ont(key)
end

graph = RDF::Graph.new

CSV.foreach('broadcasts.csv', :headers => true) do |row|
  s = RDF::URI.new(ont("id##{row['id']}"))
  p = RDF::Vocab::DC11.type
  o = RDF::URI.new(ont('broadcast'))
  graph << RDF::Statement(s, p, o)


  ['title', 'description'].each do |header|
    p = RDF::URI.new(ont(header))
    o = RDF::Literal.new(row[header])
    graph << RDF::Statement(s, p, o)
  end

  p = RDF::URI.new(ont("medium"))
  o = RDF::URI.new(medium_mapping[row['medium']])
  graph << RDF::Statement(s, p, o)
end

RDF::Writer.open("broadcasts.nq", format: :nquads) { |writer| writer << graph }

