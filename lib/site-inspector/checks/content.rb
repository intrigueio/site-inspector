class SiteInspector
  class Endpoint
    class Content < Check
      # Given a path (e.g, "/data"), check if the given path exists on the canonical endpoint
      def path_exists?(path)
        endpoint.request(path: path, followlocation: true).success?
      end

      def document
        require 'nokogiri'
        @doc ||= Nokogiri::HTML response.body if response
      end
      alias_method :doc, :document

      def body
        @body ||= document.to_s.force_encoding("UTF-8").encode("UTF-8", :invalid => :replace, :replace => "")
      end

      def robots_txt?
        @bodts_txt ||= path_exists?("robots.txt")
      end

      def sitemap_xml?
        @sitemap_xml ||= path_exists?("sitemap.xml")
      end

      def humans_txt?
        @humans_txt ||= path_exists?("humans.txt")
      end

      def doctype
        document.internal_subset.name
      end

      def prefetch
        options = SiteInspector.typhoeus_defaults.merge(followlocation: true)
        ["robots.txt", "sitemap.xml", "humans.txt", random_path].each do |path|
          request = Typhoeus::Request.new(URI.join(endpoint.uri, path), options)
          SiteInspector.hydra.queue(request)
        end
        SiteInspector.hydra.run
      end

      def proper_404s?
        @proper_404s ||= !path_exists?(random_path)
      end

      def to_h
        prefetch
        {
          doctype:     doctype,
          sitemap_xml: sitemap_xml?,
          robots_txt:  robots_txt?,
          humans_txt:  humans_txt?,
          proper_404s: proper_404s?
        }
      end

      private

      def random_path
        require 'securerandom'
        @random_path ||= SecureRandom.hex
      end
    end
  end
end
