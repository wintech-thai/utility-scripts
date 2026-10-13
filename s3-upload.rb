#!/usr/bin/env ruby

require 'aws-sdk-s3'

# ==========================================
# Configuration from Environment Variables
# ==========================================

S3_URL           = ENV.fetch('S3_URL', 'https://storage.googleapis.com')
S3_KEY           = ENV.fetch('S3_KEY')
S3_SECRET        = ENV.fetch('S3_SECRET')

BUCKET_NAME      = ENV.fetch('BUCKET_NAME')
DESTINATION_PATH = ENV.fetch('DESTINATION_PATH')
SOURCE_PATH      = ENV.fetch('SOURCE_PATH')

S3_REGION        = ENV.fetch('S3_REGION', 'auto')

# ==========================================
# Validate Source File
# ==========================================

unless File.file?(SOURCE_PATH)
  abort "ERROR: Source file not found: #{SOURCE_PATH}"
end

total_bytes = File.size(SOURCE_PATH)

if total_bytes.zero?
  abort "ERROR: Source file is empty: #{SOURCE_PATH}"
end

# ==========================================
# S3 Client
# ==========================================

s3 = Aws::S3::Client.new(
  endpoint: S3_URL,
  access_key_id: S3_KEY,
  secret_access_key: S3_SECRET,
  region: S3_REGION,
  force_path_style: true
)

# ==========================================
# Upload with Progress
# ==========================================

transferred_bytes = 0
last_percent = -1

puts "=========================================="
puts "S3 Upload"
puts "=========================================="
puts "Endpoint:    #{S3_URL}"
puts "Bucket:      #{BUCKET_NAME}"
puts "Destination: #{DESTINATION_PATH}"
puts "Source:      #{SOURCE_PATH}"
puts "File size:   #{format('%.2f MB', total_bytes / 1024.0 / 1024.0)}"
puts "------------------------------------------"

begin
  s3_resource = Aws::S3::Resource.new(client: s3)
  object = s3_resource.bucket(BUCKET_NAME).object(DESTINATION_PATH)

  object.upload_file(
    SOURCE_PATH,
    progress_callback: lambda { |bytes_transferred|
      transferred_bytes += bytes_transferred

      percent = [
        (transferred_bytes * 100.0 / total_bytes).to_i,
        100
      ].min

      if percent != last_percent
        mb_done = [transferred_bytes, total_bytes].min / 1024.0 / 1024.0
        mb_total = total_bytes / 1024.0 / 1024.0

        bar_width = 30
        filled = (percent * bar_width / 100.0).to_i
        bar = '#' * filled + '-' * (bar_width - filled)

        print "\r[#{bar}] %3d%% (%0.2f / %0.2f MB)" % [
          percent, mb_done, mb_total
        ]

        $stdout.flush
        last_percent = percent
      end
    }
  )

  puts "\n------------------------------------------"
  puts "Upload completed successfully!"
  puts "S3 URI: s3://#{BUCKET_NAME}/#{DESTINATION_PATH}"
  puts "=========================================="

rescue StandardError => e
  warn "\nUpload failed: #{e.class}: #{e.message}"
  exit 1
end
