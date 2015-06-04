module ActionView::Helpers
  class FormBuilder
    def s3_preogress_bar
      c = @template.content_tag('div')
      c << @template.content_tag('div', class: 'upload_uploading hidden') do
        @template.content_tag('div', class: 'upload-header') do
          'Your file is uploading. Do not close your browser.'
        end

        @template.content_tag('div', class: 'upload-main') do
          @template.content_tag('div', class: 'progress progress-striped active') do
            @template.content_tag('div', nil, class: 'progress-bar bar')
          end
        end
      end

      c << @template.content_tag('div', class: 'upload_succeeded hidden') do
        @template.content_tag('div', class: 'upload-main') do
          @template.content_tag('h4', 'Upload complete')
        end
      end

      c << @template.content_tag('div', class: 'upload_failed hidden') do
        @template.content_tag('div', class: 'upload-main') do
          @template.content_tag('h4', "We couldn't upload your media file. Please ensure it is a valid image or video file.")
        end
      end
      c
    end

    def s3_file(method, options = {}, html_options = {})

      options = options.with_indifferent_access
      browser_name = Browser.new(:ua => options[:http_user_agent], :accept_language => "en-us").name

      all_formats = {}
      all_formats.merge!(options[:photo_formats]) if options[:photo_formats].present?
      all_formats.merge!(options[:video_formats]) if options[:video_formats].present?
      all_formats.merge!(options[:report_formats]) if options[:report_formats].present?
      all_formats.merge!(options[:dicom_formats]) if options[:dicom_formats].present?

      available_mime = all_formats.values

      accept_mime = case browser_name
                      when 'Firefox'
                        all_formats = []
                        all_formats << 'image/*'  if options[:photo_formats].present?
                        all_formats << 'video/*' if options[:video_formats].present?
                        all_formats << 'application/*' if options[:report_formats].present? || options[:dicom_formats].present?
                        all_formats
                      else
                        available_mime
                    end.join(', ')


      @template.content_tag('div', class: 'row') do
        @template.content_tag('div', class: 'col-md-12') do
          b = @template.content_tag('div', class: 'col-xs-3', id: "upload_thumbnail") do
            @template.image_tag("fill.png", alt: "Fill", height: "90" )
          end

          b << @template.content_tag('div', class: 'col-xs-9') do
            @template.content_tag('div', class: 'upload-picking') do
              c = @template.content_tag('div', class: 'upload-header') do
                'Please select file to upload:'
              end
              c << @template.content_tag('div', class: 'upload_main') do
                d = @template.content_tag('span', class: 'btn btn-success fileinput-button') do
                  a = @template.content_tag('i', nil, class: 'glyphicon glyphicon-plus')
                  a << @template.content_tag('span') do
                    e = @template.content_tag('span', "Add file")
                    e << @template.hidden_field_tag("upload_s3_path", nil, id: 'upload_s3_path')
                    e << @template.file_field_tag('file', class: "file-field", id: "file", accept: accept_mime, data: {available_mime: available_mime.join(' ')})
                    e
                  end
                  a
                end
                d << @template.content_tag('span', nil, id: 'file_name_for_upload')
                d
              end

              c << @template.content_tag('span', class: 'upload-footer') do
                z = @template.content_tag('p', "Accepted formats are:")
                [:photo, :video, :report, :dicom].map do |a|
                  if options["#{a}_formats"]
                    z << @template.content_tag('p') do
                      g = @template.content_tag('span') do
                        "#{a.upcase}: #{options["#{a}_formats"].keys.join(', ').upcase}"
                      end
                      if options["#{a}_link"].present?

                        link_options = { class: "btn btn-default btn-xs" }.merge(options["#{a}_link"][:link_options])
                        link_name = options["#{a}_link"][:link_options][:link_name]
                        link_options.delete('link_name')
                        g << @template.content_tag('a', link_options) do
                          link_name
                        end
                      end
                      g
                    end
                  end
                end
                z
              end
              unless options[:without_progress_bar]
                c << @template.content_tag('div', class: 'upload_uploading hidden') do
                  @template.content_tag('div', class: 'upload-header') do
                    'Your file is uploading. Do not close your browser.'
                  end

                  @template.content_tag('div', class: 'upload-main') do
                    @template.content_tag('div', class: 'progress progress-striped active') do
                      @template.content_tag('div', nil, class: 'progress-bar bar')
                    end
                  end
                end

                c << @template.content_tag('div', class: 'upload_succeeded hidden') do
                  @template.content_tag('div', class: 'upload-main') do
                    @template.content_tag('h4', 'Upload complete')
                  end
                end

                c << @template.content_tag('div', class: 'upload_failed hidden') do
                  @template.content_tag('div', class: 'upload-main') do
                    @template.content_tag('h4', "We couldn't upload your media file. Please ensure it is a valid image or video file.")
                  end
                end
              end
              c
            end
          end
          b
        end
      end
    end
  end
end
