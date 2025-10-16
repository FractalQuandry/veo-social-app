from __future__ import annotations

import logging
import uuid
from typing import Any, Dict, Tuple

from ..config import get_settings
from .mocks import slow_pending_then_ready
from .pubsub_client import publish_generate_request
from .prompt_utils import enhance_prompt_for_social, generate_title_from_prompt

try:  # pragma: no cover - optional import
    from google.cloud import aiplatform  # type: ignore
except Exception:  # pragma: no cover - optional import
    aiplatform = None


logger = logging.getLogger(__name__)


def enqueue_generation(
    uid: str,
    prompt: str,
    media_type: str,
    aspect: str = "portrait",
    seed: int | None = None,
    duration: int = 6,
    audio: bool = True,
    is_private: bool = False,
    reference_image_uris: list[str] | None = None,
) -> tuple[str, dict[str, Any], int]:
    settings = get_settings()
    
    # Generate display-friendly title from the prompt
    title = generate_title_from_prompt(prompt)
    logger.debug(f"Generated title: {title}")
    
    # Enhance prompt for social media context before sending to Vertex
    enhanced_prompt = enhance_prompt_for_social(prompt, media_type) if not settings.enable_mocks else prompt
    if not settings.enable_mocks:
        logger.debug(f"Enhanced prompt for {media_type} generation")
    
    if settings.enable_mocks or aiplatform is None:
        logger.debug("Using mock generation for %s", media_type)
        return slow_pending_then_ready(prompt, media_type, delay_ms=settings.generate_timeout_ms)

    if settings.pubsub_topic_generate:
        job_id = str(uuid.uuid4())
        payload = {
            "jobId": job_id,
            "uid": uid,
            "prompt": enhanced_prompt,  # Send enhanced prompt to worker
            "mediaType": media_type,
            "aspect": aspect,
            "seed": seed,
        }
        publish_generate_request(payload)

        post = {
            "id": job_id,
            "type": media_type,
            "status": "pending",
            "storagePath": "",
            "duration": None,
            "aspect": aspect,
            "model": "vertex",
            "prompt": prompt,  # Store original prompt for reference
            "title": title,  # Store generated title
            "seed": seed,
            "safety": {"blocked": False, "scores": {}},
            "synthId": True,
            "authorUid": uid,
            "isPrivate": is_private,
        }
        logger.info("Queued generation job %s for user %s", job_id, uid)
        return job_id, post, max(settings.generate_timeout_ms, 30_000)

    if media_type == "image":
        return _vertex_image(uid, enhanced_prompt, prompt, title, aspect, seed, is_private, reference_image_uris)
    if media_type == "video":
        return _vertex_video(uid, enhanced_prompt, prompt, title, aspect, seed, duration, audio, is_private, reference_image_uris)
    raise ValueError(f"Unsupported media type {media_type}")


def _vertex_image(uid: str, enhanced_prompt: str, original_prompt: str, title: str, aspect: str, seed: int | None, is_private: bool = False, reference_image_uris: list[str] | None = None) -> Tuple[str, Dict, int]:  # pragma: no cover - requires Vertex
    settings = get_settings()
    if aiplatform is None:
        raise RuntimeError("google-cloud-aiplatform not configured; set ENABLE_MOCKS=true for local development")
    
    from .storage import upload_media_bytes
    from vertexai.preview.vision_models import ImageGenerationModel
    
    # Initialize Vertex AI
    aiplatform.init(project=settings.vertex_project, location=settings.vertex_region)
    
    # Generate image using Imagen 4 Fast (latest image model)
    logger.info(f"Generating {'private' if is_private else 'public'} image with Imagen 4 Fast")
    logger.info(f"Original prompt: {original_prompt}")
    logger.info(f"Enhanced prompt: {enhanced_prompt}")
    logger.info(f"Display title: {title}")
    
    # If reference_image_uris is provided, modify prompt to include the user
    if reference_image_uris:
        logger.info(f"Including {len(reference_image_uris)} reference image(s): {reference_image_uris}")
        # Prepend prompt with instruction to feature the person from the reference image
        enhanced_prompt = f"Feature the person from the reference image: {enhanced_prompt}"
        logger.info(f"Modified prompt with reference images: {enhanced_prompt}")
    
    model = ImageGenerationModel.from_pretrained("imagen-4.0-fast-generate-001")
    
    # Convert aspect ratio to size
    aspect_sizes = {
        "1:1": (1024, 1024),
        "16:9": (1408, 768),
        "9:16": (768, 1408),
        "4:3": (1152, 896),
        "3:4": (896, 1152),
    }
    width, height = aspect_sizes.get(aspect, (1024, 1024))
    
    # Generate the image
    from typing import Literal
    aspect_ratio: Literal["1:1", "9:16", "16:9", "4:3", "3:4"] = aspect if aspect in ["1:1", "9:16", "16:9", "4:3", "3:4"] else "1:1"  # type: ignore
    
    images = model.generate_images(
        prompt=enhanced_prompt,  # Use enhanced prompt for generation
        number_of_images=1,
        aspect_ratio=aspect_ratio,
        safety_filter_level="block_some",
        person_generation="allow_adult",
    )
    
    if not images or len(images.images) == 0:
        raise RuntimeError("No images generated")
    
    # Get the generated image bytes
    image = images.images[0]
    image_bytes = image._image_bytes
    
    # Upload to Cloud Storage
    job_id = str(uuid.uuid4())
    result = upload_media_bytes(
        post_id=job_id,
        media_type="image",
        data=image_bytes,
        content_type="image/png",
        extension="png"
    )
    
    logger.info(f"Image uploaded to {result.storage_path}")
    
    post = {
        "id": job_id,
        "type": "image",
        "status": "ready",
        "storagePath": result.storage_path,
        "publicUrl": result.public_url,
        "duration": None,
        "aspect": aspect,
        "model": "imagen-4.0-fast-generate-001",
        "prompt": original_prompt,  # Store original user prompt
        "title": title,  # Store display-friendly title
        "seed": seed,
        "safety": {"blocked": False, "scores": {}},
        "synthId": True,
        "authorUid": uid,
        "isPrivate": is_private,
    }
    return job_id, post, 0  # 0 timeout since it's already ready


def _vertex_video(uid: str, enhanced_prompt: str, original_prompt: str, title: str, aspect: str, seed: int | None, duration: int = 6, audio: bool = True, is_private: bool = False, reference_image_uris: list[str] | None = None) -> Tuple[str, Dict, int]:  # pragma: no cover - requires Vertex
    """
    Submit video generation request using Vertex AI Veo 3 Fast.
    NOTE: Video generation operations cannot be polled via the standard REST API.
    For now, this returns a pending status immediately. A background worker is needed to check completion.
    """
    settings = get_settings()
    if aiplatform is None:
        raise RuntimeError("google-cloud-aiplatform not configured; set ENABLE_MOCKS=true for local development")
    
    post_id = str(uuid.uuid4())
    
    # Initialize Vertex AI
    aiplatform.init(project=settings.vertex_project, location=settings.vertex_region)
    
    # Prepare the request payload
    storage_path = f"gs://{settings.storage_bucket}/{settings.cloud_storage_media_prefix}/videos/{post_id}.mp4"
    
    # Use GCS URI for reference images if provided (avoids 10MB request size limit)
    # reference_image_uris are already in format: gs://bucket/path/to/image.jpg
    if reference_image_uris:
        logger.info(f"Using {len(reference_image_uris)} reference image(s) from GCS: {reference_image_uris}")
    
    logger.warning("=== SUBMITTING VIDEO GENERATION ===")
    logger.warning("Post ID: %s (Privacy: %s)", post_id, 'PRIVATE' if is_private else 'PUBLIC')
    logger.warning("Original prompt: '%s'", original_prompt)
    logger.warning("Enhanced prompt: '%s'", enhanced_prompt)
    logger.warning("Display title: '%s'", title)
    logger.warning("Storage: %s", storage_path)
    if reference_image_uris:
        logger.warning(f"Using {len(reference_image_uris)} reference image(s) (asset type) for personalization from GCS")
    
    import time
    import requests
    from google.auth import default
    from google.auth.transport.requests import Request as AuthRequest
    
    try:
        # Get credentials
        credentials, project = default()
        auth_req = AuthRequest()
        
        # Refresh to get token
        if hasattr(credentials, 'refresh'):
            credentials.refresh(auth_req)  # type: ignore
        
        # Get token
        token = credentials.token if hasattr(credentials, 'token') else None  # type: ignore
        if not token:
            raise RuntimeError("Could not obtain authentication token")
        
        # Build request payload
        instance: Dict[str, Any] = {
            "prompt": enhanced_prompt  # Use enhanced prompt for generation
        }
        
        # Determine which model to use based on whether we have reference images
        # veo-3.1-fast-generate-preview does NOT support referenceImages
        # veo-3.1-generate-preview (slower) DOES support referenceImages
        model_id = "veo-3.1-generate-preview" if reference_image_uris else "veo-3.1-fast-generate-preview"
        
        # Add reference images if provided (for personalization)
        # Use gcsUri instead of bytesBase64Encoded to avoid 10MB request size limit
        if reference_image_uris:
            # CRITICAL LIMITATION: veo-3.1-generate-preview with referenceImages only supports 16:9 aspect ratio
            # See: https://cloud.google.com/vertex-ai/generative-ai/docs/models/veo/3-1-generate-preview
            # "Aspect ratio: 16:9, 9:16 except for reference image to video"
            if aspect == "9:16":
                logger.warning(f"ASPECT RATIO OVERRIDE: referenceImages only supports 16:9, changing from {aspect} to 16:9")
                aspect = "16:9"
            
            # Build referenceImages array from list of GCS URIs (up to 3 asset images)
            instance["referenceImages"] = [
                {
                    "image": {
                        "gcsUri": uri,
                        "mimeType": "image/jpeg"
                    },
                    "referenceType": "asset"  # Asset type for person/character
                }
                for uri in reference_image_uris[:3]  # Limit to 3 as per Veo API docs
            ]
            logger.info(f"Added {len(instance['referenceImages'])} reference image(s) to payload (asset type)")
            for idx, uri in enumerate(reference_image_uris[:3], 1):
                logger.info(f"  Reference image {idx}: {uri}")
            logger.warning(f"Using {model_id} (includeMe/referenceImages requires non-fast model)")
            # When using referenceImages, duration MUST be 8 seconds per API docs
            if duration != 8:
                logger.warning(f"Overriding duration from {duration}s to 8s (required when using referenceImages)")
                duration = 8
        else:
            logger.info(f"Using {model_id} (fast model, no reference images)")
        
        payload = {
            "instances": [instance],
            "parameters": {
                "storageUri": storage_path,
                "sampleCount": 1,
                "durationSeconds": duration,  # 4, 6, or 8 seconds (must be 8 with referenceImages)
                "aspectRatio": aspect if aspect in ["9:16", "16:9"] else "16:9",  # Use aspect directly (already in correct format)
                "personGeneration": "allow_adult",
                "generateAudio": audio,  # Generate audio for video
                "resolution": "720p",  # 720p or 1080p
            }
        }
        
        if seed is not None:
            payload["parameters"]["seed"] = seed
        
        # Call the predictLongRunning API (use model_id determined above)
        endpoint_url = (
            f"https://{settings.vertex_region}-aiplatform.googleapis.com/v1/"
            f"projects/{settings.vertex_project}/locations/{settings.vertex_region}/"
            f"publishers/google/models/{model_id}:predictLongRunning"
        )
        
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        logger.warning("Calling predictLongRunning at: %s", endpoint_url)
        # Log payload without base64 image data to avoid terminal overflow
        payload_summary = {
            "instances": [{"prompt": instance.get("prompt"), "hasReferenceImages": "referenceImages" in instance}],
            "parameters": payload["parameters"]
        }
        logger.warning("Request payload: %s", payload_summary)
        response = requests.post(endpoint_url, json=payload, headers=headers)
        
        if response.status_code != 200:
            logger.error("API error response: %s", response.text)
            logger.error("Request had referenceImages: %s", "referenceImages" in instance)
        
        response.raise_for_status()
        
        operation_data = response.json()
        operation_name = operation_data.get("name")
        
        if not operation_name:
            raise RuntimeError("No operation name returned from video generation API")
        
        logger.warning("Operation started: %s", operation_name)
        
        # Poll the operation until complete
        max_wait_seconds = 90
        poll_interval = 3
        elapsed = 0
        
        # Use fetchPredictOperation to poll (NOT a GET to the operation path!)
        # Must use the same model_id as the initial request
        fetch_operation_url = (
            f"https://{settings.vertex_region}-aiplatform.googleapis.com/v1/"
            f"projects/{settings.vertex_project}/locations/{settings.vertex_region}/"
            f"publishers/google/models/{model_id}:fetchPredictOperation"
        )
        
        logger.warning("Polling with fetchPredictOperation at: %s", fetch_operation_url)
        
        # Wait a bit before first poll
        time.sleep(5)
        elapsed = 5
        
        while elapsed < max_wait_seconds:
            # Refresh credentials if needed
            if hasattr(credentials, 'valid') and hasattr(credentials, 'refresh'):
                if not credentials.valid:  # type: ignore
                    credentials.refresh(auth_req)  # type: ignore
                    token = credentials.token if hasattr(credentials, 'token') else token  # type: ignore
                    headers["Authorization"] = f"Bearer {token}"
            
            # Check operation status using fetchPredictOperation (POST with operationName in body)
            poll_payload = {"operationName": operation_name}
            check_response = requests.post(fetch_operation_url, json=poll_payload, headers=headers)
            
            if check_response.status_code != 200:
                logger.warning("Poll status %d: %s", check_response.status_code, check_response.text[:500])
                time.sleep(poll_interval)
                elapsed += poll_interval
                continue
            
            operation_status = check_response.json()
            
            if operation_status.get("done"):
                logger.warning("Video generation completed in %d seconds", elapsed)
                
                # Check for errors
                if "error" in operation_status:
                    error_msg = operation_status["error"].get("message", "Unknown error")
                    raise RuntimeError(f"Video generation failed: {error_msg}")
                
                # Extract video from response
                response_data = operation_status.get("response", {})
                videos = response_data.get("videos", [])
                
                if not videos or len(videos) == 0:
                    raise RuntimeError("No videos in response")
                
                # Get the first video
                video = videos[0]
                video_gcs_uri = video.get("gcsUri")
                
                if not video_gcs_uri:
                    raise RuntimeError("No gcsUri in video response")
                
                logger.warning("Video generated at: %s", video_gcs_uri)
                
                # Convert GCS URI to public URL
                # gs://bucket/path -> https://storage.googleapis.com/bucket/path
                public_url = video_gcs_uri.replace("gs://", "https://storage.googleapis.com/")
                storage_path_relative = video_gcs_uri.replace(f"gs://{settings.storage_bucket}/", "")
                
                post = {
                    "id": post_id,
                    "type": "video",
                    "status": "ready",
                    "storagePath": storage_path_relative,
                    "publicUrl": public_url,
                    "duration": 6,
                    "aspect": aspect,
                    "model": model_id,  # Use the model that was actually used
                    "prompt": original_prompt,  # Store original user prompt
                    "title": title,  # Store display-friendly title
                    "seed": seed,
                    "safety": {"blocked": False, "scores": {}},
                    "synthId": True,
                    "authorUid": uid,
                    "isPrivate": is_private,
                }
                
                logger.warning("Video generation successful: %s -> %s", post_id, public_url)
                return post_id, post, 0
            
            logger.debug("Polling... elapsed: %d seconds", elapsed)
            time.sleep(poll_interval)
            elapsed += poll_interval
        
        # Timeout
        logger.warning("Video generation timed out after %d seconds", elapsed)
        post = {
            "id": post_id,
            "type": "video",
            "status": "pending",
            "storagePath": "",
            "duration": None,
            "aspect": aspect,
            "model": model_id,  # Use the model that was actually used
            "prompt": original_prompt,  # Store original user prompt
            "title": title,  # Store display-friendly title
            "seed": seed,
            "safety": {"blocked": False, "scores": {}},
            "synthId": True,
            "authorUid": uid,
            "isPrivate": is_private,
        }
        return post_id, post, 0
        
    except Exception as e:
        logger.error("Video generation failed: %s", str(e), exc_info=True)
        # Use fallback model name if model_id wasn't set yet
        fallback_model = "veo-3.1-fast-generate-preview"
        post = {
            "id": post_id,
            "type": "video",
            "status": "error",
            "storagePath": "",
            "duration": None,
            "aspect": aspect,
            "model": fallback_model,  # Use fallback since error occurred before model_id was set
            "prompt": original_prompt,  # Store original user prompt
            "title": title,  # Store display-friendly title
            "seed": seed,
            "safety": {"blocked": False, "scores": {}},
            "synthId": True,
            "authorUid": uid,
            "isPrivate": is_private,
        }
        return post_id, post, 0
