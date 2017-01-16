require 'optparse'
require 'rdf/blazegraph'
require 'sparql'
require 'linkeddata'
require 'csv'
require 'pry'
require_relative '../lib/lib'



options = {}
OptionParser.new do |opts|
  opts.on("-i", "--input=file", String, 'input csv file') do |file|
    options[:input] = file
  end
  opts.on("-h", "--host=url", String, 'blazegraph sparql endpoint') do |url|
    options[:host] = url
  end
end.parse!
missing_arguments = [:input, :host].select {|o| options[o].nil? }
missing_arguments.each { |a| raise OptionParser::MissingArgument.new(a) }

graph = RDF::Graph.new
graph_uri = URI.join("https://rdf.rundfunk-mitbestimmen.de/")

CSV.foreach(options[:input], :headers => true) do |row|
  node = RDF::URI.new("http://rdf.rundfunk-mitbestimmen.de/broadcasts/#{row['id']}")
  graph << RDF::Statement(node, RDF::Vocab::DC11.type, ont('broadcast'), graph_name: graph_uri)

  statements = [
    RDF::Statement(node, ont('primary_key'), RDF::Literal.new(row['id'] ),          graph_name: graph_uri) ,
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

repo = RDF::Blazegraph::Repository.new(options[:host])
puts "Before: #{repo.count} triples"
repo << graph.statements
puts "After: #{repo.count} triples"
