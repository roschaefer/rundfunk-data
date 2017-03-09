require_relative '../lib/lib.rb'
require_relative '../models/broadcast.rb'

def scrape
  base_url = 'http://www.ardmediathek.de'
  conn = Faraday.new(url: base_url)
  broadcasts = []
  response = conn.get('/appdata/servlet/tv/sendungAbisZ?json')
  js = JSON.parse(response.body)
  js['sections'][0]['modCons'][0]['mods'][0]['inhalte'].each do |section|
    section['inhalte'].each do |b|
      url = b['link']['url']
      #bjs = JSON.parse(Faraday.get(url).body)
      #description = bjs['sections'][0]['modCons'][0]['mods'][0]['inhalte'][0]['teaserText']
      description = nil
      broadcasts << Broadcast.new(
        title: b['ueberschrift'],
        station: b['unterzeile'],
        issues: b['dachzeile'].gsub(/\D/, '').to_i,
        imageUrl: b['bilder'][0]['schemaUrl'].gsub('##width##', '648'),
        url: url,
        description: description,
        medium: :tv
      )
    end
  end
  response = conn.get('appdata/servlet/radio?json')
  js = JSON.parse(response.body)
  js['sections'][0]['modCons'][0]['mods'][0]['inhalte'].each do |b|
      url = b['link']['url']
      #bjs = JSON.parse(Faraday.get(url).body)
      #description = bjs['sections'][0]['modCons'][0]['mods'][0]['inhalte'][0]['teaserText']
      description = nil
      broadcasts << Broadcast.new(
        title: b['ueberschrift'],
        station: b['unterzeile'],
        issues: b['dachzeile'].gsub(/\D/, '').to_i,
        imageUrl: b['bilder'][0]['schemaUrl'].gsub('##width##', '648'),
        url: url,
        description: description,
        medium: :tv
      )
  end

  graph = RDF::Graph.new
  graph_uri = RDF::URI.new(base_url)
  broadcasts.each_with_index do |broadcast|
    broadcast.to_rdf(graph_uri).each {|s| graph << s }
  end

  RDF::Writer.open("hello.nt") { |writer| writer << graph }
end
