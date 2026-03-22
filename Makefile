
build:
	docker compose -f docker-compose.dev.yml build

clean:
	docker compose -f docker-compose.dev.yml down

dev:
	docker compose -f docker-compose.dev.yml up

server-shell:
	docker exec -it lincr_server sh
