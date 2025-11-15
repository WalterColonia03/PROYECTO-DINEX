.PHONY: help init validate plan apply destroy lint test deploy-lambda clean output

# Variables
ENV ?= dev
REGION ?= us-east-1
TF_DIR = infra/environments/$(ENV)
BACKEND_DIR = backend

# Colores para output
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m # No Color

help: ## Mostrar esta ayuda
	@echo "$(GREEN)DINEX Perú - Infraestructura como Código$(NC)"
	@echo ""
	@echo "Comandos disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Uso: make <comando> ENV=<dev|prod>"
	@echo "Ejemplo: make init ENV=dev"

init: ## Inicializar Terraform para el ambiente especificado
	@echo "$(GREEN)Inicializando Terraform para ambiente: $(ENV)$(NC)"
	cd $(TF_DIR) && terraform init -upgrade

validate: ## Validar configuración de Terraform
	@echo "$(GREEN)Validando configuración Terraform...$(NC)"
	cd $(TF_DIR) && terraform fmt -check -recursive
	cd $(TF_DIR) && terraform validate

plan: ## Mostrar plan de ejecución de Terraform
	@echo "$(GREEN)Generando plan de Terraform para: $(ENV)$(NC)"
	cd $(TF_DIR) && terraform plan -out=tfplan

apply: ## Aplicar cambios de Terraform
	@echo "$(YELLOW)¿Aplicar cambios a $(ENV)? [y/N]$(NC)"
	@read -r confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "$(GREEN)Aplicando cambios...$(NC)"
	cd $(TF_DIR) && terraform apply tfplan

destroy: ## Destruir infraestructura
	@echo "$(RED)¡PELIGRO! ¿Destruir infraestructura de $(ENV)? [y/N]$(NC)"
	@read -r confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "$(RED)Destruyendo infraestructura...$(NC)"
	cd $(TF_DIR) && terraform destroy -auto-approve

lint: ## Ejecutar análisis estático (tflint + checkov)
	@echo "$(GREEN)Ejecutando análisis estático...$(NC)"
	@echo "$(YELLOW)Ejecutando terraform fmt...$(NC)"
	terraform fmt -recursive infra/
	@echo "$(YELLOW)Ejecutando tflint...$(NC)"
	-tflint infra/ || echo "$(YELLOW)tflint no instalado, saltando...$(NC)"
	@echo "$(YELLOW)Ejecutando checkov...$(NC)"
	-checkov -d infra/ --framework terraform --quiet || echo "$(YELLOW)checkov no instalado, saltando...$(NC)"

output: ## Mostrar outputs de Terraform
	@echo "$(GREEN)Outputs de Terraform para $(ENV):$(NC)"
	cd $(TF_DIR) && terraform output -json

bootstrap: ## Crear backend S3 para estado remoto de Terraform
	@echo "$(GREEN)Creando bootstrap (S3 backend)...$(NC)"
	cd infra/bootstrap && terraform init
	cd infra/bootstrap && terraform apply -auto-approve
	@echo "$(GREEN)Bootstrap completado. Ahora ejecuta: make init ENV=dev$(NC)"

deploy-lambda: ## Empaquetar y preparar funciones Lambda
	@echo "$(GREEN)Empaquetando funciones Lambda...$(NC)"
	$(MAKE) package-lambda FUNCTION=ordenes
	$(MAKE) package-lambda FUNCTION=tracking
	$(MAKE) package-lambda FUNCTION=rutas
	$(MAKE) package-lambda FUNCTION=notificaciones
	@echo "$(GREEN)Todas las funciones Lambda empaquetadas.$(NC)"

package-lambda: ## Empaquetar una función Lambda específica
	@echo "$(YELLOW)Empaquetando función: $(FUNCTION)$(NC)"
	cd $(BACKEND_DIR)/$(FUNCTION) && \
		rm -rf package function.zip && \
		mkdir -p package && \
		pip install -r requirements.txt -t package/ --quiet && \
		cd package && zip -r9 ../function.zip . -q && cd .. && \
		zip -g function.zip *.py -q
	@echo "$(GREEN)✓ Función $(FUNCTION) empaquetada en $(BACKEND_DIR)/$(FUNCTION)/function.zip$(NC)"

test: ## Ejecutar tests unitarios
	@echo "$(GREEN)Ejecutando tests...$(NC)"
	cd $(BACKEND_DIR)/ordenes && pytest tests/ -v --color=yes
	@echo "$(GREEN)Tests completados.$(NC)"

test-integration: ## Ejecutar tests de integración
	@echo "$(GREEN)Ejecutando tests de integración...$(NC)"
	@echo "$(YELLOW)Obteniendo API URL...$(NC)"
	$(eval API_URL=$(shell cd $(TF_DIR) && terraform output -raw api_gateway_url))
	@echo "API URL: $(API_URL)"
	curl -X GET $(API_URL)/health || echo "$(RED)API no disponible$(NC)"

clean: ## Limpiar archivos temporales
	@echo "$(GREEN)Limpiando archivos temporales...$(NC)"
	find . -type f -name "*.zip" -delete
	find . -type f -name "tfplan" -delete
	find . -type d -name "package" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	@echo "$(GREEN)Limpieza completada.$(NC)"

docs: ## Generar diagrama de arquitectura
	@echo "$(GREEN)Generando diagrama de arquitectura...$(NC)"
	cd $(TF_DIR) && terraform graph | dot -Tpng > ../../../docs/diagrams/architecture.png
	@echo "$(GREEN)Diagrama guardado en docs/diagrams/architecture.png$(NC)"

cost-estimate: ## Estimar costos de infraestructura
	@echo "$(GREEN)Estimando costos...$(NC)"
	@echo "$(YELLOW)Usando AWS Free Tier limits:$(NC)"
	@echo "  - Lambda: 1M requests/mes + 400,000 GB-s GRATIS"
	@echo "  - DynamoDB: 25 GB storage + 25 WCU/RCU GRATIS"
	@echo "  - API Gateway: 1M llamadas/mes GRATIS"
	@echo "  - SQS: 1M requests/mes GRATIS"
	@echo "  - CloudWatch: 5 GB logs GRATIS"
	@echo ""
	@echo "$(GREEN)Costo estimado para $(ENV): $$0-20/mes (dentro de Free Tier)$(NC)"

security-scan: ## Escanear vulnerabilidades de seguridad
	@echo "$(GREEN)Escaneando seguridad...$(NC)"
	-checkov -d infra/ --framework terraform || echo "$(YELLOW)Instalar checkov: pip install checkov$(NC)"
	-tfsec infra/ || echo "$(YELLOW)Instalar tfsec: brew install tfsec$(NC)"

format: ## Formatear código Terraform
	@echo "$(GREEN)Formateando código Terraform...$(NC)"
	terraform fmt -recursive infra/
	@echo "$(GREEN)Formato completado.$(NC)"

install-tools: ## Instalar herramientas necesarias
	@echo "$(GREEN)Instalando herramientas...$(NC)"
	@echo "$(YELLOW)Instalando Python dependencies...$(NC)"
	pip install -r requirements-dev.txt || echo "$(YELLOW)Archivo requirements-dev.txt no encontrado$(NC)"
	@echo "$(YELLOW)Para tflint: https://github.com/terraform-linters/tflint$(NC)"
	@echo "$(YELLOW)Para checkov: pip install checkov$(NC)"
	@echo "$(YELLOW)Para tfsec: https://github.com/aquasecurity/tfsec$(NC)"

logs: ## Ver logs de CloudWatch
	@echo "$(GREEN)Mostrando logs de CloudWatch...$(NC)"
	aws logs tail /aws/lambda/dinex-$(ENV)-process-orders --follow --region $(REGION)

status: ## Verificar estado de la infraestructura
	@echo "$(GREEN)Estado de la infraestructura $(ENV):$(NC)"
	@cd $(TF_DIR) && terraform show -json | jq -r '.values.root_module.resources[] | "\(.type): \(.name)"'

refresh: ## Actualizar estado de Terraform
	@echo "$(GREEN)Actualizando estado de Terraform...$(NC)"
	cd $(TF_DIR) && terraform refresh

unlock: ## Desbloquear estado de Terraform (en caso de error)
	@echo "$(YELLOW)Desbloqueando estado de Terraform...$(NC)"
	@echo "Introduce el Lock ID:"
	@read -r lock_id && cd $(TF_DIR) && terraform force-unlock $$lock_id

all: lint validate plan ## Ejecutar lint, validate y plan

deploy-full: init validate plan apply deploy-lambda ## Deploy completo (init + validate + plan + apply + lambda)

check: ## Verificar prerrequisitos
	@echo "$(GREEN)Verificando prerrequisitos...$(NC)"
	@terraform version || echo "$(RED)✗ Terraform no instalado$(NC)"
	@python --version || echo "$(RED)✗ Python no instalado$(NC)"
	@aws --version || echo "$(RED)✗ AWS CLI no instalado$(NC)"
	@make --version | head -1 || echo "$(RED)✗ Make no instalado$(NC)"
	@echo "$(GREEN)Verificación completada.$(NC)"
