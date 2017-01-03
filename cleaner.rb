require 'csv'
require 'pp'
require 'byebug'


def normalize(row)
  title, station = row['title'], row['station']
  separators = ['| Radio','///', '@', '-', '|', ':', '']
  patterns = separators.collect {|s| /^#{Regexp.escape(station)}\s*#{Regexp.escape(s)}\s+/i}
  patterns += separators.collect {|s| /\s+#{Regexp.escape(s)}\s*#{Regexp.escape(station)}$/i }
  new_title = patterns.inject(title) do |nt, pattern|
    nt.gsub(pattern, '')
  end
  row['title'] = new_title
  row['unnormalized_title'] = title
  row
end

TITLE_NONOS = [
  'Wir werden COSMO! Bitte neuen Feed abonnieren',

  # too unspecific
  "Film",
  "Film und Serie",
  "Film & Serie",
  "Film im NDR",
  "Film im rbb",
  "FilmMittwoch im Ersten",
  "Filme im Ersten"
]

STATION_NONOS = [
  'Deutsche Welle'
]

def poor?(row)
  poor = false
  poor ||= TITLE_NONOS.include?(row['title']) || STATION_NONOS.include?(row['station'])
  poor ||= row['title'].include?('(komplette Sendung)') || row['title'].include?('(ganze Sendung)')
  poor ||= row['description'].include?('Selbstverständlich können Sie Ihre Lieblingsfolgen weiterhin online nachhören oder downloaden.')
  poor
end


input = CSV.read("broadcasts.csv", headers: true)
titles = input['title']
first_indices = titles.map{|t| titles.index(t) }


result = []
input.each do |row|
  result << normalize(row)
end


# merge duplicates
first_indices.each_with_index do |fi,i|
  result[i]['duplicate'] = (fi != i)
  if result[i]['duplicate']
    former_description = result[fi]['description']
    new_description = result[i]['description']
    if new_description.length > former_description.length
      result[fi]['description'] = new_description
    end
  end
end



CSV.open("cleaned/broadcasts.csv", "w", write_headers: true, headers: result.first.headers ) do |csv|
  result.each do |row|
    unless poor?(row) || row['duplicate']
      csv << row
    else
      p row['title']
    end
  end
end
