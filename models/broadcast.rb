class Broadcast < Spira::Base

  configure :base_uri => 'http://www.ardmediathek.de'

  property :title,       predicate: RDF::Vocab::DC.title, type: XSD.string

  property :station,     predicate: RDF::URI.new('http://rdf.rundfunk-mitbestimmen.de/ontology/bc/station'),     type: String
  property :description, predicate: RDF::URI.new('http://rdf.rundfunk-mitbestimmen.de/ontology/bc/description'), type: String
  property :issues,      predicate: RDF::URI.new('http://rdf.rundfunk-mitbestimmen.de/ontology/bc/issues'),      type: Integer
  property :medium,      predicate: RDF::URI.new('http://rdf.rundfunk-mitbestimmen.de/ontology/bc/medium'),      type: String
  property :url,         predicate: RDF::URI.new('http://rdf.rundfunk-mitbestimmen.de/ontology/bc/url'),         type: String
  property :imageUrl,    predicate: RDF::URI.new('http://rdf.rundfunk-mitbestimmen.de/ontology/bc/imageUrl'),    type: String

end
