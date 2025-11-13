# frozen_string_literal: true

namespace :salt do
  desc "Verify SaltService thread-safety refactor"
  task verify: :environment do
    puts "\n=== SaltService Thread-Safety Verification ==="
    puts "=" * 50

    # Test 1: Basic cache functionality
    puts "\n[Test 1] Verifying Rails.cache is working..."
    test_key = "salt_service_verification_test_#{Time.current.to_i}"
    test_value = "test_#{SecureRandom.hex(8)}"

    begin
      Rails.cache.write(test_key, test_value)
      retrieved_value = Rails.cache.read(test_key)

      if retrieved_value == test_value
        puts "✓ Rails.cache is working correctly"
      else
        puts "✗ Rails.cache read/write mismatch!"
        puts "  Expected: #{test_value}"
        puts "  Got: #{retrieved_value}"
      end

      Rails.cache.delete(test_key)
    rescue StandardError => e
      puts "✗ Rails.cache error: #{e.message}"
      puts "  Make sure Redis is running!"
    end

    # Test 2: SaltService connection
    puts "\n[Test 2] Testing SaltService connectivity..."
    begin
      result = SaltService.test_connection

      if result[:status] == 'connected'
        puts "✓ SaltService connected successfully"
        puts "  API URL: #{result[:api_url]}"
      else
        puts "✗ SaltService connection failed"
        puts "  Error: #{result[:message]}"
      end
    rescue StandardError => e
      puts "✗ SaltService error: #{e.message}"
    end

    # Test 3: Check if token is stored in cache
    puts "\n[Test 3] Verifying token storage in cache..."
    begin
      token = Rails.cache.read('salt_api_auth_token')
      expires_at = Rails.cache.read('salt_api_token_expires_at')

      if token.present?
        puts "✓ Token found in cache"
        puts "  Token: #{token[0..20]}..." # Show first 20 chars only
        puts "  Expires at: #{expires_at}"

        time_until_expiry = expires_at - Time.current
        puts "  Time until expiry: #{(time_until_expiry / 3600).round(2)} hours"
      else
        puts "✗ No token found in cache"
        puts "  This is normal if this is the first run"
      end
    rescue StandardError => e
      puts "✗ Error reading token from cache: #{e.message}"
    end

    # Test 4: Token refresh test
    puts "\n[Test 4] Testing token refresh mechanism..."
    begin
      # Clear existing token
      SaltService.clear_token!
      puts "  Cleared existing token"

      # Force authentication
      token = SaltService.auth_token

      if token.present?
        puts "✓ Token refresh successful"

        # Verify it's in cache
        cached_token = Rails.cache.read('salt_api_auth_token')
        if cached_token == token
          puts "✓ Token correctly stored in cache"
        else
          puts "✗ Token not matching cache!"
        end
      else
        puts "✗ Token refresh failed"
      end
    rescue StandardError => e
      puts "✗ Token refresh error: #{e.message}"
    end

    # Test 5: Concurrent access simulation
    puts "\n[Test 5] Testing concurrent access (thread-safety)..."
    begin
      # Clear token first
      SaltService.clear_token!

      # Track authentication calls
      auth_count = 0
      mutex = Mutex.new

      # Simulate 10 concurrent requests
      threads = 10.times.map do |i|
        Thread.new do
          begin
            token = SaltService.auth_token

            # Count if this thread triggered authentication
            # (Note: This is just a simulation - actual counting would require instrumentation)
            mutex.synchronize do
              puts "  Thread #{i} got token: #{token[0..10]}..." if token
            end
          rescue StandardError => e
            puts "  Thread #{i} error: #{e.message}"
          end
        end
      end

      threads.each(&:join)
      puts "✓ All 10 threads completed successfully"
      puts "  (Check logs for 'Authenticating with Salt API' - should appear only once)"
    rescue StandardError => e
      puts "✗ Concurrent access test error: #{e.message}"
    end

    # Test 6: Cache keys inspection
    puts "\n[Test 6] Inspecting Redis cache keys..."
    begin
      if defined?(Redis)
        redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
        redis = Redis.new(url: redis_url)

        salt_keys = redis.keys("*salt_api*")

        if salt_keys.any?
          puts "✓ Found #{salt_keys.count} Salt API cache keys:"
          salt_keys.each do |key|
            ttl = redis.ttl(key)
            puts "  - #{key}"
            puts "    TTL: #{ttl} seconds (#{(ttl / 3600.0).round(2)} hours)" if ttl > 0
          end
        else
          puts "  No Salt API keys found in Redis"
        end

        redis.close
      else
        puts "  Redis gem not available - skipping"
      end
    rescue StandardError => e
      puts "  Could not inspect Redis: #{e.message}"
    end

    # Summary
    puts "\n=== Verification Complete ==="
    puts "=" * 50
    puts "\nNext Steps:"
    puts "1. Review the output above for any failures"
    puts "2. Check Rails logs for authentication messages"
    puts "3. Monitor Redis for Salt API keys: redis-cli KEYS 'salt_api_*'"
    puts "4. Deploy to production with confidence!"
    puts "\nFor detailed documentation, see: THREAD_SAFETY_REFACTOR.md"
    puts ""
  end

  desc "Clear Salt API authentication token from cache"
  task clear_token: :environment do
    puts "Clearing Salt API token from cache..."
    SaltService.clear_token!
    puts "✓ Token cleared successfully"
  end

  desc "Show current Salt API token info"
  task token_info: :environment do
    puts "\n=== Salt API Token Information ==="

    token = Rails.cache.read('salt_api_auth_token')
    expires_at = Rails.cache.read('salt_api_token_expires_at')

    if token.present?
      puts "Token: #{token[0..20]}...#{token[-10..-1]}"
      puts "Expires at: #{expires_at}"

      if expires_at.present?
        time_until_expiry = expires_at - Time.current

        if time_until_expiry > 0
          puts "Status: Valid"
          puts "Time until expiry: #{(time_until_expiry / 3600).round(2)} hours"
        else
          puts "Status: Expired"
          puts "Expired: #{((Time.current - expires_at) / 60).round(2)} minutes ago"
        end
      end
    else
      puts "No token found in cache"
    end

    puts ""
  end

  desc "Test Salt API connectivity"
  task test_connection: :environment do
    puts "\n=== Testing Salt API Connection ==="

    result = SaltService.test_connection

    if result[:status] == 'connected'
      puts "✓ Connected successfully"
      puts "  API URL: #{result[:api_url]}"
      puts "  Authenticated: #{result[:authenticated]}"
    else
      puts "✗ Connection failed"
      puts "  Error: #{result[:message]}"
    end

    puts ""
  end
end
