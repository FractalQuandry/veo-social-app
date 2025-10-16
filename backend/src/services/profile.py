"""
Profile image management service for MyWay.
Handles 3-angle capture, base image generation via Imagen 4, and storage.
"""

import logging
from datetime import datetime
from typing import Optional

from google.cloud import storage as gcs
from google.cloud import aiplatform
import vertexai
from vertexai.preview.vision_models import ImageGenerationModel, Image
from PIL import Image as PILImage, ImageOps
import io

from ..config import get_settings
from ..models.schemas import ProfileImages, ProfileCaptureImages
from .store import get_store

logger = logging.getLogger(__name__)
settings = get_settings()


class ProfileService:
    """Service for managing user profile images"""
    
    def __init__(self):
        self.storage_client = gcs.Client(project=settings.vertex_project)
        self.bucket = self.storage_client.bucket(settings.storage_bucket)
        
        # Initialize Vertex AI
        vertexai.init(
            project=settings.vertex_project,
            location=settings.vertex_region,
        )
    
    def _get_storage_path(self, uid: str, image_type: str) -> str:
        """Generate storage path for profile images"""
        return f"profiles/{uid}/{image_type}.jpg"
    
    async def upload_capture_images(
        self,
        uid: str,
        front_data: bytes,
        left_data: bytes,
        right_data: bytes,
    ) -> ProfileCaptureImages:
        """
        Upload 3 angle photos to Cloud Storage.
        
        Args:
            uid: User ID
            front_data: Front-facing image bytes
            left_data: Left profile image bytes
            right_data: Right profile image bytes
            
        Returns:
            ProfileCaptureImages with storage paths
        """
        logger.info(f"Uploading capture images for user {uid}")
        
        images = {
            'front': front_data,
            'left': left_data,
            'right': right_data,
        }
        
        paths = {}
        
        for angle, data in images.items():
            path = self._get_storage_path(uid, f"capture_{angle}")
            blob = self.bucket.blob(path)
            
            # Upload with metadata
            blob.upload_from_string(
                data,
                content_type='image/jpeg',
                timeout=60,
            )
            
            # Make publicly readable (optional - can use signed URLs instead)
            # blob.make_public()
            
            paths[angle] = path
            logger.info(f"Uploaded {angle} image to {path}")
        
        capture_images = ProfileCaptureImages(
            front=paths['front'],
            left=paths['left'],
            right=paths['right'],
        )
        
        # Update Firestore
        db = get_store()
        logger.info(f"Updating user profile images in store for user {uid}")
        logger.info(f"Capture images data: {capture_images.model_dump()}")
        db.update_user_profile_images(
            uid,
            capture_images=capture_images,
        )
        logger.info(f"Successfully updated profile images in store")
        
        # Verify the data was saved
        user_data = db.get_user(uid)
        logger.info(f"Verification - User data after save: {user_data}")
        
        return capture_images
    
    async def generate_base_image(self, uid: str) -> str:
        """
        Generate base image using Imagen 4 from 3 capture photos.
        
        Args:
            uid: User ID
            
        Returns:
            Storage path of generated base image
            
        Raises:
            ValueError: If capture images don't exist
        """
        logger.info(f"Generating base image for user {uid}")
        
        # Get user's capture images
        db = get_store()
        user_data = db.get_user(uid)
        
        logger.info(f"User data retrieved: {user_data}")
        
        if not user_data or 'profileImages' not in user_data:
            logger.error(f"No profileImages found. user_data keys: {user_data.keys() if user_data else 'None'}")
            raise ValueError("No capture images found for user")
        
        profile_images = user_data['profileImages']
        if 'captureImages' not in profile_images:
            raise ValueError("No capture images found")
        
        capture = profile_images['captureImages']
        
        # Download the front reference image
        front_path = capture['front']
        front_blob = self.bucket.blob(front_path)
        base_image_bytes = front_blob.download_as_bytes()
        
        # Process image with Imagen: Remove background and normalize lighting
        try:
            logger.info("Processing image with Imagen for background removal")
            
            # Fix EXIF orientation before processing
            try:
                pil_img = PILImage.open(io.BytesIO(base_image_bytes))
                # Auto-rotate based on EXIF orientation
                pil_img = ImageOps.exif_transpose(pil_img)
                # Convert back to bytes
                buffer = io.BytesIO()
                pil_img.save(buffer, format='JPEG', quality=95)
                base_image_bytes = buffer.getvalue()
                logger.info("Fixed EXIF orientation")
            except Exception as e:
                logger.warning(f"Could not fix EXIF orientation: {e}, continuing with original")
            
            # Load the image using Vertex AI SDK
            base_img = Image(image_bytes=base_image_bytes)
            
            # Use imagegeneration@006 with automatic background masking
            model = ImageGenerationModel.from_pretrained("imagegeneration@006")
            
            # Edit with mask_mode="background" to automatically detect and replace background
            # Using inpainting-insert with neutral background prompt
            images = model.edit_image(
                base_image=base_img,
                mask_mode="background",  # Automatically detect background
                prompt="plain neutral gray studio background, professional lighting, photorealistic",
                edit_mode="inpainting-insert",
            )
            
            # Get the edited image bytes
            image_bytes = images[0]._image_bytes
            logger.info(f"Successfully processed image with background removal. Output size: {len(image_bytes)} bytes")
            
        except Exception as e:
            logger.error(f"Failed to process image with Imagen: {e}")
            logger.info("Falling back to original image")
            image_bytes = base_image_bytes
        
        # Upload to storage (whether processed or original)
        try:
            base_image_path = self._get_storage_path(uid, "base_image")
            blob = self.bucket.blob(base_image_path)
            blob.upload_from_string(
                image_bytes,
                content_type='image/jpeg',
            )
            
            # Generate public URL
            blob.make_public()
            public_url = blob.public_url
            
            # Update Firestore (not approved yet)
            db.update_user_profile_images(
                uid,
                base_image=base_image_path,
                base_image_public_url=public_url,
                base_image_approved=False,
                base_image_created_at=datetime.utcnow(),
            )
            
            logger.info(f"Generated base image at {base_image_path}")
            return base_image_path
            
        except Exception as e:
            logger.error(f"Failed to upload/save base image: {e}")
            raise
    
    async def approve_base_image(self, uid: str, approved: bool) -> bool:
        """
        User approves or rejects the generated base image.
        
        Args:
            uid: User ID
            approved: True to approve, False to reject
            
        Returns:
            Success status
        """
        logger.info(f"User {uid} {'approved' if approved else 'rejected'} base image")
        
        db = get_store()
        
        if approved:
            # Mark as approved
            db.update_user_profile_images(
                uid,
                base_image_approved=True,
            )
        else:
            # Clear the rejected base image
            db.update_user_profile_images(
                uid,
                base_image=None,
                base_image_public_url=None,
                base_image_approved=False,
            )
        
        return True
    
    async def get_profile_images(self, uid: str) -> Optional[ProfileImages]:
        """
        Get user's profile images data.
        
        Args:
            uid: User ID
            
        Returns:
            ProfileImages if exists, None otherwise
        """
        db = get_store()
        user_data = db.get_user(uid)
        
        if not user_data or 'profileImages' not in user_data:
            return None
        
        profile_data = user_data['profileImages']
        
        # Convert to Pydantic model
        return ProfileImages(
            captureImages=ProfileCaptureImages(**profile_data['captureImages']) 
                if 'captureImages' in profile_data else None,
            baseImage=profile_data.get('baseImage'),
            baseImagePublicUrl=profile_data.get('baseImagePublicUrl'),
            baseImageApproved=profile_data.get('baseImageApproved', False),
            baseImageCreatedAt=profile_data.get('baseImageCreatedAt'),
        )


# Singleton instance
_profile_service: Optional[ProfileService] = None


def get_profile_service() -> ProfileService:
    """Get or create the profile service singleton"""
    global _profile_service
    if _profile_service is None:
        _profile_service = ProfileService()
    return _profile_service
