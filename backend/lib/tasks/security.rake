namespace :security do
  desc "Run security audit"
  task audit: :environment do
    puts "🔒 Running security audit..."
    
    # Check for vulnerable gems
    puts "\n📦 Checking for vulnerable gems..."
    begin
      require 'bundler/audit/cli'
      Bundler::Audit::CLI.start(['check'])
    rescue LoadError
      puts "⚠️  bundler-audit not installed. Run: bundle add bundler-audit --group development"
    end
    
    # Check environment variables
    puts "\n🔐 Checking environment variables..."
    required_vars = %w[RAILS_MASTER_KEY SECRET_KEY_BASE JWT_SECRET_KEY]
    missing_vars = required_vars.select { |var| ENV[var].blank? }
    
    if missing_vars.any?
      puts "❌ Missing required environment variables: #{missing_vars.join(', ')}"
    else
      puts "✅ All required environment variables are set"
    end
    
    # Check database security
    puts "\n🗄️  Checking database security..."
    if ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
      puts "✅ Using PostgreSQL (recommended)"
    else
      puts "⚠️  Consider using PostgreSQL for better security"
    end
    
    # Check SSL configuration
    puts "\n🔒 Checking SSL configuration..."
    if Rails.env.production?
      if Rails.application.config.force_ssl
        puts "✅ SSL is enforced in production"
      else
        puts "❌ SSL is not enforced in production"
      end
    else
      puts "ℹ️  SSL check skipped (not in production)"
    end
    
    # Check CORS configuration
    puts "\n🌐 Checking CORS configuration..."
    cors_origins = ENV['CORS_ORIGINS']
    if cors_origins.present?
      puts "✅ CORS origins configured: #{cors_origins}"
    else
      puts "⚠️  CORS origins not configured"
    end
    
    puts "\n✅ Security audit completed!"
  end

  desc "Check for suspicious activity in logs"
  task check_logs: :environment do
    puts "🔍 Checking for suspicious activity..."
    
    log_file = Rails.root.join('log', "#{Rails.env}.log")
    return puts "❌ Log file not found: #{log_file}" unless File.exist?(log_file)
    
    suspicious_patterns = [
      'SECURITY:',
      'Unauthorized',
      'SQL injection',
      'XSS attempt',
      'Suspicious request'
    ]
    
    suspicious_lines = []
    File.readlines(log_file).each_with_index do |line, index|
      suspicious_patterns.each do |pattern|
        if line.include?(pattern)
          suspicious_lines << { line_number: index + 1, line: line.strip }
          break
        end
      end
    end
    
    if suspicious_lines.any?
      puts "⚠️  Found #{suspicious_lines.count} suspicious log entries:"
      suspicious_lines.last(10).each do |entry|
        puts "  Line #{entry[:line_number]}: #{entry[:line]}"
      end
    else
      puts "✅ No suspicious activity found in recent logs"
    end
  end

  desc "Generate security report"
  task report: :environment do
    puts "📊 Generating security report..."
    
    report = {
      timestamp: Time.current,
      environment: Rails.env,
      security_checks: {}
    }
    
    # Check authentication
    report[:security_checks][:authentication] = {
      devise_enabled: defined?(Devise),
      jwt_enabled: defined?(JWT),
      confirmation_required: User.devise_modules.include?(:confirmable)
    }
    
    # Check authorization
    report[:security_checks][:authorization] = {
      role_based_access: User.roles.keys,
      admin_controller_exists: File.exist?(Rails.root.join('app/controllers/api/v1/admin/base_controller.rb'))
    }
    
    # Check data protection
    report[:security_checks][:data_protection] = {
      gdpr_compliance: User.column_names.include?('gdpr_consent_at'),
      soft_delete: User.column_names.include?('deleted_at'),
      data_retention: Booking.column_names.include?('data_retention_until')
    }
    
    # Check infrastructure
    report[:security_checks][:infrastructure] = {
      ssl_enforced: Rails.application.config.force_ssl,
      cors_configured: ENV['CORS_ORIGINS'].present?,
      rate_limiting: defined?(Rack::Attack)
    }
    
    # Save report
    report_file = Rails.root.join('tmp', 'security_report.json')
    File.write(report_file, JSON.pretty_generate(report))
    
    puts "✅ Security report saved to: #{report_file}"
    puts "\n📋 Summary:"
    puts "  Authentication: #{report[:security_checks][:authentication].values.all? ? '✅' : '⚠️'}"
    puts "  Authorization: #{report[:security_checks][:authorization].values.all? ? '✅' : '⚠️'}"
    puts "  Data Protection: #{report[:security_checks][:data_protection].values.all? ? '✅' : '⚠️'}"
    puts "  Infrastructure: #{report[:security_checks][:infrastructure].values.all? ? '✅' : '⚠️'}"
  end
end
