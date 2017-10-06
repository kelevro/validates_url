require 'active_model'
require 'active_support/i18n'
I18n.load_path += Dir[File.dirname(__FILE__) + "/locale/*.yml"]

module ActiveModel
  module Validations
    class UrlValidator < ActiveModel::EachValidator
      RESERVED_OPTIONS = [:schemes, :no_local]

      def initialize(options)
        options.reverse_merge!(:schemes => %w(http https))
        options.reverse_merge!(:message => :url)
        options.reverse_merge!(:no_local => false)

        super(options)
      end

      def validate_each(record, attribute, value)
        begin
          uri = URI.parse(value)

          if uri.blank?
            return record.errors.add(attribute, :url, filtered_options(value))
          end

          validate_host!(record, attribute, uri, value) if uri.host.present?
          validate_schema!(record, attribute, uri, value)
        rescue URI::InvalidURIError
          record.errors.add(attribute, :url, filtered_options(value))
        end
      end

      protected

      def validate_host!(record, attribute, uri, value)
        return if !options.fetch(:no_local) && uri.host.include?('localhost')
        return if uri.host.include?('.')
        record.errors.add(attribute, :host, filtered_options(value))
      end

      def validate_schema!(record, attribute, uri, value)
        schemes = [*options.fetch(:schemes)].map(&:to_s)
        return if schemes.include?(uri.scheme) && uri.host.present?
        record.errors.add(attribute, :schema)
      end

      def filtered_options(value)
        filtered = options.except(*RESERVED_OPTIONS)
        filtered[:value] = value
        filtered
      end
    end

    module ClassMethods
      # Validates whether the value of the specified attribute is valid url.
      #
      #   class Unicorn
      #     include ActiveModel::Validations
      #     attr_accessor :homepage, :ftpsite
      #     validates_url :homepage, :allow_blank => true
      #     validates_url :ftpsite, :schemes => ['ftp']
      #   end
      # Configuration options:
      # * <tt>:message</tt> - A custom error message (default is: "is not a valid URL").
      # * <tt>:allow_nil</tt> - If set to true, skips this validation if the attribute is +nil+ (default is +false+).
      # * <tt>:allow_blank</tt> - If set to true, skips this validation if the attribute is blank (default is +false+).
      # * <tt>:schemes</tt> - Array of URI schemes to validate against. (default is +['http', 'https']+)

      def validates_url(*attr_names)
        validates_with UrlValidator, _merge_attributes(attr_names)
      end
    end
  end
end
