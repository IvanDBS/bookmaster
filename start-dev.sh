#!/bin/bash

echo "🚀 Starting BookMaster in DEVELOPMENT mode..."

# Stop any running containers
docker compose down

# Build and start containers with development config
docker compose -f docker-compose.dev.yml up --build -d

echo "✅ Development server started!"
echo "📱 Frontend: http://localhost:5173"
echo "🔧 API: http://localhost:3000"
echo "🗄️  Database: localhost:5433"
echo ""
echo "📋 Useful commands:"
echo "  docker compose -f docker-compose.dev.yml logs -f web      # Rails logs"
echo "  docker compose -f docker-compose.dev.yml logs -f frontend-dev # Frontend logs"
echo "  docker compose -f docker-compose.dev.yml exec web rails console # Rails console"
echo "  docker compose -f docker-compose.dev.yml down             # Stop all containers"
echo ""
echo "🔧 Setup database:"
echo "  docker compose -f docker-compose.dev.yml exec web rails db:create db:migrate db:seed"
