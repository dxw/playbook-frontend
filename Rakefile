require 'rake'

namespace :cache do
  desc 'Clear the cached content for an Outline document ID'
  task :clear_document, [:document_id] do |_task, args|
    document_id = args[:document_id]
    abort 'Usage: bundle exec rake "cache:clear_document[DOCUMENT_ID]"' if document_id.to_s.empty?

    require_relative 'lib/cache_service'
    deleted = CacheService.new.delete("document_#{document_id}")
    puts "Deleted #{deleted} cache entries for document #{document_id}"
  end

  desc 'Clear all Playbook cache entries'
  task :clear_all do
    require_relative 'lib/cache_service'
    deleted = CacheService.new.clear_all
    puts "Deleted #{deleted} Playbook cache entries"
  end
end
