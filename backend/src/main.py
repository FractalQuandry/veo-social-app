
import logging
import time
from typing import List

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .models.schemas import (
    FeedItem,
    FeedRequest,
    FeedResponse,
    GenRequest,
    JobStatus,
    ModerationRequest,
    ModerationResponse,
    MoreLikeThisRequest,
    PubSubEnvelope,
    GenerateTask,
)
from .services import feed as feed_service
from .services import generation, moderation, store
from .services.worker import process_generate_task

logger = logging.getLogger(__name__)
from .services.mocks import generate_mock_post


settings = get_settings()
app = FastAPI(title=settings.app_name, version=settings.api_version)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def seed_mock_content() -> None:
    db = store.get_store()
    if not settings.enable_mocks:
        return
    if db.list_ready_posts():
        return
    for topic in settings.trending_seed_prompts:
        post = generate_mock_post(topic, "image")
        post["status"] = "ready"
        saved = db.save_post(post)
        db.add_fallback(saved)


@app.get("/health")
def health() -> dict:
    return {
        "ok": True, 
        "mocks": settings.enable_mocks,
        "feed_size": settings.feed_size,
    }


@app.post("/feed", response_model=FeedResponse)
def feed(req: FeedRequest) -> FeedResponse:
    return feed_service.build_feed(req)


@app.post("/gen/image")
def gen_image(req: GenRequest) -> dict:
    return _enqueue_generation(req, "image")


@app.post("/gen/video")
def gen_video(req: GenRequest) -> dict:
    return _enqueue_generation(req, "video")


def _enqueue_generation(req: GenRequest, media_type: str) -> dict:
    if req.type != media_type:
        raise HTTPException(status_code=400, detail="type does not match endpoint")
    
    # Build list of reference image GCS URIs
    reference_image_uris = []
    
    # If includeMe is true, add the user's base image as first reference
    if req.includeMe:
        db = store.get_store()
        user_data = db.get_user(req.uid)
        if user_data and 'profileImages' in user_data:
            # Get the storage path (e.g., "profile/uid/base_image.jpg")
            base_image_path = user_data['profileImages'].get('baseImage')
            if base_image_path:
                # Convert to full GCS URI for Veo API
                base_image_gcs_uri = f"gs://{settings.storage_bucket}/{base_image_path}"
                reference_image_uris.append(base_image_gcs_uri)
                logger.info(f"Added profile image to references: {base_image_gcs_uri}")
            else:
                logger.warning(f"User {req.uid} requested includeMe but has no base image path")
        else:
            logger.warning(f"User {req.uid} requested includeMe but has no profile images")
    
    # Add custom reference images (up to 3 total)
    if req.referenceImagePaths:
        for path in req.referenceImagePaths:
            if len(reference_image_uris) >= 3:
                logger.warning("Maximum 3 reference images allowed, skipping extras")
                break
            gcs_uri = f"gs://{settings.storage_bucket}/{path}"
            reference_image_uris.append(gcs_uri)
            logger.info(f"Added custom reference image: {gcs_uri}")
    
    logger.info(f"Total reference images: {len(reference_image_uris)}")
    
    job_id, post_payload, delay_ms = generation.enqueue_generation(
        req.uid,
        req.prompt,
        media_type,
        aspect=req.aspect,
        seed=req.seed,
        duration=req.duration,
        audio=req.audio,
        is_private=req.isPrivate,
        reference_image_uris=reference_image_uris if reference_image_uris else None,
    )
    
    db = store.get_store()
    
    # If generation completed immediately (delay_ms == 0), save as ready post
    if delay_ms == 0 and post_payload.get("status") == "ready":
        logger.info(f"Image generation completed immediately, saving as ready post: {post_payload.get('id')}")
        saved_post = db.save_post(post_payload)
        # Attach to user's feed so it appears when they refresh
        db.attach_to_feed(req.uid, saved_post, score=1.0, reason=["composer"])
        logger.info(f"Attached post {saved_post.id} to user {req.uid} feed")
        return {"jobId": job_id, "etaMs": 0, "status": "ready"}
    else:
        # Save as pending job for async processing
        logger.info(f"Saving as pending job: {job_id}, delay_ms={delay_ms}")
        db.save_job(
            job_id,
            {
                "jobId": job_id,
                "userId": req.uid,
                "status": "pending",
                "post": post_payload,
                "ready_at": time.time() + (delay_ms / 1000.0),
                "reasons": ["composer"],
            },
        )
        return {"jobId": job_id, "etaMs": delay_ms}


@app.get("/gen/status", response_model=JobStatus)
def gen_status(jobId: str) -> JobStatus:
    db = store.get_store()
    job = db.get_job(jobId)
    if not job:
        raise HTTPException(status_code=404, detail="job not found")
    if job["status"] == "pending" and time.time() >= job.get("ready_at", 0):
        post_payload = job["post"]
        post_payload["status"] = "ready"
        saved_post = db.save_post(post_payload)
        db.attach_to_feed(job.get("userId", "system"), saved_post, score=1.0, reason=job.get("reasons", ["generated"]))
        job["status"] = "ready"
        job["postId"] = saved_post.id
        job["updated_at"] = time.time()
        db.save_job(jobId, job)
    return JobStatus(status=job["status"], postId=job.get("postId"))


@app.post("/moderate", response_model=ModerationResponse)
def moderate(req: ModerationRequest) -> ModerationResponse:
    return moderation.moderate(req)


@app.post("/more-like-this")
def more_like_this(req: MoreLikeThisRequest) -> dict:
    db = store.get_store()
    base_post = db.get_post(req.postId)
    if not base_post:
        raise HTTPException(status_code=404, detail="post not found")
    job_ids: List[str] = []
    for _ in range(req.count):
        prompt = f"Variation on {base_post.prompt}"
        job_id, post_payload, delay_ms = generation.enqueue_generation(
            req.uid,
            prompt,
            base_post.type,
            aspect=base_post.aspect,
            seed=None,
        )
        db.save_job(
            job_id,
            {
                "jobId": job_id,
                "userId": req.uid,
                "status": "pending",
                "post": post_payload,
                "ready_at": time.time() + (delay_ms / 1000.0),
                "reasons": ["variation"],
            },
        )
        job_ids.append(job_id)
    return {"jobs": job_ids}


@app.post("/tasks/consume")
def consume_task(envelope: PubSubEnvelope) -> dict:
    if settings.enable_mocks:
        logger.debug("Skipping task processing in mock mode")
        return {"skipped": True}

    payload = envelope.message.decoded_data()
    task = GenerateTask(**payload)
    process_generate_task(task)
    return {"ok": True}


# Profile Image Endpoints
from fastapi import File, UploadFile, Form
from .models.schemas import (
    GenerateBaseImageRequest,
    ApproveBaseImageRequest,
    ProfileImagesResponse,
)
from .services.profile import get_profile_service


@app.post("/profile/capture-images", response_model=ProfileImagesResponse)
async def upload_capture_images(
    uid: str = Form(...),
    front: UploadFile = File(...),
    left: UploadFile = File(...),
    right: UploadFile = File(...),
) -> ProfileImagesResponse:
    """Upload 3 angle photos for profile image generation"""
    try:
        profile_service = get_profile_service()
        
        # Read image data
        front_data = await front.read()
        left_data = await left.read()
        right_data = await right.read()
        
        # Upload to storage
        capture_images = await profile_service.upload_capture_images(
            uid=uid,
            front_data=front_data,
            left_data=left_data,
            right_data=right_data,
        )
        
        # Get updated profile data
        profile_images = await profile_service.get_profile_images(uid)
        
        return ProfileImagesResponse(
            profileImages=profile_images,
            success=True,
            message="Capture images uploaded successfully",
        )
    except Exception as e:
        logger.error(f"Failed to upload capture images: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/profile/generate-base", response_model=ProfileImagesResponse)
async def generate_base_image(req: GenerateBaseImageRequest) -> ProfileImagesResponse:
    """Generate base image from 3 capture photos using Imagen 4"""
    try:
        profile_service = get_profile_service()
        
        # Generate base image
        base_image_path = await profile_service.generate_base_image(req.uid)
        
        # Get updated profile data
        profile_images = await profile_service.get_profile_images(req.uid)
        
        return ProfileImagesResponse(
            profileImages=profile_images,
            success=True,
            message="Base image generated successfully. Please review and approve.",
        )
    except Exception as e:
        logger.error(f"Failed to generate base image: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/profile/approve-base", response_model=ProfileImagesResponse)
async def approve_base_image(req: ApproveBaseImageRequest) -> ProfileImagesResponse:
    """User approves or rejects generated base image"""
    try:
        profile_service = get_profile_service()
        
        # Approve/reject
        await profile_service.approve_base_image(req.uid, req.approved)
        
        # Get updated profile data
        profile_images = await profile_service.get_profile_images(req.uid)
        
        message = (
            "Base image approved and saved to your profile!"
            if req.approved
            else "Base image rejected. You can generate a new one."
        )
        
        return ProfileImagesResponse(
            profileImages=profile_images,
            success=True,
            message=message,
        )
    except Exception as e:
        logger.error(f"Failed to approve base image: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/profile/images", response_model=ProfileImagesResponse)
async def get_profile_images(uid: str) -> ProfileImagesResponse:
    """Get user's profile images"""
    try:
        profile_service = get_profile_service()
        profile_images = await profile_service.get_profile_images(uid)
        
        return ProfileImagesResponse(
            profileImages=profile_images,
            success=True,
            message=None,
        )
    except Exception as e:
        logger.error(f"Failed to get profile images: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/debug/check-isprivate")
def check_isprivate():
    """Check how many posts are missing isPrivate field"""
    from .services.store_firestore import FirestoreStore
    
    db = store.get_store()
    if not isinstance(db, FirestoreStore):
        return {"error": "Not using FirestoreStore"}
    
    posts_ref = db.client.collection("posts")
    all_posts = list(posts_ref.limit(100).stream())
    
    missing_field = 0
    has_field = 0
    ready_without_field = 0
    
    for post_doc in all_posts:
        data = post_doc.to_dict() or {}
        status = data.get("status")
        
        if "isPrivate" not in data:
            missing_field += 1
            if status == "ready":
                ready_without_field += 1
        else:
            has_field += 1
    
    return {
        "total_checked": len(all_posts),
        "missing_isprivate": missing_field,
        "has_isprivate": has_field,
        "ready_without_isprivate": ready_without_field
    }

@app.get("/debug/check-storage")
def check_storage():
    """Check for posts with missing or invalid storagePath"""
    from .services.store_firestore import FirestoreStore
    
    db = store.get_store()
    if not isinstance(db, FirestoreStore):
        return {"error": "Not using FirestoreStore"}
    
    posts_ref = db.client.collection("posts").where("status", "==", "ready").where("isPrivate", "==", False)
    all_posts = list(posts_ref.stream())
    
    missing_storage = []
    missing_public_url = []
    
    for post_doc in all_posts:
        data = post_doc.to_dict() or {}
        post_id = post_doc.id
        storage_path = data.get("storagePath", "")
        public_url = data.get("publicUrl")
        
        if not storage_path or storage_path == "":
            missing_storage.append({
                "id": post_id,
                "prompt": data.get("prompt", "")[:50]
            })
        
        if not public_url or public_url == "":
            missing_public_url.append({
                "id": post_id,
                "prompt": data.get("prompt", "")[:50],
                "storagePath": storage_path[:50] if storage_path else ""
            })
    
    return {
        "total_ready_posts": len(all_posts),
        "missing_storagePath": len(missing_storage),
        "missing_publicUrl": len(missing_public_url),
        "posts_missing_storage": missing_storage[:10],
        "posts_missing_url": missing_public_url[:10]
    }

@app.post("/fix/add-isprivate")
def fix_add_isprivate():
    """Add isPrivate=false to posts that don't have this field"""
    from .services.store_firestore import FirestoreStore
    
    db = store.get_store()
    if not isinstance(db, FirestoreStore):
        return {"error": "Not using FirestoreStore"}
    
    posts_ref = db.client.collection("posts")
    all_posts = list(posts_ref.stream())
    
    fixed_count = 0
    already_had_field = 0
    
    for post_doc in all_posts:
        data = post_doc.to_dict() or {}
        
        if "isPrivate" not in data:
            post_doc.reference.update({"isPrivate": False})
            fixed_count += 1
        else:
            already_had_field += 1
    
    return {
        "fixed": fixed_count,
        "already_had_field": already_had_field,
        "total": len(all_posts)
    }
