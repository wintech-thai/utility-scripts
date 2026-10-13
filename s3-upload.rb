#!/usr/bin/env ruby

require 'aws-sdk-s3'

# ==========================================
# Configuration
# ==========================================

S3_URL    = 'https://storage.googleapis.com'
S3_KEY    = 'YOUR_S3_KEY'
S3_SECRET = 'YOUR_S3_SECRET'

BUCKET_NAME      = 'your-bucket-name'
DESTINATION_PATH = 'backups/my-file.tar.gz'
SOURCE_PATH      = '/path/to/my-file.tar.gz'

REGION = 'auto'

# ==========================================
# S3 Client
# ==========================================

s3 = Aws::S3::Client.new(
  endpoint: S3_URL,
  access_key_id: S3_KEY,
  secret_access_key: S3_SECRET,
  region: REGION,
  force_path_style: true
)

# ==========================================
# Upload
# ==========================================

unless File.file?(SOURCE_PATH)
  abort "ERROR: Source file not found: #{SOURCE_PATH}"
end

puts "Uploading..."
puts "Source:      #{SOURCE_PATH}"
puts "Bucket:      #{BUCKET_NAME}"
puts "Destination: #{DESTINATION_PATH}"

begin
  File.open(SOURCE_PATH, 'rb') do |file|
    s3.put_object(
      bucket: BUCKET_NAME,
      key: DESTINATION_PATH,
      body: file
    )
  end

  puts 'Upload completed successfully!'

rescue Aws::S3::Errors::ServiceError => e
  warn "S3 upload failed: #{e.message}"
  exit 1
rescue StandardError => e
  warn "Error: #{e.message}"
  exit 1
end
