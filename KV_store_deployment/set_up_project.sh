project_name="kv-store-344415"
repo_name='kv-store-repo'

gcloud config set project $project_name

gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud artifacts repositories create $repo_name --location=us-central1 --repository-format=docker