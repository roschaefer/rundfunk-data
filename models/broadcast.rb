require_relative '../lib/lib.rb'
class Broadcast
  attr_accessor :title, :station, :genre, :url, :imageUrl, :issues, :description, :medium

  def initialize(title:, station:, issues:, imageUrl:, url:, description:, medium:)
    self.title = title
    self.station = station
    self.issues = issues
    self.imageUrl = imageUrl
    self.url = url
    self.description = description
    self.medium = medium
  end

  def to_rdf(graph_uri)
    node = RDF::URI.new(self.url)
    statements = []
    statements << RDF::Statement(node, RDF::Vocab::DC11.type, ont('broadcast'), graph_name: graph_uri)
    statements << RDF::Statement(node, ont('scraped'), graph_uri, graph_name: graph_uri)

    statements <<  RDF::Statement(node, ont('title'),       RDF::Literal.new(self.title),           graph_name: graph_uri)
    statements <<  RDF::Statement(node, ont('station'),     RDF::Literal.new(self.station),         graph_name: graph_uri)
    statements <<  RDF::Statement(node, ont('description'), RDF::Literal.new(self.description),     graph_name: graph_uri)
    statements <<  RDF::Statement(node, ont('issues'),      RDF::Literal::Integer.new(self.issues), graph_name: graph_uri)
    statements <<  RDF::Statement(node, ont('medium'),      map(self.medium),                       graph_name: graph_uri)
    statements <<  RDF::Statement(node, ont('url'),         RDF::Literal.new(self.url),             graph_name: graph_uri)
    statements <<  RDF::Statement(node, ont('imageUrl'),    RDF::Literal.new(self.imageUrl),        graph_name: graph_uri)
    statements.select {|s| s.predicate && s.object }
  end
end
