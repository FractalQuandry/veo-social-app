
#!/usr/bin/env bash
set -euo pipefail

if [[ -f .env ]]; then
	# shellcheck disable=SC1091
	source .env
fi

: "${GCP_PROJECT_ID:?Set GCP_PROJECT_ID in environment or .env file}"
: "${REGION_RUN:?Set REGION_RUN in environment or .env file}"

SERVICE_NAME=${SERVICE_NAME:-my-way-api}
ARTIFACT_REPO=${ARTIFACT_REPO:-my-way}
IMAGE="${REGION_RUN}-docker.pkg.dev/${GCP_PROJECT_ID}/${ARTIFACT_REPO}/${SERVICE_NAME}:latest"
PUBSUB_TOPIC=${PUBSUB_TOPIC_GENERATE:-myway-gen-requests}
PUBSUB_SUB=${PUBSUB_SUBSCRIPTION_GENERATE:-myway-gen-worker}

echo "==> Enabling required APIs"
gcloud services enable \
	run.googleapis.com \
	firestore.googleapis.com \
	aiplatform.googleapis.com \
	storage.googleapis.com \
	pubsub.googleapis.com \
	artifactregistry.googleapis.com

echo "==> Creating Artifact Registry (if missing)"
gcloud artifacts repositories describe "${ARTIFACT_REPO}" \
	--location="${REGION_RUN}" --project="${GCP_PROJECT_ID}" >/dev/null 2>&1 || \
gcloud artifacts repositories create "${ARTIFACT_REPO}" \
	--repository-format=docker \
	--location="${REGION_RUN}" \
	--description="My Way backend images"

echo "==> Building backend container"
gcloud builds submit backend --tag "${IMAGE}" --project "${GCP_PROJECT_ID}"

echo "==> Deploying to Cloud Run"
gcloud run deploy "${SERVICE_NAME}" \
	--project "${GCP_PROJECT_ID}" \
	--image "${IMAGE}" \
	--region "${REGION_RUN}" \
	--allow-unauthenticated \
 --set-env-vars "ENABLE_MOCKS=${ENABLE_MOCKS:-true},GENERATE_TIMEOUT_MS=${GENERATE_TIMEOUT_MS:-800},FEED_SHARE_INTEREST=${FEED_SHARE_INTEREST:-0.6},FEED_SHARE_EXPLORE=${FEED_SHARE_EXPLORE:-0.25},FEED_SHARE_TRENDING=${FEED_SHARE_TRENDING:-0.15},REGION_VERTEX=${REGION_VERTEX:-${REGION_RUN}},PUBSUB_TOPIC_GENERATE=${PUBSUB_TOPIC},PUBSUB_SUBSCRIPTION_GENERATE=${PUBSUB_SUB},FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET:-},CLOUD_STORAGE_MEDIA_PREFIX=${CLOUD_STORAGE_MEDIA_PREFIX:-media},CLOUD_RUN_SERVICE=${SERVICE_NAME}"

echo "==> Ensuring Pub/Sub topic and subscription"
gcloud pubsub topics describe "${PUBSUB_TOPIC}" --project "${GCP_PROJECT_ID}" >/dev/null 2>&1 || \
gcloud pubsub topics create "${PUBSUB_TOPIC}" --project "${GCP_PROJECT_ID}"

if [[ -n "${PUBSUB_PUSH_ENDPOINT:-}" ]]; then
	if [[ -n "${PUBSUB_PUSH_AUTH_SA:-}" ]]; then
		PUSH_ARGS=(--push-auth-service-account "${PUBSUB_PUSH_AUTH_SA}")
	else
		PUSH_ARGS=()
	fi
	gcloud pubsub subscriptions describe "${PUBSUB_SUB}" --project "${GCP_PROJECT_ID}" >/dev/null 2>&1 || \
	gcloud pubsub subscriptions create "${PUBSUB_SUB}" \
		--project "${GCP_PROJECT_ID}" \
		--topic "${PUBSUB_TOPIC}" \
		--push-endpoint "${PUBSUB_PUSH_ENDPOINT}" \
		${PUSH_ARGS[@]}
else
	gcloud pubsub subscriptions describe "${PUBSUB_SUB}" --project "${GCP_PROJECT_ID}" >/dev/null 2>&1 || \
	gcloud pubsub subscriptions create "${PUBSUB_SUB}" \
		--project "${GCP_PROJECT_ID}" \
		--topic "${PUBSUB_TOPIC}"
fi

echo "==> Deploying Firestore rules"
gcloud firestore databases update --project "${GCP_PROJECT_ID}" --location "${LOCATION_FIRESTORE:-${REGION_RUN}}" --type=firestore-native || true
gcloud firestore security-rules update infra/firestore.rules --project "${GCP_PROJECT_ID}"

echo "==> Deploying Firestore composite indexes"
gcloud firestore indexes composite create --project "${GCP_PROJECT_ID}" --quiet --async --file infra/firestore.indexes.json || true

if command -v firebase >/dev/null 2>&1 && [[ -n "${FIREBASE_PROJECT_ID:-}" ]]; then
	echo "==> Deploying Firebase Storage rules"
	firebase storage:rules:set infra/storage.rules --project "${FIREBASE_PROJECT_ID}"
else
	echo "==> Skipping Firebase Storage rules deploy (firebase CLI not found or FIREBASE_PROJECT_ID missing)"
fi

echo "==> Deployment complete"
