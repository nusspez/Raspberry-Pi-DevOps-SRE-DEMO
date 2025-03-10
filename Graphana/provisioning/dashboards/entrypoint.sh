#!/bin/bash
echo "Reemplazando variables en el JSON del dashboard..."
envsubst < /etc/grafana/provisioning/dashboards/RaspberryPiDashboards.json > /etc/grafana/provisioning/dashboards/dashboards_fixed.json

# Ejecutar Grafana
exec /run.sh