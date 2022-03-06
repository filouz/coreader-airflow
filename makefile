REGISTRY = ghcr.io/filouz
TAG = local

NAMESPACE=coreader

DEPLOYMENT_DIR=deployment
DEPLOYMENT_NS=${DEPLOYMENT_DIR}/.${NAMESPACE}

AIRFLOW_HOST_DOMAIN=public.example.com

AIRFLOW_DAGS_REPO=https://git-repo/dags.git
AIRFLOW_DAGS_REPO_USERNAME=git_user 
AIRFLOW_DAGS_REPO_PASSWORD=git_password

LOCAL_PATH_NODE=main-node-hostname
LOCAL_PATH_REDIS=/volume/redis
LOCAL_PATH_MONGO=/volume/mongo

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT_DIR := $(dir $(mkfile_path))

############################################ 
############################################

kustomize:
	@if [ -d "${DEPLOYMENT_NS}" ]; then \
		rm -r "${DEPLOYMENT_NS}"; \
	fi \

	@mkdir -p "${DEPLOYMENT_NS}" \

	@for FILE in ${DEPLOYMENT_DIR}/*; do \
		sed -e "s|{{NAMESPACE}}|${NAMESPACE}|g" \
			-e "s|{{AIRFLOW_HOST_DOMAIN}}|${AIRFLOW_HOST_DOMAIN}|g" \
			-e "s|{{AIRFLOW_DAGS_REPO}}|${AIRFLOW_DAGS_REPO}|g" \
			-e "s|{{AIRFLOW_DAGS_REPO_USERNAME}}|${shell echo -n $(AIRFLOW_DAGS_REPO_USERNAME) | base64 -w 0}|g" \
			-e "s|{{AIRFLOW_DAGS_REPO_PASSWORD}}|${shell echo -n $(AIRFLOW_DAGS_REPO_PASSWORD) | base64 -w 0}|g" \
			-e "s|{{LOCAL_PATH_NODE}}|${LOCAL_PATH_NODE}|g" \
			-e "s|{{LOCAL_PATH_REDIS}}|${LOCAL_PATH_REDIS}|g" \
			-e "s|{{LOCAL_PATH_MONGO}}|${LOCAL_PATH_MONGO}|g" \
			"$$FILE" > "${DEPLOYMENT_NS}/$$(basename $$FILE)"; \
	done

check: 
	@if [ ! -d "${DEPLOYMENT_NS}" ]; then \
		echo "Path ${DEPLOYMENT_NS} doesn't exist. (kustomize first)"; \
		exit 1; \
	fi

uninstall:
	-@kubectl delete namespace $(NAMESPACE)
	-@rm -r $(DEPLOYMENT_NS)


install: kustomize
	@sh ./scripts/install.sh "$(NAMESPACE)" "${DEPLOYMENT_NS}"


upgrade: check
	helm upgrade -n $(NAMESPACE) airflow apache-airflow/airflow --debug -f $(DEPLOYMENT_NS)/airflow-values.yaml 


deploy: check
	kubectl apply -f $(DEPLOYMENT_NS)/mongo.yaml
	kubectl apply -f $(DEPLOYMENT_NS)/redis.yaml

delete: check
	-kubectl delete -f $(DEPLOYMENT_NS)/mongo.yaml
	-kubectl delete -f $(DEPLOYMENT_NS)/redis.yaml
	

deploy_jupyter: check
	kubectl apply -f $(DEPLOYMENT_NS)/jupyter.yaml
	until kubectl get pods -n $(NAMESPACE) -l app=jupyter -o jsonpath="{.items[0].status.phase}" | grep Running ; do sleep 1 ; done
	@POD=$$(kubectl -n $(NAMESPACE) get pods -l app=jupyter -o jsonpath='{.items[0].metadata.name}'); \
	TOKEN=""; \
	END=$$(date -ud "5 minutes" +%s); \
	while [ -z "$$TOKEN" ]; do \
	  CURRENT=$$(date +%s); \
	  if [ $$CURRENT -ge $$END ]; then \
	    echo "Timeout waiting for Jupyter token."; \
	    exit 1; \
	  fi; \
	  sleep 1; \
	  TOKEN=$$(kubectl -n $(NAMESPACE) exec $$POD -- jupyter notebook list | grep -oP '(?<=token=)[^ ]*' | head -1); \
	done; \
	echo "http://$(AIRFLOW_HOST_DOMAIN):48081/?token=$$TOKEN"

	
delete_jupyter: check
	-kubectl delete -f $(DEPLOYMENT_NS)/jupyter.yaml
	


include dags/makefile