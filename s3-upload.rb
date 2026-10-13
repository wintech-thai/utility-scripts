
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
  transfer_manager = Aws::S3::TransferManager.new(client: s3)

  transfer_manager.upload_file(
    SOURCE_PATH,
    bucket: BUCKET_NAME,
    key: DESTINATION_PATH,
    on_chunk_sent: lambda { |bytes_transferred, total_transferred, total_size|
      transferred_bytes = total_transferred

      percent = (transferred_bytes * 100.0 / total_size).to_i
      percent = [percent, 100].min

      if percent != last_percent
        mb_done = transferred_bytes / 1024.0 / 1024.0
        mb_total = total_size / 1024.0 / 1024.0

        bar_width = 30
        filled = percent * bar_width / 100
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
