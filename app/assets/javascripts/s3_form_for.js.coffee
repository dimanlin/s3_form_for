#= require jquery-fileupload/basic
#= require jquery-fileupload/vendor/tmpl


$ = jQuery

$.fn.S3Uploader = (options) ->

  # support multiple elements
  if @length > 1
    @each ->
      $(this).S3Uploader options

    return this

  $uploadForm = this

  settings =
    path: ''
    additional_data: null
    before_add: null
    remove_completed_progress_bar: true
    remove_failed_progress_bar: false
    progress_bar_target: $uploadForm.find('.progress')
    click_submit_target: null
    allow_multiple_files: true
    used_fields: ['utf8', 'key', 'acl', 'AWSAccessKeyId', 'policy', 'signature', 'success_action_status', 'X-Requested-With', 'content-type', 'file', 'x-amz-server-side-encryption']
    disable_fields_after_submit: null
    allow_send_form_without_file: false

  selectors =
    s3_form: '#s3-uploader'
    submit: '#form_submit'
    cancel_upload: '#cancel_upload'
    s3_path_text_field: $('#s3-uploader').data('s3_path_text_field')
    main_form: $($('#s3-uploader').data('s3-path-text-field')).closest('form')
    disable_fields: 'textarea,input[type=text],input[type=checkbox],select'
    file_name_for_upload: '#file_name_for_upload'

  $.extend settings, options

  current_files = []
  forms_for_submit = []
  validation_form = true

  $uploadForm.find('.file-field').on 'change', ->
    # Populate thumb
    if this.files && this.files[0] && /^image/.test(this.files[0].type) && window.FileReader isnt 'undefined' && Modernizr.canvas
      # Browser supports File and Canvas APIs
      file = this.files[0]

      loadImage.parseMetaData file, (img) ->
        # Get orientation
        ornt = if img.exif? then img.exif.get("Orientation") else 1

        # Set thumbnail
        loadImage file, ((img) ->
            imgElem = $(img)
            imgElem.addClass 'img-responsive'
            container = $("#upload_thumbnail").parent()
            container.children().remove()
            container.css 'text-align': 'center'
            container.append imgElem
          ),
          maxHeight: 90
          orientation: ornt
          canvas: true
    else
      # Fallback; just use a placeholder
      $('#upload_thumbnail').show().attr('src', assetPath('media/mrx-placeholder-120x90.png'))

  console.log('1111111111111111111111111111111111111111')
  if settings.click_submit_target
    console.log('22222222222222222222222222222222222222')
    settings.click_submit_target.click =>
      validation_form = true
      $.each $uploadForm.find(settings.disable_fields_after_submit), (index, item) =>
        if $(item).attr('required') == 'required' && $(item).val().length == 0
          error_message = $('<label />', class: 'text-danger')
          error_message.text("can't be blank.")
          unless $(item).next().hasClass('text-danger')
            $(item).after(error_message)
          validation_form = false
          true
        else
          if $(item).next().hasClass('text-danger')
            $(item).next().remove()
          $(item).attr('disabled','disabled')

      if settings.allow_send_form_without_file && $uploadForm.find('#file_name_for_upload').text().length == 0
        $.each $uploadForm.find(settings.disable_fields_after_submit), (index, item) =>
          $(item).removeAttr('disabled')

      console.log('ccccccccccccccccccccccccc')
      console.log(validation_form)
      if  validation_form
#        form.submit() for form in forms_for_submit
        $(forms_for_submit).submit()
        #$('#form_submit').click()

      if settings.allow_send_form_without_file && $uploadForm.find('#file_name_for_upload').text().length == 0
        console.log('444444444444444444444444444444444444444444')
        true
      else
        console.log('55555555555555555555555555555555555555')
        false

  setUploadForm = ->
    $uploadForm.fileupload
      url: $uploadForm.data('s3-url')
      add: (e, data) ->
        file = data.files[0]
        file.unique_id = Math.random().toString(36).substr(2,16)
        unless settings.before_add and not settings.before_add(file)
          current_files.push data
          if $('#template-upload').length > 0
            data.context = $($.trim(tmpl("template-upload", file)))
            $(data.context).appendTo(settings.progress_bar_target || $uploadForm)
          else if !settings.allow_multiple_files
            data.context = settings.progress_bar_target
          if settings.click_submit_target
            if settings.allow_multiple_files
              forms_for_submit.push data
            else
              forms_for_submit = [data]
          else
            console.log('zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz')
            data.submit()

      send: (e, data) =>
        console.log('send')
        $uploadForm.trigger('show_cancel_button')
        $(selectors.cancel_upload).on 'click', (e) =>
          data.xhr().abort()
          $uploadForm.trigger('enable_all_field')
          $uploadForm.trigger('reset_s3_uploder')
          $uploadForm.trigger('show_submit_button')
          return false

      start: (e) ->
        console.log('start')
        $($uploadForm).find(".upload_picking").hide()
        $($uploadForm).find(".upload_uploading").show().removeClass "hidden"
        $("#upload_cancel_link").addClass "hidden"

      progress: (e, data) ->
        console.log('progress')
        if data.context
          progress = parseInt(data.loaded / data.total * 100, 10)
          data.context.find('.bar').css('width', progress + '%')

      done: (e, data) ->
        console.log('done')
        content = build_content_object $uploadForm, data.files[0], data.result

        callback_url = $uploadForm.data('callback-url')
        if callback_url
          content[$uploadForm.data('callback-param')] = content.url

          $.ajax
            type: $uploadForm.data('callback-method')
            url: callback_url
            data: content
            dataType: 'json'
            beforeSend: ( xhr, settings )       ->
              event = $.Event('ajax:beforeSend')
              $uploadForm.trigger(event, [xhr, settings])
              return event.result
            complete:   ( xhr, status )         ->
              event = $.Event('ajax:complete')
              $uploadForm.trigger(event, [xhr, status])
              return event.result
            success:    ( data, status, xhr )   ->
              event = $.Event('ajax:success')
              $uploadForm.trigger(event, [data, status, xhr])
              return event.result
            error:      ( xhr, status, error )  ->
              event = $.Event('ajax:error')
              $uploadForm.trigger(event, [xhr, status, error])
              return event.result

        data.context.remove() if data.context && settings.remove_completed_progress_bar # remove progress bar
        $uploadForm.trigger("s3_upload_complete", [content])

        current_files.splice($.inArray(data, current_files), 1) # remove that element from the array
        $uploadForm.trigger("s3_uploads_complete", [content]) unless current_files.length

      fail: (e, data) ->
        console.log('fail')
        content = build_content_object $uploadForm, data.files[0], data.result
        content.error_thrown = data.errorThrown

        data.context.remove() if data.context && settings.remove_failed_progress_bar # remove progress bar
        $uploadForm.trigger("s3_upload_failed", [content])

      formData: (form) ->
        console.log('formData 1')

        data = form.serializeArray()
        console.log('form data 1.2')
        console.log(data[0])
        valid_data = []
        for i in data
          console.log('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
          if $.inArray(i.name, settings.used_fields) == -1
            console.log('1.2.1')
          else
            console.log('1.2.2')
            valid_data.push(i)

        console.log('1.2.3')
        data = valid_data

        console.log('form data 1.3')
        console.log(data)
        fileType = ""
        if "type" of @files[0]
          fileType = @files[0].type
        data.push
          name: "content-type"
          value: fileType
        console.log('form datat 2')
        key = $uploadForm.data("key")
          .replace('{timestamp}', new Date().getTime())
          .replace('{unique_id}', @files[0].unique_id)
          .replace('{extension}', @files[0].name.split('.').pop())

        # substitute upload timestamp and unique_id into key
        key_field = $.grep data, (n) ->
          n if n.name == "key"

        if key_field.length > 0
          key_field[0].value = settings.path + key

        # IE <= 9 doesn't have XHR2 hence it can't use formData
        # replace 'key' field to submit form
        unless 'FormData' of window
          $uploadForm.find("input[name='key']").val(settings.path + key)
        console.log(data)
        data

    $uploadForm.on 'show_cancel_button', ->
      console.log('show_cancel_button')
      $(selectors.submit).hide()
      $(selectors.cancel_upload).removeClass('hide')


    $uploadForm.on 'enable_all_field', ->
      console.log('enable_all_field')
      $(selectors.s3_form).find(selectors.disable_fields).removeAttr('disabled')

    $uploadForm.on 'reset_s3_uploder', ->
      console.log('reset_s3_uploder')
      $('.upload_uploading').hide()
      $('.upload_picking').show()
      $('.progress-bar').removeAttr('style')

    $uploadForm.on 'show_submit_button', ->
      console.log('show_submit_button')
      $(selectors.submit).show()
      $(selectors.cancel_upload).addClass('hide')

    $uploadForm.on 'show_cancel_button', ->
      console.log('show_cancel_button')
      $(selectors.submit).hide()
      $(selectors.cancel_upload).removeClass('hide')

    $uploadForm.on 's3_upload_complete', (e, content) =>
      console.log('s3_upload_complete')
      $(selectors.s3_form).find(selectors.disable_fields).removeAttr('disabled')
      console.log('s3_upload_complete 1')
      $uploadForm.find(".upload_uploading").hide()
      console.log('s3_upload_complete 2')
      $uploadForm.find(".upload_finished").show().removeClass "hidden"
      console.log('s3_upload_complete 3')
      $(selectors.submit).removeClass("disabled").prop "disabled", false
      console.log('s3_upload_complete 4')
      $("#upload_skip_link").removeClass "hidden"
      console.log('s3_upload_complete 5')
      $("#upload_s3_path").val(content.filepath)
      console.log('s3_upload_complete 6')
      console.log(selectors)
      console.log(selectors.s3_form)
      $(selectors.s3_form).submit()
      console.log('s3_upload_complete end')

  build_content_object = ($uploadForm, file, result) ->
    console.log('zzzzzzzzzzzzzzzzzzzz')
    content = {}
    if result # Use the S3 response to set the URL to avoid character encodings bugs
      content.url            = $(result).find("Location").text()
      content.filepath       = $('<a />').attr('href', content.url)[0].pathname
    else # IE <= 9 retu      rn a null result object so we use the file object instead
      domain                 = $uploadForm.attr('action')
      content.filepath       = $uploadForm.find('input[name=key]').val().replace('/${filename}', '')
      content.url            = domain + content.filepath + '/' + encodeURIComponent(file.name)

    content.filename         = file.name
    content.filesize         = file.size if 'size' of file
    content.lastModifiedDate = file.lastModifiedDate if 'lastModifiedDate' of file
    content.filetype         = file.type if 'type' of file
    content.unique_id        = file.unique_id if 'unique_id' of file
    content.relativePath     = build_relativePath(file) if has_relativePath(file)
    content = $.extend content, settings.additional_data if settings.additional_data
    content

  has_relativePath = (file) ->
    console.log('xxxxxxxxxxxxxxxxxxxxx')
    file.relativePath || file.webkitRelativePath

  build_relativePath = (file) ->
    console.log('cccccccccccccccccccccc')
    file.relativePath || (file.webkitRelativePath.split("/")[0..-2].join("/") + "/" if file.webkitRelativePath)

  #public methods
  @initialize = ->
    console.log('dddddddddddddddddddddddddddddddddd')
    # Save key for IE9 Fix
    $uploadForm.data("key", $uploadForm.find("input[name='key']").val())

    setUploadForm()
    this

  @path = (new_path) ->
    settings.path = new_path

  @additional_data = (new_data) ->
    settings.additional_data = new_data

  @initialize()
