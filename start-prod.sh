#!/bin/bash

echo "🚀 Starting BookMaster in PRODUCTION mode..."

# Stop any running containers
docker compose -f docker-compose.prod.yml down

# Build and start containers
docker compose -f docker-compose.prod.yml up --build -d

echo "✅ Production server started!"
echo "🌐 Frontend: http://book-master.ddns.net"
echo "🔧 API: http://book-master.ddns.net/api/v1"
echo ""
echo "📋 Useful commands:"
echo "  docker compose -f docker-compose.prod.yml logs -f web      # Rails logs"
echo "  docker compose -f docker-compose.prod.yml logs -f frontend # Frontend logs"
echo "  docker compose -f docker-compose.prod.yml exec web rails console # Rails console"
echo "  docker compose -f docker-compose.prod.yml down             # Stop all containers"
echo ""
echo "🔧 Setup database:"
echo "  docker compose -f docker-compose.prod.yml exec web rails db:create db:migrate db:seed"
