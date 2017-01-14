require 'linkeddata'

def map(key)
  mapping = {
    'tv'     => RDF::URI.new("http://rdf.rundfunk-mitbestimmen.de/ontology/bc/tv"),
    'radio'  => RDF::URI.new("http://rdf.rundfunk-mitbestimmen.de/ontology/bc/radio"),
    'other'  => RDF::URI.new("http://rdf.rundfunk-mitbestimmen.de/ontology/bc/other"),
    'online' => RDF::URI.new("http://rdf.rundfunk-mitbestimmen.de/ontology/bc/online")
  }
  mapping[key]
end

def ont(prop)
  RDF::URI.new("http://rdf.rundfunk-mitbestimmen.de/ontology/bc/#{prop}")
end
