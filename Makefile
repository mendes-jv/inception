DOCKER_COMPOSE=docker compose -f $(DOCKER_COMPOSE_FILE)
DOCKER_COMPOSE_FILE = ./srcs/docker-compose.yml
PROJECT_ENV_URL = https://raw.githubusercontent.com/mendes-jv/inception/srcs
DOMAIN_NAME = jovicto2.42.fr

all: install config build

verify_os:
	@echo "Verifying OS(Debian/Ubuntu)..."
	@if [ -r /etc/os-release ]; then \
		. /etc/os-release; \
		if [ "$$ID" = "debian" ] || [ "$$ID" = "ubuntu" ] || echo "$$ID_LIKE" | grep -qi debian; then \
			echo "OK: $$PRETTY_NAME detectado."; \
		else \
			echo "Error: Sistem is not supported: $$PRETTY_NAME"; exit 1; \
		fi; \
	else \
		echo "Error: /etc/os-release not found. Aborting."; exit 1; \
	fi;

install:
	@$(MAKE) verify_os

	sudo apt remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin --purge
	sudo apt autoremove -y

	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh ./get-docker.sh && rm ./get-docker.sh

	sudo usermod -aG docker $$(whoami)
	echo "%docker ALL=(ALL) NOPASSWD: /home/$$(whoami)/data/*" | sudo tee /etc/sudoers.d/docker
	@echo ""
	@echo "Docker installed successfully!"
	@docker --version
	@echo ""
	@docker compose version
	@echo ""
	
config:
	@$(MAKE) verify_os
	@echo "Getting the .env file..."
	@if [ ! -f ./srcs/.env ]; then \
		curl -fsSL "$(PROJECT_ENV_URL)/.env" -o ./srcs/.env; \
		else echo ".env file already exists!"; \
	fi
	@echo ""
	@echo ""

	@echo "Add $(DOMAIN_NAME) in /etc/hosts..."
		@if ! grep -q "$(DOMAIN_NAME)" /etc/hosts; then \
		echo "127.0.0.1 $(DOMAIN_NAME)" | sudo tee -a /etc/hosts > /dev/null; \
		else echo "$$(whoami).42.fr already exists in /etc/hosts!"; \
	fi
	
	@if [ ! -d "/home/$$(whoami)/data/mysql" ]; then \
		mkdir -p "/home/$$(whoami)/data/mysql"; \
	else \
		echo "Mysql data directory already exists!"; \
	fi
	@echo ""
	@echo ""

	@if [ ! -d "/home/$$(whoami)/data/wordpress" ]; then \
		mkdir -p "/home/$$(whoami)/data/wordpress"; \
	else \
		echo "Wordpress data directory already exists!"; \
	fi
	@echo ""
	@echo ""

build:
	@$(DOCKER_COMPOSE) up --build -d
kill:
	@$(DOCKER_COMPOSE) kill
down:
	@$(DOCKER_COMPOSE) down
clean:
	@containers_before=$$(docker ps -aq | wc -l); \
	echo "Number of containers in execution: $$containers_before";
	@$(DOCKER_COMPOSE) down -v > /dev/null

fclean: clean
	@sudo sed -i "/$(DOMAIN_NAME)/d" /etc/hosts;
	@images_before=$$(docker images -q | wc -l); \
	echo "Number of existing images: $$images_before";
	@if [ -d "$(HOME)/data" ]; then \
		echo "Removing $(HOME)/data..."; \
		sudo rm -rf "$(HOME)/data"; \
	else \
		echo "$(HOME)/data not existent. Skipping remove."; \
	fi
	@if [ -f srcs/.env ]; then \
		echo "Removing .env"; \
		sudo rm -rf srcs/.env; \
	else \
		echo "srcs/.env files not existent"; \
	fi
	@echo "Pruning Docker system..."
	@docker system prune -a -f >/dev/null
	@containers_after=$$(docker ps -aq | wc -l); \
	images_after=$$(docker images -q | wc -l); \
	echo "Number of contained that remained: $$containers_after"; \
	echo "Number of images that remained: $$images_after"

uninstall:
	sudo apt remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin --purge
	sudo apt autoremove -y
	sudo rm -r /etc/sudoers.d/docker || true

restart: clean build

.PHONY: build clean fclean down install kill restart uninstall verify_os config all
