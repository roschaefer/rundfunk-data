require_relative '../models/broadcast.rb'

def scrape
 Spira.repository = RDF::Repository.new

  base_url = 'http://www.ardmediathek.de'
  conn = Faraday.new(url: base_url)

  response = conn.get('/appdata/servlet/tv/sendungAbisZ?json')
  js = JSON.parse(response.body)
  js['sections'][0]['modCons'][0]['mods'][0]['inhalte'].each do |section|
    section['inhalte'].each do |b|
      url = b['link']['url']
      #bjs = JSON.parse(Faraday.get(url).body)
      #description = bjs['sections'][0]['modCons'][0]['mods'][0]['inhalte'][0]['teaserText']
      broadcast = Broadcast.for(RDF::URI.new(url))
      broadcast.title= b['ueberschrift']
      broadcast.station= b['unterzeile']
      broadcast.issues= b['dachzeile'].gsub(/\D/, '').to_i
      broadcast.imageUrl= b['bilder'][0]['schemaUrl'].gsub('##width##', '648')
      broadcast.url= url
      broadcast.description=nil
      broadcast.medium= :tv
      broadcast.save!
    end
  end

  response = conn.get('appdata/servlet/radio?json')
  js = JSON.parse(response.body)
  js['sections'][0]['modCons'][0]['mods'][0]['inhalte'].each do |b|
      url = b['link']['url']
      #bjs = JSON.parse(Faraday.get(url).body)
      #description = bjs['sections'][0]['modCons'][0]['mods'][0]['inhalte'][0]['teaserText']
      broadcast = Broadcast.for(RDF::URI.new(url))
      broadcast.title= b['ueberschrift']
      broadcast.station= b['unterzeile']
      broadcast.issues= b['dachzeile'].gsub(/\D/, '').to_i
      broadcast.imageUrl= b['bilder'][0]['schemaUrl'].gsub('##width##', '648')
      broadcast.url= url
      broadcast.description= nil
      broadcast.medium= :radio
      broadcast.save
  end

  File.open("spira.nt", "w") {|f| f << Spira.repository.dump(:ntriples)}
end
