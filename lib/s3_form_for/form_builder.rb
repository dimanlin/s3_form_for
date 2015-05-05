module ActionView::Helpers
  class FormBuilder
    def s3_file(method, options = {}, html_options = {})
      # '<div></div>'
      @template.content_tag('div', class: 'row') do
        @template.content_tag('div', class: 'col-md-12') do
          b = @template.content_tag('div', class: 'col-md-2') do
            a = @template.image_tag("fill.png", alt: "Fill", height: "90", id: "upload_thumbnail" )
            a << @template.hidden_field_tag("upload_s3_path", nil, id: 'upload_s3_path' )
          end

          b << @template.content_tag('div', class: 'col-md-9 last') do
            @template.content_tag('div', class: 'upload-picking') do
              c = @template.content_tag('div', class: 'upload-header') do
                'Please select file to upload:'
              end
              c << @template.content_tag('div', class: 'upload_main') do
                d = @template.content_tag('span', class: 'btn btn-success fileinput-button') do
                  a = @template.content_tag('i', nil, class: 'glyphicon glyphicon-plus')
                  a << @template.content_tag('span') do
                    e = @template.content_tag('span', "Add file")
                    e << @template.file_field_tag('file', class: "file-field", id: "file")
                    e
                  end
                  a
                end

                d << @template.content_tag('span', nil, id: 'file_name_for_upload')
                d
              end

              c << @template.content_tag('span', class: 'upload-footer') do
                @template.content_tag('p', "Accepted formats are: #{options[:accepted_formats].join(', ').upcase}") if options[:accepted_formats]
              end

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
          end
          b
        end
      end
    end
  end
end
