project_name="kv-store-344415"
image_name="kv-store"
repo_name="kv-store-repo"

sudo usermod -a -G docker ${USER}

gcloud auth login
gcloud config set project $project_name

gcloud services enable artifactregistry.googleapis.com
gcloud artifacts repositories create $repo_name --location=us-central1 --repository-format=docker

#todo add in steps to create the repo

gcloud auth configure-docker us-central1-docker.pkg.dev

docker tag $image_name us-central1-docker.pkg.dev/$project_name/$repo_name/$image_name
docker push us-central1-docker.pkg.dev/$project_name/$repo_name/$image_name