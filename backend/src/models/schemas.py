
from datetime import datetime
import base64
import json
from typing import Any, Dict, List, Literal, Optional

from pydantic import BaseModel, Field

class FeedRequest(BaseModel):
    uid: str
    page: int = 0
    feedType: Optional[str] = "hot"  # hot, interests, private, random

class FeedResponse(BaseModel):
    items: List["FeedItem"]
    hasMore: bool
    nextPage: int

class FeedItem(BaseModel):
    slot: Literal['READY','PENDING','FALLBACK']
    post: Optional["Post"] = None
    jobId: Optional[str] = None
    reason: Optional[List[str]] = None

class GenRequest(BaseModel):
    uid: str
    prompt: str
    type: Literal['image','video']
    fast: bool = True
    aspect: str = "9:16"
    seed: Optional[int] = None
    duration: int = 6  # Video duration in seconds (4, 6, or 8)
    audio: bool = True  # Generate audio for video
    isPrivate: bool = False  # Privacy setting for the post
    includeMe: bool = False  # Include user's profile image in generation
    baseImageUrl: Optional[str] = None  # URL of user's profile image (populated server-side)
    referenceImagePaths: Optional[list[str]] = None  # Storage paths for custom reference images (up to 3)

class JobStatus(BaseModel):
    status: Literal['pending','ready','failed']
    postId: Optional[str] = None


class PubSubMessage(BaseModel):
    data: str
    messageId: Optional[str] = None
    attributes: Dict[str, str] = {}

    def decoded_data(self) -> Dict[str, Any]:
        try:
            raw = base64.b64decode(self.data)
            return json.loads(raw.decode("utf-8"))
        except Exception as exc:  # pragma: no cover - defensive
            raise ValueError("Invalid Pub/Sub message data") from exc


class PubSubEnvelope(BaseModel):
    message: PubSubMessage
    subscription: str


class GenerateTask(BaseModel):
    jobId: str
    uid: str
    prompt: str
    mediaType: Literal['image', 'video']
    aspect: str = "9:16"
    seed: Optional[int] = None


class SafetyInfo(BaseModel):
    blocked: bool
    scores: Dict[str, float] = {}


class Post(BaseModel):
    id: str
    type: Literal['image', 'video']
    status: Literal['pending', 'ready', 'failed']
    storagePath: str
    publicUrl: Optional[str] = None
    duration: Optional[float] = None
    aspect: str = Field(default="9:16")
    model: str
    prompt: str
    title: Optional[str] = None  # Display-friendly title (generated from prompt)
    seed: Optional[int] = None
    safety: SafetyInfo
    synthId: bool = True
    authorUid: str
    isPrivate: bool = False  # Privacy setting
    createdAt: datetime = Field(default_factory=datetime.utcnow)
    updatedAt: datetime = Field(default_factory=datetime.utcnow)


class FeedJob(BaseModel):
    jobId: str
    userId: str
    slotIndex: int
    status: Literal['pending', 'ready', 'failed'] = 'pending'
    postId: Optional[str] = None
    createdAt: datetime = Field(default_factory=datetime.utcnow)
    updatedAt: datetime = Field(default_factory=datetime.utcnow)


class ModerationRequest(BaseModel):
    prompt: Optional[str] = None
    post: Optional[Post] = None


class ModerationResponse(BaseModel):
    allowed: bool
    reasons: List[str] = []
    safety: Optional[Dict[str, float]] = None


class MoreLikeThisRequest(BaseModel):
    uid: str
    postId: str
    count: int = Field(default=2, ge=1, le=5)


# Profile Image Schemas
class ProfileCaptureImages(BaseModel):
    """Three angle photos captured by user"""
    front: str  # Storage path
    left: str
    right: str


class ProfileImages(BaseModel):
    """User's profile image data"""
    captureImages: Optional[ProfileCaptureImages] = None
    baseImage: Optional[str] = None  # AI-generated digital twin storage path
    baseImagePublicUrl: Optional[str] = None
    baseImageApproved: bool = False
    baseImageCreatedAt: Optional[datetime] = None


class CaptureImagesRequest(BaseModel):
    """Request to upload 3 angle photos"""
    uid: str
    # Images will be uploaded as multipart/form-data files


class GenerateBaseImageRequest(BaseModel):
    """Request to generate base image from captures"""
    uid: str


class ApproveBaseImageRequest(BaseModel):
    """User approves or rejects generated base image"""
    uid: str
    approved: bool


class ProfileImagesResponse(BaseModel):
    """Response with user's profile images"""
    profileImages: Optional[ProfileImages] = None
    success: bool
    message: Optional[str] = None
