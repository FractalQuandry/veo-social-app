
import json
import pathlib
import uuid
from datetime import datetime
from typing import Dict, List

from google.cloud import firestore


def main():
    posts, users = load_seed_data()
    try:
        client = firestore.Client()
    except Exception as exc:  # pragma: no cover - requires GCP setup
        print("Firestore client not available:", exc)
        print("Posts preview:")
        for entry in posts:
            print("-", entry["type"], entry["prompt"][:40], entry["url"])
        print("Users preview:")
        for user in users:
            print("-", user["uid"], user.get("displayName", ""))
        return

    seed_posts(client, posts)
    seed_users(client, users)


def seed_posts(client: firestore.Client, posts: List[Dict]) -> None:
    for entry in posts:
        doc_id = entry.get("id") or str(uuid.uuid4())
        post_ref = client.collection("posts").document(doc_id)
        post_ref.set(
            {
                "type": entry["type"],
                "status": "ready",
                "storagePath": entry["url"],
                "model": entry.get("model", "mock"),
                "prompt": entry["prompt"],
                "aspect": entry.get("aspect", "9:16"),
                "duration": entry.get("duration"),
                "safety": {"blocked": False, "scores": {"harm": 0.0}},
                "synthId": True,
                "authorUid": entry.get("authorUid", "seed"),
                "createdAt": datetime.utcnow(),
                "updatedAt": datetime.utcnow(),
            }
        )
        feed_ref = client.collection("feeds").document("public").collection("items").document(doc_id)
        feed_ref.set({
            "postId": doc_id,
            "score": entry.get("score", 0.8),
            "reason": entry.get("reason", ["seed"]),
            "expiry": datetime.utcnow(),
        })
        print(f"Seeded post {doc_id}")


def seed_users(client: firestore.Client, users: List[Dict]) -> None:
    for entry in users:
        uid = entry["uid"]
        user_ref = client.collection("users").document(uid)
        user_ref.set(
            {
                "displayName": entry.get("displayName", ""),
                "photoUrl": entry.get("photoUrl"),
                "anon": entry.get("anon", True),
                "interests": entry.get("interests", []),
                "sessionBudget": entry.get("sessionBudget", {"images": 3, "videos": 1}),
                "createdAt": datetime.utcnow(),
                "updatedAt": datetime.utcnow(),
            },
            merge=True,
        )
        print(f"Seeded user {uid}")


def load_seed_data():
    posts_path = pathlib.Path(__file__).with_name("seed_posts.json")
    users_path = pathlib.Path(__file__).with_name("seed_users.json")
    posts = json.loads(posts_path.read_text())
    users = json.loads(users_path.read_text()) if users_path.exists() else []
    return posts, users


if __name__ == "__main__":
    main()
