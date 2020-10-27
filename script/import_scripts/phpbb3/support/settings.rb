# frozen_string_literal: true

require 'csv'
require 'yaml'
require_relative '../../base'

module ImportScripts::PhpBB3
  class Settings
    def self.load(filename)
      yaml = YAML::load_file(filename)
      Settings.new(yaml)
    end

    attr_reader :site_name
    attr_reader :category_mapping

    attr_reader :import_anonymous_users
    attr_reader :import_attachments
    attr_reader :import_private_messages
    attr_reader :import_polls
    attr_reader :import_bookmarks
    attr_reader :import_passwords

    attr_reader :import_uploaded_avatars
    attr_reader :import_remote_avatars
    attr_reader :import_gallery_avatars

    attr_reader :use_bbcode_to_md

    attr_reader :original_site_prefix
    attr_reader :new_site_prefix
    attr_reader :base_dir
    attr_reader :permalinks

    attr_reader :username_as_name
    attr_reader :emojis

    attr_reader :database

    def initialize(yaml)
      import_settings = yaml['import']

      @site_name = import_settings['site_name']

      @category_mapping = setup_category_mapping(import_settings['category_mapping'])

      @import_anonymous_users = import_settings['anonymous_users']
      @import_attachments = import_settings['attachments']
      @import_private_messages = import_settings['private_messages']
      @import_polls = import_settings['polls']
      @import_bookmarks = import_settings['bookmarks']
      @import_passwords = import_settings['passwords']

      avatar_settings = import_settings['avatars']
      @import_uploaded_avatars = avatar_settings['uploaded']
      @import_remote_avatars = avatar_settings['remote']
      @import_gallery_avatars = avatar_settings['gallery']

      @use_bbcode_to_md = import_settings['use_bbcode_to_md']

      @original_site_prefix = import_settings['site_prefix']['original']
      @new_site_prefix = import_settings['site_prefix']['new']
      @base_dir = import_settings['phpbb_base_dir']
      @permalinks = PermalinkSettings.new(import_settings['permalinks'])

      @username_as_name = import_settings['username_as_name']
      @emojis = import_settings.fetch('emojis', [])

      @database = DatabaseSettings.new(yaml['database'])
    end

    def prefix(val)
      @site_name.present? ? "#{@site_name}:#{val}" : val
    end

    def setup_category_mapping(filename)
      return {} if !filename

      mapping = {}

      File.open(filename) do |file|
        csv = CSV.parse(file)
        header = csv.shift
        csv.each do |row|
          row = header.zip(row).to_h

          category = [
            row["Map to Discourse category or SKIP"]&.strip,
            row["Subcategory"]&.strip
          ]

          if category[0].blank? && category[1].present?
            puts "parent category is undefined for category (#{row["ID"]})"
            next
          end

          category.compact!
          tags = (row["Tags"] || "").split(",").map(&:strip).compact

          # If no category or tags were specified, this category is left
          # untouched
          next if category.blank? && tags.blank?

          mapping[row["ID"].to_i] = if category.any? { |cat| cat == "SKIP" }
            { skip?: true }
          else
            { category: category, tags: tags }
          end
        end
      end

      mapping
    end
  end

  class DatabaseSettings
    attr_reader :type
    attr_reader :host
    attr_reader :port
    attr_reader :username
    attr_reader :password
    attr_reader :schema
    attr_reader :table_prefix
    attr_reader :batch_size

    def initialize(yaml)
      @type = yaml['type']
      @host = yaml['host']
      @port = yaml['port']
      @username = yaml['username']
      @password = yaml['password']
      @schema = yaml['schema']
      @table_prefix = yaml['table_prefix']
      @batch_size = yaml['batch_size']
    end
  end

  class PermalinkSettings
    attr_reader :create_category_links
    attr_reader :create_topic_links
    attr_reader :create_post_links
    attr_reader :normalization_prefix

    def initialize(yaml)
      @create_category_links = yaml['categories']
      @create_topic_links = yaml['topics']
      @create_post_links = yaml['posts']
      @normalization_prefix = yaml['prefix']
    end
  end
end
