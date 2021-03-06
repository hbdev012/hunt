require 'fast_stemmer'
require 'mongo_mapper'
require 'hunt/util'

module Hunt
  extend ActiveSupport::Concern

  included do
    before_save(:index_search_terms)
  end

  module ClassMethods
    def search_keys
      @search_keys ||= []
    end

    def searches(*keys)
      # Using a hash to support multiple indexes per document at some point
      key(:searches, Hash)
      @search_keys = keys
    end

    def search(term)
      # puts Util.to_stemmed_words(term).inspect
      where('searches.default' => Util.to_stemmed_words(term) )
    end

    def search_regex(term)
      # puts Util.to_stemmed_words(term).inspect
      where('searches.default' => Regexp.new(Util.to_stemmed_words(term).to_s) )
    end


  end

  module InstanceMethods
    def concatted_search_values
      self.class.search_keys.map do |key| 
        if key.to_s.include?(".")
          methods = key.split(".")
          object = self
          methods.each{|x| object = object.send(x) }
          object
        else
          send(key) 
        end
      end.flatten.join(' ')
    end

    def index_search_terms
      self.searches['default'] = Util.to_stemmed_words(concatted_search_values)
    end
  end
end
