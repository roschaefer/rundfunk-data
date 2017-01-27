require 'rdf/blazegraph'
require 'sparql'
require 'linkeddata'
require 'pry'
require_relative '../lib/lib'

Medium.class_eval do
  def to_uri
    RDF::URI.new("http://rdf.rundfunk-mitbestimmen.de/media/#{self.id}")
  end

  def to_rdf
    statements = [
      RDF::Statement(to_uri, RDF::Vocab::DC11.type, ont('medium')),
      RDF::Statement(to_uri, ont('name'), RDF::Literal.new(name)),
    ]
    statements.select {|s| s.predicate && s.object }
  end
end

Broadcast.class_eval do
  def to_uri
    RDF::URI.new("http://rdf.rundfunk-mitbestimmen.de/broadcasts/#{self.id}")
  end

  def to_rdf
    statements = [
      RDF::Statement(to_uri, RDF::Vocab::DC11.type, ont('broadcast')),
      RDF::Statement(to_uri, ont('primary_key'), RDF::Literal.new(id)) ,
      RDF::Statement(to_uri, ont('title'),       RDF::Literal.new(title)) ,
      RDF::Statement(to_uri, ont('description'), RDF::Literal.new(description)) ,
      RDF::Statement(to_uri, ont("medium"),      RDF::Literal.new(medium.name))
    ]
    if mediathek_identification
      statements << RDF::Statement(to_uri, ont("mediathekId"), RDF::Literal::Integer.new(mediathek_identification))
    end
    statements.select {|s| s.predicate && s.object }
  end
end


def convert
  graph = RDF::Graph.new
  graph_uri = URI.join("https://rdf.rundfunk-mitbestimmen.de/")

  Medium.find_each do |medium|
    medium.to_rdf.each {|s| graph << s }
  end

  Broadcast.find_each do |broadcast|
    broadcast.to_rdf.each {|s| graph << s }
  end

  repo = RDF::Blazegraph::Repository.new(Config['sparql_endpoint'])
  puts "Before: #{repo.count} triples"
  repo << graph.statements
  puts "After: #{repo.count} triples"
end
