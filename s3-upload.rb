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
  transfer_manager = Aws::S3::TransferManager.new(client: s3)

  transfer_manager.upload_file(
    SOURCE_PATH,
    bucket: BUCKET_NAME,
    key: DESTINATION_PATH,
    on_chunk_sent: lambda { |bytes_transferred, total_transferred, total_size|
      percent = (total_transferred * 100.0 / total_size).to_i
      percent = [[percent, 0].max, 100].min

      @last_percent ||= -1

      if percent != @last_percent
        mb_done = [total_transferred, total_size].min / 1024.0 / 1024.0
        mb_total = total_size / 1024.0 / 1024.0

        bar_width = 30
        filled = percent * bar_width / 100
        bar = '#' * filled + '-' * (bar_width - filled)

        print "\r[#{bar}] %3d%% (%0.2f / %0.2f MB)" % [
          percent, mb_done, mb_total
        ]

        $stdout.flush
        @last_percent = percent
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
