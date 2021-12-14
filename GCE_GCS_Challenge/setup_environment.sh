#! /bin/bash
set -x

billing_account_id="0143A5-D35603-875A49"

prefix="kfinn-gcs-gce-challenge-3"

project_id="${prefix}"
bucket_name="gs://${prefix}"
service_account_name="${prefix}-sa"
sa_full_name="${service_account_name}@${project_id}.iam.gserviceaccount.com"
vm_name="${prefix}-vm"

#create a new project
gcloud projects create $project_id --name="GCS GCE Challenge Lab" --set-as-default

#link to the billing account
gcloud beta billing projects link $project_id --billing-account=$billing_account_id

#enable compute service
gcloud services enable compute

#create bucket to store logs
gsutil mb $bucket_name

#create a service account
gcloud iam service-accounts create $service_account_name

#grant permissions
gcloud projects add-iam-policy-binding ${project_id} --member="serviceAccount:${sa_full_name}" --role=roles/storage.objectAdmin

#create VM
gcloud compute instances create "${vm_name}" --image-project=debian-cloud --image-family=debian-10 --zone=us-central1-c  --machine-type=e2-micro --project=$project_id \
--metadata=lab-logs-bucket=${bucket_name} --metadata-from-file=startup-script=startup_script.sh --service-account=${sa_full_name} --scopes=storage-rw
