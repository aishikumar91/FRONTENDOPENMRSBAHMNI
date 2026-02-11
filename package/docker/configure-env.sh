#!/bin/bash
# ============================================================================
# HealsFast USA - Runtime Environment Configuration Script
# ============================================================================
# This script runs at container startup to inject environment variables
# into the frontend application without requiring a rebuild
# ============================================================================

set -e

echo "=== HealsFast USA - Configuring Runtime Environment ==="

# Environment variables with defaults
BACKEND_BASE_URL="${BACKEND_BASE_URL:-}"
NODE_ENV="${NODE_ENV:-production}"
APP_NAME="${APP_NAME:-HealsFast USA}"

# Paths
APP_ROOT="/usr/share/nginx/html/bahmni"
ENV_CONFIG_FILE="${APP_ROOT}/env-config.js"

# Create runtime environment configuration file
cat > "${ENV_CONFIG_FILE}" << EOF
// ============================================================================
// HealsFast USA - Runtime Environment Configuration
// ============================================================================
// This file is auto-generated at container startup
// DO NOT EDIT MANUALLY - Changes will be overwritten
// ============================================================================

(function(window) {
  window.__env = window.__env || {};
  
  // Application settings
  window.__env.appName = '${APP_NAME}';
  window.__env.nodeEnv = '${NODE_ENV}';
  
  // Backend configuration
  window.__env.backendBaseUrl = '${BACKEND_BASE_URL}';
  
  // API endpoints (constructed from backend base URL)
  if (window.__env.backendBaseUrl) {
    window.__env.openmrsRestUrl = window.__env.backendBaseUrl + '/openmrs/ws/rest/v1';
    window.__env.bahmniRestUrl = window.__env.backendBaseUrl + '/openmrs/ws/rest/v1/bahmnicore';
    window.__env.fhirBaseUrl = window.__env.backendBaseUrl + '/openmrs/ws/fhir2/R4';
  }
  
  // Feature flags (can be extended)
  window.__env.features = {
    enableIPD: true,
    enableOT: true,
    enableADT: true,
    enableDocumentUpload: true
  };
  
  // Debug mode (always false in production)
  window.__env.debug = ${NODE_ENV} !== 'production';
  
}(this));
EOF

echo "✓ Environment configuration created at: ${ENV_CONFIG_FILE}"

# Inject env-config.js into all HTML files
if [ -d "${APP_ROOT}" ]; then
  echo "✓ Injecting environment configuration into HTML files..."
  
  # Find all index.html files and inject the script tag if not already present
  find "${APP_ROOT}" -name "index.html" -type f | while read -r html_file; do
    if ! grep -q "env-config.js" "${html_file}"; then
      # Inject before closing </head> tag
      sed -i 's|</head>|  <script src="/bahmni/env-config.js"></script>\n</head>|' "${html_file}"
      echo "  ✓ Injected into: ${html_file}"
    fi
  done
fi

# Display configuration summary
echo ""
echo "=== Configuration Summary ==="
echo "  App Name: ${APP_NAME}"
echo "  Environment: ${NODE_ENV}"
echo "  Backend URL: ${BACKEND_BASE_URL:-[Not configured - using localStorage]}"
echo "  Config File: ${ENV_CONFIG_FILE}"
echo ""

# If BACKEND_BASE_URL is not set, show warning
if [ -z "${BACKEND_BASE_URL}" ]; then
  echo "⚠ WARNING: BACKEND_BASE_URL is not set!"
  echo "  The application will use the 'host' value from localStorage."
  echo "  To configure backend URL, set BACKEND_BASE_URL environment variable."
  echo ""
fi

echo "=== Environment Configuration Complete ==="

