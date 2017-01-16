require 'linkeddata'
require 'csv'
require 'pry'
require_relative '../lib/lib'

project_root = Pathname.new(File.dirname(__FILE__)).join('..')
format = :ntriples
out_file = project_root.join("data/rdf/broadcasts.#{format[0..1]}")

graph = RDF::Graph.new
graph_uri = URI.join('file:///', out_file.realdirpath.to_s)
CSV.foreach(project_root.join('data/csv/broadcasts.csv'), :headers => true) do |row|
  node = RDF::URI.new("http://rdf.rundfunk-mitbestimmen.de/broadcasts/#{row['id']}")
  graph << RDF::Statement(node, RDF::Vocab::DC11.type, ont('broadcast'), graph_name: graph_uri)

  statements = [
    RDF::Statement(node, ont('description'), RDF::Literal.new(row['description'] ), graph_name: graph_uri) ,
    RDF::Statement(node, ont('title'), RDF::Literal.new(row['title']             ), graph_name: graph_uri) ,
    RDF::Statement(node, ont("medium"), map(row['medium']                        ), graph_name: graph_uri)
  ]
  statements = statements.select {|s| s.predicate && s.object }
  if row['mediathek_identification']
    statements << RDF::Statement(node, ont("mediathekId"), RDF::Literal::Integer.new(row['mediathek_identification']), graph_name: graph_uri)
  end
  statements.each {|s| graph << s }
end

RDF::Writer.open(out_file, format: format) { |writer| writer << graph }

