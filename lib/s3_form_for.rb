require 's3_form_for/version'
require 'jquery-fileupload-rails' if defined?(Rails)

require 'base64'
require 'openssl'
require 'digest/sha1'

require 's3_form_for/config_aws'
require 's3_form_for/form_helper'
require 's3_form_for/form_builder'
require 's3_form_for/engine' if defined?(Rails)
require 's3_form_for/railtie' if defined?(Rails)

ActionView::Base.send(:include, S3DirectUpload::UploadHelper) if defined?(ActionView::Base)
