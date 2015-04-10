module ApplicationHelper
  def s3_form_options(options)
    {
        id: options[:id],
        class: options[:class],
        method: "post",
        # authenticity_token: false,
        multipart: true,
        data: {
            callback_url: options[:callback_url],
            callback_method: options[:callback_method],
            callback_param: options[:callback_param]
        }.reverse_merge(options[:data] || {})
    }
  end

  def s3_uploader_fields(options)
    s3_uploader = S3DirectUpload::UploadHelper::S3Uploader.new(options)
    default_fields = s3_uploader.fields.map do |name, value|
      hidden_field_tag(name, value)
    end.join.html_safe
    default_fields << hidden_field_tag(:url, s3_uploader.url)
  end
end