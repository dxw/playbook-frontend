require 'digest'

# Appends a content digest to static asset URLs so browsers fetch a fresh copy whenever the file changes.
class AssetPath
  @digests = {}

  def self.for(path, public_folder:, cache: false)
    file = File.join(public_folder, path)
    return path unless File.file?(file)

    digest = cache ? (@digests[file] ||= digest(file)) : digest(file)
    "#{path}?v=#{digest}"
  end

  def self.digest(file)
    Digest::MD5.file(file).hexdigest[0, 8]
  end

  def self.clear_cache
    @digests.clear
  end
end
