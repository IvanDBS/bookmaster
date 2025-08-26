namespace :postgresql do
  desc "Check PostgreSQL version and JIT status"
  task check_jit: :environment do
    puts "=== PostgreSQL Version and JIT Status ==="

    # Check PostgreSQL version
    version_result = ActiveRecord::Base.connection.execute("SELECT version();")
    puts "PostgreSQL Version: #{version_result.first['version']}"

    # Check JIT settings
    jit_settings = ActiveRecord::Base.connection.execute(<<~SQL.squish)
      SELECT name, setting, unit, context#{' '}
      FROM pg_settings#{' '}
      WHERE name LIKE 'jit%'
      ORDER BY name;
    SQL

    puts "\n=== JIT Settings ==="
    jit_settings.each do |row|
      puts "#{row['name']}: #{row['setting']}#{" #{row['unit']}" if row['unit']} (#{row['context']})"
    end

    # Check if pg_stat_statements is available
    begin
      # First check if extension exists
      ext_result = ActiveRecord::Base.connection.execute("SELECT * FROM pg_extension WHERE extname = 'pg_stat_statements';")
      if ext_result.any?
        # Then try to access the view
        stat_result = ActiveRecord::Base.connection.execute("SELECT COUNT(*) as count FROM pg_stat_statements;")
        if stat_result.first['count'].to_i.positive?
          puts "\n✅ pg_stat_statements extension is loaded and working (#{stat_result.first['count']} queries tracked)"
        else
          puts "\n⚠️ pg_stat_statements extension is loaded but no queries tracked yet"
        end
      else
        puts "\n❌ pg_stat_statements extension is not installed"
      end
    rescue StandardError => e
      puts "\n❌ pg_stat_statements extension error: #{e.message}"
    end

    # Check JIT provider
    provider_result = ActiveRecord::Base.connection.execute("SELECT name, setting FROM pg_settings WHERE name = 'jit_provider';")
    puts "\nJIT Provider: #{provider_result.first['setting']}"

    # Check available JIT providers
    available_result = ActiveRecord::Base.connection.execute("SELECT name, setting FROM pg_settings WHERE name = 'jit_available_providers';")
    if available_result.any?
      puts "Available JIT Providers: #{available_result.first['setting']}"
    else
      puts "Available JIT Providers: Not available"
    end

    puts "\n=== JIT Status Summary ==="
    jit_status = ActiveRecord::Base.connection.execute("SELECT setting FROM pg_settings WHERE name = 'jit';")
    if jit_status.first['setting'] == 'on'
      puts "✅ JIT is ENABLED"
    else
      puts "❌ JIT is DISABLED"
    end
  end

  desc "Show JIT usage statistics"
  task jit_stats: :environment do
    puts "=== JIT Usage Statistics ==="

    begin
      # Check if pg_stat_statements is available
      stat_result = ActiveRecord::Base.connection.execute("SELECT * FROM pg_extension WHERE extname = 'pg_stat_statements';")

      if stat_result.any?
        # Show top queries by execution time
        top_queries = ActiveRecord::Base.connection.execute(<<~SQL.squish)
          SELECT#{' '}
            LEFT(query, 100) as query_preview,
            calls,
            ROUND(total_exec_time::numeric, 2) as total_time_ms,
            ROUND(mean_exec_time::numeric, 2) as mean_time_ms,
            ROUND((total_exec_time / calls)::numeric, 2) as avg_time_per_call_ms
          FROM pg_stat_statements#{' '}
          ORDER BY total_exec_time DESC#{' '}
          LIMIT 10;
        SQL

        puts "\nTop 10 queries by total execution time:"
        puts "#{'Query Preview'.ljust(50)}#{'Calls'.ljust(10)}#{'Total Time (ms)'.ljust(15)}#{'Mean Time (ms)'.ljust(15)}Avg/Call (ms)"
        puts "-" * 100

        top_queries.each do |row|
          puts row['query_preview'].to_s.ljust(50) +
               row['calls'].to_s.ljust(10) +
               row['total_time_ms'].to_s.ljust(15) +
               row['mean_time_ms'].to_s.ljust(15) +
               row['avg_time_per_call_ms'].to_s
        end
      else
        puts "❌ pg_stat_statements extension is not loaded"
        puts "To enable query statistics, add 'pg_stat_statements' to shared_preload_libraries"
      end
    rescue StandardError => e
      puts "❌ Error getting statistics: #{e.message}"
    end
  end

  desc "Test JIT performance with sample query"
  task test_jit: :environment do
    puts "=== JIT Performance Test ==="

    # Create a test table if it doesn't exist
    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      CREATE TABLE IF NOT EXISTS jit_test_table (
        id SERIAL PRIMARY KEY,
        value INTEGER,
        text_field TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      );
    SQL

    # Insert test data
    puts "Inserting test data..."
    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      INSERT INTO jit_test_table (value, text_field)
      SELECT#{' '}
        (random() * 1000)::integer,
        'test_' || generate_series(1, 10000)
      FROM generate_series(1, 10000);
    SQL

    # Test query that should trigger JIT
    puts "\nRunning JIT test query..."
    start_time = Time.zone.now

    result = ActiveRecord::Base.connection.execute(<<~SQL.squish)
      EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
      SELECT#{' '}
        value,
        COUNT(*) as count,
        AVG(value) as avg_value,
        SUM(value) as sum_value
      FROM jit_test_table#{' '}
      WHERE value > 500#{' '}
      GROUP BY value#{' '}
      HAVING COUNT(*) > 5
      ORDER BY count DESC;
    SQL

    end_time = Time.zone.now
    execution_time = (end_time - start_time) * 1000

    puts "\nQuery execution time: #{execution_time.round(2)}ms"
    puts "\nExecution plan:"
    result.each do |row|
      puts row['QUERY PLAN']
    end

    # Clean up
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS jit_test_table;")
    puts "\n✅ JIT test completed"
  end
end
