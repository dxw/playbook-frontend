require 'csv'

class UrlMapper
  def initialize(mapping_file = 'mapping_old_urls_to_new.csv')
    @mapping_file = mapping_file
    @mappings = load_mappings
  end

  def find_mapping(url)
    # Normalize URL to handle variations
    normalized_url = normalize_url(url)

    # Look for exact match
    exact_match = @mappings.find { |mapping| normalize_url(mapping[:old_url]) == normalized_url }
    return exact_match if exact_match

    # Look for partial matches (in case of trailing slashes, etc.)
    partial_matches = @mappings.select do |mapping|
      old_normalized = normalize_url(mapping[:old_url])
      old_normalized.include?(normalized_url) || normalized_url.include?(old_normalized)
    end

    partial_matches.first if partial_matches.any?
  end

  def get_redirect_url(url)
    mapping = find_mapping(url)
    return nil unless mapping

    # Extract path from the new URL
    mapping[:new_url] =~ %r{/doc/.*?-[a-zA-Z0-9]+$} ? ::Regexp.last_match(0) : nil
  end

  private

  def load_mappings
    return [] unless File.exist?(@mapping_file)

    mappings = []
    CSV.foreach(@mapping_file, headers: true) do |row|
      mappings << row.to_h.transform_keys(&:to_sym)
    end
    mappings
  rescue StandardError => e
    puts "Error loading mappings: #{e.message}"
    []
  end

  def normalize_url(url)
    return '' if url.nil? || url.empty?

    # Remove protocol and domain if present
    normalized = url.gsub(%r{^https?://[^/]+}, '')

    # Remove trailing slash
    normalized = normalized.chomp('/')

    # Ensure it starts with /
    normalized = "/#{normalized}" unless normalized.start_with?('/')

    normalized
  end
end
