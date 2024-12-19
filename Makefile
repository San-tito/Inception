SRCS_PATH			:= ./srcs
DOCKER_COMPOSE		:= docker-compose
DOCKER_COMPOSE_FILE	:= $(SRCS_PATH)/docker-compose.yml

.PHONY: up start stop restart logs status ps clean

up:
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) up $(c)

start:
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) up -d $(c)

stop:
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) stop $(c)

restart: stop start

logs:
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) logs --tail=100 $(c)

status:
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) ps

ps: status

clean:
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) down
