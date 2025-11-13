namespace :sample_data do
  desc "Add sample servers and data for testing the admin interface"
  task add: :environment do
    puts "\n========================================="
    puts "Adding Sample Data for Testing"
    puts "========================================="

    # Mark sample data with special tags
    SAMPLE_DATA_TAG = '[SAMPLE_DATA]'

    # Create sample servers
    servers_data = [
      {
        hostname: 'web-server-01',
        minion_id: 'sample-web-01.example.com',
        ip_address: '192.168.1.10',
        status: 'online',
        os_family: 'Debian',
        os_name: 'Ubuntu',
        os_version: '22.04',
        cpu_cores: 8,
        memory_gb: 16.0,
        disk_gb: 500.0,
        environment: 'production',
        location: 'us-east-1',
        provider: 'aws',
        tags: ['web', 'nginx', 'production', 'sample'],
        notes: "#{SAMPLE_DATA_TAG} Primary web server for customer-facing application",
        last_seen: Time.current,
        last_heartbeat: Time.current
      },
      {
        hostname: 'web-server-02',
        minion_id: 'sample-web-02.example.com',
        ip_address: '192.168.1.11',
        status: 'online',
        os_family: 'Debian',
        os_name: 'Ubuntu',
        os_version: '22.04',
        cpu_cores: 8,
        memory_gb: 16.0,
        disk_gb: 500.0,
        environment: 'production',
        location: 'us-east-1',
        provider: 'aws',
        tags: ['web', 'nginx', 'production', 'sample'],
        notes: "#{SAMPLE_DATA_TAG} Secondary web server for load balancing",
        last_seen: Time.current - 5.minutes,
        last_heartbeat: Time.current - 5.minutes
      },
      {
        hostname: 'db-master-01',
        minion_id: 'sample-db-01.example.com',
        ip_address: '192.168.1.20',
        status: 'online',
        os_family: 'RedHat',
        os_name: 'CentOS',
        os_version: '8.5',
        cpu_cores: 16,
        memory_gb: 64.0,
        disk_gb: 2000.0,
        environment: 'production',
        location: 'us-east-1',
        provider: 'aws',
        tags: ['database', 'postgresql', 'master', 'sample'],
        notes: "#{SAMPLE_DATA_TAG} Primary PostgreSQL database server",
        last_seen: Time.current - 2.minutes,
        last_heartbeat: Time.current - 2.minutes
      },
      {
        hostname: 'cache-server-01',
        minion_id: 'sample-cache-01.example.com',
        ip_address: '192.168.1.30',
        status: 'online',
        os_family: 'Debian',
        os_name: 'Debian',
        os_version: '11',
        cpu_cores: 4,
        memory_gb: 8.0,
        disk_gb: 100.0,
        environment: 'production',
        location: 'us-east-1',
        provider: 'aws',
        tags: ['cache', 'redis', 'production', 'sample'],
        notes: "#{SAMPLE_DATA_TAG} Redis cache server",
        last_seen: Time.current - 10.minutes,
        last_heartbeat: Time.current - 10.minutes
      },
      {
        hostname: 'staging-web-01',
        minion_id: 'sample-staging-01.example.com',
        ip_address: '192.168.2.10',
        status: 'online',
        os_family: 'Debian',
        os_name: 'Ubuntu',
        os_version: '22.04',
        cpu_cores: 4,
        memory_gb: 8.0,
        disk_gb: 200.0,
        environment: 'staging',
        location: 'us-west-2',
        provider: 'aws',
        tags: ['web', 'staging', 'sample'],
        notes: "#{SAMPLE_DATA_TAG} Staging environment web server",
        last_seen: Time.current - 30.minutes,
        last_heartbeat: Time.current - 30.minutes
      },
      {
        hostname: 'dev-server-01',
        minion_id: 'sample-dev-01.example.com',
        ip_address: '192.168.3.10',
        status: 'offline',
        os_family: 'Debian',
        os_name: 'Ubuntu',
        os_version: '20.04',
        cpu_cores: 2,
        memory_gb: 4.0,
        disk_gb: 100.0,
        environment: 'development',
        location: 'local',
        provider: 'virtualbox',
        tags: ['development', 'test', 'sample'],
        notes: "#{SAMPLE_DATA_TAG} Development test server",
        last_seen: Time.current - 2.hours,
        last_heartbeat: Time.current - 2.hours
      },
      {
        hostname: 'monitoring-01',
        minion_id: 'sample-monitor-01.example.com',
        ip_address: '192.168.1.40',
        status: 'maintenance',
        os_family: 'Debian',
        os_name: 'Ubuntu',
        os_version: '22.04',
        cpu_cores: 4,
        memory_gb: 8.0,
        disk_gb: 200.0,
        environment: 'production',
        location: 'us-east-1',
        provider: 'aws',
        tags: ['monitoring', 'prometheus', 'grafana', 'sample'],
        notes: "#{SAMPLE_DATA_TAG} Monitoring stack server - scheduled maintenance",
        last_seen: Time.current - 5.minutes,
        last_heartbeat: Time.current - 5.minutes
      },
      {
        hostname: 'backup-server-01',
        minion_id: 'sample-backup-01.example.com',
        ip_address: '192.168.1.50',
        status: 'offline',
        os_family: 'Debian',
        os_name: 'Ubuntu',
        os_version: '20.04',
        cpu_cores: 8,
        memory_gb: 32.0,
        disk_gb: 5000.0,
        environment: 'production',
        location: 'us-west-2',
        provider: 'aws',
        tags: ['backup', 'storage', 'sample'],
        notes: "#{SAMPLE_DATA_TAG} Backup storage server",
        last_seen: Time.current - 1.day,
        last_heartbeat: Time.current - 1.day
      }
    ]

    created_servers = []
    servers_data.each do |server_data|
      server = Server.find_or_create_by!(minion_id: server_data[:minion_id]) do |s|
        s.attributes = server_data
      end
      created_servers << server
      puts "✓ Created server: #{server.hostname} (#{server.minion_id})"
    end

    puts "\nCreating sample metrics for online servers..."

    # Create metrics for online servers
    created_servers.select { |s| s.status == 'online' }.each do |server|
      # Create recent metrics (last 24 hours, every 4 hours)
      6.times do |i|
        time_offset = (i * 4).hours.ago

        # Simulate realistic metrics with some variation
        base_cpu = case server.hostname
                   when /web/ then 40
                   when /db/ then 60
                   when /cache/ then 30
                   else 25
                   end

        base_memory = case server.hostname
                     when /db/ then 70
                     when /cache/ then 60
                     when /web/ then 50
                     else 40
                     end

        ServerMetric.create!(
          server: server,
          cpu_percent: (base_cpu + rand(-20.0..20.0)).clamp(5.0, 95.0).round(2),
          memory_percent: (base_memory + rand(-15.0..15.0)).clamp(10.0, 90.0).round(2),
          memory_used_gb: (server.memory_gb * base_memory / 100 * rand(0.8..1.2)).round(2),
          memory_total_gb: server.memory_gb,
          disk_usage: {
            '/' => {
              'total_gb' => server.disk_gb,
              'used_gb' => (server.disk_gb * rand(0.3..0.7)).round(2),
              'percent_used' => rand(30.0..70.0).round(2),
              'filesystem' => '/dev/sda1'
            },
            '/var' => {
              'total_gb' => 100,
              'used_gb' => rand(20.0..60.0).round(2),
              'percent_used' => rand(20.0..60.0).round(2),
              'filesystem' => '/dev/sda2'
            }
          },
          network_io: {
            'eth0' => {
              'rx_bytes' => rand(1000000..50000000),
              'tx_bytes' => rand(1000000..50000000),
              'rx_packets' => rand(10000..100000),
              'tx_packets' => rand(10000..100000)
            }
          },
          load_1m: (base_cpu / 100.0 * server.cpu_cores * rand(0.5..1.5)).round(2),
          load_5m: (base_cpu / 100.0 * server.cpu_cores * rand(0.4..1.2)).round(2),
          load_15m: (base_cpu / 100.0 * server.cpu_cores * rand(0.3..1.0)).round(2),
          process_count: rand(100..400),
          tcp_connections: rand(10..200),
          swap_percent: rand(0.0..25.0).round(2),
          collected_at: time_offset
        )
      end
      puts "✓ Created 6 metrics entries for: #{server.hostname}"
    end

    puts "\nCreating sample commands..."

    # Sample command templates
    command_samples = [
      { command_type: 'ping', command: 'test.ping', status: 'completed', exit_code: 0, output: 'True', duration: 0.1 },
      { command_type: 'shell', command: 'uptime', status: 'completed', exit_code: 0,
        output: ' 14:23:01 up 45 days,  3:21,  2 users,  load average: 0.52, 0.58, 0.59', duration: 0.5 },
      { command_type: 'shell', command: 'df -h', status: 'completed', exit_code: 0,
        output: "Filesystem      Size  Used Avail Use% Mounted on\n/dev/sda1       493G  123G  345G  27% /\n/dev/sda2        98G   45G   48G  49% /var", duration: 0.3 },
      { command_type: 'shell', command: 'systemctl status nginx', status: 'completed', exit_code: 0,
        output: "● nginx.service - nginx web server\n   Loaded: loaded (/lib/systemd/system/nginx.service; enabled)\n   Active: active (running) since Mon 2024-01-01 00:00:00 UTC; 45 days ago", duration: 0.2 },
      { command_type: 'shell', command: 'apt update', status: 'failed', exit_code: 1,
        error_output: 'E: Could not get lock /var/lib/apt/lists/lock - open (11: Resource temporarily unavailable)', duration: 1.5 },
      { command_type: 'metrics', command: 'status.all', status: 'completed', exit_code: 0,
        output: '{"load": {"1-min": 1.23, "5-min": 1.45, "15-min": 1.11}}', duration: 2.0 },
      { command_type: 'shell', command: 'free -m', status: 'completed', exit_code: 0,
        output: "              total        used        free      shared  buff/cache   available\nMem:          16384        8192        2048         512        6144        7680\nSwap:          4096         512        3584", duration: 0.1 },
      { command_type: 'shell', command: 'netstat -tuln | wc -l', status: 'completed', exit_code: 0,
        output: '42', duration: 0.8 }
    ]

    created_servers.sample(5).each do |server|
      command_samples.sample(rand(2..5)).each_with_index do |cmd_data, index|
        started_at = (60 - index * 10).minutes.ago

        Command.create!(
          server: server,
          command_type: cmd_data[:command_type],
          command: cmd_data[:command],
          arguments: {},
          status: cmd_data[:status],
          output: cmd_data[:output],
          error_output: cmd_data[:error_output],
          exit_code: cmd_data[:exit_code],
          duration_seconds: cmd_data[:duration] || rand(0.1..5.0).round(2),
          salt_job_id: "sample_#{Time.current.to_i}#{rand(1000..9999)}",
          started_at: started_at,
          completed_at: started_at + (cmd_data[:duration] || rand(0.1..5.0)).seconds
        )
      end
      puts "✓ Created sample commands for: #{server.hostname}"
    end

    puts "\n========================================="
    puts "Sample Data Successfully Created!"
    puts "========================================="
    puts "Servers:        #{Server.where("notes LIKE ?", "%#{SAMPLE_DATA_TAG}%").count}"
    puts "Metrics:        #{ServerMetric.joins(:server).where("servers.notes LIKE ?", "%#{SAMPLE_DATA_TAG}%").count}"
    puts "Commands:       #{Command.joins(:server).where("servers.notes LIKE ?", "%#{SAMPLE_DATA_TAG}%").count}"
    puts ""
    puts "Access the admin interface at: http://localhost:3001/avo"
    puts ""
    puts "To remove sample data, run: rails sample_data:remove"
    puts "========================================="
  end

  desc "Remove all sample data (keeps real servers/minions)"
  task remove: :environment do
    puts "\n========================================="
    puts "Removing Sample Data"
    puts "========================================="

    SAMPLE_DATA_TAG = '[SAMPLE_DATA]'

    # Find all sample servers
    sample_servers = Server.where("notes LIKE ? OR minion_id LIKE ?", "%#{SAMPLE_DATA_TAG}%", "sample-%")

    if sample_servers.empty?
      puts "No sample data found to remove."
      return
    end

    puts "Found #{sample_servers.count} sample servers to remove:"
    sample_servers.each do |server|
      puts "  - #{server.hostname} (#{server.minion_id})"
    end

    print "\nAre you sure you want to remove all sample data? (yes/no): "
    confirmation = STDIN.gets.chomp.downcase

    if confirmation == 'yes'
      # Delete associated data first
      metrics_count = ServerMetric.where(server_id: sample_servers.pluck(:id)).delete_all
      commands_count = Command.where(server_id: sample_servers.pluck(:id)).delete_all
      servers_count = sample_servers.delete_all

      puts "\n✓ Removed #{metrics_count} metrics"
      puts "✓ Removed #{commands_count} commands"
      puts "✓ Removed #{servers_count} servers"
      puts "\nSample data successfully removed!"
    else
      puts "\nOperation cancelled."
    end
  end

  desc "List all sample data in the system"
  task list: :environment do
    puts "\n========================================="
    puts "Current Sample Data"
    puts "========================================="

    SAMPLE_DATA_TAG = '[SAMPLE_DATA]'

    sample_servers = Server.where("notes LIKE ? OR minion_id LIKE ?", "%#{SAMPLE_DATA_TAG}%", "sample-%")

    if sample_servers.empty?
      puts "No sample data found in the system."
      puts ""
      puts "To add sample data, run: rails sample_data:add"
    else
      puts "\nSample Servers:"
      puts "---------------"
      sample_servers.each do |server|
        status_color = case server.status
                      when 'online' then "\e[32m"    # green
                      when 'offline' then "\e[31m"    # red
                      when 'maintenance' then "\e[33m" # yellow
                      else "\e[37m"                    # white
                      end

        puts "#{status_color}● \e[0m#{server.hostname.ljust(20)} #{server.status.ljust(12)} #{server.environment.ljust(12)} #{server.ip_address}"
      end

      metrics_count = ServerMetric.joins(:server).where("servers.notes LIKE ?", "%#{SAMPLE_DATA_TAG}%").count
      commands_count = Command.joins(:server).where("servers.notes LIKE ?", "%#{SAMPLE_DATA_TAG}%").count

      puts "\nSummary:"
      puts "--------"
      puts "Sample Servers:  #{sample_servers.count}"
      puts "Sample Metrics:  #{metrics_count}"
      puts "Sample Commands: #{commands_count}"
      puts ""
      puts "To remove sample data, run: rails sample_data:remove"
    end

    # Also show real servers if any
    real_servers = Server.where.not(id: sample_servers.pluck(:id))
    if real_servers.any?
      puts "\n========================================="
      puts "Real Servers (from Salt Minions)"
      puts "========================================="
      real_servers.each do |server|
        status_color = case server.status
                      when 'online' then "\e[32m"    # green
                      when 'offline' then "\e[31m"    # red
                      else "\e[37m"                    # white
                      end

        puts "#{status_color}● \e[0m#{server.hostname.ljust(20)} #{server.minion_id.ljust(30)} #{server.ip_address}"
      end
      puts "\nTotal real servers: #{real_servers.count}"
    end
  end

  desc "Refresh sample data (remove and re-add)"
  task refresh: :environment do
    puts "\n========================================="
    puts "Refreshing Sample Data"
    puts "========================================="

    # First remove existing sample data
    SAMPLE_DATA_TAG = '[SAMPLE_DATA]'
    sample_servers = Server.where("notes LIKE ? OR minion_id LIKE ?", "%#{SAMPLE_DATA_TAG}%", "sample-%")

    if sample_servers.any?
      metrics_count = ServerMetric.where(server_id: sample_servers.pluck(:id)).delete_all
      commands_count = Command.where(server_id: sample_servers.pluck(:id)).delete_all
      servers_count = sample_servers.delete_all

      puts "Removed existing sample data:"
      puts "  - #{servers_count} servers"
      puts "  - #{metrics_count} metrics"
      puts "  - #{commands_count} commands"
      puts ""
    end

    # Now add fresh sample data
    Rake::Task['sample_data:add'].invoke
  end
end

desc "Shortcut for sample_data:add"
task sample_data: 'sample_data:add'