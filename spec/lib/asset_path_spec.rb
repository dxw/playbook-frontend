require 'spec_helper'
require 'tmpdir'

RSpec.describe AssetPath do
  around do |example|
    Dir.mktmpdir do |dir|
      @public_folder = dir
      FileUtils.mkdir_p(File.join(dir, 'assets'))
      example.run
    end
  end

  after { AssetPath.clear_cache }

  let(:public_folder) { @public_folder }
  let(:asset) { File.join(public_folder, 'assets', 'style.css') }

  describe '.for' do
    it 'appends a digest of the file contents' do
      File.write(asset, 'body { color: red; }')
      digest = Digest::MD5.hexdigest('body { color: red; }')[0, 8]

      expect(AssetPath.for('/assets/style.css', public_folder: public_folder)).to eq("/assets/style.css?v=#{digest}")
    end

    it 'changes the URL when the file contents change' do
      File.write(asset, 'body { color: red; }')
      before = AssetPath.for('/assets/style.css', public_folder: public_folder)
      File.write(asset, 'body { color: blue; }')

      expect(AssetPath.for('/assets/style.css', public_folder: public_folder)).not_to eq(before)
    end

    it 'reuses the first digest when caching is enabled' do
      File.write(asset, 'body { color: red; }')
      before = AssetPath.for('/assets/style.css', public_folder: public_folder, cache: true)
      File.write(asset, 'body { color: blue; }')

      expect(AssetPath.for('/assets/style.css', public_folder: public_folder, cache: true)).to eq(before)
    end

    it 'returns the path unchanged when the file does not exist' do
      expect(AssetPath.for('/assets/missing.css', public_folder: public_folder)).to eq('/assets/missing.css')
    end
  end
end
