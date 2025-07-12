//= link_tree ../images
//= link_directory ../stylesheets/dbwatcher .css
//= link_directory ../javascripts/dbwatcher .js
//= link_directory ../javascripts/dbwatcher/vendor .js
//= link_directory ../javascripts/dbwatcher/core .js
//= link_directory ../javascripts/dbwatcher/services .js
//= link_directory ../javascripts/dbwatcher/components .js

// Core modules
//= require dbwatcher/core/errors
//= require dbwatcher/core/lifecycle
//= require dbwatcher/core/event_bus
//= require dbwatcher/core/utils
//= require dbwatcher/core/component_registry

// API Services
//= require dbwatcher/services/api/index
//= require dbwatcher/services/api/session_api
//= require dbwatcher/services/api/system_api
//= require dbwatcher/services/api/diagram_api
//= require dbwatcher/services/api/query_api
//= require dbwatcher/services/api/table_api

// Services
//= require dbwatcher/services/mermaid

// Components
//= require dbwatcher/components/base
//= require dbwatcher/components/dashboard
//= require dbwatcher/components/diagrams
//= require dbwatcher/components/summary
//= require dbwatcher/components/timeline
//= require dbwatcher/components/changes_table_hybrid

// Alpine Registrations
//= require dbwatcher/alpine_registrations

// Initialize
//= require dbwatcher/dbwatcher
//= require dbwatcher/auto_init
