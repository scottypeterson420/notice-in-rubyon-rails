module Noticed
  module Model
    extend ActiveSupport::Concern

    included do
      self.inheritance_column = nil

      serialize :params, noticed_coder

      belongs_to :recipient, polymorphic: true

      scope :newest_first, -> { order(created_at: :desc) }
      scope :unread, -> { where(read_at: nil) }
      scope :read, -> { where.not(read_at: nil) }
    end

    class_methods do
      def mark_as_read!
        update_all(read_at: Time.current, updated_at: Time.current)
      end

      def mark_as_unread!
        update_all(read_at: nil, updated_at: Time.current)
      end

      def noticed_coder
        return Noticed::TextCoder unless table_exists?

        case attribute_types["params"].type
        when :json, :jsonb
          Noticed::Coder
        else
          Noticed::TextCoder
        end
      rescue ActiveRecord::NoDatabaseError
        Noticed::TextCoder
      end
    end

    # Rehydrate the database notification into the Notification object for rendering
    def to_notification
      @_notification ||= begin
        instance = type.constantize.with(params)
        instance.record = self
        instance.recipient = recipient
        instance
      end
    end

    def mark_as_read!
      update(read_at: Time.current)
    end

    def mark_as_unread!
      update(read_at: nil)
    end

    def unread?
      !read?
    end

    def read?
      read_at?
    end
  end
end
