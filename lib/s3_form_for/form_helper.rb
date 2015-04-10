module S3DirectUpload
  module UploadHelper

    def s3_form_for(object, options = {})
      options.deep_symbolize_keys!
      uploader = S3Uploader.new(options)
      form_for(object, uploader.form_options) do |f|
        uploader.fields.map do |name, value|
          hidden_field_tag(name, value)
        end.join.html_safe + yield(f)
      end
    end

    class S3Uploader
      def initialize(options)
        @key_starts_with = options[:key_starts_with] || "uploads/"
        @options = options.reverse_merge(
          aws_access_key_id: S3DirectUpload.config.access_key_id,
          aws_secret_access_key: S3DirectUpload.config.secret_access_key,
          bucket: options[:bucket] || S3DirectUpload.config.bucket,
          region: S3DirectUpload.config.region || "s3",
          url: S3DirectUpload.config.url,
          ssl: true,
          acl: "public-read",
          expiration: 10.hours.from_now.utc.iso8601,
          max_file_size: 500.megabytes,
          callback_method: "POST",
          callback_param: "file",
          key_starts_with: @key_starts_with,
          key: key
        )
      end

      def form_options
        {
          method: "post",
          multipart: true,
          data: {
            callback_url: @options[:callback_url],
            callback_method: @options[:callback_method],
            callback_param: @options[:callback_param]
          }.reverse_merge(@options[:data] || {})
        }.merge({html: @options[:html] || {}})
      end

      def fields
        {
          :key => @options[:key] || key,
          :acl => @options[:acl],
          "AWSAccessKeyId" => @options[:aws_access_key_id],
          :policy => policy,
          :signature => signature,
          :success_action_status => "201",
          'X-Requested-With' => 'xhr'
        }
      end

      def key
        @key ||= "#{@key_starts_with}{timestamp}-{unique_id}-#{SecureRandom.hex}/${filename}"
      end

      def url
        @options[:url] || "http#{@options[:ssl] ? 's' : ''}://#{@options[:region]}.amazonaws.com/#{@options[:bucket]}/"
      end

      def policy
        Base64.encode64(policy_data.to_json).gsub("\n", "")
      end

      def policy_data
        {
          expiration: @options[:expiration],
          conditions: [
            ["starts-with", "$utf8", ""],
            ["starts-with", "$key", @options[:key_starts_with]],
            ["starts-with", "$x-requested-with", ""],
            ["content-length-range", 0, @options[:max_file_size]],
            ["starts-with","$content-type", @options[:content_type_starts_with] ||""],
            {bucket: @options[:bucket]},
            {acl: @options[:acl]},
            {success_action_status: "201"}
          ] + (@options[:conditions] || [])
        }
      end

      def signature
        Base64.encode64(
          OpenSSL::HMAC.digest(

            OpenSSL::Digest.new('sha1'),
            @options[:aws_secret_access_key], policy
          )
        ).gsub("\n", "")
      end
    end
  end
end
