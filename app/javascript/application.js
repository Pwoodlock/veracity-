// Veracity - Main JavaScript Entry Point
// All dependencies are bundled locally for security

// Hotwire Turbo - Real-time page updates
import "@hotwired/turbo-rails"

// Stimulus - JavaScript framework for Rails
import { Application } from "@hotwired/stimulus"
const application = Application.start()
window.Stimulus = application

// ActionCable - WebSocket connections
import { createConsumer } from "@rails/actioncable"
const consumer = createConsumer()

// Export ActionCable for use in views (allows ActionCable.createConsumer() syntax)
window.ActionCable = { createConsumer: () => consumer }

// Connect ActionCable to Turbo Streams for real-time updates
// Note: Turbo.connectStreamSource is handled internally by turbo-rails

// ApexCharts - Charting library
import ApexCharts from "apexcharts"
window.ApexCharts = ApexCharts

// Theme Switcher - must run after DOM is ready
import "./theme-switcher.js"

// ApexCharts Theme Integration
import "./apex-charts-theme.js"

console.log("Veracity: Local assets loaded successfully")
