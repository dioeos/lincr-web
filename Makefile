POWERSHELL := /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe

build:
	docker compose -f docker-compose.dev.yml build

clean:
	docker compose -f docker-compose.dev.yml down

dev:
	docker compose -f docker-compose.dev.yml up

server-shell:
	docker exec -it lincr_server sh

connection:
	$(POWERSHELL) -NoExit -Command "Set-Location ~" && \
		adb reverse tcp:5173 tcp:5173 \
		adb reverse tcp:9000 tcp:9000 \
		adb reverse tcp:8088 tcp:8088 \
		adb reverse tcp:80	 tcp:80 \
