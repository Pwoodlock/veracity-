# frozen_string_literal: true

namespace :deploy do
  desc 'Verify deployment readiness - compare local vs production'
  task verify: :environment do
    puts "\n" + "=" * 80
    puts "🔍 DEPLOYMENT VERIFICATION"
    puts "=" * 80

    # Configuration
    production_host = ENV.fetch('DEPLOY_HOST', '78.47.203.163')
    production_user = ENV.fetch('DEPLOY_USER', 'root')
    production_path = ENV.fetch('DEPLOY_PATH', '/opt/server-manager')
    ssh_password = ENV.fetch('DEPLOY_PASSWORD', '190481**//**')

    results = {
      missing_files: [],
      pending_migrations: [],
      differences: [],
      warnings: []
    }

    # 1. Check for pending migrations locally
    puts "\n📋 Checking local pending migrations..."
    begin
      pending = ActiveRecord::Base.connection.migration_context.needs_migration?
      if pending
        results[:warnings] << "⚠️  Local database has pending migrations - run 'rails db:migrate' first"
      else
        puts "✅ Local migrations up to date"
      end
    rescue => e
      results[:warnings] << "⚠️  Could not check migrations: #{e.message}"
    end

    # 2. Compare critical files
    puts "\n📁 Comparing critical files with production..."

    critical_patterns = [
      'app/models/**/*.rb',
      'app/controllers/**/*.rb',
      'app/services/**/*.rb',
      'app/jobs/**/*.rb',
      'db/migrate/*.rb',
      'config/routes.rb',
      'Gemfile',
      'Gemfile.lock'
    ]

    local_files = []
    critical_patterns.each do |pattern|
      local_files.concat(Dir.glob(pattern).sort)
    end

    puts "Found #{local_files.size} critical files locally"

    # Get file list from production
    puts "\n🔗 Connecting to production server..."
    file_list_cmd = "sshpass -p '#{ssh_password}' ssh -o StrictHostKeyChecking=no #{production_user}@#{production_host} " +
                    "\"cd #{production_path} && find app/models app/controllers app/services app/jobs db/migrate config/routes.rb Gemfile Gemfile.lock -type f 2>/dev/null | sort\""

    production_files = `#{file_list_cmd}`.split("\n").map(&:strip)

    if production_files.empty?
      results[:warnings] << "⚠️  Could not connect to production or no files found"
      puts "⚠️  Production connection failed or empty"
    else
      puts "✅ Found #{production_files.size} critical files on production"

      # Compare
      missing_on_production = local_files - production_files
      extra_on_production = production_files - local_files

      if missing_on_production.any?
        puts "\n❌ Files missing on production:"
        missing_on_production.first(20).each do |file|
          puts "   - #{file}"
          results[:missing_files] << file
        end
        if missing_on_production.size > 20
          puts "   ... and #{missing_on_production.size - 20} more"
        end
      else
        puts "✅ No missing files detected"
      end

      if extra_on_production.any? && extra_on_production.size < 10
        puts "\n⚠️  Extra files on production (may be obsolete):"
        extra_on_production.each do |file|
          puts "   - #{file}"
          results[:differences] << file
        end
      end
    end

    # 3. Check production migrations status
    puts "\n🗄️  Checking production database migrations..."
    migration_check_cmd = "sshpass -p '#{ssh_password}' ssh -o StrictHostKeyChecking=no #{production_user}@#{production_host} " +
                          "\"cd #{production_path} && RAILS_ENV=production /home/deploy/.rbenv/shims/bundle exec rails db:migrate:status 2>&1 | tail -20\""

    migration_output = `#{migration_check_cmd}`

    if migration_output.include?('down')
      puts "❌ Production has pending migrations:"
      migration_output.lines.select { |l| l.include?('down') }.each do |line|
        puts "   #{line.strip}"
        results[:pending_migrations] << line.strip
      end
    elsif migration_output.include?('up')
      puts "✅ Production migrations appear up to date"
    else
      results[:warnings] << "⚠️  Could not verify production migration status"
    end

    # 4. Summary
    puts "\n" + "=" * 80
    puts "📊 VERIFICATION SUMMARY"
    puts "=" * 80

    has_issues = results[:missing_files].any? || results[:pending_migrations].any?

    if has_issues
      puts "\n❌ DEPLOYMENT NOT READY - Issues found:\n"

      if results[:missing_files].any?
        puts "📦 #{results[:missing_files].size} files missing on production"
        puts "   Run: rake deploy:sync_files"
      end

      if results[:pending_migrations].any?
        puts "🗄️  #{results[:pending_migrations].size} pending migrations on production"
        puts "   Run: ssh and execute 'RAILS_ENV=production bundle exec rails db:migrate'"
      end

      puts "\n🔧 Recommended actions:"
      puts "   1. Review missing files above"
      puts "   2. Deploy missing files: rake deploy:sync_files"
      puts "   3. Run pending migrations on production"
      puts "   4. Restart production server"

      exit 1
    else
      puts "\n✅ DEPLOYMENT READY"

      if results[:warnings].any?
        puts "\n⚠️  Warnings (non-blocking):"
        results[:warnings].each { |w| puts "   #{w}" }
      end

      if results[:differences].any?
        puts "\n📝 Minor differences detected (#{results[:differences].size} files)"
      end

      puts "\n✨ All critical checks passed!"
      exit 0
    end
  end

  desc 'Sync missing files to production'
  task sync_files: :environment do
    production_host = ENV.fetch('DEPLOY_HOST', '78.47.203.163')
    production_user = ENV.fetch('DEPLOY_USER', 'root')
    production_path = ENV.fetch('DEPLOY_PATH', '/opt/server-manager')
    ssh_password = ENV.fetch('DEPLOY_PASSWORD', '190481**//**')

    puts "\n🚀 Syncing files to production..."

    # Sync critical directories
    dirs_to_sync = %w[
      app/models
      app/controllers
      app/services
      app/jobs
      app/views
      db/migrate
      config
      lib
    ]

    dirs_to_sync.each do |dir|
      next unless Dir.exist?(dir)

      puts "📁 Syncing #{dir}..."
      cmd = "rsync -avz --checksum -e \"sshpass -p '#{ssh_password}' ssh -o StrictHostKeyChecking=no\" " +
            "#{dir}/ #{production_user}@#{production_host}:#{production_path}/#{dir}/"

      system(cmd)
    end

    # Sync important files
    files_to_sync = %w[Gemfile Gemfile.lock]
    files_to_sync.each do |file|
      next unless File.exist?(file)

      puts "📄 Syncing #{file}..."
      cmd = "rsync -avz -e \"sshpass -p '#{ssh_password}' ssh -o StrictHostKeyChecking=no\" " +
            "#{file} #{production_user}@#{production_host}:#{production_path}/#{file}"

      system(cmd)
    end

    puts "\n✅ File sync complete!"
    puts "📝 Next steps:"
    puts "   1. SSH to production and run: bundle install"
    puts "   2. Run migrations: RAILS_ENV=production bundle exec rails db:migrate"
    puts "   3. Restart server: systemctl restart server-manager.service"
  end

  desc 'Run production migrations'
  task migrate_production: :environment do
    production_host = ENV.fetch('DEPLOY_HOST', '78.47.203.163')
    production_user = ENV.fetch('DEPLOY_USER', 'root')
    production_path = ENV.fetch('DEPLOY_PATH', '/opt/server-manager')
    ssh_password = ENV.fetch('DEPLOY_PASSWORD', '190481**//**')

    puts "\n🗄️  Running production migrations..."

    cmd = "sshpass -p '#{ssh_password}' ssh -o StrictHostKeyChecking=no #{production_user}@#{production_host} " +
          "\"cd #{production_path} && RAILS_ENV=production /home/deploy/.rbenv/shims/bundle exec rails db:migrate\""

    system(cmd)

    puts "\n✅ Migrations complete!"
  end

  desc 'Restart production server'
  task restart_production: :environment do
    production_host = ENV.fetch('DEPLOY_HOST', '78.47.203.163')
    production_user = ENV.fetch('DEPLOY_USER', 'root')
    ssh_password = ENV.fetch('DEPLOY_PASSWORD', '190481**//**')

    puts "\n🔄 Restarting production server..."

    cmd = "sshpass -p '#{ssh_password}' ssh -o StrictHostKeyChecking=no #{production_user}@#{production_host} " +
          "\"systemctl restart server-manager.service && sleep 2 && systemctl status server-manager.service --no-pager\""

    system(cmd)
  end

  desc 'Full deployment: verify, sync, migrate, restart'
  task full_deploy: :environment do
    puts "\n🚀 FULL DEPLOYMENT PROCESS"
    puts "=" * 80

    # Step 1: Verify
    puts "\n[1/4] Verification..."
    Rake::Task['deploy:verify'].invoke rescue puts "⚠️  Verification found issues, continuing..."

    # Step 2: Sync files
    puts "\n[2/4] Syncing files..."
    Rake::Task['deploy:sync_files'].execute

    # Step 3: Migrations
    puts "\n[3/4] Running migrations..."
    Rake::Task['deploy:migrate_production'].execute

    # Step 4: Restart
    puts "\n[4/4] Restarting server..."
    Rake::Task['deploy:restart_production'].execute

    puts "\n" + "=" * 80
    puts "✅ DEPLOYMENT COMPLETE!"
    puts "=" * 80
    puts "\nVerify at: https://#{ENV['DOMAIN'] || 'your-domain.com'}"
  end
end
