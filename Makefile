# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: sguzman <sguzman@student.42barcelona.com   +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/04/26 13:24:15 by sguzman           #+#    #+#              #
#    Updated: 2025/04/26 16:07:00 by sguzman          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

SRCS_PATH			:= ./srcs
DOCKER_COMPOSE		:= docker-compose
DOCKER_COMPOSE_FILE	:= $(SRCS_PATH)/docker-compose.yml

.PHONY: usage
usage:
	@$(DOCKER_COMPOSE) --help | awk '/^Usage:/ {print} /^Commands:/,0 {print}'

%:
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) $@ $(filter-out $@,$(MAKECMDGOALS))
