"""
Utilities for enhancing prompts and generating titles for social media posts.
"""

import logging
import re

logger = logging.getLogger(__name__)


def enhance_prompt_for_social(prompt: str, media_type: str = "image") -> str:
    """
    Enhance a user prompt with context for social media content generation.
    
    Adds implicit context to guide Vertex AI toward creating content that's
    appropriate and engaging for a social feed environment.
    
    Args:
        prompt: The user's original prompt
        media_type: "image" or "video"
    
    Returns:
        Enhanced prompt with social context
    """
    # Don't enhance if prompt is already very detailed (>100 chars)
    if len(prompt) > 100:
        return prompt
    
    # Social context prefix - subtle guidance without being prescriptive
    if media_type == "video":
        social_context = "Create an engaging, visually appealing scene: "
    else:
        social_context = "Create a stunning, shareable visual: "
    
    # Clean up the user prompt
    clean_prompt = prompt.strip()
    
    # Add social context if prompt is brief
    if len(clean_prompt) < 50:
        enhanced = f"{social_context}{clean_prompt}"
    else:
        enhanced = clean_prompt
    
    # Add quality modifiers for very short prompts
    if len(clean_prompt) < 20:
        enhanced += ", high quality, vibrant, eye-catching"
    
    logger.info(f"Enhanced prompt: '{prompt}' -> '{enhanced}'")
    return enhanced


def generate_title_from_prompt(prompt: str, max_length: int = 50) -> str:
    """
    Generate a friendly, concise title from a prompt for display in feed.
    
    Takes a potentially long generation prompt and converts it to a
    readable, display-friendly title suitable for feed items.
    
    Args:
        prompt: The original generation prompt
        max_length: Maximum length of the title (default 50 chars)
    
    Returns:
        Friendly title string, truncated if needed with ellipsis
    """
    if not prompt or not prompt.strip():
        return "Untitled"
    
    # Clean up the prompt
    clean = prompt.strip()
    
    # Remove common system prompt additions we might have added
    clean = re.sub(r'^(Create an engaging.*?scene:|Create a stunning.*?visual:)\s*', '', clean, flags=re.IGNORECASE)
    clean = re.sub(r',\s*(high quality|vibrant|eye-catching|dramatic|cinematic).*$', '', clean, flags=re.IGNORECASE)
    
    # Capitalize first letter
    if clean:
        clean = clean[0].upper() + clean[1:]
    
    # Truncate if too long
    if len(clean) > max_length:
        # Try to break at a word boundary
        truncated = clean[:max_length].rsplit(' ', 1)[0]
        # If we didn't break anywhere, just hard truncate
        if len(truncated) < max_length - 10:
            truncated = clean[:max_length-3]
        return truncated + "..."
    
    return clean


def generate_share_text(prompt: str, media_type: str = "image") -> str:
    """
    Generate share-friendly text for social sharing.
    
    Args:
        prompt: The original generation prompt
        media_type: "image" or "video"
    
    Returns:
        Share-friendly text
    """
    title = generate_title_from_prompt(prompt, max_length=60)
    media_label = "video" if media_type == "video" else "image"
    return f"Check out this amazing {media_label} on MyWay! \"{title}\""


# Quality and style modifiers for different scenarios
QUALITY_MODIFIERS = {
    "high_quality": "high quality, detailed, professional",
    "vibrant": "vibrant colors, eye-catching, bold",
    "artistic": "artistic, creative, expressive",
    "cinematic": "cinematic, dramatic lighting, atmospheric",
    "minimal": "clean, minimal, elegant",
}


def add_style_modifier(prompt: str, style: str = "high_quality") -> str:
    """
    Add optional style modifier to a prompt.
    
    Args:
        prompt: The original prompt
        style: Style key from QUALITY_MODIFIERS
    
    Returns:
        Prompt with style modifier appended
    """
    modifier = QUALITY_MODIFIERS.get(style, "")
    if modifier:
        return f"{prompt}, {modifier}"
    return prompt
