# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# For sample data management, we use dedicated rake tasks
# This allows easy addition and removal of test data without affecting real servers

puts "\n========================================="
puts "Database Seed File"
puts "========================================="
puts ""
puts "This seed file is kept minimal to avoid conflicts with real data."
puts ""
puts "For sample/test data, use these commands:"
puts ""
puts "  rails sample_data:add     # Add sample servers and data"
puts "  rails sample_data:list    # List current sample data"
puts "  rails sample_data:remove  # Remove all sample data"
puts "  rails sample_data:refresh # Refresh sample data (remove & re-add)"
puts ""
puts "Sample data is marked with special tags and can be safely removed"
puts "without affecting real servers from Salt minions."
puts "========================================="

# Add any essential seed data here that should always exist
# For example, default configurations, admin users, etc.

# Currently, no essential seed data is required
# The system will create servers automatically when Salt minions connect
