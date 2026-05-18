import os

mode = os.environ.get("MODE", "stable")
version = os.environ.get("APP_VERSION", "1.0.0")

print(f"Mode is: {mode}")
print(f"Version is: {version}")

