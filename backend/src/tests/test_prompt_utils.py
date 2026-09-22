"""Tests for prompt enhancement and title generation utilities."""

import subprocess
import sys
from pathlib import Path

import pytest

from src.services.prompt_utils import (
    enhance_prompt_for_social,
    generate_title_from_prompt,
)


def test_enhance_prompt_for_image():
    """Test that image prompts are enhanced with social context."""
    user_prompt = "sunset over ocean"
    enhanced = enhance_prompt_for_social(user_prompt, "image")
    
    # Should contain the original prompt
    assert "sunset over ocean" in enhanced
    # Should contain social context guidance
    assert "stunning" in enhanced or "shareable" in enhanced or "visual" in enhanced
    

def test_enhance_prompt_for_video():
    """Test that video prompts are enhanced with social context."""
    user_prompt = "coffee shop vibes"
    enhanced = enhance_prompt_for_social(user_prompt, "video")
    
    # Should contain the original prompt
    assert "coffee shop vibes" in enhanced
    # Should contain social context guidance
    assert "engaging" in enhanced or "appealing" in enhanced or "scene" in enhanced


def test_generate_title_short_prompt():
    """Test title generation from short prompt."""
    prompt = "beautiful sunset"
    title = generate_title_from_prompt(prompt)
    
    # Should keep the entire prompt
    assert title == "Beautiful sunset"


def test_generate_title_long_prompt():
    """Test title generation from long prompt."""
    prompt = "A breathtaking cinematic wide-angle shot of a vibrant sunset over a vast ocean with dramatic cloud formations"
    title = generate_title_from_prompt(prompt)
    
    # Should be truncated
    assert len(title) <= 60
    # Should end with ellipsis
    assert title.endswith("...")
    # Should start with capital letter
    assert title[0].isupper()


def test_generate_title_with_emojis():
    """Test title generation with emojis (kept as-is for now)."""
    prompt = "beautiful sunset over the ocean"
    title = generate_title_from_prompt(prompt)
    
    # Should contain the text and be properly capitalized
    assert "Beautiful" in title
    assert len(title) <= 60


def test_generate_title_with_punctuation():
    """Test that titles end with proper punctuation."""
    prompt = "What a beautiful day"
    title = generate_title_from_prompt(prompt)
    
    # Should not end with period for short titles
    assert not title.endswith(".")


def test_generate_title_empty_prompt():
    """Test title generation from empty prompt."""
    title = generate_title_from_prompt("")
    
    # Should return a default title
    assert title == "Untitled"


def test_generate_title_max_length():
    """Test title respects max_length parameter."""
    prompt = "This is a very long prompt that exceeds the maximum length and should be truncated properly"
    title = generate_title_from_prompt(prompt, max_length=30)
    
    # Should be truncated to max_length
    assert len(title) <= 30
    # Should end with ellipsis
    assert title.endswith("...")


@pytest.mark.parametrize(
    ("prompt", "expected"),
    [
        ("sunset, high quality, vibrant, eye-catching", "Sunset"),
        ("sunset, vibrant colors", "Sunset"),
        ("sunset, eye-catching detail", "Sunset"),
        ("sunset, dramatic lighting", "Sunset"),
        ("sunset, CINEMATICALLY lit", "Sunset"),
        ("sunset, HIGH QUALİTY!", "Sunset"),
        ("sunset, cınematıc shot", "Sunset"),
        ("sunset, dramatic\nnew subject", "Sunset, dramatic\nnew subject"),
        ("sunset, vibrant\nclouds, cinematic light", "Sunset, vibrant\nclouds"),
        ("sunset,\n\tHIGH QUALITY!", "Sunset"),
        ("sunset, dramatic\rnew subject", "Sunset"),
        ("sunset, dramatic\u2028new subject", "Sunset"),
        ("sunset, blue sky", "Sunset, blue sky"),
        (
            "Create a stunning, shareable visual: sunset, high quality",
            "Sunset",
        ),
    ],
)
def test_generate_title_preserves_modifier_handling(prompt, expected):
    assert generate_title_from_prompt(prompt, max_length=200) == expected


@pytest.mark.parametrize("modifier", ["vibrant", "cinematic"])
def test_generate_title_handles_repeated_modifiers_before_newline(modifier):
    # The old end-anchored regex rescans the whole suffix at every comma.
    # Run in a subprocess so a regression fails without hanging the test suite.
    script = (
        "from src.services.prompt_utils import generate_title_from_prompt\n"
        f"prompt = 'sunset' + ',{modifier}' * 100_000 + '\\nX'\n"
        "title = generate_title_from_prompt(prompt, max_length=len(prompt))\n"
        "assert title == prompt[0].upper() + prompt[1:]\n"
    )
    subprocess.run(
        [sys.executable, "-c", script],
        cwd=Path(__file__).resolve().parents[2],
        capture_output=True,
        text=True,
        timeout=5,
        check=True,
    )
