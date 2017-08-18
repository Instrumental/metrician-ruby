begin
  require 'active_support/core_ext/hash/deep_merge'
rescue LoadError
  class Hash
    # active_support
    def deep_merge(other_hash, &block)
      dup.deep_merge!(other_hash, &block)
    end if !{}.respond_to?(:deep_merge)

    def deep_merge!(other_hash, &block)
      other_hash.each_pair do |current_key, other_value|
        this_value = self[current_key]

        self[current_key] = if this_value.is_a?(Hash) && other_value.is_a?(Hash)
          this_value.deep_merge(other_value, &block)
        else
          if block_given? && key?(current_key)
            block.call(current_key, this_value, other_value)
          else
            other_value
          end
        end
      end

      self
    end if !{}.respond_to?(:deep_merge!)
  end
end

begin
  require 'active_support/core_ext/string/inflections'
rescue LoadError
  class String
    # active_support
    def underscore
      camel_cased_word = self
      return camel_cased_word unless camel_cased_word =~ /[A-Z-]|::/
      word = camel_cased_word.to_s.gsub(/::/, '/')
      # word.gsub!(/(?:(?<=([A-Za-z\d]))|\b)(#{inflections.acronym_regex})(?=\b|[^a-z])/) { "#{$1 && '_'}#{$2.downcase}" }
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word    end
  end if !"".respond_to?(:underscore)
end


