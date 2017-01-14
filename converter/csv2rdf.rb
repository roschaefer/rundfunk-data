require 'linkeddata'
require 'csv'
require 'pry'
require_relative '../lib/lib'

project_root = Pathname.new(File.dirname(__FILE__)).join('..')

graph = RDF::Graph.new
CSV.foreach(project_root.join('data/csv/broadcasts.csv'), :headers => true) do |row|
  node = RDF::URI.new("http://rdf.rundfunk-mitbestimmen.de/broadcasts/#{row['id']}")
  graph << RDF::Statement(node, RDF::Vocab::DC11.type, ont('broadcast'))

  statements = [
    RDF::Statement(node, ont('description'), RDF::Literal.new(row['description'])),
    RDF::Statement(node, ont('title'), RDF::Literal.new(row['title'])),
    RDF::Statement(node, ont("medium"), map(row['medium']))
  ]
  statements = statements.select {|s| s.predicate && s.object }
  if row['mediathek_identification']
    statements << RDF::Statement(node, ont("mediathekId"), RDF::Literal::Integer.new(row['mediathek_identification']))
  end
  statements.each {|s| graph << s }
end

RDF::Writer.open(project_root.join('data/nt/broadcasts.nt')) { |writer| writer << graph }

