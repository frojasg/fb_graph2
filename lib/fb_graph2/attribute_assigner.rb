module FbGraph2
  module AttributeAssigner
    extend ActiveSupport::Concern

    included do
      extend ClassMethods
      attr_accessor :raw_attributes
      cattr_accessor :registered_attributes
    end

    module ClassMethods
      def register_attributes(attributes)
        self.registered_attributes = attributes
        send :attr_accessor, *attributes.values.flatten
      end
    end

    def assign(attributes)
      self.raw_attributes = attributes
      self.class.registered_attributes.each do |type, keys|
        keys.each do |key|
          raw = attributes[key]
          if raw.present?
            value = case type
            when :raw
              raw
            when :date
              Date.parse raw
            when :time
              Time.parse raw
            when :timestamp
              Time.at raw
            when :application
              Application.new raw[:id], raw
            when :page
              Page.new raw[:id], raw
            when :pages
              Collection.new(raw).each do |_raw_|
                Page.new _raw_[:id], _raw_
              end
            when :profile
              as_profile raw
            when :profiles
              Collection.new(raw).each do |_raw_|
                as_profile _raw_
              end
            when :user
              User.new raw[:id], raw
            when :custom
              # NOTE: handle custom attributes in each class
            end
            self.send :"#{key}=", value
          end
        end
      end
    end

    def as_profile(raw)
      klass = if raw.include?(:namespace)
        Application
      elsif raw.include?(:category)
        Page
      else
        # TODO: needs to handle Event and Group here.
        User
      end
      klass.new raw[:id], raw
    end
  end
end