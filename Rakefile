require  'parseconfig'
Config = ParseConfig.new('rundfunk-data.conf')

require_relative "#{Config['backend_path']}/config/application"

Rails.application.load_tasks

namespace :graph do

  desc 'Update relational database with graph data'
  task :merge => [:environment] do
    require_relative 'merge/merge_scraped'
    run_query
  end

  desc 'Clean sparql endpoint'
  task :clean do
    require 'sparql'
    repo = RDF::Blazegraph::Repository.new(Config['sparql_endpoint'])
    repo.clear!
  end

  desc 'Convert relational data to graph data'
  task :backend => [:environment] do
    require_relative 'converter/db2rdf'
    convert
  end

  namespace :scrape do
    desc 'Scrape ARD mediathek'
    task :ard do
      require_relative 'scraper/ard'
      scrape
    end

    desc 'Scrape ZDF mediathek'
    task :zdf do
      require_relative 'scraper/zdf'
      scrape
    end
  end
end

desc 'Run default graph task'
task :graph => ['graph:scrape:ard']

